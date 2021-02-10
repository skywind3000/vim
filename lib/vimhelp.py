#! /usr/bin/env python2
# -*- coding: utf-8 -*-
#======================================================================
#
# vimhelp.py - 
#
# Created by skywind on 2017/08/06
# Last change: 2017/08/06 18:38:33
#
#======================================================================
import sys
import os
import time
import subprocess


#----------------------------------------------------------------------
# python 2/3 compatible
#----------------------------------------------------------------------
if sys.version_info[0] < 3:
	pass
else:
	xrange = range
	unicode = str


#----------------------------------------------------------------------
# Win32
#----------------------------------------------------------------------
class Win32 (object):

	def __init__ (self):
		self.unix = sys.platform[:3] != 'win'
		self._kernel32 = None
		self._user32 = None
		self._initialize()

	def _initialize (self):
		if self.unix:
			return -1
		import ctypes
		import ctypes.wintypes
		self._kernel32 = ctypes.windll.LoadLibrary('kernel32.dll')
		self._user32 = ctypes.windll.LoadLibrary('user32.dll')
		self.WinHelpA = self._user32.WinHelpA
		self.WinHelpW = self._user32.WinHelpW
		HWND = ctypes.wintypes.HWND
		args1 = [HWND, ctypes.c_char_p, ctypes.c_uint32, ctypes.c_char_p]
		args2 = [HWND, ctypes.c_wchar_p, ctypes.c_uint32, ctypes.c_wchar_p]
		self.WinHelpA.argtypes = args1
		self.WinHelpW.argtypes = args2
		self.WinHelpA.restype = ctypes.wintypes.BOOL
		self.WinHelpW.restype = ctypes.wintypes.BOOL
		return 0

	def win_help (self, help, key = None):
		HELP_KEY = 0x0101
		HELP_FINDER = 0x000b
		HELP_COMMAND = 0x0102
		HELP_CONTENTS = 0x0003
		HELP_INDEX = 0x0003
		if isinstance(help, unicode):
			if not key:
				return self.WinHelpW(None, help, HELP_INDEX, '')
			else:
				if isinstance(key, bytes):
					key = key.decode(sys.stdout.encoding, 'ignore')
				return self.WinHelpW(None, help, HELP_KEY, key)
		else:
			if not key:
				return self.WinHelpA(None, help, HELP_INDEX, '')
			else:
				if isinstance(key, unicode):
					key = key.encode(sys.stdout.encoding, 'ignore')
				return self.WinHelpA(None, help, HELP_KEY, key)
		return 0

	def chm_help (self, chm, key = None):
		args = ['KeyHH.exe']
		if key:
			args += ['-#klink', key]
		args += [chm]
		subprocess.call(args)
		time.sleep(0.5)
		return 0



#----------------------------------------------------------------------
# main 
#----------------------------------------------------------------------
def main(args = None):
	if not args:
		args = sys.argv
	args = [ n for n in args ]
	if len(args) < 2:
		name = sys.argv[0]
		print('usage: %s <operation> [...]'%name)
		print('operations:')
		print('  %s -h help [keyword] '%name)
		return 1
	op = args[1].lower()
	parameters = args[2:]
	if op == '-h':
		if len(parameters) < 1:
			print('require help file name')
			return 2
		if not os.path.exists(parameters[0]):
			print('error file name')
			return 3
		extname = os.path.splitext(parameters[0])[-1].lower()
		win32 = Win32()
		if extname == '.hlp':
			if len(parameters) == 1:
				win32.win_help(parameters[0], '')
			else:
				win32.win_help(parameters[0], parameters[1])
		else:
			keyword = ''
			if len(parameters) > 1:
				keyword = parameters[1]
			win32.chm_help(parameters[0], keyword)
	else:
		print('unknow operation: %s'%op)
	return 0


#----------------------------------------------------------------------
# testing case
#----------------------------------------------------------------------
if __name__ == '__main__':
	def test1():
		win32 = Win32()
		win32.win_help('d:/dev/help/win32.hlp', 'MessageBox')
		# win32.win_help(u'd:/dev/help/win32.hlp', 'MessageBox')
		# win32.chm_help(u'd:/dev/help/python2713.chm', 'print_callers')
		# raw_input()
		time.sleep(0.5)
		return 0

	# test1()
	main()


