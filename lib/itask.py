#! /usr/bin/env python
# -*- coding: utf-8 -*-
#======================================================================
#
# itask.py - background task executer
#
# Created by skywind on 2024/05/26
# Last Modified: 2024/05/26 05:50:57
#
#======================================================================
import sys
import time
import threading
import queue


#----------------------------------------------------------------------
# itask
#----------------------------------------------------------------------
class itask (object):
    def run (self):             # 线程池调用的主函数，self.__env__是环境字典
        return 0
    def done (self):            # 主线程调用，如果 run 无异常
        return 0
    def error (self, what):     # 主线程调用，如果 run 抛出异常了
        return 0
    def final (self):           # 主线程调用，结束调用，释放资源用
        return 0


#----------------------------------------------------------------------
# thread executor
#----------------------------------------------------------------------
class TaskExecutor (object):

    # 初始化，name为名称 num为需要启动多少个线程
    def __init__ (self, name = '', num = 1, slap = 0.05):
        self.name = name
        self.stderr = None
        self.__q1 = queue.Queue(0)
        self.__q2 = queue.Queue(0)
        self.__threads = []                 # 线程池
        self.__stop_unconditional = False   # 强制停止标志，有该标志就停止
        self.__stop_empty_queue = False     # 完成停止标志，有该标志且无新任务才退出
        self.__active_thread_num = 0        # 活跃数量
        self.__thread_num = num             # 线程数量
        self.__lock_main = threading.Lock()
        self.__lock_output = threading.Lock()
        self.__lock_environ = threading.Lock()
        self.__cond_main = threading.Condition()
        self.__slap = slap
        self.__environ = {}
        
    # error output
    def log (self, text):
        self.__lock_output.acquire()
        if self.stderr:
            self.stderr.write(text + '\n')
        self.__lock_output.release()
        return 0

    # get thread-local environment dictionary
    def environ (self, index):
        obj = None
        with self.__lock_environ:
            if index not in self.__environ:
                self.__environ[index] = {}
            obj = self.__environ[index]
        return obj

    # get thread-local environment dictionary
    def __getitem__ (self, index):
        return self.environ(index)

    # 内部函数：线程主函数，从请求队列取出 task执行完 run后，塞入结果队列
    def __run (self, env):
        self.__active_thread_num += 1
        name = threading.currentThread().name
        env['_NAME'] = name
        while not self.__stop_unconditional:
            if self.__stop_empty_queue:
                break
            task = None
            self.__cond_main.acquire()
            try:
                if self.__q1.qsize() == 0:
                    #5秒的超时设置
                    self.__cond_main.wait(5)                    
                else:
                    task = self.__q1.get(True, self.__slap)
            except queue.Empty:
                pass            
            self.__cond_main.release()
            if task is None:
                continue
            ts = time.time()
            hr = None
            try:
                task.__env__ = env
                hr = task.run()
                task.__env__ = None
                task.__return__ = hr
                task.__error__ = None
                task.__elapse__ = time.time() - ts
                task.__done__ = True
            except Exception as e:
                task.__return__ = hr
                task.__error__ = e
                task.__elapse__ = time.time() - ts
                task.__done__ = False
                self.log('[%s] error in run(): %s\n%s'%(name, e, callstack()))
                #self.log('[%s] error in run(): %s'%(name, e))
                #for line in callstack().split('\n'):
                #   self.log(line)
            except:
                task.__return__ = hr
                task.__error__ = None
                task.__elapse__ = time.time() - ts
                task.__done__ = False
                self.log('[%s] unknow error in run()\n%s'%(name, e, callstack()))
                #self.log('[%s] unknow error in run()'%(name))
                #for line in callstack().split('\n'):
                #   self.log(line)
            task.__env__ = None
            self.__q2.put(task)
            self.__q1.task_done()
            if task is None:
                break
        self.__active_thread_num -= 1
        return 0
    
    # 内部函数：更新状态，从结果队列取出task 并执行 done, error, final
    def __update (self, limit = -1):
        count = 0
        while True:
            #为了在需要发送大量包的时候，保证其他操作能够被调用到，一次最多发送50个包
            if count > limit and limit >= 0:
                break
            try:
                task = self.__q2.get(False)
            except queue.Empty:
                break
            if node is not None:
                name = 'main'
                node.task.__error__ = node.ex
                node.task.__elapse__ = node.ts
                if node.ok:
                    try: 
                        node.task.done()
                    except Exception as e: 
                        self.log('[main] error in done(): %s\n%s'%(e, callstack()))
                        #self.log('[main] error in done(): %s'%(e))
                        #for line in callstack().split('\n'):
                        #   self.log(line)
                    except:
                        self.log('[main] unknow error in done()\n%s' % (callstack(),))
                        #self.log('[main] unknow error in done()')
                        #for line in callstack().split('\n'):
                        #   self.log(line)
                else:
                    try: 
                        node.task.error(node.ex)
                    except Exception as e: 
                        self.log('[main] error in error(): %s\n%s'% (e, callstack()))
                        #self.log('[main] error in error(): %s'%e)
                        #for line in callstack().split('\n'):
                        #   self.log(line)
                    except:
                        self.log('[main] unknow error in error()\n%s' % (callstack(),))
                        #self.log('[main] unknow error in error()')
                        #for line in callstack().split('\n'):
                        #   self.log(line)
                try: 
                    node.task.final()
                except Exception as e: 
                    self.log('[main] error in final(): %s\n%s'%(e, callstack()))
                    #self.log('[main] error in final(): %s'%(e))
                    #for line in callstack().split('\n'):
                    #   self.log(line)
                except:
                    self.log('[main] unknow error in final()\n%s' % callstack())
                    #self.log('[main] unknow error in final()')
                    #for line in callstack().split('\n'):
                    #   self.log(line)
                count += 1
            self.__q2.task_done()
            if node is None:
                break
        return count

    # 将一个 task塞入请求队列
    def push (self, task, update = False):
        node = OBJECT(task = task)
        self.__cond_main.acquire()
        self.__q1.put(node)
        if update:
            #self.__update()
            pass
        self.__cond_main.notify()
        self.__cond_main.release()
        return 0

    # 更新状态：从结果队列取出task 并执行 done, error, final
    # limit为每次运行多少条主线程消息，< 0 为持续处理完所有消息 ，这里默认数值为50，主要是防止连续收发很多包导致主线程卡住
    def update (self, limit = 50):
        self.__update(limit)

    # 等待线程池处理完所有任务并结束
    def join (self, timeout = 0, discard = False):
        self.__lock_main.acquire()
        self.__stop_empty_queue = True
        if self.__threads:
            self.__stop_unconditional = False
            if discard:
                self.__stop_unconditional = True
            self.__update()
            ts = time.time()
            while self.__active_thread_num > 0:
                #唤醒全部等待中的线程
                self.__cond_main.acquire()              
                self.__cond_main.notifyAll()
                self.__cond_main.release()

                self.__update()
                time.sleep(0.01)
                if timeout > 0:
                    if time.time() - ts >= timeout:
                        break
            timeout = max(timeout * 0.2, 0.2)
            slap = timeout / self.__thread_num
            for th in self.__threads:
                th.join(slap)
            self.__update()
            self.__threads = []
        self.__lock_main.release()
        return 0
    
    # 开始线程池：envctor/envdtor分别是线程环境的初始化反初始化函数
    # 如果提供的话，每个线程开始都会调用 envctor(env)，结束前都会调用
    # envdtor(env), 其中 env是每个独立线程特有的环境变量，是一个 OBJECT
    def start (self, envctor = None, envdtor = None):
        hr = False
        self.__lock_main.acquire()
        if not self.__threads:
            self.__q1 = queue.Queue(0)
            self.__q2 = queue.Queue(0)
            self.__stop_unconditional = False
            self.__stop_empty_queue = False
            self.__active_thread_num = False
            self.__envctor = envctor
            self.__envdtor = envdtor
            for i in range(self.__thread_num):
                name = self.name + '.%d'%(i + 1)
                env = self.__environ[i]
                th = threading.Thread(None, self.__run, name, [env])
                th.setDaemon(True)
                th.start()
                self.__threads.append(th)
            hr = True
        self.__lock_main.release()
        return hr
    
    # 强制结束线程池
    def stop (self):
        self.__lock_main.acquire()
        self.__stop_empty_queue = True
        self.__stop_unconditional = True
        self.__lock_main.release()
        self.__cond_main.acquire()              
        self.__cond_main.notifyAll()
        self.__cond_main.release()
    
    # 取得请求队列的任务数量
    def pending_size (self):
        return self.__q1.qsize()
    
    # get send queue size
    def waiting_size (self):
        return self.__q2.qsize()


