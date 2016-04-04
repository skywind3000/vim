#! /usr/bin/python
import sys, os, time
import subprocess


#----------------------------------------------------------------------
# configure
#----------------------------------------------------------------------
class configure (object):

	def __init__ (self):
		self.dirhome = os.path.abspath(os.path.dirname(__file__))
		self.diruser = os.path.abspath(os.path.expanduser('~'))
		self.unix = sys.platform[:3] != 'win' and True or False
		self.temp = os.environ.get('temp', os.environ.get('tmp', '/tmp'))
		self.tick = long(time.time()) % 100
		if self.unix:
			temp = os.environ.get('tmp', '/tmp')
			if not temp:
				temp = '/tmp'
			folder = os.path.join(temp, 'runner/folder')
			if not os.path.exists(folder):
				try:
					os.makedirs(folder, 0777)
				except:
					folder = ''
			if folder:
				self.temp = folder
				try:
					os.chmod(self.temp, 0777)
				except:
					pass
		self.temp = os.path.join(self.temp, 'winex_%02d.cmd'%self.tick)
		self.cygwin = ''
		self.GetShortPathName = None
		self.GetFullPathName = None
		self.GetLongPathName = None
		self.ShellExecute = None
		self.kernel32 = None
		self.textdata = None
		self.filter = None
		self.filter_mode = ''
		self.encoding = None
	
	def call (self, args, stdin = None):
		p = subprocess.Popen(args, shell = False,
				stdin = subprocess.PIPE,
				stdout = subprocess.PIPE, 
				stderr = subprocess.PIPE)
		if stdin != None:
			p.stdin.write(stdin)
			p.stdin.flush()
		p.stdin.close()
		stdout = p.stdout.read()
		stderr = p.stderr.read()
		code = p.wait()
		return code, stdout, stderr

	def where (self, filename, path = []):
		PATH = os.environ.get('PATH', '')
		if sys.platform[:3] == 'win':
			PATH = PATH.split(';')
		else:
			PATH = PATH.split(':')
		if path:
			PATH.extend(path)
		for base in PATH:
			path = os.path.join(base, filename)
			if os.path.exists(path):
				return path
		return None
		
	def escape (self, path):
		path = path.replace('\\', '\\\\').replace('"', '\\"')
		return path.replace('\'', '\\\'')

	def darwin_osascript (self, script):
		for line in script:
			#print line
			pass
		if type(script) == type([]):
			script = '\n'.join(script)
		p = subprocess.Popen(['/usr/bin/osascript'], shell = False,
				stdin = subprocess.PIPE, stdout = subprocess.PIPE,
				stderr = subprocess.STDOUT)
		p.stdin.write(script)
		p.stdin.flush()
		p.stdin.close()
		text = p.stdout.read()
		p.stdout.close()
		code = p.wait() 
		#print text
		return code, text

	def darwin_open_system (self, title, script, profile = None):
		script = [ line for line in script ]
		script.insert(0, 'clear')
		fp = open(self.temp, 'w')
		fp.write('#! /bin/sh\n')
		for line in script:
			fp.write(line + '\n')
		fp.close()
		os.chmod(self.temp, 0777)
		cmd = self.where('open')
		self.call([cmd, '-a', 'Terminal', self.temp])
		return 0, ''

	def darwin_open_terminal (self, title, script, profile = None):
		osascript = []
		command = []
		for line in script:
			if line.rstrip('\r\n\t ') == '':
				continue
			line = line.replace('\\', '\\\\')
			line = line.replace('"', '\\"')
			line = line.replace("'", "\\'")
			command.append(line)
		command.insert(0, 'clear')
		command = '; '.join(command)
		osascript.append('tell application "Terminal"')
		osascript.append('  if it is running then')
		osascript.append('     do script "%s; exit"'%command)
		osascript.append('  else')
		osascript.append('     do script "%s; exit" in window 1'%command)
		osascript.append('  end if')
		x = '  set current settings of selected tab of '
		x += 'window 1 to settings set "%s"'
		if profile != None:
			osascript.append(x%profile)
		osascript.append('  activate')
		osascript.append('end tell')
		return self.darwin_osascript(osascript)

	def darwin_open_iterm (self, title, script, profile = None):
		osascript = []
		command = []
		script = [ line for line in script ]
		if profile:
			script.insert(0, 'clear')
			script.insert(0, 'echo "\033]50;SetProfile=%s\a"'%profile)
		for line in script:
			if line.rstrip('\r\n\t ') == '':
				continue
			line = line.replace('\\', '\\\\\\\\')
			line = line.replace('"', '\\\\\\"')
			line = line.replace("'", "\\\\\\'")
			command.append(line)
		command = '; '.join(command)
		osascript.append('tell application "iTerm"')
		osascript.append('set myterm to (make new terminal)')
		osascript.append('tell myterm')
		osascript.append('set mss to (make new session at the end of sessions)')
		osascript.append('tell mss')
		if title:
			osascript.append('     set name to "%s"'%self.escape(title))
		osascript.append('     activate')
		osascript.append('     exec command "/bin/bash -c \\"%s\\""'%command)
		osascript.append('end tell')
		osascript.append('end tell')
		osascript.append('end tell')
		return self.darwin_osascript(osascript)
	
	def unix_escape (self, argument, force = False):
		argument = argument.replace('\\', '\\\\')
		argument = argument.replace('"', '\\"')
		argument = argument.replace("'", "\\'")
		return argument.replace(' ', '\\ ')

	def win32_escape (self, argument, force = False):
		if force == False and argument:
			clear = True
			for n in ' \n\r\t\v\"':
				if n in argument:
					clear = False
					break
			if clear:
				return argument
		output = '"'
		size = len(argument)
		i = 0
		while True:
			blackslashes = 0
			while (i < size and argument[i] == '\\'):
				i += 1
				blackslashes += 1
			if i == size:
				output += '\\' * (blackslashes * 2)
				break
			if argument[i] == '"':
				output += '\\' * (blackslashes * 2 + 1)
				output += '"'
			else:
				output += '\\' * blackslashes
				output += argument[i]
			i += 1
		output += '"'
		return output

	def _win32_load_kernel (self):
		if self.unix:
			return False
		import ctypes
		if not self.kernel32:
			self.kernel32 = ctypes.windll.LoadLibrary("kernel32.dll")
		if not self.textdata:
			self.textdata = ctypes.create_string_buffer('0' * 2048)
		ctypes.memset(self.textdata, 0, 2048)
		return True

	def win32_path_short (self, path):
		if not path:
			return ''
		path = os.path.abspath(path)
		if self.unix:
			return path
		self._win32_load_kernel()
		if not self.GetShortPathName:
			try:
				import ctypes
				self.GetShortPathName = self.kernel32.GetShortPathNameA
				args = [ ctypes.c_char_p, ctypes.c_char_p, ctypes.c_int32 ]
				self.GetShortPathName.argtypes = args
				self.GetShortPathName.restype = ctypes.c_uint32
			except: pass
		if not self.GetShortPathName:
			return path
		retval = self.GetShortPathName(path, self.textdata, 2048)
		shortpath = self.textdata.value
		if retval <= 0:
			import ctypes
			print 'ERROR(%d): %s'%(ctypes.GetLastError(), path)
			return ''
		return shortpath

	def win32_path_full (self, path):
		if not path:
			return ''
		path = os.path.abspath(path)
		if self.unix:
			return path
		self._win32_load_kernel()
		if not self.GetFullPathName:
			try:
				import ctypes
				self.GetFullPathName = self.kernel32.GetFullPathNameA
				args = [ ctypes.c_char_p, ctypes.c_int32, ctypes.c_char_p ]
				self.GetFullPathName.argtypes = arg + [ctypes.c_char_p]
				self.GetFullPathName.restype = ctypes.c_uint32
			except: pass
		if not self.GetFullPathName:
			return path
		retval = self.GetFullPathName(path, 2048, self.textdata, None)
		fullpath = self.textdata.value
		if retval <= 0:
			return ''
		return fullpath

	# win32 get long pathname
	def win32_path_long (self, path):
		if not path:
			return ''
		path = os.path.abspath(path)
		if self.unix:
			return path
		self._win32_load_kernel()
		if not self.GetLongPathName:
			try:
				import ctypes
				self.GetLongPathName = self.kernel32.GetLongPathNameA
				args = [ ctypes.c_char_p, ctypes.c_char_p, ctypes.c_int32 ]
				self.GetLongPathName.argtypes = arg
				self.GetLongPathName.restype = ctypes.c_uint32
			except: pass
		if not self.GetLongPathName:
			return path
		retval = self.GetLongPathName(path, self.textdata, 2048)
		longpath = self.textdata.value
		if retval <= 0:
			return ''
		return longpath

	def win32_shell_execute (self, op, filename, parameters, cwd = None):
		if self.unix:
			return False
		if not cwd:
			cwd = os.getcwd()
		self._win32_load_kernel()
		if not self.ShellExecute:
			try:
				import ctypes
				self.shell32 = ctypes.windll.LoadLibrary('shell32.dll')
				self.ShellExecute = self.shell32.ShellExecuteA
				args = [ ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p ]
				args+= [ ctypes.c_char_p, ctypes.c_char_p, ctypes.c_int32 ]
				self.ShellExecute.argtypes = args
				self.ShellExecute.restype = ctypes.wintypes.HINSTANCE
			except: pass
		if not self.ShellExecute:
			return False
		nShowCmd = 5
		self.ShellExecute(None, op, filename, parameters, cwd, nShowCmd)
		return True
	
	# win32 correct casing path: c:/windows -> C:\Windows
	def win32_path_casing (self, path):
		if not path:
			return ''
		path = os.path.abspath(path)
		if self.unix:
			return path
		path = path[:1].upper() + path[1:]
		return self.win32_path_long(self.win32_path_short(path))

	# start cmd.exe in a new window and execute script
	def win32_open_console (self, title, script, profile = None):
		fp = open(self.temp, 'w')
		fp.write('@echo off\n')
		if title:
			fp.write('title %s\n'%self.win32_escape(title))
		for line in script:
			fp.write(line + '\n')
		fp.close()
		fp = None
		pathname = self.win32_path_short(self.temp)
		os.system('start cmd /C %s'%(pathname))
		return 0

	# search bash for windows available ?
	def win32_wsl_locate (self):
		if not self.win32_detect_win10():
			return None
		root = os.environ.get('SystemRoot', None)
		if not root:
			return None
		system32 = os.path.join(root, 'System32')
		bash = os.path.join(system32, 'bash.exe')
		if os.path.exists(bash):
			return bash
		system32 = os.path.join(root, 'SysNative')
		bash = os.path.join(system32, 'bash.exe')
		if os.path.exists(bash):
			return bash
		return None

	def win32_reg_read (self, keyname, path):
		try:
			import _winreg
			mode = _winreg.KEY_READ | _winreg.KEY_WOW64_64KEY
			key = _winreg.OpenKey(keyname, path, 0, mode)
			count = _winreg.QueryInfoKey(key)[0]
		except:
			return None
		data = {}
		for i in range(count):
			try:
				name, value, tt = _winreg.EnumValue(key, i)
			except OSError as e:
				break
			data[name] = (tt, value) 
		return data

	def win32_detect_win10 (self):
		try:
			import _winreg
			path = r'SOFTWARE\Microsoft\Windows NT\CurrentVersion'
			data = self.win32_reg_read(_winreg.HKEY_LOCAL_MACHINE, path)
		except:
			return False
		version = data.get('CurrentMajorVersionNumber', (0, 0))
		if version[1] >= 10:
			return True
		return False

	def darwin_open_xterm (self, title, script, profile = None):
		command = []
		for line in script:
			if line.rstrip('\r\n\t ') == '':
				continue
			line = line.replace('\\', '\\\\')
			line = line.replace('"', '\\"')
			line = line.replace("'", "\\'")
			command.append(line)
		command = '; '.join(command)
		if title:
			command = 'xterm -T "%s" -e "%s" &'%(title, command)
		else:
			command = 'xterm -e "%s" &'%(command)
		subprocess.call(['/bin/sh', '-c', command])
		return 0

	def linux_open_xterm (self, title, script, profile = None):
		command = []
		for line in script:
			if line.rstrip('\r\n\t ') == '':
				continue
			line = line.replace('\\', '\\\\')
			line = line.replace('"', '\\"')
			line = line.replace("'", "\\'")
			command.append(line)
		command = '; '.join(command)
		cmdline = self.where('xterm') + ' '
		if title:
			title = self.escape(title)
			cmdline += '-T "%s" '%title
		cmdline += '-e "%s" '%command
		os.system(cmdline + ' & ')
		return 0

	def linux_open_gnome (self, title, script, profile = None):
		command = []
		for line in script:
			if line.rstrip('\r\n\t ') == '':
				continue
			line = line.replace('\\', '\\\\')
			line = line.replace('"', '\\"')
			line = line.replace("'", "\\'")
			command.append(line)
		command = '; '.join(command)
		command = '%s -c \"%s\"'%(self.where('bash'), command)
		cmdline = self.where('gnome-terminal') + ' '
		if title:
			title = self.escape(title and title or '')
			cmdline += '-t "%s" '%title
		if profile:
			cmdline += '--window-with-profile="%s" '%profile
		cmdline += ' --command=\'%s\''%command
		os.system(cmdline)
		return 0

	def cygwin_open_cmd (self, title, script, profile = None):
		temp = os.environ.get('TEMP', os.environ.get('TMP', '/tmp'))
		filename = os.path.split(self.temp)[-1]
		cwd = os.getcwd()
		fp = open(os.path.join(temp, filename), 'w')
		fp.write('@echo off\n')
		if title:
			fp.write('title %s\n'%self.win32_escape(title))
		for line in script:
			fp.write(line + '\n')
		fp.close()
		fp = None
		command = 'cygstart cmd /C %s'%(filename)
		# print script
		p = subprocess.Popen(['cygstart', 'cmd', '/C', filename], cwd = temp)
		p.wait()
		return 0

	def cygwin_write_script (self, filename, script):
		fp = open(filename, 'w')
		fp.write('#! /bin/sh\n')
		for line in script:
			fp.write('%s\n'%line)
		fp.close()
		fp = None
		return 0

	def cygwin_win_path (self, path):
		code, stdout, stderr = self.call(['cygpath', '-w', path])
		return stdout.strip('\r\n')

	def cygwin_open_bash (self, title, script, profile = None):
		filename = os.path.split(self.temp)[-1]
		scriptname = os.path.join('/tmp', filename)
		script = [ n for n in script ]
		script.insert(0, 'cd %s'%self.unix_escape(os.getcwd()))
		self.cygwin_write_script(scriptname, script)
		command = ['cygstart', self.cyg2win('/bin/bash')]
		if profile == 'login':
			command.append('--login')
		self.call(command + ['-i', scriptname])
		return 0
	
	def cygwin_open_mintty (self, title, script, profile = None):
		filename = os.path.split(self.temp)[-1]
		scriptname = os.path.join('/tmp', filename)
		script = [ n for n in script ]
		script.insert(0, 'cd %s'%self.unix_escape(os.getcwd()))
		self.cygwin_write_script(scriptname, script)
		command = ['cygstart']
		command += [self.cyg2win('/bin/mintty')]
		# if  title:
			# command += ['-t', title]
		if os.path.exists('/Cygwin-Terminal.ico'):
			command += ['-i', '/Cygwin-Terminal.ico']
		command += ['-e', 'bash']
		if profile == 'login':
			command.append('--login')
		command.extend(['-i', scriptname])
		self.call(command)
		return 0

	# convert windows path to cygwin path
	def win2cyg (self, path):
		path = os.path.abspath(path)
		return '/cygdrive/%s%s'%(path[0], path[2:].replace('\\', '/'))

	# convert cygwin path to windows path
	def cyg2win (self, path):
		if path[1:2] == ':':
			return os.path.abspath(path)
		if path.lower().startswith('/cygdrive/'):
			path = path[10] + ':' + path[11:]
			return path
		if not path.startswith('/'):
			raise Exception('cannot convert path: %s'%path)
		if sys.platform == 'cygwin':
			return self.cygwin_win_path(path)
		if not self.cygwin:
			raise Exception('cannot find cygwin root')
		return os.path.abspath(os.path.join(self.cygwin, path[1:]))

	# convert windows path to wsl path
	def win2wsl (self, path):
		save = path
		path = self.win32_path_casing(path)
		if not path:
			return ''
		if len(path) < 3:
			return ''
		return '/mnt/%s%s'%(path[0].lower(), path[2:].replace('\\', '/'))
	
	# use bash in cygwin to execute script and return output
	def win32_cygwin_execute (self, script, login = False):
		if not self.cygwin:
			return -1, None
		if not os.path.exists(self.cygwin):
			return -2, None
		if not os.path.exists(os.path.join(self.cygwin, 'bin/sh.exe')):
			return -3, None
		bash = os.path.join(self.cygwin, 'bin/bash')
		filename = os.path.split(self.temp)[-1]
		tempfile = os.path.join(self.cygwin, 'tmp/' + filename)
		fp = open(tempfile, 'wb')
		fp.write('#! /bin/sh\n')
		path = self.win2cyg(os.getcwd())
		fp.write('cd %s\n'%self.unix_escape(path))
		for line in script:
			fp.write('%s\n'%line)
		fp.close()
		command = [bash]
		if login:
			command.append('--login')
		command.extend(['-i', '/tmp/' + filename])
		p = subprocess.Popen(command, shell = False,
				stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
		text = p.stdout.read()
		p.stdout.close()
		code = p.wait()
		return code, text

	# use bash in cygwin to execute script and output to current cmd window
	def win32_cygwin_now (self, script, login = False):
		if not self.cygwin:
			return -1, None
		if not os.path.exists(self.cygwin):
			return -2, None
		if not os.path.exists(os.path.join(self.cygwin, 'bin/sh.exe')):
			return -3, None
		bash = os.path.join(self.cygwin, 'bin/bash')
		filename = os.path.split(self.temp)[-1]
		tempfile = os.path.join(self.cygwin, 'tmp/' + filename)
		fp = open(tempfile, 'wb')
		fp.write('#! /bin/sh\n')
		if not login:
			fp.write('export PATH=/usr/local/bin:/usr/bin\n')
		path = self.win2cyg(os.getcwd())
		fp.write('cd %s\n'%self.unix_escape(path))
		for line in script:
			fp.write('%s\n'%line)
		fp.close()
		command = [bash]
		if login:
			command.append('--login')
		if sys.stdout.isatty() and (not self.filter):
			if not self.encoding:
				command.extend(['-i'])
		command.extend(['/tmp/' + filename])
		if (not self.filter) and (not self.encoding):
			subprocess.call(command, shell = False)
		else:
			self.filter_mode = 'cygwin'
			p = subprocess.Popen(
					command,
					shell = False, 
					stdin = subprocess.PIPE,
					stderr = subprocess.STDOUT,
					stdout = subprocess.PIPE)
			stdout = p.stdout
			p.stdin.close()
			while True:
				text = stdout.readline()
				if text == '':
					break
				if self.encoding:
					text = text.decode(self.encoding, 'ignore')
				if self.filter:
					text = self.filter(text)
				if not text:
					continue
				text = text.rstrip('\r\n\t ')
				sys.stdout.write(text + '\n')
				sys.stdout.flush()
		try:
			os.remove(tempfile)
		except:
			pass
		return 0

	# open bash of cygwin in a new window and execute script
	def win32_cygwin_open_bash (self, title, script, profile = None):
		if not self.cygwin:
			return -1, None
		if not os.path.exists(self.cygwin):
			return -2, None
		if not os.path.exists(os.path.join(self.cygwin, 'bin/sh.exe')):
			return -3, None
		bash = os.path.join(self.cygwin, 'bin/bash.exe')
		filename = os.path.split(self.temp)[-1]
		tempfile = os.path.join(self.cygwin, 'tmp/' + filename)
		fp = open(tempfile, 'wb')
		fp.write('#! /bin/sh\n')
		path = self.win2cyg(os.getcwd())
		fp.write('cd %s\n'%self.unix_escape(path))
		for line in script:
			fp.write('%s\n'%line)
		fp.close()
		short_bash = self.win32_path_short(bash)
		command = 'start %s '%short_bash
		command += '--login -i /tmp/' + filename
		os.system(command)
		return 0

	# open mintty of cygwin in a new window and execute script
	def win32_cygwin_open_mintty (self, title, script, profile = None):
		if not self.cygwin:
			return -1, None
		if not os.path.exists(self.cygwin):
			return -2, None
		if not os.path.exists(os.path.join(self.cygwin, 'bin/sh.exe')):
			return -3, None
		mintty = os.path.join(self.cygwin, 'bin/mintty.exe')
		filename = os.path.split(self.temp)[-1]
		tempfile = os.path.join(self.cygwin, 'tmp/' + filename)
		fp = open(tempfile, 'wb')
		fp.write('#! /bin/sh\n')
		path = self.win2cyg(os.getcwd())
		fp.write('cd %s\n'%self.unix_escape(path))
		for line in script:
			fp.write('%s\n'%line)
		fp.close()
		shortname = self.win32_path_short(mintty)
		command = 'start %s '%shortname
		if os.path.exists(os.path.join(self.cygwin, 'Cygwin-Terminal.ico')):
			command += '-i /Cygwin-Terminal.ico '
		if title:
			command += '-t "%s" '%title
		command += '-e /usr/bin/bash '
		if profile == 'login' or True:
			command += '--login '
		command += '-i /tmp/' + filename
		# print command
		os.system(command)
		return 0

	# open bash for windows (needs windows 10) and execute script
	def win32_wsl_now (self, title, script, profile = None):
		bash = self.win32_wsl_locate()
		if not bash:
			return -1, None
		from tempfile import NamedTemporaryFile as OpenTmp
		with OpenTmp(prefix = 'bash_', suffix = '.sh', delete = False) as t:
			t.write('#! /bin/bash\n')
			path = self.win2wsl(os.getcwd())
			t.write('cd %s\n'%self.unix_escape(path))
			for line in script:
				t.write('%s\n'%line)
			t.close()
			tmpname = t.name
			if sys.stdout.isatty() and (not self.filter):
				command = '%s '%bash
				command += '--login -i "' + self.win2wsl(t.name) + '"'
				os.system(command)
			else:
				args = [bash, '--login', self.win2wsl(t.name)]
				p = subprocess.Popen(
						args,
						shell = False, 
						stdin = subprocess.PIPE,
						stderr = subprocess.STDOUT,
						stdout = subprocess.PIPE)
				stdout = p.stdout
				p.stdin.close()
				self.filter_mode = 'wsl'
				while True:
					text = stdout.readline()
					if text == '':
						break
					if self.encoding:
						text = text.decode(self.encoding, 'ignore')
					if self.filter:
						text = self.filter(text)
					if not text:
						continue
					text = text.rstrip('\n\r')
					sys.stdout.write(text + '\n')
					sys.stdout.flush()
			try:
				os.remove(t.name)
			except:
				pass
		return 0

	# open bash for windows in a new terminal window
	def win32_wsl_open_bash (self, title, script, profile = None):
		bash = self.win32_wsl_locate()
		if not bash:
			return -1, None
		fp = open(self.temp, 'wb')
		fp.write('#! /bin/bash\n')
		path = self.win2wsl(os.getcwd())
		fp.write('cd %s\n'%self.unix_escape(path))
		for line in script:
			fp.write('%s\n'%line)
		fp.close()
		command = '--login -i "' + self.win2wsl(self.temp) + '"'
		self.win32_shell_execute('open', bash, command, os.getcwd())
		return 0


#----------------------------------------------------------------------
# die
#----------------------------------------------------------------------
def die(message):
	sys.stderr.write('%s\n'%message)
	sys.stderr.flush()
	sys.exit(0)
	return 0



#----------------------------------------------------------------------
# terminal class
#----------------------------------------------------------------------
class Terminal (object):

	def __init__ (self):
		self.config = configure()
		self.unix = sys.platform[:3] != 'win' and True or False
		self.cygwin_login = False
		self.post_command = ''
	
	def __win32_open_terminal (self, terminal, title, script, profile):
		if terminal in ('', 'system', 'dos', 'win', 'windows', 'command', 'cmd'):
			self.config.win32_open_console(title, script)
		elif terminal in ('cygwin', 'bash', 'mintty', 'cygwin-mintty', 'cygwinx'):
			if not self.config.cygwin:
				die('please give cygwin path in profile')
				return -1
			if not os.path.exists(self.config.cygwin):
				die('can not find cygwin in: %s'%self.config.cygwin)
				return -2
			if not os.path.exists(os.path.join(self.config.cygwin, 'bin/sh.exe')):
				die('can not verify cygwin in: %s'%self.config.cygwin)
				return -3
			if terminal in ('cygwin', 'bash'):
				self.config.win32_cygwin_open_bash(title, script, profile)
			elif terminal in ('cygwin-silent', 'cygwin-shell', 'cygwinx'):
				self.config.win32_cygwin_now(script, False)
			else:
				self.config.win32_cygwin_open_mintty(title, script, profile)
		elif terminal in ('wsl', 'wslx', 'ubuntu', 'ubuntux'):
			if not self.config.win32_detect_win10():
				die('only supported on windows 10')
				return -1
			if not self.config.win32_wsl_locate():
				die('can not find bash.exe, please install WSL')
				return -2
			if terminal in ('wsl', 'ubuntu'):
				self.config.win32_wsl_open_bash(title, script, profile)
			else:
				self.config.win32_wsl_now(title, script, profile)
		else:
			die('bad terminal name: %s'%terminal)
			return -4
		return 0

	def __cygwin_open_terminal (self, terminal, title, script, profile):
		if terminal in ('dos', 'win', 'cmd', 'command', 'system', 'windows'):
			self.config.cygwin_open_cmd(title, script, profile)
		elif terminal in ('bash', 'sh', '', 'default'):
			self.config.cygwin_open_bash(title, script, profile)
		elif terminal in ('mintty', 'cygwin-mintty'):
			if not title:
				title = 'Cygwin Mintty'
			self.config.cygwin_open_mintty(title, script, profile)
		else:
			die('bad terminal name: %s'%terminal)
			return -1
		return 0

	def __darwin_open_terminal (self, terminal, title, script, profile):
		if terminal in ('', 'system', 'default'):
			if (not profile) and (not title):
				self.config.darwin_open_system(title, script, profile)
			else:
				self.config.darwin_open_terminal(title, script, profile)
		elif terminal in ('terminal',):
			self.config.darwin_open_terminal(title, script, profile)
		elif terminal in ('iterm', 'iterm2'):
			self.config.darwin_open_iterm(title, script, profile)
		elif terminal in ('xterm', 'x'):
			self.config.darwin_open_xterm(title, script, profile)
		else:
			die('bad terminal name: %s'%terminal)
			return -1
		return 0

	def __linux_open_terminal (self, terminal, title, script, profile):
		if terminal in ('xterm', '', 'default', 'system', 'x'):
			self.config.linux_open_xterm(title, script, profile)
		elif terminal in ('gnome', 'gnome-terminal'):
			self.config.linux_open_gnome(title, script, profile)
		else:
			die('bad terminal name: %s'%terminal)
			return -1
		return 0

	def open_terminal (self, terminal, title, script, profile):
		if terminal == None:
			terminal = ''
		if sys.platform[:3] == 'win':
			if script == None:
				names = ['cmd (default)', 'cygwin', 'mintty', 'cygwinx']
				names += ['wsl (windows subsystem for linux)', 'wslx']
				return names
			return self.__win32_open_terminal(terminal, title, script, profile)
		elif sys.platform == 'cygwin':
			if script == None:
				return ('bash (default)', 'mintty', 'windows')
			return self.__cygwin_open_terminal(terminal, title, script, profile)
		elif sys.platform == 'darwin':
			if script == None:
				return ('terminal (default)', 'iterm')
			return self.__darwin_open_terminal(terminal, title, script, profile)
		else:
			if script == None:
				return ('xterm (default)', 'gnome-terminal')
			return self.__linux_open_terminal(terminal, title, script, profile)
		return 0

	def check_windows (self, terminal):
		if sys.platform[:3] == 'win':
			if terminal == None:
				return True
			if terminal in ('', 'system', 'dos', 'win', 'windows', 'command', 'cmd'):
				return True
		elif sys.platform == 'cygwin':
			if terminal in ('dos', 'win', 'cmd', 'command', 'system', 'windows'):
				return True
		return False
	
	def execute (self, terminal, title, script, cwd, wait, profile):
		lines = [ line for line in script ]
		windows = self.check_windows(terminal)
		script = []
		if cwd == None:
			cwd = os.getcwd()
		if terminal == None:
			terminal = ''
		if sys.platform[:3] == 'win' and cwd[1:2] == ':':
			if terminal in ('', 'system', 'dos', 'win', 'windows', 'command', 'cmd'):
				script.append(cwd[:2])
				script.append('cd "%s"'%cwd)
			elif terminal in ('cygwin', 'bash', 'mintty', 'cygwin-mintty', 'cygwinx'):
				script.append('cd "%s"'%self.config.win2cyg(cwd))
			else:
				path = self.config.win2wsl(cwd)
				script.append('cd "%s"'%path)
		elif sys.platform == 'cygwin':
			if terminal in ('dos', 'win', 'cmd', 'command', 'system', 'windows'):
				path = self.config.cyg2win(os.path.abspath(cwd))
				script.append(path[:2])
				script.append('cd "%s"'%path)
			else:
				script.append('cd "%s"'%cwd)
		else:
			script.append('cd "%s"'%cwd)
		script.extend(lines)
		if wait:
			if windows:
				script.append('pause')
			else:
				script.append('read -n1 -rsp "press any key to confinue ..."')
		if self.post_command:
			script.append(self.post_command)
		return self.open_terminal(terminal, title, script, profile)

	def run_command (self, terminal, title, command, cwd, wait, profile):
		script = [ command ]
		return self.execute(terminal, title, script, cwd, wait, profile)

	def run_tee (self, command, teename, shell = False, wait = False):
		args = []
		for n in command:
			if sys.platform[:3] == 'win':
				n = self.config.win32_escape(n)
			else:
				n = self.config.unix_escape(n)
			args.append(n)
		import subprocess
		p = subprocess.Popen(args, stdin = None, stdout = subprocess.PIPE, \
				stderr = subprocess.STDOUT, shell = shell)
		if sys.platform[:3] != 'win' and '~' in teename:
			teename = os.path.expanduser(teename)
		f = open(teename, 'w')
		while True:
			text = p.stdout.readline()
			if text in ('', None):
				break
			f.write(text)
			f.flush()
			sys.stdout.write(text)
			sys.stdout.flush()
		p.stdout.close()
		p.wait()
		f.close()
		if wait:
			if sys.platform[:3] == 'win':
				os.system('pause')
			else:
				os.system('read -n1 -rsp "press any key to continue ..."')
		return 0

	def set_filter (self, name):
		if (not name) or name in ('none', 'no', 'null'):
			self.config.filter = None
			return 0
		if name == 'gcc':
			self.config.filter = self.__filter_auto
			return 0
		return 0

	def __filter_auto (self, text):
		if self.config.filter_mode == 'cygwin':
			if text.startswith('/cygdrive/') and len(text) >= 12:
				return text[10] + ':' + text[11:]
		elif self.config.filter_mode == 'wsl':
			if text.startswith('/mnt/') and len(text) >= 7:
				if text[6] == '/':
					return text[5] + ':' + text[6:]
		return text



#----------------------------------------------------------------------
# main routine
#----------------------------------------------------------------------
def main(argv = None, shellscript = None):
	if argv == None:
		argv = sys.argv
	argv = [ n for n in argv ]
	args = []
	cmds = []
	skip = ['-h', '--help', '-w', '-s']
	index = 1
	stdin = False
	if len(argv) > 0:
		args.append(argv[0])
	while index < len(argv):
		data = argv[index]
		if data in ('-s', '--stdin'):
			stdin = True
		if data[:2] == '--':
			args.append(data)
			index += 1
		elif data in skip:
			args.append(data)
			index += 1
		elif data[:1] == '-':
			args.append(data)
			index += 1
			if index >= len(argv):
				break
			args.append(argv[index])
			index += 1
		else:
			cmds = argv[index:]
			break
	terminal = Terminal()
	help = terminal.open_terminal('', '', None, '')
	text = 'available terminal: ' 
	text += ', '.join(help)
	import optparse
	if len(cmds) == 0 and len(args) > 0 and stdin == False:
		args.append('--help')
	elif stdin and len(cmds) > 0 and len(args) > 1:
		args.append('--help')
	desc = 'Execute program in a new terminal window'
	parser = optparse.OptionParser( \
			usage = 'usage: %prog [options] command [args ...]',
			version = '0.0.0',
			description = desc)
	parser.add_option('-t', '--title', dest = 'title', default = None,
			help = 'title of new window')
	parser.add_option('-m', '--terminal', dest = 'terminal', default = None, 
			help = text)
	parser.add_option('-p', '--profile', dest = 'profile', default = None,
			help = 'terminal profile')
	parser.add_option('-d', '--cwd', dest = 'cwd', default = '',
			help = 'working directory')
	parser.add_option('-w', '--wait', dest = 'wait', default = False,
			action = 'store_true', help = 'wait before exit')
	parser.add_option('-o', '--post', dest = 'post', default = '',
			help = 'post action')
	parser.add_option('-s', '--stdin', dest = 'stdin', default = False,
			action = 'store_true', help = 'read commands from stdin')
	parser.add_option('-e', '--tee', dest = 'tee', default = '',
			help = 'redirect output to file')
	if sys.platform[:3] == 'win':
		parser.add_option('-c', '--cygwin', dest = 'cygwin', default = '',
				help = 'cygwin home path when using cygwin terminal')
		parser.add_option('-f', '--filter', dest = 'filter', default = None,
				help = 'text filter for cygwinx/wslx: none (default), auto')
		parser.add_option('-n', '--encoding', dest = 'encoding', default = None,
				help = 'encoding for cygwinx/wslx: none (default), utf-8')
	opts, _ = parser.parse_args(args)
	if not opts.cwd:
		opts.cwd = os.getcwd()
	command = []
	if sys.platform[:3] == 'win':
		cygwin = opts.cygwin
		terminal.config.cygwin = cygwin
		if opts.encoding:
			if not opts.encoding in ('none', 'null', 'no'):
				terminal.config.encoding = opts.encoding
		terminal.set_filter(opts.filter)
	if shellscript:
		script = [ line for line in shellscript ]
		if opts.post:
			terminal.post_command = opts.post
		terminal.execute(opts.terminal, opts.title, script,
				opts.cwd, opts.wait, opts.profile)
	elif opts.stdin:
		text = ''
		while True:
			hr = sys.stdin.read()
			if hr == '': break
			text += hr
		script = text.split('\n')
		if opts.post:
			terminal.post_command = opts.post
		terminal.execute(opts.terminal, opts.title, script,
				opts.cwd, opts.wait, opts.profile)
	elif opts.tee != '':
		shell = False
		if sys.platform[:3] == 'win':
			shell = True
		terminal.run_tee(cmds, opts.tee, shell, opts.wait)
	else:
		for n in cmds:
			if terminal.check_windows(opts.terminal):
				n = terminal.config.win32_escape(n)
			else:
				n = terminal.config.unix_escape(n)
			command.append(n)
		command = ' '.join(command)
		if opts.post:
			terminal.post_command = opts.post
		terminal.run_command(opts.terminal, opts.title, command, 
			opts.cwd, opts.wait, opts.profile)
	return 0


#----------------------------------------------------------------------
# run clever for vimmake
#----------------------------------------------------------------------
def vimtool():
	
	return 0


#----------------------------------------------------------------------
# testing casen
#----------------------------------------------------------------------
if __name__ == '__main__':
	def test1():
		cfg = configure()
		cfg.darwin_open_terminal('111', ['ls -la /', 'read -n1 -rsp press\\ any\\ key\\ to\\ continue\\ ...', 'echo "fuck you"'])

	def test2():
		args = [ 'terminal', '-h' ]
		#args = [ 'terminal', '-w', '--terminal=cmd', '--cwd=e:/lesson', '--cygwin=d:/linux', '--title=fuck', 'DIR']
		main(args)
		return 0

	def test3():
		args = [ 'terminal', '-w', '--terminal=cmd', '--stdin' ]
		main(args)
		return 0

	def test4():
		cfg = configure()
		# cfg.win32_wsl_now('', ['echo 1234', 'ls -la'])
		cfg.win32_wsl_open_bash('', ['echo 1234', 'ls -la', 'sleep 3'])
		# cfg.win32_shell_execute('open', cfg.win32_wsl_locate(), '--login -i -c "sleep 5"')
	
	# test4()
	main()



