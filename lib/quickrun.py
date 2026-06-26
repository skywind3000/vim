#! /usr/bin/env python3
# -*- coding: utf-8 -*-
#======================================================================
#
# quickrun.py - Extract @command directives from source comments and
#               execute predefined build/run commands
#
# Description:
#   This tool scans source files for embedded @command directives in
#   comments, parses them into named commands, and executes the one
#   requested on the command line — letting build/run/test recipes
#   live alongside the code itself, with no Makefile or extra script
#   required.
#
#   Supported source types (by extension):
#     .c/.cc/.cxx/.cpp/.h/.hpp/.hh/.cs/.java/.js/.ts/.as/.go  -> C-style
#     .rs                                                      -> Rust (C-style)
#     .pas/.pp/.dpr/.lpr                                       -> Pascal
#     .php/.phtml                                              -> PHP
#     .pl/.pm                                                  -> Perl
#     .sh/.bash                                                -> Shell/Bash
#     .lua                                                     -> Lua
#     .hs                                                      -> Haskell
#     .erl/.hrl                                                -> Erlang
#     .ps1/.psm1                                               -> PowerShell
#     .py                                                      -> Python
#   Comment styles recognized per language:
#     C-style/Rust/PHP : // line, /* */ block  (PHP also has # line)
#     Pascal           : { } block, (* *) block, // line
#     Perl/Bash        : # line
#     Lua              : -- line, --[[ ]] block
#     Haskell          : -- line, {- -} block
#     Erlang           : % line
#     PowerShell       : # line, <# #> block
#     Python           : # line
#   String literals are tokenized so comment markers inside them are
#   ignored. Triple-quoted Python strings are NOT scanned for @command
#   directives. Nested block comments (Haskell, Rust) are not handled.
#
# Command directive syntax in comments:
#   // @command(name): <shell command>
#   // @command(name/target): <shell command>   # target-only command
#   A directive whose /target differs from the current target is
#   skipped, so the same source can carry platform-specific recipes.
#
# Available variables (written exactly as shown, replaced before run):
#   $(FILENAME)   - source file name with extension
#   $(FILEPATH)   - absolute path of the source file
#   $(FILEDIR)    - absolute directory of the source file
#   $(FILEEXT)    - source extension, lowercased
#   $(FILENOEXT)  - source file name without extension
#   $(PATHNOEXT)  - absolute source path without extension
#   $(ROOT)       - project root directory (detected upward by markers)
#   $(DIRNAME)    - name of the directory containing the source file
#   $(PRONAME)    - name of the project root directory
#   $(TARGET)     - current target platform (default sys.platform, -t to override)
#
# Project root detection:
#   Walks upward from the source directory looking for marker files/
#   dirs (.git, .svn, .hg, .project, .root by default). Override the
#   marker set via the QUICKRUN_MARKERS env var (comma-separated,
#   glob patterns supported). Falls back to the source directory.
#
# Usage examples:
#   quickrun.py hello.cpp            # list available commands
#   quickrun.py hello.cpp build      # run the "build" command
#   quickrun.py hello.cpp run        # run the "run" command
#   quickrun.py -t linux hello.cpp clean   # run "clean" as on linux
#   quickrun.py -l hello.cpp         # list commands explicitly
#   quickrun.py -h                   # show help
#
# Embedding commands in C/C++ source:
#   // @command(build): g++ $(FILENAME) -o $(FILENOEXT)
#   // @command(run): ./$(FILENOEXT)
#   // @command(clean/linux): rm -f $(FILENOEXT)
#   // @command(clean/win32): del /q $(FILENOEXT).exe
#
# Embedding commands in Python source:
#   # @command(run): python $(FILENAME)
#   # @command(test): python -m pytest $(FILEDIR)
#
# Behavior:
#   - Commands run via subprocess.run(..., shell=True) in the source
#     file's directory; the program exit code equals the command's.
#   - If the requested command is not defined, exit code is 1.
#
# Created by skywind on 2026/06/26
# Last Modified: 2026/06/26 14:38:46
#
#======================================================================
import sys
import os
import re
import subprocess
import pprint


#----------------------------------------------------------------------
# version
#----------------------------------------------------------------------
VERSION = '0.0.1'


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

