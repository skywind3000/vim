#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# core.py - 
#
# Created by skywind on 2023/09/10
# Last Modified: 2023/09/10 23:39:53
#
#======================================================================
import sys
import os

try:
    import vim
except ImportError:
    vim = None


#----------------------------------------------------------------------
# global constants
#----------------------------------------------------------------------
SCRIPT_NAME = os.path.abspath(__file__)
SCRIPT_HOME = os.path.join(os.path.dirname(SCRIPT_NAME), '../../..')
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



