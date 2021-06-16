DROP external TABLE ext_err_trans_v1;
--NODATA
CREATE external TABLE ext_err_trans_v1
( 
    block_num bigint,
    trans_id text
) 
location (
'gpfdist://tron1:8082/err_trans_v1/0-5000000.csv', 
'gpfdist://tron2:8082/err_trans_v1/5000000-10000000.csv',
'gpfdist://tron3:8082/err_trans_v1/10000000-15000000.csv',
'gpfdist://tron4:8082/err_trans_v1/15000000-20000000.csv',
'gpfdist://tron5:8082/err_trans_v1/20000000-25000000.csv',
'gpfdist://tron6:8082/err_trans_v1/25000000-29617378.csv'
)
format 'csv'(delimiter ',')
log errors into ext_err_trans_v1_errs segment reject limit 10000;


DROP external TABLE ext_trans_v1;
--1760110784
CREATE external TABLE ext_trans_v1
( 
    block_num bigint,
    trans_id text
) 
location (
'gpfdist://tron1:8082/trans_v1/0-5000000.csv', 
'gpfdist://tron2:8082/trans_v1/5000000-10000000.csv',
'gpfdist://tron3:8082/trans_v1/10000000-15000000.csv',
'gpfdist://tron4:8082/trans_v1/15000000-20000000.csv',
'gpfdist://tron5:8082/trans_v1/20000000-25000000.csv',
'gpfdist://tron6:8082/trans_v1/25000000-29617378.csv'
)
format 'csv'(delimiter ',')
log errors into ext_trans_v1_errs segment reject limit 10000;

DROP external TABLE ext_vote_asset_contract_v1;
--NODATA
CREATE external TABLE ext_vote_asset_contract_v1
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    support boolean,
    count int
) 
location (
'gpfdist://tron1:8082/vote_asset_contract_v1/0-5000000.csv', 
'gpfdist://tron2:8082/vote_asset_contract_v1/5000000-10000000.csv',
'gpfdist://tron3:8082/vote_asset_contract_v1/10000000-15000000.csv',
'gpfdist://tron4:8082/vote_asset_contract_v1/15000000-20000000.csv',
'gpfdist://tron5:8082/vote_asset_contract_v1/20000000-25000000.csv',
'gpfdist://tron6:8082/vote_asset_contract_v1/25000000-29617378.csv'
)
format 'csv'(delimiter ',')
log errors into ext_vote_asset_contract_v1_errs segment reject limit 10000;


DROP external TABLE ext_vote_asset_contract_vote_address_v1;
--NODATA
CREATE external TABLE ext_vote_asset_contract_vote_address_v1
( 
    trans_id text,
    vote_address text
) 
location (
'gpfdist://tron1:8082/vote_asset_contract_vote_address_v1/0-5000000.csv', 
'gpfdist://tron2:8082/vote_asset_contract_vote_address_v1/5000000-10000000.csv',
'gpfdist://tron3:8082/vote_asset_contract_vote_address_v1/10000000-15000000.csv',
'gpfdist://tron4:8082/vote_asset_contract_vote_address_v1/15000000-20000000.csv',
'gpfdist://tron5:8082/vote_asset_contract_vote_address_v1/20000000-25000000.csv',
'gpfdist://tron6:8082/vote_asset_contract_vote_address_v1/25000000-29617378.csv'
)
format 'csv'(delimiter ',')
log errors into ext_vote_asset_contract_vote_address_v1_errs segment reject limit 10000;

DROP external TABLE ext_vote_witness_contract_v1;
--7118663
CREATE external TABLE ext_vote_witness_contract_v1
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    support boolean,
    tmp_0 text -- TODO: remove columns later
) 
location (
'gpfdist://tron1:8082/vote_witness_contract_v1/0-5000000.csv', 
'gpfdist://tron2:8082/vote_witness_contract_v1/5000000-10000000.csv',
'gpfdist://tron3:8082/vote_witness_contract_v1/10000000-15000000.csv',
'gpfdist://tron4:8082/vote_witness_contract_v1/15000000-20000000.csv',
'gpfdist://tron5:8082/vote_witness_contract_v1/20000000-25000000.csv',
'gpfdist://tron6:8082/vote_witness_contract_v1/25000000-29617378.csv'
)
format 'csv'(delimiter ',')
log errors into ext_vote_witness_contract_v1_errs segment reject limit 10000;


