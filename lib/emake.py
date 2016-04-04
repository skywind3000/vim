#! /usr/bin/env python2
# -*- coding: utf-8 -*-
#======================================================================
#
# emake.py - emake version 3.6.9
#
# history of this file:
# 2009.08.20   skywind   create this file
# 2009.11.14   skywind   new install() method
# 2009.12.22   skywind   implementation execute interface
# 2010.01.18   skywind   new project info
# 2010.03.14   skywind   fixed source lex bug
# 2010.11.03   skywind   new 'import' to import config section 
# 2010.11.04   skywind   new 'export' to export .def, .lib for windll
# 2010.11.27   skywind   fixed link sequence with -Xlink -( -)
# 2012.03.26   skywind   multiprocess building system, speed up
# 2012.08.18   skywind   new 'flnk' to project
# 2012.09.09   skywind   new system condition config, optimized
# 2013.12.19   skywind   new $(target) config
# 2014.02.09   skywind   new build-event and environ
# 2014.04.15   skywind   new 'arglink' and 'argcc' config
# 2015.09.03   skywind   new replace in config.parameters()
# 2016.01.14   skywind   new compile flags with different source file
# 2016.04.27   skywind   exit non-zero when error occurs
# 2016.09.01   skywind   new lib composite method
# 2016.09.02   skywind   more environ variables rather than $(target)
# 2017.08.16   skywind   new: cflag, cxxflag, sflag, mflag, mmflag
# 2017.12.20   skywind   new: --abs=1 to tell gcc to print fullpath 
#
#======================================================================
import sys, time, os
import ConfigParser


#----------------------------------------------------------------------
# preprocessor: C/C++/Java 预处理器
#----------------------------------------------------------------------
class preprocessor(object):

	# 初始化预编译器
	def __init__ (self):
		self.reset()

	# 生成正文映射，将所有字符串及注释用 "$"和 "`"代替，排除分析干扰
	def preprocess (self, text):
		content = text
		spaces = (' ', '\n', '\t', '\r')
		import cStringIO
		srctext = cStringIO.StringIO()
		srctext.write(text)
		srctext.seek(0)
		memo = 0
		i = 0
		length = len(content)
		output = srctext.write
		while i < length:
			char = content[i]
			word = content[i : i + 2]
			if memo == 0:		# 正文中
				if word == '/*':
					output('``')
					i += 2
					memo = 1
					continue
				if word == '//':
					output('``')
					i += 2
					while (i < len(content)) and (content[i] != '\n'):
						if content[i] in spaces:
							output(content[i])
							i = i + 1
							continue						
						output('`')
						i = i + 1
					continue
				if char == '\"':
					output('\"')
					i += 1
					memo = 2
					continue
				if char == '\'':
					output('\'')
					i += 1
					memo = 3
					continue
				output(char)
			elif memo == 1:		# 注释中
				if word == '*/':
					output('``')
					i += 2
					memo = 0
					continue
				if char in spaces:
					output(content[i])
					i += 1
					continue
				output('`')
			elif memo == 2:		# 字符串中
				if word == '\\\"':
					output('$$')
					i += 2
					continue
				if word == '\\\\':
					output('$$')
					i += 2
					continue
				if char == '\"':
					output('\"')
					i += 1
					memo = 0
					continue
				if char in spaces:
					output(char)
					i += 1
					continue
				output('$')
			elif memo == 3:		# 字符中
				if word == '\\\'':
					output('$$')
					i += 2
					continue
				if word == '\\\\':
					output('$$')
					i += 2
					continue
				if char == '\'':
					output('\'')
					i += 1
					memo = 0
					continue
				if char in spaces:
					output(char)
					i += 1
					continue
				output('$')
			i += 1
		srctext.truncate()
		return srctext.getvalue()

	# 查找单一文件的头文件引用情况
	def search_reference(self, source, heads):
		content = ''
		del heads[:]
		try:
			fp = open(source, "r")
		except:
			return ''
		
		content = '\n'.join([ line.strip('\r\n') for line in fp ])
		fp.close()

		srctext = self.preprocess(content)

		length = len(srctext)
		start = 0
		endup =-1
		number = 0

		while (start >= 0) and (start < length):
			start = endup + 1
			endup = srctext.find('\n', start)
			if (endup < 0):
				endup = length
			number = number + 1

			offset1 = srctext.find('#', start, endup)
			if offset1 < 0: continue
			offset2 = srctext.find('include', offset1, endup)
			if offset2 < 0: continue
			offset3 = srctext.find('\"', offset2, endup)
			if offset3 < 0: continue
			offset4 = srctext.find('\"', offset3 + 1, endup)
			if offset4 < 0: continue

			check_range = [ i for i in xrange(start, offset1) ]
			check_range += [ i for i in xrange(offset1 + 1, offset2) ]
			check_range += [ i for i in xrange(offset2 + 7, offset3) ]
			check = 1

			for i in check_range:
				if not (srctext[i] in (' ', '`')):
					check = 0
					break

			if check != 1:
				continue
			
			name = content[offset3 + 1 : offset4]
			heads.append([name, offset1, offset4, number])

		return content

	# 合并引用的所有头文件，并返回文件依赖，及找不到的头文件
	def parse_source(self, filename, history_headers, lost_headers):
		headers = []
		filename = os.path.abspath(filename)
		import cStringIO
		outtext = cStringIO.StringIO()
		if not os.path.exists(filename):
			sys.stderr.write('can not open %s\n'%(filename))
			return outtext.getvalue()
		if filename in self._references:
			content, headers = self._references[filename]
		else:
			content = self.search_reference(filename, headers)
			self._references[filename] = content, headers
		save_cwd = os.getcwd()
		file_cwd = os.path.dirname(filename)
		if file_cwd == '':
			file_cwd = '.'
		os.chdir(file_cwd)
		available = []
		for head in headers:
			if os.path.exists(head[0]):
				available.append(head)
		headers = available
		offset = 0
		for head in headers:
			name = os.path.abspath(os.path.normcase(head[0]))
			if not (name in history_headers):
				history_headers.append(name)
				position = len(history_headers) - 1
				text = self.parse_source(name, history_headers, lost_headers)
				del history_headers[position]
				history_headers.append(name)
				outtext.write(content[offset:head[1]] + '\n')
				outtext.write('/*:: <%s> ::*/\n'%(head[0]))
				outtext.write(text + '\n/*:: </:%s> ::*/\n'%(head[0]))
				offset = head[2] + 1
			else:
				outtext.write(content[offset:head[1]] + '\n')
				outtext.write('/*:: skip including "%s" ::*/\n'%(head[0]))
				offset = head[2] + 1
		outtext.write(content[offset:])
		os.chdir(save_cwd)
		return outtext.getvalue()

	# 过滤代码注释
	def cleanup_memo (self, text):
		content = text
		outtext = ''
		srctext = self.preprocess(content)
		space = ( ' ', '\t', '`' )
		start = 0
		endup = -1
		sized = len(srctext)
		while (start >= 0) and (start < sized):
			start = endup + 1
			endup = srctext.find('\n', start)
			if endup < 0:
				endup = sized
			empty = 1
			memod = 0
			for i in xrange(start, endup):
				if not (srctext[i] in space):
					empty = 0
				if srctext[i] == '`':
					memod = 1
			if empty and memod:
				continue
			for i in xrange(start, endup):
				if srctext[i] != '`':
					outtext = outtext + content[i]
			outtext = outtext + '\n'
		return outtext

	# 复位依赖关系
	def reset (self):
		self._references = {}
		return 0

	# 直接返回依赖
	def dependence (self, filename, reset = False):
		head = []
		lost = []
		if reset: self.reset()
		text = self.parse_source(filename, head, lost)
		return head, lost, text

	# 查询 Java的信息，返回：(package, imports, classname)
	def java_preprocess (self, text):
		text = self.preprocess(text)
		content = text.replace('\r', '')
		p1 = content.find('{')
		p2 = content.rfind('}')
		if p1 >= 0:
			if p2 < 0:
				p2 = len(content)
			content = content[:p1] + ';\n' + content[p2 + 1:]
		content = self.cleanup_memo(content).rstrip() + '\n'
		info = { 'package': None, 'import': [], 'class': None }
		for line in content.split(';'):
			line = line.replace('\n', ' ').strip()
			data = [ n.strip() for n in line.split() ]
			if len(data) < 2: continue
			name = data[0]
			if name == 'package':
				info['package'] = ''.join(data[1:])
			elif name == 'import':
				info['import'] += [''.join(data[1:])]
			elif 'class' in data or 'interface' in data:
				if 'extends' in data:
					p = data.index('extends')
					data = data[:p]
				if 'implements' in data:
					p = data.index('implements')
					data = data[:p]
				info['class'] = data[-1]
		return info['package'], info['import'], info['class']

	# returns: (package, imports, classname, srcpath)
	def java_parse (self, filename):
		try:
			text = open(filename).read()
		except:
			return None, None, None, None
		package, imports, classname = self.java_preprocess(text)
		if package is None:
			path = os.path.dirname(filename)
			return None, imports, classname, os.path.abspath(path)
		path = os.path.abspath(os.path.dirname(filename))
		if sys.platform[:3] == 'win':
			path = path.replace('\\', '/')
		names = package.split('.')
		root = path
		srcpath = None
		if sys.platform[:3] == 'win':
			root = root.lower()
			names = [n.lower() for n in names]
		while 1:
			part = os.path.split(root)
			name = names[-1]
			names = names[:-1]
			if name != part[1]:
				break
			if len(names) == 0:
				srcpath = part[0]
				break
			if root == part[0]:
				break
			root = part[0]
		return package, imports, classname, srcpath
	

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
# Default CFG File
#----------------------------------------------------------------------
ININAME = ''
INIPATH = ''

CFG = {'abspath':False, 'verbose':False, 'silent':False}


