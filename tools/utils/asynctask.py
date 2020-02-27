#! /usr/bin/env python3
# -*- coding: utf-8 -*-
#======================================================================
#
# asynctask.py - 
#
# Maintainer: skywind3000 (at) gmail.com, 2020
#
# Last Modified: 2020/02/26 02:42
# Verision: 1.0.3
#
# for more information, please visit:
# https://github.com/skywind3000/asynctasks.vim
#
#======================================================================
from __future__ import print_function, unicode_literals
import sys
import os
import copy
import fnmatch
import pprint


#----------------------------------------------------------------------
# 2/3 compatible
#----------------------------------------------------------------------
if sys.version_info[0] >= 3:
    unicode = str
    long = int


UNIX = (sys.platform[:3] != 'win') and True or False


#----------------------------------------------------------------------
# macros
#----------------------------------------------------------------------
MACROS_HELP = { 
	'VIM_FILEPATH': 'File name of current buffer with full path',
	'VIM_FILENAME': 'File name of current buffer without path',
	'VIM_FILEDIR': 'Full path of current buffer without the file name',
	'VIM_FILEEXT': 'File extension of current buffer',
	'VIM_FILETYPE': 'File type (value of &ft in vim)',
    'VIM_FILENOEXT': # noqa: E261
      'File name of current buffer without path and extension',
	'VIM_PATHNOEXT':
      'Current file name with full path but without extension',
	'VIM_CWD': 'Current directory',
	'VIM_RELDIR': 'File path relativize to current directory',
	'VIM_RELNAME': 'File name relativize to current directory',
	'VIM_ROOT': 'Project root directory',
	'VIM_PRONAME': 'Name of current project root directory',
	'VIM_DIRNAME': "Name of current directory",
	'VIM_CWORD': 'Current word under cursor',
	'VIM_CFILE': 'Current filename under cursor',
	'VIM_CLINE': 'Cursor line number in current buffer',
	'VIM_GUI': 'Is running under gui ?',
	'VIM_VERSION': 'Value of v:version',
	'VIM_COLUMNS': "How many columns in vim's screen",
	'VIM_LINES': "How many lines in vim's screen", 
	'VIM_SVRNAME': 'Value of v:servername for +clientserver usage',
	'WSL_FILEPATH': '(WSL) File name of current buffer with full path',
	'WSL_FILENAME': '(WSL) File name of current buffer without path',
	'WSL_FILEDIR': '(WSL) Full path of current buffer without the file name',
	'WSL_FILEEXT': '(WSL) File extension of current buffer',
    'WSL_FILENOEXT':  # noqa: E261
      '(WSL) File name of current buffer without path and extension', 
	'WSL_PATHNOEXT':
	  '(WSL) Current file name with full path but without extension',
	'WSL_CWD': '(WSL) Current directory',
	'WSL_RELDIR': '(WSL) File path relativize to current directory',
	'WSL_RELNAME': '(WSL) File name relativize to current directory',
	'WSL_ROOT': '(WSL) Project root directory',
	'WSL_CFILE': '(WSL) Current filename under cursor',
}



#----------------------------------------------------------------------
# file type detection (as filetype in vim)
#----------------------------------------------------------------------
FILE_TYPES = {
    'text': '*.txt',
    'c': '*.[cChH],.[cChH].in',
    'cpp': '*.[cChH]pp,*.hh,*.[ch]xx,*.cc,*.cc.in,*.cpp.in,*.hh.in,*.cxx.in',
    'python': '*.py,*.pyw',
    'vim': '*.vim',
    'asm': '*.asm,*.s,*.S',
    'java': '*.java,*.jsp,*.jspx',
    'javascript': '*.js',
    'json': '*.json',
    'perl': '*.pl',
    'go': '*.go',
    'haskell': '*.hs',
    'sh': '*.sh',
    'lua': '*.lua',
    'bash': '*.bash',
    'make': '*.mk,*.mak,[Mm]akefile,[Gg][Nn][Uu]makefile,[Mm]akefile.in',
    'cmake': 'CMakeLists.txt',
    'zsh': '*.zsh',
    'fish': '*.fish',
    'ruby': '*.rb',
    'php': '*.php,*.php4,*.php5',
    'ps1': '*.ps1',
    'cs': '*.cs',
    'erlang': '*.erl,*.hrl',
    'html': '*.html,*.htm',
    'kotlin': '*.kt,*.kts',
    'markdown': '*.md,*.markdown,*.mdown,*.mkdn',
    'rust': '*.rs',
    'scala': '*.scala',
    'swift': '*.swift',
    'dosini': '*.ini',
    'yaml': '*.yaml,*.yml',
}


