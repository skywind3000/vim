#! /usr/bin/env python3
# -*- coding: utf-8 -*-
#======================================================================
#
# codecheck.py - Extract @input/@output/@args/@timeout test directives
#                from source comments and verify expected output
#
# Description:
#   This tool scans C/C++/Python source files for embedded test directives
#   (@input, @output, @args, @timeout) in comments, compiles (for C/C++) or
#   directly runs (for Python) the source, feeds @input as stdin, and
#   compares actual output against @output expectations — enabling automated
#   unit testing embedded directly in source code comments.
#
#   Three run modes are supported:
#     start  - compile and run the source file (default, no test verification)
#     debug  - run a test case with @input as stdin but without output comparison
#     check  - run test cases one by one and verify output against @output
#
# Usage examples:
#   codecheck.py hello.c            # compile and run
#   codecheck.py -c hello.c         # check all test cases
#   codecheck.py -c -1 hello.c      # check only the 1st test case
#   codecheck.py -d hello.c         # debug run (no output compare)
#   codecheck.py -d -2 hello.c      # debug the 2nd test case
#   codecheck.py -a hello.c         # compile and run with @args
#
# Embedding test cases in C/C++ source:
#   // @input: test1
#   // 10 20
#   // @output:
#   // 30 
#
# Embedding test cases in Python source:
#   # @input: test1
#   # 10 20
#   # @output:
#   # 30
#
# Config file: ~/.config/codecheck.ini
#   [default]
#   cc = /usr/bin/gcc          # C/C++ compiler path
#   python = /usr/bin/python3  # Python interpreter path
#   flags = -O2 -g -Wall       # default compile flags
#   cflags = ...               # C-specific compile flags
#   cxxflags = ...             # C++-specific compile flags
#   ldflags = ...              # linker flags
#
# Created by skywind on 2026/05/23
# Last Modified: 2026/05/25 22:56:37
#
#======================================================================
import sys
import os
import time
import re
import shutil
import subprocess
import shlex


#----------------------------------------------------------------------
# version
#----------------------------------------------------------------------
VERSION = '0.1.0'


#----------------------------------------------------------------------
# tokenize
#----------------------------------------------------------------------
def tokenize(code, specs, eof = None):
    patterns = []
    definition = {}
    extended = {}
    if not specs:
        return None
    for index in range(len(specs)):
        spec = specs[index]
        name, pattern = spec[:2]
        pn = 'PATTERN%d'%index
        definition[pn] = name
        if len(spec) >= 3:
            extended[pn] = spec[2]
        patterns.append((pn, pattern))
    tok_regex = '|'.join('(?P<%s>%s)' % pair for pair in patterns)
    line_starts = []
    pos = 0
    index = 0
    while 1:
        line_starts.append(pos)
        pos = code.find('\n', pos)
        if pos < 0:
            break
        pos += 1
    line_num = 0
    for mo in re.finditer(tok_regex, code):
        kind = mo.lastgroup
        value = mo.group()
        start = mo.start()
        while line_num < len(line_starts) - 1:
            if line_starts[line_num + 1] > start:
                break
            line_num += 1
        line_start = line_starts[line_num]
        name = definition[kind]
        if name is None:
            continue
        if callable(name):
            if kind not in extended:
                obj = name(value)
            else:
                obj = name(value, extended[kind])
            name = None
            if isinstance(obj, list) or isinstance(obj, tuple):
                if len(obj) > 0: 
                    name = obj[0]
                if len(obj) > 1:
                    value = obj[1]
            else:
                name = obj
        yield (name, value, line_num + 1, start - line_start + 1)
    if eof is not None:
        line_start = line_starts[-1]
        endpos = len(code)
        yield (eof, '', len(line_starts), endpos - line_start + 1)
    return 0


#----------------------------------------------------------------------
# patterns
#----------------------------------------------------------------------
PATTERN_WHITESPACE = r'[ \t\r\n]+'
PATTERN_COMMENT1 = r'\/\/.*'
PATTERN_COMMENT2 = r'\/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+\/'
PATTERN_NAME = r'\w+'
PATTERN_STRING1 = r"'(?:\\.|[^'\\])*'"
PATTERN_STRING2 = r'"(?:\\.|[^"\\])*"'
PATTERN_NUMBER = r'\d+(\.\d*)?'
PATTERN_CINTEGER = r'(0x)?\d+[uUlLbB]*'
PATTERN_MISMATCH = r'.'
PATTERN_PY_COMMENT = r'\#.*'
PATTERN_PY_STRING3D = r'"""(?:[^"\\]|\\.|"(?!""))*"""'
PATTERN_PY_STRING3S = r"'''(?:[^'\\]|\\.|'(?!''))*'''"
PATTERN_PY_PSTR3D = r'[bBfFrR]{1,2}"""(?:[^"\\]|\\.|"(?!""))*"""'
PATTERN_PY_PSTR3S = r"[bBfFrR]{1,2}'''(?:[^'\\]|\\.|'(?!''))*'''"
PATTERN_PY_PSTR1 = r"[bBfFrR]{1,2}'(?:\\.|[^'\\\r\n])*'"
PATTERN_PY_PSTR2 = r'[bBfFrR]{1,2}"(?:\\.|[^"\\\r\n])*"'
PATTERN_PY_STR1 = r"'(?:\\.|[^'\\\r\n])*'"
PATTERN_PY_STR2 = r'"(?:\\.|[^"\\\r\n])*"'
PATTERN_PY_MISMATCH = r'.'


