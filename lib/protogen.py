#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# EventBuilder.py - generate events
#
# Created by skywind on 2023/10/24
# Last Modified: 2023/10/31 16:12
#
#======================================================================
import sys
import os
import re
import time

from enum import Enum, IntEnum


#----------------------------------------------------------------------
# Property Types
#----------------------------------------------------------------------
T_U8 = 0
T_I8 = 1
T_U16 = 2
T_I16 = 3
T_U32 = 4
T_I32 = 5
T_U64 = 6
T_I64 = 7
T_FLOAT = 8
T_DOUBLE = 9
T_STRING = 10
T_ARRAY = 11
T_MAP = 12


#----------------------------------------------------------------------
# Type Names
#----------------------------------------------------------------------
TypeName: dict[int, str] = {
        T_U8: 'uint8', T_I8: 'int8',
        T_U16: 'uint16', T_I16: 'int16',
        T_U32: 'uint32', T_I32: 'int32',
        T_U64: 'uint64', T_I64: 'int64',
        T_FLOAT: 'float', T_DOUBLE: 'double',
        T_STRING: 'string', T_ARRAY: 'array', T_MAP: 'map',
}

NameType: dict[str, int] = { TypeName[key]: key for key in TypeName }


if 0:
    for key in NameType:
        print(key, NameType[key])


#----------------------------------------------------------------------
# PacketProperty
#----------------------------------------------------------------------
class PacketProperty (object):

    def __init__ (self, name: str, proptype: int):
        self.name: str = name
        self.type: int = proptype
        self.element_type = None
        self.key_type = None
        self.value_type = None
        self.default = None
        self.comment: str = ''

    def __str__ (self):
        return 'PacketProperty(%s, %s)'%(self.name, self.type_name())

    def type_name (self):
        tname = TypeName[self.type]
        if self.type == T_ARRAY:
            if self.element_type:
                t = TypeName[self.element_type]
                tname = '%s<%s>'%(tname, t)
        elif self.type == T_MAP:
            if self.key_type and self.value_type:
                t1 = TypeName[self.key_type]
                t2 = TypeName[self.value_type]
                tname = '%s<%s,%s>'%(tname, t1, t2)
        return tname

    def is_pod (self):
        if self.type in (T_MAP, T_ARRAY):
            return False
        return True


#----------------------------------------------------------------------
# PacketDefinition
#----------------------------------------------------------------------
class PacketDefinition (object):

    def __init__ (self, name):
        self.name = name
        self.property: list[PacketProperty] = []
        self.comments: list[str] = []
        self.lnum = 0

    def append (self, property: PacketProperty):
        self.property.append(property)

    def __len__ (self):
        return len(self.property)

    def __getitem__ (self, index):
        return self.property.__getitem__(index)

    def __iter__ (self):
        return self.property.__iter__()

    def __str__ (self):
        return 'PacketDefinition(%s)'%self.name


#----------------------------------------------------------------------
# Token: (name, value, line, column)
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
        if callable(name):
            if kind not in extended:
                obj = name(value)
            else:
                obj = name(value, extended[kind])
            name = None
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
# patterns
#----------------------------------------------------------------------
PATTERN_WHITESPACE = r'[ \t\r\n]+'
PATTERN_COMMENT1 = r'[#].*'
PATTERN_COMMENT2 = r'[;].*'
PATTERN_COMMENT3 = r'\/\/.*'
PATTERN_NAME = r'\w+'
PATTERN_STRING1 = r"'(?:\\.|[^'\\])*'"
PATTERN_STRING2 = r'"(?:\\.|[^"\\])*"'
PATTERN_NUMBER = r'\d+(\.\d*)?'
PATTERN_CINTEGER = r'(0x)?\d+[uUlLbB]*'
PATTERN_OPERATOR = r'[\+\-\*\/\?\%\=]'
PATTERN_MISMATCH = r'.'


