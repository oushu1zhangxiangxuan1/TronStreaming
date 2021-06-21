import Tron_pb2
import plyvel
from Crypto.Util.number import bytes_to_long as b2l
import binascii
import tronapi

b2hs = binascii.hexlify

# (29617377).to_bytes(8, 'big')


def num2Bytes(n):
    return n.to_bytes(8, "big")


def addressFromHex(hex_str):
    return tronapi.common.account.Address().from_hex(hex_str)


def addressFromBytes(addr):
    return tronapi.common.account.Address().from_hex(bytes.decode(b2hs(addr)))
    # 会遇到问题 UnicodeDecodeError: 'utf-8' codec can't decode byte 0xb6 in position 3: invalid start byte


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
# if


def p():
    k, v = next(transHisIt)
    print(binascii.hexlify(k).decode())
    vs = Tron_pb2.TransactionInfo()
    vs.ParseFromString(v)
    print(vs)
    return vs


print(binascii.hexlify(vs.id).decode())


transRetStore = plyvel.DB(
    "/data2/20210425/output-directory/database/transactionRetStore"
)
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
