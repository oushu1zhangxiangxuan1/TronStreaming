import logging
from binascii import hexlify as b2hs
import tronapi
import chardet
import os
from typing import Tuple
import json
from os import path
import csv
import traceback


def num2Bytes(n):
    return n.to_bytes(8, "big")


def CheckPathAccess(path: str) -> Tuple[bool, str]:
    if not os.path.isdir(path):
        return False, "Dir not exists."
    if not os.access(path, os.W_OK):
        return False, "Permission denied."
    return True, None


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
    return data.decode()


def ownerAddressDecode(data):
    try:
        return bytesRawDecode(data)
    except Exception:
        return addressFromBytes(data)


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
                logging.error("Failed to decode: {}".format(data))
                # raise e  # TODO: remove raise
                return data
        else:
            return data


class BaseParser:
    colIndex = []
    table = None

    def Parse(self, writer, data, appendData=None):
        if len(self.colIndex) == 0 or self.table is None:
            logging.error("请勿直接调用抽象类方法，请实例化类并未对象变量赋值")
            return False

        vals = []
        for col in self.colIndex:
            if col.FromAppend:
                vals.append(appendData[col.name])
            else:
                vals.append(col.oc.getattr(data))
            # if col.name == "tx_count":
            #     print("col: ", col.name)
            #     print("vals: ", vals)
            #     print("vals len: ", len(vals))
            #     print()
        self.Write(writer, vals)
        return True

    def Write(self, writer, data):
        writer.write(self.table, data)


class ColumnIndex:
    def __init__(self, name, fromAppend=False, oc=None):
        self.name = name
        self.FromAppend = fromAppend
        self.oc = oc


class OriginColumn:
    def __init__(
        self,
        name=None,
        colType="bytes",
        castFunc=None,
        oc=None,
        listHead=False,
        default=None,
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
            raise e


class TransConfigParser:
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


class TransWriter:

    init = False

    # ouput folders
    tables = [
        "err_trans_v1",
        "block",
        "trans",
        "trans_market_order_detail",
        "trans_auths",
        "account_create_contract",
        "transfer_contract",
        "transfer_asset_contract",
        # "vote_asset_contract",
        # "vote_witness_contract",
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
        # "proposal_create_contract",
        "proposal_approve_contract",
        "proposal_delete_contract",
        "set_account_id_contract",
        # "create_smart_contract",
        "trigger_smart_contract",
        "update_setting_contract",
        "exchange_create_contract",
        "exchange_inject_contract",
        "exchange_withdraw_contract",
        "exchange_transaction_contract",
        "update_energy_limit_contract",
        # "account_permission_update_contract",
        "clear_abi_contract",
        "update_brokerage_contract",
        # "shielded_transfer_contract",
        "error_block_num",
        # V1
        # "err_trans_v1",
        # "trans_v1",
        # #
        # "create_smart_contract_v1",
        # "create_smart_contract_abi_v1",
        # "create_smart_contract_abi_inputs_v1",
        # "create_smart_contract_abi_outputs_v1",
        # #
        # "account_permission_update_contract_v1",
        # "account_permission_update_contract_keys_v1",
        # "account_permission_update_contract_actives_v1",
        # #
        # "proposal_create_contract_v1",
        # "proposal_create_contract_parameters_v1",
        # #
        # "vote_asset_contract_vote_address_v1",
        # "vote_asset_contract_v1",
        # #
        # "vote_witness_contract_v1",
        # "vote_witness_contract_votes_v1",
        # #
        # "shielded_transfer_contract_v1",
        # #
        # "market_sell_asset_contract_v1",
        # "market_cancel_order_contract_v1",
    ]

    TableWriter = {}
    FileHandler = {}

    def __init__(self, config, tables=None):
        if self.init:
            raise "TransWriter has been inited!"
        self.config = config
        if tables:
            self.tables = tables
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
            ok, _ = CheckPathAccess(table_dir)
            if not ok:
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

    def flush(self):
        for _, w in self.FileHandler.items():
            w.flush()

    def refresh(self):
        self.flush()
        self.close()
