# -*- encoding:"utf-8"-*-
import Tron_pb2

import json
import plyvel

from Crypto.Util.number import bytes_to_long as b2l

# from Crypto.Util.number import long_to_bytes as l2b
from binascii import hexlify as b2hs
import tronapi
import time
import traceback
import logging

from sqlalchemy import create_engine
import psycopg2


logging.basicConfig(level=logging.INFO)


def addressFromHex(hex_str):
    return tronapi.common.account.Address().from_hex(hex_str)


def addressFromBytes(addr):
    return tronapi.common.account.Address().from_hex(bytes.decode(b2hs(addr)))
    # TODO: 会遇到问题 UnicodeDecodeError: 'utf-8' codec can't decode byte 0xb6 in position 3: invalid start byte


# 同时跑一个checkaccount-index和account的量

# 先从account-index 中取出name和address
# 然后通过address取account数据
# 插入address name create_time
# balance -> trx-balance
# 插入asset 表

# TODO: address一般需要base58


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
    def __init__(self, name, colType, castFunc=None, oc=None):
        self.oc = oc
        self.name = name
        if not self.oc:
            self.type = colType
            self.castFunc = self.castFunc
            if castFunc == b2l or colType in ["int64", "int"]:
                self.toNum = True
            if castFunc is None and colType == "bytes":
                self.castFunc = b2hs

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
        return self.oc.getatte(subData)


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
        ),
        "account_asset_v2": SubTable(
            colName="assetV2",
            sType="map",
            mapInfo=MapInfo(
                key=OriginColumn("asset_id", "string"),
                value=OriginColumn("amount", "int64"),
            ),
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
        ),
        "account_latest_asset_operation_time_v2": SubTable(
            colName="latest_asset_operation_timeV2",
            sType="map",
            mapInfo=MapInfo(
                key=OriginColumn("asset_id", "string"),
                value=OriginColumn("latest_opration_time", "int64"),
            ),
        ),
        "free_asset_net_usage": SubTable(
            colName="free_asset_net_usage",
            sType="map",
            mapInfo=MapInfo(
                key=OriginColumn("asset_id", "string"),
                value=OriginColumn("net_usage", "int64"),
            ),
        ),
        "account_free_asset_net_usage_v2": SubTable(
            colName="free_asset_net_usageV2",
            sType="map",
            mapInfo=MapInfo(
                key=OriginColumn("asset_id", "string"),
                value=OriginColumn("net_usage", "int64"),
            ),
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
                "vote_address": OriginColumn(
                    "vote_address", "bytes"
                ),  # TODO: vote address 是否需要转base58
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


class CommonParseAndInsert:
    def __init__(
        self,
        cols,
        subCols,
        table,
        sType="single",
        mapInfo=None,
        errKeys=None,
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

    def insert_error(self, data, appendix=None):
        logging.error("===============")
        logging.error("Invalid sType {}: ", self.sType)
        logging.error("===============\n\n\n")
        return False

    def insert_map(self, data, appendix=None):
        insertCols = []
        insertVals = []
        if appendix:
            for k, v in appendix.items():
                insertCols.append(k)
                insertVals.append(v)
        for key in self.data:
            v = self.data[key]

            # insert key name & value
            insertCols.append(self.mapInfo.key.name)
            insertVals.append(self.mapInfo.key.getattr(key))

            insertCols.append(self.mapInfo.value.name)
            insertVals.append(self.mapInfo.value.getattr(v))

        if len(insertCols) == 0:
            logging.error("===============")
            logging.error("insertCols is null")
            logging.error("===============\n\n\n")
            return False
        insertSql = "INSERT INTO {}({}) VALUES ({});".format(
            self.table, ",".join(insertCols), ",".join(insertVals)
        )
        print(insertSql)
        return True

    def insert_list(self, data, appendix=None):
        for d in data:
            if not self.insert_single(data, appendix):
                return False

    def insert_single(self, data, appendix=None):
        insertCols = []
        insertVals = []
        if appendix:
            for k, v in appendix.items():
                insertCols.append(k)
                insertVals.append(v)
        for col, oc in self.cols.items():
            if oc.hasattr(data):
                insertCols.append(col)
                insertVals.append(oc.getattr(data))

        if len(insertCols) == 0:
            logging.error("===============")
            logging.error("insertCols is null")
            logging.error("===============\n\n\n")
            return False
        insertSql = "INSERT INTO {}({}) VALUES ({});".format(
            self.table, ",".join(insertCols), ",".join(insertVals)
        )
        print(insertSql)
        if self.sType == "single":
            for table, st in self.subCols.items():
                if hasattr(data, st.colName):
                    # 获取数据
                    subData = getattr(data, st.colName)
                    appendData = self.getAppendix(data, st.appendCols)
                    # 建造类
                    subClass = CommonParseAndInsert(
                        cols=st.cols,
                        subCols=st.subCols,
                        table=table,
                        mapInfo=st.mapInfo,
                        sType=st.sType,
                    )
                    ret = subClass.insert(
                        data=subData,
                        appendix=appendData,
                    )
                    if not ret:
                        return ret
        return True

    def getAppendix(self, data, appendix):
        if not appendix:
            return None
        appendData = {}
        for col, oc in appendix.items():
            if hasattr(data, oc.name):
                v = getattr(data, col)
                appendData[col] = oc.String(v)
        return appendData


def getConn(config):
    try:
        conn = psycopg2.connect(
            database=config["hawq"]["database"],
            user=config["hawq"]["user"],
            password=config["hawq"]["password"],
            host=config["hawq"]["master"],
            port=str(config["hawq"]["port"]),
        )
    except Exception as e:
        logging.error("Conn hawq master failed!")
        logging.error(e)
        logging.error(traceback.format_exc())
        conn = psycopg2.connect(
            database=config["hawq"]["postgres"],
            user=config["hawq"]["user"],
            password=config["hawq"]["password"],
            host=config["hawq"]["master"],
            port=str(config["hawq"]["port"]),
        )
    conn.commit()
    conn.close()


def isNumeric(col_type):
    return col_type in ["int", "bigint", "double precision"]


if "__main__" == __name__:
    # if len(os.Args) < 2:
    #     logging.error(
    #         "请输入account数据库位置",
    #     )
    # accountDB = plyvel.DB(os.Args[1])

    config, err = ConfigParser.Parse()
    if err is not None:
        logging.error("Failed to get hawq config: {}".format(err))
        exit(-1)
    conn = getConn(config)
    try:
        cur = conn.cursor()
        accountDB = plyvel.DB("/data2/20210425/output-directory/database/account")
        accountIt = accountDB.iterator()
        accInsert = CommonParseAndInsert(
            cols=Account.cols,
            subCols=Account.subCols,
            table=Account.table,
        )
        for k, v in accountIt:
            acc = Tron_pb2.Account()
            acc.ParseFromString(v)
            acc.Insert(acc)
            conn.commit()
    finally:
        conn.close()


# cols = {
#     "account_name": "text",
#     "type": "int",
#     "address": "text",
#     "balance": "bigint",
#     "net_usage": "bigint",
#     "acquired_delegated_frozen_balance_for_bandwidth": "bigint",
#     "delegated_frozen_balance_for_bandwidth": "bigint",
#     "create_time": "bigint",
#     "latest_opration_time": "bigint",
#     "allowance": "bigint",
#     "latest_withdraw_time": "bigint",
#     "code_2l": "text",
#     "code_2hs": "text",
#     "is_witness": "bool",
#     "is_committee": "bool",
#     "asset_issued_name": "text",
#     "asset_issued_ID_2l": "text",
#     "asset_issued_ID_2hs": "text",
#     "free_net_usage": "bigint",
#     "latest_consume_time": "bigint",
#     "latest_consume_free_time": "bigint",
#     "account_id": "bytea",
# }