#----------------------------------------------------------------------
# configure: 确定gcc位置并从配置读出默认设置
#----------------------------------------------------------------------
class configure(object):

	# 构造函数
	def __init__ (self, ininame = ''):
		self.dirpath = os.path.split(os.path.abspath(__file__))[0]
		self.current = os.getcwd()
		if not ininame:
			ininame = ININAME and ININAME or 'emake.ini'
		self.ininame = ininame
		self.inipath = os.path.join(self.dirpath, self.ininame)
		self.haveini = False
		self.dirhome = ''
		self.target = ''
		self.config = {}
		self.cp = ConfigParser.ConfigParser()
		self.unix = 1
		self.xlink = 1
		self.searchdirs = None
		self.environ = {}
		self.exename = {}
		self.replace = {}
		self.cygwin = ''
		for n in os.environ:
			self.environ[n] = os.environ[n]
		if sys.platform[:3] == 'win':
			self.unix = 0
			self.GetShortPathName = None
		if sys.platform[:6] == 'darwin':
			self.xlink = 0
		if sys.platform[:3] == 'aix':
			self.xlink = 0
		self.cpus = 0
		self.inited = False
		self.fpic = 0
		self.name = {}
		ext = ('.c', '.cpp', '.c', '.cc', '.cxx', '.s', '.asm', '.m', '.mm')
		self.extnames = ext
		self.__jdk_home = None
		self.reset()
	
	# 配置信息复位
	def reset (self):
		self.inc = {}		# include路径
		self.lib = {}		# lib 路径
		self.flag = {}		# 编译参数
		self.pdef = {}		# 预定义宏
		self.link = {}		# 连接库
		self.flnk = {}		# 连接参数
		self.wlnk = {}		# 连接传递
		self.cond = {}		# 条件参数
		self.param_build = ''
		self.param_compile = ''
		return 0
	
	# 初始化工具环境
	def _cmdline_init (self, envname, exename):
		if not envname in self.config:
			return -1
		config = self._env_config(envname)
		PATH = []
		EXEC = ''
		sep = self.unix and ':' or ';'
		envpath = config.get('PATH', '') + sep + self.environ.get('PATH', '')
		condition = False
		if os.path.exists(exename):
			EXEC = exename
		for path in envpath.split(sep):
			if path.strip('\r\n\t ') == '':
				continue
			path = os.path.abspath(path)
			if os.path.exists(path):
				if not path in PATH:
					PATH.append(path)
			if not EXEC:
				name = os.path.join(path, exename)
				if os.path.exists(name):
					EXEC = name
		if not EXEC:
			return -2
		config['PATH'] = sep.join(PATH)
		for n in config:
			v = config[n]
			if not n in ('PATH',):
				os.environ[n] = v
		os.environ['PATH'] = config['PATH']
		if not self.unix:
			EXEC = self.pathshort(EXEC)
		return EXEC
	
	# 工具加载
	def _env_config (self, section):
		config = {}
		if section in self.config:
			for n in self.config[section]:
				config[n.upper()] = self.config[section][n]
		for n in config:
			config[n] = config[n].replace('$(INIROOT)', os.path.dirname(self.iniload))
		for n in config:
			config[n] = self._expand(config, self.environ, n)
		return config

	# 展开配置宏
	def _expand (self, section, environ, item, d = 0):
		if not environ: environ = {}
		if not section: section = {}
		text = ''
		if item in environ:
			text = environ[item]
		if item in section:
			text = section[item]
		if d >= 20: return text
		names = {}
		index = 0
		# print 'expanding', item
		while 1:
			index = text.find('$(', index)
			if index < 0: break
			p2 = text.find(')', index)
			if p2 < 0: break
			name = text[index + 2:p2]
			index = p2 + 1
			names[name] = name.upper()
		for name in names:
			if name != item:
				value = self._expand(section, environ, name.upper(), d + 1)
			elif name in environ:
				value = environ[name]
			else:
				value = ''
			text = text.replace('$(' + name + ')', value)
			names[name] = value
		# print '>', text
		return text
	
	# 取得短文件名
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
	
	# 读取ini文件
	def _readini (self, inipath):
		self.cp = ConfigParser.ConfigParser()
		if self.unix and '~' in inipath:
			inipath = os.path.expanduser(inipath)
		if os.path.exists(inipath):
			self.iniload = os.path.abspath(inipath)
			config = {}
			try: self.cp.read(inipath)
			except: pass
			for sect in self.cp.sections():
				for key, val in self.cp.items(sect):
					lowsect, lowkey = sect.lower(), key.lower()
					self.config.setdefault(lowsect, {})[lowkey] = val
					config.setdefault(lowsect, {})[lowkey] = val
			self.config['default'] = self.config.get('default', {})
			config['default'] = config.get('default', {})
			inihome = os.path.abspath(os.path.split(inipath)[0])
			dirhome = config['default'].get('home', '')
			if dirhome:
				dirhome = os.path.join(inihome, dirhome)
				if not os.path.exists(dirhome):
					sys.stderr.write('error: %s: %s not exists\n'%(inipath, dirhome))
					sys.stderr.flush()
				else:
					self.config['default']['home'] = dirhome
			for exename in ('gcc', 'ld', 'ar', 'as', 'nasm', 'yasm', 'dllwrap'):
				if not exename in config['default']:
					continue
				self.exename[exename] = config['default'][exename]
			for bp in ('include', 'lib'):
				if not bp in config['default']:
					continue
				data = []
				for n in config['default'][bp].replace(';', ',').split(','):
					n = os.path.normpath(os.path.join(inihome, self.pathconf(n)))
					if not self.unix: n = n.replace('\\', '/')
					data.append("'" + n + "'")
				text = ','.join(data)
				config['default'][bp] = text
				self.config['default'][bp] = text
			java = config['default'].get('java', '')
			if java:
				java = os.path.join(inihome, java)
				if not os.path.exists(java):
					sys.stderr.write('error: %s: %s not exists\n'%(inipath, java))
					sys.stderr.flush()
				else:
					self.config['default']['java'] = os.path.abspath(java)
			self.haveini = True
		return 0

	# 检查 dirhome
	def check (self):
		if not self.dirhome:
			sys.stderr.write('error: cannot find gcc home in config\n')
			sys.stderr.flush()
			sys.exit(1)
		return 0

	# 初始化
	def init (self):
		if self.inited:
			return 0
		self.config = {}
		self.reset()
		fn = INIPATH
		self.iniload = os.path.abspath(self.inipath)
		if fn:
			if os.path.exists(fn):
				self._readini(fn)
				self.iniload = os.path.abspath(fn)
			else:
				sys.stderr.write('error: cannot open %s\n'%fn)
				sys.stderr.flush()
				sys.exit(1)
		else:
			if self.unix:
				self._readini('/etc/%s'%self.ininame)
				self._readini('/usr/local/etc/%s'%self.ininame)
				self._readini('~/.config/%s'%self.ininame)
			self._readini(self.inipath)
		self.dirhome = self._getitem('default', 'home', '')
		cfghome = self.dirhome
		if not self.haveini:
			#sys.stderr.write('warning: %s cannot be open\n'%(self.ininame))
			sys.stderr.flush()
		defined = self.exename.get('gcc', None) and True or False
		for name in ('gcc', 'ar', 'ld', 'as', 'nasm', 'yasm', 'dllwrap'):
			exename = self.exename.get(name, name)
			if not self.unix:
				elements = list(os.path.splitext(exename)) + ['', '']
				if not elements[1]: exename = elements[0] + '.exe'
			self.exename[name] = exename
		gcc = self.exename['gcc']
		p1 = os.path.join(self.dirhome, '%s.exe'%gcc)
		p2 = os.path.join(self.dirhome, '%s'%gcc)
		if (not os.path.exists(p1)) and (not os.path.exists(p2)):
			self.dirhome = ''
		if sys.platform[:3] != 'win':
			if self.dirhome[1:2] == ':':
				self.dirhome = ''
		if (not self.dirhome) and (not cfghome):
			self.dirhome = self.__search_gcc()
			if (not self.dirhome) and (not defined):
				gcc = 'clang'
				self.exename['gcc'] = gcc
				self.dirhome = self.__search_gcc()
		if self.dirhome:
			self.dirhome = os.path.abspath(self.dirhome)
		try: 
			cpus = self._getitem('default', 'cpu', '')
			intval = int(cpus)
			self.cpus = intval
		except:
			pass
		cygwin = self._getitem('default', 'cygwin')
		self.cygwin = ''
		if cygwin and (not self.unix):
			if os.path.exists(cygwin):
				cygwin = os.path.abspath(cygwin)
				bash = os.path.join(cygwin, 'bin/bash.exe')
				if os.path.exists(bash):
					self.cygwin = cygwin
		self.name = {}
		self.name[sys.platform.lower()] = 1
		if sys.platform[:3] == 'win':
			self.name['win'] = 1
		if sys.platform[:7] == 'freebsd':
			self.name['freebsd'] = 1
			self.name['unix'] = 1
		if sys.platform[:5] == 'linux':
			self.name['linux'] = 1
			self.name['unix'] = 1
		if sys.platform[:6] == 'darwin':
			self.name['darwin'] = 1
			self.name['unix'] = 1
		if sys.platform == 'cygwin':
			self.name['unix'] = 1
		if sys.platform[:5] == 'sunos':
			self.name['sunos'] = 1
		if os.name == 'posix':
			self.name['unix'] = 1
		if os.name == 'nt':
			self.name['win'] = 1
		if 'win' in self.name:
			self.name['nt'] = 1
		self.target = self._getitem('default', 'target')
		names = self._getitem('default', 'name')
		if names:
			self.name = {}
			for name in names.replace(';', ',').split(','):
				name = name.strip('\r\n\t ').lower()
				if not name: continue
				self.name[name] = 1
				if not self.target:
					self.target = name
		if not self.target:
			self.target = sys.platform
		self.target = self.target.strip('\r\n\t ')
		if sys.platform[:3] in ('win', 'cyg'):
			self.fpic = False
		else:
			self.fpic = True
		#self.__python_config()
		self.replace = {}
		self.replace['home'] = self.dirhome
		self.replace['emake'] = self.dirpath
		self.replace['inihome'] = os.path.dirname(self.iniload)
		self.replace['inipath'] = self.inipath
		self.replace['target'] = self.target
		self.inited = True
		return 0

	# 读取配置
	def _getitem (self, sect, key, default = ''):
		return self.config.get(sect, {}).get(key, default)
	
	# 取得替换了$(HOME)变量的路径
	def path (self, path):
		path = path.replace('$(HOME)', self.dirhome).replace('\\', '/')
		path = self.cygpath(path)
		text = ''
		issep = False
		for n in path:
			if n == '/':
				if issep == False: text += n
				issep = True
			else:
				text += n
				issep = False
		return os.path.abspath(text)
	
	# 取得可用于参数的文本路径
	def pathtext (self, name):
		name = os.path.normpath(name)
		name = self.cygpath(name)
		name = name.replace('"', '""')
		if ' ' in name:
			return '"%s"'%(name)
		if self.unix:
			name = name.replace('\\', '/')
		return name
	
	# 取得短路径：当前路径的相对路径
	def relpath (self, name, start = None):
		name = os.path.abspath(name)
		if not start:
			start = os.getcwd()
		if 'relpath' in os.path.__dict__:
			try:
				return os.path.relpath(name, start)
			except:
				pass
		current = start.replace('\\', '/')
		if len(current) > 0:
			if current[-1] != '/':
				current += '/'
		name = self.path(name).replace('\\', '/')
		size = len(current)
		if self.unix:
			if name[:size] == current:
				name = name[size:]
		else:
			if name[:size].lower() == current.lower():
				name = name[size:]
		return name

	# 取得短路径：当前路径的相对路径
	def pathrel (self, name, start = None):
		return self.pathtext(self.relpath(name, start))
	
	# 转换到cygwin路径
	def cygpath (self, path):
		if self.unix and path[1:2] == ':':
			path = '/cygdrive/%s%s'%(path[0], path[2:].replace('\\', '/'))
		return path
	
	# 转换到cygwin路径
	def win2cyg (self, path):
		path = os.path.abspath(path)
		return '/cygdrive/%s%s'%(path[0], path[2:].replace('\\', '/'))

	# 转换回cygwin路径
	def cyg2win (self, path):
		if path[1:2] == ':':
			return os.path.abspath(path)
		if path.lower().startswith('/cygdrive/'):
			path = path[10] + ':' + path[11:]
			return os.path.abspath(path)
		if not path.startswith('/'):
			raise Exception('cannot convert path: %s'%path)
		if not self.cygwin:
			raise Exception('cannot find cygwin root')
		return os.path.abspath(os.path.join(self.cygwin, path[1:]))

	# 添加头文件目录
	def push_inc (self, inc):
		path = self.path(inc)
		if not os.path.exists(path):
			sys.stderr.write('warning: ignore invalid path %s\n'%path)
			return -1
		path = self.pathtext(path)
		self.inc[path] = 1
		return 0
	
	# 添加库文件目录
	def push_lib (self, lib):
		path = self.path(lib)
		if not os.path.exists(path):
			sys.stderr.write('warning: ignore invalid path %s\n'%path)
			return -1
		path = self.pathtext(path)
		self.lib[path] = 1
		return 0
	
	# 添加参数
	def push_flag (self, flag):
		if not flag in self.flag:
			self.flag[flag] = len(self.flag)
		return 0
	
	# 添加链接库
	def push_link (self, link):
		if link[-2:].lower() in ('.o', '.a'):
			link = self.pathtext(self.path(link))
		else:
			link = '-l%s'%link.replace(' ', '_')
		if not link in self.link:
			self.link[link] = len(self.link)
		#print 'push: ' + link
		return 0
	
	# 添加预定义
	def push_pdef (self, define):
		self.pdef[define] = 1
	
	# 添加连接参数
	def push_flnk (self, flnk):
		if not flnk in self.flnk:
			self.flnk[flnk] = len(self.flnk)
		return 0
	
	# 添加链接传递
	def push_wlnk (self, wlnk):
		if not wlnk in self.wlnk:
			self.wlnk[wlnk] = len(self.wlnk)
		return 0

	# 添加条件参数
	def push_cond (self, flag, condition):
		key = (flag, condition)
		if not key in self.cond:
			self.cond[key] = len(self.cond)
		return 0

	# 搜索gcc
	def __search_gcc (self):
		dirpath = self.dirpath
		gcc = self.exename['gcc']
		splitter = self.unix and ':' or ';'
		if os.path.exists(os.path.join(dirpath, '%s'%gcc)):
			return os.path.abspath(dirpath)
		if os.path.exists(os.path.join(dirpath, 'bin/%s'%gcc)):
			return os.path.abspath(os.path.join(dirpath, 'bin'))
		for d in os.environ.get('PATH', '').split(splitter):
			n = os.path.abspath(os.path.join(d, '%s'%gcc))
			if os.path.exists(n): return os.path.abspath(d)
		if self.unix:
			if os.path.exists('/bin/%s'%gcc):
				return '/bin'
			if os.path.exists('/usr/bin/%s'%gcc):
				return '/usr/bin'
			if os.path.exists('/usr/local/bin/%s'%gcc):
				return '/usr/local/bin'
			if os.path.exists('/opt/bin/%s'%gcc):
				return '/opt/bin'
			if os.path.exists('/opt/usr/bin/%s'%gcc):
				return '/opt/usr/bin'
			if os.path.exists('/opt/usr/local/bin/%s'%gcc):
				return '/opt/usr/local/bin'
		return ''
	
	# 写默认的配置文件
	def _write_default_ini (self):
		default = '''	[default]
						include=$(HOME)/include
						lib=$(HOME)/lib
				'''
		text = '\n'.join([ n.strip('\t\r\n ') for n in default.split('\n') ])
		if os.path.exists(self.inipath):
			return -1
		fp = open(self.inipath, 'w')
		fp.write(text)
		fp.close()
		return 0
	
	# 配置路径
	def pathconf (self, path):
		path = path.strip(' \t\r\n')
		if path[:1] == '\'' and path[-1:] == '\'': path = path[1:-1]
		if path[:1] == '\"' and path[-1:] == '\"': path = path[1:-1]
		return path.strip(' \r\n\t')

	# 刷新配置
	def loadcfg (self, sect = 'default', reset = True):
		self.init()
		if reset: self.reset()
		f1 = lambda n: (n[:1] != '\'' or n[-1:] != '\'') and n
		config = lambda n: self._getitem(sect, n, '')
		for path in config('include').replace(';', ',').split(','):
			path = self.pathconf(path)
			if not path: continue
			self.push_inc(path)
		for path in config('lib').replace(';', ',').split(','):
			path = self.pathconf(path)
			if not path: continue
			self.push_lib(path)
		for link in config('link').replace(';', ',').split(','):
			link = self.pathconf(link)
			if not link: continue
			self.push_link(link)
		for flag in config('flag').replace(';', ',').split(','):
			flag = flag.strip(' \t\r\n')
			if not flag: continue
			self.push_flag(flag)
		for pdef in config('define').replace(';', ',').split(','):
			pdef = pdef.strip(' \t\r\n')
			if not pdef: continue
			self.push_pdef(pdef.replace(' ', '_'))
		for flnk in config('flnk').replace(';', ',').split(','):
			flnk = flnk.strip(' \t\r\n')
			if not flnk: continue
			self.push_flnk(flnk)
		for wlnk in config('wlnk').replace(';', ',').split(','):
			wlnk = wlnk.strip(' \t\r\n')
			if not wlnk: continue
			self.push_wlnk(wlnk)
		for name in ('cflag', 'cxxflag', 'mflag', 'mmflag', 'sflag'):
			for flag in config(name).replace(';', ',').split(','):
				flag = flag.strip(' \t\r\n')
				if not flag: continue
				self.push_cond(flag, name)
		self.parameters()
		return 0
	
	# 按字典值顺序取出配置
	def sequence (self, data):
		x = [ (n, k) for (k, n) in data.items() ]
		x.sort()
		y = [ n for (k, n) in x ]
		return y
	
	# 替换字符串 
	def __replace_key (self, text):
		for key in self.replace:
			value = self.replace[key]
			check = '$(' + key + ')'
			if check in text:
				text = text.replace(check, value)
		return text

	# 返回条件参数
	def condition (self, conditions):
		flags = []
		for flag, cond in self.sequence(self.cond):
			if cond in conditions:
				flags.append(flag)
		return flags

	# 返回序列化的参数	
	def parameters (self):
		text = ''
		for inc in self.sequence(self.inc):
			text += '-I%s '%inc
		for lib in self.sequence(self.lib):
			text += '-L%s '%lib
		for flag in self.sequence(self.flag):
			text += '%s '%self.__replace_key(flag)
		for pdef in self.sequence(self.pdef):
			text += '-D%s '%pdef
		self.param_compile = text.strip(' ')
		text = ''
		if self.xlink:
			text = '-Xlinker "-(" '
		for link in self.sequence(self.link):
			text += '%s '%self.__replace_key(link)
		if self.xlink:
			text += ' -Xlinker "-)"'
		else:
			text = text + ' ' + text
		self.param_build = self.param_compile + ' ' + text
		for flnk in self.sequence(self.flnk):
			self.param_build += ' %s'%self.__replace_key(flnk)
		wl = ','.join([ self.__replace_key(n) for n in self.sequence(self.wlnk) ])
		if wl and self.wlnk:
			self.param_build += ' -Wl,' + wl
		return text

	# gcc 的search-dirs
	def __searchdirs (self):
		if self.searchdirs != None:
			return self.searchdirs
		path = os.path.abspath(os.path.join(self.dirhome, 'bin/gcc'))
		if not self.unix:
			name = self.pathshort(path)
			if (not name) and os.path.exists(path + '.exe'):
				name = self.pathshort(path + '.exe')
			if name: path = name
		cmdline = path + ' -print-search-dirs'
		fp = os.popen(cmdline, 'r')
		data = fp.read()
		fp.close()
		fp = None
		body = ''
		for line in data.split('\n'):
			if line[:10] == 'libraries:':
				body = line[10:].strip('\r\n ')
				if body[:1] == '=': body = body[1:]
				break
		part = []
		if sys.platform[:3] == 'win': part = body.split(';')
		else: part = body.split(':')
		data = []
		dict = {}
		for n in part:
			path = os.path.abspath(os.path.normpath(n))
			if not path in dict:
				if os.path.exists(path):
					data.append(path)
					dict[path] = 1
				else:
					dict[path] = 0
		self.searchdirs = data
		return data
	
	# 检测库是否存在
	def checklib (self, name):
		name = 'lib' + name + '.a'
		for n in self.__searchdirs():
			if os.path.exists(os.path.join(n, name)):
				return True
		for n in self.lib:
			if os.path.exists(os.path.join(n, name)):
				return True
		return False
	
	# 取得可执行名称
	def getname (self, binname):
		exename = self.exename.get(binname, binname)
		path = os.path.abspath(os.path.join(self.dirhome, exename))
		if not self.unix:
				name = self.pathshort(path)
				if (not name) and os.path.exists(path + '.exe'):
					name = self.pathshort(path + '.exe')
				if name: path = name
		return path
	
	# 执行GNU工具集
	def execute (self, binname, parameters, printcmd = False, capture = False):
		path = os.path.abspath(os.path.join(self.dirhome, binname))
		if not self.unix:
			name = self.pathshort(path)
			if (not name) and os.path.exists(path + '.exe'):
				name = self.pathshort(path + '.exe')
			if name: path = name
		cmd = '%s %s'%(self.pathtext(path), parameters)
		#printcmd = True
		text = ''
		if printcmd:
			if not capture: print cmd
			else: text = cmd + '\n'
		sys.stdout.flush()
		sys.stderr.flush()
		text = text + execute(cmd, shell = False, capture = capture)
		return text
	
	# 调用 gcc
	def gcc (self, parameters, needlink, printcmd = False, capture = False):
		param = self.param_build
		if not needlink:
			param = self.param_compile
		parameters = '%s %s'%(parameters, param)
		# printcmd = True
		return self.execute(self.exename['gcc'], parameters, printcmd, capture)

	# 编译
	def compile (self, srcname, objname, cflags, printcmd = False, capture = False):
		if CFG['abspath']:
			srcname = self.pathtext(os.path.abspath(srcname))
		else:
			srcname = self.pathrel(srcname)
		cmd = '-c %s -o %s %s'%(srcname, self.pathrel(objname), cflags)
		extname = os.path.splitext(srcname)[-1].lower()
		cond = []
		if extname in ('.c', '.h'):
			cond = self.condition({'cflag':1})
		elif extname in ('.cpp', '.cc', '.cxx', '.hpp', '.hh'):
			cond = self.condition({'cxxflag':1})
		elif extname in ('.s', '.asm'):
			cond = self.condition({'sflag':1})
		elif extname in ('.m',):
			cond = self.condition({'mflag':1})
		elif extname in ('.mm',):
			cond = self.condition({'mmflag':1})
		if cond:
			cmd = cmd + ' ' + (' '.join(cond))
		return self.gcc(cmd, False, printcmd, capture)
	
	# 使用 dllwrap
	def dllwrap (self, parameters, printcmd = False, capture = False):
		text = ''
		for lib in self.sequence(self.lib):
			text += '-L%s '%lib
		for link in self.sequence(self.link):
			text += '%s '%link
		for flnk in self.sequence(self.flnk):
			text += '%s '%flnk
		parameters = '%s %s'%(parameters, text)
		dllwrap = self.exename.get('dllwrap', 'dllwrap')
		return self.execute(dllwrap, parameters, printcmd, capture)
	
	# 生成lib库
	def makelib (self, output, objs = [], printcmd = False, capture = False):
		if 0:
			name = ' '.join([ self.pathrel(n) for n in objs ])
			parameters = 'crv %s %s'%(self.pathrel(output), name)
			return self.execute(self.exename['ar'], parameters, printcmd, capture)
		objs = [ n for n in objs ]
		for link in self.sequence(self.wlnk):
			if link[-2:] in ('.a', '.o'):
				if os.path.exists(link):
					objs.append(link)
		return self.composite(output, objs, printcmd, capture)
	
	# 生成动态链接：dll 或者 so
	def makedll (self, output, objs = [], param = '', printcmd = False, capture = False):
		if (not param) or (self.unix):
			if sys.platform[:6] == 'darwin':
				param = '-dynamiclib'
			else:
				param = '--shared'
			if self.fpic:
				param += ' -fPIC'
			return self.makeexe(output, objs, param, printcmd, capture)
		else:
			name = ' '.join([ self.pathrel(n) for n in objs ])
			parameters = '%s -o %s %s'%(param, 
				self.pathrel(output), name)
			return self.dllwrap(parameters, printcmd, capture)
	
	# 生成exe
	def makeexe (self, output, objs = [], param = '', printcmd = False, capture = False):
		name = ' '.join([ self.pathrel(n) for n in objs ])
		if self.xlink:
			name = '-Xlinker "-(" ' + name + ' -Xlinker "-)"'
		parameters = '-o %s %s %s'%(self.pathrel(output), param, name)
		return self.gcc(parameters, True, printcmd, capture)

	# 合并.o .a文件为新的 .a文件 
	def composite (self, output, objs = [], printcmd = False, capture = False):
		import os, tempfile, shutil
		cwd = os.getcwd()
		temp = tempfile.mkdtemp('.int', 'lib')
		output = os.path.abspath(output)
		libname = []
		for name in [ os.path.abspath(n) for n in objs ]:
			if not name in libname:
				libname.append(name)
		outpath = os.path.join(temp, 'out')
		srcpath = os.path.join(temp, 'src')
		os.mkdir(outpath)
		os.mkdir(srcpath)
		os.chdir(srcpath)
		names = {}
		for source in libname:
			os.chdir(srcpath)
			for fn in [ n for n in os.listdir('.') ]:
				os.remove(fn)
			files = []
			filetype = os.path.splitext(source)[-1].lower()
			if filetype == '.o':
				files.append(source)
			else:
				args = '-x %s'%self.pathrel(source)
				self.execute(self.exename['ar'], args, printcmd, capture)
				for fn in os.listdir('.'):
					files.append(os.path.abspath(fn))
			for fn in files:
				name = os.path.split(fn)[-1]
				part = os.path.splitext(name)
				last = None
				for i in xrange(1000):
					newname = (i > 0) and (part[0] + '_%d'%i + part[1]) or name
					if not newname in names:
						last = newname
						break
				if last and os.path.exists(fn):
					names[last] = 1
					shutil.copyfile(fn, os.path.join(outpath, last))
		os.chdir(outpath)
		args = ['crv', self.pathrel(output)]
		args = ' '.join(args + [self.pathrel(n) for n in names])
		try: os.remove(output)
		except: pass
		self.execute(self.exename['ar'], args, printcmd, capture)
		os.chdir(cwd)
		shutil.rmtree(temp)
		return 0

	# 运行工具
	def cmdtool (self, sectname, exename, parameters, printcmd = False):
		envsave = [ (n, os.environ[n]) for n in os.environ ]
		hr = self._cmdline_init(sectname, exename)
		if type(hr) != type(''):
			if hr == -1:
				msg = 'cmdtool error: can not find %s env !!'%(sectname)
			else:
				msg = 'cmdtool error: can not find %s exe !!'%(exename)
			sys.stderr.write(msg + '\n')
			sys.stderr.flush()
			return -2
		path = hr
		cmd = '%s %s'%(path, parameters)
		if printcmd:
			print '>', cmd
		sys.stdout.flush()
		sys.stderr.flush()
		os.system(cmd)
		envflag = {}
		remove = []
		for n, v in envsave:
			os.environ[n] = v
			envflag[n] = True
		for n in os.environ:
			if not n in envflag:
				remove.append(n)
		for n in remove:
			del os.environ[n]
		return 0
	
	# 调用 Cygwin Bash
	def cygwin_bash (self, cmds, capture = False):
		import subprocess
		output = ''
		bashpath = self.pathshort(os.path.join(self.cygwin, 'bin/bash.exe'))
		if 'Popen' in subprocess.__dict__:
			args = [ bashpath, '--login' ]
			outmode = capture and subprocess.PIPE or None
			p = subprocess.Popen(args, shell = False, \
				stdin = subprocess.PIPE, stdout = outmode, \
				stderr = subprocess.STDOUT)
			stdin, stdouterr = (p.stdin, p.stdout)
			stdin.write(cmds + '\nexit\n')
			stdin.flush()
			if capture:
				output = stdouterr.read()
			p.wait()
		else:
			p = None
			stdin, stdouterr = os.popen4('%s --login'%bashpath, 'b')	
			stdin.write(cmds + '\nexit\n')
			stdin.flush()
			if not capture:
				while True:
					output = stdouterr.readline()
					if output == '':
						break
					sys.stdout.write(output + '\n')
					sys.stdout.flush()
			else:
				output = stdouterr.read()
		stdin = None
		stdouterr = None
		return output
	
	# 运行 Cygwin 命令行
	def cygwin_execute (self, sect, exename, parameters = '', capture = 0):
		capture = capture and True or False
		sect = sect.lower()
		home = self.win2cyg(os.getcwd())
		cmds = 'export LANG=C\n'
		if sect in self.config:
			for n in self.config[sect]:
				cmds += 'export %s="%s"\n'%(n.upper(), self.config[sect][n])
		cmds += 'cd "%s"\n'%self.win2cyg(os.getcwd())
		if exename:
			exename = self.win2cyg(exename)
			cmds += '"%s" %s\n'%(exename, parameters)
		else:
			cmds += '%s\n'%parameters
		if 0:
			print '-' * 72
			print cmds
			print '-' * 72
		os.environ['EMAKECYGWIN'] = '1'
		return self.cygwin_bash(cmds, capture)

	# 读取连接基准地址
	def readlink (self, fn):
		if not self.unix:
			return fn
		while True:
			try:
				f2 = os.readlink(fn)
				fn = f2
			except:
				break
		return fn

	# 搜索 Python开发路径
	def python_config (self):
		cflags = self._getitem('default', 'python_cflags', None)
		ldflags = self._getitem('default', 'python_ldflags', None)
		if cflags or ldflags:
			return (cflags.strip('\r\n\t '), ldflags.strip('\r\n\t '))
		pythoninc, pythonlib = [], []
		import distutils.sysconfig
		sysconfig = distutils.sysconfig
		inc1 = sysconfig.get_python_inc()
		inc2 = sysconfig.get_python_inc(plat_specific = True)
		pythoninc.append('-I' + self.pathtext(inc1))
		if inc2 != inc1:
			pythoninc.append('-I' + self.pathtext(inc2))
		pyver = sysconfig.get_config_var('VERSION')
		getvar = sysconfig.get_config_var
		if not pyver:
			v1, v2 = sys.version_info[:2]
			pyver = self.unix and '%s.%s'%(v1, v2) or '%s%s'%(v1, v2)
		lib1 = getvar('LIBS')
		pythonlib.extend(lib1 and lib1.split() or [])
		prefix = sys.prefix
		if os.path.exists(prefix):
			if not pythoninc:
				n1 = os.path.join(prefix, 'include/python%s'%pyver)
				n2 = os.path.join(prefix, 'include')
				if os.path.exists(n1 + '/Python.h'):
					pythoninc.append('-I' + self.pathtext(n1))
				elif os.path.exists(n2 + '/Python.h'):
					pythoninc.append('-I' + self.pathtext(n2))
			if not pythonlib:
				n1 = os.path.join(prefix, 'lib/python%s'%pyver)
				n2 = os.path.join(n1, 'config')
				n3 = os.path.join(prefix, 'libs')
				fn1 = 'libpython' + pyver + '.a'
				fn2 = 'libpython' + pyver + '.dll.a'
				done = False
				for ff in (fn1, fn2):
					for nn in (n1, n2, n3):
						if os.path.exists(nn + '/' + ff):
							pythonlib.append('-L' + self.pathtext(nn))
							done = True
							break
					if done:
						break
		lib2 = getvar('SYSLIBS')
		pythonlib.extend(lib2 and lib2.split() or [])
		if not getvar('Py_ENABLE_SHARED'):
			if getvar('LIBPL'):
				pythonlib.insert(0, '-L' + getvar('LIBPL'))
		if not getvar('PYTHONFRAMEWORK'):
			if getvar('LINKFORSHARED'):
				pythonlib.extend(getvar('LINKFORSHARED').split())
		pythonlib.append('-lpython' + pyver)
		cflags = ' '.join(pythoninc)
		ldflags = ' '.join(pythonlib)
		return cflags, ldflags
	
	# 最终完成 java配置
	def __java_final (self, home):
		path = [ home ]
		subdir = []
		try:
			for sub in os.listdir(home):
				newpath = os.path.join(home, sub)
				if os.path.isdir(newpath):
					import difflib
					m = difflib.SequenceMatcher(None, sys.platform, sub)
					subdir.append((m.ratio(), sub))
		except:
			pass
		subdir.sort()
		if subdir:
			path.append(os.path.join(home, subdir[-1][1]))
		return ' '.join([ '-I%s'%self.pathtext(n) for n in path ])

	# 取得 java配置
	def java_home (self):
		jdk = self._getitem('default', 'java', None)
		if jdk:
			jdk = os.path.abspath(jdk)
			if os.path.exists(os.path.join(jdk, 'include/jni.h')):
				return jdk
		jdk = os.environ.get('JAVA_HOME', None)
		if jdk:
			jdk = os.path.abspath(jdk)
			if os.path.exists(jdk):
				return jdk
		spliter = self.unix and ':' or ';'
		PATH = os.environ.get('PATH', '')
		for path in PATH.split(spliter):
			path = path.strip('\r\n\t ')
			if not os.path.exists(path):
				continue
			fn = os.path.join(path, 'javac')
			if not self.unix: fn += '.exe'
			if not os.path.exists(fn):
				continue
			fn = self.readlink(fn)
			if not os.path.exists(fn):
				continue
			pp = os.path.abspath(os.path.join(os.path.dirname(fn), '..'))
			pp = os.path.join(pp, 'include')
			if not os.path.exists(pp):
				continue
			jni = os.path.join(pp, 'jni.h')
			if os.path.exists(jni):
				pp = os.path.join(pp, '../')
				return os.path.abspath(pp)
		if self.unix:
			for i in xrange(20, 4, -1):
				n = '/usr/local/openjdk%d'%i
				if os.path.exists(os.path.join(n, 'include/jni.h')):
					return os.path.abspath(n)
				n = '/usr/jdk/instances/jdk1.%d.0'%i
				if os.path.exists(os.path.join(n, 'include/jni.h')):
					return os.path.abspath(n)
		return ''

	# 取得 java配置
	def java_config (self):
		cflags = self._getitem('default', 'java_cflags', None)
		if cflags:
			return cflags.strip('\r\n\t ')
		jdk = self.java_home()
		if not jdk:
			return ''
		return self.__java_final(os.path.join(jdk, 'include'))
	
	# 执行 java命令: cmd 为 java, javac, jar等
	def java_call (self, cmd, args = [], capture = False):
		if self.__jdk_home == None:
			self.__jdk_home = self.java_home()
		if not self.__jdk_home:
			sys.stderr.write('can not find java in $JAVA_HOME or $PATH\n')
			sys.stderr.flush()
			sys.exit(1)
			return None
		if not self.unix:
			ext = os.path.splitext(cmd)[-1].lower()
			if not ext:
				cmd += '.exe'
		cc = os.path.join(self.__jdk_home, 'bin/%s'%cmd)
		if not os.path.exists(cc):
			sys.stderr.write('can not find %s in %s\n'%(cmd, self.__jdk_home))
			sys.stderr.flush()
			sys.exit(1)
			return None
		cmd = cc
		if not self.unix:
			cmd = self.pathshort(cmd)
		cmds = [ cmd ]
		for n in args: 
			cmds.append(n)
		return execute(cmds, False, capture)
		

