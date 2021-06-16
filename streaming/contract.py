import env
from enum import Enum, unique

from streaming.base import (
    BaseParser,
    ColumnIndex,
    OriginColumn,
    addressFromBytes,
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


contractTableMap = {
    ContractType.AccountCreateContract.value: "account_create_contract",
    ContractType.TransferContract.value: "transfer_contract",
    ContractType.TransferAssetContract.value: "transfer_asset_contract",
    ContractType.VoteAssetContract.value: "vote_asset_contract",
    ContractType.VoteWitnessContract.value: "vote_witness_contract",
    ContractType.WitnessCreateContract.value: "witness_create_contract",
    ContractType.AssetIssueContract.value: "asset_issue_contract",
    ContractType.WitnessUpdateContract.value: "witness_update_contract",
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
        ColumnIndex(
            name="provider",
            oc=OriginColumn(name="provider", colType="bytes", castFunc=autoDecode),
        ),
        ColumnIndex(
            name="name",
            oc=OriginColumn(name="ContractName", colType="bytes", castFunc=autoDecode),
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
        return super().Parse(writer, self.contract, appendData)


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
    table = "realtime_account_create_contract"


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
    table = "realtime_transfer_contract"


class TransferAssetContractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="asset_name",
            oc=OriginColumn(name="asset_name", castFunc=autoDecode),
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
            name="amount",
            oc=OriginColumn(name="amount", colType="int"),
        ),
    ]
    table = "realtime_transfer_asset_contract"


class WitnessCreateContractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="url",
            oc=OriginColumn(name="url", castFunc=autoDecode),
        ),
    ]
    table = "realtime_witness_create_contract"


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
            oc=OriginColumn(name="name", castFunc=autoDecode),
        ),
        ColumnIndex(
            name="abbr",
            oc=OriginColumn(name="abbr", castFunc=autoDecode),
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
            oc=OriginColumn(name="url", castFunc=autoDecode),
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
    table = "realtime_asset_issue_contract"

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            return False
        frozenAppend = {"trans_id": appendData["trans_id"]}
        for f in self.contract.frozen_supply:
            ret = self.frozenSupplyParser.Parse(writer, data, frozenAppend)
            if not ret:
                return False
        return True


class FrozenSupplyParser(ContractBaseParser):
    table = "realtime_asset_issue_contract_frozen_supply"
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
            oc=OriginColumn(name="update_url", castFunc=autoDecode),
        ),
    ]
    table = "realtime_witness_update_contract"


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
            oc=OriginColumn(name="asset_name", castFunc=autoDecode),
        ),
        ColumnIndex(
            name="amount",
            oc=OriginColumn(name="amount", colType="int64"),
        ),
    ]
    table = "realtime_participate_asset_issue_contract"


class account_update_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="account_name",
            oc=OriginColumn(name="account_name", castFunc=autoDecode),
        ),
    ]
    table = "realtime_account_update_contract"


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
    table = "realtime_freeze_balance_contract"


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
    table = "realtime_unfreeze_balance_contract"


class withdraw_balance_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
    ]
    table = "realtime_withdraw_balance_contract"


class unfreeze_asset_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
    ]
    table = "realtime_unfreeze_asset_contract"


class update_asset_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="description",
            oc=OriginColumn(name="description", castFunc=autoDecode),
        ),
        ColumnIndex(
            name="url",
            oc=OriginColumn(name="url", castFunc=autoDecode),
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
    table = "realtime_update_asset_contract"


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
    table = "realtime_proposal_approve_contract"


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
    table = "realtime_proposal_delete_contract"


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
    table = "realtime_set_account_id_contract"


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
    table = "realtime_trigger_smart_contract"


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
    table = "realtime_update_setting_contract"


class exchange_create_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="first_token_id",
            oc=OriginColumn(name="first_token_id", castFunc=autoDecode),  # TODO:type
        ),
        ColumnIndex(
            name="first_token_balance",
            oc=OriginColumn(name="first_token_balance", colType="int64"),
        ),
        ColumnIndex(
            name="second_token_id",
            oc=OriginColumn(name="second_token_id", castFunc=autoDecode),  # TODO:type
        ),
        ColumnIndex(
            name="second_token_balance",
            oc=OriginColumn(name="second_token_balance", colType="int64"),
        ),
    ]
    table = "realtime_exchange_create_contract"


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
            oc=OriginColumn(name="token_id", castFunc=autoDecode),  # TODO:type
        ),
        ColumnIndex(
            name="quant",
            oc=OriginColumn(name="quant", colType="int64"),
        ),
    ]
    table = "realtime_exchange_inject_contract"


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
            oc=OriginColumn(name="token_id", castFunc=autoDecode),  # TODO:type
        ),
        ColumnIndex(
            name="quant",
            oc=OriginColumn(name="quant", colType="int64"),
        ),
    ]
    table = "realtime_exchange_withdraw_contract"


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
            oc=OriginColumn(name="token_id", castFunc=autoDecode),
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
    table = "realtime_exchange_transaction_contract"


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
    table = "realtime_update_energy_limit_contract"


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
    table = "realtime_clear_abi_contract"


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
    table = "realtime_update_brokerage_contract"


