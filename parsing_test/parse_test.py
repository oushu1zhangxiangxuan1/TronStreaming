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
accountDB = plyvel.DB("/data2/20210425/output-directory/database/account")

accountIndexDB = plyvel.DB(
    "/data2/20210425/output-directory/database/account-index"
)  # account name to accountid
accountIdIndexDB = plyvel.DB(
    "/data2/20210425/output-directory/database/accountid-index"
)

transRetStore = plyvel.DB(
    "/data2/20210425/output-directory/database/transactionRetStore"
)
transRetIt = transRetStore.iterator()
# db = plyvel.DB('/data2/20210425/output-directory/database/transactionHistoryStore')
# b55d835c775067b72aad04164ce05d19d421303a21336bdf73bd933d646a9920  9000000

accountIT = accountDB.iterator()
k, v = next(accountIT)
print(k)
vs = binascii.hexlify(v)
print(vs)
acc = Tron_pb2.Account()
acc.ParseFromString(v)
acc


accountIndexIT = accountIndexDB.iterator()
k, v = next(accountIndexIT)
print(k)
vs = binascii.hexlify(v)
print(vs)


accountIdIndexIT = accountIdIndexDB.iterator()
k, v = next(accountIdIndexIT)
print(k)
vs = binascii.hexlify(v)
print(vs)

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

# it = db.iterator()
with db.iterator() as it:
    k, v = next(it)
    print("k: ", k)
    print("v: ", v)
    print("k decode: ", "".join(["%02x" % b for b in k]))
    vs = Tron_pb2.Transaction()
    vs.ParseFromString(v)
    print("v: ", vs)
    print("v json:", json.dumps(vs))
    print(vs.Contract.ContractType)

    for k, v in it:
        print("k: ", k)
        print("v: ", v)
        print("k decode: ", "".join(["%02x" % b for b in k]))
        vs = Tron_pb2.Transaction()
        vs.ParseFromString(v)
        print("v: ", vs)
        print("v json:", json.dumps(vs))
        break

db.close()


transHisStore = plyvel.DB(
    "/data2/20210425/output-directory/database/transactionHistoryStore"
)
transHisIt = transHisStore.iterator()
k, v = next(transHisIt)
print(k)
print(v)
print(binascii.hexlify(k))
vs = Tron_pb2.TransactionInfo()
vs.ParseFromString(v)

print(binascii.hexlify(vs.id))


contractStore = plyvel.DB("/data2/20210425/output-directory/database/contract")
contractIt = contractStore.iterator()
k, v = next(contractIt)
print(k)
print(v)
print(binascii.hexlify(k))
vs = sc.SmartContract()
vs.ParseFromString(v)

print(binascii.hexlify(vs.id))


# hex 2 bytes
# bytes.fromhex('aa')


# 000000058a28c90f57a4bdf5e5f58066e7dc11928cb6aca1a37fcdae4c80d6d6
transStore = plyvel.DB("/data2/20210425/output-directory/database/trans")
v = transStore.get(
    bytes.fromhex("000000058a28c90f57a4bdf5e5f58066e7dc11928cb6aca1a37fcdae4c80d6d6")
)
print(v)
# transIt = transStore.iterator()
# v =


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


import hashlib

tb = blkIns.transactions[0].SerializeToString()
thash = hashlib.sha256(tb).hexdigest()