#----------------------------------------------------------------------
# coremake: 核心工程编译，提供 Compile/Link/Build
#----------------------------------------------------------------------
class coremake(object):
	
	# 构造函数
	def __init__ (self, ininame = ''):
		self.ininame = ininame
		self.config = configure(self.ininame)
		self.unix = self.config.unix
		self.inited = 0
		self.extnames = self.config.extnames
		self.envos = {}
		for k, v in os.environ.items():
			self.envos[k] = v
		self.reset()
	
	# 复位配置
	def reset (self):
		self.config.reset()
		self._out = ''		# 最终输出的文件，比如abc.exe
		self._int = ''		# 中间文件的目录
		self._main = ''		# 主文件(工程文件)
		self._mode = 'exe'	# exe win dll lib
		self._src = []		# 源代码
		self._obj = []		# 目标文件
		self._opt = []
		self._export = {}	# DLL导出配置
		self._environ = {}	# 环境变量
		self.inited = 0
		
	# 初始化：设置工程名字，类型，以及中间文件的目录
	def init (self, main, out = 'a.out', mode = 'exe', intermediate = ''):
		if not mode in ('exe', 'win', 'dll', 'lib'):
			raise Exception("mode must in ('exe', 'win', 'dll', 'lib')")
		self.reset()
		self.config.init()
		self.config.loadcfg()
		self._main = os.path.abspath(main)
		self._mode = mode
		self._out = os.path.abspath(out)
		self._int = intermediate
		self._out = self.outname(self._out, mode)
	
	# 取得源文件对应的目标文件：给定源文件名和中间文件目录名
	def objname (self, srcname, intermediate = ''):
		part = os.path.splitext(srcname)
		ext = part[1].lower()
		if ext in self.extnames:
			if intermediate:
				name = os.path.join(intermediate, os.path.split(part[0])[-1])
				name = os.path.abspath(name + '.o')
			else:
				name = os.path.abspath(part[0] + '.o')
			return name
		if not ext in ('.o', '.obj'):
			raise Exception('unknow ext-type of %s\n'%srcname)
		return srcname
	
	# 取得输出文件的文件名
	def outname (self, output, mode = 'exe'):
		if not mode in ('exe', 'win', 'dll', 'lib'):
			raise Exception("mode must in ('exe', 'win', 'dll', 'lib')")
		part = os.path.splitext(os.path.abspath(output))
		output = part[0]
		if mode == 'exe':
			if self.unix == 0 and part[1] == '':
				output += '.exe'
			elif part[1]:
				output += part[1]
		elif mode == 'win':
			if self.unix == 0 and part[1] == '':
				output += '.exe'
			elif part[1]:
				output += part[1]
		elif mode == 'dll':
			if not part[1]: 
				if not self.unix: output += '.dll'
				else: output += '.so'
			else:
				output += part[1]
		elif mode == 'lib':
			if not part[1]: output += '.a'
			else: output += part[1]
		return output
	
	# 根据源文件列表取得目标文件列表
	def scan (self, sources, intermediate = ''):
		src2obj = {}
		obj2src = {}
		for src in sources:
			obj = self.objname(src, intermediate)
			if obj in obj2src:
				p1, p2 = os.path.splitext(obj)
				index = 1
				while True:
					name = '%s%d%s'%(p1, index, p2)
					if not name in obj2src:
						obj = name
						break
					index += 1
			src2obj[src] = obj
			obj2src[obj] = src
		obj2src = None
		return src2obj
	
	# 添加源文件和目标文件
	def push (self, srcname, objname, options):
		self._src.append(os.path.abspath(srcname))
		self._obj.append(os.path.abspath(objname))
		self._opt.append(options)
	
	# 创建目录
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
	
	# 删除目录
	def remove (self, path):
		try: os.remove(path)
		except: pass
		if os.path.exists(path):
			sys.stderr.write('error: cannot remove \'%s\'\n'%path)
			sys.stderr.flush()
			sys.exit(0)
		return 0
	
	# DLL配置
	def dllwrap (self, name):
		if sys.platform[:3] != 'win':
			return -1
		if self._mode != 'dll':
			return -2
		name = name.lower()
		main = os.path.splitext(os.path.abspath(self._out))[0]
		main = os.path.split(main)[-1]
		main = os.path.abspath(os.path.join(self._int, main))
		if name == 'def':
			self._export['def'] = main + '.def'
		elif name == 'lib':
			self._export['lib'] = main + '.a'
		elif name in ('hidden', 'hide', 'none'):
			self._export['hide'] = 1
		elif name in ('msvc', 'MSVC'):
			self._export['def'] = main + '.def'
			self._export['msvc'] = main + '.lib'
			self._export['msvc64'] = 0
		elif name in ('msvc64', 'MSVC64'):
			self._export['def'] = main + '.def'
			self._export['msvc'] = main + '.lib'
			self._export['msvc64'] = 1
		return 0
	
	# DLL export的参数
	def _dllparam (self):
		defname = self._export.get('def', '')
		libname = self._export.get('lib', '')
		msvclib = self._export.get('msvc', '')
		hidden = self._export.get('hide', 0)
		if (not defname) and (not libname):
			return ''
		param = ''
		if not hidden: param += '--export-all '
		if defname:
			param += '--output-def %s '%self.config.pathrel(defname)
		if libname:
			param += '--implib %s '%self.config.pathrel(libname)
		return param
	
	# DLL 编译完成后的事情
	def _dllpost (self):
		defname = self._export.get('def', '')
		libname = self._export.get('lib', '')
		msvclib = self._export.get('msvc', '')
		dllname = self._out
		if not msvclib:
			return 0
		if not os.path.exists(defname):
			return -1
		machine = '/machine:i386'
		msvc64 = self._export.get('msvc64', 0)
		if msvc64:
			machine = '/machine:x64'
		defname = self.config.pathtext(self.config.pathrel(defname))
		msvclib = self.config.pathtext(self.config.pathrel(msvclib))
		parameters = '-nologo ' + machine + ' /def:' + defname
		parameters += ' /out:' + msvclib
		self.config.cmdtool('msvc', 'LIB.EXE', parameters, False)
		return 0
	
	# 单核编译：skipexist(是否需要跳过已有的obj文件)
	def _compile_single (self, skipexist, printmode, printcmd):
		retval = 0
		for i in xrange(len(self._src)):
			srcname = self._src[i]
			objname = self._obj[i]
			options = self._opt[i]
			if srcname == objname:
				continue
			if skipexist and os.path.exists(objname):
				continue
			try: os.remove(os.path.abspath(objname))
			except: pass
			if printmode & 1:
				name = self.config.pathrel(srcname)
				if name[:1] == '"':
					name = name[1:-1]
				if CFG['abspath']:
					name = os.path.abspath(srcname)
				print name
			self.config.compile(srcname, objname, options, printcmd)
			if not os.path.exists(objname):
				retval = -1
				break
		return retval
	
	# 多核编译：skipexist(是否需要跳过已有的obj文件)
	def _compile_threading (self, skipexist, printmode, printcmd, cpus):
		# 估算编译时间，文件越大假设时间越长，放在最前面
		ctasks = [ (os.path.getsize(s), s, o, t) for s, o, t in zip(self._src, self._obj, self._opt) ]
		ctasks.sort()
		import threading
		self._task_lock = threading.Lock()
		self._task_retval = 0
		self._task_finish = False
		self._task_queue = ctasks
		self._task_thread = []
		self._task_error = ''
		for n in xrange(cpus):
			parameters = (skipexist, printmode, printcmd, cpus - 1 - n)
			th = threading.Thread(target = self._compile_working_thread, args = parameters)
			self._task_thread.append(th)
		for th in self._task_thread:
			th.start()
		for th in self._task_thread:
			th.join()
		self._task_thread = None
		self._task_lock = None
		self._task_queue = None
		for objname in self._obj:
			if not os.path.exists(objname):
				self._task_retval = -1
				break
		return self._task_retval
	
	# 具体编译线程
	def _compile_working_thread (self, skipexist, printmode, printcmd, id):
		mutex = self._task_lock
		while True:
			weight, srcname, objname = 0, '', ''
			mutex.acquire()
			if self._task_finish:
				mutex.release()
				break
			if not self._task_queue:
				mutex.release()
				break
			weight, srcname, objname, options = self._task_queue.pop()
			mutex.release()
			if srcname == objname:
				continue
			if skipexist and os.path.exists(objname):
				continue
			try: os.remove(os.path.abspath(objname))
			except: pass
			timeslap = time.time()
			output = self.config.compile(srcname, objname, options, printcmd, True)
			timeslap = time.time() - timeslap
			result = True
			if not os.path.exists(objname):
				mutex.acquire()
				self._task_retval = -1
				self._task_finish = True
				mutex.release()
				result = False
			mutex.acquire()
			if printmode & 1:
				name = self.config.pathrel(srcname)
				if name[:1] == '"':
					name = name[1:-1]
				if CFG['abspath']:
					name = os.path.abspath(srcname)
				sys.stdout.write(name + '\n')
			if sys.platform[:3] == 'win':
				lines = [ x.rstrip('\r\n') for x in output.split('\n') ]
				output = '\n'.join(lines)
			sys.stdout.write(output)
			sys.stdout.flush()
			mutex.release()
			time.sleep(0.01)
		return 0

	# 编译：skipexist(是否需要跳过已有的obj文件)
	def compile (self, skipexist = False, printmode = 0, cpus = 0):
		self.config.check()
		self.mkdir(os.path.abspath(self._int))
		printcmd = False
		if printmode & 4:
			printcmd = True
		if printmode & 2:
			print 'compiling ...'
		t = time.time()
		if cpus <= 1:
			retval = self._compile_single(skipexist, printmode, printcmd)
		else:
			retval = self._compile_threading(skipexist, printmode, printcmd, cpus)
		t = time.time() - t
		#print 'time', t
		return retval
	
	# 连接：(是否跳过已有的文件)
	def link (self, skipexist = False, printmode = 0):
		self.config.check()
		retval = 0
		printcmd = False
		if printmode & 4:
			printcmd = True
		if printmode & 2:
			print 'linking ...'
		output = self._out
		if skipexist and os.path.exists(output):
			return output
		self.remove(output)
		self.mkdir(os.path.split(output)[0])
		if self._mode == 'exe':
			self.config.makeexe(output, self._obj, '', printcmd)
		elif self._mode == 'win':
			param = '-mwindows'
			self.config.makeexe(output, self._obj, param, printcmd)
		elif self._mode == 'dll':
			param = self._dllparam()
			self.config.makedll(output, self._obj, param, printcmd)
			if param and os.path.exists(output): 
				self._dllpost()
		elif self._mode == 'lib':
			self.config.makelib(output, self._obj, printcmd)
		if not os.path.exists(output):
			return ''
		return output
	
	# 执行编译事件
	def event (self, scripts):
		if not scripts:
			return False
		# 保存环境
		envsave = {}
		for k, v in os.environ.items(): 
			envsave[k] = v
		# 初始化环境
		environ = {}
		for k, v in self._environ.items():
			environ[k] = v
		environ['EMAKE'] = os.path.abspath(__file__)
		environ['EMAKEP'] = os.path.dirname(os.path.abspath(__file__))
		environ['EMHOME'] = self.config.dirhome
		environ['EMOUT'] = self._out
		environ['EMINT'] = self._int
		environ['EMMAIN'] = self._main
		environ['EMPATH'] = os.path.dirname(self._main)
		environ['EMMODE'] = self._mode
		environ['EMMAINN'] = os.path.splitext(self._main)[0]
		environ['EMMAINE'] = os.path.splitext(self._main)[1]
		environ['EMMAINP'] = os.path.dirname(self._main)
		environ['EMOUTN'] = os.path.splitext(self._out)[0]
		environ['EMOUTE'] = os.path.splitext(self._out)[1]
		environ['EMOUTP'] = os.path.dirname(self._out)
		for name in ('gcc', 'ar', 'ld', 'as', 'nasm', 'yasm', 'dllwrap'):
			environ['EM' + name.upper()] = self.config.getname(name)
		for k, v in environ.items():	# 展开宏
			environ[k] = self.config._expand(environ, envsave, k)
		for k, v in environ.items():
			os.environ[k] = v
		# 执行应用
		workdir = os.path.dirname(self._main)
		savecwd = os.getcwd()
		for script in scripts:
			if savecwd != workdir: 
				os.chdir(workdir)
			os.system(script)
		os.chdir(savecwd)
		# 恢复环境
		for k, v in envsave.items():
			if os.environ.get(k) != v: 
				os.environ[k] = v
		for k in os.environ.keys():
			if not k in envsave: 
				del os.environ[k]
		return True
	
	# 编译与连接
	def build (self, skipexist = False, printmode = 0):
		if self.compile(skipexist, printmode) != 0:
			return -1
		output = self.link(skipexist, printmode)
		if output == '':
			return -2
		return output



