#! /usr/bin/env python2
import sys
import time
import os


#----------------------------------------------------------------------
# flow control
#----------------------------------------------------------------------
def flow_control(command, hz):
	import subprocess
	hz = (hz < 10) and 10 or hz
	#sys.stdout.write('%d: --> %s\n'%(hz, command))
	sys.stdout.flush()
	p = subprocess.Popen(
			command,
			shell = True, 
			stdin = subprocess.PIPE,
			stderr = subprocess.STDOUT,
			stdout = subprocess.PIPE)
	stdout = p.stdout
	p.stdin.close()
	count = 0
	ts = long(time.time() * 1000000)
	period = 1000000 / hz
	tt = time.time()
	while True:
		text = stdout.readline()
		if text == '':
			break
		text = text.rstrip('\n\r')
		current = long(time.time() * 1000000)
		if current < ts:
			delta = (ts - current)
			time.sleep(delta * 0.001 * 0.001)
		elif ts < current - period * 10:
			ts = current
		ts += period
		sys.stdout.write(text + '\n')
		sys.stdout.flush()
	#sys.stdout.write('endup %ld seconds\n'%long(time.time() - tt))
	sys.stdout.flush()
	return 0


#----------------------------------------------------------------------
# main program
#----------------------------------------------------------------------
def main(args):
	args = [n for n in args]
	if len(args) < 2:
		print 'usage: %s HZ command'%args[0]
		return 1
	hz = int(os.environ.get('VIM_LAUNCH_HZ', '50'))
	flow_control(args[1], hz)
	return 0


#----------------------------------------------------------------------
# main program
#----------------------------------------------------------------------
if __name__ == '__main__':
	main(sys.argv)



