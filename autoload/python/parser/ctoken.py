#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# ctoken.py - token definition
#
# Created by skywind on 2011/12/26
# Last Modified: 2015/07/12 14:41:18
#
#======================================================================


#----------------------------------------------------------------------
# exports
#----------------------------------------------------------------------
__all__ = ['Token']



#----------------------------------------------------------------------
# Token: (name, value, line, column)
# name represents token type, since "type" is a reserved word in 
# python, choose "name" instead
#----------------------------------------------------------------------
class Token (object):

    def __init__ (self, name, value, line = 0, column = 0):
        self.name = name
        self.value = value
        self.line = line
        self.column = column

    def __str__ (self):
        if self.line is None:
            return '(%s, %s)'%(self.name, self.value)
        t = (self.name, self.value, self.line, self.column)
        return '(%s, %s, %s, %s)'%t

    def __repr__ (self):
        n = type(self).__name__
        if self.line is None:
            return '%s(%r, %r)'%(n, self.name, self.value)
        t = (n, self.name, self.value, self.line, self.column)
        return '%s(%r, %r, %r, %r)'%t

    def __copy__ (self):
        return Token(self.name, self.value, self.line, self.column)


#----------------------------------------------------------------------
# testing case
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        print(repr(Token))
        token = Token('KEYWORD', 'if', 10, 20)
        print(token)
        print(repr(token))
        token = Token('NAME', 'x')
        print(token)
        print(repr(token))
        token.line = None
        print(token)
        print(repr(token))
        return 0
    test1()



