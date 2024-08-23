import sys, os

HOME = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
sys.path.append(os.path.join(HOME, 'lib'))

import terminal

CWD = os.getcwd()

VIM_FILEPATH = os.getenv('VIM_FILEPATH', '')
VIM_FILENAME = os.getenv('VIM_FILENAME', '')
VIM_FILEDIR = os.getenv('VIM_FILEDIR', CWD)
VIM_FILENOEXT = os.getenv('VIM_FILENOEXT', '')
VIM_FILEEXT = os.getenv('VIM_FILEEXT', '')
VIM_CWD = os.getenv('VIM_CWD', CWD)
VIM_RELDIR = os.getenv('VIM_RELDIR', '')
VIM_RELNAME = os.getenv('VIM_RELNAME', '')
VIM_CWORD = os.getenv('VIM_CWORD', '')
VIM_VERSION = os.getenv('VIM_VERSION', '')
VIM_MODE = os.getenv('VIM_MODE', 0)
VIM_GUI = int(os.getenv('VIM_GUI', '0'))


TERMINAL = os.environ.get('TERM_PROGRAM', '')


def execute(script, cwd = None):
	term = 'terminal'
	profile = 'Develop'
	post = ''
	if TERMINAL == 'iTerm.app':
		term = 'iterm'
	elif TERMINAL == 'Apple_Terminal':
		term = 'terminal'
	elif VIM_GUI:
		term = 'terminal'
		post = 'open /Applications/MacVim.app'
	elif os.environ.get('ATOM_HOME', ''):
		term = 'terminal'
		post = 'open /Applications/Atom.app'
	if cwd == None:
		cwd = VIM_FILEDIR
	args = [__file__, '-m', term, '-p', profile, '-w', '-d', cwd ]
	if post:
		args.extend(['-o', post])
	args.append('--stdin')
	script = [ line for line in script ]
	if term == 'terminal':
		script.insert(0, 'clear')
		pass
	terminal.main(args, script)

def open(command, cwd = None):
	return execute([command], cwd)


if __name__ == '__main__':
	execute(['ls -la '])