#----------------------------------------------------------------------
# split text 
#----------------------------------------------------------------------
def tokenize(code) -> list[Token]:
    keywords = {'packet': 'PACKET'}
    def check_keyword(what):
        if what in keywords:
            return keywords[what]
        if what in NameType:
            return 'TYPE'
        return 'NAME'
    rules = [
            (None, PATTERN_WHITESPACE),   # ignore white spaces
            ('COMMENT', PATTERN_COMMENT1),
            ('COMMENT', PATTERN_COMMENT2),
            ('COMMENT', PATTERN_COMMENT3),
            ('STRING', PATTERN_STRING1),
            ('STRING', PATTERN_STRING2),
            ('INTEGER', PATTERN_CINTEGER),
            ('NUMBER', PATTERN_NUMBER),
            (check_keyword, PATTERN_NAME),
            (':', r'[\:]'),
            ('=', r'[\=]'),
            ('<', r'[\<]'),
            ('>', r'[\>]'),
            ('@', r'[\@]'),
            ('MISMATCH', PATTERN_MISMATCH),
    ]
    tokens = []
    for t in _tokenize(code, rules):
        token = Token(t[0], t[1], t[2], t[3])
        tokens.append(token)
    return tokens


#----------------------------------------------------------------------
# load file text
#----------------------------------------------------------------------
def load_file_text (filename, encoding = None):
    content = open(filename, 'rb').read()
    if content is None:
        return None
    if content[:3] == b'\xef\xbb\xbf':
        text = content[3:].decode('utf-8')
    elif encoding is not None:
        text = content.decode(encoding, 'ignore')
    else:
        text = None
        guess = [sys.getdefaultencoding(), 'utf-8']
        if sys.stdout and sys.stdout.encoding:
            guess.append(sys.stdout.encoding)
        try:
            import locale
            guess.append(locale.getpreferredencoding())
        except:
            pass
        visit = {}
        for name in guess + ['gbk', 'ascii', 'latin1']:
            if name in visit:
                continue
            visit[name] = 1
            try:
                text = content.decode(name)
                break
            except:
                pass
        if text is None:
            text = content.decode('utf-8', 'ignore')
    return text


