#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# buffer.py - 
#
# Created by skywind on 2023/09/10
# Last Modified: 2023/09/10 23:35:43
#
#======================================================================
import sys
import vim

try:
    from . import core
except:
    import core


#----------------------------------------------------------------------
# internal
#----------------------------------------------------------------------
__buffer_cache = {}


#----------------------------------------------------------------------
# getbufvar
#----------------------------------------------------------------------
def getbufvar(bid: int, varname: str, defval = None):
    return core.call('getbufvar', [bid, varname, defval])


#----------------------------------------------------------------------
# setbufvar
#----------------------------------------------------------------------
def setbufvar(bid: int, varname: str, value):
    return core.call('setbufvar', [bid, varname, value])


#----------------------------------------------------------------------
# bufnr
#----------------------------------------------------------------------
def bufnr(name):
    return core.call('bufnr', [name])


#----------------------------------------------------------------------
# b:changedtick
#----------------------------------------------------------------------
def changedtick(bid):
    try:
        buf = vim.buffers[bid]
        return buf.vars['changedtick']
    except KeyError:
        pass
    return -1


#----------------------------------------------------------------------
# filetype
#----------------------------------------------------------------------
def filetype(bid):
    return vim.eval('getbufvar(%d, "&ft")'%bid)


#----------------------------------------------------------------------
# filetype
#----------------------------------------------------------------------
def buftype(bid):
    return vim.eval('getbufvar(%d, "&bt")'%bid)


#----------------------------------------------------------------------
# current buffer id
#----------------------------------------------------------------------
def current() -> int:
    bid = vim.current.buffer.number
    return bid


#----------------------------------------------------------------------
# get text
#----------------------------------------------------------------------
def get_text(bid):
    tick = changedtick(bid)
    if tick < 0:
        return None
    if bid in __buffer_cache:
        item = __buffer_cache[bid]
        if item[0] == tick:
            return item[1]
    buf = vim.buffers[bid]
    text = buf[:]
    content = '\n'.join(text)
    __buffer_cache[bid] = (tick, content)
    return content


