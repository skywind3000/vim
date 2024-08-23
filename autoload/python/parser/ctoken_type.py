#! /usr/bin/env python
# -*- coding: utf-8 -*-
#  vim: set ts=4 sw=4 tw=0 et :
#======================================================================
#
# ctoken_type.py - 
#
# Created by skywind on 2023/01/09
# Last Modified: 2023/01/09 09:06:11
#
#======================================================================


#----------------------------------------------------------------------
# exports
#----------------------------------------------------------------------
__all__ = []


#----------------------------------------------------------------------
# predefined token name (type)
#----------------------------------------------------------------------
CTOKEN_EOF = 0
CTOKEN_ENDLINE = 1
CTOKEN_KEYWORD = 2
CTOKEN_NAME = 3
CTOKEN_NUMBER = 4
CTOKEN_STRING = 5
CTOKEN_SPECIAL = 6
CTOKEN_OPERATOR = 7
CTOKEN_INDENT = 8
CTOKEN_DEDENT = 9
CTOKEN_OTHER = 10


#----------------------------------------------------------------------
# token name: int <-> string
#----------------------------------------------------------------------
token_register = {}

for name, value in list(globals().items()):
    if isinstance(value, int):
        if not name.startswith('_'):
            if name.isupper():
                token_register[value] = name
                token_register[name] = value

__all__.extend(filter(lambda n: isinstance(n, str), token_register))


