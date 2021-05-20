import env
from enum import Enum, unique

# import parsing.core.contract as contract
# from parsing.core import contract
# import core.contract.as as as, contract
import parsing.core.contract.account_contract_pb2 as account_contract_pb2
import parsing.core.contract.asset_issue_contract_pb2 as asset_issue_contract_pb2
import parsing.core.contract.balance_contract_pb2 as balance_contract_pb2
import parsing.core.contract.exchange_contract_pb2 as exchange_contract_pb2
import parsing.core.contract.market_contract_pb2 as market_contract_pb2
import parsing.core.contract.proposal_contract_pb2 as proposal_contract_pb2
import parsing.core.contract.shield_contract_pb2 as shield_contract_pb2
import parsing.core.contract.smart_contract_pb2 as smart_contract_pb2
import parsing.core.contract.storage_contract_pb2 as storage_contract_pb2
import parsing.core.contract.vote_asset_contract_pb2 as vote_asset_contract_pb2
import parsing.core.contract.witness_contract_pb2 as witness_contract_pb2
from parsing.block import (
    BaseParser,
    ColumnIndex,
    OriginColumn,
    addressFromBytes,
    bytesRawDecode,
    bytes2HexStr,
    ownerAddressDecode,
    autoDecode,
)
import logging


env.touch()


@unique
class ContractType(Enum):
    AccountCreateContract = 0
    TransferContract = 1
    TransferAssetContract = 2
    VoteAssetContract = 3
    VoteWitnessContract = 4
    WitnessCreateContract = 5
    AssetIssueContract = 6
    WitnessUpdateContract = 8
    ParticipateAssetIssueContract = 9
    AccountUpdateContract = 10
    FreezeBalanceContract = 11
    UnfreezeBalanceContract = 12
    WithdrawBalanceContract = 13
    UnfreezeAssetContract = 14
    UpdateAssetContract = 15
    ProposalCreateContract = 16
    ProposalApproveContract = 17
    ProposalDeleteContract = 18
    SetAccountIdContract = 19
    CustomContract = 20
    CreateSmartContract = 30
    TriggerSmartContract = 31
    GetContract = 32
    UpdateSettingContract = 33
    ExchangeCreateContract = 41
    ExchangeInjectContract = 42
    ExchangeWithdrawContract = 43
    ExchangeTransactionContract = 44
    UpdateEnergyLimitContract = 45
    AccountPermissionUpdateContract = 46
    ClearABIContract = 48
    UpdateBrokerageContract = 49
    ShieldedTransferContract = 51
    MarketSellAssetContract = 52
    MarketCancelOrderContract = 53