#----------------------------------------------------------------------
# call program and returns output (combination of stdout and stderr)
#----------------------------------------------------------------------
def execute(args, shell = False, capture = False):
    import sys, os  # noqa: F811
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
# read_ini
#----------------------------------------------------------------------
def load_ini_file (ininame, codec = None):
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
    config = {}
    sect = 'default'
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
# Terminal Output
#----------------------------------------------------------------------
class PrettyText (object):

    def __init__ (self):
        self.isatty = sys.__stdout__.isatty()
        self.names = self.__init_names()
        self.handle = None

    def __init_win32 (self):
        if sys.platform[:3] != 'win':
            return -1
        self.handle = None
        try: import ctypes
        except: return 0
        kernel32 = ctypes.windll.LoadLibrary('kernel32.dll')
        self.kernel32 = kernel32
        GetStdHandle = kernel32.GetStdHandle
        SetConsoleTextAttribute = kernel32.SetConsoleTextAttribute
        GetStdHandle.argtypes = [ ctypes.c_uint32 ]
        GetStdHandle.restype = ctypes.c_size_t
        SetConsoleTextAttribute.argtypes = [ ctypes.c_size_t, ctypes.c_uint16 ]
        SetConsoleTextAttribute.restype = ctypes.c_long
        self.handle = GetStdHandle(0xfffffff5)
        self.GetStdHandle = GetStdHandle
        self.SetConsoleTextAttribute = SetConsoleTextAttribute
        self.GetStdHandle = GetStdHandle
        self.StringBuffer = ctypes.create_string_buffer(22)
        return 0

    # init names
    def __init_names (self):
        ansi_names = ['black', 'red', 'green', 'yellow', 'blue', 'purple']
        ansi_names += ['cyan', 'white']
        names = {}
        for i, name in enumerate(ansi_names):
            names[name] = i
            names[name.upper()] = i + 8
        names['reset'] = -1
        names['RESET'] = -1
        return names

    # set color
    def set_color (self, color, stderr = False):
        if not self.isatty:
            return 0
        if isinstance(color, str):
            color = self.names.get(color, -1)
        elif sys.version_info[0] < 3:
            if isinstance(color, unicode):
                color = self.names.get(color, -1)
        if sys.platform[:3] == 'win':
            if self.handle is None:
                self.__init_win32()
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
            self.SetConsoleTextAttribute(self.handle, result)
        else:
            fp = (not stderr) and sys.stdout or sys.stderr
            if color >= 0:
                foreground = color & 7
                background = (color >> 4) & 7
                bold = color & 8
                t = bold and "01;" or ""
                if background:
                    fp.write("\033[%s3%d;4%dm"%(t, foreground, background))
                else:
                    fp.write("\033[%s3%dm"%(t, foreground))
            else:
                fp.write("\033[0m")
            fp.flush()
        return 0

    def echo (self, color, text, stderr = False):
        self.set_color(color, stderr)
        if stderr:
            sys.stderr.write(text)
            sys.stderr.flush()
        else:
            sys.stdout.write(text)
            sys.stdout.flush()
        self.set_color(-1, stderr)
        return 0

    def print (self, color, text):
        return self.echo(color, text + '\n')

    def perror (self, color, text):
        return self.echo(color, text + '\n', True)

    def tabulify (self, rows):
        colsize = {}
        maxcol = 0
        maxwidth = 1024
        if self.isatty:
            tsize = self.get_term_size()
            maxwidth = max(2, tsize[0] - 2)
        if not rows:
            return -1
        for row in rows:
            maxcol = max(len(row), maxcol)
            for col, item in enumerate(row):
                if isinstance(item, list) or isinstance(item, tuple):
                    text = str(item[1])
                else:
                    text = str(item)
                size = len(text)
                if col not in colsize:
                    colsize[col] = size
                else:
                    colsize[col] = max(size, colsize[col])
        if maxcol <= 0:
            return ''
        last_color = -100
        for row in rows:
            avail = maxwidth
            for col, item in enumerate(row):
                csize = colsize[col]
                color = -1
                if isinstance(item, list) or isinstance(item, tuple):
                    color = item[0]
                    text = str(item[1])
                else:
                    text = str(item)
                text = str(text)
                padding = 2 + csize - len(text)
                pad1 = 1
                pad2 = padding - pad1
                output = (' ' * pad1) + text + (' ' * pad2)
                if last_color != color:
                    self.set_color(color)
                    last_color = color
                if avail <= 0:
                    break
                size = len(output)
                sys.stdout.write(output[:avail])
                sys.stdout.flush()
                avail -= size
            sys.stdout.write('\n')
        self.set_color(-1)
        return 0

    def error (self, text):
        self.echo('RED', 'Error: ', True)
        self.echo('WHITE', text + '\n', True)
        return 0

    def warning (self, text):
        self.echo('red', 'Warning: ', True)
        self.echo(-1, text + '\n', True)
        return 0

    def get_term_size (self):
        if sys.version_info[0] >= 30:
            import shutil
            if 'get_terminal_size' in shutil.__dict__:
                x = shutil.get_terminal_size()
                return (x[0], x[1])
        if sys.platform[:3] == 'win':
            if self.handle is None:
                self.__init_win32()
            csbi = self.StringBuffer
            res = self.kernel32.GetConsoleScreenBufferInfo(self.handle, csbi)
            if res:
                import struct
                res = struct.unpack("hhhhHhhhhhh", csbi.raw)
                left, top, right, bottom = res[5:9]
                columns = right - left + 1
                lines = bottom - top + 1
                return (columns, lines)
        if 'COLUMNS' in os.environ and 'LINES' in os.environ:
            try:
                columns = int(os.environ['COLUMNS'])
                lines = int(os.environ['LINES'])
                return (columns, lines)
            except:
                pass
        if sys.platform[:3] != 'win':
            try:
                import fcntl, termios, struct
                if sys.__stdout__.isatty():
                    fd = sys.__stdout__.fileno()
                elif sys.__stderr__.isatty():
                    fd = sys.__stderr__.fileno()
                res = fcntl.ioctl(fd, termios.TIOCGWINSZ, b"\x00" * 4)
                lines, columns = struct.unpack("hh", res)
                return (columns, lines)
            except:
                pass
        return (80, 24)


