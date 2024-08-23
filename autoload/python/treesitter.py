#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# treesitter.py - 
#
# Created by skywind on 2023/09/10
# Last Modified: 2023/09/10 02:08:29
#
#======================================================================
from __future__ import print_function, unicode_literals
import sys
import time
import os
import tree_sitter

from tree_sitter.binding import Node, Tree, Parser, Query, Range

try:
    import vim
    has_vim = True
except ImportError:
    has_vim = False


#----------------------------------------------------------------------
# internal
#----------------------------------------------------------------------
has_win32 = (sys.platform[:3] == 'win') and True or False
has_unix = (not has_win32)


#----------------------------------------------------------------------
# Configure: treesitter dll loading
#----------------------------------------------------------------------
class Configure (object):

    def __init__ (self):
        self.win32 = (sys.platform[:3] == 'win') and True or False
        self.has64 = (sys.maxsize > 2 ** 32) and True or False
        self.HOME = os.path.expanduser('~')
        self.__init_std_path()
        self.tslib = self.__search_parser_home()
        self.found = (self.tslib != '') and True or False
        self.__lang_cache = {}
        self.__parser_cache = {}
        self.error = ''

    def __init_std_path (self):
        t1 = os.path.normpath(self.HOME + '/.config')
        self.XDG_CONFIG_HOME = os.environ.get('XDG_CONFIG_HOME', t1)
        t2 = os.path.normpath(self.HOME + '/.local/share')
        self.XDG_DATA_HOME = os.environ.get('XDG_DATA_HOME', t2)
        t3 = os.path.normpath(self.HOME + '/.cache')
        self.XDG_CACHE_HOME = os.environ.get('XDG_CACHE_HOME', t3)
        self.APPDATA = self.XDG_DATA_HOME
        self.VIMHOME = os.path.normpath(self.HOME + '/.vim')
        self.NVIMDATA = os.path.join(self.XDG_DATA_HOME, 'nvim')
        if self.win32:
            t1 = os.path.join(self.XDG_DATA_HOME, 'Local')
            self.APPDATA = os.environ.get('APPDATA', t1)
            self.APPDATA = os.path.dirname(self.APPDATA)
            self.NVIMDATA = os.path.join(self.APPDATA, 'Local\\nvim-data')
        return 0

    def __search_parser_home (self):
        t0 = os.path.join(self.VIMHOME, 'lib/parser')
        t1 = t0 + (self.has64 and '/64' or '/32')
        t2 = os.path.join(self.NVIMDATA, 'lazy/nvim-treesitter/parser')    
        if self.win32:
            if os.path.exists(t1):
                return os.path.normpath(t1)
            if self.has64 and os.path.exists(t2):
                return os.path.normpath(t2)
        else:
            if os.path.exists(t1):
                return os.path.normpath(t1)
            if os.path.exists(t2):
                return os.path.normpath(t2)
        return ''

    def language (self, langname: str):
        if langname in self.__lang_cache:
            return self.__lang_cache[langname]
        if not self.tslib:
            raise RuntimeError('can not find treesitter parser home')
        t1 = os.path.join(self.tslib, langname + '.so')
        t2 = os.path.join(self.tslib, langname + '.dll')
        if self.win32 and os.path.exists(t2):
            lang = tree_sitter.Language(t2, langname)
        elif os.path.exists(t1):
            lang = tree_sitter.Language(t1, langname)
        else:
            raise RuntimeError('can not find parser dll for %s'%langname)
        self.__lang_cache[langname] = lang
        return lang

    def create_parser (self, langname: str) -> Parser:
        lang = self.language(langname)
        if not lang:
            raise RuntimeError('can not load dll for %s'%langname)
        parser = tree_sitter.Parser()
        parser.set_language(lang)
        return parser

    def parser (self, langname: str) -> Parser:
        if langname in self.__parser_cache:
            return self.__parser_cache[langname]
        parser = self.create_parser(langname)
        if parser:
            self.__parser_cache[langname] = parser
        return parser

    def check (self, langname: str) -> bool:
        try:
            lang = self.language(langname)  # noqa
            parser = self.parser(langname)  # noqa
        except RuntimeError as e:
            self.error = str(e)
            return False
        return True
        
    def get_parser (self, langname: str) -> Parser:
        try:
            parser = self.parser(langname)
            return parser
        except RuntimeError:
            pass
        return None

    def parse (self, langname, source) -> Tree:
        parser = self.get_parser(langname)
        if parser is None:
            return None
        if isinstance(source, str):
            code = source.encode('utf-8', errors = 'ignore')
        elif isinstance(source, bytes):
            code = source
        elif isinstance(source, list):
            text = '\n'.join(source)
            code = text.encode('utf-8', errors = 'ignore')
        else:
            return None
        tree: Tree = parser.parse(code)
        return tree

    def query (self, langname, query) -> Query:
        try:
            language = self.language(langname)
        except RuntimeError:
            return None
        return language.query(query)

    def source (self, source) -> list[str]:
        if isinstance(source, str):
            code: str = source
        elif isinstance(source, bytes):
            code: str = source.decode('utf-8', errors = 'ignore')
        elif isinstance(source, Tree):
            code: str = source.text.decode('utf-8', errors = 'ignore')
        elif isinstance(source, list):
            return source
        else:
            return None
        return code.split('\n')