# reusable line-comment markers (match to end of line, excluding newlines)
PATTERN_LINE_DASH2    = r'--[^\r\n]*'             # -- line (lua, haskell)
PATTERN_LINE_PERCENT  = r'%[^\r\n]*'              # % line (erlang)
# reusable block-comment markers (may span lines via [\s\S])
PATTERN_BLOCK_BRACE   = r'\{[^}]*\}'              # Pascal { }
PATTERN_BLOCK_PSTAR   = r'\(\*[\s\S]*?\*\)'       # Pascal (* *)
PATTERN_BLOCK_LUA     = r'--\[\[[\s\S]*?\]\]'     # Lua --[[ ]]
PATTERN_BLOCK_HASKELL = r'\{-[\s\S]*?-\}'         # Haskell {- -}
PATTERN_BLOCK_PWSH    = r'<#[\s\S]*?#>'           # PowerShell <# #>
PATTERN_LUA_LONGSTR   = r'\[\[[\s\S]*?\]\]'       # Lua [[ ]] long string (skip)


#----------------------------------------------------------------------
# generic comment extractor: tokenize once, dispatch each comment
# token to a handler that returns its text as a list of source lines.
#----------------------------------------------------------------------
def _line_comment_handler (mark):
    # handler for a single-line comment: strip the leading marker and
    # return a one-element list; the collector attributes it to the
    # token's start line.
    def handler (value):
        text = value
        if text.startswith(mark):
            text = text[len(mark):]
        return [text]
    return handler

def _block_comment_handler (start, end):
    # handler for a block comment: strip the start/end delimiters, trim
    # surrounding whitespace, and split into per-source-line parts. the
    # matched text may span several lines.
    def handler (value):
        text = value
        if text.startswith(start):
            text = text[len(start):]
        if text.endswith(end):
            text = text[:-len(end)]
        text = text.strip('\r\n\t ')
        return text.split('\n')
    return handler

def _collect_comments (code, specs, handlers):
    # tokenize `code` with `specs`; for each token whose name is a key
    # in `handlers`, call the handler to obtain comment text lines and
    # merge them into a per-line dict (multiple comments on one line
    # are joined with a space). returns sorted (line, text) pairs.
    comments = {}
    for name, value, lnum, column in tokenize(code, specs):
        handler = handlers.get(name)
        if handler is None:
            continue
        line = lnum
        for part in handler(value):
            part = part.strip('\r\n\t ')
            if line not in comments:
                comments[line] = []
            comments[line].append(part)
            line += 1
    output = []
    for lnum in sorted(comments.keys()):
        text = ' '.join(comments[lnum]).strip('\r\n\t ')
        output.append((lnum, text))
    return output


#----------------------------------------------------------------------
# returns a list of (line, comment) pairs for python
#----------------------------------------------------------------------
def extract_python_comments (code):
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
        ('PY_MISMATCH', PATTERN_PY_MISMATCH),
    ]
    handlers = {'PY_COMMENT': _line_comment_handler('#')}
    return _collect_comments(code, specs, handlers)


#----------------------------------------------------------------------
# returns a list of (line, comment) pairs
#----------------------------------------------------------------------
def extract_cpp_comments (code):
    specs = [
        ('WHITESPACE', PATTERN_WHITESPACE),
        ('COMMENT1', PATTERN_COMMENT1),       # // line
        ('COMMENT2', PATTERN_COMMENT2),       # /* */ block
        ('STRING', PATTERN_STRING1),
        ('STRING', PATTERN_STRING2),
        ('NAME', PATTERN_NAME),
        ('NUMBER', PATTERN_NUMBER),
        ('MISMATCH', PATTERN_MISMATCH),
    ]
    handlers = {
        'COMMENT1': _line_comment_handler('//'),
        'COMMENT2': _block_comment_handler('/*', '*/'),
    }
    return _collect_comments(code, specs, handlers)


