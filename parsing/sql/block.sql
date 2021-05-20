-- TODO:
-- 1. bytea 直接存bytes数据是不是不行
-- 2. 如果不行则b2hs().decode()  但是需要调研hexstr再如何转回bytes
-- 3. 

DROP TABLE IF EXISTS
-- TRUNCATE TABLE
error_block_num,
block,
trans,
trans_market_order_detail,
trans_auths,
account_create_contract,
transfer_contract,
transfer_asset_contract,
vote_asset_contract,
vote_witness_contract,
witness_create_contract,
asset_issue_contract,
asset_issue_contract_frozen_supply,
witness_update_contract,
participate_asset_issue_contract,
account_update_contract,
freeze_balance_contract,
unfreeze_balance_contract,
withdraw_balance_contract,
unfreeze_asset_contract,
update_asset_contract,
proposal_create_contract,
proposal_approve_contract,
proposal_delete_contract,
set_account_id_contract,
create_smart_contract,
trigger_smart_contract,
update_setting_contract,
exchange_create_contract,
exchange_inject_contract,
exchange_withdraw_contract,
exchange_transaction_contract,
update_energy_limit_contract,
account_permission_update_contract,
clear_abi_contract,
update_brokerage_contract,
shielded_transfer_contract;

CREATE TABLE error_block_num(
    block_num bigint
) format 'csv';

CREATE TABLE block(
    block_num bigint,
    hash text,
    parent_hash text,
    create_time bigint,
    version int,
    witness_address text,
    witness_id bigint,
    tx_count int,
    tx_trie_root text,
    witness_signature text,
    account_state_root text
) format 'csv';
CREATE TABLE trans(
    id text,
    block_hash text,
    block_num bigint,
    -- ret START--
    fee bigint,
    ret int, -- NULL means SUCCESS
    contract_type int,
    contract_ret int, -- NULL means SUCCESS
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text,
    -- ret END--
    -- raw START
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    scripts_decode text,
    data text,
    data_decode text,
    -- raw END
    signature text
) format 'csv';
CREATE TABLE trans_market_order_detail(
    trans_id text,
    makerOrderId text,
    taker_order_id text,
    fill_sell_quantity bigint,
    fill_buy_quantity bigint
) format 'csv';

CREATE TABLE trans_auths(
    trans_id text,
    account_address text,
    account_name text,
    permission_name text
) format 'csv';

CREATE TABLE account_create_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    account_address text,
    account_type int
) format 'csv';
CREATE TABLE transfer_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    to_address text,
    amount bigint
) format 'csv';
CREATE TABLE transfer_asset_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    asset_name text,
    owner_address text,
    to_address text,
    amount bigint
) format 'csv';
CREATE TABLE vote_asset_contract(
    trans_id text,
    ret int,
    bytes_hex text
) format 'csv';
CREATE TABLE vote_witness_contract(
    trans_id text,
    ret int,
    bytes_hex text
) format 'csv';
-- CREATE TABLE vote_asset_contract(
--     trans_id text,
--     ret int,
--     provider text,
--     name text,
--     permission_id int,
--     -- more
--     owner_address text,
--     vote_address text, --csv格式存储多个vote_address
--     support boolean,
--     count int
-- ) format 'csv';
-- CREATE TABLE vote_witness_contract(
--     trans_id text,
--     ret int,
--     provider text,
--     name text,
--     permission_id int,
--     -- more
--     owner_address text,
--     support boolean,
--     vote_address text,
--     vote_count bigint
-- ) format 'csv';
CREATE TABLE witness_create_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    url text
) format 'csv';
CREATE TABLE asset_issue_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    id text,
    owner_address text,
    name_ text, -- contract 详情中的name
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
CREATE TABLE asset_issue_contract_frozen_supply(
    trans_id text,
    frozen_amount bigint,
    frozen_days bigint
) format 'csv';
CREATE TABLE witness_update_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    update_url text
) format 'csv';
CREATE TABLE participate_asset_issue_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    to_address text,
    asset_name text,
    amount bigint
) format 'csv';
CREATE TABLE account_update_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    account_name text
) format 'csv';
CREATE TABLE freeze_balance_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    frozen_balance bigint,
    frozen_duration bigint,
    resource int,
    receiver_address text
) format 'csv';
CREATE TABLE unfreeze_balance_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    resource int,
    receiver_address text
) format 'csv';
CREATE TABLE withdraw_balance_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text
) format 'csv';
CREATE TABLE unfreeze_asset_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text
) format 'csv';
CREATE TABLE update_asset_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    description text,
    url text,
    new_limit bigint,
    new_public_limit bigint
) format 'csv';
CREATE TABLE proposal_create_contract(
    trans_id text,
    ret int,
    bytes_hex text
) format 'csv';
CREATE TABLE proposal_approve_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    proposal_id bigint,
    is_add_approval boolean
) format 'csv';
CREATE TABLE proposal_delete_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    proposal_id bigint
) format 'csv';
CREATE TABLE set_account_id_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    account_id text
) format 'csv';
CREATE TABLE create_smart_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    -- SmartContract new_contract = 2;
    contract_bytes text,
    call_token_value bigint,
    token_id bigint
) format 'csv';
CREATE TABLE trigger_smart_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    contract_address text,
    call_value bigint,
    data text,
    call_token_value bigint,
    token_id bigint
) format 'csv';
CREATE TABLE update_setting_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    contract_address text,
    consume_user_resource_percent bigint
) format 'csv';
CREATE TABLE exchange_create_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    first_token_id  text,
    first_token_balance bigint,
    second_token_id  text,
    second_token_balance bigint
) format 'csv';
CREATE TABLE exchange_inject_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    exchange_id bigint,
    token_id text,
    quant bigint
) format 'csv';
CREATE TABLE exchange_withdraw_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    exchange_id bigint,
    token_id text,
    quant bigint
) format 'csv';
CREATE TABLE exchange_transaction_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    exchange_id bigint,
    token_id text,
    quant bigint,
    expected bigint
) format 'csv';
CREATE TABLE update_energy_limit_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    contract_address text,
    origin_energy_limit bigint
) format 'csv';
CREATE TABLE account_permission_update_contract(
    trans_id text,
    ret int,
    bytes_hex text
) format 'csv';
CREATE TABLE clear_abi_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    contract_address text
) format 'csv';
CREATE TABLE update_brokerage_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    brokerage int
) format 'csv';
CREATE TABLE shielded_transfer_contract(
    trans_id text,
    ret int,
    bytes_hex text
    -- provider text,
    -- name text,
    -- permission_id int,
    -- -- more
    -- transparent_from_address text,
    -- from_amount bigint,
    -- -- repeated SpendDescription spend_description = 3;
    -- -- repeated ReceiveDescription receive_description = 4;
    -- binding_signature text,
    -- transparent_to_address text,
    -- to_amount bigint
) format 'csv';

CREATE TABLE market_sell_asset_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    sell_token_id text,
    sell_token_quantity bigint,
    buy_token_id text,
    buy_token_quantity bigint
) format 'csv';

CREATE TABLE market_cancel_order_contract(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    order_id text
) format 'csv';