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

    table = "realtime_block"

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
                # 记录trans,block
                writer.write("err_trans_v1", [appendData["block_num"], transId])
                return False
        return True

    # def Sql(self, data, appendData):
    #     pass


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

    table = "realtime_trans"

    def Parse(self, writer, data, appendData):
        super().Parse(writer, data, appendData)
        odAppend = {"trans_id": appendData["id"]}

        if hasattr(data.ret, "orderDetails"):
            ods = getattr(data.raw_data, "orderDetails")
            for od in ods:
                OrderDetailParser.Parse(writer, od, odAppend)

        if hasattr(data.raw_data, "auths"):
            auths = getattr(data.raw_data, "auths")
            for auth in auths:
                AuthParser.Parse(writer, auth, odAppend)

        # 过滤v1中解析的contract
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

        # 解析contract
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