#----------------------------------------------------------------------
# iparser: 工程分析器，分析各种配置信息
#----------------------------------------------------------------------
class iparser (object):
	
	# 构造函数
	def __init__ (self, ininame = ''):
		self.preprocessor = preprocessor()
		self.coremake = coremake(ininame)
		self.config = self.coremake.config
		self.extnames = self.config.extnames
		self.reset()

	# 配置复位
	def reset (self):
		self.src = []
		self.inc = []
		self.lib = []
		self.imp = []
		self.exp = []
		self.link = []
		self.flag = []
		self.flnk = []
		self.wlnk = []
		self.cond = []
		self.environ = {}
		self.events = {}
		self.mode = 'exe'
		self.define = {}
		self.name = ''
		self.home = ''
		self.info = 3
		self.out = ''
		self.int = ''
		self.makefile = ''
		self.incdict = {}
		self.libdict = {}
		self.srcdict = {}
		self.chkdict = {}
		self.optdict = {}
		self.impdict = {}
		self.expdict = {}
		self.linkdict = {}
		self.flagdict = {}
		self.flnkdict = {}
		self.wlnkdict = {}
		self.conddict = {}
		self.makefile = ''
	
	# 取得文件的目标文件名称
	def __getitem__ (self, key):
		return self.srcdict[key]
	
	# 取得模块个数
	def __len__ (self):
		return len(self.srcdict)
	
	# 检测是否包含模块
	def __contains__ (self, key):
		return (key in self.srcdict)
	
	# 取得迭代器
	def __iter__ (self):
		return self.src.__iter__()
	
	# 添加代码
	def push_src (self, filename, options):
		filename = os.path.abspath(filename)
		realname = os.path.normcase(filename)
		if filename in self.srcdict:	
			return -1
		if realname in self.chkdict:
			return -1
		self.srcdict[filename] = ''
		self.chkdict[realname] = ''
		self.optdict[filename] = options
		self.src.append(filename)
		return 0
	
	# 添加链接
	def push_link (self, linkname):
		if linkname in self.linkdict:
			return -1
		self.linkdict[linkname] = len(self.link)
		self.link.append(linkname)
		return 0
	
	# 添加头路径
	def push_inc (self, inc):
		if inc in self.incdict:
			return -1
		self.incdict[inc] = len(self.inc)
		self.inc.append(inc)
		return 0

	# 添加库路径
	def push_lib (self, lib):
		if lib in self.libdict:
			return -1
		self.libdict[lib] = len(self.lib)
		self.lib.append(lib)
		return 0
	
	# 添加参数
	def push_flag (self, flag):
		if flag in self.flagdict:
			return -1
		self.flagdict[flag] = len(self.flag)
		self.flag.append(flag)
		return 0
	
	# 添加宏定义
	def push_define (self, define, value = 1):
		self.define[define] = value
		return 0
	
	# 添加连接参数
	def push_flnk (self, flnk):
		if flnk in self.flnkdict:
			return -1
		self.flnkdict[flnk] = len(self.flnk)
		self.flnk.append(flnk)

	# 添加连接传递
	def push_wlnk (self, wlnk):
		if wlnk in self.wlnkdict:
			return -1
		self.wlnkdict[wlnk] = len(self.wlnk)
		self.wlnk.append(wlnk)

	# 添加条件编译
	def push_cond (self, flag, condition):
		key = (flag, condition)
		if key in self.conddict:
			return -1
		self.conddict[key] = len(self.cond)
		self.cond.append(key)
	
	# 添加导入配置
	def push_imp (self, name, fname = '', lineno = -1):
		if name in self.impdict:
			return -1
		self.impdict[name] = len(self.imp)
		self.imp.append((name, fname, lineno))
		return 0
	
	# 添加输出配置
	def push_exp (self, name, fname = '', lineno = -1):
		if name in self.expdict:
			return -1
		self.expdict[name] = len(self.exp)
		self.exp.append((name, fname, lineno))
	
	# 添加环境变量
	def push_environ (self, name, value):
		self.environ[name] = value
	
	# 添加编译事件
	def push_event (self, name, value):
		if not name in self.events:
			self.events[name] = []
		self.events[name].append(value)
	
	# 分析开始
	def parse (self, makefile):
		self.reset()
		self.config.init()
		makefile = os.path.abspath(makefile)
		self.makefile = makefile
		part = os.path.split(makefile)
		self.home = part[0]
		self.name = os.path.splitext(part[1])[0]
		if not os.path.exists(makefile):
			sys.stderr.write('error: %s cannot be open\n'%(makefile))
			sys.stderr.flush()
			return -1
		cfg = self.config.config.get('default', {})
		for name in ('prebuild', 'prelink', 'postbuild'):
			body = cfg.get(name, '').strip('\r\n\t ').split('&&')
			for script in body:
				script = script.strip('\r\n\t ')
				self.push_event(name, script)
		extname = os.path.splitext(makefile)[1].lower()
		if extname in ('.mak', '.em', '.emk', '.pyx', '.py'):
			if self.scan_makefile() != 0:
				return -3
		elif extname in self.extnames:
			if self.scan_mainfile() != 0:
				return -4
		else:
			sys.stderr.write('error: unknow file type of "%s"\n'%makefile)
			sys.stderr.flush()
			return -5
		if not self.out:
			self.out = os.path.splitext(makefile)[0]
		self.out = self.coremake.outname(self.out, self.mode)
		self._update_obj_names()
		return 0
	
	# 取得相对路径
	def pathrel (self, name, current = ''):
		if not current:
			current = os.getcwd()
		current = current.replace('\\', '/')
		if len(current) > 0:
			if current[-1] != '/':
				current += '/'
		name = self.path(name).replace('\\', '/')
		size = len(current)
		if name[:size] == current:
			name = name[size:]
		return name

	# 配置路径
	def pathconf (self, path):
		path = path.strip(' \r\n\t')
		if path[:1] == '\'' and path[-1:] == '\'': path = path[1:-1]
		if path[:1] == '\"' and path[-1:] == '\"': path = path[1:-1]
		return path.strip(' \r\n\t')
	
	# 扫描代码中 关键注释的工程信息
	def _scan_memo (self, filename, prefix = '!'):
		command = []
		content = open(filename, 'U').read()
		srctext = self.preprocessor.preprocess(content)
		srcline = [ 0 for i in xrange(len(srctext)) ]
		length = len(srctext)
		lineno = 1
		for i in xrange(len(srctext)):
			srcline[i] = lineno
			if srctext[i] == '\n':
				lineno += 1
		start = 0
		endup = 0
		while (start >= 0) and (start < length):
			start = endup
			endup = srctext.find('`', start)
			if endup < 0:
				break
			start = endup
			head = content[start:start + 2]
			body = ''
			if head == '//':
				endup = srctext.find('\n', start)
				if endup < 0: endup = length
				body = content[start + 2:endup]
				endup += 1
			elif head == '/*':
				endup = content.find('*/', start)
				if endup < 0: endup = length
				body = content[start + 2:endup]
				endup += 2
			else:
				Exception ('error comment')
			if body[:len(prefix)] != prefix:
				continue
			pos = start + 2 + len(prefix)
			body = body[len(prefix):]
			if pos >= length: pos = length - 1
			lineno = srcline[pos]
			for n in body.split('\n'):
				command.append((lineno, n.strip('\r\n').strip(' \t')))
				lineno += 1
		return command
	
	# 扫描主文件
	def scan_mainfile (self):
		command = self._scan_memo(self.makefile)
		savedir = os.getcwd()
		os.chdir(os.path.split(self.makefile)[0])
		retval = 0
		for lineno, text in command:
			if self._process(self.makefile, lineno, text) != 0:
				retval = -1
				break
		os.chdir(savedir)
		self.push_src(self.makefile, '')
		return retval

	# 扫描工程文件
	def scan_makefile (self):
		savedir = os.getcwd()
		os.chdir(os.path.split(self.makefile)[0])
		ext = os.path.splitext(self.makefile)[1].lower()
		lineno = 1
		retval = 0
		for text in open(self.makefile, 'U'):
			if ext in ('.pyx', '.py'):
				text = text.strip('\r\n\t ')
				if text[:3] != '##!':
					continue
				text = text[3:]
			if self._process(self.makefile, lineno, text) != 0:
				retval = -1
				break
			lineno += 1
		os.chdir(savedir)
		return retval
	
	# 输出错误
	def error (self, text, fname = '', line = -1):
		message = ''
		if fname and line > 0:
			message = '%s:%d: '%(fname, line)
		sys.stderr.write(message + text + '\n')
		sys.stderr.flush()
		return 0
	
	# 处理源文件
	def _process_src (self, textline, fname = '', lineno = -1):
		ext1 = ('.c', '.cpp', '.cc', '.cxx', '.asm')
		ext2 = ('.s', '.o', '.obj', '.m', '.mm')
		pos = textline.find(':')
		body, options = textline, ''
		pos = textline.find(':')
		if pos >= 0:
			split = (sys.platform[:3] != 'win') and True or False
			if sys.platform[:3] == 'win':
				if not textline[pos:pos + 2] in (':/', ':\\'):
					split = True
			if split:
				body = textline[:pos].strip('\r\n\t ')
				options = textline[pos + 1:].strip('\r\n\t ')
		for name in body.replace(';', ',').split(','):
			srcname = self.pathconf(name)
			if not srcname:
				continue
			if (not '*' in srcname) and (not '?' in srcname):
				names = [ srcname ]
			else:
				import glob
				names = glob.glob(srcname)
			for srcname in names:
				absname = os.path.abspath(srcname)
				if not os.path.exists(absname):
					self.error('error: %s: No such file'%srcname, \
						fname, lineno)
					return -1
				extname = os.path.splitext(absname)[1].lower()
				if (not extname in ext1) and (not extname in ext2):
					self.error('error: %s: Unknow file type'%absname, \
						fname, lineno)
					return -2
				self.push_src(absname, options)
		return 0

	# 处理：分析信息
	def _process (self, fname, lineno, text):
		text = text.strip(' \t\r\n')
		if not text:					# 空行
			return 0
		if text[:1] in (';', '#'):		# 跳过注释
			return 0
		pos = text.find(':')
		if pos < 0:
			self.error('unknow emake command', fname, lineno)
			return -1
		command, body = text[:pos].lower(), text[pos + 1:]
		pos = command.find('/')
		if pos >= 0:
			condition, command = command[:pos].lower(), command[pos + 1:]
			match = False
			for cond in condition.replace(';', ',').split(','):
				cond = cond.strip('\r\n\t ')
				if not cond: continue
				if cond in self.config.name:
					match = True
					break
			if not match:
				#print '"%s" not in %s'%(condition, self.config.name)
				return 0
		environ = {}
		environ['target'] = self.config.target
		environ['int'] = self.int
		environ['out'] = self.out
		environ['mode'] = self.mode
		environ['home'] = os.path.dirname(os.path.abspath(fname))
		environ['bin'] = self.config.dirhome
		for name in ('gcc', 'ar', 'ld', 'as', 'nasm', 'yasm', 'dllwrap'):
			if name in self.config.exename:
				data = self.config.exename[name]
				environ[name] = os.path.join(self.config.dirhome, data)
		environ['cc'] = environ['gcc']
		for name in environ:
			key = '$(%s)'%name
			val = environ[name]
			if key in body:
				body = body.replace(key, val)
		if command in ('out', 'output'):
			self.out = os.path.abspath(self.pathconf(body))
			return 0
		if command in ('int', 'intermediate'):
			self.int = os.path.abspath(self.pathconf(body))
			return 0
		if command in ('src', 'source'):
			retval = self._process_src(body, fname, lineno)
			return retval
		if command in ('mode', 'mod'):
			body = body.lower().strip(' \r\n\t')
			if not body in ('exe', 'win', 'lib', 'dll'):
				self.error('error: %s: mode is not supported'%body, \
					fname, lineno)
				return -1
			self.mode = body
			return 0
		if command == 'link':
			for name in body.replace(';', ',').split(','):
				srcname = self.pathconf(name)
				if not srcname:
					continue
				self.push_link(srcname)
			return 0
		if command in ('inc', 'lib'):
			for name in body.replace(';', ',').split(','):
				srcname = self.pathconf(name)
				if not srcname:
					continue
				absname = os.path.abspath(srcname)
				if not os.path.exists(absname):
					self.error('error: %s: No such directory'%srcname, \
						fname, lineno)
					return -1
				if command == 'inc': 
					self.push_inc(absname)
				elif command == 'lib':
					self.push_lib(absname)
			return 0
		if command == 'flag':
			for name in body.replace(';', ',').split(','):
				srcname = self.pathconf(name)
				if not srcname:
					continue
				if srcname[:2] in ('-o', '-I', '-B', '-L'):
					self.error('error: %s: invalid option'%srcname, \
						fname, lineno)
				self.push_flag(srcname)
			return 0
		if command in ('flnk', 'linkflag', 'flink'):
			for name in body.replace(';', ',').split(','):
				srcname = self.pathconf(name)
				if not srcname:
					continue
				self.push_flnk(srcname)
			return 0
		if command in ('wlnk', 'wl', 'ld', 'wlink'):
			for name in body.replace(';', ',').split(','):
				srcname = self.pathconf(name)
				if not srcname:
					continue
				self.push_wlnk(srcname)
			return 0
		for cond in ('cflag', 'cxxflag', 'sflag', 'mflag', 'mmflag'):
			if command == cond or command.rstrip('s') == cond:
				for name in body.replace(';', ',').split(','):
					flag = self.pathconf(name)
					if not flag:
						continue
					if flag[:2] in ('-o', '-I', '-B', '-L'):
						self.error('error: %s: invalid option'%flag, \
								fname, lineno)
					self.push_cond(flag, cond)
				return 0
		if command in ('arglink', 'al'):
			self.push_flnk(body.strip('\r\n\t '))
			return 0
		if command in ('argcc', 'ac'):
			self.push_flag(body.strip('\r\n\t '))
			return 0
		if command == 'define':
			for name in body.replace(';', ',').split(','):
				srcname = self.pathconf(name).replace(' ', '_')
				if not srcname:
					continue
				self.push_define(srcname)
			return 0
		if command == 'info':
			body = body.strip(' \t\r\n').lower()
			if body in ('0', 'false', 'off'):
				self.info = 0
			else:
				try: info = int(body)
				except: info = 3
				self.info = info
			return 0
		if command in ('cexe', 'clib', 'cdll' ,'cwin', 'exe', 'dll', 'win'):
			if not self.int:
				self.int = os.path.abspath(os.path.join('objs', self.config.target))
			self.mode = command[-3:]
			retval = self._process_src(body, fname, lineno)
			return retval
		if command in ('swf', 'swc', 'elf'):
			self.mode = 'exe'
			if not self.out:
				self.out = os.path.splitext(fname)[0] + '.' + command
			if not self.int:
				self.int = os.path.abspath(os.path.join('objs', self.config.target))
			body = body.strip('\r\n\t ')
			if command == 'swf':
				self.push_flnk('-emit-swf')
				pos = body.find('x')
				if pos >= 0:
					try:
						t1 = int(body[:pos])
						t2 = int(body[pos + 1:])
					except:
						self.error('error: %s: bad size'%body, fname, lineno)
						return -1
					self.push_flnk('-swf-size=%dx%d'%(t1, t2))
				elif body:
					self.error('error: %s: bad size'%body, fname, lineno)
					return -1
			elif command == 'swc':
				if not body:
					self.error('error: namespace empty', fname, lineno)
					return -1
				self.push_flnk('-emit-swc=' + body.strip('\t\n\r '))
			else:
				return self._process_src(body, fname, lineno)
			return 0
		if command in ('imp', 'import'):
			for name in body.replace(';', ',').split(','):
				name = self.pathconf(name)
				if not name:
					continue
				self.push_imp(name, fname, lineno)
			return 0
		if command in ('exp', 'export'):
			self.dllexp = 'yes'
			for name in body.replace(';', ',').split(','):
				name = self.pathconf(name).lower()
				if not name:
					continue
				self.push_exp(name, fname, lineno)
			return 0
		if command == 'echo':
			print body
			return 0
		if command == 'color':
			self.console(int(body.strip('\r\n\t '), 0))
			return 0
		if command in ('prebuild', 'prelink', 'postbuild'):
			self.push_event(command, body)
			return 0
		if command == 'environ':
			for name in body.replace(';', ',').split(','):
				name = name.strip('\r\n\t ')
				k, v = (name.split('=') + ['',''])[:2]
				self.push_environ(k.strip('\r\n\t '), v.strip('\r\n\t '))
			return 0
		if command == 'use':
			for name in body.replace(';', ',').split(','):
				name = name.strip('\r\n\t ')
				if name == 'python':
					cflags, ldflags = self.config.python_config()
					if cflags:
						self.push_flag(cflags)
					if ldflags:
						self.push_flnk(ldflags)
				elif name == 'java':
					java = self.config.java_config()
					if java:
						self.push_flag(java)
				else:
					tt = 'error: %s: invalid name to use, only python or java'
					self.error(tt%command, fname, lineno)
					return -1
			return 0
		self.error('error: %s: invalid command'%command, fname, lineno)
		return -1
	
	# 扫描并确定目标文件
	def _update_obj_names (self):
		src2obj = self.coremake.scan(self.src, self.int)
		for fn in self.src:
			obj = src2obj[fn]
			self.srcdict[fn] = os.path.abspath(obj)
		return 0
	
	# 设置终端颜色
	def console (self, color):
		if not os.isatty(sys.stdout.fileno()):
			return False
		if sys.platform[:3] == 'win':
			try: import ctypes
			except: return 0
			kernel32 = ctypes.windll.LoadLibrary('kernel32.dll')
			GetStdHandle = kernel32.GetStdHandle
			SetConsoleTextAttribute = kernel32.SetConsoleTextAttribute
			GetStdHandle.argtypes = [ ctypes.c_uint32 ]
			GetStdHandle.restype = ctypes.c_size_t
			SetConsoleTextAttribute.argtypes = [ ctypes.c_size_t, ctypes.c_uint16 ]
			SetConsoleTextAttribute.restype = ctypes.c_long
			handle = GetStdHandle(0xfffffff5)
			if color < 0: color = 7
			result = 0
			if (color & 1): result |= 4
			if (color & 2): result |= 2
			if (color & 4): result |= 1
			if (color & 8): result |= 8
			if (color & 16): result |= 64
			if (color & 32): result |= 32
			if (color & 64): result |= 16
			if (color & 128): result |= 128
			SetConsoleTextAttribute(handle, result)
		else:
			if color >= 0:
				foreground = color & 7
				background = (color >> 4) & 7
				bold = color & 8
				sys.stdout.write("\033[%s3%d;4%dm"%(bold and "01;" or "", foreground, background))
				sys.stdout.flush()
			else:
				sys.stdout.write("\033[0m")
				sys.stdout.flush()
		return 0


