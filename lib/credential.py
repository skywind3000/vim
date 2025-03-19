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
    test1()