#----------------------------------------------------------------------
# instance
#----------------------------------------------------------------------
config = Configure()


#----------------------------------------------------------------------
# Utils
#----------------------------------------------------------------------
class Utils (object):

    def __init__ (self):
        self.__buffer_cache = {}

    def source_range (self, source: list[str], start: tuple, endup: tuple) -> str:
        if start[0] == endup[0]:
            lnum = start[0]
            if lnum < 0:
                return None
            elif lnum >= len(source):
                return None
            left: int = start[1]
            right: int = endup[1]
            return source[lnum][left:right]
        elif start[0] > endup[0]:
            return None
        lnum = start[0]
        output = []
        output.append(source[lnum][start[1]:])
        lnum += 1
        while lnum < endup[0]:
            output.append(source[lnum])
            lnum += 1
        output.append(source[lnum][:endup[1]])
        return '\n'.join(output)

    def node_text (self, node: Node) -> str:
        return node.text.decode('utf-8', errors = 'ignore')

    def node_source (self, source: list[str], node: Node) -> str:
        t = self.source_range(source, node.start_point, node.end_point)
        return t

    def load_file_content (self, filename, mode = 'r'):
        if hasattr(filename, 'read'):
            try: content = filename.read()
            except: pass
            return content
        try:
            fp = open(filename, mode)
            content = fp.read()
            fp.close()
        except:
            content = None
        return content

    # load file and guess encoding
    def load_file_text (self, filename, encoding = None):
        content = self.load_file_content(filename, 'rb')
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
# instance
#----------------------------------------------------------------------
utils = Utils()