contractTypeMap = {
    ContractType.AccountCreateContract.value: account_contract_pb2.AccountCreateContract,
    ContractType.TransferContract.value: balance_contract_pb2.TransferContract,
    ContractType.TransferAssetContract.value: asset_issue_contract_pb2.TransferAssetContract,
    ContractType.VoteAssetContract.value: vote_asset_contract_pb2.VoteAssetContract,
    ContractType.VoteWitnessContract.value: witness_contract_pb2.VoteWitnessContract,
    ContractType.WitnessCreateContract.value: witness_contract_pb2.WitnessCreateContract,
    ContractType.AssetIssueContract.value: asset_issue_contract_pb2.AssetIssueContract,
    ContractType.WitnessUpdateContract.value: witness_contract_pb2.WitnessUpdateContract,
    ContractType.ParticipateAssetIssueContract.value: asset_issue_contract_pb2.ParticipateAssetIssueContract,
    ContractType.AccountUpdateContract.value: account_contract_pb2.AccountUpdateContract,
    ContractType.FreezeBalanceContract.value: balance_contract_pb2.FreezeBalanceContract,
    ContractType.UnfreezeBalanceContract.value: balance_contract_pb2.UnfreezeBalanceContract,
    ContractType.WithdrawBalanceContract.value: balance_contract_pb2.WithdrawBalanceContract,
    ContractType.UnfreezeAssetContract.value: asset_issue_contract_pb2.UnfreezeAssetContract,
    ContractType.UpdateAssetContract.value: asset_issue_contract_pb2.UpdateAssetContract,
    ContractType.ProposalCreateContract.value: proposal_contract_pb2.ProposalCreateContract,
    ContractType.ProposalApproveContract.value: proposal_contract_pb2.ProposalApproveContract,
    ContractType.ProposalDeleteContract.value: proposal_contract_pb2.ProposalDeleteContract,
    ContractType.SetAccountIdContract.value: account_contract_pb2.SetAccountIdContract,
    # ContractType.CustomContract.value: .CustomContract,
    ContractType.CreateSmartContract.value: smart_contract_pb2.CreateSmartContract,
    ContractType.TriggerSmartContract.value: smart_contract_pb2.TriggerSmartContract,
    # ContractType.GetContract.value: .GetContract,
    ContractType.UpdateSettingContract.value: smart_contract_pb2.UpdateSettingContract,
    ContractType.ExchangeCreateContract.value: exchange_contract_pb2.ExchangeCreateContract,
    ContractType.ExchangeInjectContract.value: exchange_contract_pb2.ExchangeInjectContract,
    ContractType.ExchangeWithdrawContract.value: exchange_contract_pb2.ExchangeWithdrawContract,
    ContractType.ExchangeTransactionContract.value: exchange_contract_pb2.ExchangeTransactionContract,
    ContractType.UpdateEnergyLimitContract.value: smart_contract_pb2.UpdateEnergyLimitContract,
    ContractType.AccountPermissionUpdateContract.value: account_contract_pb2.AccountPermissionUpdateContract,
    ContractType.ClearABIContract.value: smart_contract_pb2.ClearABIContract,
    ContractType.UpdateBrokerageContract.value: storage_contract_pb2.UpdateBrokerageContract,
    ContractType.ShieldedTransferContract.value: shield_contract_pb2.ShieldedTransferContract,
    ContractType.MarketSellAssetContract.value: market_contract_pb2.MarketSellAssetContract,
    ContractType.MarketCancelOrderContract.value: market_contract_pb2.MarketCancelOrderContract,
}


contractTableMap = {
    ContractType.AccountCreateContract.value: "account_create_contract",
    ContractType.TransferContract.value: "transfer_contract",
    ContractType.TransferAssetContract.value: "transfer_asset_contract",
    ContractType.VoteAssetContract.value: "vote_asset_contract",
    ContractType.VoteWitnessContract.value: "vote_witness_contract",
    ContractType.WitnessCreateContract.value: "witness_create_contract",
    ContractType.AssetIssueContract.value: "asset_issue_contract",
    ContractType.WitnessUpdateContract.value: "witness_update_contract",  # TODO: has sub table
    ContractType.ParticipateAssetIssueContract.value: "participate_asset_issue_contract",
    ContractType.AccountUpdateContract.value: "account_update_contract",
    ContractType.FreezeBalanceContract.value: "freeze_balance_contract",
    ContractType.UnfreezeBalanceContract.value: "unfreeze_balance_contract",
    ContractType.WithdrawBalanceContract.value: "withdraw_balance_contract",
    ContractType.UnfreezeAssetContract.value: "unfreeze_asset_contract",
    ContractType.UpdateAssetContract.value: "update_asset_contract",
    ContractType.ProposalCreateContract.value: "proposal_create_contract",
    ContractType.ProposalApproveContract.value: "proposal_approve_contract",
    ContractType.ProposalDeleteContract.value: "proposal_delete_contract",
    ContractType.SetAccountIdContract.value: "set_account_id_contract",
    # ContractType.CustomContract.value: .CustomContract,
    ContractType.CreateSmartContract.value: "create_smart_contract",
    ContractType.TriggerSmartContract.value: "trigger_smart_contract",
    # ContractType.GetContract.value: .GetContract,
    ContractType.UpdateSettingContract.value: "update_setting_contract",
    ContractType.ExchangeCreateContract.value: "exchange_create_contract",
    ContractType.ExchangeInjectContract.value: "exchange_inject_contract",
    ContractType.ExchangeWithdrawContract.value: "exchange_withdraw_contract",
    ContractType.ExchangeTransactionContract.value: "exchange_transaction_contract",
    ContractType.UpdateEnergyLimitContract.value: "update_energy_limit_contract",
    ContractType.AccountPermissionUpdateContract.value: "account_permission_update_contract",
    ContractType.ClearABIContract.value: "clear_abi_contract",
    ContractType.UpdateBrokerageContract.value: "update_brokerage_contract",
    ContractType.ShieldedTransferContract.value: "shielded_transfer_contract",
    ContractType.MarketSellAssetContract.value: "market_sell_asset_contract",
    ContractType.MarketCancelOrderContract.value: "market_cancel_order_contract",
}


