# -*- encoding: utf-8 -*-
import env
from parsing import Tron_pb2
from typing import Tuple
import chardet

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
# logging.basicConfig(level=logging.INFO)
# logging.basicConfig(
#     format="%(asctime)s.%(msecs)03d [%(levelname)s] [%(filename)s:%(lineno)d] %(message)s",
#     datefmt="## %Y-%m-%d %H:%M:%S",
# )

logging.getLogger().setLevel(logging.INFO)
logger = logging.getLogger()
ch = logging.StreamHandler()
formatter = logging.Formatter(
    "[%(asctime)s][%(levelname)s][%(filename)s:%(lineno)d] %(message)s"
)
# add formatter to console handler
ch.setFormatter(formatter)
logger.addHandler(ch)


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
                logger.error("Failed to decode: {}".format(data))
                # raise e  # TODO: remove raise
                return data
        else:
            return data


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
    ??????config???outputpath, ??????????????????????????????start-num???end-num???csv??????
    ?????????????????????handler
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
                logger.error("{} already exists!".format(csv_path))
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
                logger.error("Failed to close {}'s writer.".format(t))

    def flush(self):
        for _, w in self.FileHandler.items():
            w.flush()

    def refresh(self):
        self.flush()
        self.close()


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
            logger.error(e)
            return None, "Parse config json error."
        logging.warn("config is : {}".format(config))

        inputDir = config.get("input_dir")
        if inputDir is None or len(inputDir.strip()) == 0:
            logger.error("input_dir not specified.")
            return None, "input_dir not specified."

        # check block_dir block_index_dir exists
        block_dir = path.join(inputDir, "block")
        block_index_dir = path.join(inputDir, "block-index")
        ok, err = CheckPathAccess(block_dir)
        if not ok:
            logger.error("block dir {}.".format(err))
            return None, "block dir {}.".format(err)
        config["blockDb"] = block_dir
        ok, err = CheckPathAccess(block_index_dir)
        if not ok:
            logger.error("block_index_dir {}.".format(err))
            return None, "block_index_dir {}.".format(err)
        config["blockIndexDb"] = block_index_dir

        outputDir = config.get("output_dir")
        if outputDir is None or len(outputDir.strip()) == 0:
            logger.error("output_dir not specified.")
            return None, "output_dir not specified."
        ok, err = CheckPathAccess(outputDir)
        if not ok:
            logger.error("output_dir {}.".format(err))
            return None, "output_dir {}.".format(err)

        start_num = config.get("start_num")
        if start_num is None or type(start_num) is not int or start_num < 0:
            logger.error("start_num should be positive integer.")
            return None, "start_num should be positive integer."

        end_num = config.get("end_num")
        if end_num is None or type(end_num) is not int or end_num < 0:
            logger.error("end_num should be positive integer.")
            return None, "end_num should be positive integer."

        if start_num >= end_num:
            logger.error("end_num greater than start_num.")
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
            logger.error(
                "Failed to getattr: {}\n From data: {}".format(self.name, data)
            )
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
            logger.error("???????????????????????????????????????????????????????????????????????????")
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
        super().Parse(writer, data, appendData)
        transAppend = {
            "block_hash": appendData["hash"],
            "block_num": appendData["block_num"],
        }
        for trans in data.transactions:
            transId = hashlib.sha256(trans.raw_data.SerializeToString()).hexdigest()
            transAppend["id"] = transId
            ret = transParser.Parse(writer, trans, transAppend)
            if not ret:
                # ??????trans,block
                writer.write("err_trans_v1", [appendData["block_num"], transId])
                return False
        return True


def _retWrapper(oc):
    return OriginColumn(name="ret", oc=oc, listHead=True)


def _rawDataWrapper(oc):
    return OriginColumn(name="raw_data", oc=oc)


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
            oc=_retWrapper(OriginColumn(name="order_id", castFunc=autoDecode)),
        ),
        ColumnIndex(
            name="ref_block_bytes",
            oc=_rawDataWrapper(OriginColumn(name="ref_block_bytes")),
        ),
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
            # oc=_rawDataWrapper(OriginColumn(name="scripts", castFunc=autoDecode)),
            oc=_rawDataWrapper(OriginColumn(name="scripts")),
        ),
        ColumnIndex(
            name="data",
            # oc=_rawDataWrapper(OriginColumn(name="data", castFunc=autoDecode)),
            oc=_rawDataWrapper(OriginColumn(name="data")),
        ),
        ColumnIndex(
            name="signature",
            oc=OriginColumn(
                name="signature",
                listHead=True,
                oc=OriginColumn(name="signature", colType="bytes"),
            ),
        ),
    ]

    table = "trans"

    def Parse(self, writer, data, appendData):
        super().Parse(writer, data, appendData)
        odAppend = {"trans_id": appendData["id"]}

        if hasattr(data.ret, "orderDetails"):
            ods = getattr(data.ret, "orderDetails")
            for od in ods:
                OrderDetailParser.Parse(writer, od, odAppend)

        if hasattr(data.raw_data, "auths"):
            auths = getattr(data.raw_data, "auths")
            for auth in auths:
                AuthParser.Parse(writer, auth, odAppend)

        # ??????v1????????????contract
        if data.raw_data.contract[0].type in [
            contract.ContractType.CreateSmartContract.value,
            contract.ContractType.AccountPermissionUpdateContract.value,
            contract.ContractType.ProposalCreateContract.value,
            contract.ContractType.VoteAssetContract.value,
            contract.ContractType.VoteWitnessContract.value,
            contract.ContractType.ShieldedTransferContract.value,
            contract.ContractType.MarketSellAssetContract.value,
            contract.ContractType.MarketCancelOrderContract.value,
        ]:
            return True

        # ??????contract
        # logger.info("trans data: {}".format(data))
        odAppend["ret"] = None
        # print("data: ", data)
        if len(data.ret) > 0:
            # print("data.ret len: ", len(data.ret))
            # print("data.ret[0].contractRet: ", len(data.ret[0].contractRet))
            odAppend["ret"] = data.ret[0].contractRet
        # print("odAppend: ", odAppend)

        contractParser = contract.getContractParser(data.raw_data.contract[0].type)

        # if (
        #     data.raw_data.contract[0].type
        #     == contract.ContractType.UnfreezeAssetContract.value
        # ):
        #     logging.error("unfrezze trans id: {}".format(appendData["id"]))
        #     logging.error(
        #         "data.raw_data.contract[0].type: {}".format(
        #             data.raw_data.contract[0].type
        #         )
        #     )
        #     logging.error("contractParser: {}".format(contractParser))
        try:
            ret = contractParser.Parse(
                writer, data.raw_data.contract[0].parameter.value, odAppend
            )
            # if (
            #     data.raw_data.contract[0].type
            #     == contract.ContractType.UnfreezeAssetContract.value
            # ):
            #     logging.error("unfrezze trans id: {}".format(appendData["id"]))
            #     logging.error("contractParser: {}".format(contractParser))
            #     return False
            return ret
        except Exception as e:
            logger.error(
                "Failed from contract type: {}, \nCause:\n{}".format(
                    contract.contractTableMap.get(data.raw_data.contract[0].type), e
                )
            )
            return False


