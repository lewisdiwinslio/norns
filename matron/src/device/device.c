#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "device.h"


#define TEST_NULL_AND_FREE(p) if((p)!=NULL) { free(p); }

// start the rx thread for a device
static int dev_start(union dev* d, device_t t, const char* path);

union dev* dev_new(device_t type, const char* path) {
  union dev* d = calloc(1, sizeof(union dev));
  if(!d) return NULL;
  // initialize the base class
  d->base.type = type;
  d->base.path = malloc(strlen(path)+1);
  strcpy(d->base.path, path);
  // initialize the subclass
  switch(type) {
  case DEV_TYPE_MONOME:
	dev_monome_init(d);
	break;
  case DEV_TYPE_INPUT:
	dev_input_init(d);
	break;
  default:
	// this is an error
	free(d);
	return NULL;
  }
  // start the thread
  dev_start(d, type, path);						
  return d;
}

int dev_delete(union dev* d) {
  int ret = pthread_cancel(d->base.tid);
  if(ret) {
	printf("dev_monome_free(): error in pthread_cancel()\n");
	fflush(stdout);
	return -1;
  }
  ret = pthread_join(d->base.tid, NULL); // wait before free
  if(ret) {
	printf("dev_monome_free(): error in pthread_join()\n");
	fflush(stdout);
	return -1;
  }
  d->base.deinit(d);
  TEST_NULL_AND_FREE(d->base.path);
  TEST_NULL_AND_FREE(d->base.serial);
  TEST_NULL_AND_FREE(d->base.name);
  free(d);
}

int dev_start(union dev* d, device_t type, const char* path) {
  pthread_attr_t attr;
  int ret;

  if (d->base.start == NULL) {
	return -1;
  }

  ret = pthread_attr_init(&attr);
  if(ret) {
	printf("m_init(): error on thread attributes \n"); fflush(stdout);
	return -1;
  }
  ret = pthread_create(&d->base.tid, &attr, d->base.start, d);
  pthread_attr_destroy(&attr);
  if(ret) {
	printf("m_init(): error creating thread\n");fflush(stdout);
	return -1;
  }
  return 0;
}

int dev_id(union dev* d) {
  return d->base.id;
}

const char* dev_serial(union dev* d) {
  return d->base.serial;
}

const char* dev_name(union dev* d) {
  return d->base.name;
}
