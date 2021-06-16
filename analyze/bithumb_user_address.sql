--标签表：t_tag
--内部交易表:  t_ethernum_iet

-- 找出okex资金池地址 A

SELECT
    address
FROM
    t_tag
WHERE 
    tag_name = 'okex_pool';


-- 找出bithumb 过渡地址 B

SELECT
    address
FROM
    t_tag
WHERE 
    tag_name = 'bithumb';

-- 找出from1在A中且to在B中的交易， 并按to以天为单位进行count
-- TODO： 需要确认:而且外国交易所的过渡地址必须是否是一直收的同种通证
with 
okex_pools as(
    SELECT
    address
    FROM
        t_tag
    WHERE 
        tag_name = 'okex_pool'
)，
bithumb_users as(
    SELECT
    address
    FROM
        t_tag
    WHERE 
        tag_name = 'bithumb'
),
-- 查出所有from1在A中的交易（下游地址，时间，金额）
trans_from AS(SELECT
    b.to1,to_char(to_timestamp(b.timestamp), 'yyyy-mm-dd') AS tx_date, b.value, toiscontraxt AS is_contract
FROM 
    okex_pools a
    JOIN
    t_ethernum_iet b 
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
        to1, tx_date, sum(value) OVER (PARTITION BY to1) AS amount, is_contract
    FROM
        trans_to
),
--交易天数的distinct
trans_date_unique AS(
    SELECT 
        to1, tx_date, amount, is_contract
    FROM
        trans_amount_sum
    GROUP BY to1, tx_date, amount, is_contract
)
SELECT 
    to1, count(1) AS date_count, amount, is_contract
INTO bithumb_suspects
FROM trans_date_unique
GROUP BY to1, amount, is_contract;




-- DEPRECATED
SELECT * INTO bithumb_suspects FROM(
    SELECT c.to1 as address, count(1) AS date_count FROM(
        SELECT
            DISTINCT b.to1,to_char(b.timestamp, 'yyyy-mm-dd') AS tx_date
        FROM 
            okex_pools a
            JOIN
            t_ethernum_iet b 
            ON (a.address = b.from1)
    ) c 
    JOIN 
    bithumb_users d
    ON (c.to1 = d.address)
    GROUP BY c.to1) e
ORDER BY date_count DESC;
