#! /usr/bin/env python2
# -*- coding: utf-8 -*-
#======================================================================
#
# escope.py - 
#
# Created by skywind on 2016/11/02
# Last change: 2016/11/02 18:12:09
#
#======================================================================
import sys
import time
import os
import json
import hashlib
import datetime

if sys.version_info[0] >= 3:
	raise "Must be using Python 2"


#----------------------------------------------------------------------
# execute and capture
#----------------------------------------------------------------------
def execute(args, shell = False, capture = False):
	import sys, os
	parameters = []
	if type(args) in (type(''), type(u'')):
		import shlex
		cmd = args
		if sys.platform[:3] == 'win':
			ucs = False
			if type(cmd) == type(u''):
				cmd = cmd.encode('utf-8')
				ucs = True
			args = shlex.split(cmd.replace('\\', '\x00'))
			args = [ n.replace('\x00', '\\') for n in args ]
			if ucs:
				args = [ n.decode('utf-8') for n in args ]
		else:
			args = shlex.split(cmd)
	for n in args:
		if sys.platform[:3] != 'win':
			replace = { ' ':'\\ ', '\\':'\\\\', '\"':'\\\"', '\t':'\\t', \
				'\n':'\\n', '\r':'\\r' }
			text = ''.join([ replace.get(ch, ch) for ch in n ])
			parameters.append(text)
		else:
			if (' ' in n) or ('\t' in n) or ('"' in n): 
				parameters.append('"%s"'%(n.replace('"', ' ')))
			else:
				parameters.append(n)
	cmd = ' '.join(parameters)
	if sys.platform[:3] == 'win' and len(cmd) > 255:
		shell = False
	if shell and (not capture):
		os.system(cmd)
		return ''
	elif (not shell) and (not capture):
		import subprocess
		if 'call' in subprocess.__dict__:
			subprocess.call(args)
			return ''
	import subprocess
	if 'Popen' in subprocess.__dict__:
		if sys.platform[:3] != 'win' and shell:
			p = None
			stdin, stdouterr = os.popen4(cmd)
		else:
			p = subprocess.Popen(args, shell = shell,
					stdin = subprocess.PIPE, stdout = subprocess.PIPE, 
					stderr = subprocess.STDOUT)
			stdin, stdouterr = (p.stdin, p.stdout)
	else:
		p = None
		stdin, stdouterr = os.popen4(cmd)
	text = stdouterr.read()
	stdin.close()
	stdouterr.close()
	if p: p.wait()
	if not capture:
		sys.stdout.write(text)
		sys.stdout.flush()
		return ''
	return text


#----------------------------------------------------------------------
# redirect process output to reader(what, text)
#----------------------------------------------------------------------
def redirect(args, reader, combine = True):
	import subprocess
	if 'Popen' in subprocess.__dict__:
		p = subprocess.Popen(args, shell = False,
			stdin = subprocess.PIPE, stdout = subprocess.PIPE,
			stderr = combine and subprocess.STDOUT or subprocess.PIPE)
		stdin, stdout, stderr = p.stdin, p.stdout, p.stderr
		if combine: stderr = None
	else:
		p = None
		if combine == False:
			stdin, stdout, stderr = os.popen3(cmd)
		else:
			stdin, stdout = os.popen4(cmd)
			stderr = None
	stdin.close()
	while 1:
		text = stdout.readline()
		if text == '':
			break
		reader('stdout', text)
	while stderr != None:
		text = stderr.readline()
		if text == '':
			break
		reader('stderr', text)
	stdout.close()
	if stderr: stderr.close()
	retcode = None
	if p:
		retcode = p.wait()
	return retcode


