# -*- encoding: utf-8 -*-
import Tron_pb2

import json
import plyvel

import functools


from Crypto.Util.number import bytes_to_long as b2l

# from Crypto.Util.number import long_to_bytes as l2b
from binascii import hexlify as b2hs
import tronapi
import time
import traceback
import logging
import datetime

from sqlalchemy import create_engine
import psycopg2


logging.basicConfig(level=logging.INFO)


def bytes2HexStr(data):
    return b2hs(data).decode()


def bytes2HexStr_V2(data):
    return "".join(["%02X " % b for b in data])


def addressFromHex(hex_str):
    return tronapi.common.account.Address().from_hex(hex_str).decode()


def addressFromBytes(addr):
    return tronapi.common.account.Address().from_hex(bytes.decode(b2hs(addr))).decode()


class ConfigParser:
    @staticmethod
    def Parse():
        # valid = False
        config = None
        try:
            with open("./hawq.json") as f:
                config = json.load(f)
        except Exception as e:
            logging.error(e)
            return None, "Parse config json error."
        logging.warn("config is : {}".format(config))
        # check hawq config
        master = config.get("master")
        standby = config.get("standby")
        if (master is None or len(master.strip()) == 0) and (
            standby is None or len(standby.strip()) == 0
        ):
            logging.error("Hawq master and standby not specified.")
            return None, "Hawq master and standby not specified."
        if master is not None:
            config["master"] = master.strip()
        else:
            config["master"] = ""

        if standby is not None:
            config["standby"] = standby.strip()
        else:
            config["standby"] = ""

        port = config.get("port")
        if port is None:
            logging.error("Hawq port not specified.")
            return None, "Hawq port not specified."

        user = config.get("user")
        if user is None or len(user.strip()) == 0:
            logging.error("Hawq user not specified.")
            return None, "Hawq user not specified."

        password = config.get("password")
        if password is None:
            logging.error("Hawq password not specified.")
            return None, "Hawq password not specified."

        database = config.get("database")
        if database is None or len(database.strip()) == 0:
            logging.error("Hawq database not specified.")
            return None, "Hawq database not specified."
        config["database"] = database.strip()

        return config, None


class OriginColumn:
    def __init__(self, name=None, colType=None, castFunc=None, oc=None):
        self.oc = oc
        self.name = name
        self.toNum = None
        if not self.oc:
            self.type = colType
            self.castFunc = castFunc
            if castFunc == b2l or colType in ["int64", "int32", "int"]:
                self.toNum = True
            if castFunc is None and colType == "bytes":
                self.castFunc = bytes2HexStr

    def String(self, v):
        if self.castFunc:
            v = self.castFunc(v)
        if self.toNum:
            return "{}".format(v)
        return "'{}'".format(v)

    def hasattr(self, data):
        has = hasattr(data, self.name)
        if not self.oc:
            return has
        if has:
            subData = getattr(data, self.name)
            return self.oc.hasattr(subData)
        return False

    def getattr(self, data):
        subData = getattr(data, self.name)
        if not self.oc:
            return self.String(subData)
        return self.oc.getattr(subData)


class SubTable:
    def __init__(
        self,
        colName=None,
        appendCols=None,
        sType="single",
        mapInfo=None,
        cols=None,
        subCols=None,
    ):
        self.sType = sType
        self.colName = colName
        self.appendCols = appendCols
        self.mapInfo = mapInfo
        self.cols = cols
        self.subCols = subCols


class MapInfo:
    def __init__(self, key, value):
        self.key = key
        self.value = value


frozen_OC = {
    "frozen_balance": OriginColumn("frozen_balance", "int64"),
    "expire_time": OriginColumn("expire_time", "int64"),
}


