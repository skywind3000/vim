#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# ascmini.py - mini library
#
# Created by skywind on 2017/03/24
# Last change: 2017/03/24 19:42:40
#
#======================================================================
from __future__ import print_function
import sys
import time
import os
import socket


#----------------------------------------------------------------------
# python 2/3 compatible
#----------------------------------------------------------------------
if sys.version_info[0] >= 3:
	long = int
	unicode = str
	xrange = range

UNIX = (sys.platform[:3] != 'win') and True or False


#----------------------------------------------------------------------
# call program and returns output (combination of stdout and stderr)
#----------------------------------------------------------------------
def execute(args, shell = False, capture = False):
	import sys, os
	parameters = []
	cmd = None
	if not isinstance(args, list):
		import shlex
		cmd = args
		if sys.platform[:3] == 'win':
			ucs = False
			if sys.version_info[0] < 3:
				if not isinstance(cmd, str):
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
			replace = { ' ':'\\ ', '\\':'\\\\', '\"':'\\\"', '\t':'\\t',
				'\n':'\\n', '\r':'\\r' }
			text = ''.join([ replace.get(ch, ch) for ch in n ])
			parameters.append(text)
		else:
			if (' ' in n) or ('\t' in n) or ('"' in n): 
				parameters.append('"%s"'%(n.replace('"', ' ')))
			else:
				parameters.append(n)
	if cmd is None:
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
# call subprocess and returns retcode, stdout, stderr
#----------------------------------------------------------------------
def call(args, input_data = None, combine = False):
	import sys, os
	parameters = []
	for n in args:
		if sys.platform[:3] != 'win':
			replace = { ' ':'\\ ', '\\':'\\\\', '\"':'\\\"', '\t':'\\t', 
				'\n':'\\n', '\r':'\\r' }
			text = ''.join([ replace.get(ch, ch) for ch in n ])
			parameters.append(text)
		else:
			if (' ' in n) or ('\t' in n) or ('"' in n): 
				parameters.append('"%s"'%(n.replace('"', ' ')))
			else:
				parameters.append(n)
	cmd = ' '.join(parameters)
	import subprocess
	if 'Popen' in subprocess.__dict__:
		p = subprocess.Popen(args, shell = False,
			stdin = subprocess.PIPE, stdout = subprocess.PIPE,
			stderr = combine and subprocess.STDOUT or subprocess.PIPE)
		stdin, stdout, stderr = p.stdin, p.stdout, p.stderr
		if combine: stderr = None
	else:
		p = None
		if combine is False:
			stdin, stdout, stderr = os.popen3(cmd)
		else:
			stdin, stdout = os.popen4(cmd)
			stderr = None
	if input_data is not None:
		if not isinstance(input_data, bytes):
			if sys.stdin and sys.stdin.encoding:
				input_data = input_data.encode(sys.stdin.encoding, 'ignore')
			elif sys.stdout and sys.stdout.encoding:
				input_data = input_data.encode(sys.stdout.encoding, 'ignore')
			else:
				input_data = input_data.encode('utf-8', 'ignore')
		stdin.write(input_data)
		stdin.flush()
	exeout = stdout.read()
	if stderr: exeerr = stderr.read()
	else: exeerr = None
	stdin.close()
	stdout.close()
	if stderr: stderr.close()
	retcode = None
	if p:
		retcode = p.wait()
	return retcode, exeout, exeerr


#----------------------------------------------------------------------
# redirect process output to reader(what, text)
#----------------------------------------------------------------------
def redirect(args, reader, combine = True):
	import subprocess
	parameters = []
	for n in args:
		if sys.platform[:3] != 'win':
			replace = { ' ':'\\ ', '\\':'\\\\', '\"':'\\\"', '\t':'\\t', 
				'\n':'\\n', '\r':'\\r' }
			text = ''.join([ replace.get(ch, ch) for ch in n ])
			parameters.append(text)
		else:
			if (' ' in n) or ('\t' in n) or ('"' in n): 
				parameters.append('"%s"'%(n.replace('"', ' ')))
			else:
				parameters.append(n)
	cmd = ' '.join(parameters)
	if 'Popen' in subprocess.__dict__:
		p = subprocess.Popen(args, shell = False,
			stdin = subprocess.PIPE, stdout = subprocess.PIPE,
			stderr = combine and subprocess.STDOUT or subprocess.PIPE)
		stdin, stdout, stderr = p.stdin, p.stdout, p.stderr
		if combine: stderr = None
	else:
		p = None
		if combine is False:
			stdin, stdout, stderr = os.popen3(cmd)
		else:
			stdin, stdout = os.popen4(cmd)
			stderr = None
	stdin.close()
	while 1:
		text = stdout.readline()
		if text == b'' or text == '':
			break
		reader('stdout', text)
	while stderr is not None:
		text = stderr.readline()
		if text == b'' or text == '':
			break
		reader('stderr', text)
	stdout.close()
	if stderr: stderr.close()
	retcode = None
	if p:
		retcode = p.wait()
	return retcode


