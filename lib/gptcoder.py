#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# gptcoder.py - 
#
# Created by skywind on 2024/02/19
# Last Modified: 2024/02/19 21:45:51
#
#======================================================================
import sys
import time
import os
import json


#----------------------------------------------------------------------
# configure
#----------------------------------------------------------------------
class configure (object):

    def __init__ (self, ininame = None):
        if ininame is None:
            ininame = '~/.config/gptcoder.ini'
        if isinstance(ininame, dict):
            self.config = self._deep_copy(ininame)
        else:
            self.config = self.load_ini(ininame)
        if not self.config:
            self.config = {}
        if 'default' not in self.config:
            self.config['default'] = {}
        self.engine = self.config['default'].get('engine', '').lower()
        if self.engine == '':
            self.engine = 'chatgpt'
        self._initialize()

    # initialize
    def _initialize (self):
        return 0

    # copy config
    def _deep_copy (self, d):
        obj = {}
        for key in d:
            obj[key] = {}
            src = d[key]
            for k in src:
                obj[key][k] = src[k]
        return obj

    # auto detect encoding and decode into a string
    def string_auto_decode (self, payload, encoding = None):
        content = None
        if payload is None:
            return None
        if hasattr(payload, 'read'):
            try: content = payload.read()
            except: pass
        else:
            content = payload
        if sys.version_info[0] >= 3:
            if isinstance(content, str):
                return content
        else:
            # pylint: disable-next=else-if-used, undefined-variable
            if isinstance(content, unicode):   # noqa
                return content
        if content is None:
            return None
        if not isinstance(payload, bytes):
            return str(payload)
        if content[:3] == b'\xef\xbb\xbf':
            return content[3:].decode('utf-8', 'ignore')
        elif encoding is not None:
            return content.decode(encoding, 'ignore')
        guess = [sys.getdefaultencoding(), 'utf-8']
        if sys.stdout and sys.stdout.encoding:
            guess.append(sys.stdout.encoding)
        try:
            import locale
            guess.append(locale.getpreferredencoding())
        except:
            pass
        visit = {}
        text = None
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

    def load_file_content (self, filename, mode = 'r'):
        if hasattr(filename, 'read'):
            try: 
                return filename.read()
            except: 
                return None
        try:
            if '~' in filename:
                filename = os.path.expanduser(filename)
            fp = open(filename, mode)
            content = fp.read()
            fp.close()
        except:
            return None
        return content

    def load_file_text (self, filename, encoding = None):
        content = self.load_file_content(filename, 'rb')
        return self.string_auto_decode(content, encoding)

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

    # find vcs root
    def vcs_find_root (self, path):
        markers = ('.git', '.svn', '.hg')
        root = self.find_root(path, markers, False)
        return root

    # check vcs type
    def vcs_check_type (self, path):
        root = self.vsc_find_root(path)
        if not root:
            return None
        for marker in ('.git', '.svn', '.hg'):
            test = os.path.join(root, marker)
            if os.path.isdir(test):
                return marker[1:]
        return None

    # execute program and return output
    def execute (self, args):
        import subprocess
        p = subprocess.Popen(args, shell = True,
                             stdin = subprocess.PIPE, 
                             stdout = subprocess.PIPE,
                             stderr = subprocess.STDOUT)
        stdin, stdouterr = (p.stdin, p.stdout)
        stdin.close()
        content = stdouterr.read()
        stdouterr.close()
        p.wait()
        return self.string_auto_decode(content)

    # request openai
    def _chatgpt_request (self, messages, apikey, opts):
        import urllib, urllib.request
        url = opts.get('url', 'https://api.openai.com').rstrip('/')
        url = url + "/v1/chat/completions"
        proxy = opts.get('proxy', None)
        timeout = opts.get('timeout', 20000)
        d = {'messages': messages}
        d['model'] = opts.get('model', 'gpt-3.5-turbo')
        d['stream'] = opts.get('stream', False)
        handlers = []
        if proxy:
            p = {'http': proxy, 'https': proxy}
            proxy_handler = urllib.request.ProxyHandler(p)
            handlers.append(proxy_handler)
        opener = urllib.request.build_opener(*handlers)
        req = urllib.request.Request(url, data = json.dumps(d).encode('utf-8'))
        req.add_header("Content-Type", "application/json")
        req.add_header("Authorization", "Bearer %s"%apikey)
        # req.add_header("Accept", "text/event-stream")
        response = opener.open(req, timeout = timeout)
        data = response.read()
        response.close()
        text = data.decode('utf-8', errors = 'ignore')
        return json.loads(text)

    # request local ollama service
    def _ollama_request (self, messages, model, opts):
        import urllib, urllib.request
        url = opts.get('url', 'http://127.0.0.1:11434/api/chat')
        # print('url', url)
        proxy = opts.get('proxy', None)
        timeout = opts.get('timeout', 20000)
        d = {'model': model, 'messages': messages}
        d['stream'] = False
        handlers = []
        if proxy:
            p = {'http': proxy, 'https': proxy}
            proxy_handler = urllib.request.ProxyHandler(p)
            handlers.append(proxy_handler)
        opener = urllib.request.build_opener(*handlers)
        req = urllib.request.Request(url, data = json.dumps(d).encode('utf-8'))
        req.add_header("Content-Type", "application/json")
        response = opener.open(req, timeout = timeout)
        data = response.read()
        response.close()
        text = data.decode('utf-8', errors = 'ignore')
        return json.loads(text)

    def _get_proxy (self, section, convert = False):
        if section not in self.config:
            return None
        proxy = self.config[section].get('proxy', '')
        if proxy:
            proxy = proxy.strip()
            if proxy.startswith('socks5://') and convert:
                proxy = 'socks5h://' + proxy[9:]
        return proxy and proxy or None

    def fatal (self, *args):
        sys.stderr.write('ERROR: ' + ' '.join(args))
        sys.stderr.flush()
        sys.exit(1)
        return 0

    def request (self, messages):
        opts = {}
        if self.engine in ('', 'chatgpt'):
            config = self.config.get('chatgpt', {})
            if 'url' in config:
                opts['url'] = config['url'].strip()
            proxy = self._get_proxy('chatgpt')
            if proxy:
                opts['proxy'] = proxy
            apikey = config.get('apikey', '').strip()
            if not apikey:
                self.fatal('require open apikey')
            obj = self._chatgpt_request(messages, apikey, opts)
            return obj['choices'][0]['message']['content']
        elif self.engine == 'ollama':
            config = self.config.get('ollama', {})
            model = config.get('model', 'llama2')
            proxy = self._get_proxy(self.engine)
            if proxy:
                opts['proxy'] = proxy
            url = config.get('url', '')
            if url:
                opts['url'] = url.strip()
            obj = self._ollama_request(messages, model, opts)
            return obj['message']['content']
        return None


