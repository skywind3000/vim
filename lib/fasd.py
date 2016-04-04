#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# fasd.py - 
#
# Created by skywind on 2018/01/27
# Last change: 2018/01/27 00:19:27
#
#======================================================================
from __future__ import print_function
import sys
import time
import os
import shutil
import codecs
import random
import re


#----------------------------------------------------------------------
# data file
#----------------------------------------------------------------------
class FasdData (object):

	def __init__ (self, filename, owner = None):
		if '~' in filename:
			filename = os.path.expanduser(filename)
		self.name = filename
		self.user = owner
		self.mode = -1
		self.home = os.path.expanduser('~')
		self.unix = (sys.platform[:3] != 'win')
		self.nocase = False
		self.maxage = 2000
		self.exclude = []

	# load z/fasd compatible file to a list of [path, rank, atime, 0]
	def load (self):
		data = []
		keys = {}
		try:
			with codecs.open(self.name, 'r', encoding = 'utf-8') as fp:
				for line in fp:
					part = line.split('|')
					if len(part) != 3:
						continue
					path = part[0]
					rank = 0
					try: rank = int(float(part[1]))
					except: pass
					atime = part[2].rstrip('\n')
					atime = atime.isdigit() and int(atime) or 0
					score = 0
					keys[path] = [path, rank, atime, score]
		except IOError:
			return []
		for key in keys:
			data.append(keys[key])
		return data

	# save data into text file in the line format of "path|rank|atime" 
	def save (self, data):
		def make_tempname(filename):
			if sys.platform[:3] == 'win':
				ts = int(time.time() * 1000)
				ts = hex(ts)[2:]
			else:
				ts = int(time.time() * 1000000)
				ts = hex(ts)[2:]
			ts += hex(random.randrange(65536))[2:]
			return filename + '.' + ts.lower()
		tmpname = make_tempname(self.name)
		retval = 0
		try:
			with codecs.open(tmpname, 'w', encoding = 'utf-8') as fp:
				for path, rank, atime, _ in data:
					fp.write('%s|%d|%d\n'%(path, rank, atime))
			if self.unix:
				if self.user:
					import pwd
					user = pwd.getpwnam(self.user)
					uid = user.pw_uid
					gid = user.pw_gid
					os.chown(self.name, uid, gid)
				if self.mode > 0:
					os.chmod(self.name, self.mode)
			shutil.move(tmpname, self.name)
		except IOError:
			retval = -1
		if os.path.exists(tmpname):
			try:
				os.remove(tmpname)
			except:
				pass
		return retval

	# check existence and filter
	def filter (self, data, what = 'a'):
		new_data = []
		for item in data:
			if what == 'a':
				if os.path.exists(item[0]):
					new_data.append(item)
			elif what == 'f':
				if os.path.isfile(item[0]):
					new_data.append(item)
			else:
				if os.path.isdir(item[0]):
					new_data.append(item)
		return new_data
			
	def print (self, data):
		for path, rank, atime, score in data:
			print('%s|%d|%d -> %s'%(path, rank, atime, score))
		return 0

	def pretty (self, data, noscore = False, reverse = False):
		output = [ (n[3], n[0]) for n in data ]
		output.sort(reverse = reverse)
		output = [ (str(n[0]), n[1]) for n in output ]
		maxlen = max([12] + [ len(n[0]) for n in output ]) + 2
		strfmt = '%%-%ds %%s'%maxlen
		for m, n in output:
			if noscore:
				print(n)
			else:
				print(strfmt%(m, n))
		return 0

	def string_match_fasd (self, string, args, nocase):
		pos = 0
		if nocase:
			string = string.lower()
		for arg in args:
			if arg.endswith('$'):
				arg = arg[:-1]
			pos = string.find(arg, pos)
			if pos < 0:
				return False
			pos += len(arg)
		if args:
			lastarg = args[-1]
			if self.unix:
				if lastarg.endswith('/'):
					return True
			else:
				if lastarg.endswith('\\'):
					return True
			if lastarg[-1:] == '$':
				return string.endswith(lastarg[:-1])
			lastpath = os.path.split(string)[-1]
			lastpath = lastpath and lastpath or string
			if not lastarg in lastpath:
				return False
		return True

	def string_match_z (self, string, patterns):
		for pat in patterns:
			m = pat.search(string)
			if not m:
				return False
			string = string[m.end():]
		return True

	def match (self, data, args, nocase, mode):
		if mode in (0, 'f', 'fasd'):
			if nocase:
				args = [ n.lower() for n in args ]
			f = lambda n: self.string_match_fasd(n[0], args, nocase)
			m = filter(f, data)
		elif mode in (1, 'z', 2, 'zc'):
			flags = nocase and re.I or 0
			patterns = [ re.compile(n, flags) for n in args ]
			f = lambda n: self.string_match_z(n[0], patterns)
			m = filter(f, data)
		else:
			return []
		return m

	def common (self, data, args):
		perf = os.path.commonprefix([ n[0] for n in data ])
		if not perf or perf == '/':
			return None
		lowperf = perf.lower()
		find = False
		for item in data:
			path = item[0]
			test = perf
			if self.nocase:
				path = path.lower()
				test = lowperf
			if test == path:
				find = True
				break
		if not find:
			return None
		for arg in args:
			flag = self.nocase and re.I or 0
			m = re.search(arg, perf, flag)
			if not m:
				return None
		return perf

	def search (self, data, args, mode):
		if self.nocase:
			m = self.match(data, args, True, mode)
		else:
			m = self.match(data, args, False, mode)
			if not m:
				m = self.match(data, args, True, mode)
		return m

	def score (self, data, mode):
		current = int(time.time())
		if mode in (0, 'frecent', 'f'):
			for item in data:
				atime = item[2]
				delta = current - atime
				if delta < 3600: 
					score = item[1] * 4
				elif delta < 86400: 
					score = item[1] * 2
				elif delta < 604800: 
					score = item[1] / 2
				else:
					score = item[1] / 4
				item[3] = score
		elif mode in (1, 'rank', 'r'):
			for item in data:
				item[3] = item[1]
		elif mode in (2, 'time', 't'):
			for item in data:
				atime = item[2]
				item[3] = atime - current
		return 0

	def insert (self, data, paths):
		if not isinstance(paths, list):
			paths = [paths]
		current = int(time.time())
		count = sum([ n[1] for n in data ])
		if count >= self.maxage:
			newdata = []
			for item in data:
				key = int(item[1] * 0.9)
				if key > 0:
					newdata.append(item)
			data = newdata
		keys = {}
		for item in data:
			key = self.nocase and item[0].lower() or item[0]
			keys[key] = item
		for path in paths:
			key = self.nocase and path.lower() or path
			if not key:
				continue
			if key in keys:
				item = keys[key]
				item[1] += 1
				item[2] = current
			else:
				keys[key] = [path, 1, current, 0]
		data = [ keys[n] for n in keys ]
		return data

	def remove (self, data, paths):
		if not isinstance(paths, list):
			paths = [paths]
		if not paths:
			return data
		keys = {}
		for item in data:
			key = self.nocase and item[0].lower() or item[0]
			keys[key] = item
		for path in paths:
			key = self.nocase and path.lower() or path
			if not key:
				continue
			if key in keys:
				del keys[key]
		data = [ keys[n] for n in keys ]
		return data

	def normalize (self, path):
		path = path.strip('\r\n\t ')
		if not path:
			return None
		path = os.path.normpath(path)
		key = self.nocase and path.lower() or path
		if (not path) or (not os.path.exists(path)):
			return None
		if self.unix:
			home = self.nocase and self.home.lower() or self.home
			if key == home:
				return None
		for exclude in self.exclude:
			if self.nocase:
				exclude = exclude.lower()
			if key.startswith(exclude):
				return None
		return path

	def add (self, data, paths):
		if not isinstance(paths, list):
			paths = [paths]
		new_paths = []
		for path in paths:
			path = self.normalize(path)
			if path:
				new_paths.append(path)
		return self.insert(data, new_paths)

	def delete (self, data, paths):
		if not isinstance(paths, list):
			paths = [paths]
		new_paths = []
		for path in paths:
			path = os.path.normpath(path)
			if path:
				new_paths.append(path)
		return self.remove(data, new_paths)

	def converge (self, data_list):
		path_dict = {}
		for data in data_list:
			for item in data:
				key = item[0]
				if self.nocase:
					key = key.lower()
				if not key in path_dict:
					path_dict[key] = item
				else:
					oi = path_dict[key]
					rank = oi[1]
					atime = oi[2]
					oi[1] = rank + item[1]
					oi[2] = max(atime, item[2])
		data = []
		for key in path_dict:
			data.append(path_dict[key])
		return data