class Account:
    cols = {
        "account_name": OriginColumn("account_name", "bytes"),
        "type": OriginColumn("type", "int"),
        "address": OriginColumn("address", "bytes", castFunc=addressFromBytes),
        "balance": OriginColumn("balance", "int"),
        "net_usage": OriginColumn("net_usage", "int64"),
        "acquired_delegated_frozen_balance_for_bandwidth": OriginColumn(
            "acquired_delegated_frozen_balance_for_bandwidth", "int64"
        ),
        "delegated_frozen_balance_for_bandwidth": OriginColumn(
            "delegated_frozen_balance_for_bandwidth", "int64"
        ),
        "create_time": OriginColumn("create_time", "int64"),
        "latest_opration_time": OriginColumn("latest_opration_time", "int64"),
        "allowance": OriginColumn("allowance", "int64"),
        "latest_withdraw_time": OriginColumn("latest_withdraw_time", "int64"),
        "code_2l": OriginColumn("code", "bytes", castFunc=b2l),
        "code_2hs": OriginColumn("code", "bytes"),
        "is_witness": OriginColumn("is_witness", "bool"),
        "is_committee": OriginColumn("is_committee", "bool"),
        "asset_issued_name": OriginColumn("asset_issued_name", "bytes"),
        "asset_issued_id_2l": OriginColumn("asset_issued_ID", "bytes"),
        "asset_issued_id_2hs": OriginColumn("asset_issued_ID", "bytes"),
        "free_net_usage": OriginColumn("free_net_usage", "int64"),
        "latest_consume_time": OriginColumn("latest_consume_time", "int64"),
        "latest_consume_free_time": OriginColumn("latest_consume_free_time", "int64"),
        "account_id": OriginColumn("account_id", "bytes"),
    }

    subCols = {
        "account_asset": SubTable(
            colName="asset",
            sType="map",
            mapInfo=MapInfo(
                key=OriginColumn("asset_id", "string"),
                value=OriginColumn("amount", "int64"),
            ),
            appendCols={
                "account_address": OriginColumn(
                    "address", "bytes", castFunc=addressFromBytes
                )
            },
        ),
        "account_asset_v2": SubTable(
            colName="assetV2",
            sType="map",
            mapInfo=MapInfo(
                key=OriginColumn("asset_id", "string"),
                value=OriginColumn("amount", "int64"),
            ),
            appendCols={
                "account_address": OriginColumn(
                    "address", "bytes", castFunc=addressFromBytes
                )
            },
        ),
        "account_frozen": SubTable(
            sType="list",
            colName="frozen",
            cols=frozen_OC,
            subCols=None,
            appendCols={
                "account_address": OriginColumn(
                    "address", "bytes", castFunc=addressFromBytes
                )
            },
        ),
        "account_frozen_supply": SubTable(
            sType="list",
            colName="frozen",
            cols=frozen_OC,
            subCols=None,
            appendCols={
                "account_address": OriginColumn(
                    "address", "bytes", castFunc=addressFromBytes
                )
            },
        ),
        "account_latest_asset_operation_time": SubTable(
            colName="latest_asset_operation_time",
            sType="map",
            mapInfo=MapInfo(
                key=OriginColumn("asset_id", "string"),
                value=OriginColumn("latest_opration_time", "int64"),
            ),
            appendCols={
                "account_address": OriginColumn(
                    "address", "bytes", castFunc=addressFromBytes
                )
            },
        ),
        "account_latest_asset_operation_time_v2": SubTable(
            colName="latest_asset_operation_timeV2",
            sType="map",
            mapInfo=MapInfo(
                key=OriginColumn("asset_id", "string"),
                value=OriginColumn("latest_opration_time", "int64"),
            ),
            appendCols={
                "account_address": OriginColumn(
                    "address", "bytes", castFunc=addressFromBytes
                )
            },
        ),
        "free_asset_net_usage": SubTable(
            colName="free_asset_net_usage",
            sType="map",
            mapInfo=MapInfo(
                key=OriginColumn("asset_id", "string"),
                value=OriginColumn("net_usage", "int64"),
            ),
            appendCols={
                "account_address": OriginColumn(
                    "address", "bytes", castFunc=addressFromBytes
                )
            },
        ),
        "account_free_asset_net_usage_v2": SubTable(
            colName="free_asset_net_usageV2",
            sType="map",
            mapInfo=MapInfo(
                key=OriginColumn("asset_id", "string"),
                value=OriginColumn("net_usage", "int64"),
            ),
            appendCols={
                "account_address": OriginColumn(
                    "address", "bytes", castFunc=addressFromBytes
                )
            },
        ),
        "account_resource": SubTable(
            sType="single",
            colName="account_resource",
            cols={
                "energy_usage": OriginColumn("energy_usage", "int64"),
                "frozen_balance_for_energy": OriginColumn(
                    name="frozen_balance_for_energy",
                    oc=OriginColumn(name="frozen_balance", colType="int64"),
                ),
                "frozen_balance_for_energy_expire_time": OriginColumn(
                    name="frozen_balance_for_energy",
                    oc=OriginColumn(name="expire_time", colType="int64"),
                ),
                "latest_consume_time_for_energy": OriginColumn(
                    "latest_consume_time_for_energy", "int64"
                ),
                "acquired_delegated_frozen_balance_for_energy": OriginColumn(
                    "acquired_delegated_frozen_balance_for_energy", "int64"
                ),
                "delegated_frozen_balance_for_energy": OriginColumn(
                    "delegated_frozen_balance_for_energy", "int64"
                ),
                "storage_limit": OriginColumn("storage_limit", "int64"),
                "storage_usage": OriginColumn("storage_usage", "int64"),
                "latest_exchange_storage_time": OriginColumn(
                    "latest_exchange_storage_time", "int64"
                ),
            },
            subCols=None,
            appendCols={
                "account_address": OriginColumn(
                    "address", "bytes", castFunc=addressFromBytes
                )
            },
        ),
        "account_votes": SubTable(
            sType="list",
            colName="votes",
            cols={
                "vote_address": OriginColumn("vote_address", "bytes"),
                "vote_count": OriginColumn("vote_count", "int64"),
            },
            subCols=None,
            appendCols={
                "account_address": OriginColumn(
                    "address", "bytes", castFunc=addressFromBytes
                )
            },
            mapInfo=None,
        ),
    }

    table = "account"


