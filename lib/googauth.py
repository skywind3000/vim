#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# googauth.py - Google Authenticator
#
# Created by skywind on 2018/08/10
# Last Modified: 2018/08/10 21:50
#
#======================================================================
from __future__ import print_function
import sys
import time
import base64
import hashlib
import hmac
import struct
import os


#----------------------------------------------------------------------
# python 2/3 compatible
#----------------------------------------------------------------------
if sys.version_info[0] >= 3:
	long = int
	unicode = str
	xrange = range


#----------------------------------------------------------------------
# generate verification code from secret key and value 
#----------------------------------------------------------------------
def generate_code(secret, value = None):
	if value is None:
		value = int(time.time() / 30)
	value = struct.pack('>q', value)

	secretkey = base64.b32decode(secret.upper())

	hash = hmac.new(secretkey, value, hashlib.sha1).digest()

	offset = struct.unpack('>B', hash[-1:])[0] & 0xf
	truncated_hash = hash[offset:offset + 4]

	truncated_hash = struct.unpack('>L', truncated_hash)[0]
	truncated_hash &= 0x7fffffff
	truncated_hash %= 1000000

	return '%06d' % truncated_hash


#----------------------------------------------------------------------
# counter based code varification
#----------------------------------------------------------------------
def verify_counter_based(secret, code, counter, window = 3):
	if (not isinstance(code, str)) and (not isinstance(code, unicode)):
		raise TypeError('code must be a string')

	for offset in xrange(1, window + 1):
		valid_code = generate_code(secret, counter + offset)
		if code == valid_code:
			return counter + offset
	
	return None


