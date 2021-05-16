CREATE TABLE account (
    account_name text,
    type int, --Normal = 0; AssetIssue = 1; Contract = 2;
    address text,
    balance bigint,
    net_usage bigint,
    acquired_delegated_frozen_balance_for_bandwidth bigint,
    delegated_frozen_balance_for_bandwidth bigint,
    create_time bigint,
    latest_opration_time bigint,
    allowance bigint,
    latest_withdraw_time bigint,
    code_2l text,
    code_2hs text,
    is_witness bool,
    is_committee bool,
    asset_issued_name text,
    asset_issued_ID_2l text,
    asset_issued_ID_2hs text,
    free_net_usage bigint,
    latest_consume_time bigint,
    latest_consume_free_time bigint,
    account_id bytea --bytes?
);

CREATE TABLE account_resource (
    account_address text,
    energy_usage bigint,
    frozen_balance_for_energy bigint,
    frozen_balance_for_energy_expire_time bigint,
    latest_consume_time_for_energy bigint,
    acquired_delegated_frozen_balance_for_energy bigint,
    delegated_frozen_balance_for_energy bigint,
    storage_limit bigint,
    storage_usage bigint,
    latest_exchange_storage_time bigint
);

CREATE TABLE account_votes (
    account_address text,
    vote_address text,
    vote_count bigint
);

CREATE TABLE account_asset (
    account_address text,
    asset_id text,
    amount bigint,
    latest_opration_time bigint
);

CREATE TABLE account_asset_v2 (
    account_address text,
    asset_id text,
    amount bigint,
    latest_opration_time bigint
);

-- TODO:
CREATE TABLE account_frozen (
    account_address text,
    frozen_balance bigint,
    expire_time bigint
);

CREATE TABLE account_frozen_supply (
    account_address text,
    frozen_balance bigint,
    expire_time bigint
);

CREATE TABLE free_asset_net_usage (
    account_address text,
    asset_id text,
    net_usage bigint
);

CREATE TABLE free_asset_net_usage_v2 (
    account_address text,
    asset_id text,
    net_usage bigint
);

-- pkeys:account_id,asset_id
CREATE TABLE block (
    num bigint,
    hash text,
    parent_hash text,
    create_time bigint,
);

