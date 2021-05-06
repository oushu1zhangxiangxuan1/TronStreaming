from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
import env
import yaml
import logging

from typing import List, Tuple, Any
from streaming.util.utils import CheckPathAccess


env.touch()


basic: str = './conf/basic.yaml'
cameras: str = './conf/cameras.yaml'

logging.basicConfig(level=logging.INFO)


class Config:

    __MustCheck: List[str] = [
        'BlockNum',
        'OutputDir',
        'Interval',
    ]

    __isInit: bool = False

    def __init__(self, basic: str):
        self.basic_file: str = basic

    @staticmethod
    def ReadYaml(file: str) -> Tuple[Any, bool]:
        try:
            with open(file, 'r') as f:
                return yaml.load(f, Loader=yaml.FullLoader), True
        except Exception as e:
            print(e)
            print("Can not access file:"+file)
            logging.error(e)
            return {}, False

    def __getBasicConfig(self) -> Tuple[Any, bool]:
        return self.ReadYaml(self.basic_file)

    def InitConfig(self) -> bool:
        self.basic_config, ok = self.__getBasicConfig()
        if not ok:
            logging.error(
                "Can not access basic config, please check basic config file:"+self.basic_file)
            return False

        logging.info(self.basic_config)

        for key in self.__MustCheck:
            value = self.basic_config.get(key)
            if value is None:
                logging.error("Can not find config:"+key)
                return False
            else:
                setattr(self, key, value)

        ok, err = CheckPathAccess(self.OutputDir)
        if not ok:
            logging.error("Can not access OutputDir :%s, please check sync.yaml:%s",
                          self.LogPath, self.cameras_file)
            return False

        return True


if __name__ == '__main__':
    config = Config('/Users/johnsaxon/test/github.com/TronStreaming/streaming/sync.yaml')
    ok = config.InitConfig()
    print(ok)

    __MustCheck: List[str] = [
        'BlockNum',
        'OutputDir',
        'Interval',
    ]
    for key in __MustCheck:
        print(getattr(config, key))

