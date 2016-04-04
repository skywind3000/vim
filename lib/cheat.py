#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# cheat.py - python cheat sheet
#
# Created by skywind on 2018/01/25
# Last change: 2018/01/25 16:20:27
#
#======================================================================
from __future__ import print_function
import sys
import time
import os
import subprocess
import shutil


#----------------------------------------------------------------------
# CheatUtils
#----------------------------------------------------------------------
class CheatUtils (object):

	def __init__ (self):
		self.name = 'utils'
		self.isatty = sys.stdout.isatty()

	def colorize (self, sheet_content):
		""" Colorizes cheatsheet content if so configured """

		# only colorize if so configured
		if not 'CHEATCOLORS' in os.environ:
			return sheet_content

		try:
			from pygments import highlight
			from pygments.lexers import get_lexer_by_name
			from pygments.formatters import TerminalFormatter

		# if pygments can't load, just return the uncolorized text
		except ImportError:
			return sheet_content

		first_line = sheet_content.splitlines()[0]
		lexer      = get_lexer_by_name('bash')
		if first_line.startswith('```'):
			sheet_content = '\n'.join(sheet_content.split('\n')[1:-2])
			try:
				lexer = get_lexer_by_name(first_line[3:])
			except Exception:
				pass

		return highlight(sheet_content, lexer, TerminalFormatter())

	def die (self, message):
		""" Prints a message to stderr and then terminates """
		warn(message)
		exit(1)

	def editor (self):
		""" Determines the user's preferred editor """

		# determine which editor to use
		editor = os.environ.get('CHEAT_EDITOR') \
			or os.environ.get('VISUAL')         \
			or os.environ.get('EDITOR')         \
			or False

		# assert that the editor is set
		if editor == False:
			die(
				'You must set a CHEAT_EDITOR, VISUAL, or EDITOR environment '
				'variable in order to create/edit a cheatsheet.'
			)

		return editor

	def open_with_editor (self, filepath):
		""" Open `filepath` using the EDITOR specified by the environment variables """
		editor_cmd = self.editor().split()
		try:
			subprocess.call(editor_cmd + [filepath])
		except OSError:
			die('Could not launch ' + self.editor())

	def warn (self, message):
		""" Prints a message to stderr """
		print((message), file=sys.stderr)

	def search_cheat (self):
		available = []
		import site
		site_system = site.getsitepackages()
		site_user = site.getusersitepackages()
		for name in [site_user] + site_system:
			path = os.path.join(name, 'cheat')
			if not os.path.exists(path):
				continue
			path = os.path.join(path, 'cheatsheets')
			if not os.path.exists(path):
				continue
			available.append(path)
		return available

	def set_color (self, color):
		if not self.isatty:
			return 0
		if sys.platform[:3] == 'win':
			try: import ctypes
			except: return 0
			kernel32 = ctypes.windll.LoadLibrary('kernel32.dll')
			GetStdHandle = kernel32.GetStdHandle
			SetConsoleTextAttribute = kernel32.SetConsoleTextAttribute
			GetStdHandle.argtypes = [ ctypes.c_uint32 ]
			GetStdHandle.restype = ctypes.c_size_t
			SetConsoleTextAttribute.argtypes = [ ctypes.c_size_t, ctypes.c_uint16 ]
			SetConsoleTextAttribute.restype = ctypes.c_long
			handle = GetStdHandle(0xfffffff5)
			if color < 0: color = 7
			result = 0
			if (color & 1): result |= 4
			if (color & 2): result |= 2
			if (color & 4): result |= 1
			if (color & 8): result |= 8
			if (color & 16): result |= 64
			if (color & 32): result |= 32
			if (color & 64): result |= 16
			if (color & 128): result |= 128
			SetConsoleTextAttribute(handle, result)
		else:
			if color >= 0:
				foreground = color & 7
				background = (color >> 4) & 7
				bold = color & 8
				sys.stdout.write("\033[%s3%d;4%dm"%(bold and "01;" or "", foreground, background))
				sys.stdout.flush()
			else:
				sys.stdout.write("\033[0m")
				sys.stdout.flush()
		return 0
	

#----------------------------------------------------------------------
# local utils
#----------------------------------------------------------------------
utils = CheatUtils()
die = utils.die
warn = utils.warn
set_color = utils.set_color


