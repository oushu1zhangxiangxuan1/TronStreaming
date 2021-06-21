CREATE TABLE trans_his(
    id text, -- 交易hash b2hs
    fee bigint,
    block_number bigint,
    block_timestamp  bigint,
    -- contractResult
    contract_address text,
    -- receipt
    -- log
    result int, -- 0:SUCESS, 1:FAILED
    resMessage text, -- dec?
    asset_issue_id text,
    withdraw_amount bigint,
    unfreeze_amount bigint,
    -- internal_transactions
    exchange_received_amount bigint,
    exchange_inject_another_amount bigint,
    exchange_withdraw_another_amount bigint,
    exchange_id bigint,
    shielded_transaction_fee bigint,
    order_id text, -- dec?
    -- orderDetails
    packing_fee bigint
) format 'csv';

create trans_his_contract_result(
    trans_id text,
    result_index int,
    result text
) format 'csv';

create trans_his_log(
    trans_id text,
    log_index int,
    address text,
    data text
) format 'csv';

create trans_his_log_topics(
    trans_id text,
    log_index int,
    topic_index int,
    topic text
) format 'csv';


create trans_his_inter_trans(
    trans_id text,
    inter_index int,
    hash text, -- b2hs
    caller_address text,
    transferTo_address text,
    note text, -- autoDecode
    rejected boolean
) format 'csv';

create trans_his_inter_trans_call_value(
    trans_id text,
    inter_index int,
    call_index int,
    call_value bigint,
    token_id text
) format 'csv';

create trans_his_order_detail(
    trans_id text,
    order_index int,
    makerOrderId text, -- b2hs
    takerOrderId text,
    fillSellQuantity text,
    fillBuyQuantity text
) format 'csv';
/*
TODO:
1. 验证contract result、log、internal_transactions、orderDetails的长度
*/