#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# crontab.py - yet another crond implementation in python
# author: skywind3000 (at) gmail.com, 2016-2023
# 
# Last Modified: 2023/04/04 15:06
#
# If you find yourself in a situation where you require a standalone
# crontab scheduler, there are a few reasons why this may be 
# necessary. For example, some embedded Linux systems may not allow 
# you to modify the system's built-in crontab, or you may simply 
# prefer to have a separate crontab on a Windows system. In either
# case, a standalone crontab scheduler can provide a reliable and 
# efficient solution.
#
# To define the time you can provide concrete values for 
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').
#
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
#
# For more information see the manual pages of crontab(5) and cron(8)
#
#======================================================================
from __future__ import print_function, unicode_literals
import sys
import time
import os


#----------------------------------------------------------------------
# python 2/3 compatible
#----------------------------------------------------------------------
if sys.version_info[0] >= 3:
    long = int
    unicode = str
    xrange = range

UNIX = (sys.platform[:3] != 'win') and True or False


#----------------------------------------------------------------------
# crontab
#----------------------------------------------------------------------
class crontab (object):

    def __init__ (self):
        self.daynames = {}
        self.monnames = {}
        DAYNAMES = ('sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat')
        MONNAMES = ('jan', 'feb', 'mar', 'apr', 'may', 'jun')
        MONNAMES = MONNAMES + ('jul', 'aug', 'sep', 'oct', 'nov', 'dec')
        for x in range(7):
            self.daynames[DAYNAMES[x]] = x
        for x in range(12):
            self.monnames[MONNAMES[x]] = x + 1
        self.timestamp = 0
        self.lastmin = -1

    # check_atom('0-10/2', (0, 59), 4) -> True
    # check_atom('0-10/2', (0, 59), 5) -> False
    def check_atom (self, text, minmax, value):
        if value < minmax[0] or value > minmax[1]:
            return None
        if minmax[0] > minmax[1]:
            return None
        text = text.strip('\r\n\t ')
        if text == '*':
            return True
        if text.isdigit():
            try: x = int(text)
            except: return None
            if x < minmax[0] or x > minmax[1]:
                return None
            if value == x:
                return True
            return False
        increase = 1
        if '/' in text:
            part = text.split('/')
            if len(part) != 2:
                return None
            try: increase = int(part[1])
            except: return None
            if increase < 1:
                return None
            text = part[0]
        if text == '*':
            x, y = minmax
        elif text.isdigit():
            try: x = int(text)
            except: return None
            if x < minmax[0] or x > minmax[1]:
                return None
            y = minmax[1]
        else:
            part = text.split('-')
            if len(part) != 2:
                return None
            try:
                x = int(part[0])
                y = int(part[1])
            except:
                return None
        if x < minmax[0] or x > minmax[1]:
            return None
        if y < minmax[0] or y > minmax[1]:
            return None
        if x <= y:
            if x <= value <= y:
                if increase == 1 or (value - x) % increase == 0:
                    return True
            return False
        else:
            if value <= y:
                if increase == 1 or (value - minmax[0]) % increase == 0:
                    return True
            elif value >= x:
                if increase == 1 or (value - x) % increase == 0:
                    return True
            return False
        return None

    # parse month and week information
    def check_token (self, text, minmax, value):
        for text in text.strip('\r\n\t ').split(','):
            text = text.lower()
            for x, y in self.daynames.items():
                text = text.replace(x, str(y))
            for x, y in self.monnames.items():
                text = text.replace(x, str(y))
            hr = self.check_atom(text, minmax, value)
            if hr is None:
                return None
            if hr:
                return True
        return False

    # split rule and command
    def split (self, text):
        text = text.strip('\r\n\t ')
        need = text[:1] == '@' and 1 or 5
        data, mode, line = [], 1, ''
        for i in range(len(text)):
            ch = text[i]
            if mode == 1:
                if ch.isspace():
                    data.append(line)
                    line = ''
                    mode = 0
                else:
                    line += ch
            else:
                if not ch.isspace():
                    if len(data) == need:
                        data.append(text[i:])
                        line = ''
                        break
                    line = ch
                    mode = 1
        if line:
            data.append(line)
        if len(data) < need:
            return None
        if len(data) == need:
            data.append('')
        return tuple(data[:need + 1])

    # input a datetime tuple like (2013, 10, 21, 16, 35)
    # returns True if the text match the given date-time.
    def check (self, text, datetuple, runtimes = 0):
        data = self.split(text)
        if not data:
            return None
        if len(data) == 2:
            entry = data[0].lower()
            if entry == '@reboot':
                return (runtimes == 0) and True or False
            if entry == '@shutdown':
                return (runtimes < 0) and True or False
            if entry in ('@yearly', '@annually'):
                data = self.split('0 0 1 1 * ' + data[1])
            elif entry == '@monthly':
                data = self.split('0 0 1 * * ' + data[1])
            elif entry == '@weekly':
                data = self.split('0 0 * * 0 ' + data[1])
            elif entry == '@daily':
                data = self.split('0 0 * * * ' + data[1])
            elif entry == '@midnight':
                data = self.split('0 0 * * * ' + data[1])
            elif entry == '@hourly':
                data = self.split('0 * * * * ' + data[1])
            else:
                return None
            if data is None:
                return None
        if len(data) != 6 or len(datetuple) != 5:
            return None
        year, month, day, hour, mins = datetuple
        if isinstance(month, str):
            month = month.lower()
            for x, y in self.monnames.items():
                month = month.replace(x, str(y))
            try:
                month = int(month)
            except:
                return None
        import datetime
        try:
            x = datetime.datetime(year, month, day).strftime("%w")
            weekday = int(x)
        except:
            return None
        hr = self.check_token(data[0], (0, 59), mins)
        if not hr: return hr
        hr = self.check_token(data[1], (0, 23), hour)
        if not hr: return hr
        hr = self.check_token(data[2], (0, 31), day)
        if not hr: return hr
        hr = self.check_token(data[3], (1, 12), month)
        if not hr: return hr
        hr = self.check_token(data[4], (0, 6), weekday)
        if not hr: return hr
        return True

    # 调用 crontab程序
    def call (self, command):
        import subprocess
        if sys.version_info[0] < 3:
            pid = subprocess.Popen(command, shell = True, close_fds = True)
        else:
            pid = subprocess.Popen(command, shell = True)
        return pid

    # 单位时间触发，返回成功调度的任务
    def interval (self, schedule, timestamp, workdir = '.', env = {}):
        runlist = []
        if not schedule:
            return []
        savedir = os.getcwd()
        if timestamp - self.timestamp >= 300:
            self.timestamp = long(timestamp)
            self.timestamp = self.timestamp - (self.timestamp % 10)
        while timestamp >= self.timestamp:
            now = time.localtime(self.timestamp)
            if now.tm_min != self.lastmin:
                datetuple = now[:5]
                for obj in schedule:
                    if self.check(obj['cron'], datetuple, 1):
                        if workdir:
                            os.chdir(workdir)
                        command = obj['command']
                        execute = command
                        for k, v in env.items():
                            execute = execute.replace('$(%s)'%k, str(v))
                        self.call(execute)
                        if workdir:
                            os.chdir(savedir)
                        obj['runtimes'] += 1
                        t = (obj['cron'], command, execute, obj['lineno'])
                        runlist.append(t + (obj['runtimes'], ))
                self.lastmin = now.tm_min
            self.timestamp += 10
        return runlist

    # 开启关闭时调用，返回在关闭时调度的任务，开启mode=0，关闭 mode=1
    def event (self, schedule, mode, workdir = '.', env = {}, wait = False):
        runlist = []
        pids = []
        savedir = os.getcwd()
        for obj in schedule:
            if self.check(obj['cron'], (0, 0, 0, 0, 0), mode):
                if workdir:
                    os.chdir(workdir)
                command = obj['command']
                execute = command
                for k, v in env.items():
                    execute = execute.replace('$(%s)'%k, str(v))
                pids.append(self.call(execute))
                if workdir:
                    os.chdir(savedir)
                obj['runtimes'] += 1
                t = (obj['cron'], command, execute, obj['lineno'])
                runlist.append(t + (obj['runtimes'], ))
        if wait:
            for pid in pids:
                pid.wait()
        return runlist

    # read crontab configuration and returns task list
    # or error line number
    def read (self, content, times = 0):
        schedule = []
        if not isinstance(content, str):
            raise ValueError('must be string')
        ln = 0
        for line in content.split('\n'):
            line = line.strip('\r\n\t ')
            ln += 1
            if line[:1] in ('#', ';', ''):
                continue
            hr = self.split(line)
            if hr is None:
                return ln
            obj = {}
            obj['cron'] = line
            obj['command'] = hr[-1]
            obj['runtimes'] = times
            obj['lineno'] = ln
            schedule.append(obj)
        return schedule



