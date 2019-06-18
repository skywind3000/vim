#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# translator.py - 命令行翻译（谷歌，必应，百度，有道，词霸）
#
# Created by skywind on 2019/06/14
# Version: 1.0.2, Last Modified: 2019/06/18 18:40
#
#======================================================================
from __future__ import print_function, unicode_literals
import sys
import time
import os
import random
import copy


#----------------------------------------------------------------------
# 语言的别名
#----------------------------------------------------------------------
langmap = {
        "arabic": "ar",
        "bulgarian": "bg",
        "catalan": "ca",
        "chinese": "zh-CN",
        "chinese simplified": "zh-CHS",
        "chinese traditional": "zh-CHT",
        "czech": "cs",
        "danish": "da",	
        "dutch": "nl",
        "english": "en",
        "estonian": "et",
        "finnish": "fi",
        "french": "fr",
        "german": "de",
        "greek": "el",
        "haitian creole": "ht",
        "hebrew": "he",
        "hindi": "hi",
        "hmong daw": "mww",
        "hungarian": "hu",
        "indonesian": "id",
        "italian": "it",
        "japanese": "ja",
        "klingon": "tlh",
        "klingon (piqad)":"tlh-Qaak",
        "korean": "ko",
        "latvian": "lv",
        "lithuanian": "lt",
        "malay": "ms",
        "maltese": "mt",
        "norwegian": "no",
        "persian": "fa",
        "polish": "pl",
        "portuguese": "pt",
        "romanian": "ro",
        "russian": "ru",
        "slovak": "sk",
        "slovenian": "sl",
        "spanish": "es",
        "swedish": "sv",
        "thai": "th",
        "turkish": "tr",
        "ukrainian": "uk",
        "urdu": "ur",
        "vietnamese": "vi",
        "welsh": "cy"
    }


#----------------------------------------------------------------------
# BasicTranslator
#----------------------------------------------------------------------
class BasicTranslator(object):

    def __init__ (self, name, **argv):
        self._name = name
        self._config = {}  
        self._options = argv
        self._session = None
        self._agent = None
        self._load_config(name)
        self._check_proxy()

    def __load_ini (self, ininame, codec = None):
        config = {}
        if not ininame:
            return None
        elif not os.path.exists(ininame):
            return None
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
                config.setdefault(lowsect, {})[lowkey] = val
        if 'default' not in config:
            config['default'] = {}
        return config

    def _load_config (self, name):
        self._config = {}
        ininame = os.path.expanduser('~/.config/translator/config.ini')
        config = self.__load_ini(ininame)
        if not config:
            return False
        for section in ('default', name):
            items = config.get(section, {})
            for key in items:
                self._config[key] = items[key]
        return True

    def _check_proxy (self):
        proxy = os.environ.get('all_proxy', None)
        if not proxy:
            return False
        if not isinstance(proxy, str):
            return False
        if 'proxy' not in self._config:
            self._config['proxy'] = proxy.strip()
        return True

    def request (self, url, data = None, post = False, header = None):
        import requests
        if not self._session:
            self._session = requests.Session()
        argv = {}
        if header is not None:
            header = copy.deepcopy(header)
        else:
            header = {}
        if self._agent:
            header['User-Agent'] = self._agent
        argv['headers'] = header
        timeout = self._config.get('timeout', 7)
        proxy = self._config.get('proxy', None)
        if timeout:
            argv['timeout'] = float(timeout)
        if proxy:
            proxies = {'http': proxy, 'https': proxy}
            argv['proxies'] = proxies
        if not post:
            if data is not None:
                argv['params'] = data
        else:
            if data is not None:
                argv['data'] = data
        if not post:
            r = self._session.get(url, **argv)
        else:
            r = self._session.post(url, **argv)
        return r

    def http_get (self, url, data = None, header = None):
        return self.request(url, data, False, header)

    def http_post (self, url, data = None, header = None):
        return self.request(url, data, True, header)

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

    # 翻译结果：需要填充如下字段
    def translate (self, sl, tl, text):
        res = {}
        res['sl'] = sl              # 来源语言
        res['tl'] = sl              # 目标语言
        res['text'] = text          # 需要翻译的文本
        res['translation'] = None   # 翻译结果
        res['html'] = None          # HTML 格式的翻译结果（如果有的话）
        res['xterm'] = None         # ASCII 色彩输出（如果有的话）
        res['info'] = None          # 原始网站的返回值
        return res

    # 是否是英文
    def check_english (self, text):
        for ch in text:
            if ord(ch) >= 128:
                return False
        return True

    # 猜测语言
    def guess_language (self, sl, tl, text):
        if ((not sl) or sl == 'auto') and ((not tl) or tl == 'auto'):
            if self.check_english(text):
                sl, tl = ('en-US', 'zh-CN')
            else:
                sl, tl = ('zh-CN', 'en-US')
        if sl.lower() in langmap:
            sl = langmap[sl.lower()]
        if tl.lower() in langmap:
            tl = langmap[tl.lower()]
        return sl, tl
    
    def md5sum (self, text):
        import hashlib
        m = hashlib.md5()
        if sys.version_info[0] < 3:
            if isinstance(text, unicode):
                text = text.encode('utf-8')
        else:
            if isinstance(text, str):
                text = text.encode('utf-8')
        m.update(text)
        return m.hexdigest()


