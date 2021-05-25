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
    bytes2HexStr,
    # ownerAddressDecode,
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
    table = "vote_asset_contract_v1"

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            return False

        for addr in self.contract.vote_address:
            addr = addressFromBytes(addr)
            writer.Write(
                "vote_asset_contract_vote_address_v1", [appendData["trans_id"], addr]
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
        # ColumnIndex(
        #     name="vote_address",
        #     oc=OriginColumn(name="vote_address", castFunc=addressFromBytes),
        # ),
        ColumnIndex(
            name="vote_count",
            oc=OriginColumn(name="vote_count", colType="int"),
        ),
    ]
    table = "vote_witness_contract_v1"

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            return False

        for vote in self.contract.votes:
            addr = addressFromBytes(vote.vote_address)
            writer.Write(
                "vote_witness_contract_votes_v1",
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
    table = "proposal_create_contract_v1"

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            return False

        # 遍历parameters
        for key in self.contract.parameters:
            value = self.contract.parameters[key]
            writer.Write(
                "proposal_create_contract_parameters_v1",
                [appendData["trans_id"], key, value],
            )
        return True


class create_smart_contractParser(ContractBaseParser):
    def __init__(self):
        self.abiParser = create_smart_contract_abi_Parser()

    colIndex = ContractBaseParser.colIndex + [
        ColumnIndex(
            name="origin_address",
            oc=OriginColumn(name="origin_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="contract_address",
            oc=OriginColumn(name="contract_address", castFunc=addressFromBytes),
        ),
        ColumnIndex(
            name="bytecode",
            oc=OriginColumn(name="bytecode", castFunc=autoDecode),
        ),
        ColumnIndex(
            name="call_value",
            oc=OriginColumn(name="call_value", colType="int64"),
        ),
        ColumnIndex(
            name="consume_user_resource_percent",
            oc=OriginColumn(name="consume_user_resource_percent", colType="int64"),
        ),
        ColumnIndex(
            name="name",
            oc=OriginColumn(name="name", colType="string"),
        ),
        ColumnIndex(
            name="origin_energy_limit",
            oc=OriginColumn(name="origin_energy_limit", colType="int64"),
        ),
        ColumnIndex(
            name="code_hash",
            oc=OriginColumn(name="code_hash"),
        ),
        ColumnIndex(
            name="trx_hash",
            oc=OriginColumn(name="trx_hash"),
        ),
    ]

    table = "create_smart_contract_v1"

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            return False
        for i, entry in enumerate(self.contract.abi.entrys):
            appendData["enrey_id"] = i
            ret = self.abiParser.Parse(writer, entry, appendData)
            if not ret:
                return False
        return True


class create_smart_contract_abi_Parser(BaseParser):
    colIndex = ContractBaseParser.colIndex + [
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

    table = "create_smart_contract_content_abi_v1"

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            return False

        # 遍历parameters
        for param in data.inputs:
            writer.Write(
                "create_smart_contract_content_abi_inputs_v1",
                [
                    appendData["trans_id"],
                    appendData["entry_id"],
                    param.indexed,
                    param.name,
                    param.type,
                ],
            )
        for param in data.outputs:
            writer.Write(
                "create_smart_contract_content_abi_outputs_v1",
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


class account_permission_update_contract_Parser(BaseParser):
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

    table = "account_permission_update_contract_v1"

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
                "account_permission_update_contract_keys_v1",
                [
                    appendData["trans_id"],
                    -1,
                    i,
                    autoDecode(key.address),  # TODO:check how to decode
                    key.weight,
                ],
            )
        for i, key in enumerate(self.contract.owner.keys):
            writer.write(
                "account_permission_update_contract_keys_v1",
                [
                    appendData["trans_id"],
                    0,
                    i,
                    autoDecode(key.address),  # TODO:check how to decode
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
            oc=_ownerWrapper(OriginColumn(name="type", colType="int")),
        ),
        ColumnIndex(
            name="id",
            oc=_ownerWrapper(OriginColumn(name="id", colType="int")),
        ),
        ColumnIndex(
            name="permission_name",
            oc=_ownerWrapper(OriginColumn(name="permission_name", colType="string")),
        ),
        ColumnIndex(
            name="threshold",
            oc=_ownerWrapper(OriginColumn(name="threshold", colType="int64")),
        ),
        ColumnIndex(
            name="parent_id",
            oc=_ownerWrapper(OriginColumn(name="parent_id", colType="int32")),
        ),
        ColumnIndex(
            name="operations",
            oc=_ownerWrapper(
                OriginColumn(name="operations", colType="bytes")
            ),  # TODO: check how to decode
        ),
    ]
    table = "account_permission_update_contract_actives_v1"

    def Parse(self, writer, data, appendData):
        ret = super().Parse(writer, data, appendData)
        if not ret:
            return False
        for i, key in enumerate(data.keys):
            writer.write(
                "account_permission_update_contract_keys_v1",
                [
                    appendData["trans_id"],
                    appendData["active_index"],
                    i,
                    autoDecode(key.address),  # TODO:check how to decode
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

    table = "shielded_transfer_contract_v1"


def getContract(contractType):
    return contractTypeMap[contractType]()


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


contractParserMap = {
    ContractType.VoteAssetContract.value: VoteAssetContractParser(),
    ContractType.VoteWitnessContract.value: VoteWitnessContractParser(),
    ContractType.ProposalCreateContract.value: ProposalCreateContractParser(),
    ContractType.CreateSmartContract.value: create_smart_contractParser(),
    ContractType.AccountPermissionUpdateContract.value: account_permission_update_contract_Parser(),
    ContractType.ShieldedTransferContract.value: shiled_transfer_contract_Parser(),
}


def initContractParser():
    for t, p in contractParserMap.items():
        setattr(p, "contract", getContract(t))


# class market_cancel_order_contractParser(ContractBaseParser):
#     colIndex = ContractBaseParser.colIndex + [
#         ColumnIndex(
#             name="owner_address",
#             oc=OriginColumn(name="owner_address", castFunc=addressFromBytes),
#         ),
#         ColumnIndex(
#             name="order_id",
#             oc=OriginColumn(name="order_id", castFunc=autoDecode),  # TODO:type
#         ),
#     ]
#     table = "market_cancel_order_contract"