DROP external TABLE ext_vote_witness_contract_votes_v1;
--26516210
CREATE external TABLE ext_vote_witness_contract_votes_v1
( 
    trans_id text,
    vote_address text,
    bote_account bigint
) 
location (
'gpfdist://tron1:8082/vote_witness_contract_votes_v1/0-5000000.csv', 
'gpfdist://tron2:8082/vote_witness_contract_votes_v1/5000000-10000000.csv',
'gpfdist://tron3:8082/vote_witness_contract_votes_v1/10000000-15000000.csv',
'gpfdist://tron4:8082/vote_witness_contract_votes_v1/15000000-20000000.csv',
'gpfdist://tron5:8082/vote_witness_contract_votes_v1/20000000-25000000.csv',
'gpfdist://tron6:8082/vote_witness_contract_votes_v1/25000000-29617378.csv'
)
format 'csv'(delimiter ',')
log errors into ext_vote_witness_contract_votes_v1_errs segment reject limit 10000;


DROP external TABLE ext_proposal_create_contract_v1;
--55
CREATE external TABLE ext_proposal_create_contract_v1
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
'gpfdist://tron1:8082/proposal_create_contract_v1/0-5000000.csv', 
'gpfdist://tron2:8082/proposal_create_contract_v1/5000000-10000000.csv',
'gpfdist://tron3:8082/proposal_create_contract_v1/10000000-15000000.csv',
'gpfdist://tron4:8082/proposal_create_contract_v1/15000000-20000000.csv',
'gpfdist://tron5:8082/proposal_create_contract_v1/20000000-25000000.csv',
'gpfdist://tron6:8082/proposal_create_contract_v1/25000000-29617378.csv'
)
format 'csv'(delimiter ',')
log errors into ext_proposal_create_contract_v1_errs segment reject limit 10000;


DROP external TABLE ext_proposal_create_contract_parameters_v1;
--NODATA
CREATE external TABLE ext_proposal_create_contract_parameters_v1
( 
    p_key bigint,
    p_value bigint
) 
location (
'gpfdist://tron1:8082/proposal_create_contract_parameters_v1/0-5000000.csv', 
'gpfdist://tron2:8082/proposal_create_contract_parameters_v1/5000000-10000000.csv',
'gpfdist://tron3:8082/proposal_create_contract_parameters_v1/10000000-15000000.csv',
'gpfdist://tron4:8082/proposal_create_contract_parameters_v1/15000000-20000000.csv',
'gpfdist://tron5:8082/proposal_create_contract_parameters_v1/20000000-25000000.csv',
'gpfdist://tron6:8082/proposal_create_contract_parameters_v1/25000000-29617378.csv'
)
format 'csv'(delimiter ',')
log errors into ext_proposal_create_contract_parameters_v1_errs segment reject limit 10000;


DROP external TABLE ext_create_smart_contract_v1;
--230783
CREATE external TABLE ext_create_smart_contract_v1
( 
    trans_id     text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    call_token_value bigint,
    token_id bigint,
    origin_address text,
    contract_address text,
    bytecode text,
    call_value bigint,
    consume_user_resource_percent bigint,
    name_contract text,
    origin_energy_limit bigint,
    code_hash text,
    trx_hash text
) 
location (
'gpfdist://tron1:8082/create_smart_contract_v1/0-5000000.csv', 
'gpfdist://tron2:8082/create_smart_contract_v1/5000000-10000000.csv',
'gpfdist://tron3:8082/create_smart_contract_v1/10000000-15000000.csv',
'gpfdist://tron4:8082/create_smart_contract_v1/15000000-20000000.csv',
'gpfdist://tron5:8082/create_smart_contract_v1/20000000-25000000.csv',
'gpfdist://tron6:8082/create_smart_contract_v1/25000000-29617378.csv'
)
format 'csv'(delimiter ',')
log errors into ext_create_smart_contract_v1_errs segment reject limit 10000;

DROP external TABLE ext_create_smart_contract_abi_v1;
--3338621
CREATE external TABLE ext_create_smart_contract_abi_v1
( 
    trans_id text,
    tmp_ret int, -- TODO: remove columns later
    tmp_provider text, -- TODO: remove columns later
    tmp_name text, -- TODO: remove columns later
    tmp_permission_id int, -- TODO: remove columns later
    -- more
    anonymous boolean,
    constant boolean,
    name text,
    type int,
    payable boolean,
    state_mutability int
) 
location (
'gpfdist://tron1:8082/create_smart_contract_abi_v1/0-5000000.csv', 
'gpfdist://tron2:8082/create_smart_contract_abi_v1/5000000-10000000.csv',
'gpfdist://tron3:8082/create_smart_contract_abi_v1/10000000-15000000.csv',
'gpfdist://tron4:8082/create_smart_contract_abi_v1/15000000-20000000.csv',
'gpfdist://tron5:8082/create_smart_contract_abi_v1/20000000-25000000.csv',
'gpfdist://tron6:8082/create_smart_contract_abi_v1/25000000-29617378.csv'
)
format 'csv'(delimiter ',')
log errors into ext_create_smart_contract_abi_v1_errs segment reject limit 10000;