#----------------------------------------------------------------------
# pascal: { } and (* *) block comments, // line comments
#----------------------------------------------------------------------
def extract_pascal_comments (code):
    specs = [
        ('WHITESPACE', PATTERN_WHITESPACE),
        ('BLOCK_BRACE', PATTERN_BLOCK_BRACE),
        ('BLOCK_PSTAR', PATTERN_BLOCK_PSTAR),
        ('COMMENT1', PATTERN_COMMENT1),
        ('STRING', PATTERN_STRING1),
        ('STRING', PATTERN_STRING2),
        ('NAME', PATTERN_NAME),
        ('NUMBER', PATTERN_NUMBER),
        ('MISMATCH', PATTERN_MISMATCH),
    ]
    handlers = {
        'BLOCK_BRACE': _block_comment_handler('{', '}'),
        'BLOCK_PSTAR': _block_comment_handler('(*', '*)'),
        'COMMENT1': _line_comment_handler('//'),
    }
    return _collect_comments(code, specs, handlers)


#----------------------------------------------------------------------
# php: // and # line comments, /* */ block comments
#----------------------------------------------------------------------
def extract_php_comments (code):
    specs = [
        ('WHITESPACE', PATTERN_WHITESPACE),
        ('COMMENT2', PATTERN_COMMENT2),       # /* */ block
        ('COMMENT1', PATTERN_COMMENT1),       # // line
        ('HASH', PATTERN_PY_COMMENT),         # # line
        ('STRING', PATTERN_STRING1),
        ('STRING', PATTERN_STRING2),
        ('NAME', PATTERN_NAME),
        ('NUMBER', PATTERN_NUMBER),
        ('MISMATCH', PATTERN_MISMATCH),
    ]
    handlers = {
        'COMMENT2': _block_comment_handler('/*', '*/'),
        'COMMENT1': _line_comment_handler('//'),
        'HASH': _line_comment_handler('#'),
    }
    return _collect_comments(code, specs, handlers)


#----------------------------------------------------------------------
# perl: # line comments (POD blocks are not extracted)
#----------------------------------------------------------------------
def extract_perl_comments (code):
    specs = [
        ('WHITESPACE', PATTERN_WHITESPACE),
        ('HASH', PATTERN_PY_COMMENT),
        ('STRING', PATTERN_STRING1),
        ('STRING', PATTERN_STRING2),
        ('NAME', PATTERN_NAME),
        ('NUMBER', PATTERN_NUMBER),
        ('MISMATCH', PATTERN_MISMATCH),
    ]
    handlers = {'HASH': _line_comment_handler('#')}
    return _collect_comments(code, specs, handlers)


#----------------------------------------------------------------------
# bash/shell: # line comments
#----------------------------------------------------------------------
def extract_bash_comments (code):
    specs = [
        ('WHITESPACE', PATTERN_WHITESPACE),
        ('HASH', PATTERN_PY_COMMENT),
        ('STRING', PATTERN_STRING1),
        ('STRING', PATTERN_STRING2),
        ('NAME', PATTERN_NAME),
        ('NUMBER', PATTERN_NUMBER),
        ('MISMATCH', PATTERN_MISMATCH),
    ]
    handlers = {'HASH': _line_comment_handler('#')}
    return _collect_comments(code, specs, handlers)


#----------------------------------------------------------------------
# lua: -- line comments and --[[ ]] block comments
#----------------------------------------------------------------------
def extract_lua_comments (code):
    specs = [
        ('WHITESPACE', PATTERN_WHITESPACE),
        ('BLOCK_LUA', PATTERN_BLOCK_LUA),       # --[[ ]] (before -- line)
        ('LUA_LONGSTR', PATTERN_LUA_LONGSTR),   # [[ ]] long string (skip)
        ('LINE_DASH2', PATTERN_LINE_DASH2),     # --
        ('STRING', PATTERN_STRING1),
        ('STRING', PATTERN_STRING2),
        ('NAME', PATTERN_NAME),
        ('NUMBER', PATTERN_NUMBER),
        ('MISMATCH', PATTERN_MISMATCH),
    ]
    handlers = {
        'BLOCK_LUA': _block_comment_handler('--[[', ']]'),
        'LINE_DASH2': _line_comment_handler('--'),
    }
    return _collect_comments(code, specs, handlers)