#----------------------------------------------------------------------
# dependence: 工程编译，Compile/Link/Build
#----------------------------------------------------------------------
class dependence (object):
	
	def __init__ (self, parser = None):
		self.parser = parser
		self.preprocessor = preprocessor()
		self.reset()
	
	def reset (self):
		self._mtime = {}
		self._dirty = {}
		self._depinfo = {}
		self._depname = ''
		self._outchg = False
	
	def mtime (self, fname):
		fname = os.path.abspath(fname)
		if fname in self._mtime:
			return self._mtime[fname]
		try: mtime = os.path.getmtime(fname)
		except: mtime = 0.0
		mtime = float('%.6f'%mtime)
		self._mtime[fname] = mtime
		return mtime
	
	def _scan_src (self, srcname):
		srcname = os.path.abspath(srcname)
		if not srcname in self.parser:
			return None
		if not os.path.exists(srcname):
			return None
		objname = self.parser[srcname]
		head, lost, src = self.preprocessor.dependence(srcname)
		filelist = [srcname] + head
		dependence = []
		for fn in filelist:
			name = os.path.abspath(fn)
			dependence.append((name, self.mtime(name)))
		return dependence
	
	def _update_dep (self, srcname):
		srcname = os.path.abspath(srcname)
		if not srcname in self.parser:
			return -1
		retval = 0
		debug = 0
		if debug: print '\n<dep:%s>'%srcname
		objname = self.parser[srcname]
		srctime = self.mtime(srcname)
		objtime = self.mtime(objname)
		update = False
		info = self._depinfo.setdefault(srcname, {})
		if len(info) == 0: 
			update = True
		if not update:
			for fn in info:
				if not os.path.exists(fn):
					update = True
					break
				oldtime = info[fn]
				newtime = self.mtime(fn)
				if newtime > oldtime:
					update = True
					#print '%f %f %f'%(newtime, oldtime, newtime - oldtime)
					break
		if update:
			dependence = self._scan_src(srcname)
			info = {}
			self._depinfo[srcname] = info
			if not dependence:
				return -2
			for fname, mtime in dependence:
				info[fname] = mtime
		info = self._depinfo[srcname]
		for fn in info:
			oldtime = info[fn]
			if oldtime > objtime:
				self._dirty[srcname] = 1
				retval = 1
				break
		if debug: print '</dep:%s>\n'%srcname
		return retval
	
	def _load_dep (self):
		lineno = -1
		retval = 0
		if os.path.exists(self._depname):
			for line in open(self._depname, 'U'):
				line = line.strip(' \t\r\n')
				if not line: continue
				pos = line.find('=')
				if pos < 0: continue
				src, body = line[:pos], line[pos + 1:]
				src = os.path.abspath(src)
				if not os.path.exists(src): continue
				item = body.replace(';', ',').split(',')
				count = len(item) / 2
				info = {}
				self._depinfo[src] = info
				for i in xrange(count):
					fname = item[i * 2 + 0].strip(' \r\n\t')
					mtime = item[i * 2 + 1].strip(' \r\n\t')
					fname = self.parser.pathconf(fname)
					info[fname] = float(mtime)
			retval = 0
		for fn in self.parser:
			self._update_dep(fn)
		return retval

	def _save_dep (self):
		path = os.path.split(self._depname)[0]
		if not os.path.exists(path):
			self.parser.coremake.mkdir(path)
		fp = open(self._depname, 'w')
		names = self._depinfo.keys()
		names.sort()
		for src in names:
			info = self._depinfo[src]
			fp.write('%s = '%(src))
			part = []
			keys = info.keys()
			keys.sort()
			for fname in keys:
				mtime = info[fname]
				if ' ' in fname: fname = '"%s"'%fname
				part.append('%s, %.6f'%(fname, mtime))
			fp.write(', '.join(part) + '\n')
		fp.close()
		return 0
	
	def process (self):
		self.reset()
		parser = self.parser
		depname = parser.name + '.p'
		self._depname = os.path.join(parser.home, depname)
		if parser.int:
			self._depname = os.path.join(parser.int, depname)
		self._depname = os.path.abspath(self._depname)
		self._load_dep()
		self._save_dep()
		for info in self._depinfo:
			dirty = (info in self._dirty) and 1 or 0
			#print info, '=', dirty
		return 0


