# -*- encoding: utf-8 -*-
import env
from parsing import Tron_pb2

import plyvel
import hashlib
import traceback
import logging
import datetime
from parsing import contract
from parsing.base import (
    BaseParser,
    ColumnIndex,
    OriginColumn,
    # addressFromBytes,
    autoDecode,
    # CheckPathAccess,
    TransConfigParser,
    TransWriter,
    bytes2HexStr,
    num2Bytes,
)

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


class BlockParser(BaseParser):
    def Parse(self, writer, data, appendData):
        # super().Parse(writer, data, appendData)
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
        return super().Parse(writer, data, appendData)


transParser = TransParser()

tables = [
    "err_trans_v1",
    "trans",
]


lack_blocks = [
    27779189,
    28096332,
    28078777,
    28109154,
    29353174,
    29319124,
    28096371,
    28069505,
    28073568,
    27587264,
    28128355,
    27581476,
    28180651,
    28096321,
    28118082,
    28107537,
    27587288,
    27581743,
    28109115,
    29353199,
    28180688,
    27581436,
    28128398,
    28107475,
    28118123,
    28109057,
    28069312,
    28078793,
    28107566,
    28073602,
    27581758,
    28107624,
    21541218,
    27779160,
    28069473,
    21541322,
    28069332,
    28096275,
]


def main():
    """ """
    config, err = TransConfigParser.Parse()
    if err is not None:
        logger.error("Failed to get block config: {}".format(err))
        exit(-1)
    transWriter = TransWriter(config, tables)

    start = datetime.datetime.now()
    count = 1
    try:
        blockDb = plyvel.DB(config.get("blockDb"))
        blockIndexDb = plyvel.DB(config.get("blockIndexDb"))

        contract.initContractParser()
        for blockNum in lack_blocks:
            try:
                if count % 1000 == 0:
                    end = datetime.datetime.now()
                    logger.info(
                        "已处理 {} 个区块，共耗时 {} 微秒, 平均单个耗时 {} 微秒".format(
                            count,
                            (end - start).microseconds,
                            (end - start).microseconds / count,
                        )
                    )
                    transWriter.flush()
                blockHashBytes = blockIndexDb.get(num2Bytes(int(blockNum)))
                blockBytes = blockDb.get(blockHashBytes)
                blockHash = bytes2HexStr(blockHashBytes)
                block = Tron_pb2.Block()
                block.ParseFromString(blockBytes)
                appendData = {
                    "block_num": blockNum,
                    "hash": blockHash,
                }
                bp = BlockParser()
                ret = bp.Parse(transWriter, block, appendData)
                if not ret:
                    logger.error("Failed to parse block num: {}".format(blockNum))
                    break
                count += 1
            except Exception:
                logger.error("Failed to parse block num: {}".format(blockNum))
                traceback.print_exc()
                break
    except Exception:
        traceback.print_exc()
    finally:
        transWriter.flush()
        transWriter.close()
        end = datetime.datetime.now()
        logger.info(
            "共处理 {} 个区块，共耗时 {} 微秒, 平均单个耗时 {} 微秒".format(
                count - 1,
                (end - start).microseconds,
                (end - start).microseconds / (count - 1),
            )
        )
        logger.info(
            "处理 29617377 个区块，预计用时 {} 小时".format(
                ((29617377 / (count - 1)) * (end - start).microseconds) / 1000000 / 3600
            )
        )
        logger.info("开始时间: {}".format(start.strftime("%Y-%m-%d %H:%M:%S")))
        logger.info("结束时间: {}".format(end.strftime("%Y-%m-%d %H:%M:%S")))


if "__main__" == __name__:
    main()
