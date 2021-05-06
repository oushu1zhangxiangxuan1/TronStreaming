import env
import streaming.util.global_var as gl
from streaming.config import Config
import logging
import os
import json
import time

from tronapi import Tron
from tronapi import HttpProvider

# pip install tronapi

env.touch()

full_node = HttpProvider("https://api.trongrid.io")
solidity_node = HttpProvider("https://api.trongrid.io")
event_server = HttpProvider("https://api.trongrid.io")

tron = Tron(full_node=full_node, solidity_node=solidity_node, event_server=event_server)
tron.default_block = "latest"


def main():
    gl.config = Config(gl.basic_file)
    ok: bool = gl.config.InitConfig()
    if not ok:
        logging.error(
            "Failed to init config, \
            please recheck config files and contents."
        )
        return
    config = gl.config
    if config.BlockNum < 0:
        logging.error(
            "BlockNum must not less than 0, \
            please recheck config files and contents."
        )
        return

    syncTron = SyncTron(gl.config)
    syncTron.sync()


def getLatestBlockNum():
    return int(tron.trx.get_block("latest")["block_header"]["raw_data"]["number"])


def getLatestBlock():
    return tron.trx.get_block("latest")


def getBlockByNum(block_num):
    return tron.trx.get_block(block_num)


class SyncTron:
    def __init__(self, config):
        self.config = config
        self.curBlock = config.BlockNum

    def sync(self):
        # 获取当前最新BlockNum
        newBlock = getLatestBlock()
        latestNum = int(newBlock["block_header"]["raw_data"]["number"])

        logging.info("lastest block: {}".format(latestNum))

        self.ProcessData(newBlock)
        if latestNum < self.config.BlockNum:
            self.curBlock = latestNum
            logging.error(
                "Warning: Latest BlockNum is less than config.BlockNum, \
                we will sync from lastest block: {}".format(
                    latestNum
                )
            )
            time.sleep(self.config.Interval * 60)
        # 解析参数
        while True:
            newBlock = getLatestBlock()
            latestNum = int(newBlock["block_header"]["raw_data"]["number"])
            self.ProcessData(newBlock)
            if self.curBlock < latestNum:
                data = getBlockByNum(self.curBlock)
                self.ProcessData(data)
                self.curBlock += 1
            else:
                logging.info("---sleeping---")
                logging.info("lastest block: {}".format(latestNum))
                logging.info("cur block: {}".format(self.curBlock))
                time.sleep(self.config.Interval)
            # break

    def ProcessData(self, block):
        block_num = block["block_header"]["raw_data"]["number"]
        logging.info("saving block: {}".format(block_num))
        with open(self.GetBlockFileName(block_num), "w") as f:
            json.dump(block, f, indent=4, ensure_ascii=False)

    def GetBlockFileName(self, block_num):
        file_name = str(block_num) + ".json"
        return os.path.join(self.config.OutputDir, file_name)


if "__main__" == __name__:
    main()
