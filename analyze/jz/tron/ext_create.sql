DROP external TABLE ext_error_block_num;
--0
CREATE external TABLE ext_error_block_num
( block_num bigint) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/error_block_num/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/error_block_num/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/error_block_num/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/error_block_num/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/error_block_num/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/error_block_num/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/error_block_num/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/error_block_num/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/error_block_num/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/error_block_num/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/error_block_num/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/error_block_num/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_error_block_num_errs segment reject limit 10000;


DROP external TABLE ext_block;
--29617378
CREATE external TABLE ext_block
( 
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
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/block/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/block/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/block/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/block/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/block/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/block/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/block/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/block/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/block/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/block/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/block/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/block/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_block_errs segment reject limit 10000;


DROP external TABLE ext_trans;
--1757574154 错误数据：57614  
--1757612066 错误数据：85806 
--1757615358 copy 55330
CREATE external TABLE ext_trans
( 
    id text,
    block_hash text,
    block_num bigint,
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
    ref_block_num bigint,
    ref_block_hash text,
    expiration bigint,
    trans_time bigint,
    fee_limit bigint,
    scripts text,
    data text,
    signature text
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/trans/0-2500000.csv'        ,	       --12166004  +
'gpfdist://tron1:8081/block_parsed_250_500w/trans/2500000-5000000.csv',        --92405153  +
'gpfdist://tron2:8081/block_parsed_500_750w/trans/5000000-7500000.csv'    ,    --194073206 +
'gpfdist://tron2:8081/block_parsed_750_1000w/trans/7500000-10000000.csv'  ,    --162276532 +
'gpfdist://tron3:8081/block_parsed_1000_1250w/trans/10000000-12500000.csv',    --193490907 +
'gpfdist://tron3:8081/block_parsed_1250_1500w/trans/12500000-15000000.csv',    --161046330 +
'gpfdist://tron4:8081/block_parsed_1500_1750w/trans/15000000-17500000.csv',    --86328025  +
'gpfdist://tron4:8081/block_parsed_1750_2000w/trans/17500000-20000000.csv',    --105065458 +
'gpfdist://tron5:8081/block_parsed_2000_2250w/trans/20000000-22500000.csv',    --116040884 +
'gpfdist://tron5:8081/block_parsed_2250_2500w/trans/22500000-25000000.csv',    --196435282 +
'gpfdist://tron6:8081/block_parsed_2500_2750w/trans/25000000-27500000.csv',    --198756535 +
'gpfdist://tron6:8081/block_parsed_2750_3000w/trans/27500000-29617378.csv'     --253256145
)
format 'csv'( quote '"'  delimiter ','  null '')
log errors into ext_trans_errs segment reject limit 100000;

--csv:   1771340461
--trans: 1757615358
--ext:   1757604051

DROP external TABLE ext_trans_market_order_detail;
--0
CREATE external TABLE ext_trans_market_order_detail
( 
    trans_id text,
    makerOrderId text,
    taker_order_id text,
    fill_sell_quantity bigint,
    fill_buy_quantity bigint
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/trans_market_order_detail/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/trans_market_order_detail/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/trans_market_order_detail/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/trans_market_order_detail/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/trans_market_order_detail/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/trans_market_order_detail/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/trans_market_order_detail/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/trans_market_order_detail/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/trans_market_order_detail/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/trans_market_order_detail/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/trans_market_order_detail/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/trans_market_order_detail/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_trans_market_order_detail_errs segment reject limit 10000;

DROP external TABLE ext_trans_auths;
--0
CREATE external TABLE ext_trans_auths
( 
    trans_id text,
    account_address text,
    account_name text,
    permission_name text
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/trans_auths/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/trans_auths/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/trans_auths/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/trans_auths/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/trans_auths/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/trans_auths/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/trans_auths/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/trans_auths/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/trans_auths/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/trans_auths/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/trans_auths/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/trans_auths/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_trans_auths_errs segment reject limit 10000;



DROP external TABLE ext_account_create_contract;
--3316810
CREATE external TABLE ext_account_create_contract
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    account_address text,
    account_type int
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/account_create_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/account_create_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/account_create_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/account_create_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/account_create_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/account_create_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/account_create_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/account_create_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/account_create_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/account_create_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/account_create_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/account_create_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_account_create_contract_errs segment reject limit 10000;


DROP external TABLE ext_transfer_contract;
--225977939
CREATE external TABLE ext_transfer_contract
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    to_address text,
    amount bigint
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/transfer_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/transfer_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/transfer_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/transfer_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/transfer_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/transfer_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/transfer_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/transfer_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/transfer_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/transfer_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/transfer_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/transfer_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_transfer_contract_errs segment reject limit 10000;   


DROP external TABLE ext_transfer_asset_contract_old;
--170418461
CREATE external TABLE ext_transfer_asset_contract_old
( 
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
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/transfer_asset_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/transfer_asset_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/transfer_asset_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/transfer_asset_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/transfer_asset_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/transfer_asset_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/transfer_asset_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/transfer_asset_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/transfer_asset_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/transfer_asset_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/transfer_asset_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/transfer_asset_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_transfer_asset_contract_old_errs segment reject limit 10000;



DROP external TABLE ext_transfer_asset_contract;
--170418461
CREATE external TABLE ext_transfer_asset_contract
( 
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
) 
location (
'gpfdist://tron1:8081/transfer_asset_contract/0-2500000.csv', 
'gpfdist://tron1:8081/transfer_asset_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/transfer_asset_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/transfer_asset_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/transfer_asset_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/transfer_asset_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/transfer_asset_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/transfer_asset_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/transfer_asset_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/transfer_asset_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/transfer_asset_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/transfer_asset_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_transfer_asset_contract_errs segment reject limit 10000;



-- NODATA
DROP external TABLE ext_vote_asset_contract;
CREATE external TABLE ext_vote_asset_contract
( 
	trans_id text,
    ret int,
    bytes_hex text
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/vote_asset_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/vote_asset_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/vote_asset_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/vote_asset_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/vote_asset_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/vote_asset_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/vote_asset_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/vote_asset_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/vote_asset_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/vote_asset_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/vote_asset_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/vote_asset_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_vote_asset_contract_errs segment reject limit 10000;


DROP external TABLE ext_vote_witness_contract;
--7118663
CREATE external TABLE ext_vote_witness_contract
( 
    trans_id text,
    ret int,
    bytes_hex text
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/vote_witness_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/vote_witness_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/vote_witness_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/vote_witness_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/vote_witness_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/vote_witness_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/vote_witness_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/vote_witness_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/vote_witness_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/vote_witness_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/vote_witness_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/vote_witness_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_vote_witness_contract_errs segment reject limit 10000;


DROP external TABLE ext_witness_create_contract;
--291
CREATE external TABLE ext_witness_create_contract
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    url text
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/witness_create_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/witness_create_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/witness_create_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/witness_create_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/witness_create_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/witness_create_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/witness_create_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/witness_create_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/witness_create_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/witness_create_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/witness_create_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/witness_create_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_witness_create_contract_errs segment reject limit 10000;


DROP external TABLE ext_asset_issue_contract;
--3921
CREATE external TABLE ext_asset_issue_contract
( 
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
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/asset_issue_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/asset_issue_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/asset_issue_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/asset_issue_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/asset_issue_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/asset_issue_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/asset_issue_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/asset_issue_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/asset_issue_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/asset_issue_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/asset_issue_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/asset_issue_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_asset_issue_contract_errs segment reject limit 10000;

DROP external TABLE ext_asset_issue_contract_frozen_supply;
--1543
CREATE external TABLE ext_asset_issue_contract_frozen_supply
( 
    trans_id text,
    frozen_amount bigint,
    frozen_days bigint
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/asset_issue_contract_frozen_supply/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/asset_issue_contract_frozen_supply/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/asset_issue_contract_frozen_supply/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/asset_issue_contract_frozen_supply/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/asset_issue_contract_frozen_supply/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/asset_issue_contract_frozen_supply/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/asset_issue_contract_frozen_supply/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/asset_issue_contract_frozen_supply/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/asset_issue_contract_frozen_supply/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/asset_issue_contract_frozen_supply/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/asset_issue_contract_frozen_supply/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/asset_issue_contract_frozen_supply/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_asset_issue_contract_frozen_supply_errs segment reject limit 10000;


DROP external TABLE ext_witness_update_contract;
--749
CREATE external TABLE ext_witness_update_contract
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    update_url text
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/witness_update_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/witness_update_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/witness_update_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/witness_update_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/witness_update_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/witness_update_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/witness_update_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/witness_update_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/witness_update_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/witness_update_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/witness_update_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/witness_update_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_witness_update_contract_errs segment reject limit 10000;


DROP external TABLE ext_participate_asset_issue_contract;
--134021
CREATE external TABLE ext_participate_asset_issue_contract
( 
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
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/participate_asset_issue_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/participate_asset_issue_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/participate_asset_issue_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/participate_asset_issue_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/participate_asset_issue_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/participate_asset_issue_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/participate_asset_issue_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/participate_asset_issue_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/participate_asset_issue_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/participate_asset_issue_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/participate_asset_issue_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/participate_asset_issue_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_participate_asset_issue_contract_errs segment reject limit 10000;


DROP external TABLE ext_account_update_contract;
--39692
CREATE external TABLE ext_account_update_contract
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    account_name text
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/account_update_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/account_update_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/account_update_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/account_update_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/account_update_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/account_update_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/account_update_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/account_update_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/account_update_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/account_update_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/account_update_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/account_update_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_account_update_contract_errs segment reject limit 10000;


DROP external TABLE ext_freeze_balance_contract;
--5710993
CREATE external TABLE ext_freeze_balance_contract
( 
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
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/freeze_balance_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/freeze_balance_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/freeze_balance_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/freeze_balance_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/freeze_balance_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/freeze_balance_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/freeze_balance_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/freeze_balance_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/freeze_balance_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/freeze_balance_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/freeze_balance_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/freeze_balance_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_freeze_balance_contract_errs segment reject limit 10000;


DROP external TABLE ext_unfreeze_balance_contract;
--1971478
CREATE external TABLE ext_unfreeze_balance_contract
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    resource int,
    receiver_address text
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/unfreeze_balance_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/unfreeze_balance_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/unfreeze_balance_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/unfreeze_balance_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/unfreeze_balance_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/unfreeze_balance_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/unfreeze_balance_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/unfreeze_balance_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/unfreeze_balance_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/unfreeze_balance_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/unfreeze_balance_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/unfreeze_balance_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_unfreeze_balance_contract_errs segment reject limit 10000;


DROP external TABLE ext_withdraw_balance_contract;
--1712855
CREATE external TABLE ext_withdraw_balance_contract
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/withdraw_balance_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/withdraw_balance_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/withdraw_balance_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/withdraw_balance_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/withdraw_balance_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/withdraw_balance_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/withdraw_balance_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/withdraw_balance_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/withdraw_balance_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/withdraw_balance_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/withdraw_balance_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/withdraw_balance_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_withdraw_balance_contract_errs segment reject limit 10000;

DROP external TABLE ext_unfreeze_asset_contract;
--285
CREATE external TABLE ext_unfreeze_asset_contract
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/unfreeze_asset_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/unfreeze_asset_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/unfreeze_asset_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/unfreeze_asset_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/unfreeze_asset_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/unfreeze_asset_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/unfreeze_asset_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/unfreeze_asset_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/unfreeze_asset_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/unfreeze_asset_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/unfreeze_asset_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/unfreeze_asset_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_unfreeze_asset_contract_errs segment reject limit 10000;


DROP external TABLE ext_update_asset_contract;
--109
CREATE external TABLE ext_update_asset_contract
( 
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
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/update_asset_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/update_asset_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/update_asset_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/update_asset_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/update_asset_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/update_asset_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/update_asset_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/update_asset_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/update_asset_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/update_asset_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/update_asset_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/update_asset_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_update_asset_contract_errs segment reject limit 10000;

DROP external TABLE ext_proposal_create_contract;
--0
CREATE external TABLE ext_proposal_create_contract
( 
    trans_id text,
    ret int,
    bytes_hex text
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/proposal_create_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/proposal_create_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/proposal_create_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/proposal_create_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/proposal_create_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/proposal_create_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/proposal_create_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/proposal_create_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/proposal_create_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/proposal_create_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/proposal_create_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/proposal_create_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_proposal_create_contract_errs segment reject limit 10000;


DROP external TABLE ext_proposal_approve_contract;
--612
CREATE external TABLE ext_proposal_approve_contract
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    proposal_id bigint,
    is_add_approval boolean
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/proposal_approve_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/proposal_approve_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/proposal_approve_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/proposal_approve_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/proposal_approve_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/proposal_approve_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/proposal_approve_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/proposal_approve_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/proposal_approve_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/proposal_approve_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/proposal_approve_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/proposal_approve_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_proposal_approve_contract_errs segment reject limit 10000;


DROP external TABLE ext_proposal_delete_contract;
--7
CREATE external TABLE ext_proposal_delete_contract
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    proposal_id bigint
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/proposal_delete_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/proposal_delete_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/proposal_delete_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/proposal_delete_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/proposal_delete_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/proposal_delete_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/proposal_delete_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/proposal_delete_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/proposal_delete_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/proposal_delete_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/proposal_delete_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/proposal_delete_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_proposal_delete_contract_errs segment reject limit 10000;


DROP external TABLE ext_set_account_id_contract;
--12
CREATE external TABLE ext_set_account_id_contract
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    account_id text
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/set_account_id_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/set_account_id_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/set_account_id_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/set_account_id_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/set_account_id_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/set_account_id_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/set_account_id_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/set_account_id_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/set_account_id_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/set_account_id_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/set_account_id_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/set_account_id_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_set_account_id_contract_errs segment reject limit 10000;


DROP external TABLE ext_trigger_smart_contract;
--1341835207
CREATE external TABLE ext_trigger_smart_contract
( 
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
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/trigger_smart_contract/0-2500000.csv',
'gpfdist://tron1:8081/block_parsed_250_500w/trigger_smart_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/trigger_smart_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/trigger_smart_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/trigger_smart_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/trigger_smart_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/trigger_smart_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/trigger_smart_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/trigger_smart_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/trigger_smart_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/trigger_smart_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/trigger_smart_contract/27500000-29617378.csv'
)
format 'csv'(delimiter ',' null '')
log errors into ext_trigger_smart_contract_errs segment reject limit 10000;

DROP external TABLE ext_update_setting_contract;
--906
CREATE external TABLE ext_update_setting_contract
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    contract_address text,
    consume_user_resource_percent bigint
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/update_setting_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/update_setting_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/update_setting_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/update_setting_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/update_setting_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/update_setting_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/update_setting_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/update_setting_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/update_setting_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/update_setting_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/update_setting_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/update_setting_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_update_setting_contract_errs segment reject limit 10000;

DROP external TABLE ext_exchange_create_contract;
--184
CREATE external TABLE ext_exchange_create_contract
( 
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
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/exchange_create_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/exchange_create_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/exchange_create_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/exchange_create_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/exchange_create_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/exchange_create_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/exchange_create_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/exchange_create_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/exchange_create_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/exchange_create_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/exchange_create_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/exchange_create_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_exchange_create_contract_errs segment reject limit 10000;


DROP external TABLE ext_exchange_inject_contract;
--1318
CREATE external TABLE ext_exchange_inject_contract
( 
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
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/exchange_inject_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/exchange_inject_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/exchange_inject_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/exchange_inject_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/exchange_inject_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/exchange_inject_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/exchange_inject_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/exchange_inject_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/exchange_inject_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/exchange_inject_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/exchange_inject_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/exchange_inject_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_exchange_inject_contract_errs segment reject limit 10000;

DROP external TABLE ext_exchange_withdraw_contract;
--675
CREATE external TABLE ext_exchange_withdraw_contract
( 
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
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/exchange_withdraw_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/exchange_withdraw_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/exchange_withdraw_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/exchange_withdraw_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/exchange_withdraw_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/exchange_withdraw_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/exchange_withdraw_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/exchange_withdraw_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/exchange_withdraw_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/exchange_withdraw_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/exchange_withdraw_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/exchange_withdraw_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_exchange_withdraw_contract_errs segment reject limit 10000;

DROP external TABLE ext_exchange_transaction_contract;
--1611048
CREATE external TABLE ext_exchange_transaction_contract
( 
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
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/exchange_transaction_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/exchange_transaction_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/exchange_transaction_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/exchange_transaction_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/exchange_transaction_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/exchange_transaction_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/exchange_transaction_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/exchange_transaction_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/exchange_transaction_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/exchange_transaction_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/exchange_transaction_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/exchange_transaction_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_exchange_transaction_contract_errs segment reject limit 10000;

DROP external TABLE ext_update_energy_limit_contract;
--98
CREATE external TABLE ext_update_energy_limit_contract
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    contract_address text,
    origin_energy_limit bigint
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/update_energy_limit_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/update_energy_limit_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/update_energy_limit_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/update_energy_limit_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/update_energy_limit_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/update_energy_limit_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/update_energy_limit_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/update_energy_limit_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/update_energy_limit_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/update_energy_limit_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/update_energy_limit_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/update_energy_limit_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_update_energy_limit_contract_errs segment reject limit 10000;

DROP external TABLE ext_account_permission_update_contract;
--22084
CREATE external TABLE ext_account_permission_update_contract
( 
    trans_id text,
    ret int,
    bytes_hex text
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/account_permission_update_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/account_permission_update_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/account_permission_update_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/account_permission_update_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/account_permission_update_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/account_permission_update_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/account_permission_update_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/account_permission_update_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/account_permission_update_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/account_permission_update_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/account_permission_update_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/account_permission_update_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_account_permission_update_contract_errs segment reject limit 10000;


DROP external TABLE ext_clear_abi_contract;
--46
CREATE external TABLE ext_clear_abi_contract
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    contract_address text
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/clear_abi_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/clear_abi_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/clear_abi_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/clear_abi_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/clear_abi_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/clear_abi_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/clear_abi_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/clear_abi_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/clear_abi_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/clear_abi_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/clear_abi_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/clear_abi_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_clear_abi_contract_errs segment reject limit 10000;


DROP external TABLE ext_update_brokerage_contract;
--1476
CREATE external TABLE ext_update_brokerage_contract
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    brokerage int
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/update_brokerage_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/update_brokerage_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/update_brokerage_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/update_brokerage_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/update_brokerage_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/update_brokerage_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/update_brokerage_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/update_brokerage_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/update_brokerage_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/update_brokerage_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/update_brokerage_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/update_brokerage_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_update_brokerage_contract_errs segment reject limit 10000;


DROP external TABLE ext_shielded_transfer_contract;
--0
CREATE external TABLE ext_shielded_transfer_contract
( 
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
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/shielded_transfer_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/shielded_transfer_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/shielded_transfer_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/shielded_transfer_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/shielded_transfer_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/shielded_transfer_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/shielded_transfer_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/shielded_transfer_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/shielded_transfer_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/shielded_transfer_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/shielded_transfer_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/shielded_transfer_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_shielded_transfer_contract_errs segment reject limit 10000;


DROP external TABLE ext_market_sell_asset_contract;
--缺少文件
CREATE external TABLE ext_market_sell_asset_contract
( 
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
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/market_sell_asset_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/market_sell_asset_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/market_sell_asset_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/market_sell_asset_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/market_sell_asset_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/market_sell_asset_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/market_sell_asset_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/market_sell_asset_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/market_sell_asset_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/market_sell_asset_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/market_sell_asset_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/market_sell_asset_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_market_sell_asset_contract_errs segment reject limit 10000;


DROP external TABLE ext_market_cancel_order_contract;
--缺少文件
CREATE external TABLE ext_market_cancel_order_contract
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    order_id text
) 
location (
'gpfdist://tron1:8081/block_parsed_0_250w/market_cancel_order_contract/0-2500000.csv', 
'gpfdist://tron1:8081/block_parsed_250_500w/market_cancel_order_contract/2500000-5000000.csv',
'gpfdist://tron2:8081/block_parsed_500_750w/market_cancel_order_contract/5000000-7500000.csv',
'gpfdist://tron2:8081/block_parsed_750_1000w/market_cancel_order_contract/7500000-10000000.csv',
'gpfdist://tron3:8081/block_parsed_1000_1250w/market_cancel_order_contract/10000000-12500000.csv',
'gpfdist://tron3:8081/block_parsed_1250_1500w/market_cancel_order_contract/12500000-15000000.csv',
'gpfdist://tron4:8081/block_parsed_1500_1750w/market_cancel_order_contract/15000000-17500000.csv',
'gpfdist://tron4:8081/block_parsed_1750_2000w/market_cancel_order_contract/17500000-20000000.csv',
'gpfdist://tron5:8081/block_parsed_2000_2250w/market_cancel_order_contract/20000000-22500000.csv',
'gpfdist://tron5:8081/block_parsed_2250_2500w/market_cancel_order_contract/22500000-25000000.csv',
'gpfdist://tron6:8081/block_parsed_2500_2750w/market_cancel_order_contract/25000000-27500000.csv',
'gpfdist://tron6:8081/block_parsed_2750_3000w/market_cancel_order_contract/27500000-29617378.csv')
format 'csv'(delimiter ',')
log errors into ext_market_cancel_order_contract_errs segment reject limit 10000;



