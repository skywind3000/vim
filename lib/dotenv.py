#! /usr/bin/env python3
# -*- coding: utf-8 -*-
#======================================================================
#
# dotenv.py - Simple .env file parser and environment variable loader
# author: skywind3000 (at) 163.com, 2026
#
# Last Modified: 2026/02/03 00:54:50
#
# Features:
#
# - Load .env files from current directory to root and run commands
# - Load specific .env file or config .env file from ~/.config/dotenv/
# - Supports variable substitution with ${VAR} or $VAR syntax
# - Supports default values with ${VAR:default} syntax
# - Supports quoted values with escape sequences
# - Case-insensitive keys on Windows
# 
# Usage:
#
# 1. Load .env file from current directory to root and run command:
#    $ dotenv <command> [args...]
# 
# 2. Load specific .env file and run command:
#    $ dotenv -f <filename> <command> [args...]
#
# 3. Load ~/.config/dotenv/{name}.env and run command:
#    $ dotenv -c <name> <command> [args...]
#
# 4. List all .env files found from current directory to root:
#    $ dotenv --list
#
# 5. Echo loaded environment variables:
#    $ dotenv --echo
#
# Note:
#
# - This script requires Python 3.x to run.
# - It uses only standard library modules for compatibility.
#
# For more details, refer to the documentation or source code comments
#
#======================================================================
import sys
import os


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
# CaseInsensitiveDict
#----------------------------------------------------------------------
class CaseInsensitiveDict (object):

    def __init__ (self, insensitive):
        self._store = {}
        self._names = {}
        self._insensitive = insensitive

    def __len__ (self):
        return len(self._store)

    def __getitem__ (self, key):
        if self._insensitive:
            lkey = key.lower()
            if lkey not in self._store:
                raise KeyError(key)
            return self._store[lkey]
        return self._store[key]

    def __setitem__ (self, key, value):
        if self._insensitive:
            lkey = key.lower()
            self._names[lkey] = key
            self._store[lkey] = value
        else:
            self._store[key] = value
        return 0

    def __delitem__ (self, key):
        if self._insensitive:
            lkey = key.lower()
            if lkey not in self._names:
                raise KeyError(key)
            del self._names[lkey]
            del self._store[lkey]
        else:
            if key not in self._store:
                raise KeyError(key)
            del self._store[key]
        return 0

    def get (self, key, default = None):
        if self._insensitive:
            lkey = key.lower()
            return self._store.get(lkey, default)
        return self._store.get(key, default)

    def __contains__ (self, key):
        if self._insensitive:
            lkey = key.lower()
            return lkey in self._store
        return key in self._store

    def __iter__ (self):
        if self._insensitive:
            for lkey in self._store:
                yield self._names[lkey]
        else:
            for key in self._store:
                yield key

    def __keys__ (self):
        if self._insensitive:
            return [self._names[lkey] for lkey in self._store]
        return list(self._store.keys())

    def keys (self):
        return self.__keys__()

    def items (self):
        if self._insensitive:
            return [(self._names[lkey], self._store[lkey]) for lkey in self._store]
        return list(self._store.items())

    def values (self):
        return list(self._store.values())

    def clear (self):
        self._store.clear()
        self._names.clear()
        return 0


