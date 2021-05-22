DROP TABLE IF EXISTS 
-- TRUNCATE TABLE
error_account,
account,
account_resource,
account_votes,
account_asset,
account_asset_v2,
account_latest_asset_operation_time,
account_latest_asset_operation_time_v2,
account_frozen,
account_frozen_supply,
account_free_asset_net_usage,
account_free_asset_net_usage_v2;

CREATE TABLE error_account(
    account_index bigint,
    account_hex text,
    account_address text
) format 'csv';
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
    asset_issued_id_2l text,
    asset_issued_id_2hs text,
    free_net_usage bigint,
    latest_consume_time bigint,
    latest_consume_free_time bigint,
    account_id text --bytes?
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
    amount bigint
);

CREATE TABLE account_asset_v2 (
    account_address text,
    asset_id text,
    amount bigint
);


CREATE TABLE account_latest_asset_operation_time (
    account_address text,
    asset_id text,
    latest_opration_time bigint
);

CREATE TABLE account_latest_asset_operation_time_v2 (
    account_address text,
    asset_id text,
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

CREATE TABLE account_free_asset_net_usage (
    account_address text,
    asset_id text,
    net_usage bigint
);

CREATE TABLE account_free_asset_net_usage_v2 (
    account_address text,
    asset_id text,
    net_usage bigint
);

SELECT * FROM account limit 5;
SELECT * FROM account_resource limit 5;
SELECT * FROM account_votes limit 5;
SELECT * FROM account_asset limit 5; --CHECKED
SELECT * FROM account_asset_v2 limit 5; --CHECKED
SELECT * FROM account_latest_asset_operation_time limit 5; --NODATA
SELECT * FROM account_latest_asset_operation_time_v2 limit 5; --CHECKED
SELECT * FROM account_frozen limit 5; --CHECKED
SELECT * FROM account_frozen_supply limit 5; --CHECKED
SELECT * FROM account_free_asset_net_usage limit 5; --NODATA
SELECT * FROM account_free_asset_net_usage_v2 limit 5; --CHECKED

TRUNCATE TABLE
error_account,
account,
account_resource,
account_votes,
account_asset,
account_asset_v2,
account_latest_asset_operation_time,
account_latest_asset_operation_time_v2,
account_frozen,
account_frozen_supply,
account_free_asset_net_usage,
account_free_asset_net_usage_v2;
COPY error_account FROM '/data2/20210425/account_parsed/error_account.csv' csv;
COPY account FROM '/data2/20210425/account_parsed/account.csv' csv;
COPY account_resource FROM '/data2/20210425/account_parsed/account_resource.csv' csv;
COPY account_votes FROM '/data2/20210425/account_parsed/account_votes.csv' csv;
COPY account_asset FROM '/data2/20210425/account_parsed/account_asset.csv' csv;
COPY account_asset_v2 FROM '/data2/20210425/account_parsed/account_asset_v2.csv' csv;
COPY account_latest_asset_operation_time FROM '/data2/20210425/account_parsed/account_latest_asset_operation_time.csv' csv;
COPY account_latest_asset_operation_time_v2 FROM '/data2/20210425/account_parsed/account_latest_asset_operation_time_v2.csv' csv;
COPY account_frozen FROM '/data2/20210425/account_parsed/account_frozen.csv' csv;
COPY account_frozen_supply FROM '/data2/20210425/account_parsed/account_frozen_supply.csv' csv;
COPY account_free_asset_net_usage FROM '/data2/20210425/account_parsed/account_free_asset_net_usage.csv' csv;
COPY account_free_asset_net_usage_v2 FROM '/data2/20210425/account_parsed/account_free_asset_net_usage_v2.csv' csv;


SELECT 
    -- account_name,
    address,
    -- code_2l,
    -- code_2hs,
    -- asset_issued_name,
    -- account_id
    -- asset_issued_id_2l,
    -- asset_issued_id_2hs,
FROM 
    account
WHERE asset_issued_name is not null;

-- TODO:
-- 1. check account unique