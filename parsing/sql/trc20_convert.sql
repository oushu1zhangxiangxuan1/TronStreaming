-- 1. 创建trc20_token表
DROP TABLE IF EXISTS trc20_token;
CREATE TABLE trc20_token(
id serial, 
issue_ts int,
symbol text,
contract_address text,
gain text,
home_page text,
token_desc text,
price_trx int,
git_hub text,
price text,
total_supply_with_decimals text, -- TODO: 精度等
-- social_media_list text,
vip boolean,
email text,
icon_url text,
total_supply bigint,
level text,
total_supply_str text,
volume24h bigint,
index bigint,
contract_name text,
volume bigint,
issue_address text,
holders_count bigint,
decimals int,
name text,
issue_time text,
tokenType text,
white_paper text,
social_media text
)
WITH (appendonly = true, orientation = orc, compresstype = lz4, dicthreshold = 0.8);

-- 2. 导入数据
copy trc20_token from '/Users/johnsaxon/test/github.com/TronStreaming/parsing/trc20_tokens.csv' csv header;

-- 3. check cur serial after copy: ok
-- 4. check contract address unique
SELECT count(1) FROM(
    SELECT contract_address, count(1)
    FROM trc20_token
    GROUP BY contract_address
    HAVING count(1) > 1
)a;
-- 4. check index unique
SELECT count(1) FROM(
    SELECT index, count(1)
    FROM trc20_token
    GROUP BY index
    HAVING count(1) > 1
)a;

-- 5. check symbol unique
SELECT count(1) FROM(
    SELECT symbol, count(1)
    FROM trc20_token
    GROUP BY symbol
    HAVING count(1) > 1
)a; -- 3415

SELECT symbol, count(1) AS cnt
FROM trc20_token
GROUP BY symbol
HAVING count(1) > 1
ORDER BY cnt desc limit 10;