#----------------------------------------------------------------------
# assistant
#----------------------------------------------------------------------
class CodeAssistant (object):

    def __init__ (self, ininame = None):
        self.config = configure(ininame)

    def set_engine (self, engine):
        self.config.engine = engine

    def strip_lines (self, text):
        textlist = []
        state = 0
        for line in text.split('\n'):
            line = line.rstrip('\r\n\t ')
            if state == 0:
                if line:
                    textlist.append(line)
                    state = 1
            else:
                textlist.append(line)
        while len(textlist) > 0 and not textlist[-1]:
            textlist.pop()
        return '\n'.join(textlist)

    # pass args[0] as prompt
    def shell (self, options, args):
        input_text = ''
        if not sys.stdin.isatty():
            try:
                input_text = sys.stdin.read()
            except:
                pass
        msgs = []
        if len(args) > 0:
            prompt = args[0].strip('\r\n\t ')
            if prompt:
                msgs.append({'role': 'system', 'content': prompt})
        input_text = input_text.strip('\r\n\t ')
        if input_text:
            msgs.append({'role': 'user', 'content': input_text})
        if not msgs:
            return 0
        if 0:
            import pprint
            pprint.pprint(msgs)
        if 1:
            msg = self.config.request(msgs)
            print(msg)
        return 0

    # pass args[0] as a filename contains prompt + query
    def playground (self, options, args):
        if len(args) == 0:
            print('requires filename')
            return 0
        content = self.config.load_file_text(args[0])
        textlist = []
        state = ''
        blocks = []
        for lnum, line in enumerate(content.split('\n')):
            line = line.rstrip('\r\n\t ')
            # print(lnum, line)
            if line.startswith('<<<'):
                if textlist:
                    blocks.append((state, textlist))
                    textlist = []
                state = 'user'
            elif line.startswith('>>>'):
                if textlist:
                    blocks.append((state, textlist))
                    textlist = []
                state = 'assistant'
            elif line.lstrip('\r\n\t ').startswith('#'):
                if state != '' or len(textlist) != 0:
                    textlist.append(line)
            else:
                textlist.append(line)
        if textlist:
            blocks.append((state, textlist))
            textlist = []
        if 0:
            import pprint
            pprint.pprint(blocks)
        msgs = []
        for state, textlist in blocks:
            if state == '':
                prompt = '\n'.join(textlist)
                prompt = self.strip_lines(prompt)
                # print('prompt', prompt)
                # print('textlist', textlist)
                if prompt.strip():
                    msgs.append({'role': 'system', 'content': prompt})
            else:
                query = '\n'.join(textlist)
                query = query.rstrip('\r\n\t ')
                if query.strip():
                    msgs.append({'role': state, 'content': query})
        if not msgs:
            return 0
        if 0:
            import pprint
            pprint.pprint(msgs)
        if 1:
            msg = self.config.request(msgs)
            print(msg)
        return 0


