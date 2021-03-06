import Tron_pb2
import json
import plyvel
from Crypto.Util.number import bytes_to_long as b2l
from Crypto.Util.number import long_to_bytes as l2b
import binascii
import tronapi
import time

b2hs = binascii.hexlify

# (29617377).to_bytes(8, 'big')


def num2Bytes(n):
    return n.to_bytes(8, "big")


def addressFromHex(hex_str):
    return tronapi.common.account.Address().from_hex(hex_str)


def addressFromBytes(addr):
    return tronapi.common.account.Address().from_hex(bytes.decode(b2hs(addr)))
    # 会遇到问题 UnicodeDecodeError: 'utf-8' codec can't decode byte 0xb6 in position 3: invalid start byte


# db = plyvel.DB("/data2/20210425/output-directory/database/trans")
blockIndexDB = plyvel.DB("/data2/20210425/output-directory/database/block-index")
blockDB = plyvel.DB("/data2/20210425/output-directory/database/block")


blockIndexIT = blockIndexDB.iterator()

k, v = next(blockIndexIT)
k = b2l(k)
print(k)
vs = binascii.hexlify(v)
print(vs)


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

# tsc = sc.TriggerSmartContract()
# tsc.ParseFromString(blkIns.transactions[0].raw_data.contract[0].parameter.value)


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
c1.ParseFromString(vs.transactions[1].raw_data.contract[0].parameter.value)


import core.contract.asset_issue_contract_pb2 as asset_issue_contract


c2 = asset_issue_contract.TransferAssetContract()
c2.ParseFromString(vs.transactions[2].raw_data.contract[0].parameter.value)


#
i = blockIndexDB.get(num2Bytes(29617377))
blk = blockDB.get(i)
blkIns = Tron_pb2.Block()
blkIns.ParseFromString(blk)
tb = blkIns.transactions[0].SerializeToString()
