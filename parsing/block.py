# -*- encoding: utf-8 -*-
import env
from parsing import Tron_pb2
from typing import Tuple

import json
import plyvel

import functools
import hashlib
import csv

from Crypto.Util.number import bytes_to_long as b2l
from binascii import hexlify as b2hs
import tronapi
import traceback
import logging
import datetime

import os
from os import path

from parsing import contract

# import parsing.contract as contract

# from parsing.contract import getContractParser

# .getContractParser as getContractParser

env.touch()
logging.basicConfig(level=logging.INFO)


def bytes2HexStr(data):
    return b2hs(data).decode()


def bytes2HexStr_V2(data):
    return "".join(["%02X " % b for b in data])


def addressFromHex(hex_str):
    return tronapi.common.account.Address().from_hex(hex_str).decode()


def addressFromBytes(addr):
    return tronapi.common.account.Address().from_hex(bytes.decode(b2hs(addr))).decode()


class TransWriter:

    init = False

    # ouput folders
    tables = [
        "block",
        "trans",
        "trans_market_order_detail",
        "trans_auths",
        "account_create_contract",
        "transfer_contract",
        "transfer_asset_contract",
        "vote_asset_contract",
        "vote_witness_contract",
        "witness_create_contract",
        "asset_issue_contract",
        "asset_issue_contract_frozen_supply",
        "witness_update_contract",
        "participate_asset_issue_contract",
        "account_update_contract",
        "freeze_balance_contract",
        "unfreeze_balance_contract",
        "withdraw_balance_contract",
        "unfreeze_asset_contract",
        "update_asset_contract",
        "proposal_create_contract",
        "proposal_approve_contract",
        "proposal_delete_contract",
        "set_account_id_contract",
        "create_smart_contract",
        "trigger_smart_contract",
        "update_setting_contract",
        "exchange_create_contract",
        "exchange_inject_contract",
        "exchange_withdraw_contract",
        "exchange_transaction_contract",
        "update_energy_limit_contract",
        "account_permission_update_contract",
        "clear_abi_contract",
        "update_brokerage_contract",
        "shielded_transfer_contract",
    ]

    TableWriter = {}

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
            table_dir = path.join(self.config.output_dir, d)
            os.mkdirs(table_dir)
            csv_path = path.join(
                table_dir,
                "{}-{}.csv".format(self.config.start_num, self.config.end_num),
            )
            if os.access(csv_path, os.F_OK):
                logging.error("{} already exists!".format(csv_path))
                raise "Failed to init writers: {}".format(
                    "{} already exists!".format(csv_path)
                )
            f = open(csv_path, "w")
            self.TableWriter[d] = csv.writer(f)

    def write(self, table, data):
        self.TableWriter[table].writerow(data)

    def close(self):
        for t, w in self.TableWriter.values():
            try:
                w.close()
            except Exception:
                logging.error("Failed to close {}'s writer.".format(t))


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
            with open("./block.json") as f:
                config = json.load(f)
        except Exception as e:
            logging.error(e)
            return None, "Parse config json error."
        logging.warn("config is : {}".format(config))

        inputDir = config.get("input_dir")
        if inputDir is None or len(inputDir.strip()) == 0:
            logging.error("input_dir not specified.")
            return None, "input_dir not specified."

        # check block_dir block_index_dir exists
        block_dir = path.join(inputDir, "block")
        block_index_dir = path.join(inputDir, "block-index")
        ok, err = CheckPathAccess(block_dir)
        if not ok:
            logging.error("block dir {}.".format(err))
            return None, "block dir {}.".format(err)
        ok, err = CheckPathAccess(block_index_dir)
        if not ok:
            logging.error("block_index_dir {}.".format(err))
            return None, "block_index_dir {}.".format(err)

        outputDir = config.get("output_dir")
        if outputDir is None or len(outputDir.strip()) == 0:
            logging.error("output_dir not specified.")
            return None, "output_dir not specified."
        ok, err = CheckPathAccess(outputDir)
        if not ok:
            logging.error("output_dir {}.".format(err))
            return None, "output_dir {}.".format(err)

        start_num = config.get("start_num")
        if start_num is None or type(start_num) is not int or start_num < 0:
            logging.error("start_num should be positive integer.")
            return None, "start_num should be positive integer."

        end_num = config.get("end_num")
        if end_num is None or type(end_num) is not int or end_num < 0:
            logging.error("end_num should be positive integer.")
            return None, "end_num should be positive integer."

        if start_num >= end_num:
            logging.error("end_num greater than start_num.")
            return None, "end_num greater than start_num."

        return config, None


