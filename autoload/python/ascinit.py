#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# ascinit.py - 
#
# Created by skywind on 2022/09/09
# Last Modified: 2022/09/09 22:27:36
#
#======================================================================
from __future__ import print_function, unicode_literals
import sys
import os
import time

try:
    import vim
except:
    vim = None


#----------------------------------------------------------------------
# global constants
#----------------------------------------------------------------------
SCRIPT_NAME = os.path.abspath(__file__)
SCRIPT_HOME = os.path.join(os.path.dirname(SCRIPT_NAME), '../..')
SCRIPT_HOME = os.path.normpath(SCRIPT_HOME)


#----------------------------------------------------------------------
# runtime: 
#----------------------------------------------------------------------
def runtime(dir):
    if not dir:
        return SCRIPT_HOME
    return os.path.normpath(os.path.join(SCRIPT_HOME, dir))


#----------------------------------------------------------------------
# call vim function
#----------------------------------------------------------------------
def call(funcname, args):
    vim.__args__ = args
    if sys.version_info[0] == 3:
        hr = vim.eval('call("%s", py3eval("vim.__args__"))'%funcname)
    else:
        hr = vim.eval('call("%s", pyeval("vim.__args__"))'%funcname)
    return hr


#----------------------------------------------------------------------
# setup path
#----------------------------------------------------------------------
sys.path.append(runtime('autoload/python'))
sys.path.append(runtime('lib'))

def __normalize_path():
    check = {}
    result = []
    for n in sys.path:
        if n not in check:
            check[n] = 1
            result.append(n)
    sys.path = result

__normalize_path()


#----------------------------------------------------------------------
# testing case
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        print(SCRIPT_HOME)
        for n in sys.path: print(n)
        return 0
    test1()



