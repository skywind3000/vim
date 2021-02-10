#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim: set ts=4 sw=4 tw=0 et :
#======================================================================
#
# ascmini.py - mini library
#
# Created by skywind on 2017/03/24
# Version: 8, Last Modified: 2020/11/01 15:06
#
#======================================================================
from __future__ import print_function
import sys
import time
import os
import socket
import collections
import json


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
        return b''
    elif (not shell) and (not capture):
        import subprocess
        if 'call' in subprocess.__dict__:
            subprocess.call(args)
            return b''
    import subprocess
    if 'Popen' in subprocess.__dict__:
        p = subprocess.Popen(args, shell = shell,
                stdin = subprocess.PIPE, stdout = subprocess.PIPE, 
                stderr = subprocess.STDOUT)
        stdin, stdouterr = (p.stdin, p.stdout)
    else:
        p = None
        stdin, stdouterr = os.popen4(cmd)
    stdin.close()
    text = stdouterr.read()
    stdouterr.close()
    if p: p.wait()
    if not capture:
        sys.stdout.write(text)
        sys.stdout.flush()
        return b''
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
    bufsize = 0x100000
    if input_data is not None:
        if not isinstance(input_data, bytes):
            if sys.stdin and sys.stdin.encoding:
                input_data = input_data.encode(sys.stdin.encoding, 'ignore')
            elif sys.stdout and sys.stdout.encoding:
                input_data = input_data.encode(sys.stdout.encoding, 'ignore')
            else:
                input_data = input_data.encode('utf-8', 'ignore')
        size = len(input_data) * 2 + 0x10000
        if size > bufsize:
            bufsize = size
    if 'Popen' in subprocess.__dict__:
        p = subprocess.Popen(args, shell = False, bufsize = bufsize,
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
        stdin.write(input_data)
        stdin.flush()
    stdin.close()
    exeout = stdout.read()
    if stderr: exeerr = stderr.read()
    else: exeerr = None
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
        if text in (b'', ''):
            break
        reader('stdout', text)
    while stderr is not None:
        text = stderr.readline()
        if text in (b'', ''):
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
        line = [ '%s=%s'%(k, repr(v)) for k, v in self.__dict__.items() ]
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
    def search_exe (self, exename, prefix = None, postfix = None):
        path = self.which(exename, prefix, postfix)
        if path is None:
            return None
        return self.pathshort(path)

    # executable 
    def search_cmd (self, cmdname, prefix = None, postfix = None):
        if sys.platform[:3] == 'win':
            ext = os.path.splitext(cmdname)[-1].lower()
            if ext:
                return self.search_exe(cmdname, prefix, postfix)
            for ext in ('.cmd', '.bat', '.exe', '.vbs'):
                path = self.which(cmdname + ext, prefix, postfix)
                if path:
                    return self.pathshort(path)
        return self.search_exe(cmdname)

    # load content
    def load_file_content (self, filename, mode = 'r'):
        if hasattr(filename, 'read'):
            try: content = filename.read()
            except: pass
            return content
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
            try:
                import locale
                guess.append(locale.getpreferredencoding())
            except:
                pass
            visit = {}
            for name in guess + ['gbk', 'ascii', 'latin1']:
                if name in visit:
                    continue
                visit[name] = 1
                try:
                    text = content.decode(name)
                    break
                except:
                    pass
            if text is None:
                text = content.decode('utf-8', 'ignore')
        return text

    # save file text
    def save_file_text (self, filename, content, encoding = None):
        import codecs
        if encoding is None:
            encoding = 'utf-8'
        if (not isinstance(content, unicode)) and isinstance(content, bytes):
            return self.save_file_content(filename, content)
        with codecs.open(filename, 'w', 
                encoding = encoding, 
                errors = 'ignore') as fp:
            fp.write(content)
        return True

    # load ini without ConfigParser
    def load_ini (self, filename, encoding = None):
        text = self.load_file_text(filename, encoding)
        config = {}
        sect = 'default'
        if text is None:
            return None
        for line in text.split('\n'):
            line = line.strip('\r\n\t ')
            if not line:
                continue
            elif line[:1] in ('#', ';'):
                continue
            elif line.startswith('['):
                if line.endswith(']'):
                    sect = line[1:-1].strip('\r\n\t ')
                    if sect not in config:
                        config[sect] = {}
            else:
                pos = line.find('=')
                if pos >= 0:
                    key = line[:pos].rstrip('\r\n\t ')
                    val = line[pos + 1:].lstrip('\r\n\t ')
                    if sect not in config:
                        config[sect] = {}
                    config[sect][key] = val
        return config


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
            if text[:3] == '\xef\xbb\xbf':      # remove BOM+
                text = text[3:]
            return json.loads(text, encoding = "utf-8")
        else:
            if text[:3] == b'\xef\xbb\xbf':     # remove BOM+
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
    status = -1
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
            for k, v in head.items():
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
        status = res.getcode()
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
            for k, v in head.items():
                req.add_header(k, v)
        try:
            res = urllib2.urlopen(req, timeout = timeout)
            content = res.read()
            status = res.getcode()
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
    return status, content, headers


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
# parse text
#----------------------------------------------------------------------
def parse_conf_text(text, default = None):
    if text is None:
        return default
    if isinstance(default, str):
        return text
    elif isinstance(default, bool):
        text = text.lower()
        if not text:
            return default
        text = text.lower()
        if default:
            if text in ('false', 'f', 'no', 'n', '0'):
                return False
        else:
            if text in ('true', 'ok', 'yes', 't', 'y', '1'):
                return True
            if text.isdigit():
                try:
                    value = int(text)
                    if value:
                        return True
                except:
                    pass
        return default
    elif isinstance(default, float):
        try:
            value = float(text)
            return value
        except:
            return default
    elif isinstance(default, int) or isinstance(default, long):
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
    return text



#----------------------------------------------------------------------
# ConfigReader
#----------------------------------------------------------------------
class ConfigReader (object):

    def __init__ (self, ininame, codec = None):
        self.ininame = ininame
        self.reset()
        self.load(ininame, codec)

    def reset (self):
        self.config = {}
        self.sections = []
        return True

    def load (self, ininame, codec = None):
        if not ininame:
            return False
        elif not os.path.exists(ininame):
            return False
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
            cp = configparser.ConfigParser(interpolation = None)
            cp.read_string(text)
        for sect in cp.sections():
            for key, val in cp.items(sect):
                lowsect, lowkey = sect.lower(), key.lower()
                self.config.setdefault(lowsect, {})[lowkey] = val
        if 'default' not in self.config:
            self.config['default'] = {}
        return True

    def option (self, section, item, default = None):
        sect = self.config.get(section, None)
        if not sect:
            return default
        text = sect.get(item, None)
        if text is None:
            return default
        return parse_conf_text(text, default)


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
        fp = open(filename, 'w', encoding = encoding, newline = '')
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

    def replace_range (self, text, start, size, newtext):
        head = text[:start]
        tail = text[start + size:]
        return head + newtext + tail

    def url_parse (self, url):
        if sys.version_info[0] < 3:
            import urlparse
            return urlparse.urlparse(url)
        import urllib.parse
        return urllib.parse.urlparse(url)

    def url_unquote (self, text, plus = True):
        if sys.version_info[0] < 3:
            import urllib
            if plus:
                return urllib.unquote_plus(text)
            return urllib.unquote(text)
        import urllib.parse
        if plus:
            return urllib.parse.unquote_plus(text)
        return urllib.parse.unquote(text)

    def url_quote (self, text, plus = True):
        if sys.version_info[0] < 3:
            import urllib
            if plus:
                return urllib.quote_plus(text)
            return urlparse.quote(text)
        import urllib.parse
        if plus:
            return urllib.parse.quote_plus(text)
        return urllib.parse.quote(text)
        
    def url_parse_qs (self, text, keep_blank = 0):
        if sys.version_info[0] < 3:
            import urlparse
            return urlparse.parse_qs(text, keep_blank)
        import urllib.parse
        return urllib.parse.parse_qs(text, keep_blank)

    def url_parse_qsl (self, text, keep_blank = 0):
        if sys.version_info[0] < 3:
            import urlparse
            return urlparse.parse_qsl(text, keep_blank)
        import urllib.parse
        return urllib.parse.parse_qsl(text, keep_blank)



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
        import copy
        s = self.__session_get(name)
        if not s:
            s = requests.Session()
        r = None
        option = self._options.get(name, {})
        argv = {}
        timeout = self._option.get('timeout', None)
        proxy = self._option.get('proxy', None)
        agent = self._option.get('agent', None)
        if 'timeout' in option:
            timeout = option.get('timeout')
        if 'proxy' in option:
            proxy = option['proxy']
        if proxy and isinstance(proxy, str):
            if proxy.startswith('socks5://'):
                proxy = 'socks5h://' + proxy[9:]
                proxy = {'http': proxy, 'https': proxy}
        if 'agent' in option:
            agent = option['agent']
        if timeout:
            argv['timeout'] = timeout
        if proxy:
            argv['proxies'] = proxy
        if header is None:
            header = {}
        else:
            header = copy.deepcopy(header)
        if agent:
            header['User-Agent'] = agent
        if header is not None:
            argv['headers'] = header
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
# instance
#----------------------------------------------------------------------
lazy = LazyRequests()


#----------------------------------------------------------------------
# ShellUtils
#----------------------------------------------------------------------
class ShellUtils (object):

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

    # find root
    def find_root (self, path, markers = None, fallback = False):
        if markers is None:
            markers = ('.git', '.svn', '.hg', '.project', '.root')
        if path is None:
            path = os.getcwd()
        path = os.path.abspath(path)
        base = path
        while True:
            parent = os.path.normpath(os.path.join(base, '..'))
            for marker in markers:
                test = os.path.join(base, marker)
                if os.path.exists(test):
                    return base
            if os.path.normcase(parent) == os.path.normcase(base):
                break
            base = parent
        if fallback:
            return path
        return None

    # project root
    def project_root (self, path, markers = None):
        return self.find_root(path, markers, True)

    # getopt: returns (options, args)
    def getopt (self, argv):
        args = []
        options = {}
        if argv is None:
            argv = sys.argv[1:]
        index = 0
        count = len(argv)
        while index < count:
            arg = argv[index]
            if arg != '':
                head = arg[:1]
                if head != '-':
                    break
                if arg == '-':
                    break
                name = arg.lstrip('-')
                key, _, val = name.partition('=')
                options[key.strip()] = val.strip()
            index += 1
        while index < count:
            args.append(argv[index])
            index += 1
        return options, args

    # hexdump
    def hexdump (self, data, char = False):
        content = ''
        charset = ''
        lines = []
        if isinstance(data, str):
            if sys.version_info[0] >= 3:
                data = data.encode('utf-8', 'ignore')
        if not isinstance(data, bytes):
            raise ValueError('data must be bytes')
        for i, _ in enumerate(data):
            if sys.version_info[0] < 3:
                ascii = ord(data[i])
            else:
                ascii = data[i]
            if i % 16 == 0: content += '%08X  '%i
            content += '%02X'%ascii
            content += ((i & 15) == 7) and '-' or ' '
            if (ascii >= 0x20) and (ascii < 0x7f): charset += chr(ascii)
            else: charset += '.'
            if (i % 16 == 15): 
                lines.append(content + ' ' + charset)
                content, charset = '', ''
        if len(content) < 60: content += ' ' * (58 - len(content))
        lines.append(content + ' ' + charset)
        limit = char and 104 or 58
        return '\n'.join([ n[:limit] for n in lines ])

    def print_binary (self, data, char = False):
        print(self.hexdump(data, char))
        return True
    

utils = ShellUtils()


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
        self._stdout = sys.__stdout__
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
            self._stdout.write('[%s] %s\n'%(now, text))
            self._stdout.flush()
        if self._stderr:
            self._stderr.write('[%s] %s\n'%(now, text))
            self._stderr.flush()
        return True

    def change (self, prefix):
        self._lock.acquire()
        self._logtime = None
        self._prefix = prefix
        if self._logfile:
            try:
                self._logfile.close()
            except:
                pass
        self._logfile = None
        self._lock.release()
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
# OutputHandler
#----------------------------------------------------------------------
class OutputHandler (object):
    def __init__(self, writer):
        import threading
        self.writer = writer
        self.content = ''
        self.lock = threading.Lock()
        self.encoding = sys.__stdout__.encoding
    def flush(self):
        return True
    def write(self, s):
        self.lock.acquire()
        self.content += s
        while True:
            pos = self.content.find('\n')
            if pos < 0: break
            self.writer(self.content[:pos])
            self.content = self.content[pos + 1:]
        self.lock.release()
        return True
    def writelines(self, l):
        map(self.write, l)


#----------------------------------------------------------------------
# run until mainfunc returns false 
#----------------------------------------------------------------------
def safe_loop (mainfunc, trace = None, sleep = 2.0, dtor = None):
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
            else:
                for line in tb:
                    sys.stderr.write(line + '\n')
            if dtor:
                if trace:
                    trace.error('clean up')
                else:
                    sys.stderr.write('clean up\n')
                try:
                    dtor()
                except:
                    pass
            if trace:
                trace.error('')
                trace.error('restarting in %s seconds'%sleep)
                trace.error('')
            else:
                sys.stderr.write('\nready to restart\n')
            time.sleep(sleep)
    return True


#----------------------------------------------------------------------
# tabulify: style = 0, 1, 2
#----------------------------------------------------------------------
def tabulify (rows, style = 0):
    colsize = {}
    maxcol = 0
    output = []
    if not rows:
        return ''
    for row in rows:
        maxcol = max(len(row), maxcol)
        for col, text in enumerate(row):
            text = str(text)
            size = len(text)
            if col not in colsize:
                colsize[col] = size
            else:
                colsize[col] = max(size, colsize[col])
    if maxcol <= 0:
        return ''
    def gettext(row, col):
        csize = colsize[col]
        if row >= len(rows):
            return ' ' * (csize + 2)
        row = rows[row]
        if col >= len(row):
            return ' ' * (csize + 2)
        text = str(row[col])
        padding = 2 + csize - len(text)
        pad1 = 1
        pad2 = padding - pad1
        return (' ' * pad1) + text + (' ' * pad2)
    if style == 0:
        for y, row in enumerate(rows):
            line = ''.join([ gettext(y, x) for x in xrange(maxcol) ])
            output.append(line)
    elif style == 1:
        if rows:
            newrows = rows[:1]
            head = [ '-' * colsize[i] for i in xrange(maxcol) ]
            newrows.append(head)
            newrows.extend(rows[1:])
            rows = newrows
        for y, row in enumerate(rows):
            line = ''.join([ gettext(y, x) for x in xrange(maxcol) ])
            output.append(line)
    elif style == 2:
        sep = '+'.join([ '-' * (colsize[x] + 2) for x in xrange(maxcol) ])
        sep = '+' + sep + '+'
        for y, row in enumerate(rows):
            output.append(sep)
            line = '|'.join([ gettext(y, x) for x in xrange(maxcol) ])
            output.append('|' + line + '|')
        output.append(sep)
    return '\n'.join(output)


#----------------------------------------------------------------------
# compact dict: k1:v1,k2:v2,...,kn:vn
#----------------------------------------------------------------------
def compact_dumps(data):
    output = []
    for k, v in data.items():
        k = k.strip().replace(',', '').replace(':', '')
        v = v.strip().replace(',', '').replace(':', '')
        output.append(k + ':' + v)
    return ','.join(output)

def compact_loads(text):
    data = {}
    for pp in text.strip().split(','):
        pp = pp.strip()
        if not pp:
            continue
        ps = pp.split(':')
        if len(ps) < 2:
            continue
        k = ps[0].strip()
        v = ps[1].strip()
        if k:
            data[k] = v
    return data


#----------------------------------------------------------------------
# replace file atomicly
#----------------------------------------------------------------------
def replace_file (srcname, dstname):
    import sys, os
    if sys.platform[:3] != 'win':
        try:
            os.rename(srcname, dstname)
        except OSError:
            return False
    else:
        import ctypes.wintypes
        kernel32 = ctypes.windll.kernel32
        wp, vp, cp = ctypes.c_wchar_p, ctypes.c_void_p, ctypes.c_char_p
        DWORD, BOOL = ctypes.wintypes.DWORD, ctypes.wintypes.BOOL
        kernel32.ReplaceFileA.argtypes = [ cp, cp, cp, DWORD, vp, vp ]
        kernel32.ReplaceFileW.argtypes = [ wp, wp, wp, DWORD, vp, vp ]
        kernel32.ReplaceFileA.restype = BOOL
        kernel32.ReplaceFileW.restype = BOOL
        kernel32.GetLastError.argtypes = []
        kernel32.GetLastError.restype = DWORD
        success = False
        try:
            os.rename(srcname, dstname)
            success = True
        except OSError:
            pass
        if success:
            return True
        if sys.version_info[0] < 3 and isinstance(srcname, str):
            hr = kernel32.ReplaceFileA(dstname, srcname, None, 2, None, None)
        else:
            hr = kernel32.ReplaceFileW(dstname, srcname, None, 2, None, None)
        if not hr:
            return False
    return True


#----------------------------------------------------------------------
# random temp 
#----------------------------------------------------------------------
def tmpname (filename, fill = 5):
    import time, os, random
    while 1:
        name = '.' + str(int(time.time() * 1000000))
        for i in range(fill):
            k = random.randint(0, 51)
            name += (k < 26) and chr(ord('A') + k) or chr(ord('a') + k - 26)
        test = filename + name + str(os.getpid())
        if not os.path.exists(test):
            return test
    return None


#----------------------------------------------------------------------
# save json atomic 
#----------------------------------------------------------------------
def save_config_atomic(filename, obj):
    temp = tmpname(filename)
    save_config(temp, obj)
    return replace_file(temp, filename)


#----------------------------------------------------------------------
# Simple Timer
#----------------------------------------------------------------------
class SimpleTimer (object):

    def __init__ (self, period):
        self.__current = None
        self.__timeslap = None
        self.__period = period
    
    def run (self):
        raise NotImplementedError('Method not implemented')

    def update (self, now):
        self.__current = now
        if self.__timeslap is None:
            self.__timeslap = self.__current + self.__period
        elif self.__current >= self.__timeslap:
            self.__timeslap = self.__current + self.__period
            self.run()  
        return True


#----------------------------------------------------------------------
# Registry
#----------------------------------------------------------------------
class Registry (object):

    def __init__ (self, filename = None):
        self.registry = {}
        if filename:
            registry = load_config(filename)
            if registry:
                self.registry = registry
        self.filename = filename

    def save (self, filename = None):
        filename = (filename) and filename or self.filename
        if filename is None:
            raise IOError('Filename must not be None')
        names = list(self.registry.keys())
        names.sort()
        dump = collections.OrderedDict()
        for name in names:
            dump[name] = self.registry[name]
        save_config_atomic(filename, dump)

    def get (self, key, default = None):
        return self.registry.get(key, default)

    def set (self, key, value):
        if (not isinstance(key, str)) and (not isinstance(key, int)):
            raise ValueError('key must be int/string')
        if (not isinstance(value, str)) and (not isinstance(value, int)):
            if (not isinstance(value, float)) and (not isinstance(value, bool)):
                if value is not None:
                    raise ValueError('value must be int/string/float')
        self.registry[key] = value
        return True

    def __contains__ (self, key):
        return (key in self.registry)

    def __len__ (self):
        return len(self.registry)

    def __getitem__ (self, key):
        return self.registry[key]

    def __setitem__ (self, key, value):
        self.set(key, value)

    def __iter__ (self):
        return self.registry.__iter__()

    def keys (self):
        return self.registry.keys()


#----------------------------------------------------------------------
# json decode: safe for python 3.5
#----------------------------------------------------------------------
def json_loads(text):
    if sys.version_info[0] == 3 and sys.version_info[1] < 7:
        if isinstance(text, bytes):
            text = text.decode('utf-8')
    return json.loads(text)


#----------------------------------------------------------------------
# misc functions
#----------------------------------------------------------------------

# calling fzf
def fzf_execute(input, args = None, fzf = None):
    import tempfile
    code = 0
    output = None
    args = args is not None and args or ''
    fzf = fzf is not None and fzf or 'fzf'
    with tempfile.TemporaryDirectory(prefix = 'fzf.') as dirname:
        outname = os.path.join(dirname, 'output.txt')
        if isinstance(input, list):
            inname = os.path.join(dirname, 'input.txt')
            with open(inname, 'wb') as fp:
                content = '\n'.join([ str(n) for n in input ])
                fp.write(content.encode('utf-8'))
            cmd = '%s %s < "%s" > "%s"'%(fzf, args, inname, outname)
        elif isinstance(input, str):
            cmd = '%s | %s %s > "%s"'%(input, fzf, args, outname)
        code = os.system(cmd)
        if os.path.exists(outname):
            with open(outname, 'rb') as fp:
                output = fp.read()
    if output is not None:
        output = output.decode('utf-8')
    if code != 0:
        return None
    return output


#----------------------------------------------------------------------
# testing case
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        code, data, headers = http_request('http://www.baidu.com')
        for k, v in headers:
            print('%s: %s'%(k, v))
        print(web.IsFastCGI())
        print(code)
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
    def test5():
        reg = Registry('output.json')
        import pprint
        pprint.pprint(reg.registry)
        reg.set('home.default', 1234)
        reg.set('target.abc', 'asdfasdf')
        reg.set('home.haha', 'hiahia')
        reg.set('target.pi', 3.1415926)
        # reg.save()
        return 0
    def test6():
        print(utils.find_root(__file__))
        print(utils.project_root('/'))
        utils.print_binary('Hello, World !! Ni Hao !!', True)
        print(utils.getopt(['-t', '--name=123', '--out', '-', 'abc', 'def', 'ghi']))
        print(utils.getopt([]))
        print(web.replace_range('Hello, World', 4, 2, 'fuck'))
        url = 'socks5://test:pass@localhost/tt?123=45'
        res = web.url_parse(url)
        print(res)
        print(res.hostname)
        print(res.port)
        print(res.username)
        print(res.password)
        return 0
    test6()



