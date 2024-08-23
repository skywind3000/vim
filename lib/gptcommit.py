#! /usr/bin/env python3
# -*- coding: utf-8 -*-
#======================================================================
#
# gptcommit.py - 
#
# Created by skywind on 2024/02/11
# Last Modified: 2024/02/14 14:40
#
#======================================================================
import sys
import time
import os
import json


#----------------------------------------------------------------------
# request chatgpt
#----------------------------------------------------------------------
def chatgpt_request(messages, apikey, opts):
    import urllib, urllib.request, json
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


#----------------------------------------------------------------------
# request ollama
#----------------------------------------------------------------------
def ollama_request(messages, url, model, opts):
    import urllib, urllib.request, json
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


#----------------------------------------------------------------------
# load ini
#----------------------------------------------------------------------
def load_ini(filename, encoding = None):
    if '~' in filename:
        filename = os.path.expanduser(filename)
    content = open(filename, 'r', encoding = encoding).read()
    config = {}
    for line in content.split('\n'):
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


#----------------------------------------------------------------------
# execute
#----------------------------------------------------------------------
def execute(args):
    import subprocess
    p = subprocess.Popen(args, shell = False,
                         stdin = subprocess.PIPE, 
                         stdout = subprocess.PIPE,
                         stderr = subprocess.STDOUT)
    stdin, stdouterr = (p.stdin, p.stdout)
    stdin.close()
    content = stdouterr.read()
    stdouterr.close()
    p.wait()
    guess = [sys.getdefaultencoding(), 'utf-8']
    import locale
    guess.append(locale.getpreferredencoding())
    for name in guess + ['gbk', 'ascii', 'latin1']:
        try:
            text = content.decode(name)
            return text
        except:
            pass
    return content.decode(sys.stdout.encoding, 'ignore')


#----------------------------------------------------------------------
# call git
#----------------------------------------------------------------------
def CallGit(*args):
    lines = execute(['git'] + list(args))
    content = [line.rstrip('\r\n\t ') for line in lines.split('\n')]
    return '\n'.join(content)


#----------------------------------------------------------------------
# lazy request
#----------------------------------------------------------------------
DEFAULT_MAX_LINE = 160


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
# get git diff
#----------------------------------------------------------------------
def GitDiff(path, staged = False):
    previous = os.getcwd()
    if path:
        os.chdir(path)
    if staged:
        text = CallGit('diff', '--staged')
    else:
        text = CallGit('diff')
    os.chdir(previous)
    return text


#----------------------------------------------------------------------
# Find Root
#----------------------------------------------------------------------
def FindRoot(path, markers = None, fallback = False):
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


#----------------------------------------------------------------------
# get head lines
#----------------------------------------------------------------------
def TextLimit(text, maxline):
    content = [line for line in text.split('\n')]
    partial = content[:maxline]
    return '\n'.join(partial)


#----------------------------------------------------------------------
# make messages
#----------------------------------------------------------------------
def MakeMessages(text, OPTIONS):
    msgs = []
    engine = OPTIONS.get('engine', 'chatgpt')
    prompt = 'Generate git commit message, for my changes'
    if OPTIONS['concise']:
        prompt = 'Generate concise git commit message, for my changes'
    if engine == 'ollama':
        model = OPTIONS.get('ollama_model', 'llama2')
        if model.startswith('llama2'):
            prompt = prompt + ' (less verbose)'
    lang = OPTIONS.get('lang', '')
    if lang:
        lang = lang[:1].upper() + lang[1:].lower()
        prompt += ' (in %s)'%lang
    if 'prompt' in OPTIONS:
        prompt = OPTIONS['prompt']
    # print('prompt', prompt)
    msgs.append({'role': 'system', 'content': prompt})
    text = TextLimit(text, OPTIONS.get('maxline', DEFAULT_MAX_LINE))
    text = text.rstrip('\r\n\t ')
    msgs.append({'role': 'user', 'content': text})
    return msgs


#----------------------------------------------------------------------
# check a path is inside a repository, returns repo root
#----------------------------------------------------------------------
def CheckRepo(path):
    return FindRoot(path, ('.git',), False)


