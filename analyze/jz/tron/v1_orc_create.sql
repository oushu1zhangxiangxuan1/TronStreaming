
CREATE TABLE err_trans_v1( --NODATA
    block_num bigint,
    trans_id text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);


CREATE TABLE trans_v1( --NODATA
    block_num bigint,
    trans_id text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);


CREATE TABLE vote_asset_contract_v1(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    support boolean,
    count int
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE vote_asset_contract_vote_address_v1(
    trans_id text,
    vote_address text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);



CREATE TABLE vote_witness_contract_v1(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    support boolean,
    tmp_0 text -- TODO: remove columns later
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE vote_witness_contract_votes_v1(
    trans_id text,
    vote_address text,
    bote_account bigint
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);



CREATE TABLE proposal_create_contract_v1(
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE proposal_create_contract_parameters_v1(
    p_key bigint,
    p_value bigint
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);



CREATE TABLE create_smart_contract_v1(
    trans_id text,
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
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE create_smart_contract_abi_v1(
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
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE create_smart_contract_abi_inputs_v1(
    trans_id text,
    entry_id int,
    -- more
    indexed boolean,
    name text,
    type text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE create_smart_contract_abi_outputs_v1(
    trans_id text,
    entry_id int,
    -- more
    indexed boolean,
    name text,
    type text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);




CREATE TABLE account_permission_update_contract_v1(
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
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE account_permission_update_contract_keys_v1(
    trans_id text,
    key_sign int, -- -1 :owner -2:witness 0+:index of actives
    key_index bigint, -- index of keys
    -- more
    address text, -- by addressFromBytes
    address_hex text, -- by bytes2HexStr
    weight bigint
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE account_permission_update_contract_actives_v1(
    trans_id text,
    active_index bigint,
    -- more
    permission_type int,
    permission_id int,
    permission_name text,
    permission_threshold bigint,
    permission_parent_id int,
    permission_operations text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);



CREATE TABLE shielded_transfer_contract_v1(
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
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);



CREATE TABLE market_sell_asset_contract_v1( --NODATA
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
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);


CREATE TABLE market_cancel_order_contract_v1( --NODATA
    trans_id text,
    ret int,
    provider text,
    name text,
    permission_id int,
    -- more
    owner_address text,
    order_id text
) with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);
