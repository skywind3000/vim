#! /usr/bin/env python3
# -*- coding: utf-8 -*-
#======================================================================
#
# dotenv.py - 
#
# Created by skywind on 2026/02/02
# Last Modified: 2026/02/02 20:08:46
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
# DotEnvParser
#----------------------------------------------------------------------
class DotEnvParser:

    def __init__ (self, origin = None):
        self._environ = {}
        self._origin = origin and origin or os.environ.copy()

    def _load_value (self, key, default = None):
        if key in self._environ:
            return self._environ[key]
        if key in self._origin:
            return self._origin[key]
        return default

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
                var_name = value[dollar_index + 2:end_brace]
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
        self._environ[key] = value
        return key

    def push (self, line):
        return self._parse_line(line)

    def clear (self):
        self._environ.clear()

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
        envcopy = os.environ.copy()
        for key in self._dotenv:
            os.environ[key] = self._dotenv[key]
        import subprocess
        ep = subprocess.run(args, shell = True)
        for key in os.environ:
            if key not in self._origin:
                del os.environ[key]
        for key in self._origin:
            os.environ[key] = self._origin[key]
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
        files = ['.dotenv', '.env']
        envfiles = dotenv.list_env_files(os.getcwd(), files)
        for envfile in envfiles:
            dotenv.load(envfile)
    if len(args) == 1:
        if args[0] == '--list':
            envfiles = dotenv.list_env_files(os.getcwd(), ['.dotenv', '.env'])
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
    # test4()
    main()



