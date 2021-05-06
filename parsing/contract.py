from enum import Enum, unique
import parsing.core.contract as contract


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
    ContractType.AccountCreateContract: contract.account_contract_pb2.AccountCreateContract,
    ContractType.TransferContract: contract.balance_contract_pb2.TransferContract,
    ContractType.TransferAssetContract: contract.asset_issue_contract_pb2.TransferAssetContract,
    ContractType.VoteAssetContract: contract.vote_asset_contract_pb2.VoteAssetContract,
    ContractType.VoteWitnessContract: contract.witness_contract_pb2.VoteWitnessContract,
    ContractType.WitnessCreateContract: contract.witness_contract_pb2.WitnessCreateContract,
    ContractType.AssetIssueContract: contract.asset_issue_contract_pb2.AssetIssueContract,
    ContractType.WitnessUpdateContract: contract.witness_contract_pb2.WitnessUpdateContract,
    ContractType.ParticipateAssetIssueContract: contract.asset_issue_contract_pb2.ParticipateAssetIssueContract,
    ContractType.AccountUpdateContract: contract.account_contract_pb2.AccountUpdateContract,
    ContractType.FreezeBalanceContract: contract.balance_contract_pb2.FreezeBalanceContract,
    ContractType.UnfreezeBalanceContract: contract.balance_contract_pb2.UnfreezeBalanceContract,
    ContractType.WithdrawBalanceContract: contract.balance_contract_pb2.WithdrawBalanceContract,
    ContractType.UnfreezeAssetContract: contract.asset_issue_contract_pb2.UnfreezeAssetContract,
    ContractType.UpdateAssetContract: contract.asset_issue_contract_pb2.UpdateAssetContract,
    ContractType.ProposalCreateContract: contract.proposal_contract_pb2.ProposalCreateContract,
    ContractType.ProposalApproveContract: contract.proposal_contract_pb2.ProposalApproveContract,
    ContractType.ProposalDeleteContract: contract.proposal_contract_pb2.ProposalDeleteContract,
    ContractType.SetAccountIdContract: contract.account_contract_pb2.SetAccountIdContract,
    # ContractType.CustomContract: contract..CustomContract,
    ContractType.CreateSmartContract: contract.smart_contract_pb2.CreateSmartContract,
    ContractType.TriggerSmartContract: contract.smart_contract_pb2.TriggerSmartContract,
    # ContractType.GetContract: contract..GetContract,
    ContractType.UpdateSettingContract: contract.smart_contract_pb2.UpdateSettingContract,
    ContractType.ExchangeCreateContract: contract.exchange_contract_pb2.ExchangeCreateContract,
    ContractType.ExchangeInjectContract: contract.exchange_contract_pb2.ExchangeInjectContract,
    ContractType.ExchangeWithdrawContract: contract.exchange_contract_pb2.ExchangeWithdrawContract,
    ContractType.ExchangeTransactionContract: contract.exchange_contract_pb2.ExchangeTransactionContract,
    ContractType.UpdateEnergyLimitContract: contract.smart_contract_pb2.UpdateEnergyLimitContract,
    ContractType.AccountPermissionUpdateContract: contract.account_contract_pb2.AccountPermissionUpdateContract,
    ContractType.ClearABIContract: contract.smart_contract_pb2.ClearABIContract,
    ContractType.UpdateBrokerageContract: contract.storage_contract_pb2.UpdateBrokerageContract,
    ContractType.ShieldedTransferContract: contract.shield_contract_pb2.ShieldedTransferContract,
    ContractType.MarketSellAssetContract: contract.market_contract_pb2.MarketSellAssetContract,
    ContractType.MarketCancelOrderContract: contract.market_contract_pb2.MarketCancelOrderContract,
}


def getContract(contractType):
    return contractTypeMap[contractType]()
