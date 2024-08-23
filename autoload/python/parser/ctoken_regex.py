#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# ctoken_regex.py - 
#
# Created by skywind on 2023/01/05
# Last Modified: 2023/01/05 18:21:53
#
#======================================================================
import re

try:
    from . import ctoken
except:
    import ctoken


#----------------------------------------------------------------------
# tokenize
#----------------------------------------------------------------------
def _tokenize(code, specs, eof = None):
    patterns = []
    definition = {}
    extended = {}
    if not specs:
        return None
    for index in range(len(specs)):
        spec = specs[index]
        name, pattern = spec[:2]
        pn = 'PATTERN%d'%index
        definition[pn] = name
        if len(spec) >= 3:
            extended[pn] = spec[2]
        patterns.append((pn, pattern))
    tok_regex = '|'.join('(?P<%s>%s)' % pair for pair in patterns)
    line_starts = []
    pos = 0
    index = 0
    while 1:
        line_starts.append(pos)
        pos = code.find('\n', pos)
        if pos < 0:
            break
        pos += 1
    line_num = 0
    for mo in re.finditer(tok_regex, code):
        kind = mo.lastgroup
        value = mo.group()
        start = mo.start()
        while line_num < len(line_starts) - 1:
            if line_starts[line_num + 1] > start:
                break
            line_num += 1
        line_start = line_starts[line_num]
        name = definition[kind]
        if name is None:
            continue
        elif callable(name):
            if kind not in extended:
                obj = name(value)
            else:
                obj = name(value, extended[kind])
            name, value = None, None
            if isinstance(obj, list) or isinstance(obj, tuple):
                if len(obj) > 0: 
                    name = obj[0]
                if len(obj) > 1:
                    value = obj[1]
            else:
                name = obj
        yield (name, value, line_num + 1, start - line_start + 1)
    if eof is not None:
        line_start = line_starts[-1]
        endpos = len(code)
        yield (eof, '', len(line_starts), endpos - line_start + 1)
    return 0


#----------------------------------------------------------------------
# Tokenize
#----------------------------------------------------------------------
def tokenize(code, rules, eof = None):
    for info in _tokenize(code, rules, eof):
        yield ctoken.Token(info[0], info[1], info[2], info[3])
    return 0


#----------------------------------------------------------------------
# returns (line, column)
#----------------------------------------------------------------------
def extract_position(code, position):
    line_starts = []
    pos = 0
    while 1:
        line_starts.append(pos)
        pos = code.find('\n', pos)
        if pos < 0:
            break
        pos += 1
    index = 0
    size = len(line_starts)
    while index < size - 1:
        if line_starts[index + 1] > position:
            break
        index += 1
    column = position - line_starts[index] + 1
    return (index + 1, column)


#----------------------------------------------------------------------
# validate pattern
#----------------------------------------------------------------------
def validate_pattern(pattern):
    try:
        re.compile(pattern)
    except re.error:
        return False
    return True


#----------------------------------------------------------------------
# replace '{name}' in a pattern with the text in "macros[name]"
#----------------------------------------------------------------------
def regex_expand(macros, pattern, guarded = True):
    output = []
    pos = 0
    size = len(pattern)
    while pos < size:
        ch = pattern[pos]
        if ch == '\\':
            output.append(pattern[pos:pos + 2])
            pos += 2
            continue
        elif ch != '{':
            output.append(ch)
            pos += 1
            continue
        p2 = pattern.find('}', pos)
        if p2 < 0:
            output.append(ch)
            pos += 1
            continue
        p3 = p2 + 1
        name = pattern[pos + 1:p2].strip('\r\n\t ')
        if name == '':
            output.append(pattern[pos:p3])
            pos = p3
            continue
        elif name[0].isdigit():
            output.append(pattern[pos:p3])
            pos = p3
            continue
        elif ('<' in name) or ('>' in name):
            raise ValueError('invalid pattern name "%s"'%name)
        if name not in macros:
            raise ValueError('{%s} is undefined'%name)
        if guarded:
            output.append('(?:' + macros[name] + ')')
        else:
            output.append(macros[name])
        pos = p3
    return ''.join(output)


#----------------------------------------------------------------------
# build regex info
#----------------------------------------------------------------------
def regex_build(code, macros = None, capture = True):
    defined = {}
    if macros is not None:
        for k, v in macros.items():
            defined[k] = v
    line_num = 0
    for line in code.split('\n'):
        line_num += 1
        line = line.strip('\r\n\t ')
        if (not line) or line.startswith('#'):
            continue
        pos = line.find('=')
        if pos < 0:
            raise ValueError('%d: not a valid rule'%line_num)
        head = line[:pos].strip('\r\n\t ')
        body = line[pos + 1:].strip('\r\n\t ')
        if (not head):
            raise ValueError('%d: empty rule name'%line_num)
        elif head[0].isdigit():
            raise ValueError('%d: invalid rule name "%s"'%(line_num, head))
        elif ('<' in head) or ('>' in head):
            raise ValueError('%d: invalid rule name "%s"'%(line_num, head))
        try:
            pattern = regex_expand(defined, body, guarded = not capture)
        except ValueError as e:
            raise ValueError('%d: %s'%(line_num, str(e)))
        try:
            re.compile(pattern)
        except re.error:
            raise ValueError('%d: invalid pattern "%s"'%(line_num, pattern))
        if not capture:
            defined[head] = pattern
        else:
            defined[head] = '(?P<%s>%s)'%(head, pattern)
    return defined


