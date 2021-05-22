# -*- encoding: utf-8 -*-
import env
import Tron_pb2

import json
import plyvel

import functools


from Crypto.Util.number import bytes_to_long as b2l

# from Crypto.Util.number import long_to_bytes as l2b
from binascii import hexlify as b2hs
import tronapi
import traceback
import logging
import datetime

import os.path as path
import os
import csv
from typing import Tuple
import chardet

env.touch()
# logging.basicConfig(level=logging.INFO)
logging.basicConfig(
    format="%(asctime)s [%(levelname)s] [%(filename)s:%(lineno)d] %(message)s",
    datefmt="## %Y-%m-%d %H:%M:%S",
)
logging.getLogger().setLevel(logging.INFO)
logger = logging.getLogger()
# ch = logging.StreamHandler()
# formatter = logging.Formatter(
#     "[%(asctime)s][%(levelname)s][%(filename)s:%(lineno)d] %(message)s"
# )
# # add formatter to console handler
# ch.setFormatter(formatter)
# logger.addHandler(ch)


def bytes2HexStr(data):
    return b2hs(data).decode()


def bytes2HexStr_V2(data):
    return "".join(["%02X " % b for b in data])


def addressFromHex(hex_str):
    return tronapi.common.account.Address().from_hex(hex_str).decode()


def addressFromBytes(addr):
    cache = tronapi.common.account.Address().from_hex(bytes.decode(b2hs(addr)))
    if type(cache) == bytes:
        return cache.decode()
    return cache


def autoDecode(data):
    try:
        return data.decode()
    except Exception:
        encs = chardet.detect(data)
        if encs and encs["encoding"] and len(encs["encoding"]) > 0:
            try:
                return data.decode(encs["encoding"])
            # except Exception as e:
            except Exception:
                logger.error("Failed to decode: {}".format(data))
                # raise e  # TODO: remove raise
                return data
        else:
            return data


def CheckPathAccess(path: str) -> Tuple[bool, str]:
    if not os.path.isdir(path):
        return False, "Dir not exists."
    if not os.access(path, os.W_OK):
        return False, "Permission denied."
    return True, None


class ConfigParser:
    @staticmethod
    def Parse():
        # valid = False
        config = None
        try:
            with open("./account.json") as f:
                config = json.load(f)
        except Exception as e:
            logging.error(e)
            return None, "Parse config json error."
        logging.warn("config is : {}".format(config))

        inputDir = config.get("input_dir")
        if inputDir is None or len(inputDir.strip()) == 0:
            logging.error("input_dir not specified.")
            return None, "input_dir not specified."
        ok, err = CheckPathAccess(inputDir)
        if not ok:
            logging.error("block dir {}.".format(err))
            return None, "block dir {}.".format(err)

        outputDir = config.get("output_dir")
        if outputDir is None or len(outputDir.strip()) == 0:
            logging.error("output_dir not specified.")
            return None, "output_dir not specified."
        ok, err = CheckPathAccess(outputDir)
        if not ok:
            logging.error("output_dir {}.".format(err))
            return None, "output_dir {}.".format(err)

        return config, None


class OriginColumn:
    def __init__(
        self,
        name=None,
        colType="bytes",
        castFunc=None,
        oc=None,
        listHead=False,
        default="",
    ):
        self.oc = oc
        self.name = name
        # self.toNum = None
        self.listHead = listHead
        self.default = default
        if not self.oc:
            self.type = colType
            self.castFunc = castFunc
            # if (
            #     castFunc == b2l
            #     or castFunc == b2l
            #     or colType in ["int64", "int32", "int"]
            # ):
            #     self.toNum = True
            if castFunc is None and colType == "bytes":
                self.castFunc = bytes2HexStr

    def String(self, v):
        if self.castFunc:
            v = self.castFunc(v)
        # if self.toNum:
        #     return "{}".format(v)
        # return "'{}'".format(v)
        return v

    def hasattr(self, data):
        has = hasattr(data, self.name)
        if not has:
            return False
        subData = getattr(data, self.name)
        if self.listHead:
            if len(subData) == 0:
                return False
            subData = subData[0]
        if not self.oc:
            return True
        return self.oc.hasattr(subData)

    def getattr(self, data):
        try:
            if not self.hasattr(data):
                return self.default
            subData = getattr(data, self.name)
            if self.listHead:
                subData = subData[0]
            if not self.oc:
                return self.String(subData)
            return self.oc.getattr(subData)
        except Exception as e:
            logger.error(
                "Failed to getattr: {}\n From data: {}".format(self.name, data)
            )
            raise e


