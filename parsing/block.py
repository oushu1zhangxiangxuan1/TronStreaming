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
    cache = tronapi.common.account.Address().from_hex(bytes.decode(b2hs(addr)))
    if type(cache) == bytes:
        return cache.decode()
    return cache


def bytesRawDecode(data):
    if b"\xa0" in data:
        return data.decode("latin1")
    return data.decode()


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
        "error_block_num",
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
            table_dir = path.join(self.config["output_dir"], d)
            os.makedirs(table_dir)
            csv_path = path.join(
                table_dir,
                "{}-{}.csv".format(self.config["start_num"], self.config["end_num"]),
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
        config["blockDb"] = block_dir
        ok, err = CheckPathAccess(block_index_dir)
        if not ok:
            logging.error("block_index_dir {}.".format(err))
            return None, "block_index_dir {}.".format(err)
        config["blockIndexDb"] = block_index_dir

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
            logging.error(
                "Failed to getattr: {}\n From data: {}".format(self.name, data)
            )
            traceback.print_exc()
            raise e


def num2Bytes(n):
    return n.to_bytes(8, "big")


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
            # print("col: ", col.name)
            if col.FromAppend:
                vals.append(appendData[col.name])
            else:
                vals.append(col.oc.getattr(data))
            # print("vals: ", vals)
            # print("vals len: ", len(vals))
            # print()
        self.Write(writer, vals)
        return True

    def Write(self, writer, data):
        writer.write(self.table, data)


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
            oc=_blockHeaderWrapper(OriginColumn(name="timestamp", colType="int64")),
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
            transParser.Parse(writer, trans, transAppend)
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
            name="contract_type",
            oc=_rawDataWrapper(
                OriginColumn(
                    name="contract",
                    oc=OriginColumn(name="type", colType="int"),
                    listHead=True,
                )
            ),
        ),
        ColumnIndex(
            name="contract_ret",
            oc=_retWrapper(OriginColumn(name="contractRet", colType="int")),
        ),
        ColumnIndex(
            name="asset_issue_id",
            oc=_retWrapper(OriginColumn(name="assetIssueID", colType="string")),
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
            name="shielded_transaction_fee",
            oc=_retWrapper(
                OriginColumn(name="shielded_transaction_fee", colType="int64")
            ),
        ),
        ColumnIndex(
            name="order_id",
            oc=_retWrapper(OriginColumn(name="order_id", colType="bytes")),
        ),  # TODO: deocode or hex
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
            oc=_rawDataWrapper(OriginColumn(name="fee_limit", colType="int64")),
        ),
        ColumnIndex(
            name="scripts",
            oc=_rawDataWrapper(
                OriginColumn(name="scripts", colType="bytes")
            ),  # TODO: deocode or hex
        ),
        ColumnIndex(
            name="scripts_decode",
            oc=_rawDataWrapper(
                OriginColumn(name="scripts", castFunc=bytesRawDecode)
            ),  # TODO: deocode or hex
        ),
        ColumnIndex(
            name="data",
            oc=_rawDataWrapper(
                OriginColumn(name="data", colType="bytes")
            ),  # TODO: deocode or hex
        ),
        ColumnIndex(
            name="data_decode",
            oc=_rawDataWrapper(
                OriginColumn(name="data", castFunc=bytesRawDecode)
            ),  # TODO: deocode or hex
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

        # 解析contract
        # logging.info("trans data: {}".format(data))
        odAppend["ret"] = ""
        if len(data.ret) > 0:
            odAppend["ret"] = data.ret[0].contractRet
        contractParser = contract.getContractParser(data.raw_data.contract[0].type)
        try:
            ret = contractParser.Parse(
                writer, data.raw_data.contract[0].parameter.value, odAppend
            )
            return ret
        except Exception as e:
            logging.error(
                "Failed from contract type: {}".format(
                    contract.contractTableMap.get(data.raw_data.contract[0].type)
                )
            )
            raise e


transParser = TransParser()


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

    start = datetime.datetime.now()
    try:
        blockDb = plyvel.DB(config.get("blockDb"))
        blockIndexDb = plyvel.DB(config.get("blockIndexDb"))

        contract.initContractParser()

        count = 1
        for i in range(config.get("start_num"), config.get("end_num")):
            try:
                if count % 100 == 0:
                    end = datetime.datetime.now()
                    logging.info(
                        "已处理 {} 个区块，共耗时 {} 微秒, 平均单个耗时 {} 微秒".format(
                            count,
                            (end - start).microseconds,
                            (end - start).microseconds / count,
                        )
                    )
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
                count += 1
            except Exception:
                logging.error("Failed to parse block num: {}".format(i))
                traceback.print_exc()
                transWriter.write("error_block_num", [i])
            # except Exception as e:
            #     logging.error("Failed to parse block num: {}".format(i))
            #     traceback.print_exc()
            #     raise e
            #     break

        # end = datetime.datetime.now()
        # logging.info(
        #     "共处理 {} 个区块，共耗时 {} 微秒, 平均单个耗时 {} 微秒".format(
        #         count - 1,
        #         (end - start).microseconds,
        #         (end - start).microseconds / (count - 1),
        #     )
        # )
    except Exception:
        traceback.print_exc()
    finally:
        transWriter.close()
        end = datetime.datetime.now()
        logging.info(
            "共处理 {} 个区块，共耗时 {} 微秒, 平均单个耗时 {} 微秒".format(
                count - 1,
                (end - start).microseconds,
                (end - start).microseconds / (count - 1),
            )
        )
        logging.info(
            "处理 29617377 个区块，预计用时 {} 小时".format(
                (229617377 / (count - 1)) * (end - start).microseconds / 1000000 / 3600
            )
        )


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
