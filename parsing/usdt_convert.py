# -*- encoding:"utf-8"-*-
import env
import csv
import datetime
from Crypto.Util.number import bytes_to_long as b2l
from parsing.base import addressFromBytes

env.touch()

usdt_in_file = "/DATA/tron_usdt/from_to_amount.csv"

usdt_out_file = "/DATA/tron_usdt/from_to_amount.csv"

# usdt_in_file = "usdt_head.csv"

# usdt_out_file = "usdt_conv.csv"


def topic2Address(topic):
    return addressFromBytes(bytes.fromhex("41" + topic[-40:]))


def main():
    start = datetime.datetime.now()
    i = 0
    count = 10
    with open(usdt_in_file) as rf:
        r_csv = csv.reader(rf)
        with open(usdt_out_file, "w") as wf:
            w_csv = csv.writer(wf)
            conv_start = datetime.datetime.now()
            read_time = (conv_start - start).total_seconds()
            print("读取耗时 {} 微秒, {} 秒".format(read_time * 10 ** 6, read_time))
            for rline in r_csv:
                print("src data: ", rline)
                rline[2] = addressFromBytes(bytes.fromhex("41" + rline[2][-40:]))
                rline[3] = addressFromBytes(bytes.fromhex("41" + rline[3][-40:]))
                rline[4] = b2l(bytes.fromhex(rline[4])) / 1000000
                print("dst data: ", rline)
                w_csv.writerow(rline)
                i += 1
                if i % 1000 == 0:
                    wf.flush()
                if i == 10:
                    break
            wf.flush()

    end = datetime.datetime.now()
    conv_time = (end - conv_start).total_seconds()
    print("解析 {} 条 总耗时 {} 微秒, {} 秒".format(count, conv_time * 10 ** 6, conv_time))
    print(
        "单条耗时 {} 微秒, 解析 68678330 条预计耗时 {} 秒, {} 分钟".format(
            conv_time * 10 ** 6 / count,
            (conv_time / count) * 68678330,
            (conv_time / count) * 68678330 / 60,
        )
    )


if "__main__" == __name__:
    main()

# 读csv
# 将第3，4列转address
# 第5列转long / 10^6
# 写入新文件
