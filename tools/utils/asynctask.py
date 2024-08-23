#! /usr/bin/env python3
# -*- coding: utf-8 -*-
#======================================================================
#
# asynctask.py - execute tasks in command line
#
# Maintainer: skywind3000 (at) gmail.com, 2020
#
# Last Modified: 2024/08/20 15:17:27
# Verision: 1.2.5
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
import tempfile
import codecs
import shutil


#----------------------------------------------------------------------
# 2/3 compatible
#----------------------------------------------------------------------
if sys.version_info[0] >= 3:
    unicode = str
    long = int


UNIX = (sys.platform[:3] != 'win') and True or False
HAS_READLINE = False

if UNIX:
    try:
        import readline
        HAS_READLINE = True
    except ImportError:
        pass


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
    'VIM_PROFILE': 'Current building profile (debug/release/...)',
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
# can be overrided in ~/.config/asynctask/asynctask.ini
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
# read_ini, configparser has problems in parsing key with colon
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
# Prettify Terminal Text
#----------------------------------------------------------------------
class PrettyText (object):

    def __init__ (self):
        self.isatty = sys.__stdout__.isatty()
        self.term256 = False
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
        if sys.platform[:3] != 'win':
            if '256' in os.environ.get('TERM', ''):
                self.term256 = True
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
                if avail <= 0:
                    break
                size = len(output)
                self.echo(color, output[:avail])
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
        self.tasks = {}
        self.environ = {}
        self.setting = {}
        self.config = {}
        self.avail = []
        self.shadow = {}
        self.reserved = ['*', '+', '-', '%', '#']
        self._load_config()
        if self.target == 'file':
            self.filetype = self.match_ft(self.path)
        self._root_detect()

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
                if not marker:
                    continue
                test = os.path.join(base, marker)
                if ('*' in test) or ('?' in test) or ('[' in test):
                    import glob
                    if glob.glob(test):
                        return base
                if os.path.exists(test):
                    return base
            if os.path.normcase(parent) == os.path.normcase(base):
                break
            base = parent
        if fallback:
            return path
        return None

    def relpath (self, path, base = None):
        if not base:
            base = os.getcwd()
        base = os.path.abspath(base)
        path = os.path.abspath(path)
        if self.win32:
            try:
                return os.path.relpath(path, base)
            except ValueError:
                return path
        return os.path.relpath(path, base)

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
        self.global_config = []
        self.config = {}
        self.feature = {}
        # load ~/.config
        xdg = os.path.expanduser('~/.config')
        if self.check_environ('XDG_CONFIG_HOME'):
            xdg = os.environ['XDG_CONFIG_HOME']
        name = os.path.join(xdg, 'asynctask/asynctask.ini')
        name = os.path.abspath(name)
        if os.path.exists(name):
            self.config = self.read_ini(name)
        if 'default' not in self.config:
            self.config['default'] = {}
        setting = self.config['default']
        self.system = setting.get('system', self.system).strip()
        self.cfg_name = setting.get('cfg_name', self.cfg_name).strip()
        self.rtp_name = setting.get('rtp_name', self.rtp_name).strip()
        self.global_config.append('~/.vim/' + self.rtp_name)
        self.global_config.append(os.path.join(xdg, 'nvim', self.rtp_name))
        self.global_config.append('~/.config/asynctask/' + self.rtp_name)
        if 'global_config' in setting:
            for path in self.extract_list(setting['global_config']):
                if '~' in path:
                    path = os.path.expanduser(path)
                if os.path.exists(path):
                    self.global_config.append(os.path.abspath(path))
        if 'extra_config' in setting:
            for path in self.extract_list(setting['extra_config']):
                if '~' in path:
                    path = os.path.expanduser(path)
                if os.path.exists(path):
                    self.global_config.append(os.path.abspath(path))
        if 'feature' in setting:
            for feat in self.extract_list(setting['feature']):
                feat = feat.strip()
                if feat:
                    self.feature[feat] = True
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
                    self.global_config.append(os.path.abspath(path))
        return 0

    def _root_detect (self):
        self.mark = '.git,.svn,.project,.hg,.root'
        if 'root_marker' in self.config['default']:
            self.mark = self.config['default']['root_marker']
        if 'VIM_TASK_ROOTMARK' in os.environ:
            mark = os.environ['VIM_TASK_ROOTMARK'].strip()
            if mark:
                self.mark = mark
        mark = [ n.strip() for n in self.mark.split(',') ]
        self.root = self.find_root(self.home, mark, True)
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
        setting = self.reserved
        for key in source:
            if ':' in key:
                special.append(key)
            elif '/' in key:
                special.append(key)
            elif key not in setting:
                target[key] = source[key]
                if ininame:
                    target[key]['__name__'] = ininame
                if mode:
                    target[key]['__mode__'] = mode
            else:
                if key not in target:
                    target[key] = {}
                for name in source[key]:
                    target[key][name] = source[key][name]
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
        for path in self.global_config:
            if '~' in path:
                path = os.path.expanduser(path)
            if os.path.exists(path):
                names.append(os.path.abspath(path))
        newname = []
        checker = {}
        names.reverse()
        for name in names:
            key = os.path.normcase(name)
            if key not in checker:
                newname.append(name)
                checker[key] = 1
        newname.reverse()
        names = newname
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
        output.reverse()
        return output

    # search for local configs
    def collect_local_config (self):
        names = self.search_parent(self.home)
        parts = self.cfg_name.split(',')
        for name in names:
            for part in parts:
                part = part.strip('\r\n\t ')
                if not part:
                    continue
                t = os.path.abspath(os.path.join(name, part))
                if os.path.exists(t):
                    obj = self.read_ini(t)
                    self.config_merge(self.tasks, obj, t, 'local')
        return 0

    # merge global and local config
    def load_tasks (self):
        self.tasks = {}
        self.collect_rtp_config()
        self.collect_local_config()
        self.environ = self.tasks.get('*', {})
        self.environ.update(self.tasks.get('+', {}))
        self.setting = {}
        setting = self.reserved
        for name in setting:
            self.setting[name] = self.tasks.get(name, {})
        self.avail = []
        keys = list(self.tasks.keys())
        keys.sort()
        for key in keys:
            if key in setting:
                continue
            self.avail.append(key)
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
            macros['VIM_RELDIR'] = self.relpath(macros['VIM_FILEDIR'])
            macros['VIM_RELNAME'] = self.relpath(macros['VIM_FILEPATH'])
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
        macros['VIM_PROFILE'] = self.profile
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

    def mark_replace (self, text, mark_open, mark_close, handler):
        size_open = len(mark_open)
        while True:
            p1 = text.find(mark_open)
            if p1 < 0:
                break
            p2 = text.find(mark_close, p1)
            if p2 < 0:
                break
            name = text[p1 + size_open:p2]
            mark = mark_open + name + mark_close
            data = handler(name.strip('\r\n\t '))
            if data is None:
                return ''
            elif isinstance(data, list):
                if len(data) > 0:
                    msg = 'in ' + mark + ': '
                    pretty.error(msg + data[0])
                return ''
            text = text.replace(mark, data)
        return text

    def _handle_environ (self, text):
        key, sep, default = text.strip().partition(':')
        key = key.strip()
        if '+' in self.shadow:
            shadow = self.shadow['+']
            if key in shadow:
                return shadow[key]
        if key not in self.environ:
            if sep == '':
                return ['Internal variable "' + key + '" is undefined']
            else:
                return default
        return self.environ[key]

    def _handle_osenv (self, text):
        key, sep, default = text.strip().partition(':')
        key = key.strip()
        return os.environ.get(key, default.strip())

    def environ_replace (self, text):
        text = self.mark_replace(text, '$(+', ')', self._handle_environ)
        text = self.mark_replace(text, '$(VIM:', ')', self._handle_environ)
        text = self.mark_replace(text, '$(%', ')', self._handle_osenv)
        return text


