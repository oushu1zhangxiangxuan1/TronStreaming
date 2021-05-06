from datetime import datetime
import threading
from typing import List, Any, Tuple
import os
import logging
from datetime import timedelta


def GetCurTimeString():
    return datetime.now().strftime("%Y%m%d%H%M%S_%f")


def _time_analyze_(func):
    from time import clock
    exec_times = 1

    def callf(*args, **kwargs):
        start = clock()
        for i in range(exec_times):
            r = func(*args, **kwargs)
        finish = clock()
        print("{:<20}{:10.6} s".format(func.__name__ + ":", finish - start))
        return r
    return callf


def _defer_lock_(lock: threading.Lock):
    lock.acquire()
    print("i am locked")

    def wrap(func):
        def wrap_1(*args, **kwargs):
            return func(*args)
        return wrap_1
    lock.release()
    print("i am unlocked")
    return wrap


def sync(lock):
    def syncWithLock(fn):
        def newFn(*args, **kwargs):
            lock.acquire()
            print("i am locked")
            try:
                return fn(*args, **kwargs)
            finally:
                lock.release()
                print("i am unlocked")
        # newFn.func_name = fn.func_name
        # newFn.__doc__ = fn.__doc__
        return newFn
    return syncWithLock


lock = threading.Thread()

tmp = 1


def yieldStatus():
    print("before while")
    while True:
        print("lock.acquire()")
        yield "lock"
        # lock.acquire()
        global tmp
        tmp = yield tmp
        print("res is:", tmp)
        # lock.release()
        print("lock.release()")
        print("after 2")
    print("after while")


def getStatus():
    print("before while")
    while True:
        print("before")
        yield 1
        print("after")
        print("after 2")
    print("after while")


def IndexSafe(key: Any, l: List[Any]) -> int:
    try:
        index = l.index(key)
        return index
    except ValueError:
        return -1
    else:
        raise


def file_cleaner(dirDel, retentionHour):
    if os.path.isdir(dirDel):
        files = os.listdir(dirDel)
        for f in files:
            filePath = os.path.join(dirDel, f)
            if os.path.isfile(filePath):
                fileMTime = os.stat(filePath).st_mtime
                if datetime.utcfromtimestamp(fileMTime) < datetime.now()-timedelta(hours=retentionHour):
                    logging.info("Removing file: %s", filePath)
                    os.remove(filePath)


def CheckPathAccess(path: str) -> Tuple[bool, str]:
    if not os.path.isdir(path):
        return False, "Dir not exists."
    if not os.access(path, os.W_OK):
        return False, "Permission denied."
    return True, None


if __name__ == "__main__":
    # print(GetCurTimeString())

    # lock = threading.Lock()
    # @sync(lock)
    # def testlock():
    #     print("i am in func")

    # testlock()
    # f = yieldStatus()

    # # print(f.send(1))
    # # print('---------')
    # print(next(f))
    # print('---------')
    # print(f.send(2))
    # print('---------')
    # print(next(f))
    # print('---------')
    # print(next(f))
    # print('---------')
    # print(f.send(3))
    print(CheckPathAccess("hahaha i am not exist"))
    print(CheckPathAccess("/tmp"))