#----------------------------------------------------------------------
# returns a list of (line, comment) pairs for python
#----------------------------------------------------------------------
def extract_python_comments(code):
    specs = [
        ('WHITESPACE', PATTERN_WHITESPACE),
        ('PY_COMMENT', PATTERN_PY_COMMENT),
        ('PY_STRING3D', PATTERN_PY_STRING3D),
        ('PY_STRING3S', PATTERN_PY_STRING3S),
        ('PY_PSTR3D', PATTERN_PY_PSTR3D),
        ('PY_PSTR3S', PATTERN_PY_PSTR3S),
        ('PY_PSTR1', PATTERN_PY_PSTR1),
        ('PY_PSTR2', PATTERN_PY_PSTR2),
        ('PY_STR1', PATTERN_PY_STR1),
        ('PY_STR2', PATTERN_PY_STR2),
        ('NAME', PATTERN_NAME),
        ('NUMBER', PATTERN_NUMBER),
        ('PY_MISMATCH', PATTERN_PY_MISMATCH)
    ]
    comments = {}
    for name, value, lnum, column in tokenize(code, specs):
        if name == 'PY_COMMENT':
            comment = value.strip('\r\n\t ')
            if comment.startswith('#'):
                comment = comment[1:].strip()
            if lnum not in comments:
                comments[lnum] = []
            comments[lnum].append(comment)
        elif name in ('PY_STRING3D', 'PY_STRING3S'):
            text = value[3:-3].strip('\r\n\t ')
            line = lnum
            for part in text.split('\n'):
                part = part.strip('\r\n\t ')
                if line not in comments:
                    comments[line] = []
                comments[line].append(part)
                line += 1
        elif name in ('PY_PSTR3D', 'PY_PSTR3S'):
            # prefix triple-quoted: strip prefix + quotes
            idx = value.index('"') if '"' in value[:4] else value.index("'")
            text = value[idx + 3:-3].strip('\r\n\t ')
            line = lnum
            for part in text.split('\n'):
                part = part.strip('\r\n\t ')
                if line not in comments:
                    comments[line] = []
                comments[line].append(part)
                line += 1
    output = []
    lines = list(comments.keys())
    lines.sort()
    for lnum in lines:
        comment = comments[lnum]
        text = ' '.join(comment)
        text = text.strip('\r\n\t ')
        output.append((lnum, text))
    return output


#----------------------------------------------------------------------
# returns a list of (line, comment) pairs
#----------------------------------------------------------------------
def extract_cpp_comments(code):
    specs = [
        ('WHITESPACE', PATTERN_WHITESPACE),
        ('COMMENT1', PATTERN_COMMENT1),
        ('COMMENT2', PATTERN_COMMENT2),
        ('NAME', PATTERN_NAME),
        ('STRING', PATTERN_STRING1),
        ('STRING', PATTERN_STRING2),
        ('NUMBER', PATTERN_NUMBER),
        ('CINTEGER', PATTERN_CINTEGER),
        ('MISMATCH', PATTERN_MISMATCH)
    ]
    comments = {}
    for name, value, lnum, column in tokenize(code, specs):
        if name == 'COMMENT1':
            comment = value.strip('\r\n\t ')
            if comment.startswith('//'):
                comment = comment[2:].strip()
            if lnum not in comments:
                comments[lnum] = []
            comments[lnum].append(comment)
        elif name == 'COMMENT2':
            comment = value.strip('\r\n\t ')
            if comment.startswith('/*'):
                comment = comment[2:]
            if comment.endswith('*/'):
                comment = comment[:-2]
            comment = comment.strip('\r\n\t ')
            line = lnum
            for text in comment.split('\n'):
                text = text.strip('\r\n\t ')
                if line not in comments:
                    comments[line] = []
                comments[line].append(text)
                line += 1
    output = []
    lines = list(comments.keys())
    lines.sort()
    for lnum in lines:
        comment = comments[lnum]
        text = ' '.join(comment)
        text = text.strip('\r\n\t ')
        output.append((lnum, text))
    return output


#----------------------------------------------------------------------
# code sample
#----------------------------------------------------------------------
code_sample_cpp = r'''
// My first C program
int main(void)
{
    int x = 10;
    int y = x+++3;
    printf("Hello, World !!\n");
    /* test1 */ .. /* test2 */
    return 0;
}
/* haha
test1
*/
'''