#----------------------------------------------------------------------
# extract return info
#----------------------------------------------------------------------
def ExtractInfo(obj):
    if not isinstance(obj, dict):
        print('invalid response: %s'%obj)
        return 1
    if 'choices' not in obj:
        print('invalid response: %s'%obj)
        return 2
    choices = obj['choices']
    if not isinstance(choices, list):
        print('invalid response: %s'%obj)
        return 3
    if len(choices) == 0:
        print('invalid response: %s'%obj)
        return 4
    first = choices[0]
    if 'message' not in first:
        print('invalid response: %s'%obj)
        return 5
    message = first['message']
    if not isinstance(message, dict):
        print('invlaid message: %s'%message)
        return 6
    if 'content' not in message:
        print('invlaid message: %s'%message)
        return 7
    return message['content']


#----------------------------------------------------------------------
# EXAMPLE
#----------------------------------------------------------------------
EXAMPLE_RETURN = {
    'choices': [{
         'finish_reason': 'stop',
         'index': 0,
         'logprobs': None,
         'message': {'content': 'Refactored gptcommit.py code and added a '
                     'new function CheckRepo() to check if a '
                     'path is inside a repository',
                     'role': 'assistant'}}],
    'created': 1707882946,
    'id': 'chatcmpl-8s0f4jUWzPyzvZ2Er9CBzNiPgLGMh',
    'model': 'gpt-3.5-turbo-0613',
    'object': 'chat.completion',
    'system_fingerprint': None,
    'usage': {'completion_tokens': 25,
           'prompt_tokens': 1042,
           'total_tokens': 1067}}


EXAMPLE_MESSAGE = '''
Add new function to handle command interface in gpt.vim and utils.vim files
- Added a new function `gptcommit#gpt#cmd(bang, path)` to handle the command interface for generating the commit message.
- Added logic to detect the current path if no path is provided.
- Added logic to check if the provided path is a valid directory.
- Added logic to check if the provided path is within a git repository.
- Added logic to handle cases where the buffer is not writable.
- Added logic to generate the commit message and display it.
- Added logic to append the generated commit message to the current buffer or copy it to the unnamed register.
- Modified the `gptcommit#utils#current_path()` function to handle cases specific to the `fugitive` plugin and the `gitcommit` filetype.
- Added a new function `gptcommit#utils#buffer_writable()` to check if a buffer is writable.
- Added a new function `gptcommit#utils#repo_root(path)` to find the root directory of a git repository.
'''.strip('\r\n\t ')


#----------------------------------------------------------------------
# help
#----------------------------------------------------------------------
def help():
    exe = os.path.split(os.path.abspath(sys.executable))[1]
    exe = os.path.splitext(exe)[0]
    script = os.path.split(sys.argv[0])[1]
    print('usage: %s %s <options> repo_path'%(exe, script))
    print('available options:')
    print('  --key=xxx       required, your openai apikey')
    print('  --staged        optional, use staged diff if present')
    print('  --proxy=xxx     optional, proxy support')
    n = DEFAULT_MAX_LINE
    print('  --maxline=num   optional, max diff lines to feed ChatGPT, default ot %d'%n)
    print('  --model=xxx     optional, can be gpt-3.5-turbo (default) or something')
    print('  --lang=xxx      optional, output language')
    print('  --concise       optional, generate concise message if present')
    print('  --utf8          optional, output utf-8 encoded text if present')
    print('  --url=xxx       optional, alternative openai request url')
    print()
    return 0