#----------------------------------------------------------------------
# FasdNg
#----------------------------------------------------------------------
class FasdNg (object):

	def __init__ (self):
		datafile = os.environ.get('_F_DATA', os.path.expanduser('~/.fasd'))
		owner = os.environ.get('_F_OWNER', None)
		self.fd = FasdData(os.path.normpath(datafile), owner)
		self.unix = self.fd.unix
		self._init_environ()
		self.common = None
		self.data = None
		self.backend_map = {}
		self.method = 'frecent'

	def _init_environ (self):
		exclude = os.environ.get('_F_BLACKLIST', '')
		for black in exclude.split(self.unix and ':' or ';'):
			black = black.strip('\r\n\t ')
			if not black:
				continue
			self.fd.exclude.append(black)
		if sys.platform in ('cygwin', 'msys') or sys.platform[:3] == 'win':
			self.fd.nocase = True
		else:
			self.fd.nocase = False
		self.matcher = 0
		if os.environ.get('_F_MATCHER', 0) in ('z', '1'):
			self.matcher = 1
		self.track_pwd = True
		if os.environ.get('_F_TRACK_PWD', '') in ('0', 'no', 'false'):
			self.track_pwd = False
		self.track_file = True
		if os.environ.get('_F_TRACK_FILE', '') in ('0', 'no', 'false'):
			self.track_file = False
		self.readonly = False
		if os.environ.get('_F_READ_ONLY') in ('1', 'yes', 'true'):
			self.readonly = True
		self.backends = {}
		sep = self.unix and ':' or ';'
		for n in os.environ.get('_F_BACKENDS', '').split(sep):
			self.backends[n.strip('\r\n\t ')] = 1
		t = os.environ.get('_F_MAX_SCORE', '')
		if t.isdigit():
			self.fd.maxage = int(t)
		return 0

	def load (self):
		if self.data is None:
			data = self.fd.load()
			self.data = self.fd.filter(data)
		return self.data

	def save (self):
		if self.readonly:
			return False
		self.fd.save(self.data)
		return True

	def add (self, paths):
		if not isinstance(paths, list):
			paths = [paths]
		available = []
		for path in paths:
			path = os.path.normpath(path)
			if not os.path.exists(path):
				continue
			if os.path.isdir(path):
				if not self.track_pwd:
					continue
			else:
				if not self.track_file:
					continue
			if path:
				available.append(path)
		self.load()
		self.data = self.fd.add(self.data, available)
		self.save()
		return True

	def delete (self, paths):
		self.load()
		self.data = self.fd.delete(self.data, paths)
		self.save()
		return True

	# st: f, d, a
	def search (self, args, st):
		data = self.load()
		for backend in self.backends:
			source = []
			try:
				if backend.startswith('+'):
					source = self.backend_command(backend[1:])
				elif backend in self.backend_map:
					b = self.backend_map[backend]
					source = b()
			except:
				continue
			source = self.fd.filter(source)
			data = self.fd.converge([data, source])
		self.common = None
		m = self.fd.search(data, args, self.matcher)
		if st == 'f':
			m = filter(lambda n: os.path.isfile(n[0]), m)
		elif st == 'd':
			m = filter(lambda n: os.path.isdir(n[0]), m)
			self.common = self.fd.common(m, args)
		if self.method in (0, '0', 'f', 'frecent'):
			self.fd.score(m, 'f')
		elif self.method in (1, '1', 'r', 'rank', 'ranked'):
			self.fd.score(m, 'r')
		else:
			self.fd.score(m, 't')
		return m

	# query one result
	def query (self, args, mode):
		if args:
			lastarg = args[-1]
			if os.path.isabs(lastarg) and os.path.exists(lastarg):
				return lastarg
		m = self.search(args, mode)
		if not m:
			return None
		if self.matcher != 0:
			if self.common and mode == 'd':
				return self.common
		t = [ (n[3], n[0]) for n in m ]
		t.sort()
		return t[-1][1]

	# execute shell command and parse the output into a 
	# list of: [path, rank, atime, scroe]
	def backend_command (self, command):
		import subprocess
		p = subprocess.Popen(command, shell = True,
			stdin = None, stdout = subprocess.PIPE, stderr = None)
		output = p.stdout.read()
		p.wait()
		if isinstance(output, bytes):
			if sys.stdout and sys.stdout.encoding:
				output = output.encode(sys.stdout.encoding, 'ignore')
			elif sys.stdin and sys.stdin.encoding:
				output = output.encode(sys.stdin.encoding, 'ignore')
			else:
				output = output.encode('utf-8', 'ignore')
		data = []
		for line in output.split('\n'):
			part = line.rstrip('\r\n\t ').split('|')
			if len(part) != 3:
				continue
			path = part[0]
			rank = 0
			try: rank = int(float(part[1]))
			except: pass
			atime = part[2].rstrip('\n')
			atime = atime.isdigit() and int(atime) or 0
			score = 0
			data.append([path, rank, atime, score])
		return data
		
	def register (self, name, backend_function):
		self.backend_map[name] = backend_function
		return True