#----------------------------------------------------------------------
# CheatSheets
#----------------------------------------------------------------------
class CheatSheets (object):

	def __init__ (self):
		self.site_sheets = utils.search_cheat()
		self.cheats_dict = None
	
	def default_path (self):

		""" Returns the default cheatsheet path """

		# determine the default cheatsheet dir
		default_sheets_dir = os.environ.get('DEFAULT_CHEAT_DIR') or os.path.join('~', '.cheat')
		default_sheets_dir = os.path.expanduser(os.path.expandvars(default_sheets_dir))

		# create the DEFAULT_CHEAT_DIR if it does not exist
		if not os.path.isdir(default_sheets_dir):
			try:
				# @kludge: unclear on why this is necessary
				os.umask(0000)
				os.mkdir(default_sheets_dir)

			except OSError:
				die('Could not create DEFAULT_CHEAT_DIR')

		# assert that the DEFAULT_CHEAT_DIR is readable and writable
		if not os.access(default_sheets_dir, os.R_OK):
			die('The DEFAULT_CHEAT_DIR (' + default_sheets_dir +') is not readable.')
		if not os.access(default_sheets_dir, os.W_OK):
			die('The DEFAULT_CHEAT_DIR (' + default_sheets_dir +') is not writable.')

		# return the default dir
		return default_sheets_dir

	def paths (self):
		""" Assembles a list of directories containing cheatsheets """
		sheet_paths = [ self.default_path() ]
		sheet_paths.extend(self.site_sheets)

		# merge the CHEATPATH paths into the sheet_paths
		if 'CHEATPATH' in os.environ and os.environ['CHEATPATH']:
			for path in os.environ['CHEATPATH'].split(os.pathsep):
				if os.path.isdir(path):
					sheet_paths.append(path)

		if not sheet_paths:
			die('The DEFAULT_CHEAT_DIR dir does not exist or the CHEATPATH is not set.')

		return sheet_paths

	def get (self):
		""" Assembles a dictionary of cheatsheets as name => file-path """
		cheats = {}

		# otherwise, scan the filesystem
		for cheat_dir in reversed(self.paths()):
			for cheat in os.listdir(cheat_dir):
				if cheat[:1] == '.' or cheat[:2] == '__':
					continue
				cheats[cheat] = os.path.join(cheat_dir, cheat)

		return cheats

	def list (self):
		""" Lists the available cheatsheets """
		sheet_list = ''
		pad_length = max([len(x) for x in self.get().keys()]) + 4
		for sheet in sorted(self.get().items()):
			sheet_list += sheet[0].ljust(pad_length) + sheet[1] + "\n"
		return sheet_list

	def search (self, term):
		""" Searches all cheatsheets for the specified term """
		result = ''

		for cheatsheet in sorted(self.get().items()):
			match = ''
			for line in open(cheatsheet[1]):
				if term in line:
					match += '  ' + line

			if match != '':
				result += cheatsheet[0] + ":\n" + match + "\n"

		return result

	def sheets (self):
		if not self.cheats_dict:
			self.cheats_dict = self.get()
		return self.cheats_dict


#----------------------------------------------------------------------
# cheatsheets
#----------------------------------------------------------------------
cheatsheets = CheatSheets()


#----------------------------------------------------------------------
# Sheet
#----------------------------------------------------------------------
class CheatSheet (object):

	def copy (self, current_sheet_path, new_sheet_path):
		""" Copies a sheet to a new path """

		# attempt to copy the sheet to DEFAULT_CHEAT_DIR
		try:
			shutil.copy(current_sheet_path, new_sheet_path)

		# fail gracefully if the cheatsheet cannot be copied. This can happen if
		# DEFAULT_CHEAT_DIR does not exist
		except IOError:
			die('Could not copy cheatsheet for editing.')

	def create_or_edit (self, sheet):
		""" Creates or edits a cheatsheet """

		# if the cheatsheet does not exist
		if not self.exists(sheet):
			self.create(sheet)

		# if the cheatsheet exists but not in the default_path, copy it to the
		# default path before editing
		elif self.exists(sheet) and not self.exists_in_default_path(sheet):
			self.copy(self.path(sheet), os.path.join(cheatsheets.default_path(), sheet))
			self.edit(sheet)

		# if it exists and is in the default path, then just open it
		else:
			self.edit(sheet)

	def create (self, sheet):
		""" Creates a cheatsheet """
		new_sheet_path = os.path.join(cheatsheets.default_path(), sheet)
		utils.open_with_editor(new_sheet_path)

	def edit (self, sheet):
		""" Opens a cheatsheet for editing """
		utils.open_with_editor(self.path(sheet))

	def exists (self, sheet):
		""" Predicate that returns true if the sheet exists """
		return sheet in cheatsheets.get() and os.access(self.path(sheet), os.R_OK)

	def exists_in_default_path (self, sheet):
		""" Predicate that returns true if the sheet exists in default_path"""
		default_path_sheet = os.path.join(cheatsheets.default_path(), sheet)
		return sheet in cheatsheets.get() and os.access(default_path_sheet, os.R_OK)

	def is_writable (self, sheet):
		""" Predicate that returns true if the sheet is writeable """
		return sheet in cheatsheets.get() and os.access(self.path(sheet), os.W_OK)

	def path (self, sheet):
		""" Returns a sheet's filesystem path """
		return cheatsheets.get()[sheet]

	def read (self, sheet):
		""" Returns the contents of the cheatsheet as a String """
		if not self.exists(sheet):
			die('No cheatsheet found for ' + sheet)

		with open(self.path(sheet)) as cheatfile:
			return cheatfile.read()


#----------------------------------------------------------------------
# sheet
#----------------------------------------------------------------------
cheatsheet = CheatSheet()


