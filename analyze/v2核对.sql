with 
okex_pools as(
    SELECT
    address
    FROM
        t_tag
    WHERE 
        tag_name = 'okex_pool'
	group by address
),
bithumb_users as(
    SELECT
    address
    FROM
        t_tag
    WHERE 
        tag_name = 'bithumb'
	group by address
),

-- 查出所有from1在A中的交易（下游地址，时间，金额）
trans_from AS(SELECT
    b.to1,to_char(to_timestamp(b.timestamp::bigint), 'yyyy-mm-dd') AS tx_date, b.transactionhash, b.value, toiscontract AS is_contract
FROM 
    okex_pools a
    JOIN
    orc_t_ethereum_iet b 
    ON 
	a.address = b.from1
)
-- 查出所有from1在B中的交易（下游地址，时间，金额）
SELECT
    trans_from.*
    FROM 
    trans_from
	WHERE to1 = '0x286f1c2a65704b71f54f91ff463eefcf8b09691c'
;