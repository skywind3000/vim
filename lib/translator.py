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
        timeout = self._options.get('timeout', 10)
        proxy = self._options.get('proxy', None)
        if timeout:
            argv['timeout'] = timeout
        if proxy:
            proxies = {'http': proxy, 'https': proxy}
            argv['proxies'] = proxies
        if not post:
            if data is not None:
                argv['params'] = data
        else:
            if data is not None:
                argv['data'] = data
        try:
            if not post:
                r = self._session.get(url, **argv)
            else:
                r = self._session.post(url, **argv)
        except requests.exceptions.ConnectionError:
            r = None
        except requests.exceptions.RetryError as e:
            r = requests.Response()
            r.status_code = -1
            r.text = 'RetryError'
            r.error = e
        except requests.exceptions.BaseHTTPError as e:
            r = requests.Response()
            r.status_code = -2
            r.text = 'BaseHTTPError'
            r.error = e
        except requests.exceptions.HTTPError as e:
            r = requests.Response()
            r.status_code = -3
            r.text = 'HTTPError'
            r.error = e
        except requests.exceptions.RequestException as e:
            r = requests.Response()
            r.status_code = -4
            r.error = e
        return r

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

    # src: 源语言，None 为自动识别
    # dst: 目标语言
    # text: 待翻译文字
    def translate (self, src, dst, text):
        res = {}
        res['src'] = src
        res['dst'] = dst
        res['text'] = text
        res['translation'] = None
        res['success'] = False
        return res
    

#----------------------------------------------------------------------
# Google Translator
#----------------------------------------------------------------------
class GoogleTranslator (BasicTranslator):

    def __init__ (self, **argv):
        super(GoogleTranslator, self).__init__('google', **argv)
        self._agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:59.0)'
        self._agent += ' Gecko/20100101 Firefox/59.0'


#----------------------------------------------------------------------
# testing suit
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        bt = BasicTranslator('test')
        r = bt.request("http://www.baidu.com")
        print(r.text)
        return 0
    test1()
