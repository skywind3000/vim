#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# ctoken_pygments.py - 
#
# Created by skywind on 2022/12/27
# Last Modified: 2022/12/27 18:07:46
#
#======================================================================
import pygments
import pygments.token
import pygments.lexers

from pygments.token import Token

try:
    from . import ctoken
    from . import ctoken_reader
    from . import ctoken_type
    from .ctoken_type import *
except:
    import ctoken
    import ctoken_reader
    import ctoken_type
    from ctoken_type import *



#----------------------------------------------------------------------
# ignore token type
#----------------------------------------------------------------------
_ignore_types = [
            Token.Text.Whitespace,
            Token.Comment.Multiline,
            Token.Comment.Single,
            Token.Comment.count
        ]


#----------------------------------------------------------------------
# translate type
#----------------------------------------------------------------------
_translate_types = {
            # Token.
            Token.Keyword: CTOKEN_KEYWORD,

        }


#----------------------------------------------------------------------
# get pygments tokens
#----------------------------------------------------------------------
def pygments_get_tokens(source, lang = 'cpp'):
    import pygments
    import pygments.lexers
    lexer = pygments.lexers.get_lexer_by_name(lang)
    if isinstance(source, str):
        code = source
    else:
        code = source.read()
    tokens = []
    lnum = 1
    column = 1
    for token in lexer.get_tokens(code):
        start = (lnum, column)
        text = token[1]
        if '\n' not in text:
            column += len(text)
            endup = (lnum, column)
        else:
            lines = text.split('\n')
            lnum += len(lines) - 1
            column = len(lines[-1]) + 1
            endup = (lnum, column)
        t = (token[0], token[1], start, endup)
        tokens.append(t)
    return tokens


#----------------------------------------------------------------------
# check token is target
#----------------------------------------------------------------------
def token_is(token, target) -> bool:
    if token == target:
        return True
    if token in target:
        return True
    return False


#----------------------------------------------------------------------
# cursor 
#----------------------------------------------------------------------
def cursor_in_token(token, lnum: int, column: int) -> bool:
    start = token[2]
    endup = token[3]
    if lnum < start[0] or lnum > endup[0]:
        return False
    elif start[0] == endup[0]:
        if lnum == start[0]:
            if start[1] <= column < endup[1]:
                return True
        return False
    elif lnum == start[0]:
        return (column >= start[1])
    elif lnum == endup[0]:
        return (column < endup[1])
    return True


#----------------------------------------------------------------------
# find token
#----------------------------------------------------------------------
def token_locate(tokens, lnum: int, column: int) -> int:
    if len(tokens) <= 0:
        return -1
    for index, token in enumerate(tokens):
        if cursor_in_token(token, lnum, column):
            return index
    return -1


#----------------------------------------------------------------------
# pygments_tokens -> ctoken list
#----------------------------------------------------------------------
def translate(pygments_tokens):
    tokens = []
    reader = ctoken_reader.TokenReader(pygments_tokens)
    while not reader.is_eof():
        if reader.current is None:
            break
        if reader.current[0] in Token.String:
            text = ''
            while reader.current[0] in Token.String:
                text += reader.current[1]
                reader.advance(1)
            token = ctoken.Token(CTOKEN_STRING, text, None, None)
            tokens.append(token)
        elif reader.current[0] in Token.Keyword:
            token = ctoken.Token(CTOKEN_KEYWORD, reader.current[1], None, None)
            tokens.append(token)
        elif reader.current[0]: 
            pass
    return tokens


#----------------------------------------------------------------------
# testing suit
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        f = 'e:/lab/workshop/language/test_tok.cpp'
        tokens = pygments_get_tokens(open(f), 'cpp')
        for t in tokens:
            print(t)
            # print(dir(t))
        print('')
        index = token_locate(tokens, 17, 17)
        print(tokens[index])
        return 0
    test1()


