import env
import streaming.util.global_var as gl
from streaming.config import Config
import logging
import os
import json
import time
import signal

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

    lastId = -1
    try:
        with open("last.id", "r") as f:
            lastId = int(f.read())
    except Exception as e:
        logging.error("Cannot read last id file: {}".format(e))
    else:
        gl.config.BlockNum = lastId

    print("gl.config.BlockNum: ", gl.config.BlockNum)

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
        self.sync = self.sync_to_lastest
        if config.Ceiling > 0:
            self.sync = self.sync_with_ceiling

    def sync_to_lastest(self):
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

        while True:
            if gl.stop:
                with open("last.id", "w") as f:
                    f.write(str(self.curBlock))
                return
            try:
                if self.curBlock < latestNum:
                    data = getBlockByNum(self.curBlock)
                    self.ProcessData(data)
                    self.curBlock += 1
                else:
                    newBlock = getLatestBlock()
                    latestNum = int(newBlock["block_header"]["raw_data"]["number"])
                    self.ProcessData(newBlock)
                    if self.curBlock < latestNum:
                        continue
                    logging.info("---sleeping---")
                    logging.info("lastest block: {}".format(latestNum))
                    logging.info("cur block: {}".format(self.curBlock))
                    time.sleep(self.config.Interval)
            except Exception as e:
                with open("last.id", "w") as f:
                    f.write(str(self.curBlock))
                logging.error("failed to get block info: ", e)
                time.sleep(self.config.Interval)

    def sync_with_ceiling(self):
        while self.curBlock <= self.config.Ceiling:
            if gl.stop:
                with open("last.id", "w") as f:
                    f.write(str(self.curBlock))
                return
            try:
                data = getBlockByNum(self.curBlock)
                self.ProcessData(data)
                self.curBlock += 1
            except Exception as e:
                with open("last.id", "w") as f:
                    f.write(str(self.curBlock))
                logging.error("failed to get block info: ", e)
                time.sleep(self.config.Interval)

    def ProcessData(self, block):
        block_num = block["block_header"]["raw_data"]["number"]
        logging.info("saving block: {}".format(block_num))
        with open(self.GetBlockFileName(block_num), "w") as f:
            json.dump(block, f, indent=4, ensure_ascii=False)

    def GetBlockFileName(self, block_num):
        file_name = str(block_num) + ".json"
        return os.path.join(self.config.OutputDir, file_name)


def stop(sig, frame):
    print("sig: ", sig)
    print("frame: ", frame)
    gl.stop = True


if "__main__" == __name__:
    print(
        json.dumps(
            tron.trx.get_transaction_info(
                # "06dcdfb14392f12350a0f7959f2e3879875077b381925f3edf69493938010bf8"
                # "ffbac79a2e0dea8993055d06a813d7671eca0abf6afca15a11f2e5d3bf528282"
                "f5b54e2bf7caaca5aa8a0489caf7e77f4494e61a480e3f282d1d69cf21469683"  # USDT
            ),
            indent=4,
            ensure_ascii=False,
        )
    )
