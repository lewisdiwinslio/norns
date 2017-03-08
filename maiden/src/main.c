#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/wait.h>
#include <unistd.h>

#define USE_READLINE 1
#if USE_READLINE
#include <readline/readline.h>
#include <readline/history.h>
#endif

//-----------------
//---- defines

#define PIPE_READ 0
#define PIPE_WRITE 1
#define BUFFER_SIZE 1024

//----------------
//---- variables

int matron_pipe_in[2];
int matron_pipe_out[2];

int crone_pipe_out[2];

// child process id's
pid_t matron_pid;
pid_t crone_pid;

// client thread id's
pthread_t matron_tx_tid, matron_rx_tid;
pthread_t crone_rx_tid;

//--------------------------
//---- function declarations

// run matron process and redirect its IO
int run_matron(void);
// loop to receive data from matron
void* matron_rx_loop(void* psock);
// loop to send data to matron
void* matron_tx_loop(void* x);
// run the audio process and redirect its IO
void run_crone(void);
// loop to receive data from clone
void* crone_rx_loop(void* x);
// kill the audio process
void quit_crone(void);

// utility to launch a joinable thread
void launch_thread(pthread_t *tid, void *(*start_routine) (void *), void* data);
// utility to close a pipe
void cleanup_pipe(int pipe[2]);


//-------------------------
//---- function definitions
  
int main(int argc, char** argv) {

  // create pipes for i/o redirection
  if(pipe(matron_pipe_in) < 0) {
	perror("allocating pipe for matron input redirect");
	return -1;
  }
  if(pipe(matron_pipe_out) < 0) {
	perror("allocating pipe for matron output redirect");
	cleanup_pipe(matron_pipe_in);
	return -1;
  }
  if(pipe(crone_pipe_out) < 0) {
	perror("allocating pipe for crone output redirect");
	cleanup_pipe(matron_pipe_in);
	cleanup_pipe(matron_pipe_out);
	return -1;
  }
  
  // fork a child process to run matron
  matron_pid = fork();
  if(matron_pid < 0) {
	printf("fork() returned an error\n");
	return 1;
  }
  if(matron_pid == 0) {
	run_matron();
	goto child_exit; // shouldn't get here
  }
  
  // parent continues.

  // fork child process to run crone
  crone_pid = fork();
  if(crone_pid < 0) {
	printf("fork() returned an error\n");
	return 1;
  }
  
  if(crone_pid == 0) {
	run_crone();
	goto child_exit; // shouldn't get here
  }

  // close unused pipe endpoints
  close(matron_pipe_in[PIPE_READ]);
  close(matron_pipe_out[PIPE_WRITE]);
  close(crone_pipe_out[PIPE_WRITE]);
  
  // create threads to handle the children's i/o
  launch_thread(&matron_tx_tid, &matron_tx_loop, NULL);
  launch_thread(&matron_rx_tid, &matron_rx_loop, NULL);
  launch_thread(&crone_rx_tid, &crone_rx_loop, NULL);
  
  // wait for threads to exit
  pthread_join(matron_tx_tid, NULL);
  pthread_join(matron_rx_tid, NULL);
  pthread_join(crone_rx_tid, NULL);
 
  // wait for child processes to exit
  waitpid(matron_pid, NULL, 0);
  waitpid(crone_pid, NULL, 0);
  
  printf("fare well\n\n");
  return 0;

 child_exit:
  perror("child process quit unexpectedly");
  return 0;
}

int run_matron(void) {
  if(matron_pid != 0) {
	printf("error: calling run_matron() from parent process\n");
	return -1;
  }
  // redirect stdin
  if (dup2(matron_pipe_in[PIPE_READ], STDIN_FILENO) == -1) {
	perror("redirecting stdin");
	return -1;
  }

  // redirect stdout
  if (dup2(matron_pipe_out[PIPE_WRITE], STDOUT_FILENO) == -1) {
	perror("redirecting stdout");
	return -1;
  }

  // redirect stderr
  if (dup2(matron_pipe_out[PIPE_WRITE], STDERR_FILENO) == -1) {
	perror("redirecting stderr");
	return -1;
  }

  close(matron_pipe_in[PIPE_READ]);
  close(matron_pipe_in[PIPE_WRITE]);
  close(matron_pipe_out[PIPE_READ]);
  close(matron_pipe_out[PIPE_WRITE]); 

  char *argv[] = { "matron", "57120", "8888", NULL};
  char *env[] = { NULL };
	
  execv("matron/matron", argv);
  perror("execv"); // shouldn't get here
}

void* matron_rx_loop(void* psock) {
  char rxbuf[BUFFER_SIZE];
  int nb;
  while(1) {
	// print server response
	nb = read(matron_pipe_out[PIPE_READ], rxbuf, BUFFER_SIZE-1);
	if(nb > 0) {
	  rxbuf[nb] = '\0';
	  printf("%s", rxbuf);
	}	
  }
}

void* matron_tx_loop(void* x) {
  char txbuf[BUFFER_SIZE];
  int res;
  int ch;
  size_t len;
  int quit = 0;
  char* line = (char*)NULL;
  int newline = 0;
  
  // wait a bit for the child executable
  usleep(100000);
  
  while(!quit) {

#if USE_READLINE
	if(line) { free(line); line=(char*)NULL; }
	line = readline("");
	len = strlen(line);
	if(len < 1) {
	  continue;
	}
	add_history(line);
	len++; // add newline
	snprintf(txbuf, BUFFER_SIZE, "%s\n", line);
#else // totally getch
	len = 0;
	txbuf[0] = '\0';
	newline = 0;
	// read from stdin
	while(newline != 1) {
	  if(len < (BUFFER_SIZE-1)) {
		ch = getchar();
		txbuf[len++] = (char)ch;
		if(ch == 10) { newline = 1; }
	  } else {
		newline = 1;
	  }
	}
   	txbuf[len] = '\0';
#endif
	// check for quit
	// FIXME: would be cleaner to get signal from matron, somehow, maybe?
	if(len == 2 && txbuf[0] == 'q') { // len includes \n
	  quit = 1;
	  goto exit;
	}
	// send to server
	write(matron_pipe_in[PIPE_WRITE], txbuf, len);
  }
 exit:
  quit_crone();
  kill(matron_pid, SIGUSR1);
  pthread_cancel(matron_rx_tid);
  pthread_cancel(matron_tx_tid);
}

void run_crone(void) {
  // TODO
  while(1) { usleep(1000000); }
}

void quit_crone(void) {
  kill(crone_pid, SIGUSR1);
  pthread_cancel(crone_rx_tid);
}


void* crone_rx_loop(void* x) {
  // TODO
  while(1) { usleep(1000000); }
}

void launch_thread(pthread_t *tid, void *(*start_routine) (void *), void* data) {
  pthread_attr_t attr;
  int s;
  s = pthread_attr_init(&attr);
  if(s) { printf("error initializing thread attributes \n"); }
  s = pthread_create(tid, &attr, start_routine, data);
  if(s) { printf("error creating thread\n"); }
  pthread_attr_destroy(&attr);
}

void cleanup_pipe(int pipe[2]) {
  close(pipe[PIPE_READ]);
  close(pipe[PIPE_WRITE]);
}
