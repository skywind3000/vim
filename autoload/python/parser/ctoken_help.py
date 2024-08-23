#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# ctoken_help.py - 
#
# Created by skywind on 2022/12/27
# Last Modified: 2022/12/27 17:31:10
#
#======================================================================
import sys
import json

try:
    from . import ctoken
except:
    import ctoken



#----------------------------------------------------------------------
# json -> token
#----------------------------------------------------------------------
def loads(text):
    if isinstance(text, str):
        obj = json.loads(text)
    elif isinstance(text, list):
        obj = text
    else:
        raise TypeError('require list or json list')
    if len(obj) < 1:
        raise ValueError('empty list')
    name, value, line, column = obj[0], None, None, None
    if len(obj) >= 2: value = obj[1]
    if len(obj) >= 3: line = obj[2]
    if len(obj) >= 4: column = obj[3]
    if isinstance(name, str):
        if name not in ctoken.token_register:
            raise NameError('bad token name: ' + name)
        return ctoken.Token(ctoken.token_register[name], value, line, column)
    return ctoken.Token(name, value, line, column)


#----------------------------------------------------------------------
# token -> json
#----------------------------------------------------------------------
def dumps(token):
    name = ctoken.token_register[token.name]
    obj = [name, token.value, token.line, token.column]
    return json.dumps(obj)


#----------------------------------------------------------------------
# load token list from json
#----------------------------------------------------------------------
def list_loads(text):
    tokens = []
    for n in text.split("\n"):
        n = n.strip()
        t = loads(n)
        tokens.append(t)
    return tokens


#----------------------------------------------------------------------
# token list dump to json
#----------------------------------------------------------------------
def list_dumps(tokens):
    objs = []
    for token in tokens:
        objs.append(dumps(token))
    return '\n'.join(objs)



#----------------------------------------------------------------------
# print token or token list
#----------------------------------------------------------------------
def pprint(obj):
    if isinstance(obj, ctoken.Token):
        print(obj)
        return 0
    for token in obj:
        print(token)
    return 0


#----------------------------------------------------------------------
# simplify token list
#----------------------------------------------------------------------
def simplify(tokens):
    output = []
    for token in tokens:
        # print(token)
        if token.name == ctoken.NUMBER:
            text = token.value
            if '.' in text:
                output.append(float(text))
            else:
                output.append(int(text, 0))
        elif token.name in (ctoken.KEYWORD, ctoken.NAME, ctoken.OPERATOR):
            output.append(token.value)
        elif token.name in (ctoken.SPECIAL, ctoken.STRING):
            output.append(token.value)
    return output


#----------------------------------------------------------------------
# 
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        t1 = ctoken.Token(ctoken.NUMBER, '10', 10, 20)
        t2 = ctoken.Token(ctoken.OPERATOR, '+', 10, 20)
        t3 = ctoken.Token(ctoken.NUMBER, '20', 10, 20)
        tokens = (t1, t2, t3)
        print(list_dumps(tokens))
        pprint(list_loads(list_dumps(tokens)))
        print(simplify(tokens))
        # install('KKK', 99)
        # print(ctoken.token_register)
        return 0
    def test2():
        t = ctoken.Token('NUMBER', 12)
        print(t)
        print(repr(t))
    test2()



