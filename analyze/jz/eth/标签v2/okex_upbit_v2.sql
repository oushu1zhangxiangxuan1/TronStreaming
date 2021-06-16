drop table okex_upbit_v2;
with 
okex_pools as(
    SELECT
    address
    FROM
        tag_all
    WHERE 
        tag_name = 'okex_pool'
	group by address
),
upbit_users as(
    SELECT
    address
    FROM
        tag_all
    WHERE 
        tag_name = 'upbit'
	group by address
),
-- 查出所有from1在A中的交易（下游地址，时间，金额）
trans_from AS(SELECT
    b.to1,to_char(to_timestamp(b.timestamp::bigint), 'yyyy-mm-dd') AS tx_date, b.transactionhash, b.value --, toiscontract AS is_contract
FROM 
    okex_pools a
    JOIN
    orc_t_ethereum_nmta b 
    ON 
	a.address = b.from1
),

-- 查出所有from1在B中的交易（下游地址，时间，金额）
trans_to AS(SELECT
    trans_from.*
FROM 
    upbit_users
    JOIN
    trans_from
    ON 
	upbit_users.address = trans_from.to1
),
-- 查出给境外指定交易所转币次数，算出金额的sum -- 这里可能需要区分不同代币
trans_amount_sum AS(
    SELECT 
        to1, count(transactionhash) OVER (PARTITION BY to1) tx_cnt, tx_date, sum(value::decimal/1000000000000000000) OVER (PARTITION BY to1) AS amount --, is_contract
    FROM
        trans_to
),
--交易天数的distinct
trans_date_unique AS(
    SELECT 
        to1, tx_date, tx_cnt, amount --, is_contract
    FROM
        trans_amount_sum
    GROUP BY to1, tx_date, tx_cnt, amount --, is_contract
), 
trans_counts_all AS (
	SELECT to1, count(1) cnt, max(to_char(to_timestamp(timestamp::bigint), 'yyyy-mm-dd')) AS MAX_DATE, min(to_char(to_timestamp(timestamp::bigint), 'yyyy-mm-dd')) AS MIN_DATE
	FROM
	(
		SELECT to1, transactionhash, timestamp
		FROM 
		(
			SELECT a.to1, b.transactionhash , timestamp 
			FROM
			trans_date_unique a 
			 JOIN
			 orc_t_ethereum_nmta b
			 ON 
			 a.to1 = b.from1 
			union 
			 SELECT a.to1, b.transactionhash, timestamp 
			FROM
			trans_date_unique a 
			 JOIN
			 orc_t_ethereum_nmta b
			 ON 
			 a.to1 = b.to1
		) c
		GROUP BY to1, transactionhash, timestamp
	) d
	GROUP BY to1 
)
SELECT 
    a.to1, count(tx_date) AS date_count, tx_cnt AS "转币次数",  MAX_DATE, MIN_DATE, amount::real, b.cnt --, is_contract
	INTO okex_upbit_v2	
FROM 
 trans_date_unique a
 JOIN
 trans_counts_all  b
 ON
 a.to1 = b.to1
 GROUP BY a.to1, tx_cnt, MAX_DATE, MIN_DATE, amount,  b.cnt -- is_contract,
;