#----------------------------------------------------------------------
# OBJECT：enchanced object
#----------------------------------------------------------------------
class OBJECT (object):
	def __init__ (self, **argv):
		for x in argv: self.__dict__[x] = argv[x]
	def __getitem__ (self, x):
		return self.__dict__[x]
	def __setitem__ (self, x, y):
		self.__dict__[x] = y
	def __delitem__ (self, x):
		del self.__dict__[x]
	def __contains__ (self, x):
		return self.__dict__.__contains__(x)
	def __len__ (self):
		return self.__dict__.__len__()
	def __repr__ (self):
		line = [ '%s=%s'%(k, repr(v)) for k, v in self.__dict__.iteritems() ]
		return 'OBJECT(' + ', '.join(line) + ')'
	def __str__ (self):
		return self.__repr__()
	def __iter__ (self):
		return self.__dict__.__iter__()


#----------------------------------------------------------------------
# call stack
#----------------------------------------------------------------------
def callstack ():
	import traceback
	if sys.version_info[0] < 3:
		import cStringIO
		sio = cStringIO.StringIO()
	else:
		import io
		sio = io.StringIO()
	traceback.print_exc(file = sio)
	return sio.getvalue()


#----------------------------------------------------------------------
# Posix tools
#----------------------------------------------------------------------
class PosixKit (object):

	def __init__ (self):
		self.unix = (sys.platform[:3] != 'win')

	# get short path name on windows
	def pathshort (self, path):
		if path is None:
			return None
		path = os.path.abspath(path)
		if sys.platform[:3] != 'win':
			return path
		kernel32 = None
		textdata = None
		GetShortPathName = None
		try:
			import ctypes
			kernel32 = ctypes.windll.LoadLibrary("kernel32.dll")
			textdata = ctypes.create_string_buffer(b'\000' * 1034)
			GetShortPathName = kernel32.GetShortPathNameA
			args = [ ctypes.c_char_p, ctypes.c_char_p, ctypes.c_int ]
			GetShortPathName.argtypes = args
			GetShortPathName.restype = ctypes.c_uint32
		except: 
			pass
		if not GetShortPathName:
			return path
		if not isinstance(path, bytes):
			path = path.encode(sys.stdout.encoding, 'ignore')
		retval = GetShortPathName(path, textdata, 1034)
		shortpath = textdata.value
		if retval <= 0:
			return ''
		if isinstance(path, bytes):
			if sys.stdout.encoding:
				shortpath = shortpath.decode(sys.stdout.encoding, 'ignore')
		return shortpath

	def mkdir (self, path):
		unix = sys.platform[:3] != 'win' and True or False
		path = os.path.abspath(path)
		if os.path.exists(path):
			return False
		name = ''
		part = os.path.abspath(path).replace('\\', '/').split('/')
		if unix:
			name = '/'
		if (not unix) and (path[1:2] == ':'):
			part[0] += '/'
		for n in part:
			name = os.path.abspath(os.path.join(name, n))
			if not os.path.exists(name):
				os.mkdir(name)
		return True

	# remove tree
	def rmtree (self, path, ignore_error = False, onerror = None):
		import shutil
		shutil.rmtree(path, ignore_error, onerror)
		return True

	# absolute path
	def abspath (self, path, resolve = False):
		if path is None:
			return None
		if '~' in path:
			path = os.path.expanduser(path)
		path = os.path.abspath(path)
		if not UNIX:
			return path.lower().replace('\\', '/')
		if resolve:
			return os.path.abspath(os.path.realpath(path))
		return path

	# find files
	def find (self, path, extnames = None):
		result = []
		if extnames:
			if UNIX == 0:
				extnames = [ n.lower() for n in extnames ]
			extnames = tuple(extnames)
		for root, _, files in os.walk(path):
			for name in files:
				if extnames:
					ext = os.path.splitext(name)[-1]
					if UNIX == 0:
						ext = ext.lower()
					if ext not in extnames:
						continue
				result.append(os.path.abspath(os.path.join(root, name)))
		return result

	# which file
	def which (self, name, prefix = None, postfix = None):
		if not prefix:
			prefix = []
		if not postfix:
			postfix = []
		PATH = os.environ.get('PATH', '').split(UNIX and ':' or ';')
		search = prefix + PATH + postfix
		for path in search:
			fullname = os.path.join(path, name)
			if os.path.exists(fullname):
				return fullname
		return None

	# search executable
	def search_exe (self, exename):
		path = self.which(exename)
		if path is None:
			return None
		return self.pathshort(path)

	# load content
	def load_file_content (self, filename, mode = 'r'):
		try:
			fp = open(filename, mode)
			content = fp.read()
			fp.close()
		except:
			content = None
		return content

	# save file content
	def save_file_content (self, filename, content, mode = 'w'):
		try:
			fp = open(filename, mode)
			fp.write(content)
			fp.close()
		except:
			return False
		return True

	# find file recursive
	def find_files (self, cwd, pattern = '*.*'):
		import fnmatch
		matches = []
		for root, dirnames, filenames in os.walk(cwd):
			for filename in fnmatch.filter(filenames, pattern):
				matches.append(os.path.join(root, filename))
		return matches

	# load file and guess encoding
	def load_file_text (self, filename, encoding = None):
		content = self.load_file_content(filename, 'rb')
		if content is None:
			return None
		if content[:3] == b'\xef\xbb\xbf':
			text = content[3:].decode('utf-8')
		elif encoding is not None:
			text = content.decode(encoding, 'ignore')
		else:
			text = None
			guess = [sys.getdefaultencoding(), 'utf-8']
			if sys.stdout and sys.stdout.encoding:
				guess.append(sys.stdout.encoding)
			for name in guess + ['gbk', 'ascii', 'latin1']:
				try:
					text = content.decode(name)
					break
				except:
					pass
			if text is None:
				text = content.decode('utf-8', 'ignore')
		return text


