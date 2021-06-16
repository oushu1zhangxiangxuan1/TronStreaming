

CREATE  TABLE error_block_num
( block_num bigint) 
with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);



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
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);


CREATE TABLE trans( -- TOCHECK:order_id, asset_issue_id
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
    data text,
    -- raw END
    signature text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);


CREATE TABLE trans_market_order_detail( -- NODATA
    trans_id text,
    makerOrderId text,
    taker_order_id text,
    fill_sell_quantity bigint,
    fill_buy_quantity bigint
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);


CREATE TABLE trans_auths( -- NODATA
    trans_id text,
    account_address text,
    account_name text,
    permission_name text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);


CREATE TABLE account_create_contract( -- CHECKED
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    account_address text,
    account_type int
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);


CREATE TABLE transfer_contract( -- CHECKED
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    to_address text,
    amount bigint
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE transfer_asset_contract( -- CHECKED
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
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE vote_asset_contract( -- NODATA
    trans_id text,
    ret int,
    bytes_hex text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE vote_witness_contract( -- NODATA
    trans_id text,
    ret int,
    bytes_hex text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);


CREATE TABLE witness_create_contract( --CHECKED
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    url text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

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
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE asset_issue_contract_frozen_supply( --NODATA
    trans_id text,
    frozen_amount bigint,
    frozen_days bigint
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE witness_update_contract( --CHECKED 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    update_url text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE participate_asset_issue_contract( --NODATA
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
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE account_update_contract( --NODATA
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    account_name text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE freeze_balance_contract( --CHECKED 
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
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE unfreeze_balance_contract( --CHECKED 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    resource int,
    receiver_address text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE withdraw_balance_contract( --CHECKED 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE unfreeze_asset_contract( --NODATA
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE update_asset_contract( --NODATA
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
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE proposal_create_contract( -- NODATA
    trans_id text,
    ret int,
    bytes_hex text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE proposal_approve_contract( --NODATA
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    proposal_id bigint,
    is_add_approval boolean
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE proposal_delete_contract( -- NODATA
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    proposal_id bigint
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE set_account_id_contract( -- NODATA
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    account_id text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);



CREATE TABLE trigger_smart_contract( --CHECKED
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
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE update_setting_contract( --CHECKED
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    contract_address text,
    consume_user_resource_percent bigint
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE exchange_create_contract( --NODATA
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
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE exchange_inject_contract( --NODATA
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
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE exchange_withdraw_contract( --NODATA
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
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE exchange_transaction_contract( --CHECKED
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
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE update_energy_limit_contract( --CHECKED
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    contract_address text,
    origin_energy_limit bigint
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE account_permission_update_contract(
    trans_id text,
    ret int,
    bytes_hex text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE clear_abi_contract( --NODATA
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    contract_address text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE update_brokerage_contract( --CHECKED
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    brokerage int
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

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
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);
