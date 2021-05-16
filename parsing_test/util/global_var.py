from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import env
from parsing.config import Config

# import os

env.touch()

config: Config = None

# basic_file: str = '/Users/johnsaxon/go/src/github.com/oushu-io/littleboy-cv/video_infer/conf/basic.yaml'
# cameras_file: str = '/Users/johnsaxon/go/src/github.com/oushu-io/littleboy-cv/video_infer/conf/cameras.yaml'


# basic_file: str = os.path.join(env.LITTLEBOY_CV_HOME, 'conf/basic.yaml')
# cameras_file: str = os.path.join(env.LITTLEBOY_CV_HOME, 'conf/cameras.yaml')

basic_file: str = "/Users/johnsaxon/test/github.com/TronStreaming/streaming/sync.yaml"

# print("basic_file is : ", basic_file)
# print("cameras_file is : ", cameras_file)


if __name__ == "__main__":
    print(config)
