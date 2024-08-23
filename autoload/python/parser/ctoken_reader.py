#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# ctoken_reader.py - token reader (supports PEG parsers)
#
# Created by skywind on 2022/12/27
# Last Modified: 2022/12/27 19:34:35
#
#======================================================================
try:
    from . import ctoken
except:
    import ctoken


#----------------------------------------------------------------------
# TokenReader
#----------------------------------------------------------------------
class TokenReader (object):

    def __init__ (self, source):
        self.it = iter(source)
        self.tokens = []
        self.pos = 0
        self.eof = False

    def mark (self):
        return self.pos

    def reset (self, pos):
        self.pos = pos

    def peek (self):
        while len(self.tokens) <= self.pos:
            if self.eof:
                break
            try:
                token = next(self.it)
                self.tokens.append(token)
            except StopIteration:
                self.eof = True
        if self.pos >= len(self.tokens):
            return None
        return self.tokens[self.pos]

    def read (self):
        token = self.peek()
        if not self.eof:
            self.pos += 1
        return token

    def is_eof (self):
        return self.eof

    def __check_current (self, what):
        token = self.peek()
        if token is None:
            return (what is None) and True or False
        if isinstance(what, list) or isinstance(what, tuple):
            if len(what) < 2:
                return False
            if token.name == what[0] and token.value == what[1]:
                return True
        elif token.name == what:
            return True
        elif token.value == what:
            return True
        return False

    def check (self, *args):
        for arg in args:
            if self.__check_current(arg):
                return True
        return False

    def name (self):
        token = self.peek()
        if token is None:
            return None
        return token.name

    def value (self):
        token = self.peek()
        if token is None:
            return None
        return token.value

    def expect (self, what):
        if what is None:
            if self.peek() is None:
                return self.read()
        if self.peek() is None:
            raise ValueError('current token is None')
        if self.__check_current(what):
            return self.read()
        raise ValueError('expecting %s'%(str(what),))

    def __iter__ (self):
        return self

    def __next__ (self):
        token = self.read()
        if self.eof and token is None:
            raise StopIteration()
        return token


#----------------------------------------------------------------------
# testing suit
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        ts = TokenReader([1,2,3,4,5])
        ts.read()
        ts.read()
        print(ts.peek())
        ts.reset(0)
        print(ts.peek())
        print(list(TokenReader([7,5,3,1,2,3])))
        return 0
    test1()