#----------------------------------------------------------------------
# load spec
#----------------------------------------------------------------------
class SpecParser (object):

    def __init__ (self, filename):
        self.filename = os.path.abspath(filename)
        self.code = load_file_text(filename)
        self.comments = []
        self.packets: list[PacketDefinition] = []
        self.packet_name = None
        self.packet_prop = []
        self.packet_mid = 0
        self.packet_lnum = -1
        self.line_num = 0
        self.inline = {}
        self._parse_main(self.code)

    def errmsg (self, *args):
        t = self.filename and 'error:%s:'%self.filename or 'error:'
        t += '%d: %s'%(self.line_num, ' '.join([str(n) for n in args]))
        sys.stderr.write(t + '\n')
        return 0

    def abort (self, *args):
        self.errmsg(*args)
        sys.exit(1)
        return 1

    def push_definition (self):
        if self.packet_name:
            packet = PacketDefinition(self.packet_name)
            for p in self.packet_prop:
                packet.append(p)
            packet.mid = self.packet_mid
            packet.lnum = self.packet_lnum
            packet.comments = self.packet_comment
            self.packets.append(packet)
        self.packet_name = None
        self.packet_prop = []
        self.packet_mid = 0
        self.packet_comment = []
        return 0

    def push_property (self, prop: PacketProperty):
        self.packet_prop.append(prop)

    def push_inline (self, lang: str, code: str):
        if lang not in self.inline:
            self.inline[lang] = {}
        self.inline[lang][self.line_num] = code
        # print('inline %s: %s'%(lang, code))
        return 0

    def dump_inline (self, lang: str) -> dict[int, str]:
        inline = {}
        if lang not in self.inline:
            return inline
        source = self.inline[lang]
        for key in source:
            inline[key] = source[key]
        return inline

    def _parse_main (self, code: str):
        self.line_num = 0
        retval = 0
        state = 0
        mlang = ''
        for line in code.split('\n'):
            line = line.rstrip('\r\n\t ')
            self.line_num += 1
            if state == 0:
                if not line:
                    self.comments = []
                    continue
                mark = line.lstrip('\r\n\t ')
                if mark.startswith('#') or mark.startswith(';'):
                    self.comments.append(line)
                    continue
                if mark.startswith('@'):
                    m = re.search(r'^\s*\@\s*(\w+)\s+(.*)$', line)
                    if m:
                        lang = m.group(1)
                        code = m.group(2)
                        self.push_inline(lang, code)
                    continue
                if mark.startswith('```'):
                    m = re.search(r'^\s*\`\`\`\s*(\w*)\s*$', line)
                    if m:
                        mlang = m.group(1)
                        state = 1
                    else:
                        self.abort('bad code block syntax')
                        retval = -41
                        break
                    if not mlang:
                        self.abort('code block requires language name, like "```cpp"')
                        retval = -42
                        break
                    continue
                tokens = tokenize(line)
                if not tokens:
                    continue
                if tokens[0].name == 'PACKET':
                    self.push_definition()
                    if self._parse_definition(tokens) != 0:
                        retval = -1
                        break
                else:
                    retval = 0
                    if self._parse_property(tokens) != 0:
                        retval = -2
                        break
            else:
                mark = line.strip('\r\n\t ')
                if mark == '```':
                    state = 0
                    mlang = ''
                    continue
                self.push_inline(mlang, line)
        self.push_definition()
        return retval

    def _parse_definition (self, tokens: list[Token]):
        if tokens[0].name != 'PACKET':
            self.abort('bad packet head')
            return -1
        comment = None
        if tokens[-1].name == 'COMMENT':
            comment = tokens[-1].value
            tokens = tokens[:-1]
        if len(tokens) < 2:
            self.abort('expecting packet name')
            return -2
        if tokens[1].name != 'NAME':
            self.abort('expecting packet name')
            return -3
        packet_name = tokens[1].value
        packet_mid = None
        if len(tokens) >= 4:
            if tokens[2].name == '=':
                if tokens[3].name != 'INTEGER':
                    self.abort('message id must be an integer')
                    return -4
                packet_mid = tokens[3].value
        if tokens[-1].name != ':':
            self.abort('expecting colon')
            return -5
        self.packet_name = packet_name
        self.packet_mid = packet_mid
        self.packet_lnum = self.line_num
        self.packet_comment = []
        if self.comments:
            for n in self.comments:
                self.packet_comment.append(n)
        if comment:
            self.packet_comment.append(comment)
        return 0

    def _parse_array (self, p:PacketProperty, tokens: list[Token]) -> int:
        if len(tokens) < 2:
            self.abort('bad array syntax, use array<type> to declare an array')
            return -1
        if tokens[1].name != '<':
            self.abort('expecting array type, use array<type> to declare an array')
            return -2
        if len(tokens) < 5:
            self.abort('bad array syntax, use array<type> to declare an array')
            return -3
        if tokens[3].name != '>':
            self.abort('bad array syntax, use array<type> to declare an array')
            return -4
        element_type = tokens[2].value
        if element_type not in NameType:
            self.abort('bad array type:', element_type)
            return -5
        p.element_type = NameType[element_type]
        p.name = tokens[4].value
        p.type = T_ARRAY
        return 0

    def _parse_map (self, p: PacketProperty, tokens: list[Token]) -> int:
        if len(tokens) < 2:
            self.abort('bad map syntax, use map<type,type> to declare an map')
            return -1
        if tokens[1].name != '<':
            self.abort('expecting map type, use map<type,type> to declare an map')
            return -2
        if len(tokens) < 7:
            self.abort('bad map syntax, use map<type,type> to declare an map')
            return -3
        if tokens[5].name != '>':
            self.abort('bad map syntax, use map<type,type> to declare an map')
            return -4
        if tokens[2].name != 'TYPE':
            self.abort('expecting key type, not', tokens[2].value)
            return -5
        if tokens[4].name != 'TYPE':
            self.abort('expecting value type, not', tokens[4].value)
            return -6
        if tokens[6].name not in ('NAME', 'TYPE', 'PACKET'):
            self.abort('expecting property name, not', tokens[6].value)
            return -7
        p.name = tokens[6].value
        p.type = T_MAP
        key_type = tokens[2].value
        value_type = tokens[4].value
        if key_type not in NameType:
            self.abort('bad map key type:', key_type)
            return -8
        if value_type not in NameType:
            self.abort('bad map value type', value_type)
            return -9
        p.key_type = NameType[key_type]
        p.value_type = NameType[value_type]
        return 0

    def _parse_property (self, tokens: list[Token]) -> int:
        if tokens[0].name != 'TYPE':
            self.abort('bad property type')
            return -1
        comment = None
        if tokens[-1].name == 'COMMENT':
            comment = tokens[-1].value  # noqa
            tokens = tokens[:-1]
        proptype = tokens[0].value  # noqa
        if proptype not in NameType:
            self.abort('bad type name:', proptype)
            return -2
        p = PacketProperty('', NameType[proptype])
        if proptype == 'array':
            hr = self._parse_array(p, tokens)
            if hr != 0:
                return -10 + hr
        elif proptype == 'map':
            hr = self._parse_map(p, tokens)
            if hr != 0:
                return -20 + hr
        else:
            p.comment = comment
            if len(tokens) < 2:
                self.abort('bad property syntax, use "type name" to add property')
                return -31
            if tokens[1].name not in ('NAME', 'TYPE', 'PACKET'):
                self.abort('expecting property name, not', tokens[1].value)
                return -32
            p.name = tokens[1].value
            p.default = None
            if len(tokens) >= 4:
                if tokens[2].name == '=':
                    p.default = self._normalize(tokens[3])
        p.comment = comment
        self.push_property(p)
        return 0

    def _normalize (self, token: Token) -> str:
        if token.name != 'STRING':
            return token.value
        try:
            s = eval(token.value)
        except:
            self.abort('bad string syntax')
            return None
        p = s.replace('\\', '\\\\').replace('"', '\\"').replace("'", "\\'")
        p = p.replace("\n", '\\n').replace("\t", '\\t').replace('\r', '\\r')
        return '"%s"'%p


