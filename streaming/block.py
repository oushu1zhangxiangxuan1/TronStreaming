# -*- encoding: utf-8 -*-
import env
import hashlib
import logging
from streaming import contract
from streaming.base import (
    BaseParser,
    ColumnIndex,
    OriginColumn,
    addressFromBytes,
    addressFromHex,
    # bytes2HexStr,
    # ownerAddressDecode,
    autoDecode,
)

env.touch()

logging.getLogger().setLevel(logging.INFO)
logger = logging.getLogger()
ch = logging.StreamHandler()
formatter = logging.Formatter(
    "[%(asctime)s][%(levelname)s][%(filename)s:%(lineno)d] %(message)s"
)
# add formatter to console handler
ch.setFormatter(formatter)
logger.addHandler(ch)


def _blockHeaderWrapper(oc):
    return OriginColumn(name="block_header", oc=OriginColumn(name="raw_data", oc=oc))


def _retWrapper(oc):
    return OriginColumn(name="ret", oc=oc, listHead=True)


def _rawDataWrapper(oc):
    return OriginColumn(name="raw_data", oc=oc)


class TransParser(BaseParser):
    def __init__(self, engine="csv", contractParserMap=None):
        super().__init__(self, engine=engine)
        self.contractParserMap = contract.InitContractParser(engine)

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

    table = "realtime_trans"

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            return False
        odAppend = {"trans_id": appendData["id"]}

        if hasattr(data, "ret") and len(data.ret) > 0:
            for od in data.ret[0].orderDetails:
                ret = OrderDetailParser.Parse(writer, od, odAppend)
                if not ret:
                    return False

        if hasattr(data.raw_data, "auths"):
            for auth in data.raw_data.auths:
                ret = AuthParser.Parse(writer, auth, odAppend)
                if not ret:
                    return False

        # 解析contract
        odAppend["ret"] = None
        if len(data.ret) > 0:
            odAppend["ret"] = data.ret[0].contractRet

        contractParser = contract.getContractParser(data.raw_data.contract[0].type)
        try:
            ret = contractParser.Parse(
                writer, data.raw_data.contract[0].parameter.value, odAppend
            )
            return ret
        except Exception as e:
            logger.error(
                "Failed from contract type: {}, \nCause:\n{}".format(
                    contract.contractTableMap.get(data.raw_data.contract[0].type), e
                )
            )
            return False

    def Sql(self, cur, data, appendData):
        ret = super().Sql(cur, data, appendData)
        if not ret:
            return False
        odAppend = {"trans_id": appendData["id"]}

        if "ret" in data:
            ret = data.get("ret")
            if ret and len(ret) > 0:
                if "orderDetails" in ret[0]:
                    ods = ret[0].get("orderDetails")
                    for od in ods:
                        ret = OrderDetailParser.Sql(cur, od, odAppend)
                        if not ret:
                            return False

        raw_data = data.get("raw_data")
        if "auths" in raw_data:
            auths = raw_data.get("auths")
            for auth in auths:
                ret = AuthParser.Sql(cur, auth, odAppend)
                if not ret:
                    return False

        # 解析contract
        odAppend["ret"] = None
        # ret需要转换成 int
        if len(data.ret) > 0:
            odAppend["ret"] = data.ret[0].get("contractRet")

        _contract = raw_data.get("contract")[0]
        contractParser = contract.getContractParser(_contract.get("type"))
        try:
            ret = contractParser.Sql(
                cur, _contract.get("parameter").get("value"), odAppend
            )
            return ret
        except Exception as e:
            logger.error(
                "Failed from contract type: {}, \nCause:\n{}".format(
                    contract.contractTableMap.get(_contract.get("type")), e
                )
            )
            return False


class BlockParser(BaseParser):

    colIndex = [
        ColumnIndex(name="block_num", fromAppend=True),
        ColumnIndex(
            name="block_hash", oc=OriginColumn(name="blockID", colType="bytes")
        ),
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
                OriginColumn(
                    name="witness_address",
                    castFunc=addressFromBytes,
                    castFuncSql=addressFromHex,
                )
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

    table = "realtime_block"
    transParser = TransParser(engine="sql")

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            # 记录block error
            return False
        transAppend = {
            "block_hash": appendData["hash"],
            "block_num": appendData["block_num"],
        }
        for trans in data.transactions:
            transId = hashlib.sha256(trans.raw_data.SerializeToString()).hexdigest()
            transAppend["id"] = transId
            ret = self.transParser.Parse(writer, trans, transAppend)
            if not ret:
                # 记录trans,block
                writer.write("err_trans_v1", [appendData["block_num"], transId])
                return False
        return True

    def Sql(self, cur, data, appendData):
        ret = super().Sql(cur, data, appendData)
        if not ret:
            return False
        # 解析交易
        for trans in data.get("transactions"):
            ret = self.transParser.Sql(cur, trans, appendData)
            if not ret:
                # TODO: 需要记录错误的交易hash和块号
                return False
        return True
        # pass


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
                name="account",
                oc=OriginColumn(
                    name="name", castFunc=addressFromBytes, castFuncSql=addressFromHex
                ),
            ),
        ),
        ColumnIndex(
            name="permission_name",
            oc=OriginColumn(name="permission_name", colType="bytes"),
        ),
    ]

    table = "realtime_trans_market_order_detail"


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

    table = "realtime_trans_market_order_detail"
