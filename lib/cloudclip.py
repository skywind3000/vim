#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# cloudclip.py - copy/paste text in the cloud (with gist as backend)
#
# Created by skywind on 2018/01/23
# Last change: 2018/01/23 20:52:10
#
#======================================================================
import sys
import os
import json
import time
import ConfigParser
import requests


#----------------------------------------------------------------------
# GistError
#----------------------------------------------------------------------
class GistError (StandardError):
	def __init__ (self, code, what):
		super(StandardError, self).__init__(what)
		self.code = code


#----------------------------------------------------------------------
# GistRequest
#----------------------------------------------------------------------
class GistRequest (object):

	def __init__ (self, token, options = {}):
		self.session = None
		self.options = {}
		if options:
			for k in options:
				self.options[k] = options[k]
		self.https = self.options.get('https', True)
		self.token = token
		self.code = 0
		self.error = None
		self.res = None

	def request (self, url, method, head = {}, params = {}, data = None):
		if self.session is None:
			self.session = requests.Session()
		if self.https:
			base = 'https://api.github.com/'
		else:
			base = 'http://api.github.com/'
		if url[:1] == '/':
			url = url[1:]
		url = base + url
		s = self.session
		argv = {}
		if 'timeout' in self.options:
			argv['timeout'] = self.options['timeout']
		if 'proxies' in self.options:
			argv['proxies'] = self.options['proxies']
		p = {}
		if params:
			for k in params:
				p[k] = params[k]
		headers = {}
		if head:
			for k in head:
				headers[k] = head[k]
		if self.token:
			headers['Authorization'] = 'token %s'%self.token
		if p:
			argv['params'] = p
		if data is not None:
			argv['data'] = data
		if headers:
			argv['headers'] = headers
		method = method.lower()
		if method == 'get':
			r = s.get(url, **argv)
		elif method == 'post':
			r = s.post(url, **argv)
		elif method == 'patch':
			r = s.patch(url, **argv)
		elif method == 'put':
			r = s.patch(url, **argv)
		elif method == 'delete':
			r = s.delete(url, **argv)
		else:
			raise GistError(-100, 'Bad method')
		return r

	def request_gist (self, url, method, head = {}, param = {}, data = None):
		self.res = None
		if data:
			if not isinstance(data, str):
				data = json.dumps(data)
		r = self.request(url, method, head, param, data)
		if r is None:
			raise GistError(-100, 'Unknow error')
			return None
		self.res = r
		if not r.status_code in (200, 201, 204):
			self.code = r.status_code
			self.text = r.__dict__.get('text', None)
			self.error = r.__dict__.get('error', None)
			message = 'HTTP error code=%d: %s'%(r.status_code, r.text)
			raise GistError(r.status_code, message)
			return None
		self.code = 0
		self.text = r.text
		self.error = None
		text = self.text
		try:
			obj = r.json()
		except:
			return None
		return obj

	def get (self, url, headers = {}, params = {}, data = None):
		return self.request_gist(url, 'GET', headers, params, data)

	def put (self, url, headers = {}, params = {}, data = None):
		return self.request_gist(url, 'PUT', headers, params, data)

	def post (self, url, headers = {}, params = {}, data = None):
		return self.request_gist(url, 'POST', headers, params, data)

	def patch (self, url, headers = {}, params = {}, data = None):
		return self.request_gist(url, 'PATCH', headers, params, data)

	def delete (self, url, headers = {}, params = {}, data = None):
		return self.request_gist(url, 'DELETE', headers, params, data)


#----------------------------------------------------------------------
# empty object
#----------------------------------------------------------------------
class GistObject (object):

	def __init__ (self, gistid): 
		self.gistid = gistid
		self.description = ''
		self.ctime = None
		self.mtime = None
		self.files = []