#----------------------------------------------------------------------
# emake: 工程编译，Compile/Link/Build
#----------------------------------------------------------------------
class emake (object):
	
	def __init__ (self, ininame = ''):
		if ininame == '': ininame = 'emake.ini'
		self.parser = iparser(ininame)
		self.coremake = self.parser.coremake
		self.dependence = dependence(self.parser)
		self.config = self.coremake.config
		self.unix = self.coremake.unix
		self.cpus = -1
		self.loaded = 0
	
	def reset (self):
		self.parser.reset()
		self.coremake.reset()
		self.dependence.reset()
		self.loaded = 0
	
	def open (self, makefile):
		self.reset()
		self.config.init()
		environ = {}
		cfg = self.config.config
		if 'environ' in cfg:
			for k, v in cfg['environ'].items():
				environ[k.upper()] = v
		retval = self.parser.parse(makefile)
		if retval != 0:
			return -1
		parser = self.parser
		self.coremake.init(makefile, parser.out, parser.mode, parser.int)
		#print 'open', parser.out, parser.mode, parser.int
		for src in self.parser:
			obj = self.parser[src]
			opt = self.parser.optdict[src]
			self.coremake.push(src, obj, opt)
		savedir = os.getcwd()
		os.chdir(os.path.dirname(os.path.abspath(makefile)))
		hr = self._config()
		os.chdir(savedir)
		if hr != 0:
			return -2
		self.coremake._environ = {}
		for k, v in environ.items():
			self.coremake._environ[k] = v
		for k, v in self.parser.environ.items():
			self.coremake._environ[k] = v
		self.dependence.process()
		self.loaded = 1
		return 0
	
	def _config (self):
		self.config.replace['makefile'] = self.coremake._main
		self.config.replace['workspace'] = os.path.dirname(self.coremake._main)
		for name, fname, lineno in self.parser.imp:
			if not name in self.config.config:
				self.parser.error('error: %s: No such config section'%name, \
					fname, lineno)
				return -1
			self.config.loadcfg(name, True)
		for inc in self.parser.inc:
			self.config.push_inc(inc)
			#print 'inc', inc
		for lib in self.parser.lib:
			self.config.push_lib(lib)
			#print 'lib', lib
		for flag in self.parser.flag:
			self.config.push_flag(flag)
			#print 'flag', flag
		for link in self.parser.link:
			self.config.push_link(link)
			#print 'link', link
		for pdef in self.parser.define:
			self.config.push_pdef(pdef)
			#print 'pdef', pdef
		for flnk in self.parser.flnk:
			self.config.push_flnk(flnk)
			#print 'flnk', flnk
		for wlnk in self.parser.wlnk:
			self.config.push_wlnk(wlnk)
		for cond in self.parser.cond:
			self.config.push_cond(cond[0], cond[1])
		if self.parser.mode == 'dll' and self.config.unix:
			if self.config.fpic:
				self.config.push_flag('-fPIC')
		for name, fname, lineno in self.parser.exp:
			self.coremake.dllwrap(name)
		self.config.parameters()
		#print 'replace', self.config.replace
		return 0
	
	def compile (self, printmode = 0):
		if not self.loaded:
			return 1
		dirty = 0
		for src in self.parser:
			if src in self.dependence._dirty:
				obj = self.parser[src]
				if obj != src:
					self.coremake.remove(obj)
					dirty += 1
		if dirty:
			self.coremake.remove(self.parser.out)
			self.coremake.event(self.parser.events.get('prebuild', []))
		cpus = self.config.cpus
		if self.cpus >= 0:
			cpus = self.cpus
		retval = self.coremake.compile(True, printmode, cpus)
		if retval != 0:
			return 2
		return 0
	
	def link (self, printmode = 0):
		if not self.loaded:
			return 1
		update = False
		outname = self.parser.out
		outtime = self.dependence.mtime(outname)
		for src in self.parser:
			obj = self.parser[src]
			mtime = self.dependence.mtime(obj)
			if mtime == 0 or mtime > outtime:
				update = True
				break
		if update:
			self.coremake.remove(self.parser.out)
			self.coremake.event(self.parser.events.get('prelink', []))
		retval = self.coremake.link(True, printmode)
		if retval:
			self.coremake.event(self.parser.events.get('postbuild', []))
			return 0
		return 3
	
	def build (self, printmode = 0):
		if not self.loaded:
			return 1
		retval = self.compile(printmode)
		if retval != 0:
			return 2
		retval = self.link(printmode)
		if retval != 0:
			return 3
		return 0
	
	def clean (self):
		if not self.loaded:
			return 1
		for src in self.parser:
			obj = self.parser[src]
			if obj != src:
				self.coremake.remove(obj)
		if self.loaded:
			self.coremake.remove(self.parser.out)
		return 0
	
	def rebuild (self, printmode = -1):
		if not self.loaded:
			return 1
		self.clean()
		return self.build(printmode)

	def execute (self):
		if not self.loaded:
			return 1
		outname = os.path.abspath(self.parser.out)
		if not self.parser.mode in ('exe', 'win'):
			sys.stderr.write('cannot execute: \'%s\'\n'%outname)
			sys.stderr.flush()
			return 8
		if not os.path.exists(outname):
			sys.stderr.write('cannot find: \'%s\'\n'%outname)
			sys.stderr.flush()
			return 9
		os.system('"%s"'%outname)
		return 0
	
	def call (self, cmdline):
		if not self.loaded:
			return 1
		self.coremake.event([cmdline])
		return 0
		
	def info (self, name = ''):
		name = name.lower()
		if name == '': name = 'out'
		if name in ('out', 'outname'):
			print self.parser.out
		elif name in ('home', 'base'):
			print self.parser.home
		elif name in ('list'):
			for src in self.parser:
				print src
		elif name in ('dirty', 'changed'):
			for src in self.parser:
				if src in self.dependence._dirty:
					print src
		return 0
	

		