#----------------------------------------------------------------------
# haskell: -- line comments and {- -} block comments
#----------------------------------------------------------------------
def extract_haskell_comments (code):
    specs = [
        ('WHITESPACE', PATTERN_WHITESPACE),
        ('BLOCK_HASKELL', PATTERN_BLOCK_HASKELL),  # {- -} (before -- line)
        ('LINE_DASH2', PATTERN_LINE_DASH2),        # --
        ('STRING', PATTERN_STRING1),
        ('STRING', PATTERN_STRING2),
        ('NAME', PATTERN_NAME),
        ('NUMBER', PATTERN_NUMBER),
        ('MISMATCH', PATTERN_MISMATCH),
    ]
    handlers = {
        'BLOCK_HASKELL': _block_comment_handler('{-', '-}'),
        'LINE_DASH2': _line_comment_handler('--'),
    }
    return _collect_comments(code, specs, handlers)


#----------------------------------------------------------------------
# erlang: % line comments
#----------------------------------------------------------------------
def extract_erlang_comments (code):
    specs = [
        ('WHITESPACE', PATTERN_WHITESPACE),
        ('LINE_PERCENT', PATTERN_LINE_PERCENT),
        ('STRING', PATTERN_STRING1),
        ('STRING', PATTERN_STRING2),
        ('NAME', PATTERN_NAME),
        ('NUMBER', PATTERN_NUMBER),
        ('MISMATCH', PATTERN_MISMATCH),
    ]
    handlers = {'LINE_PERCENT': _line_comment_handler('%')}
    return _collect_comments(code, specs, handlers)


#----------------------------------------------------------------------
# powershell: # line comments and <# #> block comments
#----------------------------------------------------------------------
def extract_powershell_comments (code):
    specs = [
        ('WHITESPACE', PATTERN_WHITESPACE),
        ('BLOCK_PWSH', PATTERN_BLOCK_PWSH),       # <# #>
        ('HASH', PATTERN_PY_COMMENT),             # # line
        ('STRING', PATTERN_STRING1),
        ('STRING', PATTERN_STRING2),
        ('NAME', PATTERN_NAME),
        ('NUMBER', PATTERN_NUMBER),
        ('MISMATCH', PATTERN_MISMATCH),
    ]
    handlers = {
        'BLOCK_PWSH': _block_comment_handler('<#', '#>'),
        'HASH': _line_comment_handler('#'),
    }
    return _collect_comments(code, specs, handlers)


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
            line = ''.join([ gettext(y, x) for x in range(maxcol) ])
            output.append(line)
    elif style == 1:
        if rows:
            newrows = rows[:1]
            head = [ '-' * colsize[i] for i in range(maxcol) ]
            newrows.append(head)
            newrows.extend(rows[1:])
            rows = newrows
        for y, row in enumerate(rows):
            line = ''.join([ gettext(y, x) for x in range(maxcol) ])
            output.append(line)
    elif style == 2:
        sep = '+'.join([ '-' * (colsize[x] + 2) for x in range(maxcol) ])
        sep = '+' + sep + '+'
        for y, row in enumerate(rows):
            output.append(sep)
            line = '|'.join([ gettext(y, x) for x in range(maxcol) ])
            output.append('|' + line + '|')
        output.append(sep)
    return '\n'.join(output)


#----------------------------------------------------------------------
# source extractors
#----------------------------------------------------------------------
EXTRACTORS = {
    '.c': extract_cpp_comments,
    '.cc': extract_cpp_comments,
    '.cxx': extract_cpp_comments,
    '.cpp': extract_cpp_comments,
    '.h': extract_cpp_comments,
    '.hpp': extract_cpp_comments,
    '.hh': extract_cpp_comments,
    '.cs': extract_cpp_comments,
    '.java': extract_cpp_comments,
    '.js': extract_cpp_comments,
    '.ts': extract_cpp_comments,
    '.as': extract_cpp_comments,
    '.go': extract_cpp_comments,
    '.rs': extract_cpp_comments,
    '.pas': extract_pascal_comments,
    '.pp': extract_pascal_comments,
    '.dpr': extract_pascal_comments,
    '.lpr': extract_pascal_comments,
    '.php': extract_php_comments,
    '.phtml': extract_php_comments,
    '.pl': extract_perl_comments,
    '.pm': extract_perl_comments,
    '.sh': extract_bash_comments,
    '.bash': extract_bash_comments,
    '.lua': extract_lua_comments,
    '.hs': extract_haskell_comments,
    '.erl': extract_erlang_comments,
    '.hrl': extract_erlang_comments,
    '.ps1': extract_powershell_comments,
    '.psm1': extract_powershell_comments,
    '.py': extract_python_comments,
}