class market_sell_asset_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="sell_token_id",
            oc=OriginColumn(name="sell_token_id", castFunc=autoDecode),  # TODO:type
        ),
        ColumnIndex(
            name="sell_token_quantity",
            oc=OriginColumn(name="sell_token_quantity", colType="int64"),
        ),
        ColumnIndex(
            name="buy_token_id",
            oc=OriginColumn(name="buy_token_id", castFunc=autoDecode),  # TODO:type
        ),
        ColumnIndex(
            name="buy_token_quantity",
            oc=OriginColumn(name="buy_token_quantity", colType="int64"),
        ),
    ]
    table = "realtime_market_sell_asset_contract"


class market_cancel_order_contractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="order_id",
            oc=OriginColumn(name="order_id", castFunc=autoDecode),  # TODO:type
        ),
    ]
    table = "realtime_market_cancel_order_contract"


def getContractParser(contractType):
    return contractParserMap[contractType]


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
        return True


class ContractBaseParser(BaseParser):
    colIndex = [
        ColumnIndex(name="trans_id", fromAppend=True),
        ColumnIndex(name="ret", fromAppend=True),
        ColumnIndex(
            name="provider",
            oc=OriginColumn(name="provider", colType="bytes", castFunc=autoDecode),
        ),
        ColumnIndex(
            name="name",
            oc=OriginColumn(name="ContractName", colType="bytes", castFunc=autoDecode),
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
        return super().Parse(writer, self.contract, appendData)


class VoteAssetContractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        # ColumnIndex(
        #     name="vote_address",
        #     oc=OriginColumn(name="vote_address", castFunc=addressFromBytes),
        # ),
        ColumnIndex(
            name="support",
            oc=OriginColumn(name="support", colType="bool"),
        ),
        ColumnIndex(
            name="count",
            oc=OriginColumn(name="count", colType="int32"),
        ),
    ]
    table = "realtime_vote_asset_contract"

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            return False

        for addr in self.contract.vote_address:
            addr = addressFromBytes(addr)
            writer.write(
                "vote_asset_contract_vote_address", [appendData["trans_id"], addr]
            )
        return True


class VoteWitnessContractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="support",
            oc=OriginColumn(name="support", colType="bool"),
        ),
    ]
    table = "realtime_vote_witness_contract"

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            return False

        for vote in self.contract.votes:
            addr = addressFromBytes(vote.vote_address)
            writer.write(
                "vote_witness_contract_votes",
                [appendData["trans_id"], addr, vote.vote_count],
            )
        return True


class ProposalCreateContractParser(ContractBaseParser):
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
    ]
    table = "realtime_proposal_create_contract"

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            return False

        # 遍历parameters
        for key in self.contract.parameters:
            value = self.contract.parameters[key]
            writer.write(
                "proposal_create_contract_parameters",
                [appendData["trans_id"], key, value],
            )
        return True


def _newContractWrapper(oc):
    return OriginColumn(name="new_contract", oc=oc)