#----------------------------------------------------------------------
# backend_viminfo 
#----------------------------------------------------------------------
def backend_viminfo():
	data = []
	viminfo = os.environ.get('_F_VIMINFO', '')
	if not viminfo:
		if sys.platform[:3] != 'win':
			viminfo = os.path.expanduser('~/.viminfo')
		else:
			viminfo = os.path.expanduser('~/_viminfo')
	if not os.path.exists(viminfo):
		return data
	current = int(time.time())
	with open(viminfo, 'rb') as fp:
		content = fp.read()
		pos = 0
		encoding = 'utf-8'
		while True:
			next_pos = content.find(b'\n', pos)
			if next_pos < 0:
				break
			line = content[pos:next_pos]
			pos = next_pos + 1
			line = line.strip(b'\r\n\t ')
			if line.startswith(b'*encoding='):
				enc = line[len(b'*encoding='):].strip(b'\r\n\t ')
				encoding = enc.decode('utf-8', 'ignore')
		state = 0
		filename = ''
		text = content.decode(encoding, 'ignore')
		for line in text.split('\n'):
			line = line.rstrip('\r\n\t')
			if state == 0:
				if line.startswith('>'):
					filename = line[1:].lstrip(' \t')
					state = 1
			else:
				state = 0
				if not line[:1].isspace():
					data.append([filename, 2, current, 0])
					continue
				line = line.lstrip(' \t')
				if line[:1] != '*':
					data.append([filename, 2, current, 0])
					continue
				for part in line.split():
					if part.isdigit():
						ts = int(part)
						data.append([filename, 2, ts, 0])
						break
	new_data = []
	ignore_prefix = ['git:', 'ssh:', 'gista:']
	for item in data:
		name = item[0]
		skip = False
		for ignore in ignore_prefix:
			if name.startswith(ignore):
				skip = True
				break
		if not skip:
			if '~' in name:
				item[0] = os.path.expanduser(name)
			new_data.append(item)
	# return data
	data = filter(lambda n: os.path.exists(n[0]), new_data)
	return data