#----------------------------------------------------------------------
# DotEnvParser
#----------------------------------------------------------------------
class DotEnvParser:

    def __init__ (self, origin = None):
        self._win32 = sys.platform[:3] == 'win' and True or False
        self._environ = CaseInsensitiveDict(self._win32)
        self._origin = CaseInsensitiveDict(self._win32)
        origin = origin and origin or os.environ.copy()
        for key in origin:
            self._origin[key] = origin[key]
        self._reset_windows()

    def _reset_windows (self):
        return 0

    def _load_value (self, key, default = None):
        if key in self._environ:
            return self._environ[key]
        if key in self._origin:
            return self._origin[key]
        return default

    def _store_value (self, key, value):
        self._environ[key] = value
        return 0

    def __len__ (self):
        return len(self._environ)

    def __getitem__ (self, key, default = None):
        return self._environ.get(key, default)

    def __contains__ (self, key):
        return key in self._environ

    def __iter__ (self):
        return iter(self._environ)

    def __keys__ (self):
        return self._environ.keys()

    def keys (self):
        return self.__keys__()

    def _substitute_vars (self, value):
        start = 0
        while True:
            dollar_index = value.find('$', start)
            if dollar_index == -1:
                break
            if dollar_index + 1 >= len(value):
                break
            if value[dollar_index + 1] == '{':
                end_brace = value.find('}', dollar_index + 2)
                if end_brace == -1:
                    start = dollar_index + 1
                    continue
                var_name = value[dollar_index + 2:end_brace].strip('\r\n\t ')
                if ':' in var_name:
                    var_name, _, default_val = var_name.partition(':')
                    var_name = var_name.strip('\r\n\t ')
                    default_val = default_val.strip('\r\n\t ')
                    var_value = self._load_value(var_name, default_val)
                else:
                    var_value = self._load_value(var_name, '')
                value = value[:dollar_index] + var_value + value[end_brace + 1:]
                start = dollar_index + len(var_value)
            else:
                var_end = dollar_index + 1
                while var_end < len(value) and (value[var_end].isalnum() or value[var_end] == '_'):
                    var_end += 1
                var_name = value[dollar_index + 1:var_end]
                var_value = self._load_value(var_name, '')
                value = value[:dollar_index] + var_value + value[var_end:]
                start = dollar_index + len(var_value)
        value.replace('\x00', '$')
        return value

    def _escape_string (self, text):
        output = ''
        index = 0
        while index < len(text):
            ch = text[index]
            if ch == '\\' and index + 1 < len(text):
                next_ch = text[index + 1]
                if next_ch == 'n':
                    output += '\n'
                elif next_ch == 'r':
                    output += '\r'
                elif next_ch == 't':
                    output += '\t'
                elif next_ch == '\\':
                    output += '\\'
                elif next_ch == '"':
                    output += '"'
                elif next_ch == "'":
                    output += "'"
                elif next_ch == '$':
                    output += '\x00'
                else:
                    output += next_ch
                index += 2
            else:
                output += ch
                index += 1
        return output

    def _parse_line (self, line):
        line = line.strip('\r\n\t ')
        if not line:
            return ''
        if line.startswith('#'):
            return ''
        if line.startswith(';'):
            return ''
        if '=' not in line:
            return ''
        key, _, value = line.partition('=')
        key = key.strip('\r\n\t ')
        if not key:
            return ''
        value = value.strip('\r\n\t ')
        if value.startswith('"') and value.endswith('"'):
            value = self._escape_string(value[1:-1])
        elif value.startswith("'") and value.endswith("'"):
            value = value[1:-1]
        value = self._substitute_vars(value)
        self._store_value(key, value)
        return key

    def push (self, line):
        return self._parse_line(line)

    def clear (self):
        self._environ.clear()
        self._reset_windows()

    # load content
    def _load_file_content (self, filename, mode = 'r'):
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
    def _load_file_text (self, filename, encoding = None):
        content = self._load_file_content(filename, 'rb')
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

    def load (self, filepath):
        text = self._load_file_text(filepath)
        if text is None:
            return False
        for line in text.splitlines():
            self.push(line)
        return True


#----------------------------------------------------------------------
# DotEnv
#----------------------------------------------------------------------
class DotEnv (object):

    def __init__ (self):
        self._origin = os.environ.copy()
        self._dotenv = DotEnvParser(self._origin)

    def load (self, filepath):
        return self._dotenv.load(filepath)

    def push (self, line):
        return self._dotenv.push(line)

    def reset (self):
        self._dotenv.clear()

    def run (self, args):
        if not args:
            return
        win32 = sys.platform[:3] == 'win'
        merged = CaseInsensitiveDict(win32)
        for key in os.environ:
            merged[key] = os.environ[key]
        for key in self._dotenv:
            merged[key] = self._dotenv[key]
        final = {}
        for key in merged:
            final[key] = merged[key]
        import subprocess
        if win32:
            ep = subprocess.run(args, shell = True, env = final)
        else:
            ep = subprocess.run(args, shell = False, env = final)
        return ep.returncode

    # enumerate all the .env files from current directory to root
    def list_env_files (self, locate, filename = '.env'):
        envfiles = []
        if not locate:
            locate = os.getcwd()
        curdir = os.path.abspath(locate)
        while True:
            if isinstance(filename, str):
                envpath = os.path.join(curdir, filename)
                if os.path.isfile(envpath):
                    envfiles.append(envpath)
            elif isinstance(filename, list):
                for fname in filename:
                    envpath = os.path.join(curdir, fname)
                    if os.path.isfile(envpath):
                        envfiles.append(envpath)
            parentdir = os.path.dirname(curdir)
            if parentdir == curdir:
                break
            curdir = parentdir
        envfiles.reverse()
        return envfiles

    # load {name}.env file from ~/.config/dotenv/
    def load_config (self, name):
        if not name:
            return False
        configdir = os.path.join(os.path.expanduser('~'), '.config', 'dotenv')
        if 'XDG_CONFIG_HOME' in os.environ:
            configdir = os.path.join(os.environ['XDG_CONFIG_HOME'], 'dotenv')
        configpath = os.path.join(configdir, f'{name}.env')
        hr = self.load(configpath)
        return hr


