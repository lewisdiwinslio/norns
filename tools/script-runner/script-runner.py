import os
import glob
import subprocess
import time

TIMEOUT_BOOT = 8
TIMEOUT_SCRIPT = 4

def filter_script_paths(paths):
    res = list(filter(lambda p: not '/lib/' in p, paths))
    res = list(filter(lambda p: not 'bowering' in p, res))
    res = list(filter(lambda p: not 'norns.online' in p, res))
    res.sort()
    return res

def start(exe):
    proc = subprocess.Popen(
        exe,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE)
    os.set_blocking(proc.stdout.fileno(), False)
    return proc

def write(proc, message):
    proc.stdin.write(f"{message.strip()}\n".encode("utf-8"))
    proc.stdin.flush()

def readline(proc):
    return proc.stdout.readline().decode("utf-8").strip()

def readline_timeout(proc, timeout=1.0):
    # read a line from a process's stdout
    # (assumed to be in non-blocking mode)
    # return the line read, or None on timeout
    t0 = time.time()
    while True:
        line = readline(proc)
        if (line is not None) and (line != ""):
            return line
        t1 = time.time()
        if (t1-t0) > timeout:
            return None
               
def capture_output(proc, timeout=1):
    output = []
    while True:
        proc.stdout.flush()
        line = readline_timeout(proc, 1)
        print(line)
        if line is not None:
            output.append(line)
        else:
            break
    return output
        
home = os.path.expanduser("~")
exe = os.path.join(home, 'norns/build/matron/matron')
code = os.path.join(home, 'dust/code')

proc = start(exe)
output = capture_output(proc, TIMEOUT_BOOT)
#for line in output: print(line)

paths = glob.glob(f'{code}/**/*.lua', recursive=True)
scripts = filter_script_paths(paths)

scripts_ok = open('script_runner.ok.txt', 'a')
scripts_param_err =open('script_runner.param_err.txt', 'a')
scripts_other_err = open('script_runner.other_err.txt', 'a')

def write_script_output(name, output):
    with open(f"output/{name}.txt", "w") as f:
        f.write("\n".join(output))

def run_script(path):
    name = os.path.basename(path)
    name = os.path.splitext(name)[0]
           
    print(f'running: {path}')
    cmd = f"norns.script.load('{path}')"
    write(proc, cmd)
    err = False
    paramErr = False
    output = capture_output(proc, TIMEOUT_SCRIPT)
    if len(output) < 1:
        print(" !! no output from script! (process is hung?)")
    write_script_output(name, output)
    ids = []
    for line in output:
        print(line)
        if "!!!!!" in line:
            err = True
            if "parameter id collision" in line:
                id = line.replace("!!!!! error: parameter id collision: ", "")
                ids.append(id.strip())
                paramErr = True
    if err:
        if paramErr:
            print(f"{name}: param ID collision: {', '.join(ids)}")
            scripts_param_err.write(f'{path}\n')            
        else:
            print(f"{name}: other error")
            scripts_other_err.write(f'{path}\n')               
    else:
       scripts_ok.write(f'{path}\n')


#run_script('/home/emb/dust/code/awake/awake.lua')

print(f'processing {len(scripts)} scripts...')
for script in scripts:
    run_script(script)

# if len(scripts_ok) > 0:
#     print('these scripts had parameter ID collisions:') 
#     for script in scripts_param_err:
#         print(f"    {script}")
#     print("")

# if len(scripts_ok) > 0:
#     print('these scripts had other errors:')
#     for script in scripts_other_err:
#         print(f"    {script}")
#     print("")

# if len(scripts_ok) > 0:
#     print('these scripts were OK:') 
#     for script in scripts_ok:
#         print(f"    {script}")

os.system("pidof matron | xargs kill -9")
