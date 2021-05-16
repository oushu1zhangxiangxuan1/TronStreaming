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
    return tronapi.common.account.Address().from_hex(hex_str).decode()


def addressFromBytes(addr):
    return tronapi.common.account.Address().from_hex(bytes.decode(b2hs(addr))).decode()
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
while True:
    k, v = next(accountIT)
    accIns = Tron_pb2.Account()
    accIns.ParseFromString(v)
    if (
        accIns.latest_asset_operation_time is not None
        and len(accIns.latest_asset_operation_time) > 0
    ):
        print(
            "latest_asset_operation_time of {} : {}".format(
                addressFromBytes(k), accIns.latest_asset_operation_time
            )
        )
        print(
            "latest_asset_operation_time type of {} : {}".format(
                addressFromBytes(k), type(accIns.latest_asset_operation_time)
            )
        )
        break
    if len(accIns.latest_asset_operation_timeV2) > 0:
        print(
            "latest_asset_operation_timeV2 of {} : {}".format(
                addressFromBytes(k), accIns.latest_asset_operation_timeV2
            )
        )
        print(
            "latest_asset_operation_timeV2 type of {} : {}".format(
                addressFromBytes(k), type(accIns.latest_asset_operation_timeV2)
            )
        )
        break

    if accIns.free_asset_net_usage is not None and len(accIns.free_asset_net_usage) > 0:
        print(
            "free_asset_net_usage of {} : {}".format(
                addressFromBytes(k), accIns.free_asset_net_usage
            )
        )
        print(
            "free_asset_net_usage type of {} : {}".format(
                addressFromBytes(k), type(accIns.free_asset_net_usage)
            )
        )
        break
    if len(accIns.free_asset_net_usageV2) > 0:
        print(
            "free_asset_net_usageV2 of {} : {}".format(
                addressFromBytes(k), accIns.free_asset_net_usageV2
            )
        )
        print(
            "free_asset_net_usageV2 type of {} : {}".format(
                addressFromBytes(k), type(accIns.free_asset_net_usageV2)
            )
        )
        break

    if len(accIns.frozen) > 0:
        print("frozen of {} : {}".format(addressFromBytes(k), accIns.frozen))
        print("frozen type of {} : {}".format(addressFromBytes(k), type(accIns.frozen)))
        break
    if len(accIns.frozen_supply) > 0:
        print(
            "frozen_supply of {} : {}".format(addressFromBytes(k), accIns.frozen_supply)
        )
        print(
            "frozen_supply type of {} : {}".format(
                addressFromBytes(k), type(accIns.frozen_supply)
            )
        )
        break


accountIndexIT = accountIndexDB.iterator()
while True:
    k, v = next(accountIndexIT)
    print("k: {}".format(k))
    print("k dec: {}".format(bytes.decode(k)))
    print("v: {}".format(v))
    print("v hex: {}".format(bytes.decode(b2hs(v))))
    print("v base: {}".format(addressFromBytes(v)))
    acc = accountDB.get(v)
    accIns = Tron_pb2.Account()
    accIns.ParseFromString(acc)
    accIns
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
