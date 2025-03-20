#! /usr/bin/env python3
# -*- coding: utf-8 -*-
#======================================================================
#
# credential.py - 
#
# Created by skywind on 2025/03/19
# Last Modified: 2025/03/19 15:46:10
#
#======================================================================
import sys
import time
import os
import random
import base64
import socket
import platform
import hashlib
import uuid
import subprocess


#----------------------------------------------------------------------
# random temp 
#----------------------------------------------------------------------
def tmpname (filename, fill = 5):
    while 1:
        name = '.' + str(int(time.time() * 1000000))
        for i in range(fill):
            k = random.randint(0, 51)
            name += (k < 26) and chr(ord('A') + k) or chr(ord('a') + k - 26)
        test = filename + name + str(os.getpid())
        if not os.path.exists(test):
            return test
    return None


#----------------------------------------------------------------------
# replace file atomicly
#----------------------------------------------------------------------
def replace_file(srcname, dstname):
    if sys.platform[:3] != 'win':
        try:
            os.rename(srcname, dstname)
        except OSError:
            return False
    else:
        import ctypes.wintypes
        kernel32 = ctypes.windll.kernel32
        wp, vp, cp = ctypes.c_wchar_p, ctypes.c_void_p, ctypes.c_char_p
        DWORD, BOOL = ctypes.wintypes.DWORD, ctypes.wintypes.BOOL
        kernel32.ReplaceFileA.argtypes = [ cp, cp, cp, DWORD, vp, vp ]
        kernel32.ReplaceFileW.argtypes = [ wp, wp, wp, DWORD, vp, vp ]
        kernel32.ReplaceFileA.restype = BOOL
        kernel32.ReplaceFileW.restype = BOOL
        kernel32.GetLastError.argtypes = []
        kernel32.GetLastError.restype = DWORD
        success = False
        try:
            os.rename(srcname, dstname)
            success = True
        except OSError:
            pass
        if success:
            return True
        if sys.version_info[0] < 3 and isinstance(srcname, str):
            hr = kernel32.ReplaceFileA(dstname, srcname, None, 2, None, None)
        else:
            hr = kernel32.ReplaceFileW(dstname, srcname, None, 2, None, None)
        if not hr:
            return False
    return True


#----------------------------------------------------------------------
# atomic file write
#----------------------------------------------------------------------
def atomic_file_write(filename, text):
    if isinstance(text, str):
        content = text.encode('utf-8', 'ignore')
    else:
        content = text
    temp = tmpname(filename)
    with open(temp, 'wb') as fp:
        fp.write(content)
    if not replace_file(temp, filename):
        return False
    return True


#----------------------------------------------------------------------
# read file content
#----------------------------------------------------------------------
def file_read(filename):
    if not os.path.exists(filename):
        return None
    with open(filename, 'rb') as fp:
        content = fp.read()
        return content.decode('utf-8', 'ignore')
    return None


#----------------------------------------------------------------------
# string encrypt
#----------------------------------------------------------------------
def string_encrypt(text, key):
    if not text:
        return text
    if not key:
        key = ''
    key = key.encode('utf-8')
    text = text.encode('utf-8')
    keylen = len(key)
    textlen = len(text)
    result = bytearray(textlen)
    if keylen > 0:
        for i in range(textlen):
            result[i] = text[i] ^ key[i % keylen]
    else:
        for i in range(textlen):
            result[i] = text[i]
    index = 1
    while index < textlen:
        result[index] ^= result[index - 1]
        index += 1
    return base64.b32encode(result).decode('ascii').lower()


#----------------------------------------------------------------------
# string decrypt
#----------------------------------------------------------------------
def string_decrypt(text, key):
    if not text:
        return text
    if not key:
        key = ''
    key = key.encode('utf-8')
    text = base64.b32decode(text.upper().strip())
    if not text:
        return ''
    keylen = len(key)
    textlen = len(text)
    result = bytearray(textlen)
    for i in range(textlen):
        result[i] = text[i]
    index = 1
    previous = (textlen > 0) and result[0] or 0
    while index < textlen:
        old = result[index]
        result[index] ^= previous
        previous = old
        index += 1
    if keylen > 0:
        for i in range(textlen):
            result[i] = result[i] ^ key[i % keylen]
    return result.decode('utf-8', 'ignore')


