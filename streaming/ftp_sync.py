import env
import streaming.util.global_var as gl
from streaming.config import Config
import logging
import os
import json
import time
import signal
import tempfile

from tronapi import Tron
from tronapi import HttpProvider

# pip install tronapi

env.touch()

full_node = HttpProvider("https://api.trongrid.io")
solidity_node = HttpProvider("https://api.trongrid.io")
event_server = HttpProvider("https://api.trongrid.io")

tron = Tron(full_node=full_node, solidity_node=solidity_node, event_server=event_server)
tron.default_block = "latest"


def FtpConn():
    from ftplib import FTP

    ftp = FTP()
    ftp.set_debuglevel(2)
    ftp.connect("58.216.137.13", 10021)
    ftp.login("jz_ws", "njws")
    ftp.cwd("/oushu/test/")
    return ftp


ftp = FtpConn()


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
                logging.error("failed to get block info: {}".format(e))
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
                logging.error("failed to get block info: {}".format(e))
                time.sleep(self.config.Interval)

    def ProcessData(self, block):
        block_num = block["block_header"]["raw_data"]["number"]
        logging.info("saving block: {}".format(block_num))
        # with open(self.GetBlockFileName(block_num), "w") as f:
        #     json.dump(block, f, indent=4, ensure_ascii=False)
        with tempfile.SpooledTemporaryFile() as f:
            print("sending {}".format(self.GetJsonName(block_num)))
            data = json.dumps(block, ensure_ascii=False)
            f.write(bytes(data, "utf-8"))
            filename = self.GetJsonName(block_num)
            f.seek(0)
            ftp.storbinary("STOR {}".format(filename), f)
            print("sent {}".format(self.GetJsonName(block_num)))

    def GetBlockFileName(self, block_num):
        file_name = str(block_num) + ".json"
        return os.path.join(self.config.OutputDir, file_name)

    def GetJsonName(self, block_num):
        return str(block_num) + ".json"


def stop(sig, frame):
    print("sig: ", sig)
    print("frame: ", frame)
    gl.stop = True


if "__main__" == __name__:
    with open("./sync.pid", "w") as f:
        f.write(str(os.getpid()))
    signal.signal(2, stop)
    main()