#----------------------------------------------------------------------
# configure
#----------------------------------------------------------------------
class configure (object):

	def __init__ (self, ininame = None):
		self.ininame = ininame
		self.unix = (sys.platform[:3] != 'win') and 1 or 0
		self.config = {}
		self.rc = None
		self._search_config()
		self._search_cscope()
		self._search_gtags()
		self._search_pycscope()
		self._search_rc()
		rc = self.option('default', 'rc', None)
		if rc and os.path.exists(rc):
			self.rc = self.abspath(rc)
		self.config['default']['rc'] = rc
		self.has_cscope = (self.option('default', 'cscope') != None)
		self.has_gtags = (self.option('default', 'gtags') != None)
		self.has_pycscope = (self.option('default', 'pycscope') != None)
		self.exename = {}
		if self.has_cscope:
			cscope = self.option('default', 'cscope')
			if self.unix:
				self.exename['cscope'] = os.path.join(cscope, 'cscope')
			else:
				self.exename['cscope'] = os.path.join(cscope, 'cscope.exe')
		if self.has_gtags:
			gtags = self.option('default', 'gtags')
			if self.unix:
				f = lambda n: os.path.join(gtags, n)
			else:
				g = lambda n: os.path.join(gtags, n + '.exe')
				f = lambda n: os.path.abspath(g(n))
			self.exename['gtags'] = f('gtags')
			self.exename['global'] = f('global')
			self.exename['gtags-cscope'] = f('gtags-cscope')
		if self.has_pycscope:
			pycscope = self.option('default', 'pycscope')
			if self.unix:
				pycscope = os.path.join(pycscope, 'pycscope')
			else:
				pycscope = os.path.join(pycscope, 'pycscope.exe')
			self.exename['pycscope'] = pycscope
		self.GetShortPathName = None
		self.database = None

	# search escope config
	def _search_config (self):
		self.config = {}
		self.config['default'] = {}
		if self.ininame and os.path.exists(self.ininame):
			self._read_ini(self.ininame)
			return 0
		fullname = os.path.abspath(__file__)
		testname = os.path.splitext(fullname)[0] + '.ini'
		if os.path.exists(testname):
			self._read_ini(testname)
			self.ininame = testname
		if self.unix:
			self._read_ini('/etc/escope.ini')
			self._read_ini('/usr/local/etc/escope.ini')
		self._read_ini(os.path.expanduser('~/.config/escope.ini'))
		return 0

	def _read_ini (self, filename):
		import ConfigParser
		if not os.path.exists(filename):
			return -1
		fp = open(filename, 'r')
		cp = ConfigParser.ConfigParser(fp)
		for sect in cp.sections():
			if not sect in self.config:
				self.config[sect] = {}
			for key, value in cp.items(sect):
				self.config[sect.lower()][key.lower()] = value
		fp.close()
		return 0

	# read option 
	def option (self, sect, item, default = None):
		if not sect in self.config:
			return default
		return self.config[sect].get(item, default)

	# search cscope
	def _search_cscope (self):
		def _test_cscope(path):
			if not os.path.exists(path):
				return False
			if sys.platform[:3] != 'win':
				if not os.path.exists(os.path.join(path, 'cscope')):
					return False
			else:
				if not os.path.exists(os.path.join(path, 'cscope.exe')):
					return False
			return True
		cscope = self.option('default', 'cscope')
		if cscope:
			if _test_cscope(cscope):
				self.config['default']['cscope'] = os.path.abspath(cscope)
				return 0
		self.config['default']['cscope'] = None
		cscope = os.path.abspath(os.path.dirname(__file__))
		if _test_cscope(cscope):
			self.config['default']['cscope'] = cscope
			return 0
		PATH = os.environ.get('PATH', '').split(self.unix and ':' or ';')
		for path in PATH:
			if _test_cscope(path):
				self.config['default']['cscope'] = os.path.abspath(path)
				return 0
		return -1

	# search gtags executables
	def _search_gtags (self):
		def _test_gtags(path):
			if not os.path.exists(path):
				return False
			if sys.platform[:3] != 'win':
				if not os.path.exists(os.path.join(path, 'gtags')):
					return False
				if not os.path.exists(os.path.join(path, 'global')):
					return False
				if not os.path.exists(os.path.join(path, 'gtags-cscope')):
					return False
			else:
				if not os.path.exists(os.path.join(path, 'gtags.exe')):
					return False
				if not os.path.exists(os.path.join(path, 'global.exe')):
					return False
				if not os.path.exists(os.path.join(path, 'gtags-cscope.exe')):
					return False
			return True
		gtags = self.option('default', 'gtags')
		if gtags:
			if _test_gtags(gtags):
				self.config['default']['gtags'] = os.path.abspath(gtags)
				return 0
		self.config['default']['gtags'] = None
		gtags = os.path.abspath(os.path.dirname(__file__))
		if _test_gtags(gtags):
			self.config['default']['gtags'] = gtags
			return 0
		PATH = os.environ.get('PATH', '').split(self.unix and ':' or ';')
		for path in PATH:
			if _test_gtags(path):
				self.config['default']['gtags'] = os.path.abspath(path)
				return 0
		return -1

	# search pycscope
	def _search_pycscope (self):
		def _test_pycscope(path):
			if not os.path.exists(path):
				return False
			if sys.platform[:3] != 'win':
				if not os.path.exists(os.path.join(path, 'pycscope')):
					return False
			else:
				if not os.path.exists(os.path.join(path, 'pycscope.exe')):
					return False
			return True
		pycscope = self.option('default', 'pycscope')
		if pycscope:
			if _test_pycscope(pycscope):
				pycscope = os.path.abspath(pycscope)
				self.config['default']['pycscope'] = pycscope
				return 0
		self.config['default']['pycscope'] = None
		pycscope = os.path.abspath(os.path.dirname(__file__))
		if _test_pycscope(pycscope):
			self.config['default']['pycscope'] = pycscope
			return 0
		PATH = os.environ.get('PATH', '').split(self.unix and ':' or ';')
		for path in PATH:
			if _test_pycscope(path):
				self.config['default']['pycscope'] = os.path.abspath(path)
				return 0
		return -1

	# abspath 
	def abspath (self, path, resolve = False):
		if path == None:
			return None
		if '~' in path:
			path = os.path.expanduser(path)
		path = os.path.abspath(path)
		if not self.unix:
			return path.lower().replace('\\', '/')
		if resolve:
			return os.path.abspath(os.path.realpath(path))
		return path

	# search gtags rc
	def _search_rc (self):
		rc = self.option('default', 'rc', None)
		if rc != None:
			rc = self.abspath(rc)
			if os.path.exists(rc):
				self.config['default']['rc'] = rc
				return 0
		self.config['default']['rc'] = None
		rc = self.abspath('~/.globalrc')
		if os.path.exists(rc):
			self.config['default']['rc'] = rc
			return 0
		if self.unix:
			rc = '/etc/gtags.conf'
			if os.path.exists(rc):
				self.config['default']['rc'] = rc
				return 0
			rc = '/usr/local/etc/gtags.conf'
			if os.path.exists(rc):
				self.config['default']['rc'] = rc
				return 0
		gtags = self.option('default', 'gtags')
		if gtags == None:
			return -1
		rc = os.path.join(gtags, '../share/gtags/gtags.conf')
		rc = self.abspath(rc)
		if os.path.exists(rc):
			self.config['default']['rc'] = rc
		return -1

	# short name in windows
	def pathshort (self, path):
		path = os.path.abspath(path)
		if self.unix:
			return path
		if not self.GetShortPathName:
			self.kernel32 = None
			self.textdata = None
			try:
				import ctypes
				self.kernel32 = ctypes.windll.LoadLibrary("kernel32.dll")
				self.textdata = ctypes.create_string_buffer('\000' * 1024)
				self.GetShortPathName = self.kernel32.GetShortPathNameA
				args = [ ctypes.c_char_p, ctypes.c_char_p, ctypes.c_int ]
				self.GetShortPathName.argtypes = args
				self.GetShortPathName.restype = ctypes.c_uint32
			except: pass
		if not self.GetShortPathName:
			return path
		retval = self.GetShortPathName(path, self.textdata, 1024)
		shortpath = self.textdata.value
		if retval <= 0:
			return ''
		return shortpath

	# recursion make directory
	def mkdir (self, path):
		path = os.path.abspath(path)
		if os.path.exists(path):
			return 0
		name = ''
		part = os.path.abspath(path).replace('\\', '/').split('/')
		if self.unix:
			name = '/'
		if (not self.unix) and (path[1:2] == ':'):
			part[0] += '/'
		for n in part:
			name = os.path.abspath(os.path.join(name, n))
			if not os.path.exists(name):
				os.mkdir(name)
		return 0

	# execute a gnu global executable
	def execute (self, name, args, capture = False, printcmd = False):
		if name in self.exename:
			name = self.exename[name]
		name = self.pathshort(name)
		#printcmd = True
		if printcmd:
			print [name] + args
		if not capture in (0, 1, True, False, None):
			return redirect([name] + args, capture)
		return execute([name] + args, False, capture)

	# initialize environment
	def init (self):
		if self.rc and os.path.exists(self.rc):
			os.environ['GTAGSCONF'] = os.path.abspath(self.rc)
		os.environ['GTAGSFORCECPP'] = '1'
		PATH = os.environ.get('PATH', '')
		gtags = self.option('default', 'gtags')
		if self.unix:
			if gtags: PATH = gtags + ':' + PATH
		else:
			if gtags: PATH = gtags + ';' + PATH
		os.environ['PATH'] = PATH
		database = self.option('default', 'database', None)
		if database:
			database = self.abspath(database, True)
		elif 'ESCOPE' in os.environ:
			escope = os.environ['ESCOPE']
			if not escope.lower() in (None, '', '/', '\\', 'c:/', 'c:\\'):
				database = self.abspath(escope)
		if database == None:
			database = self.abspath('~/.local/var/escope', True)
		if not os.path.exists(database):
			self.mkdir(database)
		if not os.path.exists(database):
			raise Exception('Cannot create database folder: %s'%database)
		self.database = database
		return 0

	# get project db path
	def pathdb (self, root):
		if (self.database == None) or (root == None):
			return None
		root = root.strip()
		root = self.abspath(root)
		hash = hashlib.md5(root).hexdigest().lower()
		hash = hash[:16]
		path = os.path.abspath(os.path.join(self.database, hash))
		return (self.unix) and path or path.replace('\\', '/')

	# load project desc
	def load (self, root):
		db = self.pathdb(root)
		if db == None:
			return None
		cfg = os.path.join(db, 'config.json')
		if not os.path.exists(cfg):
			return None
		fp = open(cfg, 'r')
		content = fp.read()
		fp.close()
		try:
			obj = json.loads(content)
		except:
			return None
		if type(obj) != type({}):
			return None
		return obj

	# save project desc
	def save (self, root, obj):
		db = self.pathdb(root)
		if db == None or type(obj) != type({}):
			return -1
		cfg = os.path.join(db, 'config.json')
		text = json.dumps(obj, indent = 4)
		fp = open(cfg, 'w')
		fp.write(text)
		fp.close()
		return 0

	def timestamp (self):
		return datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

	def strptime (self, text):
		return datetime.datetime.strptime(text, "%Y-%m-%d %H:%M:%S")

	def get_size (self, path = '.'):
		total_size = 0
		for dirpath, dirnames, filenames in os.walk(path):
			for f in filenames:
				fp = os.path.join(dirpath, f)
				total_size += os.path.getsize(fp)
		return total_size

	# list all projects in database
	def list (self, garbage = None):
		roots = []
		if garbage == None:
			garbage = []
		if self.database == None:
			return None
		if not os.path.exists(self.database):
			return None
		for name in os.listdir(self.database):
			name = name.strip()
			if len(name) != 16:
				garbage.append(name)
				continue
			path = os.path.join(self.database, name)
			if not os.path.isdir(path):
				garbage.append(name)
				continue
			desc = None
			cfg = os.path.join(path, 'config.json')
			if os.path.exists(cfg):
				try:
					fp = open(cfg, 'r')
					text = fp.read()
					fp.close()
					desc = json.loads(text)
				except:
					desc = None
				if type(desc) != type({}):
					desc = None
			root = (desc != None) and desc.get('root', '') or ''
			if desc == None or root == '':
				garbage.append(name)
				continue
			if desc.get('db', '') == '':
				garbage.append(name)
				continue
			roots.append((name, root, desc))
		return roots

	# select and initialize a project
	def select (self, root):
		if root == None:
			return None
		root = root.strip()
		root = self.abspath(root)
		db = self.pathdb(root)
		self.mkdir(db)
		os.environ['GTAGSROOT'] = os.path.abspath(root)
		os.environ['GTAGSDBPATH'] = os.path.abspath(db)
		desc = self.load(root)
		if desc:
			if not 'root' in desc:
				desc = None
			elif not 'db' in desc:
				desc = None
		if desc == None:
			desc = {}
			desc['root'] = root
			desc['db'] = db
			desc['ctime'] = self.timestamp()
			desc['mtime'] = self.timestamp()
			desc['version'] = 0
			desc['size'] = 0
			self.save(root, desc)
		return desc

	# clear invalid files in the database path
	def clear (self):
		if self.database == None:
			return -1
		if not os.path.exists(self.database):
			return -2
		if self.database == '/':
			return -3
		database = os.path.abspath(self.database)
		if len(self.database) == 3 and self.unix == 0:
			if self.database[1] == ':':
				return -4
		garbage = []
		self.list(garbage)
		import shutil
		for name in garbage:
			path = os.path.join(self.database, name)
			if not os.path.exists(path):
				continue
			if os.path.isdir(path):
				shutil.rmtree(path, True)
			else:
				try: os.remove(path)
				except: pass
		return 0


