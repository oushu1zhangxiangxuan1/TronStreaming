from tronapi import Tron
from tronapi import HttpProvider
import json

full_node = HttpProvider("https://api.trongrid.io")
solidity_node = HttpProvider("https://api.trongrid.io")
event_server = HttpProvider("https://api.trongrid.io")

tron = Tron(full_node=full_node, solidity_node=solidity_node, event_server=event_server)
tron.default_block = "latest"

print(tron.trx.get_block("latest")["block_header"]["raw_data"]["number"])
# print(tron.trx.get_block(15540602))
# print(tron.trx.get_block(12345678))
# print(len(tron.trx.get_block(10543367)["transactions"]))

# print(json.dumps(tron.trx.get_block(99999)))

# with open("./99999.json", "w") as f:
#     json.dump(tron.trx.get_block(99999), f)