DROP external TABLE ext_create_smart_contract_abi_inputs_v1;
--3734228
CREATE external TABLE ext_create_smart_contract_abi_inputs_v1
( 
    trans_id text,
    entry_id int,
    -- more
    indexed boolean,
    name text,
    type text
) 
location (
'gpfdist://tron1:8082/create_smart_contract_abi_inputs_v1/0-5000000.csv', 
'gpfdist://tron2:8082/create_smart_contract_abi_inputs_v1/5000000-10000000.csv',
'gpfdist://tron3:8082/create_smart_contract_abi_inputs_v1/10000000-15000000.csv',
'gpfdist://tron4:8082/create_smart_contract_abi_inputs_v1/15000000-20000000.csv',
'gpfdist://tron5:8082/create_smart_contract_abi_inputs_v1/20000000-25000000.csv',
'gpfdist://tron6:8082/create_smart_contract_abi_inputs_v1/25000000-29617378.csv'
)
format 'csv'(delimiter ',')
log errors into ext_create_smart_contract_abi_inputs_v1_errs segment reject limit 10000;


DROP external TABLE ext_create_smart_contract_abi_outputs_v1;
--1758834
CREATE external TABLE ext_create_smart_contract_abi_outputs_v1
( 
    trans_id text,
    entry_id int,
    -- more
    indexed boolean,
    name text,
    type text
) 
location (
'gpfdist://tron1:8082/create_smart_contract_abi_outputs_v1/0-5000000.csv', 
'gpfdist://tron2:8082/create_smart_contract_abi_outputs_v1/5000000-10000000.csv',
'gpfdist://tron3:8082/create_smart_contract_abi_outputs_v1/10000000-15000000.csv',
'gpfdist://tron4:8082/create_smart_contract_abi_outputs_v1/15000000-20000000.csv',
'gpfdist://tron5:8082/create_smart_contract_abi_outputs_v1/20000000-25000000.csv',
'gpfdist://tron6:8082/create_smart_contract_abi_outputs_v1/25000000-29617378.csv'
)
format 'csv'(delimiter ',')
log errors into ext_create_smart_contract_abi_outputs_v1_errs segment reject limit 10000;


DROP external TABLE ext_account_permission_update_contract_v1;
--22084
CREATE external TABLE ext_account_permission_update_contract_v1
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    owner_permission_type int,
    owner_permission_id int,
    owner_permission_name text,
    owner_permission_threshold bigint,
    owner_permission_parent_id int,
    owner_permission_operations text,
    witness_permission_type int,
    witness_permission_id int,
    witness_permission_name text,
    witness_permission_threshold bigint,
    witness_permission_parent_id int,
    witness_permission_operations text
) 
location (
'gpfdist://tron1:8082/account_permission_update_contract_v1/0-5000000.csv', 
'gpfdist://tron2:8082/account_permission_update_contract_v1/5000000-10000000.csv',
'gpfdist://tron3:8082/account_permission_update_contract_v1/10000000-15000000.csv',
'gpfdist://tron4:8082/account_permission_update_contract_v1/15000000-20000000.csv',
'gpfdist://tron5:8082/account_permission_update_contract_v1/20000000-25000000.csv',
'gpfdist://tron6:8082/account_permission_update_contract_v1/25000000-29617378.csv'
)
format 'csv'(delimiter ',')
log errors into ext_account_permission_update_contract_v1_errs segment reject limit 10000;


DROP external TABLE ext_account_permission_update_contract_keys_v1;
--179756
CREATE external TABLE ext_account_permission_update_contract_keys_v1
( 
    trans_id text,
    key_sign int, -- -1 :owner -2:witness 0+:index of actives
    key_index bigint, -- index of keys
    -- more
    address text, -- by addressFromBytes
    address_hex text, -- by bytes2HexStr
    weight bigint
) 
location (
'gpfdist://tron1:8082/account_permission_update_contract_keys_v1/0-5000000.csv', 
'gpfdist://tron2:8082/account_permission_update_contract_keys_v1/5000000-10000000.csv',
'gpfdist://tron3:8082/account_permission_update_contract_keys_v1/10000000-15000000.csv',
'gpfdist://tron4:8082/account_permission_update_contract_keys_v1/15000000-20000000.csv',
'gpfdist://tron5:8082/account_permission_update_contract_keys_v1/20000000-25000000.csv',
'gpfdist://tron6:8082/account_permission_update_contract_keys_v1/25000000-29617378.csv'
)
format 'csv'(delimiter ',')
log errors into ext_account_permission_update_contract_keys_v1_errs segment reject limit 10000;