class create_smart_contractParser(ContractBaseParser):
    def __init__(self):
        self.abiParser = create_smart_contract_abi_Parser()

    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="call_token_value",
            oc=OriginColumn(name="call_token_value", colType="int64"),
        ),
        ColumnIndex(
            name="token_id",
            oc=OriginColumn(name="token_id", colType="int64"),
        ),
        ColumnIndex(
            name="origin_address",
            oc=_newContractWrapper(
                OriginColumn(name="origin_address", castFunc=addressFromBytes)
            ),
        ),
        ColumnIndex(
            name="contract_address",
            oc=_newContractWrapper(
                OriginColumn(name="contract_address", castFunc=addressFromBytes)
            ),
        ),
        ColumnIndex(
            name="bytecode",
            oc=_newContractWrapper(
                OriginColumn(name="bytecode", castFunc=bytes2HexStr)
            ),
        ),
        ColumnIndex(
            name="call_value",
            oc=_newContractWrapper(OriginColumn(name="call_value", colType="int64")),
        ),
        ColumnIndex(
            name="consume_user_resource_percent",
            oc=_newContractWrapper(
                OriginColumn(name="consume_user_resource_percent", colType="int64")
            ),
        ),
        ColumnIndex(
            name="name",
            oc=_newContractWrapper(OriginColumn(name="name", colType="string")),
        ),
        ColumnIndex(
            name="origin_energy_limit",
            oc=_newContractWrapper(
                OriginColumn(name="origin_energy_limit", colType="int64")
            ),
        ),
        ColumnIndex(
            name="code_hash",
            oc=_newContractWrapper(OriginColumn(name="code_hash")),
        ),
        ColumnIndex(
            name="trx_hash",
            oc=_newContractWrapper(OriginColumn(name="trx_hash")),
        ),
    ]

    table = "realtime_create_smart_contract"

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            return False
        # logging.info("create smart contract: ", self.contract)
        for i, entry in enumerate(self.contract.new_contract.abi.entrys):
            appendData["entry_id"] = i
            ret = self.abiParser.Parse(writer, entry, appendData)
            if not ret:
                return False
        return True


class create_smart_contract_abi_Parser(BaseParser):
    colIndex = [
        ColumnIndex(
            name="trans_id",
            fromAppend=True,
        ),
        ColumnIndex(
            name="anonymous",
            oc=OriginColumn(name="anonymous", colType="bool"),
        ),
        ColumnIndex(
            name="constant",
            oc=OriginColumn(name="constant", colType="bool"),
        ),
        ColumnIndex(
            name="name",
            oc=OriginColumn(name="name", colType="string"),
        ),
        ColumnIndex(
            name="type",
            oc=OriginColumn(name="type", colType="int"),
        ),
        ColumnIndex(
            name="payable",
            oc=OriginColumn(name="payable", colType="bool"),
        ),
        ColumnIndex(
            name="state_mutability",
            oc=OriginColumn(name="stateMutability", colType="int"),
        ),
    ]

    table = "realtime_create_smart_contract_abi"

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            return False

        # 遍历parameters
        for param in data.inputs:
            writer.write(
                "create_smart_contract_abi_inputs",
                [
                    appendData["trans_id"],
                    appendData["entry_id"],
                    param.indexed,
                    param.name,
                    param.type,
                ],
            )
        for param in data.outputs:
            writer.write(
                "create_smart_contract_abi_outputs",
                [
                    appendData["trans_id"],
                    appendData["entry_id"],
                    param.indexed,
                    param.name,
                    param.type,
                ],
            )
        return True


def _ownerWrapper(oc):
    return OriginColumn(name="owner", oc=oc)


def _witnessWrapper(oc):
    return OriginColumn(name="witness", oc=oc)


class account_permission_update_contract_Parser(ContractBaseParser):
    def __init__(self):
        self.permissionParser = PermissionParser()

    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="owner_address",
            oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="owner_permission_type",
            oc=_ownerWrapper(OriginColumn(name="type", colType="int")),
        ),
        ColumnIndex(
            name="owner_permission_id",
            oc=_ownerWrapper(OriginColumn(name="id", colType="int")),
        ),
        ColumnIndex(
            name="owner_permission_name",
            oc=_ownerWrapper(OriginColumn(name="permission_name", colType="string")),
        ),
        ColumnIndex(
            name="owner_permission_threshold",
            oc=_ownerWrapper(OriginColumn(name="threshold", colType="int64")),
        ),
        ColumnIndex(
            name="owner_permission_parent_id",
            oc=_ownerWrapper(OriginColumn(name="parent_id", colType="int32")),
        ),
        ColumnIndex(
            name="owner_permission_operations",
            oc=_ownerWrapper(
                OriginColumn(name="operations", colType="bytes")
            ),  # TODO: check how to decode
        ),
        ColumnIndex(
            name="witness_permission_type",
            oc=_witnessWrapper(OriginColumn(name="type", colType="int")),
        ),
        ColumnIndex(
            name="witness_permission_id",
            oc=_witnessWrapper(OriginColumn(name="id", colType="int")),
        ),
        ColumnIndex(
            name="witness_permission_name",
            oc=_witnessWrapper(OriginColumn(name="permission_name", colType="string")),
        ),
        ColumnIndex(
            name="witness_permission_threshold",
            oc=_witnessWrapper(OriginColumn(name="threshold", colType="int64")),
        ),
        ColumnIndex(
            name="witness_permission_parent_id",
            oc=_witnessWrapper(OriginColumn(name="parent_id", colType="int32")),
        ),
        ColumnIndex(
            name="witness_permission_operations",
            oc=_witnessWrapper(
                OriginColumn(name="operations", colType="bytes")
            ),  # TODO: check how to decode
        ),
    ]

    table = "realtime_account_permission_update_contract"

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            return False

        for i, active in enumerate(self.contract.actives):
            appendData["active_index"] = i
            ret = self.permissionParser.Parse(writer, active, appendData)
            if not ret:
                return False

        for i, key in enumerate(self.contract.owner.keys):
            writer.write(
                "account_permission_update_contract_keys",
                [
                    appendData["trans_id"],
                    -1,
                    i,
                    addressFromBytes(key.address),  # TODO:check how to decode
                    bytes2HexStr(key.address),
                    key.weight,
                ],
            )
        for i, key in enumerate(self.contract.owner.keys):
            writer.write(
                "account_permission_update_contract_keys",
                [
                    appendData["trans_id"],
                    0,
                    i,
                    addressFromBytes(key.address),  # TODO:check how to decode
                    bytes2HexStr(key.address),
                    key.weight,
                ],
            )
        return True