class ContractBaseParser(BaseParser):
    colIndex = [
        ColumnIndex(name="trans_id", fromAppend=True),
        ColumnIndex(name="ret", fromAppend=True),
        ColumnIndex(name="provider", oc=OriginColumn(name="provider", colType="bytes")),
        ColumnIndex(
            name="name", oc=OriginColumn(name="ContractName", colType="bytes")
        ),  # TODO: not b2hs?
        ColumnIndex(
            name="permission_id", oc=OriginColumn(name="permission_id", colType="int32")
        ),
    ]

    def Parse(self, writer, data, appendData):
        # if self.table == "account_create_contract":
        #     print("account_create_contract: ", data)
        #     print("account_create_contract append data: ", appendData)
        self.contract.ParseFromString(data)
        super().Parse(writer, self.contract, appendData)


class AccountCreateContractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        # owner_address: "Justin_Sun"
        # account_address: "AFv\330\036\026`K\330\341\334\252\330T\204&\231\365\272\002~"
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=ownerAddressDecode),
        ),
        ColumnIndex(
            name="account_address",
            oc=OriginColumn(name="account_address", castFunc=addressFromBytes),
        ),
        # TO REVIEW:
        # >>> c.account_type
        # Traceback (most recent call last):
        # File "<stdin>", line 1, in <module>
        # AttributeError: account_type
        # >>> c.account_type
        ColumnIndex(
            name="account_type",
            oc=OriginColumn(name="account_type", colType="int"),
        ),
    ]
    table = "account_create_contract"


class TransferContractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="to_address",
            oc=OriginColumn(name="to_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="amount",
            oc=OriginColumn(name="amount", colType="int64"),
        ),
    ]
    table = "transfer_contract"


class TransferAssetContractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="asset_name",
            oc=OriginColumn(name="asset_name", colType="bytes"),  # TODO: decode or b2hs
        ),
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="to_address",
            oc=OriginColumn(name="to_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="account_type",
            oc=OriginColumn(name="account_type", colType="int"),
        ),
    ]
    table = "transfer_asset_contract"


# class VoteAssetContractParser(ContractBaseParser):
#     colIndex = ContractBaseParser.colIndex + [
#         ColumnIndex(
#             name="owner_address",
#             oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
#         ),
#         ColumnIndex(
#             name="vote_address",
#             oc=OriginColumn(name="vote_address", castFunc=addressFromBytes),
#         ),
#         ColumnIndex(
#             name="support",
#             oc=OriginColumn(name="support", colType="bool"),
#         ),
#         ColumnIndex(
#             name="count",
#             oc=OriginColumn(name="count", colType="int32"),
#         ),
#     ]
#     table = "vote_asset_contract"


