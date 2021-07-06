import requests
import json
import pandas as pd
import numpy as np
import csv

np.set_printoptions(suppress=True)
pd.set_option("display.float_format", lambda x: "%.6f" % x)

baseUrl = "https://apilist.tronscan.org/api/token_trc20"
HEADER = {"Content-Type": "application/json; charset=utf-8"}


def getTrc20Token(limit, f_name):
    token_list = []
    while True:
        url = "{}?limit={}&start={}".format(baseUrl, limit, len(token_list))
        rsp = requests.get(url, headers=HEADER)
        if rsp.status_code == 200:
            rspJson = json.loads(rsp.text.encode())
            trc20_tokens = rspJson.get("trc20_tokens")
            # print("trc20_tokens: ", trc20_tokens)
            token_list.extend(trc20_tokens)
            if len(trc20_tokens) != limit:
                print(
                    "unexpected res count: {}, limit: {}, start: {}".format(
                        len(trc20_tokens), limit, len(token_list)
                    )
                )
            # if len(token_list) >= rspJson.get("rangeTotal") or len(token_list) > 1000:
            if len(token_list) >= rspJson.get("rangeTotal"):
                break
        else:
            print("failed: ", rsp)
            return False

    with open("{}.json".format(f_name), "w") as f:
        json.dump(token_list, f, indent=4, ensure_ascii=False)
    return True


def json2csv(f_name):
    df = pd.read_json("{}.json".format(f_name), dtype="object")
    df.drop(["social_media_list", "market_info"], axis=1, inplace=True)
    df.to_csv("{}.csv".format(f_name), quoting=csv.QUOTE_NONNUMERIC, quotechar='"')
    # TODO:
    # 1. 不使用科学计数，发行量列


if "__main__" == __name__:

    # limit = 50
    f_name = "trc20_tokens"
    # ret = getTrc20Token(limit, f_name)
    # if ret:
    #     json2csv(f_name)

    json2csv(f_name)


# TODO:
# check tail len
