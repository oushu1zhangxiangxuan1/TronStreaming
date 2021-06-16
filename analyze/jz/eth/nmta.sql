CREATE EXTERNAL TABLE ext_t_ethereum_nmta
(
blockNumber bigint,
timestamp text,
transactionHash text,
from1 text,
to1 text,
creates text,
value text,
gasLimit text,
gasPrice text,
gasUsed text,
callingFunction text,
isError text
)
LOCATION
(
'gpfdist://tron1:8081/nmta/0to999999_NormalTransaction.csv',          
'gpfdist://tron1:8081/nmta/1000000to1999999_NormalTransaction.csv',
'gpfdist://tron2:8081/nmta/2000000to2999999_NormalTransaction.csv',
'gpfdist://tron2:8081/nmta/3000000to3999999_NormalTransaction.csv',
'gpfdist://tron3:8081/nmta/4000000to4999999_NormalTransaction.csv',
'gpfdist://tron3:8081/nmta/5000000to5999999_NormalTransaction.csv',
'gpfdist://tron4:8081/nmta/6000000to6999999_NormalTransaction.csv',
'gpfdist://tron4:8081/nmta/7000000to7999999_NormalTransaction.csv',
'gpfdist://tron5:8081/nmta/8000000to8999999_NormalTransaction.csv',
'gpfdist://tron5:8081/nmta/9000000to9999999_NormalTransaction.csv',
'gpfdist://tron6:8081/nmta/10000000to10999999_NormalTransaction.csv',
'gpfdist://tron6:8081/nmta/11000000to11999999_NormalTransaction.csv')
format 'csv'(  delimiter ',')
log errors into ext_t_ethereum_nmta_errs segment reject limit 1000;

-- 
-- 
create table orc_t_ethereum_nmta
with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8)
AS 
 SELECT * FROM ext_t_ethereum_nmta;
 
 
 
 