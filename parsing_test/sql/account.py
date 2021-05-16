import Tron_pb2

# import json
import plyvel

# from Crypto.Util.number import bytes_to_long as b2l
# from Crypto.Util.number import long_to_bytes as l2b
import binascii
import tronapi
import time
import traceback

# 同时跑一个checkaccount-index和account的量

# 先从account-index 中取出name和address
# 然后通过address取account数据
# 插入address name create_time
# balance -> trx-balance
# 插入asset 表

b2hs = binascii.hexlify


class Account:
    cols = {
        "account_name": "text",
        "type": "int",
        "address": "text",
        "balance": "bigint",
        "net_usage": "bigint",
        "acquired_delegated_frozen_balance_for_bandwidth": "bigint",
        "delegated_frozen_balance_for_bandwidth": "bigint",
        "create_time": "bigint",
        "latest_opration_time": "bigint",
        "allowance": "bigint",
        "latest_withdraw_time": "bigint",
        "code_2l": "text",
        "code_2hs": "text",
        "is_witness": "bool",
        "is_committee": "bool",
        "asset_issued_name": "text",
        "asset_issued_ID_2l": "text",
        "asset_issued_ID_2hs": "text",
        "free_net_usage": "bigint",
        "latest_consume_time": "bigint",
        "latest_consume_free_time": "bigint",
        "account_id": "bytea",
    }

    subCols = {
        "asset": "",
        "assetV2": "",
        "frozen": "",
        "frozen_supply": "",
        "latest_asset_operation_time": "",
        "latest_asset_operation_timeV2": "",
        "free_asset_net_usage": "",
        "free_asset_net_usageV2": "",
        "account_resource": "",
    }

    # return bool
    @staticmethod
    def insert(self, account):
        for col, colType in self.cols:
            print(col, colType)
        pass


if "__main__" == __name__:
    acc = None
    try:
        Account.insert(acc)
    except Exception:
        traceback.print_exception()


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