class OriginColumn:
    def __init__(
        self, name=None, colType="bytes", castFunc=None, oc=None, listHead=False
    ):
        self.oc = oc
        self.name = name
        self.toNum = None
        self.listHead = listHead
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
        if self.listHead:
            data = data[0]
        has = hasattr(data, self.name)
        if not self.oc:
            return has
        if has:
            subData = getattr(data, self.name)
            return self.oc.hasattr(subData)
        return False

    def getattr(self, data):
        if self.listHead:
            data = data[0]
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


def num2Bytes(n):
    return n.to_bytes(8, "big")


class OriginColumnWapper:
    def __init__(self, name, oc):
        self.name = name
        self.oc = oc


class ColumnIndex:
    def __init__(self, name, fromAppend=False, oc=None):
        self.name = name
        self.FromAppend = fromAppend
        self.oc = oc


class BaseParser:
    colIndex = []
    table = None

    def Parse(self, writer, data, appendData):
        if len(self.colIndex) == 0 or self.table is None:
            logging.error("请勿直接调用抽象类方法，请实例化类并未对象变量赋值")
            return False

        vals = []
        for col in self.colIndex:
            if col.FromAppend:
                vals.append(appendData[col.name])
            else:
                vals.append(col.oc.getattr(data))
        self.Write(writer, vals)
        return True

    def Write(self, writer, data):
        writer[self.table].write(data)


def _blockHeaderWrapper(oc):
    return OriginColumn(name="block_header", oc=OriginColumn(name="raw_data", oc=oc))


class BlockParser(BaseParser):

    colIndex = [
        ColumnIndex(name="block_num", fromAppend=True),
        ColumnIndex(name="hash", fromAppend=True),
        ColumnIndex(
            name="parent_hash",
            oc=_blockHeaderWrapper(OriginColumn(name="parentHash", colType="bytes")),
        ),
        ColumnIndex(
            name="create_time",
            oc=_blockHeaderWrapper(OriginColumn(name="timestamp", colType="bytes")),
        ),
        ColumnIndex(
            name="version",
            oc=_blockHeaderWrapper(OriginColumn(name="version", colType="int32")),
        ),
        ColumnIndex(
            name="witness_address",
            oc=_blockHeaderWrapper(
                OriginColumn(name="witness_address", castFunc=addressFromBytes)
            ),
        ),
        ColumnIndex(
            name="witness_id",
            oc=_blockHeaderWrapper(OriginColumn(name="witness_id", colType="int64")),
        ),
        ColumnIndex(
            name="tx_count", oc=OriginColumn(name="transactions", castFunc=len)
        ),
        ColumnIndex(
            name="tx_trie_root",
            oc=_blockHeaderWrapper(OriginColumn(name="txTrieRoot", colType="bytes")),
        ),
        ColumnIndex(
            name="witness_signature",
            oc=OriginColumn(
                name="block_header",
                oc=OriginColumn(name="witness_signature", colType="bytes"),
            ),
        ),
        ColumnIndex(
            name="account_state_root",
            oc=_blockHeaderWrapper(
                OriginColumn(name="accountStateRoot", colType="bytes")
            ),
        ),
    ]

    subTables = {
        "trans": SubTable(
            colName="transactions",
            sType="list",
            cols=[
                ColumnIndex(name="block_num", fromAppend=True),
                ColumnIndex(name="hash", fromAppend=True),
                ColumnIndex(
                    name="parent_hash",
                    oc=_blockHeaderWrapper(
                        OriginColumn(name="parentHash", colType="bytes")
                    ),
                ),
                ColumnIndex(
                    name="create_time",
                    oc=_blockHeaderWrapper(
                        OriginColumn(name="timestamp", colType="bytes")
                    ),
                ),
                ColumnIndex(
                    name="version",
                    oc=_blockHeaderWrapper(
                        OriginColumn(name="version", colType="int32")
                    ),
                ),
                ColumnIndex(
                    name="witness_address",
                    oc=_blockHeaderWrapper(
                        OriginColumn(name="witness_address", castFunc=addressFromBytes)
                    ),
                ),
                ColumnIndex(
                    name="witness_id",
                    oc=_blockHeaderWrapper(
                        OriginColumn(name="witness_id", colType="int64")
                    ),
                ),
                ColumnIndex(
                    name="tx_count", oc=OriginColumn(name="transactions", castFunc=len)
                ),
                ColumnIndex(
                    name="tx_trie_root",
                    oc=_blockHeaderWrapper(
                        OriginColumn(name="txTrieRoot", colType="bytes")
                    ),
                ),
                ColumnIndex(
                    name="witness_signature",
                    oc=OriginColumn(
                        name="block_header",
                        oc=OriginColumn(name="witness_signature", colType="bytes"),
                    ),
                ),
                ColumnIndex(
                    name="account_state_root",
                    oc=_blockHeaderWrapper(
                        OriginColumn(name="accountStateRoot", colType="bytes")
                    ),
                ),
            ],
            appendCols={
                "account_address": OriginColumn(
                    "address", "bytes", castFunc=addressFromBytes
                )
            },
        ),
    }

    table = "block"

    def Parse(self, writer, data, appendData):
        super().Parse(writer, data, appendData)  # TODO: chceck params
        transAppend = {
            "block_hash": appendData["hash"],
            "block_num": appendData["block_num"],
        }
        for trans in data.transactions:
            transId = hashlib.sha256(trans.raw_data.SerializeToString()).hexdigest()
            transAppend["id"] = transId
            TransParser.Parse(writer, trans, transAppend)
        return True