#----------------------------------------------------------------------
# internal
#----------------------------------------------------------------------
pretty = PrettyText()



#----------------------------------------------------------------------
# configure
#----------------------------------------------------------------------
class configure (object):

    def __init__ (self, path = None):
        self.win32 = sys.platform[:3] == 'win' and True or False
        self._cache = {}
        if not path:
            path = os.getcwd()
        else:
            path = os.path.abspath(path)
        if not os.path.exists(path):
            raise IOError('invalid path: %s'%path)
        if os.path.isdir(path):
            self.home = path
            self.target = 'dir'
        else:
            self.home = os.path.dirname(path)
            self.target = 'file'
        self.path = path
        self.filetype = None
        self.mark = '.git,.svn,.project,.hg,.root'
        if 'VIM_TASK_ROOTMARK' in os.environ:
            mark = os.environ['VIM_TASK_ROOTMARK'].strip()
            if mark:
                self.mark = mark
        mark = [ n.strip() for n in self.mark.split(',') ]
        self.root = self.find_root(self.home, mark, True)
        self.tasks = {}
        self.environ = {}
        self.config = {}
        self._load_config()
        if self.target == 'file':
            self.filetype = self.match_ft(self.path)
        self.feature = {}

    def read_ini (self, ininame, codec = None):
        ininame = os.path.abspath(ininame)
        key = ininame
        if self.win32:
            key = ininame.replace("\\", '/').lower()
        if key in self._cache:
            return self._cache[key]
        config = load_ini_file(ininame)
        self._cache[key] = config
        inihome = os.path.dirname(ininame)
        for sect in config:
            section = config[sect]
            for key in list(section.keys()):
                val = section[key]
                val = val.replace('$(VIM_INIHOME)', inihome)
                val = val.replace('$(VIM_ININAME)', ininame)
                section[key] = val
        return config

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

    def check_environ (self, key):
        if key in os.environ:
            if os.environ[key].strip():
                return True
        return False

    def extract_list (self, text):
        items = []
        for item in text.split(','):
            item = item.strip('\r\n\t ')
            if not item:
                continue
            items.append(item)
        return items

    def option (self, section, key, default):
        if section not in self.config:
            return default
        sect = self.config[section]
        return sect.get(key, default).strip()

    def _load_config (self):
        self.system = self.win32 and 'win32' or 'linux'
        self.profile = 'debug'
        self.cfg_name = '.tasks'
        self.rtp_name = 'tasks.ini'
        self.extra_config = []
        self.config = {}
        # load ~/.config
        name = os.path.expanduser('~/.config')
        if self.check_environ('XDG_CONFIG_HOME'):
            name = os.environ['XDG_CONFIG_HOME']
        name = os.path.join(name, 'asynctask/asynctask.ini')
        name = os.path.abspath(name)
        if os.path.exists(name):
            self.config = self.read_ini(name)
        if 'default' not in self.config:
            self.config['default'] = {}
        setting = self.config['default']
        self.system = setting.get('system', self.system).strip()
        self.cfg_name = setting.get('cfg_name', self.cfg_name).strip()
        self.rtp_name = setting.get('rtp_name', self.rtp_name).strip()
        if 'extra_config' in setting:
            for path in self.extract_list(setting['extra_config']):
                if '~' in path:
                    path = os.path.expanduser(path)
                if os.path.exists(path):
                    self.extra_config.append(os.path.abspath(path))
        # load from environment
        if self.check_environ('VIM_TASK_SYSTEM'):
            self.system = os.environ['VIM_TASK_SYSTEM']
        if self.check_environ('VIM_TASK_PROFILE'):
            self.profile = os.environ['VIM_TASK_PROFILE']
        if self.check_environ('VIM_TASK_CFG_NAME'):
            self._cfg_name = os.environ['VIM_TASK_CFG_NAME']
        if self.check_environ('VIM_TASK_RTP_NAME'):
            self._rtp_name = os.environ['VIM_TASK_RTP_NAME']
        if self.check_environ('VIM_TASK_EXTRA_CONFIG'):
            extras = os.environ['VIM_TASK_EXTRA_CONFIG']
            for path in self.extract_list(extras):
                if os.path.exists(path):
                    self.extra_config.append(os.path.abspath(path))
        return 0

    def trinity_split (self, text):
        p1 = text.find(':')
        p2 = text.find('/')
        if p1 < 0 and p2 < 0:
            return [text, '', '']
        parts = text.replace('/', ':').split(':')
        if p1 >= 0 and p2 >= 0:
            if p1 < p2:
                return [parts[0], parts[1], parts[2]]
            else:
                return [parts[0], parts[2], parts[1]]
        elif p1 >= 0 and p2 < 0:
            return [parts[0], parts[1], '']
        elif p1 < 0 and p2 >= 0:
            return [parts[0], '', parts[1]]
        return [text, '', '']

    def config_merge (self, target, source, ininame, mode):
        special = []
        for key in source:
            if ':' in key:
                special.append(key)
            elif '/' in key:
                special.append(key)
            elif key != '*':
                target[key] = source[key]
                if ininame:
                    target[key]['__name__'] = ininame
                if mode:
                    target[key]['__mode__'] = mode
        for key in special:
            parts = self.trinity_split(key)
            parts = [ n.strip('\r\n\t ') for n in parts ]
            name = parts[0]
            if parts[1]:
                if self.profile != parts[1]:
                    continue
            if parts[2]:
                feature = self.feature.get(parts[2], False)
                if not feature:
                    continue
            target[name] = source[key]
            if ininame:
                target[name]['__name__'] = ininame
            if mode:
                target[name]['__mode__'] = mode
        return 0

    # search for global configs
    def collect_rtp_config (self):
        names = []
        t = os.path.join(os.path.expanduser('~/.vim'), self.rtp_name)
        if os.path.exists(t):
            names.append(os.path.abspath(t))
        for path in self.extra_config:
            if os.path.exists(path):
                names.append(os.path.abspath(path))
        for name in names:
            obj = self.read_ini(name)
            self.config_merge(self.tasks, obj, name, 'global')        
        return 0

    # search parent
    def search_parent (self, path):
        output = []
        path = os.path.abspath(path)
        while True:
            parent = os.path.normpath(os.path.join(path, '..'))
            output.append(path)
            if os.path.normcase(path) == os.path.normcase(parent):
                break
            path = parent
        return output

    # search for local configs
    def collect_local_config (self):
        names = self.search_parent(self.home)
        for name in names:
            t = os.path.abspath(os.path.join(name, self.cfg_name))
            if not os.path.exists(t):
                continue
            obj = self.read_ini(t)
            self.config_merge(self.tasks, obj, t, 'local')
        return 0

    # merge global and local config
    def load_tasks (self):
        self.tasks = {}
        self.collect_rtp_config()
        self.collect_local_config()
        return 0

    # extract file type
    def match_ft (self, name):
        name = os.path.abspath(name)
        name = os.path.split(name)[-1]
        detect = {}
        for n in FILE_TYPES:
            detect[n] = FILE_TYPES[n]
        if 'filetypes' in self.config:
            filetypes = self.config['filetypes']
            for n in filetypes:
                detect[n] = filetypes[n]
        for ft in detect:
            rules = [ n.strip() for n in detect[ft].split(',') ]
            for rule in rules:
                if not rule:
                    continue
                if fnmatch.fnmatch(name, rule):
                    return ft
        return None

    def path_win2unix (self, path, prefix = '/mnt'):
        if path is None:
            return None
        path = path.replace('\\', '/')
        if path[1:3] == ':/':
            t = os.path.join(prefix, path[:1])
            path = os.path.join(t, path[3:])
        elif path[:1] == '/':
            t = os.path.join(prefix, os.getcwd()[:1])
            path = os.path.join(t, path[2:])
        else:
            path = path.replace('\\', '/')
        return path.replace('\\', '/')

    def macros_expand (self):
        macros = {}
        if self.target == 'file':
            t = os.path.splitext(os.path.basename(self.path))
            macros['VIM_FILEPATH'] = self.path
            macros['VIM_FILENAME'] = os.path.basename(self.path)
            macros['VIM_FILEDIR'] = os.path.abspath(self.home)
            macros['VIM_FILETYPE'] = self.filetype
            macros['VIM_FILEEXT'] = t[-1]
            macros['VIM_FILENOEXT'] = t[0]
            macros['VIM_PATHNOEXT'] = os.path.splitext(self.path)[0]
            macros['VIM_RELDIR'] = os.path.relpath(macros['VIM_FILEDIR'])
            macros['VIM_RELNAME'] = os.path.relpath(macros['VIM_FILEPATH'])
        else:
            macros['VIM_FILEPATH'] = None
            macros['VIM_FILENAME'] = None
            macros['VIM_FILEDIR'] = None
            macros['VIM_FILETYPE'] = None
            macros['VIM_FILEEXT'] = None
            macros['VIM_FILENOEXT'] = None
            macros['VIM_PATHNOEXT'] = None
            macros['VIM_RELDIR'] = None
            macros['VIM_RELNAME'] = None
        macros['VIM_CWD'] = os.getcwd()
        macros['VIM_ROOT'] = self.root
        macros['VIM_DIRNAME'] = os.path.basename(macros['VIM_CWD'])
        macros['VIM_PRONAME'] = os.path.basename(macros['VIM_ROOT'])
        if sys.platform[:3] == 'win':
            t = ['FILEPATH', 'FILEDIR', 'FILENAME', 'FILEEXT', 'FILENOEXT']
            t += ['PATHNOEXT', 'CWD', 'RELDIR', 'RELNAME', 'ROOT']
            for name in t:
                dst = 'WSL_' + name
                src = 'VIM_' + name
                if src in macros:
                    macros[dst] = self.path_win2unix(macros[src], '/mnt')
        return macros

    def macros_replace (self, text, macros):
        for name in macros:
            t = macros[name] and macros[name] or ''
            text = text.replace('$(' + name + ')', t)
        text = text.replace('<root>', macros.get('VIM_ROOT', ''))
        text = text.replace('<cwd>', macros.get('VIM_CWD', ''))
        return text
        

