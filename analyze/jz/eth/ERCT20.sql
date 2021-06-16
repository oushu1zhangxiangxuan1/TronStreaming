
2019 	  0to999999_ERC20Transaction.csv
106484923 10000000to10999999_ERC20Transaction.csv



rm -rf readme.txt
0to999999_ERC20Transaction

rm -rf readme.txt
unzip 1000000to1999999_ERC20Transaction.zip

rm -rf readme.txt
unzip 2000000to2999999_ERC20Transaction.zip

rm -rf readme.txt
unzip 3000000to3999999_ERC20Transaction.zip

rm -rf readme.txt
unzip 4000000to4999999_ERC20Transaction.zip

rm -rf readme.txt
unzip 5000000to5999999_ERC20Transaction.zip

rm -rf readme.txt
unzip 6000000to6999999_ERC20Transaction.zip

rm -rf readme.txt
unzip 7000000to7999999_ERC20Transaction.zip

rm -rf readme.txt
unzip 8000000to8999999_ERC20Transaction

rm -rf readme.txt
unzip 9000000to9999999_ERC20Transaction

rm -rf readme.txt
unzip 10000000to10999999_ERC20Transaction

rm -rf readme.txt
unzip 11000000to11999999_ERC20Transaction.zip


drop table ext_t_ethereum_erc20_errs cascade;
drop external table ext_t_ethereum_erc20;
CREATE EXTERNAL TABLE ext_t_ethereum_erc20
(
blockNumber bigint,
timestamp text,
transactionhash text,
tokenaddress text,
from1 text,
to1 text,
fromIsContract text,
toIsContract text,
value text
)
LOCATION
(
'gpfdist://tron1:8081/ERCT20/0to999999_ERC20Transaction.csv',          
'gpfdist://tron1:8081/ERCT20/1000000to1999999_ERC20Transaction.csv',
'gpfdist://tron2:8081/ERCT20/2000000to2999999_ERC20Transaction.csv',
'gpfdist://tron2:8081/ERCT20/3000000to3999999_ERC20Transaction.csv',
'gpfdist://tron3:8081/ERCT20/4000000to4999999_ERC20Transaction.csv',
'gpfdist://tron3:8081/ERCT20/5000000to5999999_ERC20Transaction.csv',
'gpfdist://tron4:8081/ERCT20/6000000to6999999_ERC20Transaction.csv',
'gpfdist://tron4:8081/ERCT20/7000000to7999999_ERC20Transaction.csv',
'gpfdist://tron5:8081/ERCT20/8000000to8999999_ERC20Transaction.csv',
'gpfdist://tron5:8081/ERCT20/9000000to9999999_ERC20Transaction.csv',
'gpfdist://tron6:8081/ERCT20/10000000to10999999_ERC20Transaction.csv',
'gpfdist://tron6:8081/ERCT20/11000000to11999999_ERC20Transaction.csv')
format 'csv'(  delimiter ',')
log errors into ext_t_ethereum_erc20_errs segment reject limit 50000;


601955106 
601955094

create table orc_t_ethereum_erc20
with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8)
AS 
 SELECT * FROM public.orc_t_ethereum_erc20 ;
 
 

with
okex_pools as(
    SELECT
    address
    FROM
        t_tag
    WHERE 
        tag_name = 'okex_pool'
),-- 找出okex资金池地址 A
bithumb_users as(
    SELECT
    address
    FROM
        t_tag
    WHERE 
        tag_name = 'bithumb'
),--找出bithumb 过渡地址 B
erc20_usdt as(
    SELECT * FROM public.orc_t_ethereum_erc20
    WHERE tokenaddress='0xdac17f958d2ee523a2206206994597c13d831ec7'
) --过滤出USDT token交易
-- 查出所有from1在A中的交易（下游地址，时间，金额）
 SELECT
    b.to1,to_char(to_timestamp(b.timestamp::bigint), 'yyyy-mm-dd') AS tx_date, b.value
FROM 
    okex_pools a
    JOIN
    erc20_usdt b 
    ON (a.address = b.from1)
 

 