def _retWrapper(oc):
    return OriginColumn(name="ret", oc=oc, listHead=True)


def _rawDataWrapper(oc):
    return OriginColumn(name="raw_data", oc=oc)


# TODO: oc getattr should be revised if data not get
class TransParser(BaseParser):

    colIndex = [
        ColumnIndex(name="id", fromAppend=True),
        ColumnIndex(name="block_hash", fromAppend=True),
        ColumnIndex(name="block_num", fromAppend=True),
        # ret
        ColumnIndex(
            name="fee", oc=_retWrapper(OriginColumn(name="fee", colType="int64"))
        ),
        ColumnIndex(
            name="ret", oc=_retWrapper(OriginColumn(name="ret", colType="int"))
        ),
        ColumnIndex(
            name="contract_ret",
            oc=_retWrapper(OriginColumn(name="contractRet", colType="int")),
        ),
        ColumnIndex(
            name="asset_issue_id",
            oc=_retWrapper(OriginColumn(name="assetIssueID", colType="bytes")),
        ),
        ColumnIndex(
            name="withdraw_amount",
            oc=_retWrapper(OriginColumn(name="withdraw_amount", colType="int64")),
        ),
        ColumnIndex(
            name="unfreeze_amount",
            oc=_retWrapper(OriginColumn(name="unfreeze_amount", colType="int64")),
        ),
        ColumnIndex(
            name="exchange_received_amount",
            oc=_retWrapper(
                OriginColumn(name="exchange_received_amount", colType="int64")
            ),
        ),
        ColumnIndex(
            name="exchange_inject_another_amount",
            oc=_retWrapper(
                OriginColumn(name="exchange_inject_another_amount", colType="int64")
            ),
        ),
        ColumnIndex(
            name="exchange_withdraw_another_amount",
            oc=_retWrapper(
                OriginColumn(name="exchange_withdraw_another_amount", colType="int64")
            ),
        ),
        ColumnIndex(
            name="exchange_id",
            oc=_retWrapper(OriginColumn(name="exchange_id", colType="int64")),
        ),
        ColumnIndex(
            name="order_id",
            oc=_retWrapper(OriginColumn(name="order_id", colType="bytes")),
        ),
        # raw
        ColumnIndex(
            name="ref_block_num",
            oc=_rawDataWrapper(OriginColumn(name="ref_block_num", colType="int64")),
        ),
        ColumnIndex(
            name="ref_block_hash",
            oc=_rawDataWrapper(OriginColumn(name="ref_block_hash", colType="bytes")),
        ),
        ColumnIndex(
            name="expiration",
            oc=_rawDataWrapper(OriginColumn(name="expiration", colType="int64")),
        ),
        ColumnIndex(
            name="trans_time",
            oc=_rawDataWrapper(OriginColumn(name="timestamp", colType="int64")),
        ),
        ColumnIndex(
            name="fee_limit",
            oc=_rawDataWrapper(OriginColumn(name="fee_limit", colType="bytes")),
        ),
        ColumnIndex(
            name="scripts",
            oc=_rawDataWrapper(OriginColumn(name="scripts", colType="int64")),
        ),
        ColumnIndex(
            name="data", oc=_rawDataWrapper(OriginColumn(name="data", colType="int64"))
        ),
        # ColumnIndex(name="signature", oc=OriginColumn(name="signature", colType="bytes", castFunc=parseFirst)), TODO: 处理
        ColumnIndex(
            name="witness_signature",
            oc=OriginColumn(
                name="block_header",
                oc=OriginColumn(name="witness_signature", colType="bytes"),
            ),
        ),
    ]

    table = "trans"

    def Parse(self, writer, data, appendData):
        super().Parse(writer, data, appendData)  # TODO: chceck params
        odAppend = {"trans_id": appendData["id"]}

        if hasattr(data.ret, "orderDetails"):
            ods = getattr(data.raw_data, "orderDetails")
            for od in ods:
                OrderDetailParser.Parse(writer, od, odAppend)

        if hasattr(data.raw_data, "auths"):
            auths = getattr(data.raw_data, "auths")
            for auth in auths:
                AuthParser.Parse(writer, auth, odAppend)

        # TODO: 解析contract
        odAppend["ret"] = data.ret.contractRet
        contractParser = contract.getContractParser(
            writer, data.raw_data.contract[0].type
        )
        ret = contractParser.Parse(
            writer, data.raw_data.contract[0].parameter.value, odAppend
        )
        return ret


