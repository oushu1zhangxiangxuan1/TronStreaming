-- 1. 核对数据
SELECT count(1) FROM usdt_trans_ret
WHERE contract_address = 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t';

-- 2. 创建表 
-- TODO: 需要把被查的表名改为内部orc表名
CREATE TABLE usdt_trans_ret
WITH (appendonly = true, orientation = orc, compresstype = lz4, dicthreshold = 0.8)
AS 
SELECT * FROM trans_ret
WHERE contract_address = 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t'
ORDER BY id;

-- check trans_id unique
SELECT count(1) FROM(
SELECT id, count(1) FROM
usdt_trans_ret
GROUP BY id
having count(1)>0
)a;


CREATE TABLE usdt_trans_ret_log
AS
SELECT a.* FROM 
trans_ret_log a
JOIN
usdt_trans_ret b
ON b.id = a.trans_id
ORDER BY a.trans_id;
-- 68678564


CREATE TABLE usdt_trans_ret_log_topics
AS
SELECT a.* FROM 
trans_ret_log_topics a
JOIN
usdt_trans_ret b
ON b.id = a.trans_id
ORDER BY a.trans_id;
-- 206035286


-- 核对都有调用了哪些函数
-- 核对topic 0 是什么，distinct count
-- enumerate 为什么从0开始
SELECT count(1) 
FROM(
    SELECT topic 
    FROM usdt_trans_ret_log_topics
    WHERE topic_index = 1
    GROUP BY topic
) a; -- 7720918

SELECT count(1) 
FROM(
    SELECT topic 
    FROM usdt_trans_ret_log_topics
    WHERE topic_index = 0
    GROUP BY topic
) a; -- 7

-- 核对对多有几个tpoic

SELECT max_index
FROM(
    SELECT trans_id, max(topic_index) as max_index
    FROM usdt_trans_ret_log_topics
    GROUP BY trans_id
) a
GROUP BY max_index;
--  max_index 
-- -----------
--          2
--          1


-- 转换成orc表
CREATE TABLE orc_usdt_trans_ret_log
WITH (appendonly = true, orientation = orc, compresstype = lz4, dicthreshold = 0.8)
AS SELECT * FROM usdt_trans_ret_log;

CREATE TABLE orc_usdt_trans_ret_log_topics
WITH (appendonly = true, orientation = orc, compresstype = lz4, dicthreshold = 0.8)
AS SELECT * FROM usdt_trans_ret_log_topics;


-- 生成event为Transfer和Approval的函数定义hash
-- 创建函数及对应hash表
CREATE TBALE usdt_func_hash(
	func_hash text,
	func_name text 
)
WITH (appendonly = true, orientation = orc, compresstype = lz4, dicthreshold = 0.8);
INSERT INTO usdt_func_hash VALUES
('ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef','Transfer(address,address,uint256)'),
('8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925','Approval(address,address,uint256)');
-- 导出event为Transfer和Approval的的数据
-- 需要知道是transfer 还是approval
CREATE TABLE orc_usdt_trans_ret_log_topics_filter
WITH (appendonly = true, orientation = orc, compresstype = lz4, dicthreshold = 0.8)
AS SELECT a.trans_id, a.log_index, b.func_name, b.func_hash 
(
	SELECT * FROM 
	orc_usdt_trans_ret_log_topics a 
	WHERE topic_index = 0
	GROUP BY trans_id, log_index
) a
JOIN
usdt_func_hash b
ON b.func_hash = a.topic;


CREATE TABLE orc_usdt_trans_ret_log_topics_filter_from
WITH (appendonly = true, orientation = orc, compresstype = lz4, dicthreshold = 0.8)
AS 
(
	SELECT trans_id, log_index, topic_index, topic
	FROM orc_usdt_trans_ret_log_topics
	WHERE topic_index = 1
) a
JOIN 
orc_usdt_trans_ret_log_topics_filter b
ON a.trans_id = b.trans_id AND a.log_index=b.log_index
GROUP BY trans_id, log_index;

CREATE TABLE orc_usdt_trans_ret_log_topics_filter_to
WITH (appendonly = true, orientation = orc, compresstype = lz4, dicthreshold = 0.8)
AS 
(
	SELECT trans_id, log_index, topic_index, topic
	FROM orc_usdt_trans_ret_log_topics
	WHERE topic_index = 2
) a
JOIN 
orc_usdt_trans_ret_log_topics_filter b
ON a.trans_id = b.trans_id AND a.log_index=b.log_index
GROUP BY trans_id, log_index;


CREATE TABLE orc_usdt_trans_ret_log_topics_filter_amount
WITH (appendonly = true, orientation = orc, compresstype = lz4, dicthreshold = 0.8)
AS 
(
	SELECT trans_id, log_index, data as amount
	FROM orc_usdt_trans_ret_log_topics
) a
JOIN 
orc_usdt_trans_ret_log_topics_filter b
ON a.trans_id = b.trans_id AND a.log_index=b.log_index
GROUP BY trans_id, log_index;

-- TODO: check from to amount count

-- 合并成一个表
CREATE TABLE usdt_from_to_amount
WITH (appendonly = true, orientation = orc, compresstype = lz4, dicthreshold = 0.8)
AS SELECT a.trans_id, a.log_index, a.from1, b.to1, c.amount
FROM 
	orc_usdt_trans_ret_log_topics_filter_from a
	JOIN
	orc_usdt_trans_ret_log_topics_filter_to b
	ON a.trans_id = b.trans_id AND a.log_index = b.log_index
	JOIN
	orc_usdt_trans_ret_log_topics_filter_amount c
	ON a.trans_id = b.trans_id AND c.log_index = c.log_index;

-- TODO: 将这三个表导出为csv

-- 解析完建一个新表导入

-- 新表的from需要通过交易hash连接trans表的from

-- 查看单个transaction info是不是只含有单个log：否
SELECT log_index
FROM trans_ret_log
WHERE log_index>1
GROUP BY log_index;