#----------------------------------------------------------------------
# manager
#----------------------------------------------------------------------
class TaskManager (object):

    def __init__ (self, path):
        self.config = configure(path)
        self.code = 0
        self.verbose = False

    def command_select (self, task):
        command = task.get('command', '')
        filetype = self.config.filetype
        for key in task:
            if (':' not in key) and ('/' not in key):
                continue
            parts = self.config.trinity_split(key)
            parts = [ n.strip('\r\n\t ') for n in parts ]
            if parts[0] != 'command':
                continue
            if parts[1]:
                check = 0
                for ft in parts[1].split(','):
                    ft = ft.strip()
                    if ft == filetype:
                        check = 1
                        break
                if check == 0:
                    continue
            if parts[2]:
                if parts[2] != self.config.system:
                    continue
            return task[key]
        return command

    def command_check (self, command, task):
        disable = ['FILEPATH', 'FILENAME', 'FILEDIR', 'FILEEXT']
        disable += ['FILENOEXT', 'PATHNOEXT', 'RELDIR', 'RELNAME']
        cwd = task.get('cwd', '')
        ini = task.get('__name__', '')
        if self.config.target != 'file':
            for name in disable:
                for head in ['$(VIM_', '$(WSL_']:
                    macro = head + name + ')'
                    if macro in command:
                        pretty.error('task command requires a file name')
                        if ini: print('from %s:'%ini)
                        pretty.perror('BLACK', 'command=' + command)
                        return 1
                    if macro in cwd: 
                        pretty.error('task cwd requires a file name')
                        if ini: print('from %s:'%ini)
                        pretty.perror('BLACK', 'cwd=' + cwd)
                        return 2
        disable = ['CFILE', 'CLINE', 'GUI', 'VERSION', 'COLUMNS', 'LINES']
        disable += ['SVRNAME', 'WSL_CFILE']
        for name in disable:
            if name == 'WSL_CFILE':
                macro = '$(WSL_CFILE)'
            else:
                macro = '$(VIM_' + name + ')'
            if name in command:
                t = '%s is invalid in command line'%macro
                pretty.error(t)
                if ini: print('from %s:'%ini)
                pretty.perror('BLACK', 'command=' + command)
                return 3
            if name in cwd:
                t = '%s is invalid in command line'%macro
                pretty.error(t)
                if ini: print('from %s:'%ini)
                pretty.perror('BLACK', 'cwd=' + cwd)
                return 4
        return 0

    def task_option (self, task):
        opts = OBJECT()
        opts.command = task.get('command', '')
        opts.cwd = task.get('cwd')
        opts.macros = self.config.macros_expand()
        if opts.cwd:
            opts.cwd = self.config.macros_replace(opts.cwd, opts.macros)
        return opts

    def execute (self, opts):
        command = opts.command
        macros = opts.macros
        macros['VIM_CWD'] = os.getcwd()
        macros['VIM_DIRNAME'] = os.path.basename(macros['VIM_CWD'])
        if self.config.target == 'file':
            macros['VIM_RELDIR'] = os.path.relpath(macros['VIM_FILEDIR'])
            macros['VIM_RELNAME'] = os.path.relpath(macros['VIM_FILEPATH'])
        if self.config.win32:
            macros['WSL_CWD'] = self.config.path_win2unix(macros['VIM_CWD'])
            if self.config.target == 'file':
                x = macros['VIM_RELDIR']
                y = macros['VIM_RELNAME']
                macros['WSL_RELDIR'] = self.config.path_win2unix(x)
                macros['WSL_RELNAME'] = self.config.path_win2unix(y)
        command = self.config.macros_replace(command, macros)
        for name in macros:
            value = macros.get(name, None)
            if value is not None:
                os.environ[name] = value
        self.code = os.system(command)
        return 0

    def task_run (self, taskname):
        self.config.load_tasks()
        if taskname not in self.config.tasks:
            pretty.error('not find task [' + taskname + ']')
            return -2
        task = self.config.tasks[taskname]
        ininame = task.get('__name__', '<unknow>')
        source = 'task [' + taskname + ']'
        command = self.command_select(task)
        if not command:
            pretty.error('no command defined in ' + source)
            if ininame:
                pretty.perror('white', 'from ' + ininame)
            return -3
        hr = self.command_check(command, task)
        if hr != 0:
            return -4
        opts = self.task_option(task)
        opts.command = command
        save = os.getcwd()
        if opts.cwd:
            os.chdir(opts.cwd)
        self.execute(opts)
        if opts.cwd:
            os.chdir(save)
        return 0

    def task_list (self, all = False):
        self.config.load_tasks()
        rows = []
        c0 = 'YELLOW'
        c1 = 'RED'
        c2 = 'cyan'
        c3 = 'white'
        c4 = 'BLACK'
        rows.append([(c0, 'Task'), (c0, 'Type'), (c0, 'Detail')])
        for name in self.config.tasks:
            if (not all) and name.startswith('.'):
                continue
            task = self.config.tasks[name]
            command = self.command_select(task)
            mode = task.get('__mode__')
            ini = task.get('__name__', '')
            rows.append([(c1, name), (c2, mode), (c3, command)])
            if ini:
                rows.append(['', '', (c4, ini)])
        pretty.tabulify(rows)
        return 0

    def task_macros (self, wsl = False):
        macros = self.config.macros_expand()
        names = ['FILEPATH', 'FILENAME', 'FILEDIR', 'FILEEXT', 'FILETYPE']
        names += ['FILENOEXT', 'PATHNOEXT', 'CWD', 'RELDIR', 'RELNAME']
        names += ['ROOT', 'DIRNAME', 'PRONAME']
        rows = []
        c0 = 'YELLOW'
        c1 = 'RED'
        c3 = 'white'
        c4 = 'BLACK'
        rows.append([(c0, 'Macro'), (c0, 'Detail'), (c0, 'Value')])
        for nn in names:
            name = ((not wsl) and 'VIM_' or 'WSL_') + nn
            if (name not in macros) or (name not in MACROS_HELP):
                continue
            help = MACROS_HELP[name]
            text = macros[name]
            rows.append([(c1, name), (c3, help), (c4, text)])
        pretty.tabulify(rows)
        return 0