transParser = TransParser()


class AuthParser(BaseParser):

    colIndex = [
        ColumnIndex(name="trans_id", fromAppend=True),
        ColumnIndex(
            name="account_id",
            oc=OriginColumn(
                name="account", oc=OriginColumn(name="name", colType="bytes")
            ),
        ),  # TODO??? ?????????b2hs????????????decode
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
        logger.error("Failed to get hawq config: {}".format(err))
        exit(-1)
    transWriter = TransWriter(config)

    start = datetime.datetime.now()
    count = 1
    try:
        blockDb = plyvel.DB(config.get("blockDb"))
        blockIndexDb = plyvel.DB(config.get("blockIndexDb"))

        contract.initContractParser()
        for i in range(config.get("start_num"), config.get("end_num")):
            try:
                if count % 1000 == 0:
                    end = datetime.datetime.now()
                    logger.info(
                        "????????? {} ????????????????????? {} ??????, ?????????????????? {} ??????".format(
                            count,
                            (end - start).microseconds,
                            (end - start).microseconds / count,
                        )
                    )
                    transWriter.flush()
                blockHashBytes = blockIndexDb.get(num2Bytes(i))
                blockBytes = blockDb.get(blockHashBytes)
                blockHash = bytes2HexStr(blockHashBytes)
                block = Tron_pb2.Block()
                block.ParseFromString(blockBytes)
                appendData = {"block_num": i, "hash": blockHash}
                bp = BlockParser()
                ret = bp.Parse(transWriter, block, appendData)
                if not ret:
                    logger.error("Failed to parse block num: {}".format(i))
                    break
                count += 1
            except Exception:
                logger.error("Failed to parse block num: {}".format(i))
                traceback.print_exc()
                transWriter.write("error_block_num", [i])
                break
            # except Exception as e:
            #     logger.error("Failed to parse block num: {}".format(i))
            #     traceback.print_exc()
            #     raise e
            #     break

        # end = datetime.datetime.now()
        # logger.info(
        #     "????????? {} ????????????????????? {} ??????, ?????????????????? {} ??????".format(
        #         count - 1,
        #         (end - start).microseconds,
        #         (end - start).microseconds / (count - 1),
        #     )
        # )
    except Exception:
        traceback.print_exc()
    finally:
        transWriter.flush()
        transWriter.close()
        end = datetime.datetime.now()
        logger.info(
            "????????? {} ????????????????????? {} ??????, ?????????????????? {} ??????".format(
                count - 1,
                (end - start).microseconds,
                (end - start).microseconds / (count - 1),
            )
        )
        logger.info(
            "?????? 29617377 ???????????????????????? {} ??????".format(
                ((29617377 / (count - 1)) * (end - start).microseconds) / 1000000 / 3600
            )
        )
        logger.info("????????????: {}".format(start.strftime("%Y-%m-%d %H:%M:%S")))
        logger.info("????????????: {}".format(end.strftime("%Y-%m-%d %H:%M:%S")))


if "__main__" == __name__:
    main()

# 1. ????????????: output-directory ?????????????????????  blockDB???blockIndexDB?????????
# 2. ??????hawq???????????????[start block num, end block num]  0-29617377
# 3. ?????????block-num??????block???hash
# 4. ??????block?????????tx_count??????block??????
# 5. ??????trans?????????trans??????trans???
# 6. touch detail, ?????????????????????trans_order_detail???
# 7. ??????contract_type??????contract???????????????contract???
# 8. ??????contract???????????????hex_bytes?????????????????????
# 9. ???????????????hdfs?????? -> ????????????????????????csv??????
# 10.???????????????csv?????????????????????????????????????????????????????????????????????????????????????????????
# TODO:
# 1. ?????????????????????
# 2. owner???account???address??????base58
# 3. ??????????????????????????????????????????????????????????????????????????????????????????blockdb??????
# 4. ???????????????????????????block???????????????????????????????????????block
# 5. ????????????????????????????????????????????????????????????????????????????????????????????????????????????trans_id????????????????????????
# 6. ???????????????trans_id????????????
# 7. account??????account_name??????????????????b2hs,??????decode???????????????