#----------------------------------------------------------------------
# default target
#----------------------------------------------------------------------
TARGET = sys.platform


#----------------------------------------------------------------------
# configure
#----------------------------------------------------------------------
class configure (object):

    def __init__ (self, srcname, target = None):
        self.srcname = os.path.abspath(srcname and srcname or __file__)
        self.dirname = os.path.dirname(self.srcname)
        self.extname = os.path.splitext(self.srcname)[1].lower()
        self.basename = os.path.basename(self.srcname)
        self.target = target if target else TARGET
        self.commands = {}
        self.names = []
        self.environ = {}
        self.environ['FILENAME'] = self.basename
        self.environ['FILEPATH'] = self.srcname
        self.environ['FILEDIR'] = self.dirname
        self.environ['FILEEXT'] = os.path.splitext(self.basename)[1].lower()
        self.environ['FILENOEXT'] = os.path.splitext(self.basename)[0]
        self.environ['PATHNOEXT'] = os.path.splitext(self.srcname)[0]
        markers = ('.git', '.svn', '.hg', '.project', '.root')
        if 'QUICKRUN_MARKERS' in os.environ:
            text = os.environ['QUICKRUN_MARKERS'].strip()
            mm = []
            for name in text.split(','):
                name = name.strip()
                if name:
                    mm.append(name)
            if mm:
                markers = tuple(mm)
        self.root = self.find_root(self.dirname, markers, True)
        self.environ['ROOT'] = self.root
        self.environ['DIRNAME'] = os.path.basename(self.dirname)
        self.environ['PRONAME'] = os.path.basename(self.root)
        self.environ['TARGET'] = self.target

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

    # execute command without capture, returns exit code
    def execute (self, args, cwd = None, env = None, timeout = None, stdin = None):
        if env:
            envcopy = os.environ.copy()
            envcopy.update(env)
            env = envcopy
        if stdin:
            if isinstance(stdin, str):
                stdin = stdin.encode('utf-8', 'ignore')
        result = subprocess.run(args, cwd = cwd, env = env,
                                shell = True,
                                input = stdin,
                                timeout = timeout)
        return result.returncode

    def system (self, cmd, cwd = None, env = None):
        return self.execute(cmd, cwd, env)

    def show_env (self):
        import pprint
        pprint.pprint(self.environ)
        return 0

    # load content
    def load_file_content (self, filename, mode = 'r'):
        if hasattr(filename, 'read'):
            try: content = filename.read()
            except Exception: content = None
            return content
        try:
            if '~' in filename:
                filename = os.path.expanduser(filename)
            fp = open(filename, mode)
            content = fp.read()
            fp.close()
        except Exception:
            content = None
        return content

    # load file and guess encoding
    def load_file_text (self, filename, encoding = None):
        content = self.load_file_content(filename, 'rb')
        if content is None:
            return None
        # BOM detection: UTF-8 / UTF-16 LE / UTF-16 BE
        if content[:3] == b'\xef\xbb\xbf':
            return content[3:].decode('utf-8')
        if content[:2] == b'\xff\xfe':
            return content[2:].decode('utf-16-le')
        if content[:2] == b'\xfe\xff':
            return content[2:].decode('utf-16-be')
        if encoding is not None:
            return content.decode(encoding, 'ignore')
        # try common encodings in order; latin1 never fails (last resort)
        guess = ['utf-8', 'gbk']
        try:
            import locale
            pe = locale.getpreferredencoding()
            if pe:
                guess.append(pe)
        except Exception:
            pass
        visit = {}
        for name in guess:
            if not name or name in visit:
                continue
            visit[name] = 1
            try:
                return content.decode(name)
            except (UnicodeDecodeError, LookupError):
                pass
        return content.decode('latin1')

    def extract_comments (self, filename):
        if not os.path.exists(filename):
            sys.stderr.write('error: file not found: %s\n' % filename)
            return None
        extname = os.path.splitext(filename)[1].lower()
        if extname not in EXTRACTORS:
            sys.stderr.write('error: no extractor for file type %s\n' % extname)
            return None
        extractor = EXTRACTORS[extname]
        content = self.load_file_text(filename)
        if content is None:
            return None
        comments = extractor(content)
        return comments

    def load (self):
        comments = self.extract_comments(self.srcname)
        if comments is None:
            return -1
        self.commands = {}
        conditional = {}
        for lnum, text in comments:
            text = text.strip('\r\n\t ')
            if not text:
                continue
            if not text.startswith('@'):
                continue
            text = text[1:].strip('\r\n\t ')
            if not text.startswith('command'):
                continue
            text = text[len('command'):].strip('\r\n\t ')
            if not ':' in text:
                continue
            key, _, val = text.partition(':')
            key = key.strip('\r\n\t ')
            val = val.strip('\r\n\t ')
            if not key:
                continue
            if not key.startswith('('):
                continue
            if not key.endswith(')'):
                continue
            key = key[1:-1].strip('\r\n\t ')
            name, _, condition = key.partition('/')
            name = name.strip('\r\n\t ')
            condition = condition.strip('\r\n\t ')
            if condition and condition != self.target:
                continue
            # platform-specific commands are buffered and merged last
            # so they override unconditional ones of the same name
            if condition:
                conditional[name] = val
            else:
                self.commands[name] = val
        self.commands.update(conditional)
        self.names = list(self.commands.keys())
        self.names.sort()
        return 0

    def quickrun (self, name):
        if name not in self.commands:
            sys.stderr.write('error: command not found: %s\n' % name)
            return 1
        cmd = self.commands[name]
        env = self.environ.copy()
        for key in self.environ:
            val = self.environ[key]
            if not isinstance(val, str):
                val = str(val)
            token = '$(' + key + ')'
            if token in cmd:
                cmd = cmd.replace(token, val)
        return self.system(cmd, cwd = self.dirname, env = env)

    def list_commands (self):
        rows = []
        for name in self.names:
            cmd = self.commands[name]
            rows.append([name, ': ' + cmd])
        text = tabulify(rows, style = 0)
        print(text)
        return 0



