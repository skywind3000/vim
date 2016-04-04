import sys
import termios

data = []
fd = sys.stdin.fileno()
old = termios.tcgetattr(fd)
new = termios.tcgetattr(fd)
new[3] = new[3] & ~termios.ECHO 
new[3] = new[3] & ~termios.ICANON
new[3] = new[3] & ~termios.ICRNL
#new[2] = new[2] & ~termios.ICRNL
#new[1] = new[1] & ~termios.ICRNL
new[0] = new[0] & ~termios.ICRNL
termios.tcsetattr(fd, termios.TCSANOW, new)

import os
os.system('stty -a')

names = {
		27:'<ESC>',
		10:'<CR>',
		127:'<BS>',
}

index = 0
while 1:
	ch = sys.stdin.read(1)
	x = ord(ch)
	if x >= 32 and x < 127:
		print '[%2x]: %s'%(x, chr(x))
	elif x in names:
		print '[%2x]: %s'%(x, names[x])
	else:
		print '[%2x]: ?'%(x)
	index += 1
	if ch == '\n': break



termios.tcsetattr(fd, termios.TCSANOW, old)