#----------------------------------------------------------------------
# testing suit
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        c = configure('d:/acm/github/vim/autoload')
        # cfg = c.read_ini(os.path.expanduser('~/.vim/tasks.ini'))
        # pprint.pprint(cfg)
        print(c.root)
        print(c.trinity_split('command:vim/win32'))
        print(c.trinity_split('command/win32:vim'))
        print(c.trinity_split('command/win32'))
        print(c.trinity_split('command:vim'))
        print(c.trinity_split('command'))
        pprint.pprint(c.tasks)
        # print(c.search_parent('d:/acm/github/vim/autoload/quickui'))
        return 0
    def test2():
        # tm = TaskManager('d:/acm/github/vim/autoload/quickui/generic.vim')
        tm = TaskManager('')
        print(tm.config.root)
        tm.config.load_tasks()
        pprint.pprint(tm.config.tasks)
    def test3():
        # pretty.print('cyan', 'hello')
        rows = []
        rows.append(['Name', 'Gender'])
        rows.append([('red', 'Zhang Jia'), 'male'])
        rows.append(['Lin Ting Ting', 'female'])
        # print('fuck you')
        print('hahahah')
        pretty.tabulify(rows)
        pretty.error('something error')
        return 0
    def test4():
        tm = TaskManager('d:/ACM/github/kcp/test.cpp')
        print(tm.config.filetype)
        pprint.pprint(tm.config.macros_expand())
        print(tm.config.path_win2unix('d:/ACM/github'))
        # tm.task_run('task2')
    def test5():
        tm = TaskManager('d:/ACM/github/vim/autoload/quickui')
        tm.task_run('p2')
        # print(tm.config.filetype)
    def test6():
        tm = TaskManager('d:/ACM/github/vim/autoload/quickui/context.vim')
        tm.task_list()
        # tm.task_macros(True)
        # size = pretty.get_term_size()
        # print('terminal size:', size)
    test6()