#----------------------------------------------------------------------
# generate host uuid
#----------------------------------------------------------------------
def __generate_host_uuid(additional = None):
    components = []
    components.append(socket.gethostname())
    try:
        if sys.platform[:3] != 'win':
            if os.path.exists('/etc/machine-id'):
                with open('/etc/machine-id', 'r') as f:
                    t = f.read().strip()
                    components.append(t)
        else:
            result = subprocess.check_output('wmic csproduct get uuid').decode()
            hardware_id = result.split('\n')[1].strip()
            components.append(hardware_id)
    except:
        pass
    try:
        mac = uuid.getnode()
        if ((mac >> 40) & 0x01) == 0:
            t = uuid.uuid5(uuid.NAMESPACE_DNS, str(mac))
            components.append(str(t))
    except:
        pass
    try:
        if os.path.exists('/sys/class/dmi/id/product_uuid'):
            with open('/sys/class/dmi/id/product_uuid', 'r') as f:
                t = str(f.read().strip())
                components.append(t)
    except:
        pass
    cpuinfo = platform.processor()
    if cpuinfo:
        components.append(cpuinfo)
    if additional:
        components.append(additional)
    unique_id = ':'.join(components)
    hash_obj = hashlib.sha256(unique_id.encode('utf-8', 'ignore'))
    digit = hash_obj.hexdigest()
    return f"{digit[:8]}-{digit[8:12]}-{digit[12:16]}-{digit[16:20]}-{digit[20:32]}"


#----------------------------------------------------------------------
# generate machine uuid
#----------------------------------------------------------------------
def fetch_uuid(key):
    if '__uuid' not in sys.modules[__name__].__dict__:
        sys.modules[__name__].__dict__['__uuid'] = {}
    uuidmap = sys.modules[__name__].__dict__['__uuid']
    if key not in uuidmap:
        uuidmap[key] = __generate_host_uuid(key)
    return uuidmap[key]


#----------------------------------------------------------------------
# profile_uuid
#----------------------------------------------------------------------
def profile_uuid():
    key = 'profile:' + os.path.expanduser('~/uuid')
    return fetch_uuid(key)


#----------------------------------------------------------------------
# samples for git credential standard input
#----------------------------------------------------------------------
SAMPLES = '''
get 'protocol=https\nhost=github.com\nwwwauth[]=Basic realm="GitHub"\n'
store 'protocol=https\nhost=github.com\nusername=jack\npassword=XXXX\n'
erase 'protocol=https\nhost=github.com\nusername=jack\npassword=Username for \'https://github.com\': jack\nwwwauth[]=Basic realm="GitHub"\n'
'''