#----------------------------------------------------------------------
# help
#----------------------------------------------------------------------
def help():
    print("Usage: dotenv [options] command [args...]")
    print("Options:")
    print("  -c <name>   Load ~/.config/dotenv/{name}.env file")
    print("  -f <name>   Load .env file given in {name}")
    print("  -h          Show this help message")
    print("  --list      List all .env files from current directory to root")
    print("  --echo      Echo loaded environment variables")
    print('')
    print('If -c and -f are not provided, dotenv will search for .env files from')
    print('current directory to root.')
    return 0


#----------------------------------------------------------------------
# dotenv files
#----------------------------------------------------------------------
DOTENV_FILES = ['.dotenv', '.env', '.dotenv.local', '.env.local']


#----------------------------------------------------------------------
# main entry
#----------------------------------------------------------------------
def main(argv = None):
    argv = argv or sys.argv[1:]
    options, args = getopt(argv, 'cf')
    if 'h' in options:
        help()
        return 0
    if 'list' in options:
        args = ['--list']
    elif 'echo' in options:
        args = ['--echo']
    if not args:
        print('Empty command to run, use -h for help.')
        return 0
    dotenv = DotEnv()
    if 'c' in options:
        name = options['c']
        if not name:
            print('Config name is empty.')
            return 0
        if not dotenv.load_config(name):
            print(f'Failed to load config file for name: {name}')
            return 0
    elif 'f' in options:
        name = options['f']
        if not name:
            print('File name is empty.')
            return 0
        if not dotenv.load(name):
            print(f'Failed to load .env file: {name}')
            return 0
    else:
        envfiles = dotenv.list_env_files(os.getcwd(), DOTENV_FILES)
        for envfile in envfiles:
            dotenv.load(envfile)
    if len(args) == 1:
        if args[0] == '--list':
            envfiles = dotenv.list_env_files(os.getcwd(), DOTENV_FILES)
            for envfile in envfiles:
                print(envfile)
            return 0
        elif args[0] == '--echo':
            keys = [n for n in dotenv._dotenv]
            # keys.sort()
            for key in keys:
                print(f'{key}={dotenv._dotenv[key]}')
            return 0
    ret = dotenv.run(args)
    return ret



#----------------------------------------------------------------------
# testing suit
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        parser = DotEnvParser()
        parser.push('KEY1=VALUE1')
        parser.push('KEY2="VALUE2 with spaces"')
        parser.push("KEY3='VALUE3 with single quotes'")
        parser.push('KEY4=VALUE4_$KEY1')
        parser.push('KEY5="VALUE5 with \\n new line"')
        assert parser['KEY1'] == 'VALUE1'
        assert parser['KEY2'] == 'VALUE2 with spaces'
        assert parser['KEY3'] == 'VALUE3 with single quotes'
        assert parser['KEY4'] == 'VALUE4_VALUE1'
        assert parser['KEY5'] == 'VALUE5 with \n new line'
        parser.clear()
        print("All tests passed.")
        return 0
    def test2():
        dotenv = DotEnv()
        ret = dotenv.run(['busybox', 'printenv', 'KEY1'])
        help()
        return 0
    def test3():
        dotenv = DotEnv()
        dotenv.load('.env')
        ret = dotenv.run(['busybox', 'printenv', 'KEY_FROM_ENV'])
        return 0
    def test4():
        os.environ['CONFIG_KEY'] = 'OriginalValue'
        args = ['busybox', 'printenv', 'CONFIG_KEY']
        main(args)
    def test5():
        cid = CaseInsensitiveDict(True)
        cid['KeyOne'] = 'Value1'
        assert cid['keyone'] == 'Value1'
        assert cid['KEYONE'] == 'Value1'
        cid['KEYTWO'] = 'Value2'
        assert cid['keytwo'] == 'Value2'
        keys = cid.keys()
        assert 'KeyOne' in keys
        print(cid['KeyONE'])
        return 0
    # test5()
    main()