#----------------------------------------------------------------------
# gist api
#----------------------------------------------------------------------
class GistApi (object):

	def __init__ (self, username, token):
		self.username = username
		self.token = token
		self.request = GistRequest(token)
		self.request.options['timeout'] = 20
		self.request.https = True
		self.error_msg = None
		self.error_code = 0

	# since: ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ
	def list (self, since = None):
		if self.username:
			url = '/users/%s/gists'%self.username
		else:
			url = '/gists'
		params = {}
		if since:
			params['since'] = since
		r = self.request.get(url)
		return r

	def get (self, gistid, version = None):
		url = '/gists/' + gistid
		if version:
			url += '/' + version
		r = self.request.get(url)
		return r

	def create (self, description, files, public = False):
		data = {}
		if description:
			data['description'] = description
		data['public'] = public
		if files is None:
			raise GistError(-101, 'files filed required')
		data['files'] = files
		params = {'scope': 'gist'}
		r = self.request.post('/gists', {}, params, data)
		return r

	def edit (self, gistid, description, files):
		data = {}
		if description:
			data['description'] = description
		data['files'] = files
		params = {'scope': 'gist'}
		r = self.request.patch('/gists/' + gistid, {}, params, data)
		return r

	def delete (self, gistid):
		r = self.request.delete('/gists/' + gistid)
		return r

	def gist_get (self, gistid):
		r = self.get(gistid)
		files = r['files']
		gist = GistObject(gistid)
		gist.ctime = r.get('created_at', '')
		gist.mtime = r.get('updated_at', '')
		gist.files = {}
		gist.owner = r.get('owner', {}).get('login', 'unknow')
		gist.description = r.get('description', None)
		for name in files:
			data = files[name]
			obj = {}
			obj['size'] = data.get('size', -1)
			obj['type'] = data.get('type', None)
			obj['truncated'] = data.get('truncated', False)
			obj['language'] = data.get('language', '')
			gist.files[name] = data
		return gist

	def gist_update (self, gist):
		r = self.edit(gist.gistid, gist.description, gist.files)
		return r
		

