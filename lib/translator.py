#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# translator.py - 命令行翻译（谷歌，必应，百度，有道，词霸）
#
# Created by skywind on 2019/06/14
# Last Modified: 2019/06/14 16:05:47
#
#======================================================================
from __future__ import print_function, unicode_literals
import sys
import time
import copy


#----------------------------------------------------------------------
# BasicTranslator
#----------------------------------------------------------------------
class BasicTranslator(object):

    def __init__ (self, name, **argv):
        self._name = name
        self._options = argv
        self._session = None
        self._agent = None

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
        timeout = self._options.get('timeout', 7)
        proxy = self._options.get('proxy', None)
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

    # sl: 源语言，auto 为自动识别
    # tl: 目标语言
    # text: 待翻译文字
    def translate (self, sl, tl, text):
        res = {}
        res['sl'] = sl
        res['tl'] = sl
        res['text'] = text
        res['translation'] = None
        res['success'] = False
        return res

    # 是否是英文
    def check_english (self, text):
        for ch in text:
            if ord(ch) >= 128:
                return False
        return True

    # 猜测语言
    def guess_language (self, text):
        if self.check_english(text):
            return ('en-US', 'zh-CN')
        return ('zh-CN', 'en-US')
    

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
        if (sl is None or sl == 'auto') and (tl is None or tl == 'auto'):
            sl, tl = self.guess_language(text)
        url = self.get_url(sl, tl, text)
        r = self.http_get(url)
        obj = r.json()
        import pprint
        pprint.pprint(obj)
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
        print(gt.translate('auto', 'auto', 'Hello, World !!'))
        return 0
    test2()