# class VoteWitnessContractParser(ContractBaseParser):
#     colIndex = ContractBaseParser.colIndex + [
#         ColumnIndex(
#             name="owner_address",
#             oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
#         ),
#         ColumnIndex(
#             name="support",
#             oc=OriginColumn(name="support", colType="bool"),
#         ),
#         ColumnIndex(
#             name="vote_address",
#             oc=OriginColumn(name="vote_address", castFunc=addressFromBytes),
#         ),
#         ColumnIndex(
#             name="vote_count",
#             oc=OriginColumn(name="vote_count", colType="int"),
#         ),
#     ]
#     table = "vote_witness_contract"


class WitnessCreateContractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="url",
            oc=OriginColumn(name="url", colType="bytes"),  # TODO: b2hs or decode
        ),
    ]
    table = "witness_create_contract"


# TODO: 子表测试
class AssetIssueContractParser(ContractBaseParser):
    def __init__(self):
        self.frozenSupplyParser = FrozenSupplyParser()

    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="id",
            oc=OriginColumn(name="id", colType="string"),
        ),
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="name_",
            oc=OriginColumn(name="name", castFunc=bytesRawDecode),
        ),
        ColumnIndex(
            name="abbr",
            oc=OriginColumn(name="abbr", castFunc=bytesRawDecode),
        ),
        ColumnIndex(
            name="total_supply",
            oc=OriginColumn(name="total_supply", colType="int64"),
        ),
        ColumnIndex(
            name="trx_num",
            oc=OriginColumn(name="trx_num", colType="int32"),
        ),
        ColumnIndex(
            name="precision",
            oc=OriginColumn(name="precision", colType="int32"),
        ),
        ColumnIndex(
            name="num",
            oc=OriginColumn(name="num", colType="int32"),
        ),
        ColumnIndex(
            name="start_time",
            oc=OriginColumn(name="start_time", colType="int64"),
        ),
        ColumnIndex(
            name="end_time",
            oc=OriginColumn(name="end_time", colType="int64"),
        ),
        ColumnIndex(
            name="order_",
            oc=OriginColumn(name="order", colType="int64"),
        ),
        ColumnIndex(
            name="vote_score",
            oc=OriginColumn(name="account_address", colType="int32"),
        ),
        ColumnIndex(
            name="description",
            oc=OriginColumn(name="description", castFunc=autoDecode),
        ),
        ColumnIndex(
            name="url",
            oc=OriginColumn(name="url", castFunc=bytesRawDecode),
        ),
        ColumnIndex(
            name="free_asset_net_limit",
            oc=OriginColumn(name="free_asset_net_limit", colType="int64"),
        ),
        ColumnIndex(
            name="public_free_asset_net_limit",
            oc=OriginColumn(name="public_free_asset_net_limit", colType="int64"),
        ),
        ColumnIndex(
            name="public_free_asset_net_usage",
            oc=OriginColumn(name="public_free_asset_net_usage", colType="int64"),
        ),
        ColumnIndex(
            name="public_latest_free_net_time",
            oc=OriginColumn(name="public_latest_free_net_time", colType="int64"),
        ),
    ]
    table = "asset_issue_contract"

    def Parse(self, writer, data, appendData):
        super().Parse(writer, data, appendData)  # TODO: super 的table是不是空的？
        frozenAppend = {"trans_id": appendData["trans_id"]}
        for f in self.contract.frozen_supply:
            self.frozenSupplyParser.Parse(writer, data, frozenAppend)


class FrozenSupplyParser(ContractBaseParser):
    def __init__(self):
        self.contract = asset_issue_contract_pb2.AssetIssueContract()

    table = "asset_issue_contract_frozen_supply"
    colIndex = [
        ColumnIndex(
            name="trans_id",
            fromAppend=True,
        ),
        ColumnIndex(
            name="frozen_amount",
            oc=OriginColumn(name="frozen_amount", colType="int64"),
        ),
        ColumnIndex(
            name="frozen_days",
            oc=OriginColumn(name="frozen_days", colType="int64"),
        ),
    ]