#----------------------------------------------------------------------
# command_proc - add filenames and pwd
#----------------------------------------------------------------------
IGNORE_LIST = ['cd', 'z', 'zz']

def command_proc(fn, fmt, args, pwd = True):
	paths = []
	# print('fmt=' + fmt)
	if fmt in ('bash', 'zsh', 'history'):
		args = args[1:]
	if not args:
		return 0
	cmd = args[0]
	if cmd in IGNORE_LIST:
		return 0
	ignore_env = os.environ.get('_F_IGNORE', '')
	if sys.platform[:3] == 'win':
		ignores = ignore_env.split(';')
	else:
		ignores = ignore_env.split(':')
	if cmd in ignores:
		return 0
	for arg in args[1:]:
		if arg.startswith('-'):
			continue
		if os.path.exists(arg):
			paths.append(os.path.abspath(arg))
	if pwd:
		dir = os.getcwd()
		if not dir in paths:
			paths.append(dir)
	if paths:
		fn.add(paths)
	return 0


#----------------------------------------------------------------------
# interactive_select
#----------------------------------------------------------------------
def interactive_select(fn, query, use_stderr):
	match = fn.search(query, fn.query_mode)
	if not match:
		return None
	s = [ (n[3], n[0]) for n in match ]
	fp = use_stderr and sys.stderr or sys.stdout
	s.sort(reverse = fn.reverse)
	s = [ [0, n[0], n[1]] for n in s ]
	w1 = 8
	w2 = 12
	index = len(s)
	for i in range(len(s)):
		n = s[i]
		n[0] = index
		index -= 1
		w1 = max(w1, len(str(n[0])))
		w2 = max(w2, len(str(n[1])))
	if fn.select_entry > 0:
		for n in s:
			if n[0] == fn.select_entry:
				return n[2]
		return None
	fmt = '%%-%ds %%-%ds %%s\n'%(w1 + 2, w2 + 2)
	for n in s:
		fp.write(fmt%(n[0], n[1], n[2]))
	fp.write('> ')
	fp.flush()
	try:
		select = raw_input()
		select = select.strip()
		if not select.isdigit():
			return None
		select = int(select)
	except:
		return None
	for n in s:
		if n[0] == select:
			return n[2]
	return None



