import env
import parsing.util.global_var as gl
from parsing.config import Config
import logging
import os
import plyvel
import binascii
import Tron_pb2
from parsing.contract import getContract
import copy

env.touch()


def main():
    gl.config = Config(gl.basic_file)
    ok: bool = gl.config.InitConfig()
    if not ok:
        logging.error(
            "Failed to init config, \
            please recheck config files and contents."
        )
        return

    # 尝试链接并创建表

    # 解析并插入表

    parseTron = ParseTron(gl.config)
    parseTron.sync()


class ParseTron:
    def __init__(self, config):
        self.config = config

    def parseTrans(self):
        # 读取trans库
        if not self.transStore:  # is not None
            self.transStore = plyvel.DB(os.path.join(self.config.LevelBase, "trans"))
        # 创建迭代器
        with self.transStore.iterator() as transIter:
            for k, v in transIter:
                txId = binascii.hexlify(k)
                vs = Tron_pb2.Transaction()
                vs.ParseFromString(v)
                txData = {}
                txData["transaction_id"] = txId
                # txData["block_num"] = # TODO: 如何通过trans获取blockNum
                txData["timestamp"] = vs.raw_data.timestamp
                txData["expiration"] = vs.raw_data.expiration
                txData["ref_block_bytes"] = vs.raw_data.ref_block_bytes
                txData["ref_block_hash"] = vs.raw_data.ref_block_hash
                txData["signature"] = vs.signature
                # txData["raw_data_hex"] = vs.raw_data.raw_data_hex
                for i, contract in enumerate(vs.transactions):
                    row = self.parseContract(
                        contract, txId, vs.ret[i].contractRet, copy.deepcopy(txData)
                    )
                    # TODO: ret 需要转化为中文还是ret作为字典表，contract_type也是
                    self.saveToOushuDb(row)
            # 通过迭代器获取数据
            # 通过不同合约类型进行解析
            # 解析后插入数据库

    def parseContract(self, data, txId, ret, txData):
        row = {}
        contract = getContract(data.type)
        contract.ParseFromString(data.parameter.value)
        for field in contract.DESCRIPTOR.fields:
            fieldValue = getattr(contract, field.name)
            if type(fieldValue).__name__ == "bytes":
                row[field.name] = binascii.hexlify(fieldValue)
            else:
                row[field.name] = fieldValue

        # 根据不同的contract type生成不同的数据

        # trans data:
        # transaction_id, block_num, timestamp, expiration, ref_block_bytes,ref_block_hash,fee_limit,signature,raw_data_hex
        #
        # contract：
        #   from_address, to_address, contract_address, owner_address, contract_type, type_url, amount,  contractRet, data,asset_name
        return row.update(txData)

    def saveToOushuDb(self, row):
        pass


if "__main__" == __name__:
    main()