#----------------------------------------------------------------------
# speed up
#----------------------------------------------------------------------
def _psyco_speedup():
	try:
		import psyco
		psyco.bind(preprocessor)
		psyco.bind(configure)
		psyco.bind(coremake)
		psyco.bind(emake)
		#print 'full optimaze'
	except:
		return False
	return True



#----------------------------------------------------------------------
# distribution
#----------------------------------------------------------------------
def install():
	filepath = os.path.abspath(sys.argv[0])
	if not os.path.exists(filepath):
		print 'error: cannot open "%s"'%filepath
		return -1
	if sys.platform[:3] == 'win':
		print 'error: install must under unix'
		return -2
	try:
		f1 = open(filepath, 'r')
	except:
		print 'error: cannot read "%s"'%filepath
		return -3
	content = f1.read()
	f1.close()
	name2 = '/usr/local/bin/emake.py'
	name3 = '/usr/local/bin/emake'
	if os.path.exists(name2):
		print '/usr/local/bin/emake.py already exists, you should delete it'
		return -6
	if os.path.exists(name3):
		print '/usr/local/bin/emake already exists, you should delete it'
		return -7
	try:
		f2 = open(name2, 'w')
	except:
		print 'error: cannot write "%s"'%name2
		return -4
	try:
		f3 = open(name3, 'w')
	except:
		print 'error: cannot write "%s"'%name3
		f2.close()
		return -5
	f2.write(content)
	f3.write(content)
	f2.close()
	f3.close()
	os.system('chmod 755 /usr/local/bin/emake.py')
	os.system('chmod 755 /usr/local/bin/emake')
	os.system('chown root /usr/local/bin/emake.py 2> /dev/null')
	os.system('chown root /usr/local/bin/emake 2> /dev/null')
	print 'install completed. you can uninstall by deleting the following two files:'
	print '/usr/local/bin/emake.py'
	print '/usr/local/bin/emake'
	return 0

__updated_files = {}

def __update_file(name, content):
	source = ''
	name = os.path.abspath(name)
	if name in __updated_files:
		return 0
	__updated_files[name] = 1
	try: 
		fp = open(name, 'r')
		source = fp.read()
		fp.close()
	except:
		source = ''
	if content == source:
		print '%s up-to-date'%name
		return 0
	try:
		fp = open(name, 'w')
		fp.write(content)
		fp.close()
	except:
		print 'can not write to %s'%name
		return -1
	print '%s update succeeded'%name
	return 1

