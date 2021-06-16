--标签表：t_tag
--ERC20交易表:  public.orc_t_erc20

-- TODO： 需要确认:而且外国交易所的过渡地址必须是否是一直收的同种通证
with
okex_pools as(
    SELECT
    address
    FROM
        t_tag
    WHERE 
        tag_name = 'okex_pool'
)，-- 找出okex资金池地址 A
bithumb_users as(
    SELECT
    address
    FROM
        t_tag
    WHERE 
        tag_name = 'bithumb'
),--找出bithumb 过渡地址 B
erc20_usdt as(
    SELECT * FROM public.orc_t_erc20
    WHERE tokenaddress='0xdac17f958d2ee523a2206206994597c13d831ec7'
),--过滤出USDT token交易
-- 查出所有from1在A中的交易（下游地址，时间，金额）
trans_from AS(SELECT
    b.to1,to_char(to_timestamp(b.timestamp), 'yyyy-mm-dd') AS tx_date, b.value/1000000
FROM 
    okex_pools a
    JOIN
    erc20_usdt b 
    ON (a.address = b.from1)
),
-- 查出所有from1在B中的交易（下游地址，时间，金额）
trans_to AS(SELECT
    trans_from.*
FROM 
    bithumb_users
    JOIN
    trans_from
    ON (bithumb_users.address = trans_from.to1)
),
-- 查出算出金额的sum -- 这里可能需要区分不同代币
trans_amount_sum AS(
    SELECT 
        to1, tx_date, sum(value) OVER (PARTITION BY to1) AS amount
    FROM
        trans_to
),
--交易天数的distinct
trans_date_unique AS(
    SELECT 
        to1, tx_date, amount
    FROM
        trans_amount_sum
    GROUP BY to1, tx_date, amount
)
SELECT 
    to1, count(1) AS date_count, amount
INTO eth_usdt_okex_bithumb
FROM trans_date_unique
GROUP BY to1, amount;
