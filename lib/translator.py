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
import re
import random
import copy
import json
import codecs
import pprint


#----------------------------------------------------------------------
# 编码兼容
#----------------------------------------------------------------------
if sys.version_info[0] < 3:
    reload(sys)   # noqa: F821
    sys.setdefaultencoding('utf-8')
    # sys.stdout = codecs.getwriter('utf-8')(sys.stdout, 'ignore')
    # sys.stderr = codecs.getwriter('utf-8')(sys.stderr, 'ignore')
else:
    # sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'ignore')
    # sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, 'ignore')
    pass


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
            if isinstance(text, unicode):    # noqa: F821
                text = text.encode('utf-8', 'ignore')
            if plus:
                return urllib.quote_plus(text)
            return urlparse.quote(text)   # noqa: F821
        import urllib.parse
        if plus:
            return urllib.parse.quote_plus(text)
        return urllib.parse.quote(text)

    def create_translation (self, sl = None, tl = None, text = None):
        res = {}
        res['engine'] = self._name
        res['sl'] = sl              # 来源语言
        res['tl'] = tl              # 目标语言
        res['text'] = text          # 需要翻译的文本
        res['phonetic'] = None      # 音标
        res['definition'] = None    # 简单释义
        res['explain'] = None       # 分行解释
        return res

    # 翻译结果：需要填充如下字段
    def translate (self, sl, tl, text):
        return self.create_translation(sl, tl, text)

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
            if isinstance(text, unicode):   # noqa: F821
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
        body = [{'text': text}]
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
        http_host = self._config.get('host', 'translate.googleapis.com')
        qry = self.url_quote(qry)
        url = 'https://{}/translate_a/single?client=gtx&sl={}&tl={}&dt=at&dt=bd&dt=ex&' \
              'dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&dt=t&q={}'.format(
                      http_host, sl, tl, qry)    # noqa: E216
        return url

    def translate (self, sl, tl, text):
        sl, tl = self.guess_language(sl, tl, text)
        self.text = text
        url = self.get_url(sl, tl, text)
        r = self.http_get(url)
        if not r:
            return None
        try:
            obj = r.json()
        except:
            return None
        # pprint.pprint(obj)
        res = self.create_translation(sl, tl, text)
        res['phonetic'] = self.get_phonetic(obj)
        res['definition'] = self.get_definition(obj)
        res['explain'] = self.get_explain(obj)
        res['detail'] = self.get_detail(obj)
        res['alternative'] = self.get_alternative(obj)
        return res

    def get_phonetic (self, obj):
        for x in obj[0]:
            if len(x) == 4:
                return x[3]
        return None

    def get_definition (self, obj):
        paraphrase = ''
        for x in obj[0]:
            if x[0]:
                paraphrase += x[0]
        return paraphrase

    def get_explain (self, obj):
        explain = []
        if obj[1]:
            for x in obj[1]:
                expl = '[{}] '.format(x[0][0])
                for i in x[2]:
                    expl += i[0] + ';'
                explain.append(expl)
        return explain

    def get_detail (self, resp):
        result = []
        if len(resp) < 13:
            return None
        for x in resp[12]:
            result.append('[{}]'.format(x[0]))
            for y in x[1]:
                result.append('- {}'.format(y[0]))
                if len(y) >= 3:
                    result.append('  * {}'.format(y[2]))
        return result

    def get_alternative (self, resp):
        definition = self.get_definition(resp)
        result = []
        if len(resp) < 6:
            return None
        for x in resp[5]:
            # result.append('- {}'.format(x[0]))
            for i in x[2]:
                if i[0] != definition:
                    result.append(' * {}'.format(i[0]))
        return result



#----------------------------------------------------------------------
# Youdao Translator
#----------------------------------------------------------------------
class YoudaoTranslator (BasicTranslator):

    def __init__ (self, **argv):
        super(YoudaoTranslator, self).__init__('youdao', **argv)
        self.url = 'https://fanyi.youdao.com/translate_o?smartresult=dict&smartresult=rule'
        self.D = "ebSeFb%=XZ%T[KZ)c(sy!"
        self.D = "97_3(jkMYg@T[KZQmqjTK"

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
        if not r:
            return None
        try:
            obj = r.json()
        except:
            return None
        # pprint.pprint(obj)
        res = self.create_translation(sl, tl, text)
        res['definition'] = self.get_definition(obj)
        res['explain'] = self.get_explain(obj)
        return res

    def get_definition (self, obj):
        translation = ''
        t = obj.get('translateResult')
        if t:
            for n in t:
                part = []
                for m in n:
                    x = m.get('tgt')
                    if x:
                        part.append(x)
                if part:
                    translation += ', '.join(part)
        return translation

    def get_explain (self, obj):
        explain = []
        if 'smartResult' in obj:
            smarts = obj['smartResult']['entries']
            for entry in smarts:
                if entry:
                    entry = entry.replace('\r', '')
                    entry = entry.replace('\n', '')
                    explain.append(entry)
        return explain