#----------------------------------------------------------------------
# escope - gtags wrapper
#----------------------------------------------------------------------
class escope (object):

	def __init__ (self, ininame = None):
		self.config = configure(ininame)
		self.desc = None
		self.root = None
		self.db = None
		self.cscope_names = ['.c', '.h', '.cpp', '.cc', '.hpp', '.hh']
		self.cscope_names += ['.go', '.java', '.js', '.m', '.mm']
		self.ignores = ('CVS', '.git', '.svn', '.hg', '.bzr')

	def init (self):
		if self.config.database != None:
			return 0
		self.config.init()
		return 0

	def select (self, root):
		self.desc = None
		self.root = None
		desc = self.config.select(root)
		if desc == None:
			return -1
		self.desc = desc
		self.root = self.config.abspath(root)
		self.db = self.desc['db']
		return 0

	def abort (self, message, code = 1):
		sys.stderr.write(message + '\n')
		sys.stderr.flush()
		sys.exit(1)
		return -1

	def check_cscope (self):
		if not self.config.has_cscope:
			self.abort('cscope executable cannot be found in $PATH')
			return False
		return True

	def check_gtags (self):
		if not self.config.has_gtags:
			msg = 'GNU Global (gtags) executables cannot be found in $PATH'
			self.abort(msg)
			return False
		return True

	def check_pycscope (self):
		if not self.config.has_pycscope:
			self.abort('pycscope executable cannot be found in $PATH')
			return False
		return True

	def find_files (self, path, extnames = None):
		result = []
		if extnames:
			if not self.config.unix:
				extnames = [ n.lower() for n in extnames ]
			extnames = tuple(extnames)
		for root, dirs, files in os.walk(path):
			for ignore in self.ignores:
				if ignore in dirs:
					dirs.remove(ignore)
			for name in files:
				if extnames:
					ext = os.path.splitext(name)[-1]
					if not self.config.unix:
						ext = ext.lower()
					if not ext in extnames:
						continue
				result.append(os.path.abspath(os.path.join(root, name)))
		return result

	def find_list (self, path, filelist):
		result = []
		lines = []
		if filelist == '-':
			for line in sys.stdin:
				lines.append(line.rstrip('\r\n\t '))
		else:
			for line in open(filelist):
				lines.append(line.rstrip('\r\n\t '))
		for line in lines:
			if not line:
				continue
			line = os.path.join(path, line)
			result.append(os.path.abspath(line))
		return result

	def cscope_generate (self, include = None, kernel = False, filelist = None, verbose = 0):
		if not self.check_cscope():
			return -1
		if (self.desc == None) or (self.root == None):
			self.abort('Project has not been selected')
			return -2
		if not filelist:
			names = self.find_files(self.root, self.cscope_names)
		else:
			names = self.find_list(self.root, filelist)
		listname = os.path.join(self.db, 'cscope.txt')
		outname = os.path.join(self.db, 'cscope.out')
		if verbose:
			for fn in names:
				print fn
			sys.stdout.flush()
		fp = open(listname, 'w')
		for line in names:
			fp.write(line + '\n')
		fp.close()
		args = ['-b']
		if kernel:
			args += ['-k']
		if include:
			for inc in include:
				args += ['-I', os.path.join(self.root, inc)]
		if self.config.unix:
			args += ['-q']
		args += ['-i', 'cscope.txt']
		savecwd = os.getcwd()
		os.chdir(self.db)
		self.config.execute('cscope', args)
		os.chdir(savecwd)
		self.desc['mtime'] = self.config.timestamp()
		self.desc['version'] = self.desc['version'] + 1
		self.config.save(self.desc['root'], self.desc)
		return 0

	def gtags_generate (self, label = None, update = False, filelist = None, verbose = False):
		if not self.check_gtags():
			return -1
		if (self.desc == None) or (self.root == None):
			self.abort('Project has not been selected')
			return -2
		args = ['--skip-unreadable']
		if label:
			args += ['--gtagslabel', label]
		if verbose:
			args += ['-v']
		if update:
			if not type(update) in (type(''), type(u'')):
				args += ['-i']
			else:
				args += ['--single-update', update]
		if filelist:
			names = self.find_list(self.root, filelist)
			listname = os.path.join(self.root, 'gtags.txt')
			fp = open(listname, 'w')
			for name in names:
				fp.write(name + '\n')
			fp.close()
			args += ['-f', listname]
		db = self.desc['db']
		args += [db]
		cwd = os.getcwd()
		os.chdir(self.root)
		self.config.execute('gtags', args)
		os.chdir(cwd)
		self.desc['mtime'] = self.config.timestamp()
		self.desc['version'] = self.desc['version'] + 1
		self.config.save(self.desc['root'], self.desc)
		return 0

	def pycscope_generate (self, filelist = None, verbose = False):
		if not self.check_pycscope():
			return -1
		if (self.desc == None) or (self.root == None):
			self.abort('Project has not been selected')
			return -2
		if not filelist:
			names = self.find_files(self.root, ['.py', '.pyw'])
		else:
			names = self.find_list(self.root, filelist)
		listname = os.path.join(self.db, 'pycscope.txt')
		outname = os.path.join(self.db, 'pycscope.out')
		if verbose:
			for fn in names:
				print fn
			sys.stdout.flush()
		fp = open(listname, 'w')
		for name in names:
			fp.write(name + '\n')
		fp.close()
		args = ['-i', 'pycscope.txt', '-f', 'pycscope.out']
		savecwd = os.getcwd()
		os.chdir(self.db)
		self.config.execute('pycscope', args)
		os.chdir(savecwd)
		self.desc['mtime'] = self.config.timestamp()
		self.desc['version'] = self.desc['version'] + 1
		self.config.save(self.desc['root'], self.desc)
		return 0

	def cscope_translate (self, where, text):
		text = text.rstrip('\r\n')
		if text == '':
			return -1
		p1 = text.find(' ')
		if p1 < 0:
			return -2
		p2 = text.find(' ', p1 + 1)
		if p2 < 0:
			return -3
		p3 = text.find(' ', p2 + 1)
		if p3 < 0:
			return -4
		cname = text[:p1]
		csymbol = text[p1 + 1:p2]
		cline = text[p2 + 1:p3]
		ctext = text[p3 + 1:]
		output = '%s:%s: <<%s>> %s'%(cname, cline, csymbol, ctext)
		sys.stdout.write(output + '\n')
		sys.stdout.flush()
		return 0

	def cscope_find (self, mode, name):
		if not self.check_cscope():
			return -1
		if (self.desc == None) or (self.root == None):
			self.abort('Project has not been selected')
			return -2
		args = ['-dl', '-L', '-f', 'cscope.out', '-' + str(mode), name]
		savecwd = os.getcwd()
		os.chdir(self.db)
		self.config.execute('cscope', args, self.cscope_translate)
		os.chdir(savecwd)
		return 0

	def pycscope_find (self, mode, name):
		if not self.check_cscope():
			return -1
		if (self.desc == None) or (self.root == None):
			self.abort('Project has not been selected')
			return -2
		args = ['-dl', '-L', '-f', 'pycscope.out', '-' + str(mode), name]
		savecwd = os.getcwd()
		os.chdir(self.db)
		self.config.execute('cscope', args, self.cscope_translate)
		os.chdir(savecwd)
		return 0

	def gtags_find (self, mode, name):
		if (self.desc == None) or (self.root == None):
			self.abort('Project has not been selected')
			return -1
		args = ['-a', '--result', 'grep']
		if mode in (0, '0', 's', 'symbol'):
			self.config.execute('global', args + ['-d', '-e', name])
			self.config.execute('global', args + ['-r', '-e', name])
			self.config.execute('global', args + ['-s', '-e', name])
		elif mode in (1, '1', 'g', 'definition'):
			self.config.execute('global', args + ['-d', '-e', name])
		elif mode in (3, '3', 'c', 'reference'):
			self.config.execute('global', args + ['-r', '-e', name])
		elif mode in (4, '4', 't', 'string', 'text'):
			self.config.execute('global', args + ['-gGo', '-e', name])
		elif mode in (6, '6', 'e', 'grep', 'egrep'):
			self.config.execute('global', args + ['-gEo', '-e', name])
		elif mode in (7, '7', 'f', 'file'):
			self.config.execute('global', args + ['-P', '-e', name])
		else:
			sys.stderr.write('unsupported')
			sys.stderr.flush()
		return 0

	def generate (self, backend, parameter, update = False, filelist = None, verbose = False):
		if (self.desc == None) or (self.root == None):
			self.abort('Project has not been selected')
			return -1
		if backend in ('cscope', 'cs'):
			kernel = True
			if parameter.lower() in ('1', 'true', 'sys', 'system'):
				kernel = False
			return self.cscope_generate(None, kernel, filelist, verbose)
		elif backend in ('pycscope', 'py'):
			return self.pycscope_generate(filelist, verbose)
		elif backend in ('gtags', 'global', 'gnu'):
			return self.gtags_generate(parameter, update, filelist, verbose)
		else:
			self.abort('unknow backend: %s'%backend)
		return 0

	def find (self, backend, mode, name):
		if (self.desc == None) or (self.root == None):
			self.abort('Project has not been selected')
			return -1
		backend = backend.split('/')
		engine = backend[0]
		parameter = len(backend) >= 2 and backend[1] or ''
		if engine in ('cscope', 'cs'):
			return self.cscope_find(mode, name)
		elif engine in ('pycscope', 'py'):
			return self.pycscope_find(mode, name)
		elif engine in ('gtags', 'global', 'gnu'):
			return self.gtags_find(mode, name)
		else:
			self.abort('unknow backend: %s'%backend)
		return 0

	def list (self):
		if self.config.database == None:
			self.abort('Initialzing is required')
			return -1
		print 'Database:', self.config.database
		print ''
		print 'Hash'.ljust(16),  'Size(KB)'.rjust(11), ' Modified'.ljust(12), ' Root'
		def add_commas(instr):
			rng = reversed(range(1, len(instr) + (len(instr) - 1)//3 + 1))
			out = [',' if j%4 == 0 else instr[-(j - j//4)] for j in rng]
			return ''.join(out)
		for name, root, desc in self.config.list():
			db = os.path.join(self.config.database, name)
			size = (self.config.get_size(db) + 1023) / 1024
			size = add_commas(str(size))
			print name, size.rjust(11), '', desc['mtime'][:10], ' ', desc['root']
		print ''
		return 0

	def clean (self, days):
		if self.config.database == None:
			self.abort('Initialzing is required')
			return -1
		self.config.clear()
		import datetime, time, shutil
		d0 = datetime.datetime.fromtimestamp(time.time())
		for name, root, desc in self.config.list():
			mtime = desc['mtime']
			path = os.path.join(self.config.database, name)
			d1 = self.config.strptime(mtime)
			dd = d0 - d1
			if dd.days >= days and os.path.exists(path):
				sys.stdout.write('%s ... '%name)
				sys.stdout.flush()
				shutil.rmtree(path)
				sys.stdout.write('(removed)\n')
				sys.stdout.flush()
		return 0


#----------------------------------------------------------------------
# errmsg
#----------------------------------------------------------------------
def errmsg(message, abort = False):
	sys.stderr.write('error: ' + message + '\n')
	sys.stderr.flush()
	if abort:
		sys.exit(2)
	return 0


#----------------------------------------------------------------------
# main
#----------------------------------------------------------------------
def main(argv = None):
	argv = (argv == None) and sys.argv or argv
	argv = [ n for n in argv ]
	if len(argv) <= 1:
		errmsg('no operation specified (use -h for help)', True)
		return -1
	operator = argv[1]
	program = os.path.split(argv[0])[-1]
	if operator in ('-h' , '--help'):
		print 'usage %s <operation> [...]'%program
		print 'operations:'
		head = '    %s '%program
		print head + '{-h --help}'
		print head + '{-V --version}'
		print head + '{-B --build} [-k backend] [-r root] [-l label] [-u] [-i] [-v] [-s]'
		print head + '{-F --find} [-k backend] [-r root] -num pattern'
		print head + '{-C --clean} [-d days]'
		print head + '{-L --list}'
		print ''
		head = '    '
		print '-k backend    Choose backend, which can be one of: cscope, gtags or pycscope.'
		print '-r root       Root path of source files, use current directory by default.'
		print '-i filelist   Give a list of candidates of target files, - for stdin.'
		print '-s            System mode - use /usr/include for #include files (cscope).'
		print '-l label      Label of gtags which can be : native, ctags, pygments ... etc.'
		print '-u            Update database only (gtags backend is required).'
		print '-num pattern  Go to cscope input field num (counting from 0) and find pattern.'
		print '-d days       Clean databases modified before given days (default is 30).'
		print '-v            Build the cross reference database in verbose mode.'
		if 0:
			print '-0 pattern    Find this C symbol'
			print '-1 pattern    Find this definition'
			print '-2 pattern    Find functions called by this function (cscope/pycscope)'
			print '-3 pattern    Find functions calling this function'
			print '-4 pattern    Find this text string'
			print '-6 pattern    Find this egrep pattern'
			print '-7 pattern    Find this file'
			print '-8 pattern    Find files #including this file'
			print '-9 pattern    Find places where this symbol is assigned a value'
		print ''
		return 0

	if operator in ('-V', '--version'):
		print 'escope: version 1.0.1'
		return 0

	if not operator in ('-B', '--build', '-F', '--find', '-L', '--list', '-C', '--clean'):
		errmsg('unknow operation: ' + operator, True)
		return -1

	es = escope()
	es.init()

	if operator in ('-L', '--list'):
		es.list()
		return 0

	options = {}
	index = 2

	while index < len(argv):
		opt = argv[index]
		if opt in ('-k', '-r', '-l', '-d', '-i'):
			if index + 1 >= len(argv):
				errmsg('not enough parameter for option: ' + opt, True)
				return -2
			options[opt] = argv[index + 1]
			index += 2
		elif opt >= '-0' and opt <= '-9' and len(opt) == 2:
			if index + 1 >= len(argv):
				errmsg('require pattern for field: ' + opt, True)
				return -2
			options['num'] = int(opt[1:])
			options['name'] = argv[index + 1]
			index += 2
		elif opt in ('-s', '-u', '-v'):
			options[opt] = True
			index += 1
		else:
			errmsg('unknow option: ' + opt, True)
			return -2

	if not '-k' in options:
		errmsg('require backend name, use one of cscope, gtags, pycscope after -k', True)
		return -3

	backend = options['-k']
	if not backend in ('cscope', 'gtags', 'pycscope'):
		errmsg('bad backend name, use one of cscope, gtags, pycscope after -k', True)
		return -3

	root = options.get('-r', os.getcwd())
	if not os.path.exists(root):
		errmsg('path does not exist: ' + root, True)
		return -3

	es.select(root)

	if operator in ('-B', '--build'):
		label = options.get('-l', '')
		if backend != 'gtags' and label != '':
			errmsg('label can only be used with gtags backend', True)
			return -5
		label = (label == '') and 'native' or label
		system = options.get('-s') and True or False
		update = options.get('-u') and True or False
		verbose = options.get('-v') and True or False
		filelist = options.get('-i', None)
		if backend != 'cscope' and system != False:
			errmsg('system mode can only be used with cscope backend', True)
			return -5
		if backend != 'gtags' and update != False:
			errmsg('update mode can only be used with gtags backend', True)
			return -5
		parameter = ''
		if backend == 'cscope' and system:
			parameter = 'system'
		elif backend == 'gtags':
			parameter = label
		if verbose:
			sys.stdout.write('Buiding %s database for: %s\n'%(backend, root))
			sys.stdout.flush()
		if filelist:
			if filelist != '-' and (not os.path.exists(filelist)):
				errmsg('cannot read file list: ' + filelist, True)
				return -5
		es.generate(backend, parameter, update, filelist, verbose)
		return 0

	if operator in ('-F', '--find'):
		if not 'num' in options:
			errmsg('-num pattern required', True)
			return -6
		num = options['num']
		if num in (2, 5, 8, 9) and backend == 'gtags':
			errmsg('gtags does not support -%d pattern'%num, True)
			return -6
		name = options['name']
		es.find(backend, num, name)
		return 0

	if operator in ('-C', '--clean'):
		count = 30
		es.clean(count)
		return 0

	return 0


#----------------------------------------------------------------------
# testing case
#----------------------------------------------------------------------
if __name__ == '__main__':

	def test1():
		config = configure()
		config.init()
		print config.select('e:/lab/casuald/src/')
		print ''
		sys.stdout.flush()
		for hash, root, desc in config.list():
			print hash, root, desc['ctime']
		config.clear()
		#os.system('cmd /c start cmd')
		return 0

	def test2():
		sc = escope()
		sc.init()
		sc.select('e:/lab/casuald/src/')
		sc.gtags_generate(label = 'pygments', update = True, verbose = False)
		sys.stdout.flush()
		sc.find('gtags', 0, 'itm_send')
		return 0

	def test3():
		os.environ['ESCOPE'] = 'd:/temp/escope'
		sc = escope()
		os.chdir('e:/lab/casuald/src')
		sc.init()
		sc.select('e:/lab/casuald/src')
		sc.cscope_generate()
		sc.pycscope_generate()
		sc.cscope_find(3, 'itm_send')
		sc.pycscope_find(0, 'vimtool')

	def test4():
		main([__file__, '-h'])
		#main([__file__, '--version'])
		#main([__file__, '--clean'])
		return 0

	def test5():
		main([__file__, '-B', '-k', 'cscope', '-r', 'e:/lab/casuald'])
		main([__file__, '-F', '-k', 'cscope', '-r', 'e:/lab/casuald', '-2', 'itm_sendudp'])

	def test6():
		main([__file__, '-B', '-k', 'pycscope', '-r', 'e:/lab/casuald'])
		main([__file__, '-F', '-k', 'pycscope', '-r', 'e:/lab/casuald', '-2', 'plog'])

	def test7():
		main([__file__, '-B', '-k', 'gtags', '-r', 'e:/lab/casuald', '-l', 'pygments', '-v', '-u'])
		main([__file__, '-F', '-k', 'gtags', '-r', 'e:/lab/casuald', '-1', 'plog'])

	#test4()
	main()