def getemake():
	import urllib2
	url1 = 'http://skywind3000.github.io/emake/emake.py'
	url2 = 'http://www.skywind.me/php/getemake.php'
	success = True
	content = ''
	for url in (url1, url2):
		print 'fetching', url, ' ...',
		sys.stdout.flush();
		success = True
		try:
			content = urllib2.urlopen(url).read()
		except urllib2.URLError, e:
			success = False
			print 'failed '
			print e
		head = content.split('\n')[0].strip('\r\n\t ')
		if head[:22] != '#! /usr/bin/env python':
			if success:
				print 'error'
			success = False
		if success:
			print 'ok'
			return content
	return ''

def update():
	content = getemake()
	if not content:
		print 'update failed'
		return -1
	name1 = os.path.abspath(sys.argv[0])
	name2 = '/usr/local/bin/emake.py'
	name3 = '/usr/local/bin/emake'
	__update_file(name1, content)
	if sys.platform[:3] == 'win':
		return 0
	r1 = __update_file(name2, content)
	r2 = __update_file(name3, content)
	if r1 > 0:
		os.system('chmod 755 /usr/local/bin/emake.py')
		os.system('chown root /usr/local/bin/emake.py 2> /dev/null')
	if r2 > 0:
		os.system('chmod 755 /usr/local/bin/emake')
		os.system('chown root /usr/local/bin/emake 2> /dev/null')
	print 'update finished !'
	return 0

def help():
	print "Emake 3.6.9 Dec.24 2017"
	print "By providing a completely new way to build your projects, Emake"
	print "is a easy tool which controls the generation of executables and other"
	print "non-source files of a program from the program's source files. "
	return 0


#----------------------------------------------------------------------
# extract param
#----------------------------------------------------------------------
def extract(parameter):
	if parameter[:2] != '${' or parameter[-1:] != '}':
		return parameter
	data = parameter[2:-1]
	pos = data.find(':')
	if pos < 0:
		return parameter
	fname, cname = data[:pos], data[pos + 1:]
	if not os.path.exists(fname):
		return parameter
	parser = iparser()
	command = parser._scan_memo(fname)
	value = ''
	for lineno, text in command:
		pos = text.find(':')
		if pos >= 0:
			name, data = text[:pos], text[pos + 1:]
			name = name.strip('\r\n\t ')
			if name == cname:
				value = data.strip('\r\n\t ')
	return value


#----------------------------------------------------------------------
# main program
#----------------------------------------------------------------------
def main(argv = None):
	# using psyco to speed up
	_psyco_speedup()

	# create main object
	make = emake()

	if argv == None:
		argv = sys.argv
	
	args = argv
	argv = argv[:1]
	options = {}

	for arg in args[1:]:
		if arg[:2] != '--':
			argv.append(arg)
			continue
		key = arg[2:].strip('\r\n\t ')
		val = None
		p1 = key.find('=')
		if p1 >= 0:
			val = key[p1 + 1:].strip('\r\n\t')
			key = key[:p1].strip('\r\n\t')
		options[key] = val

	inipath = ''

	if options.get('cfg', None) is not None:
		cfg = options['cfg']
		cfg = os.path.expanduser('~/.config/emake/%s.ini'%cfg)
		if not 'ini' in options:
			options['ini'] = cfg

	if options.get('ini', None) is not None:
		inipath = options['ini']
		if '~' in inipath:
			inipath = os.path.expanduser(inipath)
		inipath = os.path.abspath(inipath)

	if len(argv) <= 1:
		version = '(emake 3.6.9 Dec.21 2017 %s)'%sys.platform
		print 'usage: "emake.py [option] srcfile" %s'%version
		print 'options  :  -b | -build      build project'
		print '            -c | -compile    compile project'
		print '            -l | -link       link project'
		print '            -r | -rebuild    rebuild project'
		print '            -e | -execute    execute project'
		print '            -o | -out        show output file name'
		print '            -d | -cmdline    call cmdline tool in given environ'
		if sys.platform[:3] == 'win':
			print '            -g | -cygwin     cygwin execute'
			print '            -s | -cshell     cygwin shell'
		print '            -i | -install    install emake on unix'
		print '            -u | -update     update itself from github'
		print '            -h | -help       show help page'
		return 0
	
	if os.path.exists(inipath):
		global INIPATH
		INIPATH = inipath
	elif inipath:
		sys.stderr.write('error: not find %s\n'%inipath)
		sys.stderr.flush()
		return -1
	
	if argv[1] == '-check':
		make.config.init()
		make.config.check()
		dirhome = make.config.dirhome
		print 'home:', dirhome
		print 'gcc:', os.path.join(dirhome, make.config.exename['gcc'])
		print 'name:', make.config.name.keys()
		print 'target:', make.config.target
		return 0

	cmd, name = 'build', ''

	if len(argv) == 2:
		name = argv[1].strip(' ')
		if name in ('-i', '-install', '-install'):
			install()
			return 0
		if name in ('-u', '-update', '-update'):
			update()
			return 0
		if name in ('-h', '-help', '-help'):
			help()
			return 0

	if len(argv) <= 3:
		if name in ('-d', '-cmdline'):
			print 'usage: emake.py -cmdline envname exename [parameters]'
			print 'call the cmdline tool in the given environment:'
			print '- envname is a section name in emake.ini which defines environ for this tool'
			print '- exename is the tool\'s executable file name'
			return 0

	if len(argv) >= 3:
		cmd = argv[1].strip(' ').lower()
		name = argv[2]
	else:
		if name[:1] == '-':
			print 'not enough parameter: %s'%name
			return 0

	printmode = 3

	def int_safe(text, defval):
		num = defval
		try: num = int(text)
		except: pass
		return num

	def bool_safe(text, defval):
		if text is None:
			return True
		if text.lower() in ('true', '1', 'yes'):
			return True
		if text.lower() in ('0', 'false', 'no'):
			return False
		return defval

	if 'cpu' in options:
		make.cpus = int_safe(options['cpu'], 1)

	if 'print' in options:
		printmode = int_safe(options['print'], 3)

	if 'abs' in options:
		CFG['abspath'] = bool_safe(options['abs'], True)

	ext = os.path.splitext(name)[-1].lower() 
	ft1 = ('.c', '.cpp', '.cxx', '.cc', '.m', '.mm')
	ft2 = ('.h', '.hpp', '.hxx', '.hh', '.inc')
	ft3 = ('.mak', '.em', '.emk', '.py', '.pyx')

	if cmd in ('-d', '-cmdline', '-cmdline', '-m'):
		config = configure()
		config.init()
		argv += ['', '', '', '', '']
		envname = argv[2]
		exename = argv[3]
		parameters = ''
		for n in [ argv[i] for i in xrange(4, len(argv)) ]:
			if cmd in ('-m',):
				if n[:2] == '${' and n[-1:] == '}':
					n = extract(n)
					if not n: continue
			if config.unix:
				n = n.replace('\\', '\\\\').replace('"', '\\"')
				n = n.replace("'", "\\'").replace(' ', '\\ ')
				n = n.replace('\t', '\\t')
			else:
				if ' ' in n:
					n = '"' + n + '"'
			parameters += n + ' '
		config.cmdtool(envname, exename, parameters)
		return 0
	
	if cmd in ('-g', '-cygwin'):
		config = configure()
		config.init()
		if not config.cygwin:
			print 'not find "cygwin" in "default" sect of %s'%config.ininame
			sys.exit()
		argv += ['', '', '', '', '']
		envname = argv[2]
		exename = argv[3]
		parameters = ''
		for n in [ argv[i] for i in xrange(4, len(argv)) ]:
			if ' ' in n: n = '"' + n + '"'
			parameters += n + ' '
		config.cygwin_execute(envname, exename, parameters)
		return 0

	if cmd in ('-s', '-cshell'):
		config = configure()
		config.init()
		if not config.cygwin:
			print 'not find "cygwin" in "default" sect of %s'%config.ininame
			sys.exit()
		argv += ['', '', '', '', '']
		envname = argv[2]
		exename = argv[3]
		parameters = ''
		for n in [ argv[i] for i in xrange(4, len(argv)) ]:
			if ' ' in n: n = '"' + n + '"'
			parameters += n + ' '
		cmds = '"%s" %s'%(exename, parameters)
		config.cygwin_execute(envname, '', cmds)
		return 0

	if cmd == '-dump':
		if not name: name = '.'
		if not os.path.exists(name):
			print 'can not read: %s'%name
			return -1
		for root, dirs, files in os.walk(name):
			for fn in files:
				if os.path.splitext(fn)[-1].lower() in ('.c', '.cpp', '.cc'):
					xp = os.path.join(root, fn)
					if sys.platform[:3] == 'win':
						xp = xp.replace('\\', '/')
					if xp[:2] == './': 
						xp = xp[2:]
					print 'src: ' + xp
			if 'CVS' in dirs:
				dirs.remove('CVS')  # don't visit CVS directories
			if '.svn' in dirs:
				dirs.remove('.svn')
			if '.git' in dirs:
				dirs.remove('.git')
		return 0

	if not ((ext in ft1) or (ext in ft3)):
		sys.stderr.write('error: %s: unsupported file type\n'%(name))
		sys.stderr.flush()
		return -1

	retval = 0

	if cmd in ('b', '-b', 'build', '-build'):
		make.open(name)
		retval = make.build(printmode)
	elif cmd in ('c', '-c', 'compile', '-compile'):
		make.open(name)
		retval = make.compile(printmode)
	elif cmd in ('l', '-l', 'link', '-link'):
		make.open(name)
		retval = make.link(printmode)
	elif cmd in ('clean', '-clean'):
		make.open(name)
		retval = make.clean()
	elif cmd in ('r', '-r', 'rebuild', '-rebuild'):
		make.open(name)
		retval = make.rebuild(printmode)
	elif cmd in ('e', '-e', 'execute', '-execute'):
		make.open(name)
		retval = make.execute()
	elif cmd in ('a', '-a', 'call', '-call'):
		make.open(name)
		retval = make.call(' '.join(argv[3:]))
	elif cmd in ('o', '-o', 'out', '-out'):
		make.open(name)
		make.info('outname');
	elif cmd in ('dirty', '-dirty'):
		make.open(name)
		make.info('dirty')
	elif cmd in ('list', '-list'):
		make.open(name)
		make.info('list')
	elif cmd in ('home', '-home'):
		make.open(name)
		make.info('home')
	else:
		sys.stderr.write('unknow command: %s\n'%cmd)
		sys.stderr.flush()
		retval = 127
	return retval


#----------------------------------------------------------------------
# testing case
#----------------------------------------------------------------------
if __name__ == '__main__':
	def test1():
		make = coremake()
		name = 'e:/zombie/demo01.c'
		make.mkdir(r'e:\lab\malloc\obj list')
		make.mkdir(r'e:\lab\malloc\abc c\01 2\3 4\5\6')
		make.init('mainmod', 'exe', 'malloc\obj')
		make.push('malloc/main.c')
		make.push('malloc/mod1.c')
		make.push('malloc/mod2.c')
		make.push('malloc/mod3.c')
		make.build(printmode = 7)
		print os.path.getmtime('malloc/main.c')
	def test2():
		pst = preprocessor()
		head, lost, text = pst.dependence('voice/fastvoice/basewave.cpp')
		for n in head: print n
		pp = pst.preprocess(file('voice/fastvoice/basewave.cpp', 'U').read())
		print pp
	def test3():
		parser = iparser()
		parser._pragma_scan('malloc/main.c')
	def test4():
		parser = iparser()
		cmaker = coremake()
		parser.parse('malloc/main.c')
		print '"%s", "%s", "%s"'%(parser.out, parser.int, parser.mode)
		print parser.home, parser.name
		for n in parser:
			print 'src:', n, '->', cmaker.objname(n, ''), parser[n]
	def test5():
		parser = iparser()
		parser.parse('malloc/main.c')
		dep = dependence(parser)
		dep.process()
	def test6():
		make = emake()
		make.open('malloc/main.c')
		make.clean()
		make.build(3)
	def test7():
		config = configure()
		config.init()
		print config.checklib('liblinwei.a')
		print config.checklib('winmm')
		print config.checklib('pixia')
		config.push_lib('d:/dev/local/lib')
		print config.checklib('pixia')
	def test8():
		sys.argv = [sys.argv[0], '-d', 'msvc', 'cl.exe', '-help' ]
		sys.argv = [sys.argv[0], '-r', 'd:/acm/aprcode/pixellib/PixelBitmap.cpp' ]
		main()
		#os.chdir('d:/acm/aprcode/pixellib/')
		#os.system('d:/dev/python27/python.exe d:/acm/opensrc/easymake/testing/emake.py -r PixelBitmap.cpp')
	def test9():
		sys.argv = ['emake.py', '-t', 'msvc', 'cl.exe', '-help' ]
		sys.argv = [sys.argv[0], '-t', 'watcom', 'wcl386.exe', '-help' ]
		main()
	def test10():
		sys.argv = [sys.argv[0], '-g', 'default', 'd:/dev/flash/alchemy5/tutorials/01_HelloWorld/hello.exe', '--version']
		main()
	
	#test10()
	sys.exit( main() )
	#install()



