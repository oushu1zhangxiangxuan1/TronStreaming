import Tron_pb2
import json
import plyvel
from Crypto.Util.number import bytes_to_long as b2l
from Crypto.Util.number import long_to_bytes as l2b
import binascii
import tronapi
import time

b2hs = binascii.hexlify


def num2Bytes(n):
    return n.to_bytes(8, "big")


def addressFromHex(hex_str):
    return tronapi.common.account.Address().from_hex(hex_str).decode()


def addressFromBytes(addr):
    return tronapi.common.account.Address().from_hex(bytes.decode(b2hs(addr))).decode()
    # 会遇到问题 UnicodeDecodeError: 'utf-8' codec can't decode byte 0xb6 in position 3: invalid start byte


transDB = plyvel.DB("/data2/20210425/output-directory/database/trans")
transRetStore = plyvel.DB(
    "/data2/20210425/output-directory/database/transactionRetStore"
)
transHisStore = plyvel.DB(
    "/data2/20210425/output-directory/database/transactionHistoryStore"
)

transCacheStore = plyvel.DB("/data2/20210425/output-directory/database/trans-cache")


transHisIt = transHisStore.iterator()
k, v = next(transHisIt)
print(k)
print(v)
print(binascii.hexlify(k))
vs = Tron_pb2.TransactionInfo()
vs.ParseFromString(v)

print(binascii.hexlify(vs.id))

tranCacheIT = transCacheStore.iterator()
while True:
    k, v = next(tranCacheIT)
    print("k: {}".format(k))
    print("k dec: {}".format(b2hs(k)))
    print("v: {}".format(b2l(v)))
    # print("v hex: {}".format(bytes.decode(b2hs(v))))
    # print("v base: {}".format(addressFromBytes(v)))
    print("========================================\n")
    time.sleep(0.4)


transRetIt = transRetStore.iterator()
# i = 0
# while True:

k, v = next(transRetIt)
# i += 1
# print(i)
# print("k: {}".format(k))
print("k dec: {}".format(b2l(k)))
# print("v: {}".format(v))
ret = Tron_pb2.TransactionRet()
ret.ParseFromString(v)
print("========================================\n")
time.sleep(0.7)


transRetItRev = transRetStore.iterator(reverse=True)
k, v = next(transRetItRev)
print("k dec: {}".format(b2l(k)))
ret = Tron_pb2.TransactionRet()
ret.ParseFromString(v)

accountTraceIT = accountTraceDB.iterator()
i = 0
while True:
    k, v = next(accountTraceIT)
    i += 1
    print(i)
    print("k: {}".format(k))
    print("k dec: {}".format(bytes.decode(k)))
    print("v: {}".format(v))
    print("v hex: {}".format(bytes.decode(b2hs(v))))
    print("v base: {}".format(addressFromBytes(v)))
    print("========================================\n")
    time.sleep(0.7)


accountTrieIT = accountTrieDB.iterator()
i = 0
while True:
    k, v = next(accountTrieIT)
    i += 1
    print(i)
    print("k: {}".format(k))
    print("k dec: {}".format(bytes.decode(k)))
    print("v: {}".format(v))
    print("v hex: {}".format(bytes.decode(b2hs(v))))
    print("v base: {}".format(addressFromBytes(v)))
    print("========================================\n")
    time.sleep(0.7)