#----------------------------------------------------------------------
# Azure Translator
#----------------------------------------------------------------------
class AzureTranslator (BasicTranslator):

    def __init__ (self, **argv):
        super(AzureTranslator, self).__init__('azure', **argv)
        if 'apikey' not in self._config:
            sys.stderr.write('error: missing apikey in [azure] section\n')
            sys.exit()
        self.apikey = self._config['apikey']

    def translate (self, sl, tl, text):
        import uuid
        sl, tl = self.guess_language(sl, tl, text)
        qs = self.url_quote(sl)
        qt = self.url_quote(tl)
        url = 'https://api.cognitive.microsofttranslator.com/translate'
        url += '?api-version=3.0&from={}&to={}'.format(qs, qt)
        headers = {
            'Ocp-Apim-Subscription-Key': self.apikey,
            'Content-type': 'application/json',
            'X-ClientTraceId': str(uuid.uuid4())
        }
        body = [{'text' : text}]
        import json
        resp = self.http_post(url, json.dumps(body), headers).json()
        # print(resp)
        res = {}
        res['text'] = text
        res['sl'] = sl
        res['tl'] = tl
        res['translation'] = self.render(resp)
        res['html'] = None
        res['xterm'] = None
        return res

    def render (self, resp):
        if not resp:
            return ''
        x = resp[0]
        if not x:
            return ''
        y = x['translations']
        if not y:
            return ''
        output = ''
        for item in y:
            output += item['text'] + '\n'
        return output


#----------------------------------------------------------------------
# Google Translator
#----------------------------------------------------------------------
class GoogleTranslator (BasicTranslator):

    def __init__ (self, **argv):
        super(GoogleTranslator, self).__init__('google', **argv)
        self._agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:59.0)'
        self._agent += ' Gecko/20100101 Firefox/59.0'

    def get_url (self, sl, tl, qry):
        http_host = self._options.get('host', 'translate.googleapis.com')
        http_host = 'translate.google.cn'
        qry = self.url_quote(qry)
        url = 'https://{}/translate_a/single?client=gtx&sl={}&tl={}&dt=at&dt=bd&dt=ex&' \
              'dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&dt=t&q={}'.format(
                      http_host, sl, tl, qry)
        return url

    def translate (self, sl, tl, text):
        sl, tl = self.guess_language(sl, tl, text)
        self.text = text
        url = self.get_url(sl, tl, text)
        r = self.http_get(url)
        obj = r.json()
        res = {}
        res['sl'] = obj[2] and obj[2] or sl
        res['tl'] = obj[1] and obj[1] or tl
        res['info'] = obj
        res['translation'] = self.render(obj)
        res['html'] = None
        return res

    def render (self, obj):
        result = self.get_result('', obj) + '\n'
        result = self.get_synonym(result, obj)
        if len(obj) >= 13 and obj[12]:
            result = self.get_definitions(result, obj)
        if len(obj) >= 6 and obj[5]:
            result = self.get_alternative(result, obj)
        return result

    def get_result (self, result, obj):
        for x in obj[0]:
            if x[0]:
                result += x[0]
        return result

    def get_synonym (self, result, resp):
        if resp[1]:
            result += '\n-------------\n'
            result += 'Translations\n'
            for x in resp[1]:
                result += '\n'
                result += '[{}]\n'.format(x[0][0])
                for i in x[2]:
                    result += '{}: {}\n'.format(i[0], ", ".join(i[1]))
        return result

    def get_definitions (self, result, resp):
        result += '\n-------------\n'
        result += 'Definitions\n'
        for x in resp[12]:
            result += '\n'
            result += '[{}]\n'.format(x[0])
            for y in x[1]:
                result += '- {}\n'.format(y[0])
                result += '  * {}\n'.format(y[2]) if len(y) >= 3 else ''
        return result

    def get_alternative (self, result, resp):
        if len(resp) < 6 or (not resp[5]):
            return result
        result += '\n-------------\n'
        result += 'Alternatives\n'
        for x in resp[5]:
            result += '- {}\n'.format(x[0])
            for i in x[2]:
                result += '  * {}\n'.format(i[0])
        return result