#----------------------------------------------------------------------
# instance
#----------------------------------------------------------------------
posix = PosixKit()


#----------------------------------------------------------------------
# file content load/save
#----------------------------------------------------------------------


def load_config(path):
	import json
	try:
		text = posix.load_file_content(path, 'rb')
		if text is None:
			return None
		if sys.version_info[0] < 3:
			if text[:3] == '\xef\xbb\xbf':  	# remove BOM+
				text = text[3:]
			return json.loads(text, encoding = "utf-8")
		else:
			if text[:3] == b'\xef\xbb\xbf':		# remove BOM+
				text = text[3:]
			text = text.decode('utf-8', 'ignore')
			return json.loads(text)
	except:
		return None
	return None

def save_config(path, obj):
	import json
	if sys.version_info[0] < 3:
		text = json.dumps(obj, indent = 4, encoding = "utf-8") + '\n'
	else:
		text = json.dumps(obj, indent = 4) + '\n'
		text = text.encode('utf-8', 'ignore')
	if not posix.save_file_content(path, text, 'wb'):
		return False
	return True


#----------------------------------------------------------------------
# http_request
#----------------------------------------------------------------------
def http_request(url, timeout = 10, data = None, post = False, head = None):
	headers = []
	import urllib
	import ssl
	if sys.version_info[0] >= 3:
		import urllib.parse
		import urllib.request
		import urllib.error
		if data is not None:
			if isinstance(data, dict):
				data = urllib.parse.urlencode(data)
		if not post:
			if data is None:
				req = urllib.request.Request(url)
			else:
				mark = '?' in url and '&' or '?'
				req = urllib.request.Request(url + mark + data)
		else:
			data = data is not None and data or ''
			if not isinstance(data, bytes):
				data = data.encode('utf-8', 'ignore')
			req = urllib.request.Request(url, data)
		if head:
			for k, v in head:
				req.add_header(k, v)
		try:
			res = urllib.request.urlopen(req, timeout = timeout)
			headers = res.getheaders()
		except urllib.error.HTTPError as e:
			return e.code, str(e.message), None
		except urllib.error.URLError as e:
			return -1, str(e), None
		except socket.timeout:
			return -2, 'timeout', None
		except ssl.SSLError:
			return -2, 'timeout', None
		content = res.read()
	else:
		import urllib2
		if data is not None:
			if isinstance(data, dict):
				part = {}
				for key in data:
					val = data[key]
					if isinstance(key, unicode):
						key = key.encode('utf-8')
					if isinstance(val, unicode):
						val = val.encode('utf-8')
					part[key] = val
				data = urllib.urlencode(part)
			if not isinstance(data, bytes):
				data = data.encode('utf-8', 'ignore')
		if not post:
			if data is None:
				req = urllib2.Request(url)
			else:
				mark = '?' in url and '&' or '?'
				req = urllib2.Request(url + mark + data)
		else:
			req = urllib2.Request(url, data is not None and data or '')
		if head:
			for k, v in head:
				req.add_header(k, v)
		try:
			res = urllib2.urlopen(req, timeout = timeout)
			content = res.read()
			if res.info().headers:
				for line in res.info().headers:
					line = line.rstrip('\r\n\t')
					pos = line.find(':')
					if pos < 0:
						continue
					key = line[:pos].rstrip('\t ')
					val = line[pos + 1:].lstrip('\t ')
					headers.append((key, val))
		except urllib2.HTTPError as e:
			return e.code, str(e.message), None
		except urllib2.URLError as e:
			return -1, str(e), None
		except socket.timeout:
			return -2, 'timeout', None
		except ssl.SSLError:
			return -2, 'timeout', None
	return 200, content, headers