#----------------------------------------------------------------------
# sample code in python
#----------------------------------------------------------------------
code_sample_python = r'''
# My first Python program
def main():
    x = 10
    y = x + 3
    print("Hello, World !!")
    # test1
    # test2
    s = r"# not a comment"
    t = r"raw string with \""
    u = f"formatted {x}"
    return 0
"""
docstring test1
docstring test2
"""
'''

code_sample_python2 = r'''
# header comment
import os  # inline comment
r = 5  # r as variable, not raw prefix
path = r"C:\Users\test"  # raw string, \ not escape
msg = r"he said \"hello\""  # raw string with escaped quote
regex = r"\d+\.\d*"  # regex pattern
label = f"name: {name}"  # f-string
data = b"bytes here"  # byte string
doc = r"""
raw docstring line1
raw docstring line2
"""
def foo():
    """normal docstring"""
    pass
'''


#----------------------------------------------------------------------
# getopt: returns (options, args)
#----------------------------------------------------------------------
def getopt (argv, shortopts = ''):
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
            if arg in ('-', '--'):
                index += 1
                break
            if (not arg.startswith('--')) and (len(arg) == 2):
                name = arg[1]
                if (name in shortopts) and (index + 1 < count):
                    nextarg = argv[index + 1]
                    options[name] = nextarg
                    index += 2
                    continue
            name = arg.lstrip('-')
            key, _, val = name.partition('=')
            options[key.strip()] = val.strip()
        index += 1
    while index < count:
        args.append(argv[index])
        index += 1
    return options, args


#----------------------------------------------------------------------
# stripping leading/trailing whitespace and empty lines
#----------------------------------------------------------------------
def text_normalize(text):
    output = []
    firstline = True
    for line in text.rstrip('\r\n\t ').split('\n'):
        line = line.rstrip('\r\n\t ')
        line = line.lstrip('\r\n\t ')
        if firstline:
            if not line:
                continue
            firstline = False
        output.append(line)
    while len(output) > 0:
        if output[-1]:
            break
        output.pop()
    return '\n'.join(output)