#----------------------------------------------------------------------
# load file and guess encoding
#----------------------------------------------------------------------
def load_file_text(filename, encoding = None):
    content = None
    if hasattr(filename, 'read'):
        try: content = filename.read()
        except: pass
    try:
        fp = open(filename, 'rb')
        content = fp.read()
        fp.close()
    except:
        pass
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
# daemon
#----------------------------------------------------------------------
def daemon():
    if sys.platform[:3] == 'win':
        return -1
    try:
        if os.fork() > 0: os._exit(0)
    except OSError:
        os._exit(1)
    os.setsid()
    os.umask(0)
    try:
        if os.fork() > 0: os._exit(0)
    except OSError:
        os._exit(1)
    return 0


#----------------------------------------------------------------------
# signals
#----------------------------------------------------------------------
closing = False

def sig_exit (signum, frame):
    global closing
    closing = True

def sig_chld (signum, frame):
    while 1:
        try:
            pid, status = os.waitpid(-1, os.WNOHANG)
        except:
            pid = -1
        if pid < 0: break
    return 0

def signal_initialize():
    import signal
    signal.signal(signal.SIGTERM, sig_exit)
    signal.signal(signal.SIGINT, sig_exit)
    signal.signal(signal.SIGABRT, sig_exit)
    if 'SIGQUIT' in signal.__dict__:
        signal.signal(signal.SIGQUIT, sig_exit)
    if 'SIGCHLD' in signal.__dict__:
        signal.signal(signal.SIGCHLD, sig_chld)
    if 'SIGPIPE' in signal.__dict__:
        signal.signal(signal.SIGPIPE, signal.SIG_IGN)
    return 0


