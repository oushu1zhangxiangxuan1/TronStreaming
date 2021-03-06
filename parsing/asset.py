# -*- encoding:"utf-8"-*-
import env
import json
import logging
import datetime
import os
from os import path
import traceback
import csv
import plyvel
import parsing.core.contract.asset_issue_contract_pb2 as asset_issue_contract_pb2
from parsing.base import (
    BaseParser,
    ColumnIndex,
    OriginColumn,
    addressFromBytes,
    autoDecode,
    CheckPathAccess,
)

env.touch()

# AssetIssueContractParser.table = "asset_issue_v2"
# FrozenSupplyParser.table = "asset_issue_v2_frozen_supply"

# assetIssueV2Parser = AssetIssueContractParser()
# assetIssueV2Parser.frozenSupplyParser = FrozenSupplyParser()


class AssetConfigParser:
    @staticmethod
    def Parse():
        # valid = False
        config = None
        try:
            with open("./asset.json") as f:
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


class AssetWriter:

    init = False

    # ouput folders
    tables = [
        "error_asset_id",
        "asset_issue_v2",
        "asset_issue_v2_frozen_supply",
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
                logging.error("{} already exists!".format(csv_path))
                raise "Failed to init writers: {}".format(
                    "{} already exists!".format(csv_path)
                )
            f = open(csv_path, "w")
            self.TableWriter[d] = csv.writer(f, delimiter="|", quoting=csv.QUOTE_ALL)
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


class AssetIssueV2Parser(BaseParser):
    def __init__(self):
        self.frozenSupplyParser = FrozenSupplyParser()

    colIndex = [
        ColumnIndex(
            name="id",
            oc=OriginColumn(
                name="id", colType="string"
            ),  # TODO: check id not null and unique after decode
        ),
        # ColumnIndex(
        #     name="owner_address",
        #     oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        # ),
        ColumnIndex(
            name="name",
            oc=OriginColumn(name="name", castFunc=autoDecode),
        ),
        # ColumnIndex(
        #     name="abbr",
        #     oc=OriginColumn(name="abbr", castFunc=autoDecode),
        # ),
        # ColumnIndex(
        #     name="total_supply",
        #     oc=OriginColumn(name="total_supply", colType="int64"),
        # ),
        # ColumnIndex(
        #     name="trx_num",
        #     oc=OriginColumn(name="trx_num", colType="int32"),
        # ),
        # ColumnIndex(
        #     name="precision",
        #     oc=OriginColumn(name="precision", colType="int32"),
        # ),
        # ColumnIndex(
        #     name="num",
        #     oc=OriginColumn(name="num", colType="int32"),
        # ),
        # ColumnIndex(
        #     name="start_time",
        #     oc=OriginColumn(name="start_time", colType="int64"),
        # ),
        # ColumnIndex(
        #     name="end_time",
        #     oc=OriginColumn(name="end_time", colType="int64"),
        # ),
        # ColumnIndex(
        #     name="order_",
        #     oc=OriginColumn(name="order", colType="int64"),
        # ),
        # ColumnIndex(
        #     name="vote_score",
        #     oc=OriginColumn(name="account_address", colType="int32"),
        # ),
        # ColumnIndex(
        #     name="description",
        #     oc=OriginColumn(name="description", castFunc=autoDecode),
        # ),
        # ColumnIndex(
        #     name="url",
        #     oc=OriginColumn(name="url", castFunc=autoDecode),
        # ),
        # ColumnIndex(
        #     name="free_asset_net_limit",
        #     oc=OriginColumn(name="free_asset_net_limit", colType="int64"),
        # ),
        # ColumnIndex(
        #     name="public_free_asset_net_limit",
        #     oc=OriginColumn(name="public_free_asset_net_limit", colType="int64"),
        # ),
        # ColumnIndex(
        #     name="public_free_asset_net_usage",
        #     oc=OriginColumn(name="public_free_asset_net_usage", colType="int64"),
        # ),
        # ColumnIndex(
        #     name="public_latest_free_net_time",
        #     oc=OriginColumn(name="public_latest_free_net_time", colType="int64"),
        # ),
    ]
    table = "asset_issue_v2"

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        return ret
        if not ret:
            return False
        frozenAppend = {
            "asset_id": data.id,
            "asset_name": autoDecode(data.name),
        }
        for f in data.frozen_supply:
            ret = self.frozenSupplyParser.Parse(writer, f, frozenAppend)
            if not ret:
                return False
        return True


class FrozenSupplyParser(BaseParser):
    table = "asset_issue_v2_frozen_supply"
    colIndex = [
        ColumnIndex(
            name="asset_id",
            fromAppend=True,
        ),
        ColumnIndex(
            name="asset_name",
            fromAppend=True,
        ),
        ColumnIndex(
            name="frozen_amount",
            oc=OriginColumn(name="frozen_amount", colType="int64"),
        ),
        ColumnIndex(
            name="frozen_days",
            oc=OriginColumn(name="frozen_days", colType="int64"),
        ),
    ]


"""
1. ????????????
2. ???????????????
3. open csv handler defer close
4. ????????????????????????asset_issue_contract
5. ???csv
"""


def main():
    config, err = AssetConfigParser.Parse()
    if err is not None:
        logging.error("Failed to get hawq config: {}".format(err))
        exit(-1)
    assetWriter = AssetWriter(config)

    start = datetime.datetime.now()
    count = 1
    try:
        assetV2DB = plyvel.DB(config.get("input_dir"))
        # for i in range(config.get("start_num"), config.get("end_num")):
        assetIssueV2Parser = AssetIssueV2Parser()
        for k, v in assetV2DB:
            count += 1
            try:
                if count % 1000 == 0:
                    end = datetime.datetime.now()
                    logging.info(
                        "????????? {} ??? asset issue???????????? {} ??????, ?????????????????? {} ??????".format(
                            count,
                            (end - start).microseconds,
                            (end - start).microseconds / count,
                        )
                    )
                    assetWriter.flush()
                # if k.decode() not in [
                #     "1000436",
                #     "1004368",
                #     "1000329",
                #     "1000370",
                #     "1000371",
                #     "1000322",
                #     "1000373",
                # ]:
                #     return
                aic = asset_issue_contract_pb2.AssetIssueContract()
                aic.ParseFromString(v)
                ret = assetIssueV2Parser.Parse(assetWriter, aic, None)
                if not ret:
                    logging.error("Failed to parse asset id: {}".format(k.decode()))
                    break
            except Exception:
                logging.error("Failed to parse asset id: {}".format(k.decode()))
                traceback.print_exc()
                assetWriter.write("error_asset_id", [k.decode()])
                break
            # except Exception as e:
            #     logging.error("Failed to parse asset id: {}".format(k.decode()))
            #     traceback.print_exc()
            #     raise e
            #     break

        # end = datetime.datetime.now()
        # logging.info(
        #     "????????? {} ????????????????????? {} ??????, ?????????????????? {} ??????".format(
        #         count - 1,
        #         (end - start).microseconds,
        #         (end - start).microseconds / (count - 1),
        #     )
        # )
    except Exception:
        traceback.print_exc()
    finally:
        assetWriter.flush()
        assetWriter.close()
        end = datetime.datetime.now()
        logging.info(
            "????????? {} ????????????????????? {} ??????, ?????????????????? {} ??????".format(
                count - 1,
                (end - start).microseconds,
                (end - start).microseconds / (count - 1),
            )
        )
        logging.info(
            "?????? 29617377 ???????????????????????? {} ??????".format(
                ((29617377 / (count - 1)) * (end - start).microseconds) / 1000000 / 3600
            )
        )
        logging.info("????????????: {}".format(start.strftime("%Y-%m-%d %H:%M:%S")))
        logging.info("????????????: {}".format(end.strftime("%Y-%m-%d %H:%M:%S")))


if "__main__" == __name__:
    main()