#----------------------------------------------------------------------
# configure
#----------------------------------------------------------------------
class configure (object):

    def __init__ (self, ininame = None):
        t = time.time()
        self._config = {}
        self._binary = {}
        if not ininame:
            ininame = os.path.expanduser('~/.config/codecheck.ini')
        if os.path.isfile(ininame):
            self._ininame = os.path.abspath(ininame)
            self._inibase = os.path.dirname(self._ininame)
            self._config = self.load_ini(self._ininame)
        if 'default' not in self._config:
            self._config['default'] = {}
        self.win32: bool = (sys.platform[:3] == 'win') and True or False
        self.PATH: str = os.environ.get('PATH', '')
        self._locate_binary()

    # load content
    def load_file_content (self, filename, mode = 'r'):
        if hasattr(filename, 'read'):
            try: content = filename.read()
            except: content = None
            return content
        try:
            if '~' in filename:
                filename = os.path.expanduser(filename)
            fp = open(filename, mode)
            content = fp.read()
            fp.close()
        except:
            content = None
        return content

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

    # load ini without ConfigParser
    def load_ini (self, filename, encoding = None):
        text = self.load_file_text(filename, encoding)
        config = {}
        sect = 'default'
        if text is None:
            return None
        for line in text.split('\n'):
            line = line.strip('\r\n\t ')
            # pylint: disable-next=no-else-continue
            if not line:   # noqa
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

    def _locate_binary (self):
        self._locate_cc()
        self._locate_python()
        return 0

    def _locate_cc (self):
        cc = ''
        if 'cc' in self._config['default']:
            cc = self._config['default']['cc']
            cc = cc.strip('\r\n\t ')
            if '~' in cc:
                cc = os.path.expanduser(cc)
            if self.win32:
                extname = os.path.splitext(cc)[-1].lower()
                if not extname:
                    cc += '.exe'
            if os.path.isabs(cc):
                if not os.path.isfile(cc) or not os.access(cc, os.X_OK):
                    sys.stderr.write('Warning: C/C++ compiler not found at %s\n' % cc)
                    sys.stderr.write('Check your config file %s\n' % self._ininame)
                    sys.exit(1)
                    cc = ''
            else:
                PATH = os.environ.get('PATH', '')
                PATH = self._inibase + os.pathsep + PATH
                cc = shutil.which(cc, path = PATH)
        if not cc:
            for name in ('gcc', 'clang', 'cc'):
                cc = shutil.which(name)
                if cc:
                    break
        if cc:
            self._binary['cc'] = os.path.abspath(cc)
        return 0

    def _locate_python (self):
        py = ''
        if 'python' in self._config['default']:
            py = self._config['default']['python']
            py = py.strip('\r\n\t ')
            if '~' in py:
                py = os.path.expanduser(py)
            if os.path.isabs(py):
                if not os.path.isfile(py) or not os.access(py, os.X_OK):
                    py = ''
            else:
                PATH = os.environ.get('PATH', '')
                PATH = self._inibase + os.pathsep + PATH
                py = shutil.which(py, path = PATH)
        if not py:
            py = sys.executable
        if py:
            self._binary['python'] = os.path.abspath(py)
        return 0

    # read config
    def read_config (self, section, key, default = None):
        if section not in self._config:
            return default
        return self._config[section].get(key, default)

    # read config value as int
    def read_int (self, section, key, default = -1):
        val = self.read_config(section, key, None)
        if val is None:
            return default
        try:
            return int(val)
        except:
            pass
        return default

    # execute command without capture, returns exit code
    def execute (self, args, cwd = None, env = None, timeout = None, stdin = None):
        if env:
            envcopy = os.environ.copy()
            envcopy.update(env)
            env = envcopy
        if stdin:
            if isinstance(stdin, str):
                stdin = stdin.encode('utf-8', 'ignore')
        try:
            result = subprocess.run(args, cwd = cwd, env = env, 
                                    shell = False,
                                    input = stdin,
                                    timeout = timeout)
            return result.returncode
        except Exception as e:
            raise e
        return -1

    # execute command and capture output, returns (exit code, stdout, stderr)
    def capture (self, args, cwd = None, env = None, timeout = None, stdin = None):
        if env:
            envcopy = os.environ.copy()
            envcopy.update(env)
            env = envcopy
        if stdin:
            if isinstance(stdin, str):
                stdin = stdin.encode('utf-8', 'ignore')
        try:
            result = subprocess.run(args, cwd = cwd, env = env,
                                    timeout = timeout,
                                    shell = False,
                                    input = stdin,
                                    stdout = subprocess.PIPE,
                                    stderr = subprocess.PIPE)
            stdout = result.stdout.decode('utf-8', 'ignore')
            stderr = result.stderr.decode('utf-8', 'ignore')
            return (result.returncode, stdout, stderr)
        except Exception as e:
            raise e
        return (-1, '', '')

    # check source file type by extension
    def check_source_type (self, filename):
        extname = os.path.splitext(filename)[-1].lower()
        if extname in ('.c',):
            return 'c'
        elif extname in ('.cpp', '.cc', '.cxx', '.c++'):
            return 'cpp'
        elif extname in ('.py', '.pyw'):
            return 'python'
        return ''

    # extract comments from source file, 
    # returns a list of (line, comment) pairs
    def extract_comments (self, filename):
        source_type = self.check_source_type(filename)
        if not source_type:
            return None
        content = self.load_file_text(filename)
        if content is None:
            return None
        if source_type in ('c', 'cpp'):
            return extract_cpp_comments(content)
        elif source_type == 'python':
            return extract_python_comments(content)
        return None

    def gcc (self, args, cwd = None, timeout = None):
        if 'cc' not in self._binary:
            sys.stderr.write('C/C++ compiler not found\n')
            sys.exit(1)
        cc = self._binary['cc']
        dirname = os.path.dirname(os.path.abspath(cc))
        cmd = [self._binary['cc']] + args
        env = {}
        env['PATH'] = dirname + os.pathsep + os.environ.get('PATH', '')
        # print('cc:', cmd)
        return self.execute(cmd, cwd = cwd, env = env, timeout = timeout)

    def toolchain_path (self):
        PATH = os.environ.get('PATH', '')
        cc = self._binary.get('cc', '')
        if not cc:
            return PATH
        dirname = os.path.dirname(os.path.abspath(cc))
        return dirname + os.pathsep + PATH

    # set terminal color
    def console (self, color):
        if sys.platform[:3] != 'win':
            if color >= 0:
                foreground = color & 7
                background = (color >> 4) & 7
                bold = color & 8
                if background != 0:
                    sys.stdout.write("\033[%s3%d;4%dm"%(bold and "01;" or "", foreground, background))
                else:
                    sys.stdout.write("\033[%s3%dm"%(bold and "01;" or "", foreground))
                sys.stdout.flush()
            else:
                sys.stdout.write("\033[0m")
                sys.stdout.flush()
            return 0
        if '_console_handle' not in self.__dict__:
            import ctypes
            self.kernel32 = ctypes.windll.LoadLibrary('kernel32.dll')
            GetStdHandle = self.kernel32.GetStdHandle
            SetConsoleTextAttribute = self.kernel32.SetConsoleTextAttribute
            GetStdHandle.argtypes = [ ctypes.c_uint32 ]
            GetStdHandle.restype = ctypes.c_size_t
            SetConsoleTextAttribute.argtypes = [ ctypes.c_size_t, ctypes.c_uint16 ]
            SetConsoleTextAttribute.restype = ctypes.c_long
            self._console_handle = GetStdHandle(0xfffffff5)
            self.SetConsoleTextAttribute = SetConsoleTextAttribute
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
        self.SetConsoleTextAttribute(self._console_handle, result)
        return 0

    def echo (self, color, *args):
        self.console(color)
        print(*args)
        self.console(-1)
        return 0