class ColumnIndex:
    def __init__(self, name, fromAppend=False, oc=None):
        self.name = name
        self.FromAppend = fromAppend
        self.oc = oc


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


frozen_OC = [
    ColumnIndex(
        name="frozen_balance", oc=OriginColumn(name="frozen_balance", colType="int64")
    ),
    ColumnIndex(
        name="expire_time", oc=OriginColumn(name="expire_time", colType="int64")
    ),
]


addressAppend = ColumnIndex(name="account_address", fromAppend=True)


class Column:
    def __init__(self, name, default=""):
        self.name = name
        self.default = default


class Account:

    cols = [
        ColumnIndex(
            name="account_name",
            oc=OriginColumn(name="account_name", castFunc=autoDecode),
        ),
        ColumnIndex(name="type", oc=OriginColumn(name="type", colType="int")),
        ColumnIndex(
            name="address",
            oc=OriginColumn(name="address", castFunc=addressFromBytes),
        ),
        ColumnIndex(name="balance", oc=OriginColumn(name="balance", colType="int")),
        ColumnIndex(
            name="net_usage", oc=OriginColumn(name="net_usage", colType="int64")
        ),
        ColumnIndex(
            name="acquired_delegated_frozen_balance_for_bandwidth",
            oc=OriginColumn(
                name="acquired_delegated_frozen_balance_for_bandwidth", colType="int64"
            ),
        ),
        ColumnIndex(
            name="delegated_frozen_balance_for_bandwidth",
            oc=OriginColumn(
                name="delegated_frozen_balance_for_bandwidth", colType="int64"
            ),
        ),
        ColumnIndex(
            name="create_time", oc=OriginColumn(name="create_time", colType="int64")
        ),
        ColumnIndex(
            name="latest_opration_time",
            oc=OriginColumn(name="latest_opration_time", colType="int64"),
        ),
        ColumnIndex(
            name="allowance", oc=OriginColumn(name="allowance", colType="int64")
        ),
        ColumnIndex(
            name="latest_withdraw_time",
            oc=OriginColumn(name="latest_withdraw_time", colType="int64"),
        ),
        ColumnIndex(name="code_2l", oc=OriginColumn(name="code", castFunc=autoDecode)),
        ColumnIndex(name="code_2hs", oc=OriginColumn(name="code", colType="bytes")),
        ColumnIndex(
            name="is_witness", oc=OriginColumn(name="is_witness", colType="bool")
        ),
        ColumnIndex(
            name="is_committee", oc=OriginColumn(name="is_committee", colType="bool")
        ),
        ColumnIndex(
            name="asset_issued_name",
            oc=OriginColumn(name="asset_issued_name", castFunc=autoDecode),
        ),
        ColumnIndex(
            name="asset_issued_id_2l",
            oc=OriginColumn(name="asset_issued_ID", castFunc=autoDecode),
        ),
        ColumnIndex(
            name="asset_issued_id_2hs",
            oc=OriginColumn(name="asset_issued_ID", colType="bytes"),
        ),
        ColumnIndex(
            name="free_net_usage",
            oc=OriginColumn(name="free_net_usage", colType="int64"),
        ),
        ColumnIndex(
            name="latest_consume_time",
            oc=OriginColumn(name="latest_consume_time", colType="int64"),
        ),
        ColumnIndex(
            name="latest_consume_free_time",
            oc=OriginColumn(name="latest_consume_free_time", colType="int64"),
        ),
        ColumnIndex(
            name="account_id", oc=OriginColumn(name="account_id", castFunc=autoDecode)
        ),
    ]

    subCols = {
        "account_asset": SubTable(
            colName="asset",
            sType="map",
            cols=[
                addressAppend,
                # ColumnIndex(name="asset_id", fromAppend=True),
                # ColumnIndex(name="amount", fromAppend=True),
            ],
            mapInfo=MapInfo(
                key=OriginColumn(name="asset_id", colType="string"),
                value=OriginColumn(name="amount", colType="int64"),
            ),
            appendCols={
                "account_address": OriginColumn(
                    name="address", castFunc=addressFromBytes
                )
            },
        ),
        "account_asset_v2": SubTable(
            colName="assetV2",
            sType="map",
            cols=[
                addressAppend,
                # ColumnIndex(name="asset_id", fromAppend=True),
                # ColumnIndex(name="amount", fromAppend=True),
            ],
            mapInfo=MapInfo(
                key=OriginColumn(name="asset_id", colType="string"),
                value=OriginColumn(name="amount", colType="int64"),
            ),
            appendCols={
                "account_address": OriginColumn(
                    name="address", castFunc=addressFromBytes
                )
            },
        ),
        "account_frozen": SubTable(
            sType="list",
            colName="frozen",
            cols=[addressAppend] + frozen_OC,
            subCols=None,
            appendCols={
                "account_address": OriginColumn(
                    name="address", castFunc=addressFromBytes
                )
            },
        ),
        "account_frozen_supply": SubTable(
            sType="list",
            colName="frozen_supply",
            cols=[addressAppend] + frozen_OC,
            subCols=None,
            appendCols={
                "account_address": OriginColumn(
                    name="address", castFunc=addressFromBytes
                )
            },
        ),
        "account_latest_asset_operation_time": SubTable(
            colName="latest_asset_operation_time",
            sType="map",
            cols=[
                addressAppend,
                # ColumnIndex(name="asset_id", fromAppend=True),
                # ColumnIndex(name="latest_opration_time", fromAppend=True),
            ],
            mapInfo=MapInfo(
                key=OriginColumn(name="asset_id", colType="string"),
                value=OriginColumn(name="latest_opration_time", colType="int64"),
            ),
            appendCols={
                "account_address": OriginColumn(
                    name="address", castFunc=addressFromBytes
                )
            },
        ),
        "account_latest_asset_operation_time_v2": SubTable(
            colName="latest_asset_operation_timeV2",
            sType="map",
            cols=[
                addressAppend,
                # ColumnIndex(name="asset_id", fromAppend=True),
                # ColumnIndex(name="latest_opration_time", fromAppend=True),
            ],
            mapInfo=MapInfo(
                key=OriginColumn(name="asset_id", colType="string"),
                value=OriginColumn(name="latest_opration_time", colType="int64"),
            ),
            appendCols={
                "account_address": OriginColumn(
                    name="address", castFunc=addressFromBytes
                )
            },
        ),
        "account_free_asset_net_usage": SubTable(
            colName="free_asset_net_usage",
            sType="map",
            cols=[
                addressAppend,
                # ColumnIndex(name="asset_id", fromAppend=True),
                # ColumnIndex(name="net_usage", fromAppend=True),
            ],
            mapInfo=MapInfo(
                key=OriginColumn(name="asset_id", colType="string"),
                value=OriginColumn(name="net_usage", colType="int64"),
            ),
            appendCols={
                "account_address": OriginColumn(
                    name="address", castFunc=addressFromBytes
                )
            },
        ),
        "account_free_asset_net_usage_v2": SubTable(
            colName="free_asset_net_usageV2",
            sType="map",
            cols=[
                addressAppend,
                # ColumnIndex(name="asset_id", fromAppend=True),
                # ColumnIndex(name="net_usages", fromAppend=True),
            ],
            mapInfo=MapInfo(
                key=OriginColumn(name="asset_id", colType="string"),
                value=OriginColumn(name="net_usage", colType="int64"),
            ),
            appendCols={
                "account_address": OriginColumn(
                    name="address", castFunc=addressFromBytes
                )
            },
        ),
        "account_resource": SubTable(
            sType="single",
            colName="account_resource",
            cols=[
                addressAppend,
                ColumnIndex(
                    name="energy_usage",
                    oc=OriginColumn(name="energy_usage", colType="int64"),
                ),
                ColumnIndex(
                    name="frozen_balance_for_energy",
                    oc=OriginColumn(
                        name="frozen_balance_for_energy",
                        oc=OriginColumn(name="frozen_balance", colType="int64"),
                    ),
                ),
                ColumnIndex(
                    name="frozen_balance_for_energy_expire_time",
                    oc=OriginColumn(
                        name="frozen_balance_for_energy",
                        oc=OriginColumn(name="expire_time", colType="int64"),
                    ),
                ),
                ColumnIndex(
                    name="latest_consume_time_for_energy",
                    oc=OriginColumn(
                        name="latest_consume_time_for_energy", colType="int64"
                    ),
                ),
                ColumnIndex(
                    name="acquired_delegated_frozen_balance_for_energy",
                    oc=OriginColumn(
                        name="acquired_delegated_frozen_balance_for_energy",
                        colType="int64",
                    ),
                ),
                ColumnIndex(
                    name="delegated_frozen_balance_for_energy",
                    oc=OriginColumn(
                        name="delegated_frozen_balance_for_energy", colType="int64"
                    ),
                ),
                ColumnIndex(
                    name="storage_limit",
                    oc=OriginColumn(name="storage_limit", colType="int64"),
                ),
                ColumnIndex(
                    name="storage_usage",
                    oc=OriginColumn(name="storage_usage", colType="int64"),
                ),
                ColumnIndex(
                    name="latest_exchange_storage_time",
                    oc=OriginColumn(
                        name="latest_exchange_storage_time", colType="int64"
                    ),
                ),
            ],
            subCols=None,
            appendCols={
                "account_address": OriginColumn(
                    name="address", castFunc=addressFromBytes
                )
            },
        ),
        "account_votes": SubTable(
            sType="list",
            colName="votes",
            cols=[
                addressAppend,
                ColumnIndex(
                    name="vote_address",
                    oc=OriginColumn(name="vote_address", castFunc=addressFromBytes),
                ),
                ColumnIndex(
                    name="vote_count",
                    oc=OriginColumn(name="vote_count", colType="int64"),
                ),
            ],
            subCols=None,
            appendCols={
                "account_address": OriginColumn(
                    name="address", castFunc=addressFromBytes
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

    def insert_error(self, tableWriter, data, appendix=None):
        logging.error("Invalid sType {}: ", self.sType)
        return False

    """
    特殊逻辑:
        只允许fromAppend进行有序写入
        然后逐个写入key，value
    """
    # @loginfo
    def insert_map(self, tableWriter, data, appendix=None):
        if data is None or len(data) == 0:
            return True

        appendVals = []
        for col in self.cols:
            appendVals = []
            if col.FromAppend:
                appendVals.append(appendix.get(col.name))
        for key in data:
            insertVals = []
            v = data[key]
            # insert key name & value
            insertVals.append(self.mapInfo.key.String(key))
            insertVals.append(self.mapInfo.value.String(v))

            self.Write(tableWriter, appendVals + insertVals)
        return True

    # @loginfo
    def insert_list(self, tableWriter, data, appendix=None):
        if data is None or len(data) == 0:
            return True
        for d in data:
            ret = self.insert_single(tableWriter, d, appendix)
            if not ret:
                return False
        return True

    # @loginfo
    def insert_single(self, tableWriter, data, appendix=None):
        insertVals = []
        for col in self.cols:
            if col.FromAppend:
                insertVals.append(appendix.get(col.name))
            else:
                insertVals.append(col.oc.getattr(data))

        self.Write(tableWriter, insertVals)
        if self.sType == "single" and self.subCols:
            for table, st in self.subCols.items():
                if hasattr(data, st.colName):
                    # 获取数据
                    subData = getattr(data, st.colName)
                    # logging.info("\n sub data:{}".format(subData))
                    # logging.info("sub data type:{}\n".format(type(subData)))
                    appendData = self.getAppendix(data, st.appendCols)
                    if appendData is None or len(appendData) == 0:
                        logger.error("table: ", table)
                        logger.error("data: ", data)
                        logger.error("data dir: ", dir(data))
                        logger.error("st.appendCols: ", st.appendCols)
                        logger.error("st.table: ", st.table)
                        raise
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
                    ret = subClass.Insert(
                        tableWriter,
                        data=subData,
                        appendix=appendData,
                    )
                    if not ret:
                        return False
        return True

    def Write(self, writer, data):
        writer.write(self.table, data)

    def getAppendix(self, data, appendix):
        if not appendix:
            return None
        appendData = {}
        for col, oc in appendix.items():
            if oc.hasattr(data):
                v = oc.getattr(data)
                appendData[col] = v
        return appendData


def main():
    config, err = ConfigParser.Parse()
    if err is not None:
        logging.error("Failed to get hawq config: {}".format(err))
        exit(-1)
    tableWriter = TableWriter(config)
    start = datetime.datetime.now()
    try:
        accountDB = plyvel.DB(config.get("input_dir"))
        # accountIt = accountDB.iterator()
        accInsert = CommonParseAndInsert(
            cursor=tableWriter,
            cols=Account.cols,
            subCols=Account.subCols,
            table=Account.table,
        )
        count = 0
        acc = Tron_pb2.Account()
        for k, v in accountDB:
            count += 1
            try:
                # if count < 180000:
                #     continue
                if count % 10000 == 0:
                    tableWriter.flush()
                    end = datetime.datetime.now()
                    logging.info(
                        "已处理 {} 个账户，共耗时 {} 微秒".format(count, (end - start).microseconds)
                    )
                acc.ParseFromString(v)
                # if addressFromBytes(acc.address) not in [
                #     # "TA7CEh4xHiY8kh28D6nyM2zVYKB8PSbZhh",
                #     # "T9yDMSrP8exVeYbBy7yFYnM5BNYbquSGRp",
                #     "T9zoNbweZZXd7eVxbasQXDth54FEU3xsnb",
                #     "T9ztt6FVT6c6mSGGRvbBDC32xqtxRAnQQ9",
                #     "TA4JFjPAaY8Gtr4qUVUqBxK98aewUVEPAo",
                #     "TA55VXkWcF2EbKX64aXiP21NidLrvAtF4d",
                #     "TA5k7U2uUz6MxF3bnX1DE6KyzAX63MQ9tp",
                # ]:
                #     continue
                ret = accInsert.Insert(tableWriter, acc)
                if not ret:
                    tableWriter.write(
                        "error_account",
                        [count, b2hs(acc.address), addressFromBytes(acc.address)],
                    )
                    logging.error("解析插入失败:\n address hex: {}".format(b2hs(acc.address)))
                    logging.error(
                        "解析插入失败:\n address: {}".format(addressFromBytes(acc.address))
                    )
            except Exception as e:
                logging.error("解析插入失败:\n address hex: {}".format(b2hs(acc.address)))
                logging.error(
                    "解析插入失败:\n address: {}".format(addressFromBytes(acc.address))
                )
                tableWriter.write(
                    "error_account",
                    [count, b2hs(acc.address), addressFromBytes(acc.address)],
                )
                logger.error("解析插入失败原因: {}".format(e))
    except Exception as e:
        traceback.print_exc()
        logging.error("Failed to run main: {}".format(e))
    finally:
        tableWriter.close()
        end = datetime.datetime.now()
        logging.info(
            "共处理 {} 个账户，共耗时 {} 微秒, 平均单个耗时 {} 微秒".format(
                count - 1,
                (end - start).microseconds,
                (end - start).microseconds / (count - 1),
            )
        )
        logging.info(
            "处理 30004228 个账户，预计用时 {} 小时".format(
                (((30004228 / (count - 1)) * (end - start).microseconds))
                / 1000000
                / 3600
            )
        )
        logging.info("开始时间: {}".format(start.strftime("%Y-%m-%d %H:%M:%S")))
        logging.info("结束时间: {}".format(end.strftime("%Y-%m-%d %H:%M:%S")))


class TableWriter:

    init = False

    # ouput folders
    tables = [
        "error_account",
        "account",
        "account_resource",
        "account_votes",
        "account_asset",
        "account_asset_v2",
        "account_latest_asset_operation_time",
        "account_latest_asset_operation_time_v2",
        "account_frozen",
        "account_frozen_supply",
        "account_free_asset_net_usage",
        "account_free_asset_net_usage_v2",
    ]

    TableWriter = {}
    FileHandler = {}

    def __init__(self, config):
        if self.init:
            raise "TransWriter has been inited!"
        self.config = config
        try:
            self._initWriter()
        except Exception as e:
            self.close()
            raise e

    """
    根据config中outputpath, 创建对应的表目录和以start-num和end-num的csv文件
    打开追加写入的handler
    """

    def _initWriter(self):
        for d in self.tables:
            csv_path = path.join(
                self.config["output_dir"],
                "{}.csv".format(d),
            )
            if os.access(csv_path, os.F_OK):
                logging.error("{} already exists!".format(csv_path))
                raise "Failed to init writers: {}".format(
                    "{} already exists!".format(csv_path)
                )
            f = open(csv_path, "w")
            self.TableWriter[d] = csv.writer(f)
            self.FileHandler[d] = f

    def write(self, table, data):
        self.TableWriter[table].writerow(data)

    def close(self):
        for t, w in self.FileHandler.items():
            try:
                w.close()
            except Exception:
                traceback.print_exc()
                logging.error("Failed to close {}'s writer.".format(t))

    def flush(self):
        for _, w in self.FileHandler.items():
            w.flush()

    def refresh(self):
        self.flush()
        self.close()


if "__main__" == __name__:
    main()
    # test()

# TODO:
# 1. 处理None值，不再插入  account_votes account_frozen account_frozen_supply DONE
# 2. 使用seek并行
# 3. 删除无用log
# 4. account count: 30004228  14ms/acc

# 5. T9yD9dtZuxPe1pgdQuy3QTXPPK51ukLkmr
# address hex: b'4100001f9ac7032955f71612dea92dc850ff3fa087'