#----------------------------------------------------------------------
# help()
#----------------------------------------------------------------------
def help():
    fn = os.path.basename(sys.argv[0])
    tt = sys.platform
    print('usage: python %s [options] <filename> [command]' % fn)
    print('options:')
    print('  -h, --help                  show this message and exit')
    print('  -t {name}, --target={name}  specify target platform (default: %s)' % tt)
    print('  -l, --list                  list available commands')
    return 0


#----------------------------------------------------------------------
# main function
#----------------------------------------------------------------------
def main(argv = None):
    argv = argv if argv is not None else sys.argv[1:]
    args = [n for n in argv]
    options, args = getopt(args, 't')
    if ('h' in options) or ('help' in options):
        help()
        return 0
    if not args:
        print('filename is not provided, use -h for help')
        return 1
    srcname = args[0]
    target = TARGET
    if 't' in options:
        target = options['t']
    if 'target' in options:
        target = options['target']
    if not os.path.exists(srcname):
        print('error: file not found: %s' % srcname)
        return 1
    cc = configure(srcname, target)
    if cc.load() != 0:
        return 1
    if (len(args) == 1) or ('l' in options) or ('list' in options):
        print('Command List (%s):' % srcname)
        cc.list_commands()
        return 0
    command = args[1]
    return cc.quickrun(command)


#----------------------------------------------------------------------
# commands in comment
#----------------------------------------------------------------------
# @command(build): gcc -o $(FILENOEXT) $(FILENAME)
# @command(run-win32/win32): echo running on windows
# @command(run-linux/linux): echo running on linux
# @command(echo): echo source: "$(FILEPATH)"


#----------------------------------------------------------------------
# testing suit
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        print('extracting comments from C/C++ code sample:')
        comments = extract_cpp_comments(code_sample_cpp)
        for lnum, text in comments:
            print('line %d: %s' % (lnum, text))
        print('\nextracting comments from Python code sample:')
        comments = extract_python_comments(code_sample_python)
        for lnum, text in comments:
            print('line %d: %s' % (lnum, text))
        return 0
    def test2():
        c = configure(None)
        c.show_env()
        c.load()
        pprint.pprint(c.commands)
        c.quickrun('echo')
        c.list_commands()
        help()
        return 0
    def test3():
        args = []
        args = [__file__]
        main(args)
        return 0

    # test3()
    sys.exit(main())


