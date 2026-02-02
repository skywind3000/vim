#! /usr/bin/env python3
# -*- coding: utf-8 -*-
#======================================================================
#
# envrun.py - 
#
# Created by skywind on 2026/02/02
# Last Modified: 2026/02/02 20:08:46
#
#======================================================================
import sys
import os



#----------------------------------------------------------------------
# DotEnvParser
#----------------------------------------------------------------------
class DotEnvParser:

    def __init__ (self, init = None):
        self._environ = {}
        self._init = init and init or os.environ.copy()

    def _load_value (self, key, default = None):
        if key in self._environ:
            return self._environ[key]
        if key in self._init:
            return self._init[key]
        return default

    def __len__ (self):
        return len(self._environ)

    def __getitem__ (self, key, default = None):
        return self._environ.get(key, default)

    def __contains__ (self, key):
        return key in self._environ

    def __iter__ (self):
        return iter(self._environ)

    def _substitute_vars (self, value):
        start = 0
        while True:
            dollar_index = value.find('$', start)
            if dollar_index == -1:
                break
            if dollar_index + 1 >= len(value):
                break
            if value[dollar_index + 1] == '{':
                end_brace = value.find('}', dollar_index + 2)
                if end_brace == -1:
                    start = dollar_index + 1
                    continue
                var_name = value[dollar_index + 2:end_brace]
                var_value = self._load_value(var_name, '')
                value = value[:dollar_index] + var_value + value[end_brace + 1:]
                start = dollar_index + len(var_value)
            else:
                var_end = dollar_index + 1
                while var_end < len(value) and (value[var_end].isalnum() or value[var_end] == '_'):
                    var_end += 1
                var_name = value[dollar_index + 1:var_end]
                var_value = self._load_value(var_name, '')
                value = value[:dollar_index] + var_value + value[var_end:]
                start = dollar_index + len(var_value)
        value.replace('\x00', '$')
        return value

    def _escape_string (self, text):
        output = ''
        index = 0
        while index < len(text):
            ch = text[index]
            if ch == '\\' and index + 1 < len(text):
                next_ch = text[index + 1]
                if next_ch == 'n':
                    output += '\n'
                elif next_ch == 'r':
                    output += '\r'
                elif next_ch == 't':
                    output += '\t'
                elif next_ch == '\\':
                    output += '\\'
                elif next_ch == '"':
                    output += '"'
                elif next_ch == "'":
                    output += "'"
                elif next_ch == '$':
                    output += '\x00'
                else:
                    output += next_ch
                index += 2
            else:
                output += ch
                index += 1
        return output

    def _parse_line (self, line):
        line = line.strip('\r\n\t ')
        if not line:
            return ''
        if line.startswith('#'):
            return ''
        if '=' not in line:
            return ''
        key, _, value = line.partition('=')
        key = key.strip('\r\n\t ')
        if not key:
            return ''
        value = value.strip('\r\n\t ')
        if value.startswith('"') and value.endswith('"'):
            value = self._escape_string(value[1:-1])
        elif value.startswith("'") and value.endswith("'"):
            value = value[1:-1]
        value = self._substitute_vars(value)
        self._environ[key] = value
        return key


#----------------------------------------------------------------------
# testing suit
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        parser = DotEnvParser()
        parser._parse_line('KEY1=VALUE1')
        parser._parse_line('KEY2="VALUE2 with spaces"')
        parser._parse_line("KEY3='VALUE3 with single quotes'")
        parser._parse_line('KEY4=VALUE4_$KEY1')
        parser._parse_line('KEY5="VALUE5 with \\n new line"')
        assert parser['KEY1'] == 'VALUE1'
        assert parser['KEY2'] == 'VALUE2 with spaces'
        assert parser['KEY3'] == 'VALUE3 with single quotes'
        assert parser['KEY4'] == 'VALUE4_VALUE1'
        assert parser['KEY5'] == 'VALUE5 with \n new line'
        print("All tests passed.")
        return 0
    test1()

