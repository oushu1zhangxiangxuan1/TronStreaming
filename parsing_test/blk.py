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

accountTraceDB = plyvel.DB("/data2/20210425/output-directory/database/account-trace")

accountTrieDB = plyvel.DB("/data2/20210425/output-directory/database/accountTrie")


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


import Tron_pb2
import json
import plyvel
from Crypto.Util.number import bytes_to_long as b2l
from Crypto.Util.number import long_to_bytes as l2b
import binascii
import core.contract.smart_contract_pb2 as sc
from core.contract.asset_issue_contract_pb2 import TransferAssetContract as tac

# pip install pycryptodome

# binascii.hexlify(k).decode('ascii')
# bytearray.fromhex(id)
# bytes.fromhex(str)
# binascii.b2a_hex()

db = plyvel.DB("/data2/20210425/output-directory/database/trans")
blockIndexDB = plyvel.DB("/data2/20210425/output-directory/database/block-index")
blockDB = plyvel.DB("/data2/20210425/output-directory/database/block")


blockIndexIT = blockIndexDB.iterator(reverse=True)
k, v = next(blockIndexIT)
k = b2l(k)
print(k)
vs = binascii.hexlify(v)
print(vs)
blk = blockDB.get(v)


blockIndexITrev = blockIndexDB.iterator(reverse=True)
k, v = next(blockIndexITrev)
k = b2l(k)
print(k)
vs = binascii.hexlify(v)
print(vs)
blk = blockDB.get(v)

blkIns = Tron_pb2.Block()
blkIns.ParseFromString(blk)
blkIns.transactions[0]

tsc = sc.TriggerSmartContract()
tsc.ParseFromString(blkIns.transactions[0].raw_data.contract[0].parameter.value)


blockDB = plyvel.DB("/data2/20210425/output-directory/database/block")
blockIt = blockDB.iterator()
k, v = next(blockIt)
print(k)
print(v)
print(binascii.hexlify(k))
vs = Tron_pb2.Block()
vs.ParseFromString(v)


# blockIndexDB = plyvel.DB("/data2/20210425/output-directory/database/block-index")
v = blockIndexDB.get(l2b(20000000))
print(v)
print(binascii.hexlify(v))
myBlock = blockDB.get(v)
print(v)


import core.contract.balance_contract_pb2 as balance_contract


c1 = balance_contract.TransferContract()
c1.ParseFromString(vs.transactions[0].raw_data.contract[0].parameter.value)


import core.contract.asset_issue_contract_pb2 as asset_issue_contract


c2 = asset_issue_contract.TransferAssetContract()
c2.ParseFromString(vs.transactions[2].raw_data.contract[0].parameter.value)