#----------------------------------------------------------------------
# Youdao Translator
#----------------------------------------------------------------------
class YoudaoTranslator (BasicTranslator):

    def __init__ (self, **argv):
        super(YoudaoTranslator, self).__init__('youdao', **argv)
        self.url = 'https://fanyi.youdao.com/translate_o?smartresult=dict&smartresult=rule'
        self.D = "ebSeFb%=XZ%T[KZ)c(sy!"

    def get_md5 (self, value):
        import hashlib
        m = hashlib.md5()
        # m.update(value)
        m.update(value.encode('utf-8'))
        return m.hexdigest()

    def sign (self, text, salt):
        s = "fanyideskweb" + text + salt + self.D
        return self.get_md5(s)

    def translate (self, sl, tl, text):
        sl, tl = self.guess_language(sl, tl, text)
        self.text = text
        salt = str(int(time.time() * 1000) + random.randint(0, 10))
        sign = self.sign(text, salt)
        header = {
            'Cookie': 'OUTFOX_SEARCH_USER_ID=-2022895048@10.168.8.76;',
            'Referer': 'http://fanyi.youdao.com/',
            'User-Agent': 'Mozilla/5.0 (Windows NT 6.2; rv:51.0) Gecko/20100101 Firefox/51.0',
        }
        data = {
            'i': text,
            'from': sl,
            'to': tl, 
            'smartresult': 'dict',
            'client': 'fanyideskweb',
            'salt': salt,
            'sign': sign,
            'doctype': 'json',
            'version': '2.1',
            'keyfrom': 'fanyi.web',
            'action': 'FY_BY_CL1CKBUTTON',
            'typoResult': 'true'
        }
        r = self.http_post(self.url, data, header)
        obj = r.json()
        translation = ''
        res = {}
        res['text'] = text
        res['sl'] = sl
        res['tl'] = tl
        res['translation'] = self.render(obj)
        res['info'] = obj
        res['html'] = None
        res['xterm'] = None
        return res

    def render (self, obj):
        output = ''
        t = obj.get('translateResult')
        if t:
            for n in t:
                part = []
                for m in n:
                    x = m.get('tgt')
                    if x:
                        part.append(x)
                if part:
                    output += ', '.join(part) + '\n'
        if 'smartResult' in obj:
            output += '---------\n'
            smarts = obj['smartResult']['entries']
            for entry in smarts:
                if entry:
                    entry = entry.replace('\r', '')
                    output += entry
        return output


#----------------------------------------------------------------------
# Bing2: 免费 web 接口，只能查单词
#----------------------------------------------------------------------
class BingDict (BasicTranslator):

    def __init__ (self, **argv):
        super(BingDict, self).__init__('bingdict', **argv)
        self._agent = 'Mozilla/5.0 (X11; Linux x86_64; rv:50.0) Gecko/20100101'
        self._agent += ' Firefox/50.0'
        self._url = 'http://cn.bing.com/dict/SerpHoverTrans'

    def translate (self, sl, tl, text):
        url = self._url + '?q=' + self.url_quote(text)
        headers = {
            'Host': 'cn.bing.com',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
        }
        resp = self.http_get(url, None, headers)
        res = {}
        res['sl'] = 'auto'
        res['tl'] = 'auto'
        res['text'] = text
        res['info'] = resp.text
        res['translation'] = self.render(text, resp.text)
        return res

    def render (self, word, html):
        from bs4 import BeautifulSoup
        if not html:
            return ''
        soup = BeautifulSoup(html, 'lxml')
        if soup.find('h4').text.strip() != word:
            return None
        lis = soup.find_all('li')
        trans = []
        for item in lis:
            t = item.get_text()
            if t:
                trans.append(t)
        if not trans:
            return None
        return '\n'.join(trans)



#----------------------------------------------------------------------
# Baidu Translator
#----------------------------------------------------------------------
class BaiduTranslator (BasicTranslator):

    def __init__ (self, **argv):
        super(BaiduTranslator, self).__init__('baidu', **argv)
        if 'apikey' not in self._config:
            sys.stderr.write('error: missing apikey in [baidu] section\n')
            sys.exit()
        if 'secret' not in self._config:
            sys.stderr.write('error: missing secret in [baidu] section\n')
            sys.exit()
        self.apikey = self._config['apikey']
        self.secret = self._config['secret']
        langmap = {
                'zh-cn': 'zh',
                'zh-chs': 'zh',
                'zh-cht': 'cht',
                'en-us': 'en', 
                'en-gb': 'en',
                'ja': 'jp',
            }
        self.langmap = langmap

    def convert_lang (self, lang):
        t = lang.lower()
        if t in self.langmap:
            return self.langmap[t]
        return lang

    def translate (self, sl, tl, text):
        sl, tl = self.guess_language(sl, tl, text)
        req = {}
        req['q'] = text
        req['from'] = self.convert_lang(sl)
        req['to'] = self.convert_lang(tl)
        req['appid'] = self.apikey
        req['salt'] = str(int(time.time() * 1000) + random.randint(0, 10))
        req['sign'] = self.sign(text, req['salt'])
        url = "https://fanyi-api.baidu.com/api/trans/vip/translate"
        r = self.http_post(url, req)
        resp = r.json()
        res = {}
        res['text'] = text
        res['sl'] = sl
        res['tl'] = tl
        res['info'] = resp
        res['translation'] = self.render(resp)
        res['html'] = None
        res['xterm'] = None
        return res

    def sign (self, text, salt):
        t = self.apikey + text + salt + self.secret
        return self.md5sum(t)

    def render (self, resp):
        output = ''
        result = resp['trans_result']
        for item in result:
            output += '' + item['src'] + '\n'
            output += ' * ' + item['dst'] + '\n'
        return output


