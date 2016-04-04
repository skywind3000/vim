#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# dash2.py - dash docset command line interface
#
# Created by skywind on 2017/01/01
# Last change: 2017/01/01 03:49:09
#
#======================================================================
import sys, time, os
import sqlite3


#----------------------------------------------------------------------
# plutil
#----------------------------------------------------------------------
def plutil(*args):
	args = [ n for n in args ]
	locate = None
	if sys.platform[:3] == 'win':
		place = []
		p1 = os.environ.get('ProgramFiles(x86)', 'C:/Program Files (x86)')
		p2 = os.environ.get('ProgramFiles', 'C:/Program Files')
		p1 = os.path.join(p1, 'Common Files')
		p2 = os.path.join(p2, 'Common Files')
		if os.path.exists(p1) and (not p1 in place):
			place.append(p1)
		if os.path.exists(p2) and (not p2 in place):
			place.append(p2)
		p1 = os.environ.get('CommonProgramFiles(x86)', '')
		p2 = os.environ.get('CommonProgramFiles', '')
		p3 = os.environ.get('CommonProgramW6432', '')
		if p1 == '':
			p1 = 'C:/Program Files (x86)/Common Files'
		if p2 == '':
			p2 = 'C:/Program Files/Common Files'
		if not p1 in place:
			place.append(p1)
		if not p2 in place:
			place.append(p2)
		if p3 and (not p3 in place):
			place.append(p3)
		name = 'Apple/Apple Application Support/plutil.exe'
		for home in place:
			home = os.path.join(home, name)
			if os.path.exists(home):
				locate = home
				break
		if locate is None:
			locate = which('plutil.exe')
		if locate is None:
			raise IOError('can not find plutil.exe, please install iTunes')
			return -1
		locate = pathshort(locate)
	else:
		locate = which('plutil')
		if locate is None:
			raise IOError('can not find plutil')
	code = os.spawnv(os.P_WAIT, locate, ['plutil'] + args)
	return code


#----------------------------------------------------------------------
# Dash DocSet 
#----------------------------------------------------------------------
class DashDoc (object):

	def __init__ (self, path):
		if not os.path.exists(path):
			raise IOError('can not read %s'%path)
		self._root = os.path.abspath(path)
		path = self._root
		if not os.path.exists(os.path.join(path, 'Contents')):
			raise IOError('not a dash docset: ' + self._root)
		if not os.path.exists(os.path.join(path, 'Contents/Info.plist')):
			raise IOError('not a dash docset: ' + self._root)
		self._read_info()

	def _read_info (self):
		self._info = self.plist_load(self.path_root('Contents/Info.plist'))
		self._database = self.path_resource('docSet.dsidx')
		self._conn = None
		self._search_index = False
		return 0

	def close (self):
		if self._conn is not None:
			self._conn.close()
			self._conn = None
		return 0

	def path_root (self, path):
		return os.path.join(self._root, path)

	def path_resource (self, path):
		return os.path.join(self.path_root('Contents/Resources'), path)

	def path_document (self, path):
		p = self.path_root('Contents/Resources/Documents')
		return os.path.join(p, path)

	def plist_load (self, filename):
		import plistlib
		fp = open(filename, 'rb')
		content = fp.read(8)
		fp.close()
		if content == 'bplist00':
			import warnings
			warnings.filterwarnings("ignore")
			tmpname = os.tempnam(None, 'plist.')
			plutil('-convert', 'xml1', '-o', tmpname, filename)
			data = plistlib.readPlist(tmpname)
			os.remove(tmpname)
			return data
		data = plistlib.readPlist(filename)
		return data	

	def connection (self):
		if self._conn is None:
			self._conn = sqlite3.connect(self._database)
			sql = "select count(*) from sqlite_master where "
			sql+= "type='table' and name='searchIndex';"
			c = self._conn.cursor()
			c.execute(sql)
			row = c.fetchone()
			if row is not None:
				if len(row) > 0 and row[0] > 0:
					self._search_index = True
		return self._conn
	
	def search (self, pattern, like = False):
		conn = self.connection()
		cursor = conn.cursor()
		if self._search_index:
			sql = "SELECT name AS name, type AS type, path AS url "
			sql+= "FROM searchIndex"
		else:
			sql = "SELECT ztokenname AS name, "
			sql+= "ztypename AS type, "
			sql+= "zpath || ifnull('#' || nullif(zanchor, ''), '') AS url "
			sql+= "FROM ztoken JOIN ztokenmetainformation "
			sql+= "ON ztokenmetainformation.z_pk = ztoken.zmetainformation "
			sql+= "JOIN zfilepath ON "
			sql+= "zfilepath.z_pk = ztokenmetainformation.zfile "
			sql+= "JOIN ztokentype ON ztokentype.z_pk = ztoken.ztokentype"
		if pattern:
			sql += " WHERE name like ? "
			sql += "COLLATE NOCASE LIMIT 100"
			cursor.execute(sql, ('%' + pattern + '%', ))
		else:
			sql += "COLLATE NOCASE LIMIT 100"
			cursor.execute(sql)
		rows = [ n for n in cursor ]
		cursor = None
		return rows


#----------------------------------------------------------------------
# testing case
#----------------------------------------------------------------------
if __name__ == '__main__':
	docsets = 'd:/Program Files/zeal-portable-0.3.1-windows-x86/docsets'

	def test1():
		dash = DashDoc(os.path.join(docsets, 'Vim.docset'))
		print dash._info
		dash.connection()
		print dash._search_index
		return 0

	def test1():
		dash = DashDoc(os.path.join(docsets, 'Python_2.docset'))
		rows = dash.search('print')
		for row in rows:
			print row
		return 0

	test1()




