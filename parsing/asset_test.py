# -*- encoding:"utf-8"-*-

import Tron_pb2
import json
import plyvel
from Crypto.Util.number import bytes_to_long as b2l
from Crypto.Util.number import long_to_bytes as l2b
import binascii
import tronapi
import timee
import chardet
import core.contract.asset_issue_contract_pb2 as asset_issue_contract_pb2

b2hs = binascii.hexlify


def addressFromHex(hex_str):
    return tronapi.common.account.Address().from_hex(hex_str)


def addressFromBytes(addr):
    return tronapi.common.account.Address().from_hex(bytes.decode(b2hs(addr)))


assetDB = plyvel.DB("/data2/20210425/output-directory/database/asset-issue")

assetV2DB = plyvel.DB("/data2/20210425/output-directory/database/asset-issue-v2")


assetIT = assetDB.iterator()
k, v = next(assetIT)
print(k)
vs = binascii.hexlify(v)
print(vs)


assetV2IT = assetV2DB.iterator()
k, v = next(assetV2IT)
print(k.decode())
aic = asset_issue_contract_pb2.AssetIssueContract()
aic.ParseFromString(v)
print(aic)


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