#----------------------------------------------------------------------
# CloudClip
#----------------------------------------------------------------------
class CloudClip (object):

	def __init__ (self, ininame):
		self.api = GistApi('', token)
		self.config = {}
		if '~' in ininame:
			ininame = os.path.expanduser(ininame)
		self.ininame = os.path.normcase(ininame)
		self.read_ini(self.ininame)
		self.set_token(self.config.get('token', None))
		self.set_id(self.config.get('id', None))

	def set_token (self, token):
		if token:
			token = token.strip('\r\n\t ').replace('\n', '')
		self.config['token'] = token
		self.api.request.token = token

	def get_token (self):
		return self.api.request.token

	def set_id (self, gistid):
		if gistid:
			gistid = gistid.strip('\r\n\t ').replace('\n', '')
		self.config['id'] = gistid
		self.gistid = gistid

	def get_id (self):
		return self.gistid

	def read_ini (self, ininame):
		if not os.path.exists(ininame):
			return False
		cp = ConfigParser.ConfigParser()
		try:
			cp.read(ininame)
		except:
			return False
		self.config = {}
		for sect in cp.sections():
			if sect.lower() != 'default':
				continue
			for key, val in cp.items(sect):
				self.config[key.lower()] = val
		self.config['token'] = self.config.get('token', '')
		self.config['id'] = self.config.get('id', '')
		self.config['public'] = self.config.get('public', True)
		self.set_token(self.config['token'].strip('\r\n\t '))
		self.set_id(self.config['id'].strip('\r\n\t '))
		return True

	def login (self, token, gistid):
		self.set_token(token)
		self.set_id(gistid)
		create_gist = False
		if (not gistid) or (gistid == '-'):
			files = {}
			text = 'CloudClip:\n'
			text += 'Your own clipboard in the cloud, '
			text += 'copy and paste text with gist between systems.\n'
			text += 'home: https://github.com/skywind3000/CloudClip\n\n'
			text += 'Place-holder, don\'t remove it !!'
			files['<clipboard>'] = {'content': text}
			r = self.api.create('<Clipboard of CloudClip>', files)
			gistid = r['id']
			self.set_id(gistid)
			print 'New gist created with id: ' + gistid
			create_gist = True
		gist = self.api.gist_get(self.gistid)
		with open(self.ininame, 'w') as fp:
			fp.write('[default]\n')
			fp.write('token=%s\n'%self.get_token())
			fp.write('id=%s\n'%self.get_id())
		print 'Configuration updated in: %s'%self.ininame
		if create_gist:
			print ''
			print 'Use the command below in other systems to initialize'
			print 'cloudclip.py -i %s %s'%(token, gistid)
		print ''
		return True

	def error (self, code, message):
		sys.stderr.write('Error: ' + message + '\n')
		sys.stderr.flush()
		sys.exit(code)

	def check (self):
		nm = sys.argv[0]
		if not os.path.exists(self.ininame) and False:
			text = "Authorization token and gist-id are required, see %s -h"%nm
			self.error(1, text)
		if not self.config['token']:
			text = "Authorization token is required, see %s -h"%nm
			self.error(2, text)
		if not self.config['id']:
			text = 'gist-id is required, see %s -h'%nm
			self.error(3, text)
		return True

	def list_info (self):
		self.check()
		gist = self.api.gist_get(self.gistid)
		ctime = gist.ctime.replace('T', ' ').replace('Z', '')
		mtime = gist.mtime.replace('T', ' ').replace('Z', '')
		print '%s: %s modified at %s'%(gist.gistid, gist.owner, mtime)
		size1 = 10
		size2 = 8
		names = gist.files.keys()
		names.sort()
		count = 0
		for name in names:
			item = gist.files[name]
			size = str(item['size'])
			size1 = max(size1, len(name))
			size2 = max(size2, len(size))
			if name == '<clipboard>':
				continue
			count += 1
		if count == 0:
			print '(empty)'
			return True
		print ''
		print 'Name'.ljust(size1), '\t', 'Size'.rjust(size2)
		print '----'.ljust(size1), '\t', '----'.rjust(size2)
		for name in names:
			item = gist.files[name]
			if name == '<clipboard>':
				continue
			print name.ljust(size1), '\t' + str(item['size']).rjust(size2)
		print ''
		print '(%d files)'%count
		return True

	def write_file (self, name, content, mime = None):
		self.check()
		gist = GistObject(self.gistid)
		gist.description = '<Clipboard of CloudClip>'
		gist.files = {}
		data = {'content': content}
		if mime:
			data['type'] = mime
		if not name:
			name = '<unnamed>'
		gist.files[name] = data
		self.api.gist_update(gist)
		return True

	def read_file (self, name):
		self.check()
		gist = self.api.gist_get(self.gistid)
		if not name:
			name = '<unnamed>'
		if not name in gist.files:
			return None
		return gist.files[name]['content']

	def clear (self):
		self.check()
		gist = self.api.gist_get(self.gistid)
		files = {}
		for name in gist.files:
			if name == '<clipboard>':
				continue
			files[name] = None
		gist.files = files
		self.api.gist_update(gist)
		return True

	def copy (self, name):
		content = sys.stdin.read()
		self.write_file(name, content)
		return 0

	def paste (self, name):
		content = self.read_file(name)
		if content is None:
			if not name:
				name = '<unnamed>'
			self.error(4, 'File not find: ' + name)
		sys.stdout.write(content)
		sys.stdout.flush()
		return 0



