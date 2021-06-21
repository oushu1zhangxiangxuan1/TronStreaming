# -*- encoding: utf-8 -*-
import env
from parsing import Tron_pb2

import plyvel
import traceback
import logging
import datetime

import json

# from parsing import contract
from parsing.base import (
    BaseParser,
    ColumnIndex,
    OriginColumn,
    addressFromBytes,
    autoDecode,
    CheckPathAccess,
    # TransConfigParser,
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


class TransRetConfigParser:
    @staticmethod
    def Parse():
        # valid = False
        config = None
        try:
            with open("./conf/trans_ret.json") as f:
                config = json.load(f)
        except Exception as e:
            logging.error(e)
            return None, "Parse config json error."
        logging.warn("config is : {}".format(config))

        inputDir = config.get("input_dir")
        if inputDir is None or len(inputDir.strip()) == 0:
            logging.error("input_dir not specified.")
            return None, "input_dir not specified."

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


class OrderDetailParser(BaseParser):
    table = "trans_ret_order_detail"

    colIndex = [
        ColumnIndex(name="trans_id", fromAppend=True),
        ColumnIndex(name="order_index", fromAppend=True),
        ColumnIndex(name="call_index", fromAppend=True),
        ColumnIndex(
            name="makerOrderId",
            oc=OriginColumn(name="makerOrderId"),
        ),
        ColumnIndex(
            name="takerOrderId",
            oc=OriginColumn(name="takerOrderId"),
        ),
        ColumnIndex(
            name="fillSellQuantity",
            oc=OriginColumn(name="fillSellQuantity", colType="bigint"),
        ),
        ColumnIndex(
            name="fillSellQuantity",
            oc=OriginColumn(name="fillSellQuantity", colType="bigint"),
        ),
    ]

    # def Parse(self, writer, data, appendData):
    #     return super().Parse(writer, data, appendData)


class CallValueInfoParser(BaseParser):
    table = "trans_ret_inter_trans_call_value"

    colIndex = [
        ColumnIndex(name="trans_id", fromAppend=True),
        ColumnIndex(name="inter_index", fromAppend=True),
        ColumnIndex(name="call_index", fromAppend=True),
        ColumnIndex(
            name="call_value",
            oc=OriginColumn(name="callValue", colType="int64"),
        ),
        ColumnIndex(
            name="token_id",
            oc=OriginColumn(name="tokenId", colType="string"),
        ),
    ]

    # def Parse(self, writer, data, appendData):
    #     return super().Parse(writer, data, appendData)


class TranInfoInterTransParser(BaseParser):
    table = "trans_ret_inter_trans"

    colIndex = [
        ColumnIndex(name="trans_id", fromAppend=True),
        ColumnIndex(name="inter_index", fromAppend=True),
        ColumnIndex(name="hash", oc=OriginColumn(name="hash")),
        ColumnIndex(
            name="caller_address",
            oc=OriginColumn(name="caller_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="transferTo_address",
            oc=OriginColumn(name="transferTo_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(name="note", oc=OriginColumn(name="note")),
        ColumnIndex(name="rejected", oc=OriginColumn(name="rejected", colType="bool")),
    ]

    callValueParser = CallValueInfoParser()

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            return False
        for i, callValue in enumerate(data.callValueInfo):
            appendData.update({"call_index": i})
            ret = self.callValueParser.Parse(writer, callValue, appendData)
            if not ret:
                return False
        return True


class TranInfoLogParser(BaseParser):
    table = "trans_ret_log"

    colIndex = [
        ColumnIndex(name="trans_id", fromAppend=True),
        ColumnIndex(name="log_index", fromAppend=True),
        ColumnIndex(name="address", oc=OriginColumn(name="address")),
        ColumnIndex(name="data", oc=OriginColumn(name="data")),
    ]

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            return False
        for i, topic in enumerate(data.topics):
            writer.write(
                "trans_ret_log_topics",
                [
                    appendData["trans_id"],
                    appendData["log_index"],
                    i,
                    bytes2HexStr(topic),
                ],
            )
        return True


def _receiptWrapper(oc):
    return OriginColumn(name="receipt", oc=oc)


class TransactionInfoParser(BaseParser):
    table = "trans_ret"

    colIndex = [
        ColumnIndex(name="id", oc=OriginColumn(name="id")),
        ColumnIndex(name="fee", oc=OriginColumn(name="fee", colType="int64")),
        ColumnIndex(
            name="block_number", oc=OriginColumn(name="blockNumber", colType="int64")
        ),
        ColumnIndex(
            name="block_timestamp",
            oc=OriginColumn(name="blockTimeStamp", colType="int64"),
        ),
        ColumnIndex(
            name="contract_address",
            oc=OriginColumn(name="contract_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="receipt_energy_usage",
            oc=_receiptWrapper(OriginColumn(name="energy_usage", colType="int64")),
        ),
        ColumnIndex(
            name="receipt_energy_fee",
            oc=_receiptWrapper(OriginColumn(name="energy_fee", colType="int64")),
        ),
        ColumnIndex(
            name="receipt_origin_energy_usage",
            oc=_receiptWrapper(
                OriginColumn(name="origin_energy_usage", colType="int64")
            ),
        ),
        ColumnIndex(
            name="receipt_energy_usage_total",
            oc=_receiptWrapper(
                OriginColumn(name="energy_usage_total", colType="int64")
            ),
        ),
        ColumnIndex(
            name="receipt_net_usage",
            oc=_receiptWrapper(OriginColumn(name="net_usage", colType="int64")),
        ),
        ColumnIndex(
            name="receipt_net_fee",
            oc=_receiptWrapper(OriginColumn(name="net_fee", colType="int64")),
        ),
        ColumnIndex(
            name="receipt_result",
            oc=_receiptWrapper(OriginColumn(name="result", colType="int")),
        ),
        ColumnIndex(name="result", oc=OriginColumn(name="result", colType="int")),
        ColumnIndex(
            name="resMessage",
            oc=OriginColumn(name="resMessage"),
        ),
        ColumnIndex(
            name="asset_issue_id",
            oc=OriginColumn(name="assetIssueID", colType="string"),
        ),
        ColumnIndex(
            name="withdraw_amount",
            oc=OriginColumn(name="withdraw_amount", colType="int64"),
        ),
        ColumnIndex(
            name="unfreeze_amount",
            oc=OriginColumn(name="unfreeze_amount", colType="int64"),
        ),
        ColumnIndex(
            name="exchange_received_amount",
            oc=OriginColumn(name="exchange_received_amount", colType="int64"),
        ),
        ColumnIndex(
            name="exchange_inject_another_amount",
            oc=OriginColumn(name="exchange_inject_another_amount", colType="int64"),
        ),
        ColumnIndex(
            name="exchange_withdraw_another_amount",
            oc=OriginColumn(name="exchange_withdraw_another_amount", colType="int64"),
        ),
        ColumnIndex(
            name="exchange_id", oc=OriginColumn(name="exchange_id", colType="int64")
        ),
        ColumnIndex(
            name="shielded_transaction_fee",
            oc=OriginColumn(name="shielded_transaction_fee", colType="int64"),
        ),
        ColumnIndex(
            name="order_id",
            oc=OriginColumn(name="orderId", castFunc=autoDecode),
        ),
        ColumnIndex(
            name="packing_fee", oc=OriginColumn(name="packingFee", colType="int64")
        ),
    ]

    logParser = TranInfoLogParser()
    interTransParser = TranInfoInterTransParser()
    orderDetailParser = OrderDetailParser()

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            return False
        transId = self.colIndex[0].oc.getattr(data)
        if hasattr(data, "contractResult"):
            for i, contractResult in enumerate(data.contractResult):
                writer.write(
                    "trans_ret_contract_result",
                    [transId, i, bytes2HexStr(contractResult)],
                )
        if hasattr(data, "log"):
            for i, log in enumerate(data.log):
                ret = self.logParser.Parse(
                    writer, log, {"trans_id": transId, "log_index": i}
                )
                if not ret:
                    return False
        if hasattr(data, "internal_transactions"):
            for i, inter_trans in enumerate(data.internal_transactions):
                ret = self.interTransParser.Parse(
                    writer, inter_trans, {"trans_id": transId, "inter_index": i}
                )
                if not ret:
                    return False
        if hasattr(data, "orderDetails"):
            for i, order in enumerate(data.orderDetails):
                ret = self.orderDetailParser.Parse(
                    writer, order, {"trans_id": transId, "order_index": i}
                )
                if not ret:
                    return False
        return True


def _retWrapper(oc):
    return OriginColumn(name="ret", oc=oc, listHead=True)


def _rawDataWrapper(oc):
    return OriginColumn(name="raw_data", oc=oc)


def main():
    # 读配置文件
    # 连接数据库
    # 开始解析
    tables = [
        "trans_ret",
        "trans_ret_contract_result",
        "trans_ret_log",
        "trans_ret_log_topics",
        "trans_ret_inter_trans",
        "trans_ret_inter_trans_call_value",
        "trans_ret_order_detail",
        "trans_ret_error",
    ]
    config, err = TransRetConfigParser.Parse()
    if err is not None:
        logger.error("Failed to get hawq config: {}".format(err))
        exit(-1)
    transWriter = TransWriter(config, tables=tables)

    start = datetime.datetime.now()
    count = 1
    transInfoParser = TransactionInfoParser()
    try:
        transRetDb = plyvel.DB(config.get("input_dir"))
        for i in range(config.get("start_num"), config.get("end_num")):
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
                transRetBytes = transRetDb.get(num2Bytes(i))
                if transRetBytes is None:
                    transWriter.write(
                        "trans_ret_error", ["block", i, "block not exists"]
                    )
                    continue
                transRet = Tron_pb2.TransactionRet()
                transRet.ParseFromString(transRetBytes)
                for transInfo in transRet.transactioninfo:
                    transId = transInfoParser.colIndex[0].oc.getattr(transInfo)
                    ret = transInfoParser.Parse(transWriter, transInfo, None)
                    if not ret:
                        transWriter.write("trans_ret_error", ["trans", transId, None])
                        logger.error("Failed to parse block num: {}".format(i))
                        break
                count += 1
            except Exception:
                logger.error("Failed to parse block num: {}".format(i))
                traceback.print_exc()
                transWriter.write("trans_ret_error", ["block", i, None])
                break
            # except Exception as e:
            #     logger.error("Failed to parse block num: {}".format(i))
            #     traceback.print_exc()
            #     raise e
            #     break

        # end = datetime.datetime.now()
        # logger.info(
        #     "共处理 {} 个区块，共耗时 {} 微秒, 平均单个耗时 {} 微秒".format(
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
