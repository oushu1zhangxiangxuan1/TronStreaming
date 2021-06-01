-- 波场交易输出表结构
CREATE TABLE tron_trans(
    trans_id text, -- 交易id或交易hash
    block_num bigint, -- 所在区块号
    trans_time timestamp, -- 交易时间
    trans_type text, -- trc10,20或者asset_name,
    from_address text, --来源地址
    to_address text, -- 去向地址
    amount bigint -- 交易量
);

-- transfer
SELECT 
    a.trans_id AS trans_id,
    b.block_num AS block_num,
    to_timestamp(b.trans_time) AS trans_time,
    'TRC-10' AS trans_type,
    a.owner_address as from_address,
    a.to_address as to_address,
    a.amount as amount
FROM
    transfer_contract a,
    left join
    trans b,
WHERE 
    a.owner_address ='TKQFpWs2GVFvjWW5xngLBirqgES4JJUdDH' OR a.to_address = 'TKQFpWs2GVFvjWW5xngLBirqgES4JJUdDH'; 
    --TODO: WHERE 提前将transfer_contract过滤是不是更快

-- transfer_asset
SELECT 
    a.trans_id AS trans_id,
    b.block_num AS block_num,
    to_timestamp(b.trans_time) AS trans_time,
    a.asset_name AS trans_type, -- TODO: 查看内部数数字还是真实的asset_name
    a.owner_address as from_address,
    a.to_address as to_address,
    a.amount as amount
FROM
    transfer_contract a,
    left join
    trans b,
WHERE 
    a.owner_address ='TKQFpWs2GVFvjWW5xngLBirqgES4JJUdDH' OR a.to_address = 'TKQFpWs2GVFvjWW5xngLBirqgES4JJUdDH'; 


-- asset_issue_contract
SELECT 
    id AS asset_id, 
    name_ AS asset_name
FROM asset_issue_contract;
-- 1. check  asset_id is unique
-- 2. check asset_name is unique
-- 3. check (asset_id, asset_name) is unique
-- 4. check asset_id is number