#----------------------------------------------------------------------
# Generator
#----------------------------------------------------------------------
class SpecGenerator (object):

    def __init__ (self, sp: SpecParser, lang: str, extname: str):
        self.sp: SpecParser = sp
        self.lang = lang
        self.stdout = False
        self.outname = os.path.splitext(self.sp.filename)[0] + extname
        self._output: list[str] = []
        self._inline: dict[int, str] = {}
        self.indent: str = ''
        self.timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
        self.reset()

    def reset (self):
        self._output.clear()
        self._inline.clear()
        cache = self.sp.inline.get(self.lang, {})
        for lnum in cache:
            self._inline[lnum] = cache[lnum]
        return 0

    def errmsg (self, *args):
        t = ' '.join([str(n) for n in args])
        sys.stderr.write('error: ' + t + '\n')
        return 0

    def abort (self, *args):
        self.errmsg(*args)
        os.abort(2)
        return 0

    def output (self, *args):
        t = ' '.join([str(n) for n in args])
        self._output.append(self.indent + t)
        if self.stdout:
            print(self.indent + t)
        return 0

    def save (self, filename = None):
        fp = open(filename and filename or self.outname, 'w')
        for t in self._output:
            fp.write(t + '\n')
        fp.close()
        return 0

    def print (self):
        for t in self._output:
            print(t)
        return 0

    def inline_dump (self, before_lnum: int):
        lnums = []
        for lnum in self._inline:
            if lnum < before_lnum or before_lnum < 0:
                lnums.append(lnum)
        lnums.sort()
        for lnum in lnums:
            self.output(self._inline[lnum])
            del self._inline[lnum]
        return 0

    def format_output (self, code_comment):
        maxwidth = 0
        for code, _ in code_comment:
            maxwidth = max(maxwidth, len(code))
        for code, comment in code_comment:
            t = code + (' ' * (maxwidth - len(code)))
            c = comment and ('    ' + comment) or ''
            self.output(t + c)
        return 0

    def segment_init (self, maxwidth, indent):
        self._segment_cache = ''
        self._segment_width = maxwidth
        self._segment_indent = indent
        return 0

    def segment_push (self, text):
        if len(text) + len(self._segment_cache) >= self._segment_width:
            self.output(self._segment_cache)
            self._segment_cache = self._segment_indent + text
        else:
            self._segment_cache += text
        return 0

    def segment_done (self):
        self.output(self._segment_cache)
        self._segment_cache = ''
        return 0