#----------------------------------------------------------------------
# display text
#----------------------------------------------------------------------
def display(text):
	cheat_colors = os.environ.get('CHEATCOLORS', '')
	if cheat_colors and sys.stdout.isatty():
		if cheat_colors in ('0', 'no', 'disable', ''):
			print(text)
			return 0
		if cheat_colors.lower() in ('yes', 'bash', '1'):
			if sys.platform[:3] != 'win':
				print(utils.colorize(text))
				return 0
			else:
				print(text)
				return 0
		colors = []
		if ',' in cheat_colors:
			colors = cheat_colors.split(',')
		c_main = -1
		c_code = 14
		c_high = 15
		c_comment = 10
		if len(colors) > 0 and colors[0].isdigit():
			c_main = int(colors[0])
		if len(colors) > 1 and colors[1].isdigit():
			c_code = int(colors[1])
		if len(colors) > 2 and colors[2].isdigit():
			c_high = int(colors[2])
		if len(colors) > 3 and colors[3].isdigit():
			c_comment = int(colors[3])
		current = c_main
		set_color(current)
		for line in text.split('\n'):
			char = line[:1]
			if char.isspace():
				color = c_code
				if line.lstrip('\r\n\t ')[:1] == '#':
					color = c_comment
			elif char == '#':
				color = c_comment
			elif char == '-':
				color = c_high
			else:
				color = c_main
			if color != current:
				set_color(color)
				current = color
			# print('color', color)
			print(line)
		set_color(-1)
		return 0
	print(text)
	return 0


#----------------------------------------------------------------------
# document
#----------------------------------------------------------------------
cheatdoc = """cheat

Create and view cheatsheets on the command line.

Usage:
  cheat <cheatsheet>
  cheat -e <cheatsheet>
  cheat -s <keyword>
  cheat -l
  cheat -d
  cheat -v

Options:
  -d --directories  List directories on CHEATPATH
  -e --edit         Edit cheatsheet
  -l --list         List cheatsheets
  -s --search       Search cheatsheets for <keyword>
  -v --version      Print the version number

Examples:
  To view the `tar` cheatsheet:
    cheat tar
  To edit (or create) the `foo` cheatsheet:
    cheat -e foo
  To list all available cheatsheets:
    cheat -l
  To search for "ssh" among all cheatsheets:
    cheat -s ssh
"""


#----------------------------------------------------------------------
# usage
#----------------------------------------------------------------------
def usage():
	print('Usage:')
	print('  cheat <cheatsheet>')
	print('  cheat -e <cheatsheet>')
	print('  cheat -s <keyword>')
	print('  cheat -l')
	print('  cheat -d')
	print('  cheat -v')
	return 0


#----------------------------------------------------------------------
# main
#----------------------------------------------------------------------
def main(args = None):

	args = [ n for n in (args and args or sys.argv) ]
	
	keywords = ['-e', '--edit', '-s', '--search', '-l', '--list', \
			'-d', '--directories', '-v', '--version', '-h', '--help']

	if len(args) < 2:
		usage()
		return 0

	argv, options = [], {}

	for arg in args[1:]:
		if arg in keywords:
			options[arg] = 1
		else:
			argv.append(arg)
	
	word = argv and argv[0] or ''

	if len(argv) > 1:
		usage()
		return 1
	
	if '-d' in options or '--directories' in options:
		print("\n".join(cheatsheets.paths()))

	elif '-l' in options or '--list' in options:
		print(cheatsheets.list())

	elif '-e' in options or '--edit' in options:
		if not word:
			usage()
			return 1
		cheatsheet.create_or_edit(word)

	elif '-h' in options or '--help' in options:
		print(cheatdoc)

	elif '-v' in options or '--version' in options:
		print('cheat 2.2.3: by Chris Allen Lane and patched by skywind3000')

	elif '-s' in options or '--search' in options:
		if not word:
			usage()
			return 1
		text = cheatsheets.search(word)
		display(text)

	else:
		if not word:
			usage()
			return 1
		text = cheatsheet.read(word)
		display(text)

	return 0


#----------------------------------------------------------------------
# testing
#----------------------------------------------------------------------
if __name__ == '__main__':

	# os.environ['DEFAULT_CHEAT_DIR'] = 'd:/acm/github/vim/cheat'

	def test1():
		print(utils.search_cheat())
		print(1,2,3)
		return 0

	def test2():
		print(cheatsheets.default_path())
		import pprint
		pprint.pprint(cheatsheets.get())
		return 0	

	def test3():
		print(cheatsheet.read('linux'))
		usage()
		return 0

	def test4():
		os.environ['EDITOR'] = 'vim'
		os.environ['CHEATCOLORS'] = 'true'
		args = ['tar']
		args = ['-d']
		args = ['-e', 'tar']
		args = ['-s', 'sed']
		args = ['cut']
		# args = ['-v']
		main(sys.argv[:1] + args)
		return 0

	# test4()
	sys.exit(main())


