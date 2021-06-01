import logging
from binascii import hexlify as b2hs
import tronapi
import chardet
import os
from typing import Tuple


def CheckPathAccess(path: str) -> Tuple[bool, str]:
    if not os.path.isdir(path):
        return False, "Dir not exists."
    if not os.access(path, os.W_OK):
        return False, "Permission denied."
    return True, None


def bytes2HexStr(data):
    return b2hs(data).decode()


def bytes2HexStr_V2(data):
    return "".join(["%02X " % b for b in data])


def addressFromHex(hex_str):
    return tronapi.common.account.Address().from_hex(hex_str).decode()


def addressFromBytes(addr):
    cache = tronapi.common.account.Address().from_hex(bytes.decode(b2hs(addr)))
    if type(cache) == bytes:
        return cache.decode()
    return cache


def bytesRawDecode(data):
    return data.decode()


def ownerAddressDecode(data):
    try:
        return bytesRawDecode(data)
    except Exception:
        return addressFromBytes(data)


def autoDecode(data):
    try:
        return data.decode()
    except Exception:
        encs = chardet.detect(data)
        if encs and encs["encoding"] and len(encs["encoding"]) > 0:
            try:
                return data.decode(encs["encoding"])
            # except Exception as e:
            except Exception:
                logging.error("Failed to decode: {}".format(data))
                # raise e  # TODO: remove raise
                return data
        else:
            return data


class BaseParser:
    colIndex = []
    table = None

    def Parse(self, writer, data, appendData):
        if len(self.colIndex) == 0 or self.table is None:
            logging.error("请勿直接调用抽象类方法，请实例化类并未对象变量赋值")
            return False

        vals = []
        for col in self.colIndex:
            if col.FromAppend:
                vals.append(appendData[col.name])
            else:
                vals.append(col.oc.getattr(data))
            # if col.name == "tx_count":
            #     print("col: ", col.name)
            #     print("vals: ", vals)
            #     print("vals len: ", len(vals))
            #     print()
        self.Write(writer, vals)
        return True

    def Write(self, writer, data):
        writer.write(self.table, data)


class ColumnIndex:
    def __init__(self, name, fromAppend=False, oc=None):
        self.name = name
        self.FromAppend = fromAppend
        self.oc = oc


class OriginColumn:
    def __init__(
        self,
        name=None,
        colType="bytes",
        castFunc=None,
        oc=None,
        listHead=False,
        default=None,
    ):
        self.oc = oc
        self.name = name
        # self.toNum = None
        self.listHead = listHead
        self.default = default
        if not self.oc:
            self.type = colType
            self.castFunc = castFunc
            # if (
            #     castFunc == b2l
            #     or castFunc == b2l
            #     or colType in ["int64", "int32", "int"]
            # ):
            #     self.toNum = True
            if castFunc is None and colType == "bytes":
                self.castFunc = bytes2HexStr

    def String(self, v):
        if self.castFunc:
            v = self.castFunc(v)
        # if self.toNum:
        #     return "{}".format(v)
        # return "'{}'".format(v)
        return v

    def hasattr(self, data):
        has = hasattr(data, self.name)
        if not has:
            return False
        subData = getattr(data, self.name)
        if self.listHead:
            if len(subData) == 0:
                return False
            subData = subData[0]
        if not self.oc:
            return True
        return self.oc.hasattr(subData)

    def getattr(self, data):
        try:
            if not self.hasattr(data):
                return self.default
            subData = getattr(data, self.name)
            if self.listHead:
                subData = subData[0]
            if not self.oc:
                return self.String(subData)
            return self.oc.getattr(subData)
        except Exception as e:
            logging.error(
                "Failed to getattr: {}\n From data: {}".format(self.name, data)
            )
            raise e