class PermissionParser(BaseParser):
    colIndex = [
        ColumnIndex(
            name="trans_id",
            fromAppend=True,
        ),
        ColumnIndex(
            name="active_index",
            fromAppend=True,
        ),
        ColumnIndex(
            name="permission_type",
            oc=OriginColumn(name="type", colType="int"),
        ),
        ColumnIndex(
            name="id",
            oc=OriginColumn(name="id", colType="int"),
        ),
        ColumnIndex(
            name="permission_name",
            oc=OriginColumn(name="permission_name", colType="string"),
        ),
        ColumnIndex(
            name="threshold",
            oc=OriginColumn(name="threshold", colType="int64"),
        ),
        ColumnIndex(
            name="parent_id",
            oc=OriginColumn(name="parent_id", colType="int32"),
        ),
        ColumnIndex(
            name="operations",
            oc=OriginColumn(
                name="operations", colType="bytes"
            ),  # TODO: check how to decode
        ),
    ]
    table = "realtime_account_permission_update_contract_actives"

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            return False
        for i, key in enumerate(data.keys):
            writer.write(
                "account_permission_update_contract_keys",
                [
                    appendData["trans_id"],
                    appendData["active_index"],
                    i,
                    addressFromBytes(key.address),  # TODO:check how to decode
                    bytes2HexStr(key.address),
                    key.weight,
                ],
            )
        return True


def _spendDesWrapper(oc):
    return OriginColumn(name="spend_description", oc=oc)


def _receiveDesWrapper(oc):
    return OriginColumn(name="receive_description", oc=oc)


class shiled_transfer_contract_Parser(BaseParser):
    # TODO: how to decode bytes data
    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="transparent_from_address",
            oc=OriginColumn(
                name="transparent_from_address", castFunc=addressFromBytes
            ),  # TODO: how to decode
        ),
        ColumnIndex(
            name="from_amount",
            oc=OriginColumn(name="from_amount", colType="int64"),
        ),
        ColumnIndex(
            name="binding_signature",
            oc=OriginColumn(name="binding_signature", colType=autoDecode),
        ),
        ColumnIndex(
            name="transparent_to_address",
            oc=OriginColumn(name="transparent_to_address", colType=autoDecode),
        ),
        ColumnIndex(
            name="to_amount",
            oc=OriginColumn(name="to_amount", colType="int64"),
        ),
        #
        # spend_description_value_commitment text,
        # spend_description_anchor text,
        # spend_description_nullifier text,
        # spend_description_rk text,
        # spend_description_zkproof text,
        # spend_description_spend_authority_signature text,
        ColumnIndex(
            name="spend_description_value_commitment",
            oc=_spendDesWrapper(OriginColumn(name="value_commitment")),
        ),
        ColumnIndex(
            name="spend_description_anchor",
            oc=_spendDesWrapper(
                OriginColumn(name="anchor", colType="bytes")
            ),  # TODO: check how to decode
        ),
        ColumnIndex(
            name="spend_description_nullifier",
            oc=_spendDesWrapper(OriginColumn(name="nullifier", colType="int")),
        ),
        ColumnIndex(
            name="spend_description_rk",
            oc=_spendDesWrapper(OriginColumn(name="rk", colType="int")),
        ),
        ColumnIndex(
            name="spend_description_zkproof",
            oc=_spendDesWrapper(OriginColumn(name="zkproof", colType="string")),
        ),
        ColumnIndex(
            name="spend_description_spend_authority_signature",
            oc=_spendDesWrapper(
                OriginColumn(name="spend_authority_signature", colType="int64")
            ),
        ),
        #
        # receive_description_value_commitment text,
        # receive_description_note_commitment text,
        # receive_description_epk text,
        # receive_description_c_enc text,
        # receive_description_c_out text,
        # receive_description_zkproof text
        ColumnIndex(
            name="receive_description_value_commitment",
            oc=_receiveDesWrapper(OriginColumn(name="value_commitment")),
        ),
        ColumnIndex(
            name="receive_description_note_commitment",
            oc=_receiveDesWrapper(
                OriginColumn(name="note_commitment", colType="bytes")
            ),  # TODO: check how to decode
        ),
        ColumnIndex(
            name="receive_description_epk",
            oc=_receiveDesWrapper(OriginColumn(name="epk")),
        ),
        ColumnIndex(
            name="receive_description_c_enc",
            oc=_receiveDesWrapper(
                OriginColumn(name="c_enc", colType="bytes")
            ),  # TODO: check how to decode
        ),
        ColumnIndex(
            name="receive_description_c_out",
            oc=_receiveDesWrapper(OriginColumn(name="c_out")),
        ),
        ColumnIndex(
            name="receive_description_zkproof",
            oc=_receiveDesWrapper(
                OriginColumn(name="zkproof", colType="bytes")
            ),  # TODO: check how to decode
        ),
    ]

    table = "realtime_shielded_transfer_contract"


