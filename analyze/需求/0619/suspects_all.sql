-- 创建国内交易名称表
create table exchange_domestic(
    name text
);
-- 创建国内交易名称表
create table exchange_overseas(
    name text
);

-- 插入国内交易所名称
INSert into exchange_domestic 
Values
('huobi'),
('binance'),
('okex');

-- 插入国外交易所名称
INSert into exchange_overseas 
Values
('upbit'),
('bithumb');

-- 获取国内交易所地址
SELECT a.name AS exchange_name, b.address AS address
INTO exchange_domestic_addr
FROM
    exchange_domestic a
    JOIN  
    tag_all b 
    ON b.tag_name like a.name||'_pool%'
    GROUP BY exchange_name, address;
-- 获取国内交易所地址
SELECT a.name AS exchange_name, b.address AS address
INTO exchange_overseas_addr
FROM
    exchange_overseas a
    JOIN  
    tag_all b 
    ON b.tag_name like a.name||'_pool%'
    GROUP BY exchange_name, address;


/*
普通交易表: nm_ta
标签表: tag_all
*/
-- 找出所有国外交易所的过渡地址
create table transit_overseas(
    exchange_name,
    address text
);
INSERT INTO transit_overseas AS
SELECT a.name AS exchange_name, b.address AS address
FROM
    exchange_overseas a
    JOIN  
    tag_all b 
    ON a.name = b.tag_name
    GROUP BY exchange_name, address;

-- 找出国内交易所和过渡地址的交易流水
SELECT a.*, b.name as exchange_domestic 
trans_domestic
FROM
    nm_ta a
JOIN
    exchange_domestic_addr b 
    ON a.from1 = b.address
JOIN 
    transit_overseas c 
    ON a.to1 = c.address;

-- 找出过渡地址和国外交易所的交易流水
SELECT a.*, c.name as exchange_overseas 
INTO trans_overseas
FROM
    nm_ta a
JOIN
    transit_overseas b 
    ON a.from1 = b.address
JOIN 
     exchange_overseas_addr c 
    ON a.to1 = c.address;

-- 国外交易所转币天数
SELECT
    from1, 
    exchange_overseas, 
    count(1) AS date_count -- 国外交易所转币天数
INTO overseas_date_count
FROM (
    SELECT
        from1, exchange_overseas, to_char(to_timestamp(timestamp::bigint), 'yyyy-mm-dd') as trans_date
    FROM
        trans_overseas
    GROUP BY from1, exchange_overseas,trans_date
)GROUP BY from1, exchange_overseas;

-- 与国内某交易所的交易统计
SELECT 
    to1, 
    exchange_domestic, 
    count(1) AS domestic_trans_count, --与国内某交易所的交易次数
    sum(value)/10^18 AS domestic_trans_amount  --与国内某交易所的交易金额
    min(timestamp) AS domestic_min_ts,  --与国内某交易所最早交易时间
INTO domestic_statics
FROM
    trans_domestic
GROUP BY to1, exchange_domestic;

-- 与国外某交易所的交易统计
SELECT 
    from1, 
    exchange_overseas, 
    count(1) AS overseas_trans_count, --与国外某交易所的交易次数
    sum(value)/10^18 AS overseas_trans_amount  --与国外某交易所的交易金额
    max(timestamp) AS overseas_max_ts,  --与国外某交易所最新交易时间
INTO overseas_statics
FROM
    trans_overseas
GROUP BY from1, exchange_overseas;

-- 与国内所有交易所的交易统计
SELECT 
    to1, 
    sum(domestic_trans_count) AS all_domestic_trans_count, --与国内所有交易所的交易次数
    sum(domestic_trans_amount) AS all_domestic_trans_amount  --与国内所有交易所的交易金额
    min(domestic_min_ts) AS all_domestic_min_ts,  --与国内所有交易所最早交易时间
INTO domestic_statics_overall
FROM
    domestic_statics
GROUP BY to1;

-- 合并大表
SELECT
    a.to1, -- 境外交易所过渡账户地址
    a.exchange_domestic, -- 国内交易所
    b.exchange_overseas, -- 国外交易所
    c.date_count, -- 给境外指定交易所转币天数
    a.domestic_trans_count, --指定国内交易所到1的交易次数
    a.domestic_trans_amount, -- 国内池到过渡地址的交易金额
    to_timestamp(a.domestic_min_ts) AS domestic_min_ts, -- 国内交易所到过渡地址的首次交易时间
    a.overseas_trans_count, --1给境外指定交易所转币次数
    a.overseas_trans_amount, -- 过渡地址到国外交易所的交易金额
    to_timestamp(a.overseas_max_ts) AS overseas_max_ts, -- 过渡地址到国外交易所的最新交易时间
    d.all_domestic_trans_count, --与国内所有交易所的交易次数
    d.all_domestic_trans_amount  --与国内所有交易所的交易金额
    d.all_domestic_min_ts,  --与国内所有交易所最早交易时间
INTO
statics_middle
FROM 
domestic_statics a 
JOIN
overseas_statics b
ON a.to1 = b.from1
JOIN
overseas_date_count c
ON a.to1 = c.from1
JOIN
domestic_statics_overall d
ON a.to1 = d.to1;

with transit_addr as(
    SELECT
        to1
    FROM
        statics_middle
    GROUP BY to1;
),
trans_overall as(
    SELECT 
        transactionhash, from1, to1, timestamp 
    FORM (
        SELECT 
            a.transactionhash, b.to1, a.timestamp 
        FROM
            nm_ta a
        JOIN
            transit_addr b
        ON b.to1 = a.from1
        UNION ALL
        SELECT 
            a.transactionhash, b.to1, a.timestamp 
        FROM
            nm_ta a
        JOIN
            transit_addr b
        ON a.to1 = b.to1
    ) a 
    GROUP BY transactionhash, from1, to1, timestamp
)
SELECT
    to1
    count(1) as trans_count_all, -- 总交易次数(from 或 to中包含该地址的) T
    min(b.timestamp) as boarding_time, -- 上链时间（第一次交易时间）
    max(b.timestamp) as lastest_time -- 过渡地址最新交易时间
INTO statics_overall
FROM
    trans_overall
GROUP BY to1;

SELECT
    a.to1, -- 境外交易所过渡账户地址
    a.exchange_domestic, -- 国内交易所
    a.exchange_overseas, -- 国外交易所
    a.date_count, -- 给境外指定交易所转币天数
    a.domestic_trans_count, --指定国内交易所到1的交易次数
    a.domestic_trans_amount, -- 国内池到过渡地址的交易金额
    a.domestic_min_ts, -- 国内交易所到过渡地址的首次交易时间
    a.overseas_trans_count, --1给境外指定交易所转币次数
    a.overseas_trans_amount, -- 过渡地址到国外交易所的交易金额
    a.overseas_max_ts, -- 过渡地址到国外交易所的最新交易时间
    a.all_domestic_trans_count, --与国内所有交易所的交易次数
    a.all_domestic_trans_amount  --与国内所有交易所的交易金额
    a.all_domestic_min_ts,  --与国内所有交易所最早交易时间
    b.trans_count_all, -- 总交易次数(from 或 to中包含该地址的) T
    b.boarding_time, -- 上链时间（第一次交易时间）
    b.lastest_time, -- 过渡地址最新交易时间
    (a.domestic_trans_count + a.overseas_trans_count)*100/b.trans_count_all -- 与交易所交易次数占总交易次数比: (A+B)/T*100
FROM
    statics_middle a 
JOIN 
    statics_overall b 
ON a.to1 = b.to1 
ORDER BY a.overseas_trans_amount desc;