class witness_update_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="update_url",
            oc=OriginColumn(name="update_url"),  # TODO: b2hs or decode
        ),
    ]
    table = "witness_update_contract"


class participate_asset_issue_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="to_address",
            oc=OriginColumn(name="to_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="asset_name",
            oc=OriginColumn(name="asset_name"),  # TODO: b2hs or decode
        ),
        ColumnIndex(
            name="amount",
            oc=OriginColumn(name="amount", colType="int64"),
        ),
    ]
    table = "participate_asset_issue_contract"


class account_update_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="account_name",
            oc=OriginColumn(name="account_name"),  # TODO: b2hs?
        ),
    ]
    table = "account_update_contract"


class freeze_balance_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="frozen_balance",
            oc=OriginColumn(name="frozen_balance", colType="int64"),
        ),
        ColumnIndex(
            name="frozen_duration",
            oc=OriginColumn(name="frozen_duration", colType="int64"),
        ),
        ColumnIndex(
            name="resource",
            oc=OriginColumn(name="resource", colType="int"),
        ),
        ColumnIndex(
            name="receiver_address",
            oc=OriginColumn(name="receiver_address", castFunc=addressFromBytes),
        ),
    ]
    table = "freeze_balance_contract"


class unfreeze_balance_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="resource",
            oc=OriginColumn(name="resource", colType="int"),
        ),
        ColumnIndex(
            name="receiver_address",
            oc=OriginColumn(name="receiver_address", castFunc=addressFromBytes),
        ),
    ]
    table = "unfreeze_balance_contract"


class withdraw_balance_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
    ]
    table = "withdraw_balance_contract"


class unfreeze_asset_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="account_address",
            oc=OriginColumn(name="account_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="account_type",
            oc=OriginColumn(name="account_type", colType="int"),
        ),
    ]
    table = "unfreeze_asset_contract"


class update_asset_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="description",
            oc=OriginColumn(name="description"),  # TODO: b2hs or decode
        ),
        ColumnIndex(
            name="url",
            oc=OriginColumn(name="url"),  # TODO: b2hs or decode
        ),
        ColumnIndex(
            name="new_limit",
            oc=OriginColumn(name="new_limit", colType="int64"),
        ),
        ColumnIndex(
            name="new_public_limit",
            oc=OriginColumn(name="new_public_limit", colType="int64"),
        ),
    ]
    table = "update_asset_contract"


class proposal_approve_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="proposal_id",
            oc=OriginColumn(name="proposal_id", colType="int64"),
        ),
        ColumnIndex(
            name="is_add_approval",
            oc=OriginColumn(name="is_add_approval", colType="int64"),
        ),
    ]
    table = "proposal_approve_contract"


class proposal_delete_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="proposal_id",
            oc=OriginColumn(name="account_address", colType="int64"),
        ),
    ]
    table = "proposal_delete_contract"


class set_account_id_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="account_id",
            oc=OriginColumn(name="account_address"),
        ),
    ]
    table = "set_account_id_contract"


#  TODO:
# class create_smart_contractParser(ContractBaseParser):
#     colIndex = ContractBaseParser.colIndex + [
#         ColumnIndex(
#             name="owner_address",
#             oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
#         ),
#         ColumnIndex(
#             name="account_address",
#             oc=OriginColumn(name="account_address", castFunc=addressFromBytes),
#         ),
#         ColumnIndex(
#             name="account_type",
#             oc=OriginColumn(name="account_type", colType="int"),
#         ),
#     ]
#     table = "create_smart_contract"


class trigger_smart_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="contract_address",
            oc=OriginColumn(name="account_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="call_value",
            oc=OriginColumn(name="call_value", colType="int64"),
        ),
        ColumnIndex(
            name="data",
            oc=OriginColumn(name="data", colType="bytes"),
        ),
        ColumnIndex(
            name="call_token_value",
            oc=OriginColumn(name="call_token_value", colType="int64"),
        ),
        ColumnIndex(
            name="token_id",
            oc=OriginColumn(name="token_id", colType="int64"),
        ),
    ]
    table = "trigger_smart_contract"


