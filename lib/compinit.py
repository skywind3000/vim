#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# compinit.py - python shell tab completion
#
# Created by skywind on 2018/01/27
# Last change: 2018/01/27 21:48:26
#
#======================================================================

def __completion_init():
	try:
		import readline
		import rlcompleter
		import atexit
		import os
		import sys
	except ImportError:
		return -1
	try:
		readline.parse_and_bind('tab: complete')
	except:
		return -2
	local = os.path.expanduser('~/.local')
	if not os.path.exists(local):
		try:
			os.mkdir(local)
		except:
			return -2
	if not os.path.exists(local + '/var'):
		try:
			os.mkdir(local + '/var')
		except:
			return -3
	history = local + '/var/python%d_hist'%sys.version_info[0]
	try:
		readline.read_history_file(history)
	except:
		pass
	atexit.register(readline.write_history_file, history)
	return 0

__completion_init()
del __completion_init