#----------------------------------------------------------------------
# request with retry
#----------------------------------------------------------------------
def request_safe(url, timeout = 10, retry = 3, verbose = True, delay = 1):
	for i in xrange(retry):
		if verbose:
			print('%s: %s'%(i == 0 and 'request' or 'retry', url))
		time.sleep(delay)
		code, content, _ = http_request(url, timeout)
		if code == 200:
			return content
	return None


#----------------------------------------------------------------------
# request json rpc
#----------------------------------------------------------------------
def json_rpc_post(url, message, timeout = 10):
	import json
	data = json.dumps(message)
	header = [('Content-Type', 'text/plain; charset=utf-8')]
	code, content, _ = http_request(url, timeout, data, True, header)
	if code == 200:
		content = json.loads(content)
	return code, content


#----------------------------------------------------------------------
# timestamp
#----------------------------------------------------------------------
def timestamp(ts = None, onlyday = False):
	import time
	if not ts: ts = time.time()
	if onlyday:
		time.strftime('%Y%m%d', time.localtime(ts))
	return time.strftime('%Y%m%d%H%M%S', time.localtime(ts))


#----------------------------------------------------------------------
# timestamp
#----------------------------------------------------------------------
def readts(ts, onlyday = False):
	if onlyday: ts += '000000'
	try: return time.mktime(time.strptime(ts, '%Y%m%d%H%M%S'))
	except: pass
	return 0


#----------------------------------------------------------------------
# ConfigReader
#----------------------------------------------------------------------
class ConfigReader (object):

	def __init__ (self, ininame, codec = None):
		self.ininame = ininame
		self.config = {}
		self.sections = []
		try:
			content = open(ininame, 'rb').read()
		except IOError:
			content = b''
		if content[:3] == b'\xef\xbb\xbf':
			text = content[3:].decode('utf-8')
		elif codec is not None:
			text = content.decode(codec, 'ignore')
		else:
			codec = sys.getdefaultencoding()
			text = None
			for name in [codec, 'gbk', 'utf-8']:
				try:
					text = content.decode(name)
					break
				except:
					pass
			if text is None:
				text = content.decode('utf-8', 'ignore')
		if sys.version_info[0] < 3:
			import StringIO
			import ConfigParser
			sio = StringIO.StringIO(text)
			cp = ConfigParser.ConfigParser()
			cp.readfp(sio)
		else:
			import configparser
			cp = configparser.ConfigParser()
			cp.read_string(text)
		config = {}
		for sect in cp.sections():
			for key, val in cp.items(sect):
				lowsect, lowkey = sect.lower(), key.lower()
				config.setdefault(lowsect, {})[lowkey] = val
		if 'default' not in config:
			config['default'] = {}
		self.config = config

	def option (self, section, item, default = None):
		sect = self.config.get(section, None)
		if not sect:
			return default
		text = sect.get(item, None)
		if text is None:
			return default
		if isinstance(default, int) or isinstance(default, long):
			multiply = 1
			text = text.strip('\r\n\t ')
			postfix1 = text[-1:].lower()
			postfix2 = text[-2:].lower()
			if postfix1 == 'k':
				multiply = 1024
				text = text[:-1]
			elif postfix1 == 'm': 
				multiply = 1024 * 1024
				text = text[:-1]
			elif postfix2 == 'kb':
				multiply = 1024
				text = text[:-2]
			elif postfix2 == 'mb':
				multiply = 1024 * 1024
				text = text[:-2]
			try: text = int(text.strip('\r\n\t '), 0)
			except: text = default
			if multiply > 1: 
				text *= multiply
		return text