class update_setting_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="contract_address",
            oc=OriginColumn(name="contract_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="consume_user_resource_percent",
            oc=OriginColumn(name="consume_user_resource_percent", colType="int64"),
        ),
    ]
    table = "update_setting_contract"


class exchange_create_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="first_token_id",
            oc=OriginColumn(name="first_token_id"),  # TODO:type
        ),
        ColumnIndex(
            name="first_token_balance",
            oc=OriginColumn(name="first_token_balance", colType="int64"),
        ),
        ColumnIndex(
            name="second_token_id",
            oc=OriginColumn(name="second_token_id"),  # TODO:type
        ),
        ColumnIndex(
            name="second_token_balance",
            oc=OriginColumn(name="second_token_balance", colType="int64"),
        ),
    ]
    table = "exchange_create_contract"


class exchange_inject_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="exchange_id",
            oc=OriginColumn(name="exchange_id", colType="int64"),
        ),
        ColumnIndex(
            name="token_id",
            oc=OriginColumn(name="token_id"),  # TODO:type
        ),
        ColumnIndex(
            name="quant",
            oc=OriginColumn(name="quant", colType="int64"),
        ),
    ]
    table = "exchange_inject_contract"


class exchange_withdraw_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="exchange_id",
            oc=OriginColumn(name="exchange_id", colType="int64"),
        ),
        ColumnIndex(
            name="token_id",
            oc=OriginColumn(name="token_id"),  # TODO:type
        ),
        ColumnIndex(
            name="quant",
            oc=OriginColumn(name="quant", colType="int64"),
        ),
    ]
    table = "exchange_withdraw_contract"


class exchange_transaction_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="exchange_id",
            oc=OriginColumn(name="exchange_id", colType="int64"),
        ),
        ColumnIndex(
            name="token_id",
            oc=OriginColumn(name="token_id"),  # TODO:type
        ),
        ColumnIndex(
            name="quant",
            oc=OriginColumn(name="quant", colType="int64"),
        ),
        ColumnIndex(
            name="expected",
            oc=OriginColumn(name="expected", colType="int64"),
        ),
    ]
    table = "exchange_transaction_contract"


class update_energy_limit_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="contract_address",
            oc=OriginColumn(name="contract_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="origin_energy_limit",
            oc=OriginColumn(name="origin_energy_limit", colType="int64"),
        ),
    ]
    table = "update_energy_limit_contract"


class clear_abi_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="contract_address",
            oc=OriginColumn(name="contract_address", castFunc=addressFromBytes),
        ),
    ]
    table = "clear_abi_contract"


class update_brokerage_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="brokerage",
            oc=OriginColumn(name="brokerage", colType="int32"),
        ),
    ]
    table = "update_brokerage_contract"


class market_sell_asset_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="sell_token_id",
            oc=OriginColumn(name="sell_token_id"),  # TODO:type
        ),
        ColumnIndex(
            name="sell_token_quantity",
            oc=OriginColumn(name="sell_token_quantity", colType="int64"),
        ),
        ColumnIndex(
            name="buy_token_id",
            oc=OriginColumn(name="buy_token_id"),  # TODO:type
        ),
        ColumnIndex(
            name="buy_token_quantity",
            oc=OriginColumn(name="buy_token_quantity", colType="int64"),
        ),
    ]
    table = "market_sell_asset_contract"


class market_cancel_order_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="order_id",
            oc=OriginColumn(name="order_id"),  # TODO:type
        ),
    ]
    table = "market_cancel_order_contract"


def getContract(contractType):
    return contractTypeMap[contractType]()


def getContractParser(contractType):
    return contractParserMap[contractType]