#----------------------------------------------------------------------
# logs
#----------------------------------------------------------------------
LOGFILE = None
LOGSTDOUT = True

def mlog(text):
    global LOGFILE, LOGSTDOUT
    now = time.strftime('%Y-%m-%d %H:%M:%S')
    txt = '[%s] %s'%(now, text)
    if LOGFILE:
        LOGFILE.write(txt + '\n')
        LOGFILE.flush()
    if LOGSTDOUT:
        sys.stdout.write(txt + '\n')
        sys.stdout.flush()
    return 0

def errmsg(text):
    sys.stderr.write(text + '\n')
    sys.stderr.flush()
    return 0


#----------------------------------------------------------------------
# testing case
#----------------------------------------------------------------------
def main(args = None):
    if args is None:
        args = [ n for n in sys.argv ]
    import optparse
    p = optparse.OptionParser('usage: %prog [options] to start cron')
    p.add_option('-f', '--filename', dest = 'filename', metavar='FILE', help = 'config file name')
    p.add_option('-i', '--pid', dest = 'pid', help = 'pid file path')
    p.add_option('-l', '--log', dest = 'log', metavar='LOG', help = 'log file')
    p.add_option('-c', '--cwd', dest = 'dir', help = 'working dir')
    p.add_option('-d', '--daemon', action = 'store_true', dest = 'daemon', help = 'run as daemon')
    options, args = p.parse_args(args)
    if not options.filename:
        errmsg('No config file name. Try --help for more information.')
        return 2
    filename = options.filename
    if filename:
        if not os.path.exists(filename):
            filename = None
    if not filename:
        errmsg('invalid file name')
        return 4
    filetime = 0
    try:
        filetime = os.stat(filename).st_mtime
        text = load_file_text(filename)
    except:
        errmsg('cannot read %s'%filename)
        return 5

    # crontab initialize
    cron = crontab()

    # read content
    task = cron.read(text)
    if not isinstance(task, list):
        errmsg('%s:%d: error: syntax error'%(filename, task))
        return 1

    global LOGSTDOUT, LOGFILE
    if options.log:
        try:
            LOGFILE = open(options.log, 'a')
        except:
            errmsg('can not open: ' + options.log)
            return 6

    if options.daemon:
        if sys.platform[:3] == 'win':
            errmsg('daemon mode does support in windows')
        elif 'fork' not in os.__dict__:
            errmsg('can not fork myself')
        else:
            daemon()
            LOGSTDOUT = False

    if options.pid:
        try:
            fp = open(options.pid, 'w')
            fp.write('%d'%os.getpid())
            fp.close()
        except:
            pass

    signal_initialize()

    environ = {}
    for n in os.environ:
        environ[n] = os.environ[n]

    mlog('crontab start with %d task(s)'%len(task))

    if options.dir:
        if os.path.exists(options.dir):
            try:
                os.chdir(options.dir)
            except:
                mlog('can not chdir to %s'%options.dir)
        else:
            mlog('dir does not exist: %s'%options.dir)

    for node in cron.event(task, 0, env = environ):
        mlog('init: ' + node[1])

    loopcount = 0

    # main loop
    while not closing:
        ts = long(time.time())
        now = time.localtime(ts)[:5]   # noqa
        run = cron.interval(task, ts, env = environ)
        if run:
            for node in run:
                mlog('exec: ' + node[1])
        if loopcount % 10 == 0:
            newts = -1
            try:
                newts = os.stat(filename).st_mtime
            except:
                pass
            if newts > 0 and newts > filetime:
                content = None
                try:
                    time.sleep(0.1)
                    content = load_file_text(filename)
                except:
                    mlog('error open: ' + filename)
                    content = None
                if content is not None:
                    newtask = cron.read(content)
                    if not isinstance(newtask, list):
                        mlog('%s:%d: syntax error'%(filename, newtask))
                    else:
                        task = newtask
                        filetime = ts
                        mlog('refresh config with %d task(s)'%len(task))
        loopcount += 1
        time.sleep(1)

    for node in cron.event(task, -1, env = environ, wait = True):
        mlog('quit: ' + node[1])

    mlog('terminated')

    return 0


#----------------------------------------------------------------------
# testing case
#----------------------------------------------------------------------
if __name__ == '__main__':
    def test1():
        print(os.stat('crontab.cfg').st_mtime)
        return 0
    def test2():
        cron = crontab()
        task = cron.read(load_file_text('crontab.cfg'))
        ts = time.time()
        for n in cron.event(task, 0):
            print('reboot', n[0])
        for i in range(3600):
            now = time.localtime(ts)[:5]
            res = cron.interval(task, ts)
            for n in res:
                print(now, n[0])
            ts += 1
        for n in cron.event(task, -1):
            print('shutdown', n[0])
        return 0
    def test3():
        args = [ 'crontab', '--filename=crontab.cfg', '--pid=crontab.pid' ]
        #args = ['crontab', '--help']
        main(args)
        return 0
    # test3()
    sys.exit(main())