#----------------------------------------------------------------------
# TERMINAL COLOR CONSTANTS
#----------------------------------------------------------------------
COLOR_BLACK         = 0
COLOR_RED           = 1
COLOR_GREEN         = 2
COLOR_YELLOW        = 3
COLOR_BLUE          = 4
COLOR_MAGENTA       = 5
COLOR_CYAN          = 6
COLOR_WHITE         = 7
COLOR_BOLD          = 8
COLOR_BOLD_RED      = 9
COLOR_BOLD_GREEN    = 10
COLOR_BOLD_YELLO    = 11
COLOR_BOLD_BLUE     = 12
COLOR_BOLD_MAGENTA  = 13
COLOR_BOLD_CYAN     = 14
COLOR_BOLD_WHITE    = 15


#----------------------------------------------------------------------
# color constants for codecheck
#----------------------------------------------------------------------
CC_NOTICE = COLOR_BOLD_YELLO
CC_INFO = COLOR_WHITE
CC_UNIT = COLOR_BOLD_CYAN
CC_GOOD = COLOR_BOLD_GREEN
CC_BAD = COLOR_BOLD_RED
CC_HIGHLIGHT = COLOR_BOLD_WHITE
CC_GRAY = COLOR_BOLD


#----------------------------------------------------------------------
# foundation class
#----------------------------------------------------------------------
class foundation (object):

    def __init__ (self, srcname):
        self.config: configure = configure()
        self.win32: bool = self.config.win32
        if '~' in srcname:
            srcname = os.path.expanduser(srcname)
        self.srcname = os.path.abspath(srcname)
        self.dirname = os.path.dirname(self.srcname)
        self.exename = os.path.splitext(self.srcname)[0]
        if self.win32:
            self.exename += '.exe'
        self.srctype = self.config.check_source_type(srcname)
        if self.srctype not in ('c', 'cpp', 'python'):
            raise ValueError('Unsupported source type: %s' % self.srctype)
        self.comments = self.config.extract_comments(srcname)
        self.compiled = False
        self._check_requirement()

    def _check_requirement (self):
        if self.srctype in ('c', 'cpp'):
            if 'cc' not in self.config._binary:
                raise ValueError('C/C++ compiler not found')
        elif self.srctype == 'python':
            if 'python' not in self.config._binary:
                raise ValueError('Python interpreter not found')
        return 0

    def echo (self, color, *args):
        self.config.echo(color, *args)
        return 0

    def compile (self):
        if 'cc' not in self.config._binary:
            raise ValueError('C/C++ compiler not found')
        if self.srctype not in ('c', 'cpp'):
            raise ValueError('Source type is not C/C++')
        args = [self.srcname, '-o', self.exename]
        if self.srctype == 'cpp':
            cc = self.config._binary['cc']
            if '++' not in cc:
                if 'gcc' in cc:
                    args.append('-lstdc++')
                elif 'clang' in cc:
                    args.append('-lc++')
        args.insert(0, '-D_CODECHECK=1')
        flags = []
        for name in ('flags', 'cflags', 'cxxflags', 'ldflags'):
            if name not in self.config._config['default']:
                continue
            value = self.config._config['default'].get(name, '')
            value = value.strip('\r\n\t ')
            if not value:
                continue
            if name in ('flags', 'ldflags'):
                flags.append(value)
            elif name == 'cflags' and self.srctype == 'c':
                flags.append(value)
            elif name == 'cxxflags' and self.srctype == 'cpp':
                flags.append(value)
        text = ' '.join(flags)
        text = text.strip('\r\n\t ')
        if text:
            args += shlex.split(text)
            args.append('-lm')
        else:
            args = ['-O2', '-g', '-Wall'] + args + ['-lm']
        cwd = os.path.dirname(self.srcname)
        retcode = self.config.gcc(args, cwd = cwd)
        if retcode != 0:
            raise RuntimeError('Compilation failed with code %d' % retcode)
        return True

    def ensure_executable (self, force = False):
        if self.srctype not in ('c', 'cpp'):
            return True
        if os.path.exists(self.exename):
            ftime = os.path.getmtime(self.exename)
            stime = os.path.getmtime(self.srcname)
            if ftime >= stime and (not force):
                return True
            try:
                os.remove(self.exename)
            except Exception as e:
                self.echo(CC_BAD, 'Error removing old executable: %s' % str(e))
                return False
        self.echo(CC_NOTICE, 'Compiling %s ...' % os.path.split(self.srcname)[-1])
        try:
            hr = self.compile()
        except Exception as e:
            hr = False
            self.echo(CC_BAD, 'ERROR: ' + str(e))
        if not hr:
            return False
        self.compiled = True
        return True

    # start the program, returns (exit code, stdout, stderr)
    def start (self, capture = False, stdin = None, timeout = None, argv = None):
        cwd = self.dirname
        env = None
        args = []
        if self.srctype in ('c', 'cpp'):
            env = {}
            env['PATH'] = self.config.toolchain_path()
            exename = os.path.split(self.exename)[-1]
            if self.win32:
                args.append(self.exename)
            else:
                args.append(self.exename)
        elif self.srctype == 'python':
            args.append(self.config._binary['python'])
            args.append(self.srcname)
        else:
            return (-1, '', '')
        if argv:
            args += argv
        if not capture:
            if not stdin:
                code = self.config.execute(args, cwd, env, timeout)
                return (code, '', '')
            else:
                code = self.config.execute(args, cwd, env, timeout, stdin)
                return (code, '', '')
        hr = self.config.capture(args, cwd, env, timeout, stdin)
        code, stdout, stderr = hr
        return (code, stdout, stderr)

    def launch (self, capture = False, stdin = None, timeout = None, args = None):
        if not self.ensure_executable():
            return False
        if not capture:
            if self.compiled:
                self.echo(CC_NOTICE, 'Running %s ...' % os.path.split(self.exename)[-1])
        try:
            hr = self.start(capture, stdin, timeout, args)
        except FileNotFoundError as e:
            self.echo(CC_BAD, 'ERROR: Executable not found: %s' % str(e))
            return (-2, '', '')
        except subprocess.TimeoutExpired as e:
            self.echo(CC_BAD, 'ERROR: Timeout expired after %d seconds' % e.timeout)
            return (-3, '', '')
        except KeyboardInterrupt as e:
            self.echo(CC_BAD, 'ERROR: Execution interrupted by user')
            return (-4, '', '')
        except Exception as e:
            hr = (-1, '', '')
            self.echo(CC_BAD, 'ERROR: ' + str(e))
            raise e
        return hr