#----------------------------------------------------------------------
# time based code verification
#----------------------------------------------------------------------
def verify_time_based(secret, code, window = 3):
	if (not isinstance(code, str)) and (not isinstance(code, unicode)):
		raise TypeError('code must be a string')

	epoch = int(time.time() / 30)

	for offset in xrange(-(window // 2), window - (window // 2)):
		valid_code = generate_code(secret, epoch + offset)
		if code == valid_code:
			return epoch + offset
	
	return None


#----------------------------------------------------------------------
# generate_secretkey
#----------------------------------------------------------------------
def generate_secret_key(length = 16):

	def _generate_random_bytes():
		sha_hash = hashlib.sha512()
		sha_hash.update(os.urandom(8192))
		byte_hash = sha_hash.digest()

		for i in xrange(6):
			sha_hash = hashlib.sha512()
			sha_hash.update(byte_hash)
			byte_hash = sha_hash.digest()

		return byte_hash
	
	if length < 8 or length > 128:
		raise TypeError('Secret key length is invalid.')

	byte_hash = _generate_random_bytes()
	if length > 102:
		byte_hash += _generate_random_bytes()
	
	text = base64.b32encode(byte_hash)[:length]
	text = str(text.decode('latin1'))

	return text


#----------------------------------------------------------------------
# get url
#----------------------------------------------------------------------
def get_otpauth_url(user, domain, secret):
	return 'otpauth://totp/' + user + '@' + domain + '?secret=' + secret


#----------------------------------------------------------------------
# barcode 
#----------------------------------------------------------------------
def get_barcode_url(user, domain, secret):
	import urllib
	if sys.version_info[0] < 3:
		from urllib import urlencode
	else:
		from urllib.parse import urlencode
	url = 'https://www.google.com/chart?chs=200x200&chld=M|0&cht=qr&'
	opt_url = get_otpauth_url(user, domain, secret)
	url += urlencode({'chl': opt_url})
	return url


#----------------------------------------------------------------------
# tabulify: style = 0, 1, 2
#----------------------------------------------------------------------
def tabulify (rows, style = 0):
	colsize = {}
	maxcol = 0
	output = []
	if not rows:
		return ''
	for row in rows:
		maxcol = max(len(row), maxcol)
		for col, text in enumerate(row):
			text = str(text)
			size = len(text)
			if col not in colsize:
				colsize[col] = size
			else:
				colsize[col] = max(size, colsize[col])
	if maxcol <= 0:
		return ''
	def gettext(row, col):
		csize = colsize[col]
		if row >= len(rows):
			return ' ' * (csize + 2)
		row = rows[row]
		if col >= len(row):
			return ' ' * (csize + 2)
		text = str(row[col])
		padding = 2 + csize - len(text)
		pad1 = 1
		pad2 = padding - pad1
		return (' ' * pad1) + text + (' ' * pad2)
	if style == 0:
		for y, row in enumerate(rows):
			line = ''.join([ gettext(y, x) for x in xrange(maxcol) ])
			output.append(line)
	elif style == 1:
		if rows:
			newrows = rows[:1]
			head = [ '-' * colsize[i] for i in xrange(maxcol) ]
			newrows.append(head)
			newrows.extend(rows[1:])
			rows = newrows
		for y, row in enumerate(rows):
			line = ''.join([ gettext(y, x) for x in xrange(maxcol) ])
			output.append(line)
	elif style == 2:
		sep = '+'.join([ '-' * (colsize[x] + 2) for x in xrange(maxcol) ])
		sep = '+' + sep + '+'
		for y, row in enumerate(rows):
			output.append(sep)
			line = '|'.join([ gettext(y, x) for x in xrange(maxcol) ])
			output.append('|' + line + '|')
		output.append(sep)
	return '\n'.join(output)


#----------------------------------------------------------------------
# load ini
#----------------------------------------------------------------------
def load_ini(ininame, codec = None):
	try:
		content = open(ininame, 'rb').read()
	except IOError:
		content = b''
	if content[:3] == b'\xef\xbb\xbf':
		text = content[3:].decode('utf-8')
	elif codec is not None:
		text = content.decode(codec, 'ignore')
	else:
		codec = sys.getdefaultencoding()
		text = None
		for name in [codec, 'gbk', 'utf-8']:
			try:
				text = content.decode(name)
				break
			except:
				pass
		if text is None:
			text = content.decode('utf-8', 'ignore')
	if sys.version_info[0] < 3:
		import StringIO
		import ConfigParser
		sio = StringIO.StringIO(text)
		cp = ConfigParser.ConfigParser()
		cp.readfp(sio)
	else:
		import configparser
		cp = configparser.ConfigParser()
		cp.read_string(text)
	config = {}
	for sect in cp.sections():
		for key, val in cp.items(sect):
			lowsect, lowkey = sect.lower(), key.lower()
			config.setdefault(lowsect, {})[lowkey] = val
	return config


#----------------------------------------------------------------------
# list code
#----------------------------------------------------------------------
def list_code(table, cont):
	while True:
		current = int(time.time())
		epoch = current // 30
		life = 30 - current % 30
		rows = []
		rows.append([ 'User', 'Domain', 'Code', 'Life Time' ])
		for record in table:
			secret = record[0]
			user = record[1]
			domain = record[2]
			code = generate_code(secret, epoch)
			rows.append([ user, domain, code, '  %d (s)'%life ])
		style = os.environ.get('GOOGAUTH_STYLE', 2)
		print(tabulify(rows, int(style)))
		# print()
		if not cont:
			break
		print('press Ctrl+C to break ...')
		try:
			time.sleep(1)
		except KeyboardInterrupt:
			print()
			break
		print()
	return 0


#----------------------------------------------------------------------
# main
#----------------------------------------------------------------------
def main(argv = None):
	argv = argv and argv or sys.argv
	argv = [ n for n in argv ]
	if len(argv) <= 1:
		prog = argv[0]
		print('usage: %s <operation> [...]'%prog)
		print('operations:')
		head = '    %s '%prog
		print(head, '{-c --create} [user] [domain]')
		print(head, '{-v --verify} secret code')
		print(head, '{-d --display} secret')
		print(head, '{-l --list} filename [--continue]')
		return 0
	cmd = argv[1]
	if cmd in ('-c', '--create'):
		key = generate_secret_key()
		print('secret:', key)
		user = len(argv) > 2 and argv[2] or ''
		domain = len(argv) > 3 and argv[3] or ''
		print('url:', get_otpauth_url(user, domain, key))
		print('barcode:', get_barcode_url(user, domain, key))
		return 0
	if cmd in ('-v', '--verify'):
		if len(argv) < 4:
			print('require secret and code parameters')
			return 1
		key = argv[2]
		code = argv[3]
		if not verify_time_based(key, code):
			print('verification failed')
			return 2
		print('verification succeeded')
		return 0
	if cmd in ('-d', '--display'):
		if len(argv) < 3:
			print('require secret parameter')
			return 1
		key = argv[2]
		print(generate_code(key))
		return 0
	if cmd in ('-l', '--list'):
		if len(argv) < 3:
			print('require file name')
			return 1
		name = argv[2]
		if '~' in name:
			name = os.path.expanduser(name)
		name = os.path.abspath(name)
		if not os.path.exists(name):
			print('can not read: %s'%name)
			return 255
		cont = False
		if len(argv) >= 4:
			if argv[3] in ('-', '-c', '--continue'):
				cont = True
		config = load_ini(name)
		keys = []
		for key in config:
			text = str(key)
			try:
				num = int(key)
				text = num
			except:
				pass
			keys.append((text, key))
		keys.sort()
		table = []
		for _, key in keys:
			cfg = config[key]
			if not cfg:
				continue
			if 'secret' not in cfg:
				continue
			secret = cfg['secret'].strip()
			user = cfg.get('user', '').strip()
			domain = cfg.get('domain', '').strip()
			table.append((secret, user, domain))
		list_code(table, cont)
		return 0
	print('unknown operation')
	return 1



#----------------------------------------------------------------------
# testing case
#----------------------------------------------------------------------
if __name__ == '__main__':
	def test1():
		key = generate_secret_key()
		code = generate_code(key)
		print(code)
		print(verify_time_based(key, code))
		print(generate_secret_key())
		print(get_otpauth_url('skywind3000', 'uex', key))
		print(get_barcode_url('skywind3000', 'uex', key))
		return 0
	def test2():
		key = generate_secret_key()
		code = generate_code(key)
		argv = [sys.argv[0], '-v', key, code]
		main(argv)
		print(code)
		main([sys.argv[0], '-d', key])
		return 0
	def test3():
		rows = []
		rows.append(['ID', 'Name', 'Score'])
		rows.append(['1', 'Lin Wei', '10'])
		rows.append(['2', 'Zhang Jia', '20'])
		rows.append([100, 'Cheng Jing Yi', '100'])
		rows.append([102, 'Li Lei', '99'])
		print(tabulify(rows, 2))
		# tabulify([[],[]])
		return 0
	def test4():
		args = [ sys.argv[0], '-l', '~/.config/googauth.ini', '-c' ]
		main(args)
		return 0
	# test1()
	argv = None
	# argv = [sys.argv[0], '-v', '']
	# test4()
	main(argv)



