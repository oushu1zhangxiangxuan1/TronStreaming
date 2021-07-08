# -*- encoding: utf-8 -*-
import env
from typing import List, Tuple, Any
import yaml
import logging
from streaming.util.utils import CheckPathAccess
import psycopg2
import traceback
import os
import json
import time
from streaming.block import BlockParser

env.touch()


class Config:

    _MustCheck: List[str] = [
        "BlockNum",
        "OutputDir",
        "Interval",
        "Ceiling",
        "Master",
        "Standby",
        "Port",
        "User",
        "Database",
        "Password",
    ]

    __isInit: bool = False

    def __init__(self, basic: str, mustCheck=None):
        self.basic_file: str = basic
        if mustCheck:
            self._MustCheck = mustCheck

    @staticmethod
    def ReadYaml(file: str) -> Tuple[Any, bool]:
        try:
            with open(file, "r") as f:
                return yaml.load(f, Loader=yaml.FullLoader), True
        except Exception as e:
            print(e)
            print("Can not access file:" + file)
            logging.error(e)
            return {}, False

    def __getBasicConfig(self) -> Tuple[Any, bool]:
        return self.ReadYaml(self.basic_file)

    def InitConfig(self) -> bool:
        self.basic_config, ok = self.__getBasicConfig()
        if not ok:
            logging.error(
                "Can not access basic config, please check basic config file:"
                + self.basic_file
            )
            return False

        logging.info(self.basic_config)

        for key in self._MustCheck:
            value = self.basic_config.get(key)
            if value is None:
                logging.error("Can not find config:" + key)
                return False
            else:
                setattr(self, key, value)

        ok, err = CheckPathAccess(self.OutputDir)
        if not ok:
            logging.error("Can not access OutputDir :%s", self.OutputDir)
            return False
        # TODO: check hawq conn
        return True


def getConn(config):
    try:
        conn = psycopg2.connect(
            database=config.Database,
            user=config.User,
            password=config.Password,
            host=config.Master,
            port=str(config.Port),
        )
        return conn
    except Exception as e:
        logging.error("Conn hawq master failed!")
        logging.error(e)
        logging.error(traceback.format_exc())
        conn = psycopg2.connect(
            database=config.Database,
            user=config.User,
            password=config.Password,
            host=config.Standby,
            port=str(config.Port),
        )
        return conn


class TronUpdate:
    def __init__(self, config, conn):
        self.config = config
        self.conn = conn
        self.cur = conn.cursor()
        self.BlockNum = config.BlockNum

    def Update(self):
        """
        1. 读取开始块号文件
        2. 解析并写block表
        3. 解析并写trans表
        4. 解析并写contract相关表
        5. 更新account等信息: 新增用户、余额变动、asset余额变动、frozen等变动、新增asset、assetid自增
        6. 将区块号加一并循环第一步
        7. 如果找不到文件则sleep interval秒
        """
        blockParser = BlockParser(engine="sql")
        while True:

            if not os.path.exists(self.getBlockFile()):
                time.sleep(self.config.Interval)
                continue
            with open(self.getBlockFile()) as f:
                block = json.load(f)
                # 写block表
                ret = blockParser.Sql(self.cur, block, {"block_num": self.BlockNum})
                if not ret:
                    # or len(sqls) == 0:
                    logging.error("Failed to get block sql: {}".format(self.BlockNum))

                    return False
                # self.cur.excute(";".join(sqls))
                self.conn.commit()
                self.BlockNum += 1
            break
            if self.BlockNum > 3:
                break

    def getBlockFile(self):
        return os.path.join(self.config.OutputDir, "{}.json".format(self.BlockNum))


def main():
    """
    1. 解析配置，验证hawq连接性
    2. 验证outputdir存在且是dir，获取开始块号
    3. 如果开始块号对应的文件不存在，则报错
    """
    config = Config("./update.yaml")
    ok = config.InitConfig()
    if not ok:
        logging.error(
            "Failed to init config, \
            please recheck config files and contents."
        )
        return
    if config.BlockNum < 0:
        logging.error(
            "BlockNum must not less than 0, \
            please recheck config files and contents."
        )
        return
    # check latest block json
    lastId = -1
    try:
        with open("update.id", "r") as f:
            lastId = int(f.read())
    except Exception as e:
        logging.error("Cannot read last id file: {}".format(e))
    else:
        config.BlockNum = lastId

    lastBlock = os.path.join(config.OutputDir, "{}.json".format(config.BlockNum))
    if not os.path.isfile(lastBlock):
        logging.error("Cannot read last block file: {}".format(lastBlock))
        return
    if not os.access(lastBlock, os.R_OK):
        logging.error("Cannot read last block file: {}".format(lastBlock))
        return

    conn = getConn(config)
    if not conn:
        logging.error("Failed to connect hawq.")
        return
    try:
        tron = TronUpdate(config, conn)
        tron.Update()
        with open("update.id", "w") as f:
            f.write(str(tron.BlockNum))
        # TODO: tron.BlockNum写入update.id
    except Exception as e:
        traceback.print_exc()
        logging.error("Failed to run main: {}".format(e))
    finally:
        try:
            conn.rollback()
        finally:
            conn.close()


if "__main__" == __name__:
    main()
