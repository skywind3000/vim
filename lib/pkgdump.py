#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# pkgdump.py - 
#
# Created by skywind on 2024/05/08
# Last Modified: 2024/05/08 15:02:44
#
#======================================================================
import sys
import os
import time
import ascmini


#----------------------------------------------------------------------
# configure
#----------------------------------------------------------------------
class configure (object):

    def __init__ (self, dirhome = None):
        self.pkg_config_path = None
        if not dirhome:
            dirhome = os.path.abspath('build')
        self.dirhome = os.path.abspath(dirhome)
        self.package = {}
        self.__collect()
        self.inited = False

    def __collect (self):
        self.package = {}
        if not os.path.isdir(self.dirhome):
            return -1
        for fname in os.listdir(self.dirhome):
            extname = os.path.splitext(fname)[1]
            if extname.lower() != '.pc':
                continue
            path = os.path.normpath(os.path.join(self.dirhome, fname))
            pkg = {}
            name = os.path.splitext(fname)[0]
            pkg['path'] = path
            pkg['name'] = name
            self.package[name] = pkg
        return 0

    def pkgconfig (self, args):
        argv = ['pkg-config'] + args
        saved = os.environ.get('PKG_CONFIG_PATH', None)
        if self.pkg_config_path:
            os.environ['PKG_CONFIG_PATH'] = self.pkg_config_path
        text = ascmini.execute(argv, False, True)
        if self.pkg_config_path:
            if saved is not None:
                os.environ['PKG_CONFIG_PATH'] = saved
            elif 'PKG_CONFIG_PATH' in os.environ:
                del os.environ['PKG_CONFIG_PATH']
        text = ascmini.posix.string_auto_decode(text)
        if os.shell_return != 0:
            return None
        return text

    def pkgconfig_cflags (self, names):
        if isinstance(names, str):
            names = [names]
        return self.pkgconfig(['--cflags-only-I'] + names)

    def pkgconfig_libs (self, names):
        if isinstance(names, str):
            names = [names]
        return self.pkgconfig(['--libs'] + names)

    def pkgconfig_variable (self, varname, names):
        if isinstance(names, str):
            names = [names]
        text = self.pkgconfig(['--variable=' + varname] + names)
        if text:
            text = text.strip('\r\n\t ')
        return text

    def pkgconfig_include (self, names):
        return self.pkgconfig_variable('includedir', names)

    def pkgconfig_lib (self, names):
        return self.pkgconfig_variable('libdir', names)

    def pkgconfig_bin (self, names):
        return self.pkgconfig_variable('bindir', names)

    def init (self):
        for pkg in self.package:
            item = self.package[pkg]
            self.__init_pkg(item)
        self.inited = True
        return 0

    def __init_pkg (self, pkg):
        pkgname = pkg['name']
        dirname = self.pkgconfig_include(pkgname)
        if dirname and os.path.exists(dirname):
            pkg['include'] = dirname
        dirname = self.pkgconfig_lib(pkgname)
        if dirname and os.path.exists(dirname):
            pkg['lib'] = dirname
        dirname = self.pkgconfig_bin(pkgname)
        if dirname and os.path.exists(dirname):
            pkg['bin'] = dirname
        elif 'lib' in pkg:
            test = os.path.normpath(os.path.join(pkg['lib'], '../bin'))
            if os.path.isdir(test):
                pkg['bin'] = test
        return 0

    def install (self, pkgname, destination):
        if pkgname not in self.package:
            return -1
        pkg = self.package[pkgname]
        for subname in ('include', 'lib', 'bin'):
            dstname = os.path.normpath(os.path.join(destination, subname))
            srcname = pkg.get(subname, None)
            if srcname and os.path.exists(srcname):
                # ascmini.utils.xcopytree(srcname, dstname, True)  # 206.367s
                ascmini.utils.xcopytree(srcname, dstname, False)  # 30.282s
        return 0

    def dump (self, destination):
        ts = time.time()
        if not self.inited:
            self.init()
        for name in self.package:
            print('installing %s ...' % name)
            self.install(name, destination)
        ts = time.time() - ts
        print('done in %.3f seconds' % ts)
        return 0


#----------------------------------------------------------------------
# main
#----------------------------------------------------------------------
def main(args = None):
    if not args:
        args = sys.argv[1:]
    argv = [n for n in args]
    options, args = ascmini.utils.getopt(argv)
    if ('h' in options) or ('help' in options) or len(args) == 0:
        print('usage: pkgdump.py <pkghome> <destination>')
        return 0
    dirhome = args[0]
    if not os.path.isdir(dirhome):
        print('error: %s is not a directory' % dirhome)
        return 1
    destination = args[1]
    if not os.path.isdir(destination):
        print('error: %s is not a directory' % destination)
        return 2
    config = configure(dirhome)
    if len(config.package) == 0:
        print('error: no package found in %s' % dirhome)
        return 3
    config.pkg_config_path = config.dirhome
    print('loading packages ...')
    config.init()
    config.dump(os.path.abspath(destination))
    return 0


#----------------------------------------------------------------------
# testing suit
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        config = configure('d:/dev/conan/mingw32/build')
        config.pkg_config_path = config.dirhome
        config.init()
        print(config.pkgconfig(['--cflags', 'zlib']))
        config.dump('d:/dev/conan/mingw32')
        return 0
    def test2():
        args = ['--help']
        main(args)
        return 0
    # test2()
    main()