#----------------------------------------------------------------------
# Bing2: 免费 web 接口，只能查单词
#----------------------------------------------------------------------
class BingDict (BasicTranslator):

    def __init__ (self, **argv):
        super(BingDict, self).__init__('bingdict', **argv)
        self._agent = 'Mozilla/5.0 (X11; Linux x86_64; rv:50.0) Gecko/20100101'
        self._agent += ' Firefox/50.0'
        self._url = 'http://bing.com/dict/SerpHoverTrans'
        self._cnurl = 'http://cn.bing.com/dict/SerpHoverTrans'

    def translate (self, sl, tl, text):
        url = ('zh' in tl) and self._cnurl or self._url
        url = self._cnurl
        url = url + '?q=' + self.url_quote(text)
        headers = {
            # 'Host': 'cn.bing.com',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
        }
        resp = self.http_get(url, None, headers)
        if not resp:
            return None
        resp = resp.text
        res = self.create_translation(sl, tl, text)
        res['sl'] = 'auto'
        res['tl'] = 'auto'
        res['text'] = text
        res['phonetic'] = self.get_phonetic(resp)
        res['explain'] = self.get_explain(resp)
        return res

    def get_phonetic (self, html):
        if not html:
            return ''
        m = re.findall(
            r'<span class="ht_attr" lang=".*?">\[(.*?)\] </span>', html)
        if not m:
            return None
        return m[0].strip()

    def get_explain (self, html):
        if not html:
            return []
        m = re.findall(
            r'<span class="ht_pos">(.*?)</span><span class="ht_trs">(.*?)</span>', html)
        expls = []
        for item in m:
            expls.append('%s %s' % item)
        return expls



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
        if not r:
            return None
        try:
            resp = r.json()
        except:
            return None
        resp = r.json()
        if not resp:
            return None
        res = self.create_translation(sl, tl, text)
        res['definition'] = ''
        if 'content' in resp:
            if 'out' in resp['content']:
                res['definition'] = resp['content']['out'] or ''
            if 'ph_en' in resp['content']:
                res['phonetic'] = resp['content']['ph_en'] or ''
            if 'word_mean' in resp['content']:
                res['explain'] = resp['content']['word_mean'] or ''
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
        msg = 'usage: translator.py {--engine=xx} {--from=xx} {--to=xx}'
        print(msg + ' {-json} text')
        print('engines:', list(ENGINES.keys()))
        return 0
    text = ' '.join(args)
    cls = ENGINES.get(engine)
    if not cls:
        print('bad engine name: ' + engine)
        return -1
    translator = cls()
    res = translator.translate(sl, tl, text)
    if 'json' in options:
        text = json.dumps(res)
        sys.stdout.write(str(text))
        return 0
    if not res:
        return -2
    if 'text' in res:
        if res['text']:
            print(res['text'])
    if 'phonetic' in res:
        if res['phonetic'] and ('phonetic' in options):
            print('[' + res['phonetic'] + ']')
    if 'definition' in res:
        if res['definition']:
            print(res['definition'])
    if 'explain' in res:
        if res['explain']:
            print('\n'.join(res['explain']))
    elif 'translation' in res:
        if res['translation']:
            print(res['translation'])
    if 'alternative' in res:
        if res['alternative']:
            print('\n'.join(res['alternative']))
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
    def test7():
        # t = CibaTranslator()
        t = GoogleTranslator()
        # t = YoudaoTranslator()
        # t = BingDict()
        # r = t.translate('zh', 'en', '吃饭了没有？')
        # r = t.translate('', '', 'apple')
        r = t.translate('', '', '正在测试翻译一段话')
        pprint.pprint(r)
    def test9():
        argv = ['', '正在测试翻译一段话']
        main(argv)
        print('=====')
        argv = ['', '--engine=bing', '--sl=zh', '--tl=en', '正在测试翻译一段话']
        main(argv)
        print('=====')
        argv = ['', '--engine=bing', '--sl=zh', '--tl=en', '-json', '苹果']
        main(argv)
        return 0
    # test9()
    main()