#----------------------------------------------------------------------
# Csv Read/Write
#----------------------------------------------------------------------

def csv_load (filename, encoding = None):
	content = None
	text = None
	try:
		content = open(filename, 'rb').read()
	except:
		return None
	if content is None:
		return None
	if content[:3] == b'\xef\xbb\xbf':
		text = content[3:].decode('utf-8')
	elif encoding is not None:
		text = content.decode(encoding, 'ignore')
	else:
		codec = sys.getdefaultencoding()
		text = None
		for name in [codec, 'utf-8', 'gbk', 'ascii', 'latin1']:
			try:
				text = content.decode(name)
				break
			except:
				pass
		if text is None:
			text = content.decode('utf-8', 'ignore')
	if not text:
		return None
	import csv
	if sys.version_info[0] < 3:
		import cStringIO
		sio = cStringIO.StringIO(text.encode('utf-8', 'ignore'))
	else:
		import io
		sio = io.StringIO(text)
	reader = csv.reader(sio)
	output = []
	if sys.version_info[0] < 3:
		for row in reader:
			output.append([ n.decode('utf-8', 'ignore') for n in row ])
	else:
		for row in reader:
			output.append(row)
	return output


def csv_save (filename, rows, encoding = 'utf-8'):
	import csv
	ispy2 = (sys.version_info[0] < 3)
	if not encoding:
		encoding = 'utf-8'
	if sys.version_info[0] < 3:
		fp = open(filename, 'wb')
		writer = csv.writer(fp)
	else:
		fp = open(filename, 'w', encoding = encoding)
		writer = csv.writer(fp)
	for row in rows:
		newrow = []
		for n in row:
			if isinstance(n, int) or isinstance(n, long):
				n = str(n)
			elif isinstance(n, float):
				n = str(n)
			elif not isinstance(n, bytes):
				if (n is not None) and ispy2:
					n = n.encode(encoding, 'ignore')
			newrow.append(n)
		writer.writerow(newrow)
	fp.close()
	return True


#----------------------------------------------------------------------
# object pool
#----------------------------------------------------------------------
class ObjectPool (object):

	def __init__ (self):
		import threading
		self._pools = {}
		self._lock = threading.Lock()

	def get (self, name):
		hr = None
		self._lock.acquire()
		pset = self._pools.get(name, None)
		if pset:
			hr = pset.pop()
		self._lock.release()
		return hr
	
	def put (self, name, obj):
		self._lock.acquire()
		pset = self._pools.get(name, None)
		if pset is None:
			pset = set()
			self._pools[name] = pset
		pset.add(obj)
		self._lock.release()
		return True