#----------------------------------------------------------------------
# predefined patterns
#----------------------------------------------------------------------
PATTERN_WHITESPACE = r'[ \t\r\n]+'
PATTERN_COMMENT1 = r'[#].*'
PATTERN_COMMENT2 = r'\/\/.*'
PATTERN_COMMENT3 = r'\/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+\/'
PATTERN_MISMATCH = r'.'
PATTERN_NAME = r'\w+'
PATTERN_GNAME = r'\w(?:\w|\@)*[\']*'
PATTERN_STRING1 = r"'(?:\\.|[^'\\])*'"
PATTERN_STRING2 = r'"(?:\\.|[^"\\])*"'
PATTERN_NUMBER = r'\d+(\.\d*)?'
PATTERN_CINTEGER = r'(0x)?\d+[uUlLbB]*'
PATTERN_REPLACE = r'(?<!\\)\{\s*[a-zA-Z_]\w*\s*\}'
# PATTERN_CFLOAT = r'\d*(\.\d*)?f*'   # bad pattern, don't use
PATTERN_EPSILON = '\u03b5'
PATTERN_GMACRO = r'[%]\s*\w+'
PATTERN_OPERATOR = r'[\+\-\*\/\?\%]'



#----------------------------------------------------------------------
# test tokenizer
#----------------------------------------------------------------------
def test_tokenizer():
    source = '''
    IF name == 'haha' THEN 
        /*  * / haha
        this is a comment
        * / /*
         "hello"
        */
        haha1
        hahs2' haha3''
        hello % import 123
        foo@bar
        "hello world \\n \\\" ff1' haha"
        'suck world \\n \\\" ff1\\\' \\\' haha'
        print('TRUE')
    ENDIF
    '''
    patterns = [
                ('COMMENT1', PATTERN_COMMENT1),
                ('COMMENT2', PATTERN_COMMENT2),
                ('COMMENT3', PATTERN_COMMENT3),
                ('WHITESPACE', PATTERN_WHITESPACE),
                ('STRING', PATTERN_STRING1),
                ('STRING', PATTERN_STRING2),
                ('GNAME', PATTERN_GNAME),
                ('NAME', PATTERN_NAME),
                ('MACRO', PATTERN_GMACRO),
                # ('STRING2', TK_STRING2),
                ('MISMATCH', PATTERN_MISMATCH),
            ]
    for n in _tokenize(source, patterns):
        if n[0] != 'WHITESPACE':
            print(n)
        if n[0] == 'STRING':
            print(n[1])
    return 0



#----------------------------------------------------------------------
# test "regex_build()"
#----------------------------------------------------------------------
def test_regex_build():
    text = r'''
    digit = [0-9]
    digits = {digit}+
    optionalFraction = (?:\.{digits})?
    optionalExponent = (?:[eE][+-]?{digits})?
    number = {digits}{optionalFraction}{optionalExponent}
    '''
    m = regex_build(text)
    if isinstance(m, str):
        print(m)
        return 1
    for k, v in m.items():
        print(k, '=', v)
    number = m['number']
    print()
    print(number)
    print(re.match(number, '3.14E+10'))
    return 0


#----------------------------------------------------------------------
# test url
#----------------------------------------------------------------------
def test_regex_url():
    text = r'''
    protocol = http|https
    login_name = [^:@\r\n\t ]+
    login_pass = [^@\r\n\t ]+
    login = {login_name}(:{login_pass})?
    host = [^:/@\r\n\t ]+
    port = \d+
    optional_port = (?:[:]{port})?
    path = /[^\r\n\t ]*
    url = {protocol}://({login}[@])?{host}{optional_port}{path}?
    '''
    m = regex_build(text, capture = True)
    if isinstance(m, str):
        print(m)
        return 
    for k, v in m.items(): 
        print(k, '=', v)
    print()
    url = m['url']
    s = re.match(url, 'https://name:pass@www.baidu.com:8080/haha')
    print(s)
    for name in ('url', 'login_name', 'login_pass', 'host', 'port', 'path'):
        print(name, '=', s.group(name))
    return 0


#----------------------------------------------------------------------
# testing suit
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        token_specification = [
            (None, r'[ \t]+'),             # Skip over spaces and tabs
            (None, r'\n'),                 # Line endings
            (None, r'[#].*'),              # Skip comments
            ('NUMBER', r'\d+(\.\d*)?'),    # Integer or decimal number
            ('ASSIGN', r':='),             # Assignment operator
            ('END', r';'),                 # Statement terminator
            ('ID', r'[A-Za-z]+'),          # Identifiers
            ('OP', r'[+\-*/]'),            # Arithmetic operators
            ('MISMATCH', r'.'),            # Any other character
        ]
        statements = '''
            IF quantity THEN
                # this is a comment IF x THEN
                total := total + price * quantity;
                tax := price * 0.05;
            ENDIF;
        '''
        for token in tokenize(statements, token_specification):
            print(token)
        return 0
    def test2():
        test_tokenizer()
        return 0
    def test3():
        spec = [
                    (None, PATTERN_WHITESPACE),
                    ('STRING', PATTERN_STRING1),
                    (lambda n: ('NAME', n.upper()), PATTERN_NAME),
                ]
        code = '''
            x y hello
            * 123
            ---------
            foo
        '''
        for token in tokenize(code, spec, '$'):
            print(token)
        return 0
    def test4():
        # test_regex_build()
        test_regex_url()
        return 0
    test3()