contractParserMap = {
    ContractType.AccountCreateContract.value: AccountCreateContractParser(),
    ContractType.TransferContract.value: TransferContractParser(),
    ContractType.TransferAssetContract.value: TransferAssetContractParser(),
    ContractType.VoteAssetContract.value: VoteAssetContractParser(),
    ContractType.VoteWitnessContract.value: VoteWitnessContractParser(),
    ContractType.WitnessCreateContract.value: WitnessCreateContractParser(),
    ContractType.AssetIssueContract.value: AssetIssueContractParser(),
    ContractType.WitnessUpdateContract.value: witness_update_contractParser(),
    ContractType.ParticipateAssetIssueContract.value: participate_asset_issue_contractParser(),
    ContractType.AccountUpdateContract.value: account_update_contractParser(),
    ContractType.FreezeBalanceContract.value: freeze_balance_contractParser(),
    ContractType.UnfreezeBalanceContract.value: unfreeze_balance_contractParser(),
    ContractType.WithdrawBalanceContract.value: withdraw_balance_contractParser(),
    ContractType.UnfreezeAssetContract.value: unfreeze_asset_contractParser(),
    ContractType.UpdateAssetContract.value: update_asset_contractParser(),
    ContractType.ProposalCreateContract.value: ProposalCreateContractParser(),
    ContractType.ProposalApproveContract.value: proposal_approve_contractParser(),
    ContractType.ProposalDeleteContract.value: proposal_delete_contractParser(),
    ContractType.SetAccountIdContract.value: set_account_id_contractParser(),
    # ContractType.CustomContract.value: .CustomContract,
    ContractType.CreateSmartContract.value: create_smart_contractParser(),
    ContractType.TriggerSmartContract.value: trigger_smart_contractParser(),
    # ContractType.GetContract.value: .GetContract,
    ContractType.UpdateSettingContract.value: update_setting_contractParser(),
    ContractType.ExchangeCreateContract.value: exchange_create_contractParser(),
    ContractType.ExchangeInjectContract.value: exchange_inject_contractParser(),
    ContractType.ExchangeWithdrawContract.value: exchange_withdraw_contractParser(),
    ContractType.ExchangeTransactionContract.value: exchange_transaction_contractParser(),
    ContractType.UpdateEnergyLimitContract.value: update_energy_limit_contractParser(),
    ContractType.AccountPermissionUpdateContract.value: account_permission_update_contract_Parser(),
    ContractType.ClearABIContract.value: clear_abi_contractParser(),
    ContractType.UpdateBrokerageContract.value: update_brokerage_contractParser(),
    ContractType.ShieldedTransferContract.value: shiled_transfer_contract_Parser(),
    ContractType.MarketSellAssetContract.value: market_sell_asset_contractParser(),
    ContractType.MarketCancelOrderContract.value: market_cancel_order_contractParser(),
}