#----------------------------------------------------------------------
# main
#----------------------------------------------------------------------
def main(args = None):
	args = args and args or sys.argv
	args = [ n for n in args ]
	program = len(args) > 0 and args[0] or 'cloudclip.py'
	if len(args) < 2 or args[1] in ('-h', '--help'):
		print 'usage: %s <operation> [...]'%program
		print 'operations:'
		head = '    ' + program
		# print head, '{-i --init} token [id]'
		# print head, '{-c --copy} [name]'
		# print head, '{-p --paste} [name]'
		# print head, '{-l --list}'
		# print head, '{-e --clean}'
		print ''
		print '-i <token> [id]  Initialize token and id, create a new gist if id is empty'
		print '-c [name]    Takes the standard input and places it in the cloud'
		print '-p [name]    Read content from cloud and output to standard output'
		print '-l           List information of the gist'
		print '-e           Clean the clipboard'
		print ''
		print 'A github access token is needed before everything, you can generate a new'
		print 'one from: https://github.com/settings/tokens'
		print ''
		print 'Create a new gist with "-i token" on your own PC, remember the gist id.'
		print 'then use "-i token id" on a remote one which you may exchange data with.'
		print ''
		return 0

	cmd = args[1]

	if not os.path.exists(os.path.expanduser('~/.config')):
		os.mkdir(os.path.expanduser('~/.config'))

	cp = CloudClip('~/.config/cloudclip.conf')

	# check token/id from system environ
	env_token = os.environ.get('CLOUDCLIP_TOKEN', '')
	env_gistid = os.environ.get('CLOUDCLIP_ID', '')

	if env_token:
		cp.set_token(env_token)
	if env_gistid:
		cp.set_id(env_gistid)

	if (not os.path.exists(cp.ininame)) and (not cp.config['token']):
		if not cmd in ('-i', '--init'):
			text = 'uses "%s -i" to initialize your token\n'%program
			text += 'get a new token from: https://github.com/settings/tokens'
			cp.error(4, text)
			return 4
	elif not cp.config['id']:
		text = 'uses "%s -i" to indicate or create a gist id'%program
		cp.error(5, text)
		return 5
	
	try:
		if cmd in ('-i', '--init'):
			if len(args) < 3:
				cp.error(6, 'missing token, see "%s -h"'%program)
				return 6
			token = args[2]
			gistid = len(args) >= 4 and args[3] or None
			cp.login(token, gistid)
			return 0

		if cmd in ('-c', '--copy'):
			name = len(args) >= 3 and args[2] or None
			cp.copy(name)
			return 0

		if cmd in ('-p', '--paste'):
			name = len(args) >= 3 and args[2] or None
			cp.paste(name)
			return 0

		if cmd in ('-l', '--list'):
			cp.list_info()
			return 0

		if cmd in ('-e', '--clean'):
			cp.clear()
			return 0

		cp.error(7, 'unknow command: ' + cmd)

	except GistError as e:
		text = 'unknow'
		if e.code == 401:
			text = 'Bad credentials, token may be invalid\n'
			text += 'uses "%s -h" to see the help'%program
		elif e.code == 404:
			text = 'File not find, are you using the right gist id ?\n'
			text += 'uses "%s -h" to see the help'%program
		cp.error(8, text)

	return 0
		


#----------------------------------------------------------------------
# testing case
#----------------------------------------------------------------------
if __name__ == '__main__':
	token = ''
	ga = GistApi('skywind3000', token)
	# ga.https = False

	def test1():
		r = ga.list()
		for item in r:
			print item['id'], item['description']
		id = '4efdb6975821b180310174a2e7dc9581'
		# id = 'alksdjflajds'
		# print ''
		r = ga.get(id)
		print json.dumps(r, indent = 2)
		return 0

	def test2():
		files = {}
		files['hello.txt'] = {'content': 'Hello, World !!'}
		files['abc.txt'] = {'content': 'abc'}
		r = ga.create('<hello>', files)
		print json.dumps(r, indent = 2)

	def test3():
		files = {}
		files['hello.txt'] = {'content': 'Hello, World !!\x00234234'}
		files['abc.txt'] = {'content': 'abc: ' + str(time.time())}
		files['<general>'] = {'content': '3'}
		id = 'f1c7b8aa521c4634e9ad4882fedfad8c'
		r = ga.edit(id, '<hello>', files)
		print json.dumps(r, indent = 2)

	def test4():
		id = '4792620aea356a437d57aadd5e579500'
		r = ga.delete(id)
		print json.dumps(r, indent = 2)

	def test5():
		cc = CloudClip('~/.config/cloudclip.conf')
		cc.login(token, '')
		return 0

	def test6():
		cc = CloudClip('~/.config/cloudclip.conf')
		cc.list_info()
		text = 'now is ' + time.strftime('%Y-%m-%d %H:%M:%S')
		print 'uploading: ', text
		cc.write_file('test', text)
		print 'reading: ', cc.read_file('test')

	def test7():
		args = ['-c', 'happy']
		args = ['-p', 'happy']
		args = ['-p', 'happy']
		# args = ['-l', 'happy']
		args = ['-l', '1234']
		main(sys.argv[:1] + args)
		return 0

	# test7()
	sys.exit(main())




#  vim: set ts=4 sw=4 tw=0 noet :