# TODO: **kwargs
class ContractRawParser(BaseParser):
    colIndex = [
        ColumnIndex(name="trans_id", fromAppend=True),
        ColumnIndex(name="ret", fromAppend=True),
        ColumnIndex(
            name="bytes_hex",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
    ]

    def __init__(self, table):
        self.table = table

    def Parse(self, writer, data, appendData):
        if len(self.colIndex) == 0 or self.table is None:
            logging.error("请勿直接调用抽象类方法，请实例化类并未对象变量赋值")
            # raise
            return False

        vals = []
        for col in self.colIndex:
            if col.FromAppend:
                vals.append(appendData[col.name])
        vals.append(bytes2HexStr(data))  # TODO:how to decode
        self.Write(writer, vals)


bytes_hex_contracts = [
    "vote_asset_contract",
    "vote_witness_contract",
    "shielded_transfer_contract",
    "account_permission_update_contract",
    "proposal_create_contract",
]


contractParserMap = {
    ContractType.AccountCreateContract.value: AccountCreateContractParser(),
    ContractType.TransferContract.value: TransferContractParser(),
    ContractType.TransferAssetContract.value: TransferAssetContractParser(),
    ContractType.VoteAssetContract.value: ContractRawParser("vote_asset_contract"),
    ContractType.VoteWitnessContract.value: ContractRawParser("vote_witness_contract"),
    ContractType.WitnessCreateContract.value: WitnessCreateContractParser(),
    ContractType.AssetIssueContract.value: AssetIssueContractParser(),  # TODO: has sub table
    ContractType.WitnessUpdateContract.value: witness_update_contractParser(),  # TODO: has sub table
    ContractType.ParticipateAssetIssueContract.value: participate_asset_issue_contractParser(),
    ContractType.AccountUpdateContract.value: account_update_contractParser(),
    ContractType.FreezeBalanceContract.value: freeze_balance_contractParser(),
    ContractType.UnfreezeBalanceContract.value: unfreeze_balance_contractParser(),
    ContractType.WithdrawBalanceContract.value: withdraw_balance_contractParser(),
    ContractType.UnfreezeAssetContract.value: unfreeze_asset_contractParser(),
    ContractType.UpdateAssetContract.value: update_asset_contractParser(),
    ContractType.ProposalCreateContract.value: ContractRawParser(
        "proposal_approve_contractParser"
    ),
    ContractType.ProposalApproveContract.value: proposal_approve_contractParser(),
    ContractType.ProposalDeleteContract.value: proposal_delete_contractParser(),
    ContractType.SetAccountIdContract.value: set_account_id_contractParser(),
    # ContractType.CustomContract.value: .CustomContract,
    ContractType.CreateSmartContract.value: ContractRawParser("create_smart_contract"),
    ContractType.TriggerSmartContract.value: trigger_smart_contractParser(),
    # ContractType.GetContract.value: .GetContract,
    ContractType.UpdateSettingContract.value: update_setting_contractParser(),
    ContractType.ExchangeCreateContract.value: exchange_create_contractParser(),
    ContractType.ExchangeInjectContract.value: exchange_inject_contractParser(),
    ContractType.ExchangeWithdrawContract.value: exchange_withdraw_contractParser(),
    ContractType.ExchangeTransactionContract.value: exchange_transaction_contractParser(),
    ContractType.UpdateEnergyLimitContract.value: update_energy_limit_contractParser(),
    ContractType.AccountPermissionUpdateContract.value: ContractRawParser(
        "account_permission_update_contract"
    ),
    ContractType.ClearABIContract.value: clear_abi_contractParser(),
    ContractType.UpdateBrokerageContract.value: update_brokerage_contractParser(),
    # ContractType.ShieldedTransferContract.value: ContractRawParser(),
    ContractType.MarketSellAssetContract.value: market_sell_asset_contractParser(),
    ContractType.MarketCancelOrderContract.value: market_cancel_order_contractParser(),
}


def initContractParser():
    for t, p in contractParserMap.items():
        setattr(p, "contract", getContract(t))