#----------------------------------------------------------------------
# Inspector
#----------------------------------------------------------------------
class Inspector (object):

    def __init__ (self):
        self._inited = True

    def __access_node (self, level: int, node: Node, output):
        item = (level, node.type, node.is_named, node.start_point, node.end_point)
        output.append(item)
        for child in node.children:
            self.__access_node(level + 1, child, output)
        return 0

    def list_nodes (self, root: Node):
        output = []
        self.__access_node(0, root, output)
        return output

    def print_list (self, node: Node) -> int:
        for node in self.list_nodes(node):
            print((' ' * node[0]) + str(node[1:]))
        return 0

    def point_in_node (self, node: Node, point: tuple[int, int]) -> bool:
        lnum, column = point
        start = node.start_point
        endup = node.end_point
        if lnum < start[0] or lnum > endup[0]:
            return False
        elif lnum == start[0] and lnum == endup[0]:
            return (start[1] <= column < endup[1])
        elif lnum == start[0]:
            return (column >= start[1])
        elif lnum == endup[0]:
            return (column < endup[1])
        return True

    def inspect (self, root: Node, point: tuple[int, int]) -> Node:
        if not self.point_in_node(root, point):
            return None
        for child in root.children:
            if self.point_in_node(child, point):
                return self.inspect(child, point)
        return root

    def parents_path (self, node: Node) -> list[Node]:
        path: list[Node] = []
        while True:
            path.append(node)
            if node.parent is None:
                break
            node = node.parent
        path.reverse()
        return path

    def traverse (self, node: Node, depth: int, output):
        for index in range(node.child_count):
            child: Node = node.children[index]
            field: str = node.field_name_for_child(index)
            if child.is_named:
                if field:
                    text = '%s: (%s)'%(field, child.type)
                else:
                    text = '(%s)'%(child.type, )
            else:
                text = child.type.replace('\n', '\\n')
                # continue
            t = (depth, text, child.start_point, child.end_point)
            if child.type == 'class_specifier':
                print('class', child.named_child_count)
                n1 = child.child_by_field_name('name')
                n2 = child.field_name_for_child(-1)
                print('n1', n1, n2)
                for i in range(child.named_child_count):
                    cc = child.named_children[i]
                    nn = child.field_name_for_child(i + 0)
                    print(' ->', cc.type, nn)
                for i in range(2000):
                    nn = child.field_name_for_child(i - 1000)
                    if nn:
                        print('fuck', nn)
            if child.is_named:
                output.append(t)
            self.traverse(child, depth + 1, output)
        return output

    def list_print (self, root):
        output = []
        self.traverse(root, 0, output)
        for item in output:
            print((' ' * item[0]) + item[1] + ' ' + str(item[2:]))
        return 0


#----------------------------------------------------------------------
# instance
#----------------------------------------------------------------------
inspector = Inspector()


#----------------------------------------------------------------------
# test code
#----------------------------------------------------------------------
sample_python = '''
import sys
import os

class foo:
    def __init__ (self):
        print('foo')

def bar():
    print('bar\\nhaha')

if __name__ == '__main__':
    f = foo()
    bar()
'''

sample_c = '''
#include <stdio.h>
#include <stdlib.h>

int main(void)
{
    printf("Hello, World !!\n");
    return 0;
}
'''


#----------------------------------------------------------------------
# testing suit
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        print(config.tslib)
        print(config.NVIMDATA)
        print(config.get_parser('c'))
        print(config.check('go'))
        print(config.check('go2'))
        print(config.error)
        return 0
    def test2():
        tree = config.parse('python', sample_python)
        print('tree', tree.root_node.sexp())
        print()
        tree = config.parse('c', sample_c)
        print('tree', tree.root_node.sexp())
    def test3():
        tree = config.parse('python', sample_python)
        output = inspector.list_nodes(tree.root_node)
        for node in output:
            print((' ' * node[0]) + str(node[1:]))
        print(dir(tree))
        print(tree.text.decode('utf-8', errors = 'ignore'))
        return 0
    def test4():
        tree = config.parse('python', sample_python)
        node = inspector.inspect(tree.root_node, (9, 11))
        print(node)
        print(node.text)
        print(utils.node_text(node))
        path = inspector.parents_path(node)
        for p in path:
            print('->', p)
        print()
        for node in inspector.list_nodes(tree.root_node):
            print((' ' * node[0]) + str(node[1:]))
        return 0
    def test5():
        uri = 'e:/lab/workshop/network/CoreRuntime.h'
        source = utils.load_file_text(uri)
        tree = config.parse('cpp', source)
        inspector.list_print(tree.root_node)
        node = tree.root_node
        # node.is_named
        # node.field_name_for_child
        return 0
    test5()