#----------------------------------------------------------------------
# 词霸
#----------------------------------------------------------------------
class CibaTranslator (BasicTranslator):

    def __init__ (self, **argv):
        super(CibaTranslator, self).__init__('ciba', **argv)

    def translate (self, sl, tl, text):
        sl, tl = self.guess_language(sl, tl, text)
        url = 'https://fy.iciba.com/ajax.php'
        req = {}
        req['a'] = 'fy'
        req['f'] = sl
        req['t'] = tl
        req['w'] = text
        r = self.http_get(url, req, None)
        resp = r.json()
        res = {}
        res['text'] = text
        res['sl'] = sl
        res['tl'] = tl
        res['translation'] = None
        res['html'] = None
        res['xterm'] = None
        if 'content' in resp:
            if 'out' in resp['content']:
                res['translation'] = resp['content']['out']
        return res


#----------------------------------------------------------------------
# 分析命令行参数
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
# 引擎注册
#----------------------------------------------------------------------
ENGINES = {
        'google': GoogleTranslator,
        'azure': AzureTranslator,
        'baidu': BaiduTranslator,
        'youdao': YoudaoTranslator,
        'bing': BingDict,
        'ciba': CibaTranslator,
    }


#----------------------------------------------------------------------
# 主程序
#----------------------------------------------------------------------
def main(argv = None):
    if argv is None:
        argv = sys.argv
    argv = [ n for n in argv ]
    options, args = getopt(argv[1:])
    engine = options.get('engine')
    if not engine:
        engine = 'google'
    sl = options.get('from')
    if not sl:
        sl = 'auto'
    tl = options.get('to')
    if not tl:
        tl = 'auto'
    if not args:
        print('usage: translator.py {--engine=xx} {--from=xx} {--to=xx} text')
        print('engines:', list(ENGINES.keys()))
        return 0
    text = ' '.join(args)
    cls = ENGINES.get(engine)
    if not cls:
        print('bad engine name: ' + engine)
        return -1
    translator = cls()
    res = translator.translate(sl, tl, text)
    if not res:
        return -2
    if 'translation' not in res:
        return -3
    print(res['translation'])
    return 0


#----------------------------------------------------------------------
# testing suit
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        bt = BasicTranslator('test')
        r = bt.request("http://www.baidu.com")
        print(r.text)
        return 0
    def test2():
        gt = GoogleTranslator()
        # r = gt.translate('auto', 'auto', 'Hello, World !!')
        # r = gt.translate('auto', 'auto', '你吃饭了没有?')
        # r = gt.translate('auto', 'auto', '长')
        r = gt.translate('auto', 'auto', 'long')
        # r = gt.translate('auto', 'auto', 'kiss')
        # r = gt.translate('auto', 'auto', '亲吻')
        import pprint
        print(r['translation'])
        # pprint.pprint(r['info'])
        return 0
    def test3():
        t = YoudaoTranslator()
        r = t.translate('auto', 'auto', 'kiss')
        import pprint
        pprint.pprint(r)
        print(r['translation'])
        return 0
    def test4():
        t = AzureTranslator()
        r = t.translate('', 'japanese', '吃饭没有？')
        # print(r['info'])
        # print()
        print(r['translation'])
    def test5():
        t = BaiduTranslator()
        r = t.translate('', '', '吃饭了没有?')
        import pprint
        pprint.pprint(r)
        print(r['translation'])
        return 0
    def test6():
        t = CibaTranslator()
        r = t.translate('', '', '吃饭没有？')
        # print(r['info'])
        # print()
        print(r['translation'])
    def test9():
        argv = ['', '正在测试翻译一段话']
        main(argv)
        print('=====')
        argv = ['', '--engine=youdao', '正在测试翻译一段话']
        main(argv)
        return 0
    # test6()
    main()