#----------------------------------------------------------------------
# main
#----------------------------------------------------------------------
def main(argv = None):
    OPTIONS = {}
    if argv is None:
        argv = sys.argv[1:]
    options, args = getopt(argv)
    if ('h' in options) or ('help' in options):
        help()
        return 0
    if len(args) == 0:
        help()
        return 0
    OPTIONS['engine'] = 'chatgpt'
    if 'engine' in options:
        OPTIONS['engine'] = options['engine']
    engine = OPTIONS['engine']
    if engine == 'chatgpt':
        if not options.get('key', ''):
            envkey = os.environ.get('GPT_COMMIT_KEY', '')
            if not envkey:
                print('--key=XXX is required, use -h for help.')
                return 1
            OPTIONS['key'] = envkey
        else:
            OPTIONS['key'] = options['key']
    elif engine == 'ollama':
        if not options.get('ollama_url', ''):
            ollama_url = os.environ.get('GPT_COMMIT_OLLAMA_URL', '')
            if not ollama_url:
                ollama_url = 'http://127.0.0.1:11434/api/chat'
            OPTIONS['ollama_url'] = ollama_url
        else:
            OPTIONS['ollama_url'] = options['ollama_url']
        if 'ollama_model' not in options:
            ollama_model = os.environ.get('GPT_COMMIT_OLLAMA_MODEL', '')
            if not ollama_model:
                print('--ollama_model=XXX is required, use -h for help.')
                return 1
            OPTIONS['ollama_model'] = ollama_model
        else:
            OPTIONS['ollama_model'] = options['ollama_model']
    # print(options)
    if 'proxy' in options:
        OPTIONS['proxy'] = options['proxy']
    if 'model' in options:
        model = options['model']
        if model:
            OPTIONS['model'] = model
    OPTIONS['maxline'] = DEFAULT_MAX_LINE
    if 'maxline' in options:
        OPTIONS['maxline'] = int(options['maxline'])
    if 'lang' in options:
        OPTIONS['lang'] = options['lang']
    elif 'language' in options:
        OPTIONS['lang'] = options['language']
    OPTIONS['staged'] = ('staged' in options)
    OPTIONS['concise'] = ('concise' in options)
    if 'prompt' in options:
        prompt = options['prompt']
        if prompt:
            OPTIONS['prompt'] = prompt
    if 'url' in options:
        url = options['url']
        if url:
            OPTIONS['url'] = url
    if args:
        OPTIONS['path'] = os.path.abspath(args[0])
        if not os.path.exists(args[0]):
            print('path is invalid: %s'%args[0])
            return 2
    else:
        OPTIONS['path'] = os.getcwd()
    path = OPTIONS['path']
    root = CheckRepo(path)
    if not root:
        print('Not a repository: %s'%path)
        return 3
    content = GitDiff(OPTIONS['path'], OPTIONS['staged'])
    msgs = MakeMessages(content, OPTIONS)
    if msgs[1]['content'] == '':
        print('No changes')
        return 4
    # print(msgs)
    opts = {}
    if 'proxy' in OPTIONS:
        proxy = OPTIONS['proxy']
        if proxy.startswith('socks5://'):
            proxy = 'socks5h://' + proxy[9:]
        opts['proxy'] = proxy
    if engine == 'chatgpt' or 'fake' in options:
        opts['model'] = OPTIONS.get('model', 'gpt-3.5-turbo')
        # opts['timeout'] = 60000
        if 'url' in OPTIONS:
            opts['url'] = OPTIONS['url']
        if 'fake' not in options:
            obj = chatgpt_request(msgs, OPTIONS['key'], opts)
        else:
            obj = EXAMPLE_RETURN
            if not OPTIONS['concise']:
                obj['choices'][0]['message']['content'] = EXAMPLE_MESSAGE
        msg = ExtractInfo(obj)
    else:
        url = OPTIONS['ollama_url']
        model = OPTIONS['ollama_model']
        obj = ollama_request(msgs, url, model, opts)
        msg = 'response error'
        if 'message' in obj:
            message = obj['message']
            if 'content' in message:
                msg = message['content']
    if not isinstance(msg, str):
        sys.exit(msg)
        return msg
    if 'utf8' in options:
        fp = open(sys.stdout.fileno(), mode = 'wb')
        fp.write(msg.encode('utf-8', 'ignore'))
    else:
        print(msg)
    return 0


#----------------------------------------------------------------------
# testing suit
#----------------------------------------------------------------------
if __name__ == '__main__':
    keyfile = '~/.config/openai/apikey.txt'
    def test1():
        import json
        msgs = json.load(open('d:/temp/diff.log'))
        print(msgs)
        return 0
    def test2():
        text = execute(['dir', 'd:\\temp'])
        print(text)
        print(CallGit('status'))
        return 0
    def test3():
        print(CheckRepo('c:/share'))
        print(CheckRepo('c:/share/vim'))
        print(CheckRepo('c:/share/vim/lib'))
        return 0
    def test4():
        apikey = open(os.path.expanduser(keyfile), 'r').read().strip('\r\n\t ')
        print(apikey)
        proxy = ''
        # proxy = '--proxy=socks5h://127.0.0.1:1080'
        args = []
        args += ['--url=' + 'https://api.v3.cm']
        args += ['--key=' + apikey, proxy, '/home/skywind/github/language']
        # args = ['--key=' + apikey, 'c:/share/plugin']
        # args = ['-h']
        main(args)
        return 0
    def test5():
        obj = json.load(open('d:/temp/response.json'))
        import pprint
        pprint.pprint(obj)
        print(ExtractInfo(obj))
        return 0
    def test6():
        os.chdir('/home/skywind/github/language')
        print(execute(['git', 'diff', '--staged']))
        return 0
    # test6()
    main()



