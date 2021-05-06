import Tron_pb2
import json
import plyvel
from Crypto.Util.number import bytes_to_long as b2l
import binascii
import core.contract.smart_contract_pb2 as sc
from core.contract.asset_issue_contract_pb2 import TransferAssetContract as tac

# pip install pycryptodome

# binascii.hexlify(k).decode('ascii')
# bytearray.fromhex(id)
# bytes.fromhex(str)
# binascii.b2a_hex()

db = plyvel.DB("/data2/20210425/output-directory/database/trans")
blockIndexDB = plyvel.DB("/data2/20210425/output-directory/database/block-index")
blockDB = plyvel.DB("/data2/20210425/output-directory/database/block")
accountDB = plyvel.DB("/data2/20210425/output-directory/database/account")

accountIndexDB = plyvel.DB(
    "/data2/20210425/output-directory/database/account-index"
)  # account name to accountid
accountIdIndexDB = plyvel.DB(
    "/data2/20210425/output-directory/database/accountid-index"
)

transRetStore = plyvel.DB(
    "/data2/20210425/output-directory/database/transactionRetStore"
)
transRetIt = transRetStore.iterator()
# db = plyvel.DB('/data2/20210425/output-directory/database/transactionHistoryStore')
# b55d835c775067b72aad04164ce05d19d421303a21336bdf73bd933d646a9920  9000000

accountIT = accountDB.iterator()
k, v = next(accountIT)
print(k)
vs = binascii.hexlify(v)
print(vs)
acc = Tron_pb2.Account()
acc.ParseFromString(v)
acc


accountIndexIT = accountIndexDB.iterator()
k, v = next(accountIndexIT)
print(k)
vs = binascii.hexlify(v)
print(vs)


accountIdIndexIT = accountIdIndexDB.iterator()
k, v = next(accountIdIndexIT)
print(k)
vs = binascii.hexlify(v)
print(vs)

# blockIndexIT = blockIndexDB.iterator()
# k,v = next(blockIndexIT)
# k = b2l(k)
# print(k)
# vs = binascii.hexlify(v)
# print(vs)
# blk=blockDB.get(v)


blockIndexITrev = blockIndexDB.iterator(reverse=True)
k, v = next(blockIndexITrev)
k = b2l(k)
print(k)
vs = binascii.hexlify(v)
print(vs)
blk = blockDB.get(v)

blkIns = Tron_pb2.Block()
blkIns.ParseFromString(blk)
blkIns.transactions[0]

tsc = sc.TriggerSmartContract()
tsc.ParseFromString(blkIns.transactions[0].raw_data.contract[0].parameter.value)

# it = db.iterator()
with db.iterator() as it:
    k, v = next(it)
    print("k: ", k)
    print("v: ", v)
    print("k decode: ", "".join(["%02x" % b for b in k]))
    vs = Tron_pb2.Transaction()
    vs.ParseFromString(v)
    print("v: ", vs)
    print("v json:", json.dumps(vs))
    print(vs.Contract.ContractType)

    for k, v in it:
        print("k: ", k)
        print("v: ", v)
        print("k decode: ", "".join(["%02x" % b for b in k]))
        vs = Tron_pb2.Transaction()
        vs.ParseFromString(v)
        print("v: ", vs)
        print("v json:", json.dumps(vs))
        break

db.close()

# message Transaction {
#   message Contract {
#     enum ContractType {
#       AccountCreateContract = 0;
#       TransferContract = 1;
#       TransferAssetContract = 2;
#       VoteAssetContract = 3;
#       VoteWitnessContract = 4;
#       WitnessCreateContract = 5;
#       AssetIssueContract = 6;
#       WitnessUpdateContract = 8;
#       ParticipateAssetIssueContract = 9;
#       AccountUpdateContract = 10;
#       FreezeBalanceContract = 11;
#       UnfreezeBalanceContract = 12;
#       WithdrawBalanceContract = 13;
#       UnfreezeAssetContract = 14;
#       UpdateAssetContract = 15;
#       ProposalCreateContract = 16;
#       ProposalApproveContract = 17;
#       ProposalDeleteContract = 18;
#       SetAccountIdContract = 19;
#       CustomContract = 20;
#       CreateSmartContract = 30;
#       TriggerSmartContract = 31;
#       GetContract = 32;
#       UpdateSettingContract = 33;
#       ExchangeCreateContract = 41;
#       ExchangeInjectContract = 42;
#       ExchangeWithdrawContract = 43;
#       ExchangeTransactionContract = 44;
#       UpdateEnergyLimitContract = 45;
#       AccountPermissionUpdateContract = 46;
#       ClearABIContract = 48;
#       UpdateBrokerageContract = 49;
#       ShieldedTransferContract = 51;
#       MarketSellAssetContract = 52;
#       MarketCancelOrderContract = 53;
#     }
#     ContractType type = 1;
#     google.protobuf.Any parameter = 2;
#     bytes provider = 3;
#     bytes ContractName = 4;
#     int32 Permission_id = 5;
#   }

#   message Result {
#     enum code {
#       SUCESS = 0;
#       FAILED = 1;
#     }
#     enum contractResult {
#       DEFAULT = 0;
#       SUCCESS = 1;
#       REVERT = 2;
#       BAD_JUMP_DESTINATION = 3;
#       OUT_OF_MEMORY = 4;
#       PRECOMPILED_CONTRACT = 5;
#       STACK_TOO_SMALL = 6;
#       STACK_TOO_LARGE = 7;
#       ILLEGAL_OPERATION = 8;
#       STACK_OVERFLOW = 9;
#       OUT_OF_ENERGY = 10;
#       OUT_OF_TIME = 11;
#       JVM_STACK_OVER_FLOW = 12;
#       UNKNOWN = 13;
#       TRANSFER_FAILED = 14;
#     }
#     int64 fee = 1;
#     code ret = 2;
#     contractResult contractRet = 3;

#     string assetIssueID = 14;
#     int64 withdraw_amount = 15;
#     int64 unfreeze_amount = 16;
#     int64 exchange_received_amount = 18;
#     int64 exchange_inject_another_amount = 19;
#     int64 exchange_withdraw_another_amount = 20;
#     int64 exchange_id = 21;
#     int64 shielded_transaction_fee = 22;


#     bytes orderId = 25;
#     repeated MarketOrderDetail orderDetails = 26;
#   }

#   message raw {
#     bytes ref_block_bytes = 1;
#     int64 ref_block_num = 3;
#     bytes ref_block_hash = 4;
#     int64 expiration = 8;
#     repeated authority auths = 9;
#     // data not used
#     bytes data = 10;
#     //only support size = 1,  repeated list here for extension
#     repeated Contract contract = 11;
#     // scripts not used
#     bytes scripts = 12;
#     int64 timestamp = 14;
#     int64 fee_limit = 18;
#   }

#   raw raw_data = 1;
#   // only support size = 1,  repeated list here for muti-sig extension
#   repeated bytes signature = 2;
#   repeated Result ret = 5;
# }
