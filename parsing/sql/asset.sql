-- TODO:
-- 1. bytea 直接存bytes数据是不是不行
-- 2. 如果不行则b2hs().decode()  但是需要调研hexstr再如何转回bytes
-- 3. 

DROP TABLE IF EXISTS
-- TRUNCATE TABLE
error_asset_id,
asset_issue_v2,
asset_issue_v2_frozen_supply;

CREATE TABLE error_asset_id(
    asset_id bigint
) format 'csv';
CREATE TABLE asset_issue_v2(
    id text,
    owner_address text,
    name text, -- contract 详情中的name
    abbr text,
    total_supply bigint,
    -- asset_issue_contract_frozen_supply
    trx_num int,
    precision int,
    num int,
    start_time bigint,
    end_time bigint,
    order_ bigint,
    vote_score int,
    description text,
    url text,
    free_asset_net_limit bigint,
    public_free_asset_net_limit bigint,
    public_free_asset_net_usage bigint,
    public_latest_free_net_time bigint
) format 'csv';
CREATE TABLE asset_issue_v2_frozen_supply( --NODATA
    asset_id text,
    asset_name text,
    frozen_amount bigint,
    frozen_days bigint
) format 'csv';