#----------------------------------------------------------------------
# unit test class
#----------------------------------------------------------------------
class UnitTest (object):
    def __init__ (self, name: str):
        self.name: str = name
        self.stdin: str = ''
        self.stdout: str = ''
        self.opts = None
    def check (self, output):
        output = text_normalize(output)
        expect = text_normalize(self.stdout)
        return output == expect
    def __repr__ (self):
        return '<UnitTest name=%s>' % self.name
    def print (self):
        print('<UnitTest: %s>' % self.name)
        print('Input:')
        print(self.stdin)
        print('Output:')
        print(self.stdout)
        if self.opts:
            print('Options:')
            for k, v in self.opts.items():
                print('  %s = %s' % (k, v))
        return 0


#----------------------------------------------------------------------
# comment parser
#----------------------------------------------------------------------
class CommentParser (object):

    def __init__ (self):
        self.units = []
        self.pattern1 = re.compile(r'^\s*@\s*input\s*(:.*)?$', re.IGNORECASE)
        self.pattern2 = re.compile(r'^\s*@\s*output\s*(:.*)?$', re.IGNORECASE)
        self.pattern3 = re.compile(r'^\s*@\s*args\s*(:.*)?$', re.IGNORECASE)
        self.pattern4 = re.compile(r'^\s*@\s*timeout\s*(:.*)?$', re.IGNORECASE)
        self.reset()

    def reset (self):
        self.units = []
        self.name = ''
        self.input = []
        self.output = []
        self.opts = None
        self.args = []
        self.state = 0
        self.index = 0
        self.next = 0
        self.timeout = None

    def process (self, comments):
        self.reset()
        for lnum, comment in comments:
            text = comment.rstrip('\r\n\t ')
            test = text.lstrip('#*\r\n\t ')
            head = self._check_input(test)
            if head is not None:
                self._unit_start(head[0], head[1])
                self.next = lnum + 1
                continue
            if self._check_output(test):
                self.state = 2
                self.next = lnum + 1
                continue
            args = self._check_args(test)
            if args is not None:
                self.args = args
                continue
            if self._check_timeout(test):
                continue
            if self.state == 1:
                if lnum == self.next:
                    self.next += 1
                    self.input.append(text)
                else:
                    self.state = 0
            elif self.state == 2:
                if lnum == self.next:
                    self.next += 1
                    self.output.append(text)
                else:
                    self.state = 0
        self._unit_end()
        return 0

    # start of a unit
    def _unit_start (self, name, opts):
        self._unit_end()
        self.index += 1
        if not name:
            name = 'test%d' % self.index
        self.name = name
        self.input = []
        self.output = []
        self.opts = opts
        self.state = 1
        return 0

    # end of unit
    def _unit_end (self):
        if self.name != '':
            unit = UnitTest(self.name)
            unit.stdin = '\n'.join(self.input)
            unit.stdout = '\n'.join(self.output)
            unit.opts = self.opts
            self.units.append(unit)
            self.name = ''
            self.input = []
            self.output = []
            self.opts = None
        return 0

    def _check_timeout (self, text):
        head = text.strip('#*\r\n\t ')
        if not head.startswith('@'):
            return False
        m = self.pattern4.match(head)
        if not m:
            return False
        meta = m.group(1)
        if meta:
            meta = meta.strip('\r\n\t ')
            if meta.startswith(':'):
                meta = meta[1:].strip('\r\n\t ')
            try:
                self.timeout = int(meta)
            except:
                pass
        return True

    def _check_args (self, text):
        head = text.strip('#*\r\n\t ')
        if not head.startswith('@'):
            return None
        if head == '@args':
            return []
        m = self.pattern3.match(head)
        if not m:
            return None
        meta = m.group(1)
        args = []
        if meta:
            meta = meta.strip('\r\n\t ')
            if meta.startswith(':'):
                meta = meta[1:].strip('\r\n\t ')
            args = shlex.split(meta)
        return args

    # returns (name, opts)
    def _check_input (self, text):
        head = text.strip('#*\r\n\t ')
        if not head.startswith('@'):
            return None
        if head == '@input':
            return ('', None)
        m = self.pattern1.match(head)
        if not m:
            return None
        meta = m.group(1)
        name = ''
        opts = {}
        if meta:
            meta = meta.strip(':\r\n\t ')
            part = meta.split(' ')
            for n in part:
                t = n.strip('\r\n\t ')
                if not t:
                    continue
                if '=' not in t:
                    if not name:
                        name = t
                else:
                    k, _, v = t.partition('=')
                    k = k.strip('\r\n\t ')
                    if k:
                        opts[k] = v.strip('\r\n\t ')
            return (name, opts and opts or None)
        return ('', None)

    # check if the comment is an output directive
    def _check_output (self, text):
        head = text.strip('#*\r\n\t ')
        if not head.startswith('@'):
            return False
        if head == '@output':
            return True
        m = self.pattern2.match(head)
        if m:
            return True
        return False