#----------------------------------------------------------------------
# manager
#----------------------------------------------------------------------
class TaskManager (object):

    def __init__ (self, path):
        self.config = configure(path)
        self.code = 0
        self.verbose = False

    def option_select (self, task, name):
        command = task.get(name, '')
        filetype = self.config.filetype
        for key in task:
            if (':' not in key) and ('/' not in key):
                continue
            parts = self.config.trinity_split(key)
            parts = [ n.strip('\r\n\t ') for n in parts ]
            if parts[0] != name:
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

    def command_select (self, task):
        return self.option_select(task, 'command')

    def command_check (self, command, task):
        disable = ['FILEPATH', 'FILENAME', 'FILEDIR', 'FILEEXT', 'FILETYPE']
        disable += ['FILENOEXT', 'PATHNOEXT', 'RELDIR', 'RELNAME']
        cwd = task.get('cwd', '')
        ini = task.get('__name__', '')
        cc = 'cyan'
        if self.config.target != 'file':
            for name in disable:
                for head in ['$(VIM_', '$(WSL_']:
                    macro = head + name + ')'
                    if macro in command:
                        pretty.error('task command requires a file name')
                        if ini: print('from %s:'%ini)
                        pretty.perror(cc, 'command=' + command)
                        return 1
                    if macro in cwd:
                        pretty.error('task cwd requires a file name')
                        if ini: print('from %s:'%ini)
                        pretty.perror(cc, 'cwd=' + cwd)
                        return 2
        disable = ['CFILE', 'CLINE', 'GUI', 'VERSION', 'COLUMNS', 'LINES']
        disable += ['SVRNAME', 'WSL_CFILE']
        for name in disable:
            if name == 'WSL_CFILE':
                macro = '$(WSL_CFILE)'
            else:
                macro = '$(VIM_' + name + ')'
            if macro in command:
                t = '%s is invalid in command line'%macro
                pretty.error(t)
                if ini: print('from %s:'%ini)
                pretty.perror(cc, 'command=' + command)
                return 3
            if macro in cwd:
                t = '%s is invalid in command line'%macro
                pretty.error(t)
                if ini: print('from %s:'%ini)
                pretty.perror(cc, 'cwd=' + cwd)
                return 4
        if command.lstrip().startswith(':'):
            pretty.error('command starting with colon is not allowed here')
            return 5
        return 0

    def raw_input (self, prompt):
        try:
            if sys.version_info[0] < 3:
                text = raw_input(prompt)  # noqa: F821
            else:
                text = input(prompt)
        except KeyboardInterrupt:
            return ''
        return text

    def _handle_input (self, varname):
        name, sep, tail = varname.strip().partition(':')
        name = name.strip()
        tail = tail.strip()
        if '-' in self.config.shadow:
            shadow = self.config.shadow['-']
            if name in shadow:
                return shadow[name]
        if ',' not in tail:
            prompt = 'Input argument (%s): '%name
            # for linux like system, using readline for editable default value
            if UNIX and HAS_READLINE: 
                text = ''
                try:
                    readline.set_startup_hook(lambda: readline.insert_text(tail))
                    text = self.raw_input(prompt)
                finally:
                    readline.set_startup_hook()
            else:
                text = self.raw_input(prompt)
                if not text:
                    text = tail.strip()
        else:
            select = []
            for part in tail.split(','):
                part = part.replace('&', '').strip()
                if part:
                    select.append(part)
            if len(select) == 0:
                prompt = 'Input argument (%s): '%name
                text = self.raw_input(prompt)
            else:
                print('Select argument (%s): '%name)
                for index, part in enumerate(select):
                    print('%d. %s'%(index + 1, part))
                text = ''
                if len(select) > 0:
                    index = self.raw_input('Type number: ')
                    try:
                        index = int(index)
                    except:
                        index = 0
                    if index > 0 and index <= len(select):
                        text = select[index - 1]
        text = text.strip()
        if not text:
            return None
        return text

    def command_input (self, command):
        if '$(VIM_CWORD)' in command:
            command = command.replace('$(VIM_CWORD)', '$(?CWORD)')
        command = self.config.mark_replace(command, '$(-', ')', self._handle_input)
        command = self.config.mark_replace(command, '$(?', ')', self._handle_input)
        return command

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
            macros['VIM_RELDIR'] = self.config.relpath(macros['VIM_FILEDIR'])
            macros['VIM_RELNAME'] = self.config.relpath(macros['VIM_FILEPATH'])
        if self.config.win32:
            macros['WSL_CWD'] = self.config.path_win2unix(macros['VIM_CWD'])
            if self.config.target == 'file':
                x = macros['VIM_RELDIR']
                y = macros['VIM_RELNAME']
                macros['WSL_RELDIR'] = self.config.path_win2unix(x)
                macros['WSL_RELNAME'] = self.config.path_win2unix(y)
        command = self.config.environ_replace(command)
        command = self.config.macros_replace(command, macros)
        command = command.strip()
        for name in macros:
            value = macros.get(name, None)
            if value is not None:
                os.environ[name] = value
        if self.verbose:
            pretty.echo('white', '+ ' + command + '\n')
        if not command:
            return 0
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
        command = command.strip()
        if not command:
            pretty.error('no command defined in ' + source)
            if ininame:
                pretty.perror('white', 'from ' + ininame)
            return -3
        precmd = self.option_select(task, 'precmd')
        if precmd:
            precmd = precmd.strip()
            if precmd:
                command = precmd + ' && ' + command
        hr = self.command_check(command, task)
        if hr != 0:
            return -4
        command = self.command_input(command)
        command = command.strip()
        if not command:
            return 0
        opts = self.task_option(task)
        opts.command = command
        save = os.getcwd()
        if opts.cwd:
            cwd = self.config.environ_replace(opts.cwd)
            if cwd:
                os.chdir(cwd)
        self.execute(opts)
        if opts.cwd:
            os.chdir(save)
        return 0

    def task_list (self, all = False, raw = False):
        self.config.load_tasks()
        rows = []
        c0 = 'yellow'
        c1 = 'RED'
        c2 = 'cyan'
        c3 = 'white'
        c4 = 'BLACK'
        if raw:
            for name in self.config.avail:
                if (not all) and name.startswith('.'):
                    continue
                task = self.config.tasks[name]
                command = self.command_select(task)
                mode = task.get('__mode__')
                rows.append([(c1, name), (c2, mode), (c3, command)])
            pretty.tabulify(rows)
            return 0
        rows.append([(c0, 'Task'), (c0, 'Type'), (c0, 'Detail')])
        for name in self.config.avail:
            if (not all) and name.startswith('.'):
                continue
            task = self.config.tasks[name]
            command = self.command_select(task)
            mode = task.get('__mode__')
            ini = task.get('__name__', '')
            rows.append([(c1, name), (c2, mode), (c3, command)])
            if ini: rows.append(['', '', (c4, ini)])
        pretty.tabulify(rows)
        return 0

    def task_macros (self, wsl = False):
        macros = self.config.macros_expand()
        names = ['FILEPATH', 'FILENAME', 'FILEDIR', 'FILEEXT', 'FILETYPE']
        names += ['FILENOEXT', 'PATHNOEXT', 'CWD', 'RELDIR', 'RELNAME']
        names += ['ROOT', 'DIRNAME', 'PRONAME', 'PROFILE']
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

    def setup (self, opts):
        if 'profile' in opts:
            profile = opts['profile']
            if profile:
                self.config.profile = profile
        if 'v' in opts or 'verbose' in opts:
            self.verbose = True
        return 0

    def interactive (self, way):
        # self.config
        self.config.load_tasks()
        names = []
        for name in self.config.avail:
            if not name.startswith('.'):
                names.append(name)
        if len(names) == 0:
            return 0
        names.sort()
        tasks = {}
        for name in names:
            task = self.config.tasks[name]
            command = self.command_select(task)
            mode = task.get('__mode__')
            tasks[name] = (mode, command)
        if way == 0:
            rows = []
            for index, name in enumerate(names):
                mode, command = tasks[name]
                ii = ('WHITE', str(index + 1) + ':')
                rows.append([ii, ('RED', name), command])
            rows.reverse()
            pretty.tabulify(rows)
            if sys.version_info[0] >= 3:
                text = input('> ')
            else:
                text = raw_input('> ')    # noqa: F821
            text = text.strip()
            if not text:
                return 0
            if not text.isdigit():
                return 0
            i = int(text)
            if i < 1 or i > len(names):
                return 0
            return self.task_run(names[i - 1])
        else:
            setting = self.config.config['default']
            fzf = setting.get('fzf', 'fzf')
            cmd = '--nth 1 --reverse --inline-info --tac '
            flag = setting.get('fzf_flag', '')
            flag = (not flag) and '+s ' or flag
            cmd = (fzf and fzf or 'fzf') + ' ' + cmd + ' ' + flag
            cmd += ' --height 35%'
            rows = []
            width = 0
            names.reverse()
            for index, name in enumerate(names):
                mode, command = tasks[name]
                rows.append([name, command])
                if len(name) > width:
                    width = len(name)
            for row in rows:
                row[0] = row[0] + ' ' * (width - len(row[0]) + 2)
            tmpdir = tempfile.mkdtemp('asynctask')
            tmpname = os.path.join(tmpdir, 'fzf.txt')
            tmprecv = os.path.join(tmpdir, 'output.txt')
            if os.path.exists(tmprecv):
                os.remove(tmprecv)
            with codecs.open(tmpname, 'w', encoding = 'utf-8') as fp:
                for row in rows:
                    fp.write('%s: %s\r\n'%(row[0], row[1]))
            if sys.platform[:3] != 'win':
                cmd = cmd + ' < "' + tmpname + '"'
            else:
                cmd = 'type "' + tmpname + '" | ' + cmd
            cmd += ' > "'  + tmprecv + '"'
            code = os.system(cmd)
            if code != 0:
                return 0
            text = ''
            with codecs.open(tmprecv, 'r', encoding = 'utf-8') as fp:
                text = fp.read()
            if tmpdir:
                shutil.rmtree(tmpdir)
            text = text.strip('\r\n\t ')
            p1 = text.find(':')
            if p1 < 0:
                return 0
            text = text[:p1].rstrip('\r\n\t ')
            if not text:
                return 0
            return self.task_run(text)
        return 0