#----------------------------------------------------------------------
# command_cd: change directory (output directory to stdout)
#----------------------------------------------------------------------
def command_cd(fn, query):
	fn.query_mode = 'd'
	if not query:
		match = fn.search([], 'd')
		sys.stdout = sys.stderr
		fn.fd.pretty(match)
		return 0
	if not fn.interactive:
		pwd = fn.query(query, 'd')
	else:
		pwd = interactive_select(fn, query, True)
	if not pwd:
		return 0
	sys.stdout.write(pwd)
	return 0


#----------------------------------------------------------------------
# command_exe: query and execute shell command
#----------------------------------------------------------------------
def command_exe(fn, query):
	if not fn.select_exec:
		return 0
	if not fn.interactive:
		n = fn.query(query, fn.query_mode)
	else:
		n = interactive_select(fn, query, False)
	if not n:
		return 0
	import pipes
	os.system(fn.select_exec + ' ' + pipes.quote(n))
	return 0

#----------------------------------------------------------------------
# command_query: query and output 
#----------------------------------------------------------------------
def command_query(fn, query):
	if not fn.interactive:
		n = fn.query(query, fn.query_mode)
	else:
		n = interactive_select(fn, query, True)
	if n:
		sys.stdout.write(n)
	return 0


#----------------------------------------------------------------------
# command_init: generate init script for shell eval
#----------------------------------------------------------------------
def command_init(fn, args):
	return 0


#----------------------------------------------------------------------
# docs
#----------------------------------------------------------------------
doc_help = '''fasd [options] [query ...]
[f|a|s|d|z] [options] [query ...]
  options:
    -s         list paths with scores
    -l         list paths without scores
    -i         interactive mode
    -e <cmd>   set command to execute on the result file
    -b <name>  only use <name> backend
    -B <name>  add additional backend <name>
    -a         match files and directories
    -d         match directories only
    -f         match files only
    -r         match by rank only
    -t         match by recent access only
    -R         reverse listing order
    -h         show a brief help message
    -[0-9]     select the nth entry

fasd [-A|-D] [paths ...]
    -A    add paths
    -D    delete paths
'''