#----------------------------------------------------------------------
# WebKit
#----------------------------------------------------------------------
class WebKit (object):
	
	def __init__ (self):
		pass

	# Check IS FastCGI 
	def IsFastCGI (self):
		import socket, errno
		if 'fromfd' not in socket.__dict__:
			return False
		try:
			s = socket.fromfd(sys.stdin.fileno(), socket.AF_INET, 
					socket.SOCK_STREAM)
			s.getpeername()
		except socket.error as err:
			if err.errno != errno.ENOTCONN: 
				return False
		return True

	def text2html (self, s):
		import cgi
		return cgi.escape(s, True).replace('\n', "</br>\n")


	def html2text (self, html):
		part = []
		pos = 0
		while 1:
			f1 = html.find('<', pos)
			if f1 < 0:
				part.append((0, html[pos:]))
				break
			f2 = html.find('>', f1)
			if f2 < 0:
				part.append((0, html[pos:]))
				break
			text = html[pos:f1]
			flag = html[f1:f2 + 1]
			pos = f2 + 1
			if text:
				part.append((0, text))
			if flag:
				part.append((1, flag))
		output = ''
		for mode, text in part:
			if mode == 0:
				text = text.lstrip()
				text = text.replace('&nbsp;', ' ').replace('&gt;', '>')
				text = text.replace('&lt;', '<').replace('&amp;', '&')
				output += text
			else:
				text = text.strip()
				tiny = text.replace(' ', '')
				if tiny in ('</p>', '<p/>', '<br>', '</br>', '<br/>'):
					output += '\n'
				elif tiny in ('</tr>', '<tr/>', '</h1>', '</h2>', '</h3>'):
					output += '\n'
				elif tiny in ('</td>', '<td/>'):
					output += ' '
				elif tiny in ('</div>',):
					output += '\n'
		return output

	def match_text (self, text, position, starts, ends):
		p1 = text.find(starts, position)
		if p1 < 0:
			return None, position
		p2 = text.find(ends, p1 + len(starts))
		if p2 < 0:
			return None, position
		value = text[p1 + len(starts):p2]
		return value, p2 + len(ends)



#----------------------------------------------------------------------
# instance
#----------------------------------------------------------------------
web = WebKit()


#----------------------------------------------------------------------
# LazyRequests
#----------------------------------------------------------------------
class LazyRequests (object):
	
	def __init__ (self):
		import threading
		self._pools = {}
		self._lock = threading.Lock()
		self._options = {}
		self._option = {}
	
	def __session_get (self, name):
		hr = None
		with self._lock:
			pset = self._pools.get(name, None)
			if pset:
				hr = pset.pop()
		return hr
	
	def __session_put (self, name, obj):
		with self._lock:
			pset = self._pools.get(name, None)
			if pset is None:
				pset = set()
				self._pools[name] = pset
			pset.add(obj)
		return True

	def request (self, name, url, data = None, post = False, header = None):
		import requests
		s = self.__session_get(name)
		if not s:
			s = requests.Session()
		r = None
		option = self._options.get(name, {})
		argv = {}
		if header is not None:
			argv['headers'] = header
		timeout = self._option.get('timeout', None)
		proxy = self._option.get('proxy', None)
		if 'timeout' in option:
			timeout = option.get('timeout')
		if 'proxy' in option:
			proxy = option['proxy']
		if timeout:
			argv['timeout'] = timeout
		if proxy:
			argv['proxies'] = proxy
		if not post:
			if data is not None:
				argv['params'] = data
		else:
			if data is not None:
				argv['data'] = data
		try:
			if not post:
				r = s.get(url, **argv)
			else:
				r = s.post(url, **argv)
		except requests.exceptions.ConnectionError:
			r = None
		except requests.exceptions.RetryError as e:
			r = requests.Response()
			r.status_code = -1
			r.text = 'RetryError'
			r.error = e
		except requests.exceptions.BaseHTTPError as e:
			r = requests.Response()
			r.status_code = -2
			r.text = 'BaseHTTPError'
			r.error = e
		except requests.exceptions.HTTPError as e:
			r = requests.Response()
			r.status_code = -3
			r.text = 'HTTPError'
			r.error = e
		except requests.exceptions.RequestException as e:
			r = requests.Response()
			r.status_code = -4
			r.error = e
		self.__session_put(name, s)
		return r

	def option (self, name, opt, value):
		if name is None:
			self._option[opt] = value
		else:
			if name not in self._options:
				self._options[name] = {}
			opts = self._options[name]
			opts[opt] = value
		return True

	def get (self, name, url, data = None, header = None):
		return self.request(name, url, data, False, header)

	def post (self, name, url, data = None, header = None):
		return self.request(name, url, data, True, header)

	def wget (self, name, url, data = None, post = False, header = None):
		r = self.request(name, url, data, post, header)
		if r is None:
			return -1, None
		if r.content:
			text = r.content.decode('utf-8')
		else:
			text = r.text
		return r.status_code, text


