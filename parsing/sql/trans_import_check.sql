-- 1.
SELECT * 
INTO trans_id_dup
FROM
(
    SELECT id, count(1)
    FROM trans
    GROUP id
    HAVING count(1) > 1
) a;


-- 2. 
CREATE TABLE trans_block_coount
with (appendonly = true, orientation = orc, compresstype = lz4, dicthreshold = 0.8)
AS SELECT block_num, count(1) as trans_count 
FROM trans 
GROUP BY block_num;

-- 3.
SELECT * FROM
INTO trans_block_coount_not_equal 
(
    SELECT a.block_num AS block_num_b, b.block_num as block_num_t, a.tx_count as tx_count_b, b.trans_count as tx_count_t
    FROM block a 
    OUTER JOIN 
    trans b 
    ON a.block_num = b.block_num
) a WHERE block_num_b != block_num_t OR tx_count_b != tx_count_t;