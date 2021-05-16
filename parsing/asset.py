# -*- encoding:"utf-8"-*-

import Tron_pb2
import json
import plyvel
from Crypto.Util.number import bytes_to_long as b2l
from Crypto.Util.number import long_to_bytes as l2b
import binascii
import tronapi
import time

b2hs = binascii.hexlify


def addressFromHex(hex_str):
    return tronapi.common.account.Address().from_hex(hex_str)


def addressFromBytes(addr):
    return tronapi.common.account.Address().from_hex(bytes.decode(b2hs(addr)))
    # 会遇到问题 UnicodeDecodeError: 'utf-8' codec can't decode byte 0xb6 in position 3: invalid start byte


# binascii.hexlify(k).decode('ascii')
# bytearray.fromhex(id)
# bytes.fromhex(str)
# binascii.b2a_hex()

accountDB = plyvel.DB("/data2/20210425/output-directory/database/account")

accountIndexDB = plyvel.DB(
    "/data2/20210425/output-directory/database/account-index"
)  # account name to accountid
accountIdIndexDB = plyvel.DB(
    "/data2/20210425/output-directory/database/accountid-index"
)


accountIT = accountDB.iterator()
k, v = next(accountIT)
print(k)
vs = binascii.hexlify(v)
print(vs)
acc = Tron_pb2.Account()
acc.ParseFromString(v)
acc


accountIndexIT = accountIndexDB.iterator()
while True:
    k, v = next(accountIndexIT)
    print("k: {}".format(k))
    print("k dec: {}".format(bytes.decode(k)))
    print("v: {}".format(v))
    print("v hex: {}".format(bytes.decode(b2hs(v))))
    print("v base: {}".format(addressFromBytes(v)))
    print("========================================\n")
    time.sleep(0.4)


accountIdIndexIT = accountIdIndexDB.iterator()
i = 0
while True:
    k, v = next(accountIdIndexIT)
    i += 1
    print(i)
    print("k: {}".format(k))
    print("k dec: {}".format(bytes.decode(k)))
    print("v: {}".format(v))
    print("v hex: {}".format(bytes.decode(b2hs(v))))
    print("v base: {}".format(addressFromBytes(v)))
    print("========================================\n")
    time.sleep(0.7)