DROP external TABLE ext_account_permission_update_contract_actives_v1;
--23120
CREATE external TABLE ext_account_permission_update_contract_actives_v1
( 
    trans_id text,
    active_index bigint,
    -- more
    permission_type int,
    permission_id int,
    permission_name text,
    permission_threshold bigint,
    permission_parent_id int,
    permission_operations text
) 
location (
'gpfdist://tron1:8082/account_permission_update_contract_actives_v1/0-5000000.csv', 
'gpfdist://tron2:8082/account_permission_update_contract_actives_v1/5000000-10000000.csv',
'gpfdist://tron3:8082/account_permission_update_contract_actives_v1/10000000-15000000.csv',
'gpfdist://tron4:8082/account_permission_update_contract_actives_v1/15000000-20000000.csv',
'gpfdist://tron5:8082/account_permission_update_contract_actives_v1/20000000-25000000.csv',
'gpfdist://tron6:8082/account_permission_update_contract_actives_v1/25000000-29617378.csv'
)
format 'csv'(delimiter ',')
log errors into ext_account_permission_update_contract_actives_v1_errs segment reject limit 10000;


DROP external TABLE ext_shielded_transfer_contract_v1;
--NODATA
CREATE external TABLE ext_shielded_transfer_contract_v1
( 
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    transparent_from_address text,
    from_amount bigint,
    binding_signature text,
    transparent_to_address text,
    to_amount bigint,
    spend_description_value_commitment text,
    spend_description_anchor text,
    spend_description_nullifier text,
    spend_description_rk text,
    spend_description_zkproof text,
    spend_description_spend_authority_signature text,
    receive_description_value_commitment text,
    receive_description_note_commitment text,
    receive_description_epk text,
    receive_description_c_enc text,
    receive_description_c_out text,
    receive_description_zkproof text
) 
location (
'gpfdist://tron1:8082/shielded_transfer_contract_v1/0-5000000.csv', 
'gpfdist://tron2:8082/shielded_transfer_contract_v1/5000000-10000000.csv',
'gpfdist://tron3:8082/shielded_transfer_contract_v1/10000000-15000000.csv',
'gpfdist://tron4:8082/shielded_transfer_contract_v1/15000000-20000000.csv',
'gpfdist://tron5:8082/shielded_transfer_contract_v1/20000000-25000000.csv',
'gpfdist://tron6:8082/shielded_transfer_contract_v1/25000000-29617378.csv'
)
format 'csv'(delimiter ',')
log errors into ext_shielded_transfer_contract_v1_errs segment reject limit 10000;


DROP external TABLE ext_market_sell_asset_contract_v1;
--NODATA
CREATE external TABLE ext_market_sell_asset_contract_v1
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
'gpfdist://tron1:8082/market_sell_asset_contract_v1/0-5000000.csv', 
'gpfdist://tron2:8082/market_sell_asset_contract_v1/5000000-10000000.csv',
'gpfdist://tron3:8082/market_sell_asset_contract_v1/10000000-15000000.csv',
'gpfdist://tron4:8082/market_sell_asset_contract_v1/15000000-20000000.csv',
'gpfdist://tron5:8082/market_sell_asset_contract_v1/20000000-25000000.csv',
'gpfdist://tron6:8082/market_sell_asset_contract_v1/25000000-29617378.csv'
)
format 'csv'(delimiter ',')
log errors into ext_market_sell_asset_contract_v1_errs segment reject limit 10000;


DROP external TABLE ext_market_cancel_order_contract_v1;
--NODATA
CREATE external TABLE ext_market_cancel_order_contract_v1
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
'gpfdist://tron1:8082/market_cancel_order_contract_v1/0-5000000.csv', 
'gpfdist://tron2:8082/market_cancel_order_contract_v1/5000000-10000000.csv',
'gpfdist://tron3:8082/market_cancel_order_contract_v1/10000000-15000000.csv',
'gpfdist://tron4:8082/market_cancel_order_contract_v1/15000000-20000000.csv',
'gpfdist://tron5:8082/market_cancel_order_contract_v1/20000000-25000000.csv',
'gpfdist://tron6:8082/market_cancel_order_contract_v1/25000000-29617378.csv'
)
format 'csv'(delimiter ',')
log errors into ext_market_cancel_order_contract_v1_errs segment reject limit 10000;