#----------------------------------------------------------------------
# main
#----------------------------------------------------------------------
def main(args = None):
	args = [ n for n in (args and args or sys.argv) ]

	first = len(args) >= 2 and args[1] or ''

	fn = FasdNg()

	# add paths
	if first in ('-A', '--add'):
		paths = [ os.path.abspath(n) for n in args[2:] ]
		if paths:
			fn.add(paths)
		return 0
	# delete paths
	elif first in ('-D', '--delete'):
		paths = [ os.path.abspath(n) for n in args[2:] ]
		if paths:
			fn.delete(paths)
		return 0
	# process paths
	elif first.startswith('--proc'):
		head = '--proc='
		fmt = ''
		if first.startswith(head):
			fmt = first[len(head):].strip('\r\n\t ')
		command_proc(fn, fmt, args[2:])
		return 0
	# return init script for shell eval
	elif first == '--init':
		command_init(fn, args[2:])
		return 0
	# run completion
	elif first == '--complete':
		head = '--complete='
		mode = ''
		if first.startswith(head):
			mode = first[len(head):].strip('\r\n\t ')
		command_complete(fn, mode, args[2:])
		return 0
	# show help
	elif first in ('-h', '--help'):
		print(doc_help)
		return 0
		
	query = []
	options = []
	fn.select_entry = -1

	pos = 1
	while pos < len(args):
		arg = args[pos]
		if not arg.startswith('-'):
			break
		if arg == '-b':
			if pos + 1 < len(args):
				fd.backends = [arg[pos + 1]]
			pos += 2
		elif arg == '-B':
			if pos + 1 < len(args):
				fd.backends.append(args[pos + 1])
			pos += 2
		elif arg == '-e':
			if pos + 1 < len(args):
				fn.select_exec = args[pos + 1]
			pos += 2
		elif arg[1:].isdigit():
			fn.select_entry = int(arg[1:])
			pos += 1
		else:
			for n in arg[1:]:
				options.append(n)
			pos += 1
	
	query = args[pos:]

	# detect query mode: files/any/directories
	if 'f' in options:
		fn.query_mode = 'f'
	elif 'a' in options:
		fn.query_mode = 'a'
	elif 'd' in options:
		fn.query_mode = 'd'
	elif 'z' in options:
		fn.query_mode = 'z'
	else:
		fn.query_mode = 'a'

	# check score method
	if 'r' in options:
		fn.method = 'rank'
	elif 't' in options:
		fn.method = 'time'
	else:
		fn.method = 'frecent'

	fn.reverse = ('R' in options)
	fn.interactive = ('i' in options)
	
	# change directories
	if fn.query_mode == 'z' or 'c' in options:
		command_cd(fn, query)
		return 0

	# execute command
	if 'e' in options:
		command_exe(fn, query)
		return 0

	# query path
	if not sys.stdout.isatty():
		command_query(fn, query)
		return 0
	
	# select paths
	if 'i' in options or fn.select_entry > 0:
		n = interactive_select(fn, query, False)
		print(n)
		return 0

	# list querys
	match = fn.search(query, fn.query_mode)
	fn.fd.pretty(match, 'l' in options, fn.reverse)

	return 0


#----------------------------------------------------------------------
# testing
#----------------------------------------------------------------------
if __name__ == '__main__':

	def test1():
		fd = FasdData('d:/navdb.txt')
		data = fd.load()
		# data.append(['fuck', 0, 0])
		# print(len(data))
		fd.print(data)
		# fd.pretty(data)
		print()
		data = fd.filter(data)
		print(len(data))
		print()
		# fd.save(data)
		args = ['github', 'im']
		# args = ['D:\\']
		# args = []
		print(fd.string_match_fasd('d:\\acm\\github\\vim', args, 0))
		m = []
		# args = ['qemu']
		m = fd.search(data, args, 1)
		fd.score(m, 'f')
		# m = fd.match(data, ['vim$'])
		fd.pretty(m)
		print(fd.common(m, args))
		return 0

	def test2():
		fn = FasdNg()
		fn.readonly = True
		print(fn.fd.name)
		# fn.data = []
		# data = fn.backend_viminfo()
		fn.backends = ['viminfo']
		# fn.backend_map['viminfo'] = backend_viminfo
		# fn.fd.score(data, 'f')
		# fn.fd.pretty(fn.load())
		fn.add(['d:/linwei', 'd:/music'])
		fn.delete(['c:/users', 'd:/', 'e:/'])
		data = fn.search([''], 'd')
		# print(data)
		fn.fd.pretty(data)
		# fn.data = data
		# fn.save()
		return 0

	def test3():
		fn = FasdNg()
		fn.select_entry = -1
		fn.query_mode = 'a'
		fn.reverse = False
		s = interactive_select(fn, [''], False)
		print(s)
		return 0

	def test4():
		args = []
		args = ['--proc=bash', '10', 'ls', '-la']
		args = ['--help']
		main(sys.argv[:1] + args)

	def test5():
		fn = FasdNg()
		match = fn.search([], 'a')
		for n in match:
			print(n)
		return 0

	# test5()
	sys.exit(main())