#----------------------------------------------------------------------
# getopt: returns (options, args)
#----------------------------------------------------------------------
def getopt (argv):
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
            if head not in ('-', '+'):
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


#----------------------------------------------------------------------
# display help text
#----------------------------------------------------------------------
def usage_help(prog):
    print('usage: %s <operation>'%prog)
    print('operations:')
    print('    %s {taskname}        - run task'%prog)
    print('    %s {taskname} <file> - run task with a file'%prog)
    print('    %s {taskname} <path> - run task in dest directory'%prog)
    print('    %s -l                - list tasks (use -L for all)'%prog)
    print('    %s -h                - show this help'%prog)
    print('    %s -m                - display command macros'%prog)
    print('    %s -i                - interactive mode'%prog)
    print('    %s -f                - interactive mode with fzf'%prog)
    # print('')
    return 0


#----------------------------------------------------------------------
# main entry
#----------------------------------------------------------------------
def main(args = None):
    args = args if args is not None else sys.argv
    args = [ n for n in args ]
    prog = 'asynctask.py' if not args else args[0]
    prog = os.path.basename(prog and prog or 'asynctask.py')
    prog = 'asynctask'
    if len(args) <= 1:
        pretty.error('require task name, use %s -h for help'%prog)
        return 1
    opts, args = getopt(args[1:])
    if 'h' in opts:
        usage_help(prog)
        return 0
    if ('l' in opts) or ('L' in opts) or ('m' in opts) or ('M' in opts):
        path = '' if not args else args[0]
        if path and (not os.path.exists(path)):
            pretty.error('path not exists: %s'%path)
            return 2
        tm = TaskManager(path)
        if 'raw' in opts:
            tm.task_list('L' in opts, True)
            return 0
        elif ('l' in opts) or ('L' in opts):
            tm.task_list('L' in opts)
            return 0
        else:
            tm.setup(opts)
            tm.task_macros('M' in opts)
            return 0
    if 'i' in opts or 'f' in opts:
        path = '' if not args else args[0]
        if path and (not os.path.exists(path)):
            pretty.error('path not exists: %s'%path)
            return 2
        tm = TaskManager(path)
        tm.setup(opts)
        mode = 0 if 'i' in opts else 1
        tm.interactive(mode)
        return 0
    if len(args) == 0:
        pretty.error('require task name, use %s -h for help'%prog)
        return 1
    taskname = args[0]
    opt2, extra = getopt(args[1:])
    path = (len(extra) > 0) and extra[-1] or ''
    path = path.strip('\r\n\t ')
    if path and (not os.path.exists(path)):
        pretty.error('path not exists: %s'%path)
        return 2
    tm = TaskManager(path)
    tm.config.shadow['+'] = {}
    tm.config.shadow['-'] = {}
    for key in opt2:
        if key.startswith('+'):
            tm.config.shadow['+'][key[1:]] = opt2[key]
        else:
            tm.config.shadow['-'][key] = opt2[key]
    tm.setup(opts)
    hr = tm.task_run(taskname)
    return hr


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
    def test7():
        args = ['', '-m']
        main(args)
    # test7()
    exit(main())


