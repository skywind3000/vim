#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# cpp.py - 
#
# Created by skywind on 2023/09/11
# Last Modified: 2023/09/11 00:38:20
#
#======================================================================
from pyvim import pyglex, buffer, utils
from pygments.token import Token


#----------------------------------------------------------------------
# 
#----------------------------------------------------------------------
def find_class_name():
    bid = buffer.current()
    tokens = pyglex.get_tokens(bid)
    if tokens is None:
        return ''
    lnum, column = utils.cursor_get()
    # print('>', type(lnum), type(column))
    index = pyglex.locate_token(bid, lnum, column)
    # print('suck', index)
    if index < 0:
        return ''
    index = pyglex.find_backwards(tokens, index, Token.Keyword, 'class')
    if index < 0:
        return ''
    found = pyglex.find_forwards(tokens, index, Token.Name)
    if found < 0:
        return ''
    token = tokens[found]
    return token[1]