def loginfo(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        # logging.info("=============info===========")
        # logging.info("args:\n{}".format(args))
        # logging.info("kwargs:\n{}".format(kwargs))
        # logging.info("=============info===========")
        return func(*args, **kwargs)

    return wrapper


class CommonParseAndInsert:
    def __init__(
        self,
        cols,
        subCols,
        table,
        sType="single",
        mapInfo=None,
        errKeys=None,
        cursor=None,
    ):
        self.cols = cols
        self.subCols = subCols
        self.table = table
        self.sType = sType
        self.mapInfo = mapInfo

        if self.sType == "single":
            self.Insert = self.insert_single
        elif self.sType == "list":
            self.Insert = self.insert_list
        elif self.sType == "map":
            self.Insert = self.insert_map
        else:
            self.Insert = self.insert_error

    # def insert_wrapper(
    #     func,
    # ):
    #     return func

    def insert_error(self, data, appendix=None):
        logging.error("Invalid sType {}: ", self.sType)
        return False, []

    @loginfo
    def insert_map(self, data, appendix=None):
        sqlList = []
        appendCols = []
        appendVals = []
        if data is None or len(data) == 0:
            return True, sqlList
        if appendix:
            for k, v in appendix.items():
                appendCols.append(k)
                appendVals.append(v)
        for key in data:
            insertCols = []
            insertVals = []
            v = data[key]
            # insert key name & value
            insertCols.append(self.mapInfo.key.name)
            insertVals.append(self.mapInfo.key.String(key))

            insertCols.append(self.mapInfo.value.name)
            insertVals.append(self.mapInfo.value.String(v))

            insertCols += appendCols
            insertVals += appendVals
            insertSql = "INSERT INTO {}({}) VALUES ({});".format(
                self.table, ",".join(insertCols), ",".join(insertVals)
            )
            # print(insertSql)
            sqlList.append(insertSql)
        return True, sqlList

    @loginfo
    def insert_list(self, data, appendix=None):
        sqlList = []
        if data is None or len(data) == 0:
            return True, sqlList
        for d in data:
            ret, subSqls = self.insert_single(d, appendix)
            sqlList += subSqls
            if not ret:
                return False, sqlList
        return True, sqlList

    @loginfo
    def insert_single(self, data, appendix=None):
        sqlList = []
        insertCols = []
        insertVals = []
        appendixLen = 0
        if appendix:
            for k, v in appendix.items():
                appendixLen += 1
                insertCols.append(k)
                insertVals.append(v)
        for col, oc in self.cols.items():
            if oc.hasattr(data):
                insertCols.append(col)
                insertVals.append(oc.getattr(data))

        if len(insertCols) <= appendixLen:
            logging.error("insertCols is null")
            logging.error("data:\n{}\n".format(data))
            return False, sqlList
        insertSql = "INSERT INTO {}({}) VALUES ({});".format(
            self.table, ",".join(insertCols), ",".join(insertVals)
        )
        sqlList.append(insertSql)
        # print(insertSql)
        if self.sType == "single" and self.subCols:
            for table, st in self.subCols.items():
                if hasattr(data, st.colName):
                    # 获取数据
                    subData = getattr(data, st.colName)
                    # logging.info("\n sub data:{}".format(subData))
                    # logging.info("sub data type:{}\n".format(type(subData)))
                    appendData = self.getAppendix(data, st.appendCols)
                    # 建造类
                    # logging.info("\nCreate sub class: {}\n".format(table))
                    # logging.info("sub table: {}\n".format(st))
                    subClass = CommonParseAndInsert(
                        cols=st.cols,
                        subCols=st.subCols,
                        table=table,
                        mapInfo=st.mapInfo,
                        sType=st.sType,
                    )
                    ret, subSqls = subClass.Insert(
                        data=subData,
                        appendix=appendData,
                    )
                    sqlList = sqlList + subSqls
                    if not ret:
                        return False, sqlList
        return True, sqlList

    def getAppendix(self, data, appendix):
        if not appendix:
            return None
        appendData = {}
        for col, oc in appendix.items():
            if oc.hasattr(data):
                v = oc.getattr(data)
                appendData[col] = v
        return appendData


def getConn(config):
    try:
        conn = psycopg2.connect(
            database=config["database"],
            user=config["user"],
            password=config["password"],
            host=config["master"],
            port=str(config["port"]),
        )
        return conn
    except Exception as e:
        logging.error("Conn hawq master failed!")
        logging.error(e)
        logging.error(traceback.format_exc())
        conn = psycopg2.connect(
            database=config["database"],
            user=config["user"],
            password=config["password"],
            host=config["standby"],
            port=str(config["port"]),
        )
        return conn


def isNumeric(col_type):
    return col_type in ["int", "bigint", "double precision"]


def num2Bytes(n):
    return n.to_bytes(8, "big")


def p_block(block):
    # 按顺序生成一个list，并使用对应writer去writerow
    return True


class OriginColumnWapper:
    def __init__(self, name, oc):
        self.name = name
        self.oc = oc


class ColumnIndex:
    def __init__(self, name, fromAppend=False, oc=None):
        self.name = name
        self.FromAppend = fromAppend
        self.oc = oc


class BlockParser:

    @staticmethod
    def _blockHeaderWrapper(oc):
        return OriginColumn(name="block_header", oc=OriginColumn(name="raw_data", oc=oc))

    colIndex = [
        ColumnIndex(name="block_num", fromAppend=True),
        ColumnIndex(name="hash", fromAppend=True),
        ColumnIndex(name="parent_hash", oc=_blockHeaderWrapper(OriginColumn(name="parentHash", colType="bytes"))),
        ColumnIndex(name="create_time", oc=_blockHeaderWrapper(OriginColumn(name="timestamp", colType="bytes"))),
        ColumnIndex(name="version", oc=_blockHeaderWrapper(OriginColumn(name="version", colType="int32"))),
        ColumnIndex(name="witness_address", oc=_blockHeaderWrapper(OriginColumn(name="witness_address", castFunc=addressFromBytes))),
        ColumnIndex(name="witness_id", oc=_blockHeaderWrapper(OriginColumn(name="witness_id", colType="int64"))),
        ColumnIndex(name="tx_count", oc=OriginColumn(name="transactions", colType=len)),
        ColumnIndex(name="tx_trie_root", oc=_blockHeaderWrapper(OriginColumn(name="txTrieRoot", colType="bytes"))),
        ColumnIndex(name="witness_signature", oc=OriginColumn(name="block_header", oc=OriginColumn(name="witness_signature", colType="bytes"))),
        ColumnIndex(name="account_state_root", oc=_blockHeaderWrapper(OriginColumn(name="accountStateRoot", colType="bytes"))),
    ]

    # cols = {

    # }
    #     # OriginColumnWapper(name="block_num", oc=OriginColumn())
    #     OriginColumnWapper(name="parent_hash", oc=OriginColumn(name"block_header"))
    # ]

    # def __init__(self, data, appendData):
    #     self.data = data
    #     self.appendData = appendData

    def Parse(self, data, appendData):

        pass


def main():
    # TODO: check output path is dir,exist and empty
    config, err = ConfigParser.Parse()
    if err is not None:
        logging.error("Failed to get hawq config: {}".format(err))
        exit(-1)
    try:
        blockDb = plyvel.DB(config.blockDb)
        blockIndexDb = plyvel.DB(config.blockIndexDb)

        for i in range(config.start_num, config.end_num):
            print(i)
            blockHashBytes = blockIndexDb.get(num2Bytes(i))
            blockBytes = blockDb.get(blockHashBytes)
            blockHash = bytes2HexStr(blockHashBytes)
            block = Tron_pb2.Block()
            block.ParseFromString(block)
            appendData = {
                "block_num": i,
                "hash": blockHash
            }
            bp = BlockParser()
            ret = bp.Parse(block, appendData)
            if not ret:
                logging.error("Failed to parse block num: {}".format(i))


    #     accInsert = CommonParseAndInsert(
    #         cursor=cur,
    #         cols=Account.cols,
    #         subCols=Account.subCols,
    #         table=Account.table,
    #     )
    #     count = 0
    #     start = datetime.datetime.now()
    #     for k, v in accountDB:
    #         if count % 10000 == 0:
    #             end = datetime.datetime.now()
    #             logging.info(
    #                 "已处理 {} 个账户，共耗时 {} 微秒".format(count, (end - start).microseconds)
    #             )
    #         acc = Tron_pb2.Account()
    #         acc.ParseFromString(v)
    #         ret, sqls = accInsert.Insert(acc)
    #         # logging.info("sqls: {}".format(sqls))
    #         if not ret or len(sqls) == 0:
    #             logging.error("===================")
    #             logging.error("解析插入失败:\n address hex: {}".format(b2hs(acc.address)))
    #             logging.error(
    #                 "解析插入失败:\n address: {}".format(addressFromBytes(acc.address))
    #             )
    #             logging.error("===================\n\n\n")
    #             continue
    #         cur.execute("".join(sqls))
    #         conn.commit()
    #         count += 1
    # except Exception as e:
    #     traceback.print_exc()
    #     logging.error("Failed to run main: {}".format(e))
    # finally:
    #     try:
    #         conn.rollback()
    #     finally:
    #         conn.close()


def test():
    config, err = ConfigParser.Parse()
    if err is not None:
        logging.error("Failed to get hawq config: {}".format(err))
        exit(-1)
    conn = getConn(config)
    if not conn:
        logging.error("Failed to connect hawq : {}".format(err))
        exit(-1)
    try:
        cur = conn.cursor()
        accountDB = plyvel.DB("/data2/20210425/output-directory/database/account")
        # accountIt = accountDB.iterator()
        accInsert = CommonParseAndInsert(
            cursor=cur,
            cols=Account.cols,
            subCols=Account.subCols,
            table=Account.table,
        )
        v = accountDB.get(bytes.fromhex("4100001f9ac7032955f71612dea92dc850ff3fa087"))
        acc = Tron_pb2.Account()
        acc.ParseFromString(v)
        ret, sqls = accInsert.Insert(acc)
        # logging.info("sqls: {}".format(sqls))
        if not ret or len(sqls) == 0:
            logging.error("===================")
            logging.error("解析插入失败:\n address hex: {}".format(b2hs(acc.address)))
            logging.error("解析插入失败:\n address: {}".format(addressFromBytes(acc.address)))
            logging.error("===================\n\n\n")
    except Exception as e:
        traceback.print_exc()
        logging.error("Failed to run main: {}".format(e))
    finally:
        try:
            conn.rollback()
        finally:
            conn.close()


# 1. 获取参数: output-directory 数据的绝对地址  blockDB和blockIndexDB拼出来
# 2. 解析hawq配置，以及[start block num, end block num]  0-29617377
# 3. 先通过block-num获取block—hash
# 4. 解析block，计算tx_count，写block文件
# 5. 轮询trans，解析trans，写trans表
# 6. touch detail, 如果有数据则写trans_order_detail表
# 7. 根据contract_type解析contract，写对应的contract表
# 8. 部分contract需要暂时写hex_bytes到表中后续解析
# 9. 配置中新增hdfs配置 -> 弃用，直接写本地csv文件
# 10.调研如何写csv文件，如何控制并发（如果需要的话），不同进程起的文件写不同名字
# TODO:
# 1. 时间控制及预估
# 2. owner或account等address需要base58
# 3. 如果需要加速的话则需要添加更多机器，或者在同一机器上拷贝多份blockdb数据
# 4. 如何控制或知道哪些block是无用的，或者有没有无用的block
# 5. 数据写入多个不同类文件的一致性，如果出错需要一致回滚，或者通过记录出错的trans_id来实现后期一致性
# 6. 最终要检验trans_id的唯一性


if "__main__" == __name__:
    main()
    # test()