#----------------------------------------------------------------------
# code sample
#----------------------------------------------------------------------
sample_cpp_code_1 = r'''
#include <stdio.h>
// @input:
// 10 20
// @output:
// 30

// not an output line, because it is not consequtive
int main() {
    int a, b;
    // add two numbers
    scanf("%d%d", &a, &b);
    printf("%d\n", a + b);
    return 0;
}
/*
@input: haha
5 7

@output:
12

@input:
9 2
*/

/**/
/*
*/
'''


#----------------------------------------------------------------------
# check code
#----------------------------------------------------------------------
class CodeCheck (object):

    def __init__ (self, srcname):
        self.foundation: foundation = foundation(srcname)
        self.config: configure = self.foundation.config
        self.parser: CommentParser = CommentParser()
        self.units = []
        self._parse_comment()
        self._default_settings()

    def _default_settings (self):
        config = self.config
        if 'timeout' not in config._config['default']:
            config._config['default']['timeout'] = '10'
        return 0

    def _parse_comment (self):
        comments = self.config.extract_comments(self.foundation.srcname)
        if not comments:
            return -1
        self.parser.process(comments)
        index = 1
        for unit in self.parser.units:
            unit.index = index
            self.units.append(unit)
            index += 1
            # unit.print()
        return 0

    # call launch in foundation
    def _launch (self, capture, stdin, timeout, args = None):
        hr = self.foundation.launch(capture, stdin, timeout, args)
        return hr

    def color (self, color):
        self.config.console(color)

    def echo (self, color, *args):
        self.config.echo(color, *args)

    # start without capture, returns exit code
    def start (self):
        if not self.foundation.ensure_executable():
            return 1
        r = self._launch(False, None, None)
        if not r:
            return 2
        return 0

    # start with args
    def run_args (self):
        if not self.foundation.ensure_executable():
            return 1
        args = None
        if self.parser.args:
            args = self.parser.args
        r = self._launch(False, None, None, args)
        return 0

    # start a unit test by index (1-based) without compare output
    def debug (self, index = None):
        if not self.foundation.ensure_executable():
            return 1
        if len(self.units) == 0:
            self.echo(CC_NOTICE, 'No unit tests found in comments, start without debug ...')
            self.start()
            return 0
        if not index:
            unit = self.units[0]
        else:
            idx = int(index) - 1
            if idx < 0 or idx >= len(self.units):
                self.echo(CC_BAD, 'Invalid unit test index: %s' % index)
                return 1
            unit = self.units[idx]
        timeout = None
        if unit.opts and 'timeout' in unit.opts:
            try:
                timeout = int(unit.opts['timeout'])
            except:
                pass
        hr = self._launch(False, unit.stdin, timeout)
        return 0

    # check each unit test, returns a list of (unit, result) pairs
    def check (self, enabled = None):
        if not self.foundation.ensure_executable():
            return 1
        if len(self.units) == 0:
            self.echo(CC_NOTICE, 'No unit tests found in comments.')
            return 0
        passed = 0
        _timeout = self.config.read_int('default', 'timeout', 10)
        if _timeout < 0:
            _timeout = None
        for unit in self.units:
            if enabled and unit.index not in enabled:
                continue
            timeout = _timeout
            if unit.opts and 'timeout' in unit.opts:
                try:
                    timeout = int(unit.opts['timeout'])
                except:
                    pass
            self.color(CC_UNIT)
            sys.stdout.write('[%d/%d] Running unit test: %s ... ' % 
                             (unit.index, len(self.units), unit.name))
            self.color(-1)
            sys.stdout.flush()
            hr = self._launch(True, unit.stdin, timeout)
            code, stdout, stderr = hr
            if code < 0:
                break
            expect = text_normalize(unit.stdout)
            output = text_normalize(stdout)
            if output == expect:
                self.echo(CC_GOOD, 'PASS')
                passed += 1
            else:
                self.echo(CC_BAD, 'FAIL')
                self.echo(CC_HIGHLIGHT, 'Expected output:')
                self.echo(COLOR_WHITE, expect)
                self.echo(CC_HIGHLIGHT, 'Actual output:')
                self.echo(COLOR_WHITE, stdout)
                log = stderr.rstrip('\r\n\t ')
                if log:
                    self.echo(CC_HIGHLIGHT, 'Error output:')
                    self.echo(CC_GRAY, log)
                break
        required = len(self.units)
        if enabled:
            required = len(enabled)
        if passed == required:
            self.echo(CC_NOTICE, '[result] All %d unit tests passed!' % passed)
        else:
            self.echo(CC_BAD, '[result] %d/%d unit tests passed.' % (passed, required))
        return 0


