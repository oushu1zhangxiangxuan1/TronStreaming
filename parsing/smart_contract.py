import Tron_pb2
import json
import plyvel
from Crypto.Util.number import bytes_to_long as b2l
from Crypto.Util.number import long_to_bytes as l2b
import binascii
import tronapi
import time

# import core
import hashlib

b2hs = binascii.hexlify

# (29617377).to_bytes(8, 'big')


def num2Bytes(n):
    return n.to_bytes(8, "big")


def addressFromHex(hex_str):
    return tronapi.common.account.Address().from_hex(hex_str)


def addressFromBytes(addr):
    return tronapi.common.account.Address().from_hex(bytes.decode(b2hs(addr)))
    # 会遇到问题 UnicodeDecodeError: 'utf-8' codec can't decode byte 0xb6 in position 3: invalid start byte


contractDB = plyvel.DB("/data2/20210425/output-directory/database/contract")
contractIt = contractDB.iterator()
k, v = next(contractIt)
print("k: ", k)
print("v: ", v)


import core.contract.smart_contract_pb2 as smart_contract

c = smart_contract.SmartContract()
c.ParseFromString(v)
