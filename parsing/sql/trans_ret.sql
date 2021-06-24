DROP TABLE IF EXISTS
-- TRUNCATE TABLE
trans_ret_error,
trans_ret,
trans_ret_contract_result,
trans_ret_log,
trans_ret_log_topics,
trans_ret_inter_trans,
trans_ret_inter_trans_call_value,
trans_ret_order_detail;


CREATE TABLE trans_ret(
    id text, -- 交易hash b2hs
    fee bigint,
    block_number bigint,
    block_timestamp bigint,
    -- contractResult
    contract_address text,
    
    receipt_energy_usage bigint,
    receipt_energy_fee bigint,
    receipt_origin_energy_usage bigint,
    receipt_energy_usage_total bigint,
    receipt_net_usage bigint,
    receipt_net_fee bigint,
    receipt_result int,

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

CREATE TABLE trans_ret_contract_result(
    trans_id text,
    result_index int,
    result text
) format 'csv';

CREATE TABLE trans_ret_log(
    trans_id text,
    log_index int,
    address text,
    data text
) format 'csv';

CREATE TABLE trans_ret_log_topics(
    trans_id text,
    log_index int,
    topic_index int,
    topic text
) format 'csv';


CREATE TABLE trans_ret_inter_trans(
    trans_id text,
    inter_index int,
    hash text, -- b2hs
    caller_address text,
    transferTo_address text,
    note text, -- autoDecode
    rejected boolean
) format 'csv';

CREATE TABLE trans_ret_inter_trans_call_value(
    trans_id text,
    inter_index int,
    call_index int,
    call_value bigint,
    token_id text
) format 'csv';

CREATE TABLE trans_ret_order_detail(
    trans_id text,
    order_index int,
    makerOrderId text, -- b2hs
    takerOrderId text, -- b2hs
    fillSellQuantity bigint,
    fillBuyQuantity bigint
) format 'csv';
/*
TODO:
1. 验证contract result、log、internal_transactions、orderDetails的长度
*/
CREATE TABLE trans_ret_error(
    type text,
    id text,
    err text
) format 'csv';

COPY trans_ret_error FROM '/data2/20210425/trans_ret_parsed/trans_ret_error/11015604-11115604.csv' csv;
COPY trans_ret FROM '/data2/20210425/trans_ret_parsed/trans_ret/11015604-11115604.csv' csv;
COPY trans_ret_contract_result FROM '/data2/20210425/trans_ret_parsed/trans_ret_contract_result/11015604-11115604.csv' csv;
COPY trans_ret_log FROM '/data2/20210425/trans_ret_parsed/trans_ret_log/11015604-11115604.csv' csv;
COPY trans_ret_log_topics FROM '/data2/20210425/trans_ret_parsed/trans_ret_log_topics/11015604-11115604.csv' csv;
COPY trans_ret_inter_trans FROM '/data2/20210425/trans_ret_parsed/trans_ret_inter_trans/11015604-11115604.csv' csv;
COPY trans_ret_inter_trans_call_value FROM '/data2/20210425/trans_ret_parsed/trans_ret_inter_trans_call_value/11015604-11115604.csv' csv;
COPY trans_ret_order_detail FROM '/data2/20210425/trans_ret_parsed/trans_ret_order_detail/11015604-11115604.csv' csv;

SELECT * from trans_ret_error limit 10;
SELECT * from trans_ret limit 10;
SELECT * from trans_ret_contract_result limit 10;
SELECT * from trans_ret_log limit 10;
SELECT * from trans_ret_log_topics limit 10;
SELECT * from trans_ret_inter_trans limit 10;
SELECT * from trans_ret_inter_trans_call_value limit 10;
SELECT * from trans_ret_order_detail limit 10;

SELECT count(1) FROM trans_ret_error WHERE err != 'block not exists';