# class


class AuthParser(BaseParser):

    colIndex = [
        ColumnIndex(name="trans_id", fromAppend=True),
        ColumnIndex(
            name="account_id",
            oc=OriginColumn(
                name="account", oc=OriginColumn(name="name", colType="bytes")
            ),
        ),  # TODO： 这个是b2hs还是直接decode
        ColumnIndex(
            name="account_name",
            oc=OriginColumn(
                name="account", oc=OriginColumn(name="name", castFunc=addressFromBytes)
            ),
        ),
        ColumnIndex(
            name="permission_name",
            oc=OriginColumn(name="permission_name", colType="bytes"),
        ),
    ]

    table = "trans_market_order_detail"


class OrderDetailParser:

    colIndex = [
        ColumnIndex(name="trans_id", fromAppend=True),
        ColumnIndex(
            name="maker_order_id", oc=OriginColumn(name="makerOrderId", colType="bytes")
        ),
        ColumnIndex(
            name="taker_order_id", oc=OriginColumn(name="takerOrderId", colType="bytes")
        ),
        ColumnIndex(
            name="fill_sell_quantity",
            oc=OriginColumn(name="fillSellQuantity", colType="int64"),
        ),
        ColumnIndex(
            name="fill_buy_quantity",
            oc=OriginColumn(name="fillBuyQuantity", colType="int64"),
        ),
    ]

    table = "trans_market_order_detail"


def main():
    config, err = ConfigParser.Parse()
    if err is not None:
        logging.error("Failed to get hawq config: {}".format(err))
        exit(-1)
    transWriter = TransWriter(config)
    try:
        blockDb = plyvel.DB(config.blockDb)
        blockIndexDb = plyvel.DB(config.blockIndexDb)

        count = 0
        start = datetime.datetime.now()

        for i in range(config.start_num, config.end_num):
            if count % 100 == 0:
                end = datetime.datetime.now()
                logging.info(
                    "已处理 {} 个账户，共耗时 {} 微秒, 平均单个耗时 {} 微秒".format(
                        count,
                        (end - start).microseconds,
                        (end - start).microseconds / count,
                    )
                )
            count += 1
            print(i)
            blockHashBytes = blockIndexDb.get(num2Bytes(i))
            blockBytes = blockDb.get(blockHashBytes)
            blockHash = bytes2HexStr(blockHashBytes)
            block = Tron_pb2.Block()
            block.ParseFromString(blockBytes)
            appendData = {"block_num": i, "hash": blockHash}
            bp = BlockParser()
            ret = bp.Parse(transWriter, block, appendData)
            if not ret:
                logging.error("Failed to parse block num: {}".format(i))

        end = datetime.datetime.now()
        logging.info(
            "共处理 {} 个账户，共耗时 {} 微秒, 平均单个耗时 {} 微秒".format(
                count,
                (end - start).microseconds,
                (end - start).microseconds / count,
            )
        )
    except Exception:
        traceback.print_exc()
    finally:
        transWriter.close()


if "__main__" == __name__:
    main()

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
# 7. account中的account_name可能不能使用b2hs,需要decode支持中文的