#----------------------------------------------------------------------
# show message
#----------------------------------------------------------------------
def help():
    fn = os.path.basename(sys.argv[0])
    print('Usage: python %s [options] <source-file>' % fn)
    print('options:')
    print('  -h, --help     show this help message and exit')
    print('  -c, --check    run embedded unit tests and verify output')
    print('  -d, --debug    run a test case without comparing output')
    print('  -a, --args     run with command-line arguments from @args directive')
    print('  -{num}         select a specific test case by index (1-based, use with -c/-d)')
    return 0


#----------------------------------------------------------------------
# main function
#----------------------------------------------------------------------
def main(argv = None):
    argv = argv if argv is not None else sys.argv[1:]
    args = [n for n in argv]
    options, args = getopt(args)
    enabled = {}
    for k in options.keys():
        if k.isdigit():
            index = int(k)
            enabled[index] = True
    if 'h' in options or 'help' in options:
        return help()
    if len(args) == 0:
        print('Error: No source file specified, use -h for help.')
        return 1
    srcname = args[0]
    if not os.path.exists(srcname):
        print('Error: Source file not found: %s' % srcname)
        return 1
    cc = CodeCheck(srcname)
    if 'c' in options or 'check' in options:
        return cc.check(enabled and enabled or None)
    elif 'd' in options or 'debug' in options:
        keys = list(enabled.keys())
        keys.sort()
        first = None
        if keys:
            first = keys[0]
        return cc.debug(first)
    elif 'a' in options or 'args' in options:
        cc.run_args()
    else:
        cc.start()
    return 0


#----------------------------------------------------------------------
# testing suit
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        for line, comment in extract_cpp_comments(code_sample_cpp):
            print('Line %d: %s' % (line, comment))
        return 0
    def test2():
        for line, comment in extract_python_comments(code_sample_python):
            print('Line %d: %s' % (line, comment))
        return 0
    def test3():
        for line, comment in extract_python_comments(code_sample_python2):
            print('Line %d: %s' % (line, comment))
        return 0
    def test4():
        cfg = configure()
        print(cfg._binary)
        print(cfg.call(['python', '-c', 'print("hello", input())'], stdin = 'world'))
        return 0
    def test5():
        f = foundation('e:/lab/workshop/scratch/cpp/noi01.c')
        print(f.exename)
        print(f.dirname)
        # f.config.gcc(['--version'])
        f.ensure_executable(True)
        f.launch(capture = False, timeout = 3, stdin = '10 20')
    def test6():
        cp = CommentParser()
        test_strings = [
            "@input",
            "@ input",
            "@  input  ",
            "@input:",
            "@ input :",
            "@  input  :",
            "@  input : sdf adf ",
            "  @ input : test1  k1=v1  k2=v2  k3=v3  ",
            "  @ input ",
            "  @ input",
            '@input:t1',
            "not matching",
            "@output",
            "  @ output  : ",
        ]
        for test in test_strings:
            print(cp._check_input(test))
        print('--')
        for test in test_strings:
            print(cp._check_output(test))
    def test7():
        parser = CommentParser()
        comments = extract_cpp_comments(sample_cpp_code_1)
        parser.process(comments)
        for unit in parser.units:
            print('Unit: %s' % unit.name)
            print('Input:\n%s' % unit.stdin)
            print('Output:\n%s' % unit.stdout)
            print('Opts: %s' % str(unit.opts))
            print('---')
    def test8():
        cc = CodeCheck('e:/lab/workshop/scratch/cpp/noi01.c')
        cc.debug()
        return 0
    def test9():
        f = 'e:/lab/workshop/scratch/cpp/noi01.cpp'
        args = [f]
        args = ['-c', f]
        # args = ['-c', '-1', '-2', f]
        # args = ['-d', f]
        main(args)
        return 0
    def test0():
        f = 'e:/lab/workshop/autumn/script/child.py'
        args = [f]
        args = ['-a', f]
        # args = [f]
        main(args)
        return 0
    # test9()
    main()