#----------------------------------------------------------------------
# GeneratorCpp
#----------------------------------------------------------------------
class GeneratorCpp (SpecGenerator):

    def __init__ (self, sp: SpecParser):
        super().__init__ (sp, 'cpp', '.h')
        self.inittypes()
        self.generate()

    def inittypes (self):
        self.typenames = {}
        for ti in TypeName:
            tn = TypeName[ti]
            if tn == 'map':
                self.typenames[ti] = 'std::map'
            elif tn == 'array':
                self.typenames[ti] = 'std::vector'
            elif tn == 'string':
                self.typenames[ti] = 'std::string'
            elif tn[0] in ('u', 'i'):
                self.typenames[ti] = tn + '_t'
            else:
                self.typenames[ti] = tn
        # print(self.typenames)
        return 0

    def generate (self):
        self.generate_head()
        self.generate_body()
        self.inline_dump(-1)
        self.output('')
        self.output('')
        return 0

    def generate_head (self):
        outname = os.path.basename(self.outname)
        self.output('//' + ('=' * 70))
        self.output('//')
        self.output('// %s - Protocol Definition'%outname)
        self.output('//')
        self.output('// Note: this file is generated by protogen.py !')
        self.output('// Created time: %s'%self.timestamp)
        self.output('//')
        self.output('//' + ('=' * 70))
        self.output('#pragma once')
        self.output('')
        self.output('#include <stddef.h>')
        self.output('#include <stdint.h>')
        self.output('#include <string.h>')
        self.output('')
        return 0

    def generate_body (self):
        sp: SpecParser = self.sp
        for packet in sp.packets:
            lnum = packet.lnum
            self.inline_dump(lnum)
            self.output('')
            self.generate_packet(packet)
        self.output('')
        return 0

    def typename (self, prop: PacketProperty, change = False) -> str:
        tname = self.typenames[prop.type]
        if prop.type == T_ARRAY:
            t1 = self.typenames[prop.element_type]
            return 'std::vector<%s>'%t1
        if prop.type == T_MAP:
            t1 = self.typenames[prop.key_type]
            t2 = self.typenames[prop.value_type]
            return 'std::map<%s, %s>'%(t1, t2)
        if prop.type == T_STRING:
            return change and 'const char*' or 'std::string'
        return tname

    def default (self, prop):
        if prop.default:
            return prop.default
        if prop.type == T_STRING:
            return '""'
        if prop.type == T_FLOAT:
            return '0.0f'
        if prop.type == T_DOUBLE:
            return '0.0'
        return '0'

    def generate_packet (self, packet: PacketDefinition):
        if packet.comments:
            self.output('//' + ('-' * 70))
            for c in packet.comments:
                self.output('//' + c[1:])
            self.output('//' + ('-' * 70))
        self.output('struct %s : public System::Marshallable {'%packet.name)
        self.indent = '\t'
        self.output('enum { MID = %s };'%packet.mid)
        self.output('')
        output = []
        for prop in packet.property:
            tname = self.typename(prop)
            comment = prop.comment and '//' + prop.comment[1:] or ''
            first = '%s %s;'%(tname, prop.name)
            # if prop.default:
            #     first = '%s %s = %s;'%(tname, prop.name, prop.default)
            output.append([first, comment])
        if output:
            self.format_output(output)
            self.output('')
        # self.generate_list(packet)
        self.generate_ctor(packet)
        self.generate_marshal(packet)
        self.generate_unmarshal(packet)
        self.generate_to_string(packet)
        self.indent = ''
        self.output('};')
        self.output('')
        return 0

    def generate_ctor (self, packet: PacketDefinition):
        self.segment_init(70, '\t')
        self.segment_push('%s('%packet.name)
        pending = []
        for prop in packet.property:
            if not prop.is_pod():
                continue
            t = self.typename(prop, True)
            d = self.default(prop)
            t = '%s %s = %s'%(t, prop.name, d)
            pending.append(t)
        for index, t in enumerate(pending):
            if index < len(pending) - 1:
                t += ', '
            self.segment_push(t)
        self.segment_push(') {')
        self.segment_done()
        for prop in packet.property:
            if not prop.is_pod():
                continue
            self.output('\tthis->%s = %s;'%(prop.name, prop.name))
        self.output('}')
        self.output('')
        return 0

    def generate_marshal (self, packet: PacketDefinition):
        self.output('void marshal(System::ByteArray &_output_ba) const {')
        self.indent = '\t\t'
        self.output('_output_ba << ((unsigned short)MID);')
        self.segment_init(70, '\t')
        reserve = '_output_ba'
        for index, prop in enumerate(packet.property):
            name = prop.name == reserve and 'this->' + reserve or prop.name
            t = '<< %s'%name
            if index == 0:
                t = '_output_ba ' + t
            if index + 1 >= len(packet.property):
                t += ';'
            else:
                t += ' '
            self.segment_push(t)
        self.segment_done()
        self.indent = '\t'
        self.output('}')
        self.output('')
        return 0

    def generate_unmarshal (self, packet: PacketDefinition):
        self.output('void unmarshal(System::ByteArray &_input_ba) {')
        self.indent = '\t\t'
        self.output('if (_input_ba.read_uint16() != MID) {')
        t = packet.name
        self.output('\tthrow System::ByteError("%s: message type mismatch");'%t)
        self.output('}')
        self.segment_init(70, '\t')
        reserve = '_input_ba'
        for index, prop in enumerate(packet.property):
            name = prop.name == reserve and 'this->' + reserve or prop.name
            t = '>> %s'%name
            if index == 0:
                t = '_input_ba ' + t
            if index + 1 >= len(packet.property):
                t += ';'
            else:
                t += ' '
            self.segment_push(t)
        self.segment_done()
        self.indent = '\t'
        self.output('}')
        self.output('')
        return 0

    def generate_to_string (self, packet: PacketDefinition):
        self.output('std::string to_string() const {')
        self.indent = '\t\t'
        self.output('std::stringstream _out_string;')
        self.segment_init(70, '\t')
        reserve = '_out_string'
        self.segment_push('_out_string << "%s(" '%packet.name)
        for index, prop in enumerate(packet.property):
            name = prop.name == reserve and 'this->' + reserve or prop.name
            if prop.is_pod():
                t = '<< ' + name
            elif prop.type == T_ARRAY:
                t = '<< System::ArrayToString(' + name + ')'
            else:
                t = '<< System::MapToString(' + name + ')'
            if index != 0:
                t = '<< ", " ' + t
            if index + 1 >= len(packet.property):
                pass
            else:
                t += ' '
            self.segment_push(t)
        self.segment_push(' << ")";')
        self.segment_done()
        self.output('return _out_string.str();')
        self.indent = '\t'
        self.output('}')
        return 0


#----------------------------------------------------------------------
# main entry
#----------------------------------------------------------------------
def main(argv = None):
    argv = argv and argv or sys.argv
    argv = [n for n in argv]
    if len(argv) < 2:
        print('usage: python protogen.py <spec>')
        print('')
        return 0
    filename = argv[1]
    sp = SpecParser(filename)
    GeneratorCpp(sp).save()
    return 0


#----------------------------------------------------------------------
# testing suit
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        sp = SpecParser('events.fmt')
        for packet in sp.packets:
            print(packet)
            for p in packet:
                print('   ', p, p.default, p.comment)
            print()
        return 0
    def test2():
        sp = SpecParser('events.fmt')
        gc = GeneratorCpp(sp)
        gc.print()
        return 0
    def test3():
        sp = SpecParser('events2.fmt')
        gc = GeneratorCpp(sp)
        gc.print()
        return 0

    # test3()
    main()