#----------------------------------------------------------------------
# getopt
#----------------------------------------------------------------------
def getopt(argv):
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


#----------------------------------------------------------------------
# help 
#----------------------------------------------------------------------
def help(simple = False):
    if simple:
        print('error: no operation specified (use -h for help)')
        print()
        return 0
    exe = os.path.split(os.path.abspath(sys.executable))[1]
    exe = os.path.splitext(exe)[0]
    script = os.path.split(sys.argv[0])[1]
    print('usage: %s %s <operation> [...]'%(exe, script))
    print('operations:')
    print('    gptcoder {-h --help}')
    print('    gptcoder {-s --shell}       <prompt>')
    print('    gptcoder {-p --playground}  <input-file>')
    print()
    return 0


#----------------------------------------------------------------------
# main
#----------------------------------------------------------------------
def main(argv = None):
    if argv is None:
        argv = sys.argv[1:]
    if len(argv) == 0:
        return help(True)
    operation = argv[0]
    options, args = getopt(argv[1:])
    ca = CodeAssistant()
    if operation in ('-h', '--help'):
        if len(argv) <= 1:
            return help(False)
        # what = argv[1]
        hr = help(False)
        return hr
    if operation in ('-s', '--shell'):
        return ca.shell(options, args)
    if operation in ('-p', '--playground'):
        return ca.playground(options, args)
    return 0


#----------------------------------------------------------------------
# testing suit
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        cfg = configure()
        import pprint
        pprint.pprint(cfg.config)
        return 0
    def test2():
        cfg = configure()
        # cfg.engine = 'chatgpt'
        msgs = [{'role': 'system', 'content': 'hello'}]
        obj = cfg.request(msgs)
        print(obj)
        return 0
    def test3():
        cfg = configure()
        # cfg.engine = 'chatgpt'
        msgs = []
        prompt = 'you will convert what I input after "::" into uppercase characters, until I say "zaij"'
        msgs.append({'role': 'system', 'content': prompt})
        while 1:
            text = input('$ ')
            msgs.append({'role': 'user', 'content': text})
            text = cfg.request(msgs)
            msgs.append({'role': 'assistant', 'content': text})
            print(text)
            print('')
        return 0
    def test4():
        argv = ['-s', 'hello']
        argv = ['-p', 'd:/temp/test.gpt']
        main(argv)
        return 0
    # test3()
    main()