#----------------------------------------------------------------------
# ShellUtilita
#----------------------------------------------------------------------
class ShellUtilita (object):

	# compress into a zip file, srcnames must be a list of tuples:
	# [ (filename_1, arcname_1), (filename_2, arcname_2), ... ]
	def zip_compress (self, zipname, srcnames, mode = 'w'):
		import zipfile
		if isinstance(srcnames, dict):
			names = [ (v and v or k, k) for k, v in srcnames.items() ]
		else:
			names = []
			for item in srcnames:
				if isinstance(item, tuple) or isinstance(item, list):
					srcname, arcname = item[0], item[1]
				else:
					srcname, arcname = item, None
				names.append((arcname and arcname or srcname, srcname))
		names.sort()
		zfp = zipfile.ZipFile(zipname, mode, zipfile.ZIP_DEFLATED)
		for arcname, srcname in names:
			zfp.write(srcname, arcname)
		zfp.close()
		zfp = None
		return 0


utils = ShellUtilita()


#----------------------------------------------------------------------
# TraceOut 
#----------------------------------------------------------------------
class TraceOut (object):

	def __init__ (self, prefix = ''):
		self._prefix = prefix
		import threading
		self._lock = threading.Lock()
		self._logtime = None
		self._logfile = None
		self._channels = {'info':True, 'debug':True, 'error':True}
		self._channels['warn'] = True
		self._encoding = 'utf-8'
		self._stdout = True
		self._stderr = False
		self._makedir = False

	def _writelog (self, *args):
		now = time.strftime('%Y-%m-%d %H:%M:%S')
		date = now.split(None, 1)[0].replace('-', '')
		self._lock.acquire()
		if date != self._logtime:
			self._logtime = date
			if self._logfile is not None:
				try:
					self._logfile.close()
				except:
					pass
				self._logfile = None
		if self._logfile is None:
			import codecs
			logname = '%s%s.log'%(self._prefix, date)
			dirname = os.path.dirname(logname)
			if self._makedir:
				if not os.path.exists(dirname):
					try: os.makedirs(dirname)
					except: pass
			self._logfile = codecs.open(logname, 'a', self._encoding)
		part = []
		for text in args:
			if isinstance(text, unicode) or isinstance(text, str):
				if not isinstance(text, unicode):
					text = text.decode(self._encoding)
			else:
				text = unicode(text)
			part.append(text)
		text = u' '.join(part)
		self._logfile.write('[%s] %s\r\n'%(now, text))
		self._logfile.flush()
		self._lock.release()
		if self._stdout:
			sys.stdout.write('[%s] %s\n'%(now, text))
			sys.stdout.flush()
		if self._stderr:
			sys.stderr.write('[%s] %s\n'%(now, text))
			sys.stderr.flush()
		return True

	def out (self, channel, *args):
		if not self._channels.get(channel, False):
			return False
		self._writelog('[%s]'%channel, *args)
		return True

	def info (self, *args):
		self.out('info', *args)

	def warn (self, *args):
		self.out('warn', *args)

	def error (self, *args):
		self.out('error', *args)

	def debug (self, *args):
		self.out('debug', *args)


#----------------------------------------------------------------------
# run until mainfunc returns false 
#----------------------------------------------------------------------
def safe_loop (mainfunc, trace = None, sleep = 2.0):
	while True:
		try:
			hr = mainfunc()
			if not hr:
				break
		except KeyboardInterrupt:
			tb = callstack().split('\n')
			if trace:
				for line in tb:
					trace.error(line)
			else:
				for line in tb:
					sys.stderr.write(line + '\n')
			break
		except:
			tb = callstack().split('\n')
			if trace:
				for line in tb:
					trace.error(line)
				trace.error('ready to restart')
				trace.error('')
			else:
				for line in tb:
					sys.stderr.write(line + '\n')
				sys.stderr.write('\nready to restart\n')
			time.sleep(sleep)
	return True


#----------------------------------------------------------------------
# testing case
#----------------------------------------------------------------------
if __name__ == '__main__':
	def test1():
		code, data, headers = http_request('http://www.baidu.com')
		for k, v in headers:
			print('%s: %s'%(k, v))
		print(web.IsFastCGI())
		return 0
	def test2():
		config = ConfigReader('e:/lab/casuald/conf/echoserver.ini')
		print(config.option('transmod', 'portu'))
		return 0
	def test3():
		trace = TraceOut('m')
		trace.info('haha', 'mama')
		return 0
	def test4():
		log = TraceOut('m')
		def loop():
			time.sleep(2)
			log.info('loop')
			return False
		safe_loop(loop, log)
		return 0
	test1()



