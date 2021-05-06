import os
import sys
# print("sys.path: ", sys.path)
# print("current path: ", os.getcwd())
# print("os.path.abspath('.'): ", os.path.abspath('.'))

# LITTLEBOY_CV_HOME: str = os.getcwd()

PROC_PATH: str = os.path.abspath(os.path.realpath(__file__))
# LITTLEBOY_CV_HOME: str = os.path.abspath(
#     os.path.dirname(PROC_PATH)+os.path.sep+"..")
DEV_PATH: str = os.path.abspath(os.path.dirname(PROC_PATH)+os.path.sep+"..")
sys.path.append(DEV_PATH)

# print("DEV_PATH:", DEV_PATH)

# print("PROC_PATH:", PROC_PATH)
# print("LITTLEBOY_CV_HOME:", LITTLEBOY_CV_HOME)

# print("os.getcwd():", os.getcwd())


def touch():
    pass