#----------------------------------------------------------------------
# git credential helper
#----------------------------------------------------------------------
class Credential (object):

    def __init__ (self, filename = None):
        if not filename:
            self.filename = os.path.expanduser('~/.git-shadow')
        else:
            self.filename = filename
        if '~' in self.filename:
            self.filename = os.path.expanduser(self.filename)
        self.__uuid = None
        self.data = []

    def __len__ (self):
        return len(self.data)

    def __getitem__ (self, key):
        return self.data[key]

    def __setitem__ (self, key, value):
        self.data[key] = value

    def __iter__ (self):
        return iter(self.data)

    def uuid (self):
        if not self.__uuid:
            self.__uuid = profile_uuid()
        return self.__uuid

    def normalize (self, text):
        text = text and text or ''
        text = text.replace(':', '').replace('\n', '').replace('\r', '')
        return text.strip('\r\n\t ')

    def load (self):
        self.data = []
        uuid = self.uuid()
        content = file_read(self.filename)
        for line in content.split('\n'):
            line = line.strip('\r\n\t ')
            if not line:
                continue
            if line.startswith('#'):
                continue
            part = line.split(':')
            if len(part) < 4:
                continue
            item = {}
            item['protocol'] = self.normalize(part[0])
            item['host'] = self.normalize(part[1])
            item['username'] = self.normalize(part[2])
            password = part[3].strip('\r\n\t ')
            item['password'] = string_decrypt(password, uuid)
            self.data.append(item)
        return True

    def save (self):
        uuid = self.uuid()
        content = []
        for item in self.data:
            line = []
            line.append(self.normalize(item.get('protocol', '')))
            line.append(self.normalize(item.get('host', '')))
            line.append(self.normalize(item.get('username', '')))
            line.append(string_encrypt(item.get('password', ''), uuid))
            content.append(':'.join(line))
        content = '\n'.join(content)
        return atomic_file_write(self.filename, content)

    def get (self, protocol, host, username):
        protocol = self.normalize(protocol)
        host = self.normalize(host)
        username = self.normalize(username)
        for item in self.data:
            if item['protocol'] == protocol and item['host'] == host:
                if username:
                    if item['username'] == username:
                        return item
                else:
                    return item
        return None

    def store (self, protocol, host, username, password):
        protocol = self.normalize(protocol)
        host = self.normalize(host)
        username = self.normalize(username)
        for item in self.data:
            if item['protocol'] == protocol and item['host'] == host:
                if item['username'] == username:
                    item['password'] = password
                    return True
        item = {}
        item['protocol'] = protocol
        item['host'] = host
        item['username'] = username
        item['password'] = password
        self.data.append(item)
        return True

    def erase (self, protocol, host, username):
        protocol = self.normalize(protocol)
        host = self.normalize(host)
        username = self.normalize(username)
        return True


#----------------------------------------------------------------------
# parse git credential standard input
#----------------------------------------------------------------------
def parse_request(text):
    request = {}
    for line in text.split('\n'):
        line = line.strip('\r\n\t ')
        if not line:
            continue
        if line.startswith('#'):
            continue
        if '=' in line:
            key, _, value = line.partition('=')
            key = key.strip('\r\n\t ')
            value = value.strip('\r\n\t ')
            request[key] = value
    return request


#----------------------------------------------------------------------
# write application level log
#----------------------------------------------------------------------
def mlog(*args):
    import sys, codecs, os, time
    now = time.strftime('%Y-%m-%d %H:%M:%S')
    part = [ str(n) for n in args ]
    text = u' '.join(part)
    mm = sys.modules[__name__]
    logfile = mm.__dict__.get('_mlog_file', None)
    encoding = mm.__dict__.get('_mlog_encoding', 'utf-8')
    stdout = mm.__dict__.get('_mlog_stdout', True)
    if logfile is None:
        name = os.path.abspath(sys.argv[0])
        name = os.path.splitext(name)[0] + '.log'
        logfile = codecs.open(name, 'a', encoding = encoding, errors = 'ignore')
        mm._mlog_file = logfile
    content = '[%s] %s'%(now, text)
    if logfile:
        logfile.write(content + '\r\n')
        logfile.flush()
    if stdout:
        sys.stdout.write(content + '\n')
    return 0



#----------------------------------------------------------------------
# main entry
#----------------------------------------------------------------------
def main(argv = None):
    argv = [ n for n in (argv or sys.argv) ]
    if len(argv) <= 1:
        print("Usage: %s <options>" % argv[0])
        return 1
    action = argv[1]
    if action == 'get':
        text = sys.stdin.read()
        mlog('get', repr(text))
        sys.exit(1)
    elif action == 'store':
        text = sys.stdin.read()
        mlog('store', repr(text))
    elif action == 'erase':
        text = sys.stdin.read()
        mlog('erase', repr(text))
    else:
        mlog('unknow action', action)
    return 0


#----------------------------------------------------------------------
# testing suit
#----------------------------------------------------------------------
if __name__ == '__main__':

    def test1():
        argv = None
        main(argv)
        return 0

    def test2():
        key = '123456'
        t = string_encrypt('hello', key)
        q = string_decrypt(t, key)
        print(q)
        print(fetch_uuid('test'))
        print(fetch_uuid('test'))
        print(fetch_uuid('test2'))
        print(profile_uuid())
        print(profile_uuid())
        return 0

    test2()

