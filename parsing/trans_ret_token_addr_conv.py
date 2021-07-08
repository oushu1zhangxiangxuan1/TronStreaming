# -*- encoding:"utf-8"-*-
import env
import sys
import csv
import datetime

# from Crypto.Util.number import bytes_to_long as b2l
from parsing.base import addressFromBytes

env.touch()

hex_file = "trans_ret_log_token_address.csv"

base58_file = "trans_ret_log_token_address_conv.csv"

total = 80307

# hex_file = "usdt_head.csv"

# base58_file = "usdt_conv.csv"


def main():
    start = datetime.datetime.now()
    i = 0
    with open(hex_file) as rf:
        r_csv = csv.reader(rf)
        with open(base58_file, "w") as wf:
            w_csv = csv.writer(wf)
            conv_start = datetime.datetime.now()
            read_time = (conv_start - start).total_seconds()
            print("读取耗时 {} 微秒, {} 秒".format(read_time * 10 ** 6, read_time))
            for rline in r_csv:
                # print("src data: ", rline)
                rline.append(addressFromBytes(bytes.fromhex("41" + rline[0])))
                # print("dst data: ", rline)
                w_csv.writerow(rline)
                i += 1
                if i % 100000 == 0:
                    wf.flush()
                    end = datetime.datetime.now()
                    conv_time = (end - conv_start).total_seconds()
                    print(
                        "解析 {} 条 总耗时 {} 微秒, {} 秒".format(
                            i, conv_time * 10 ** 6, conv_time
                        )
                    )
                    print(
                        "单条耗时 {} 微秒, 解析 {} 条预计耗时 {} 秒, {} 分钟".format(
                            conv_time * 10 ** 6 / i,
                            total,
                            (conv_time / i) * total,
                            (conv_time / i) * total / 60,
                        )
                    )
                # if i == 10:
                #     break
            wf.flush()

    end = datetime.datetime.now()
    conv_time = (end - conv_start).total_seconds()
    print("解析 {} 条 总耗时 {} 微秒, {} 秒".format(total, conv_time * 10 ** 6, conv_time))
    print(
        "单条耗时 {} 微秒, 解析 {} 条预计耗时 {} 秒, {} 分钟".format(
            conv_time * 10 ** 6 / total,
            total,
            (conv_time / total) * total,
            (conv_time / total) * total / 60,
        )
    )


if "__main__" == __name__:
    # if len(sys.argv) < 3:
    #     print("Please set input csv path")
    #     exit(-1)
    # hex_file = sys.argv[1]
    # base58_file = sys.argv[2]
    main()

# 读csv
# 将第3，4列转address
# 第5列转long / 10^6
# 写入新文件
