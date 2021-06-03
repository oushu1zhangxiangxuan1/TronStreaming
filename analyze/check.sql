一. okex1
0x6cc5f688a315f3dc28a7781717a9a798a59fda7b
postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1 ;
   count   
-----------
 661884304
 
postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1  where from1 = '0x6cc5f688a315f3dc28a7781717a9a798a59fda7b';
  count  
---------
 1232797
(1 row)


postgres=#  SELECT count(*) from orc_t_ethereum_nm_ta1  where to1 = '0x6cc5f688a315f3dc28a7781717a9a798a59fda7b';
 count  
--------
 553157
(1 row)

postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1  where from1 = '0x6cc5f688a315f3dc28a7781717a9a798a59fda7b' and to1 
= '0x6cc5f688a315f3dc28a7781717a9a798a59fda7b';
 count 
-------
   377
(1 row)

Time: 406347.404 ms


--汇给okex1 交易所的过渡账户，去重
SELECT count(*) from
 (
 SELECT  from1, to1  
 FROM orc_t_ethereum_nm_ta1  
 where to1 = '0x6cc5f688a315f3dc28a7781717a9a798a59fda7b' and from1 != '0x6cc5f688a315f3dc28a7781717a9a798a59fda7b'
 GROUP BY from1, to1
 ) C;
 
 count  
--------
 134845
(1 row)

Time: 1197533.567 ms

	
CREATE TABLE T_okex1(from1 TEXT, to1 TEXT) 
with (appendonly = true, orientation = orc, compresstype = lz4, dicthreshold = 0.8);


--汇给okex1 交易所的过渡账户的所有交易，去重
--1124692
 INSERT INTO T_okex1 
 SELECT
  from1, to1
  FROM orc_t_ethereum_nm_ta1
  where from1 IN (
  SELECT from1 
  FROM orc_t_ethereum_nm_ta1
  WHERE to1 = '0x6cc5f688a315f3dc28a7781717a9a798a59fda7b' and from1 != '0x6cc5f688a315f3dc28a7781717a9a798a59fda7b' 
  )GROUP BY from1, to1;
  
--结果
SELECT
 a.to1, 
 a.cnt,
 b.name
FROM
 (
    SELECT
    to1, 
    count(to1) as cnt
    FROM
    T_okex1 
    GROUP BY to1
 ) a
 LEFT JOIN
 name b
 ON 
 a.to1 = b.hash
ORDER BY 2 DESC;

                    to1                     |  cnt   |                   name                   
--------------------------------------------+--------+------------------------------------------
 0x6cc5f688a315f3dc28a7781717a9a798a59fda7b | 134845 | Okex1
 0xa7efae728d2936e78bda97dc267687568dd593f3 | 131526 | Okex3
 0xdac17f958d2ee523a2206206994597c13d831ec7 |  23220 | USDT
 0x8e1b448ec7adfc7fa35fc2e885678bd323176e34 |   3011 | 
 0x8b40761142b9aa6dc8964e61d0585995425c3d94 |   2708 | 
 0x11817afb29279703c5679959417015328ca6a0d1 |   2017 | 
 0x2008e3057bd734e10ad13c9eae45ff132abc1722 |   1961 | 
 0x1b793e49237758dbd8b752afc9eb4b329d5da016 |   1758 | 
 0x34364bee11607b1963d66bca665fde93fca666a8 |   1476 | 
 0x3495ffcee09012ab7d827abf3e3b3ae428a38443 |   1261 | 
 0x8a77e40936bbc27e80e9a3f526368c967869c86d |   1199 | 
 0x236f9f97e0e62388479bf9e5ba4889e46b0273c3 |   1194 | Okex2
 0xbe428c3867f05dea2a89fc76a102b544eac7f772 |    900 | 
 0x13f25cd52b21650caa8225c9942337d914c9b030 |    838 | 
 0xff603f43946a3a28df5e6a73172555d8c8b02386 |    835 | 
 0x4212fea9fec90236ecc51e41e2096b16ceb84555 |    827 | 
 0xa9d2927d3a04309e008b6af6e2e282ae2952e7fd |    813 | 
 0x75231f58b43240c9718dd58b4967c5114342a86c |    771 | 
 
 
二. okex2
0x236f9f97e0e62388479bf9e5ba4889e46b0273c3

postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1 ;
   count   
-----------
 661884304
 
postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1  where from1 = '0x236f9f97e0e62388479bf9e5ba4889e46b0273c3';
  count  
---------
 151063
(1 row)


postgres=#  SELECT count(*) from orc_t_ethereum_nm_ta1  where to1 = '0x236f9f97e0e62388479bf9e5ba4889e46b0273c3';
 count  
--------
 74100
(1 row)

postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1  where from1 = '0x236f9f97e0e62388479bf9e5ba4889e46b0273c3' and to1 
= '0x236f9f97e0e62388479bf9e5ba4889e46b0273c3';
 count 
-------
   0
(1 row)

Time: 406347.404 ms


--汇给okex2 交易所的过渡账户，去重
SELECT count(*) from
 (
 SELECT  from1, to1  
 FROM orc_t_ethereum_nm_ta1  
 where to1 = '0x236f9f97e0e62388479bf9e5ba4889e46b0273c3' and from1 != '0x236f9f97e0e62388479bf9e5ba4889e46b0273c3'
 GROUP BY from1, to1
 ) C;
 
 count  
--------
 24521
(1 row)


	
CREATE TABLE T_okex2(from1 TEXT, to1 TEXT) 
with (appendonly = true, orientation = orc, compresstype = lz4, dicthreshold = 0.8);


--汇给okex1 交易所的过渡账户的所有交易，去重
--68683
 INSERT INTO T_okex2
 SELECT
  from1, to1
  FROM orc_t_ethereum_nm_ta1
  where from1 IN (
  SELECT from1 
  FROM orc_t_ethereum_nm_ta1
  WHERE to1 = '0x236f9f97e0e62388479bf9e5ba4889e46b0273c3' and from1 != '0x236f9f97e0e62388479bf9e5ba4889e46b0273c3' 
  )GROUP BY from1, to1;
 
--结果
SELECT
 a.to1, 
 a.cnt,
 b.name
 FROM
 (
 SELECT
 to1, 
 count(to1) as cnt
 FROM
  T_okex2 
 GROUP BY to1
 ) a
 LEFT JOIN
 name b
 ON 
 a.to1 = b.hash
 ORDER BY 2 DESC;
 
                     to1                     |  cnt  |               name               
--------------------------------------------+-------+----------------------------------
 0x236f9f97e0e62388479bf9e5ba4889e46b0273c3 | 24521 | Okex2
 0x11817afb29279703c5679959417015328ca6a0d1 | 15321 | 未被标注但是和okex3有交易
 0x885a742719faf7ecc5670b16420a9487e9fbf625 |  1763 | 未被标注但是和okex有交易
 0x6cc5f688a315f3dc28a7781717a9a798a59fda7b |  1194 | Okex1
 0x519475b31653e46d20cd09f9fdcf3b12bdacb4f5 |  1180 | Viuly: Old Token
 0x86fa049857e0209aa7d9e616f7eb3b3b78ecfdb0 |   416 | EOS: Old Token
 0x3c4bea627039f0b7e7d21e34bb9c9fe962977518 |   190 | UCOT Token
 0x45245bc59219eeaaf6cd3f382e078a461ff9de7b |   128 | 合约账号，上游有很多交易所账号
 0x13f25cd52b21650caa8225c9942337d914c9b030 |   123 | 合约账号，上游有很多交易所账号
 0xbbbbca6a901c926f240b89eacb641d8aec7aeafd |   120 | Loopring: LRC Token 
 0x6ea6531b603f270d23d9edd2d8279135dc5d6773 |   115 | -
 0x8f136cc8bef1fea4a7b71aa2301ff1a52f084384 |    87 | -
 0x0b76544f6c413a555f309bf76260d1e02377c02a |    81 | InternetNodeToken
 0x9b20dabcec77f6289113e61893f7beefaeb1990a |    80 | 合约账号，上游有很多交易所账号
 
 
三. okex3
0xa7efae728d2936e78bda97dc267687568dd593f3

postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1 ;
   count   
-----------
 661884304
 
postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1  where from1 = '0xa7efae728d2936e78bda97dc267687568dd593f3';
  count  
---------
 182950
(1 row)


postgres=#  SELECT count(*) from orc_t_ethereum_nm_ta1  where to1 = '0xa7efae728d2936e78bda97dc267687568dd593f3';
 count  
--------
 401298
(1 row)

postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1  where from1 = '0xa7efae728d2936e78bda97dc267687568dd593f3' and to1 
= '0xa7efae728d2936e78bda97dc267687568dd593f3';
 count 
-------
   44
(1 row)


--汇给 okex3 交易所的过渡账户，去重
SELECT count(*) from
 (
 SELECT  from1, to1  
 FROM orc_t_ethereum_nm_ta1  
 where to1 = '0xa7efae728d2936e78bda97dc267687568dd593f3' and from1 != '0xa7efae728d2936e78bda97dc267687568dd593f3'
 GROUP BY from1, to1
 ) C;
 
 count  
--------
 166222
(1 row)


	
CREATE TABLE T_okex3(from1 TEXT, to1 TEXT) 
with (appendonly = true, orientation = orc, compresstype = lz4, dicthreshold = 0.8);


--汇给 okex3 交易所的过渡账户的所有交易，去重
--788036
 INSERT INTO T_okex3
 SELECT
  from1, to1
  FROM orc_t_ethereum_nm_ta1
  where from1 IN (
  SELECT from1 
  FROM orc_t_ethereum_nm_ta1
  WHERE to1 = '0xa7efae728d2936e78bda97dc267687568dd593f3' and from1 != '0xa7efae728d2936e78bda97dc267687568dd593f3' 
  )GROUP BY from1, to1;
 
--结果
SELECT
 a.to1, 
 a.cnt,
 b.name
 FROM
 (
 SELECT
 to1, 
 count(to1) as cnt
 FROM
  T_okex3 
 GROUP BY to1
 ) a
 LEFT JOIN
 name b
 ON 
 a.to1 = b.hash
 ORDER BY 2 DESC;

                    to1                     |  cnt   |                   name                   
--------------------------------------------+--------+------------------------------------------
 0xa7efae728d2936e78bda97dc267687568dd593f3 | 166222 | Okex3
 0x6cc5f688a315f3dc28a7781717a9a798a59fda7b | 131526 | Okex1
 0xdac17f958d2ee523a2206206994597c13d831ec7 |  33444 | USDT
 0x8e1b448ec7adfc7fa35fc2e885678bd323176e34 |   3263 | 合约账号，上游有很多交易所账号
 0x8b40761142b9aa6dc8964e61d0585995425c3d94 |   2737 | 合约账号，上游有很多交易所账号
 0x2008e3057bd734e10ad13c9eae45ff132abc1722 |   1981 | Zebi: Old Token
 0x34364bee11607b1963d66bca665fde93fca666a8 |   1919 | -
 0x1b793e49237758dbd8b752afc9eb4b329d5da016 |   1823 | -
 0x3495ffcee09012ab7d827abf3e3b3ae428a38443 |   1596 | 合约账号，上游有很多交易所账号
 0x8a77e40936bbc27e80e9a3f526368c967869c86d |   1298 | Merculet: Old MVP Token
 0x653430560be843c4a3d143d0110e896c2ab8ac0d |   1063 | Molecular Future Token
 0xbe428c3867f05dea2a89fc76a102b544eac7f772 |   1031 | CyberVein: CVT Token
 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48 |    985 | USD Coin
 0x1f9840a85d5af5bf1d1762f925bdaddc4201f984 |    952 | Uniswap Protocol: UNI token
 0xff603f43946a3a28df5e6a73172555d8c8b02386 |    913 | OneRoot: RNT Token
 0x4212fea9fec90236ecc51e41e2096b16ceb84555 |    892 | -
 0x13f25cd52b21650caa8225c9942337d914c9b030 |    888 | 合约账号，上游有很多交易所账号
 0x75231f58b43240c9718dd58b4967c5114342a86c |    875 | OKEx: OKB Token
 0xa9d2927d3a04309e008b6af6e2e282ae2952e7fd |    864 | Zipper Token
 0x4824a7b64e3966b0133f4f4ffb1b9d6beb75fff7 |    834 | TokenClub Token
 
 
 
四. huobi1  
0xaB5C66752a9e8167967685F1450532fB96d5d24f

postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1  where from1 = '0xaB5C66752a9e8167967685F1450532fB96d5d24f';
  count  
---------
 0
(1 row)


postgres=#  SELECT count(*) from orc_t_ethereum_nm_ta1  where to1 = '0xaB5C66752a9e8167967685F1450532fB96d5d24f';
 count  
--------
 0
(1 row)

postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1  where from1 = '0xaB5C66752a9e8167967685F1450532fB96d5d24f' and to1 
= '0xaB5C66752a9e8167967685F1450532fB96d5d24f';
 count 
-------
   0
(1 row)


五. huobi2
0x6748f50f686bfbca6fe8ad62b22228b87f31ff2b

postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1 ;
   count   
-----------
 661884304
 
postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1  where from1 = '0x6748f50f686bfbca6fe8ad62b22228b87f31ff2b';
  count  
---------
 1311947
(1 row)


postgres=#  SELECT count(*) from orc_t_ethereum_nm_ta1  where to1 = '0x6748f50f686bfbca6fe8ad62b22228b87f31ff2b';
 count  
--------
 264
(1 row)

postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1  where from1 = '0x6748f50f686bfbca6fe8ad62b22228b87f31ff2b' and to1 
= '0x6748f50f686bfbca6fe8ad62b22228b87f31ff2b';
 count 
-------
   0
(1 row)

--汇给huobi2 交易所的过渡账户，去重
SELECT count(*) from
 (
 SELECT  from1, to1  
 FROM orc_t_ethereum_nm_ta1  
 where to1 = '0x6748f50f686bfbca6fe8ad62b22228b87f31ff2b' and from1 != '0x6748f50f686bfbca6fe8ad62b22228b87f31ff2b'
 GROUP BY from1, to1
 ) C;
 
 count  
--------
 31
(1 row)

CREATE TABLE T_huobi2(from1 TEXT, to1 TEXT) 
with (appendonly = true, orientation = orc, compresstype = lz4, dicthreshold = 0.8);


--汇给okex1 交易所的过渡账户的所有交易，去重
--2041629
 INSERT INTO T_huobi2
 SELECT
  from1, to1
  FROM orc_t_ethereum_nm_ta1
  where from1 IN (
  SELECT from1 
  FROM orc_t_ethereum_nm_ta1
  WHERE to1 = '0x6748f50f686bfbca6fe8ad62b22228b87f31ff2b' and from1 != '0x6748f50f686bfbca6fe8ad62b22228b87f31ff2b' 
  )GROUP BY from1, to1;
 
--结果
SELECT
 a.to1, 
 a.cnt,
 b.name
 FROM
 (
 SELECT
 to1, 
 count(to1) as cnt
 FROM
  T_huobi2 
 GROUP BY to1
 ) a
 LEFT JOIN
 name b
 ON 
 a.to1 = b.hash
 ORDER BY 2 DESC;

                    to1                     | cnt |           name           
--------------------------------------------+-----+--------------------------
 0x6748f50f686bfbca6fe8ad62b22228b87f31ff2b |  31 | Huobi2  
 0xab5c66752a9e8167967685f1450532fb96d5d24f |  19 | Huobi1  
 0x46705dfff24256421a05d056c29e81bdc09723b8 |  18 | Huobi12
 0xeec606a66edb6f497662ea31b5eb1610da87ab5f |  17 | Huobi16
 0xadb2b42f6bd96f5c65920b9ac88619dce4166f94 |  16 | Huobi7  
 0xeee28d484628d41a82d01e21d12e2e78d69920da |  15 | Huobi4  
 0x1062a747393198f70f71ec65a582423dba7e5ab3 |  14 | Huobi9  
 0x0a98fb70939162725ae66e626fe4b52cff62c2e5 |  14 | Huobi36
 0xe93381fb4c4f14bda253907b18fad305d799241a |  14 | Huobi10
 0xfdb16996831753d5331ff813c29a93c76834a0ad |  13 | Huobi3  
 0x8e4b72fa2cb384ce55447d47afbc280dbcdab8fa |  12 | -
 0x4b8a339be06ff31752a806995b72e76e93dd9106 |  12 | 上游类似交易所，下游大部分是合约TOken
 0x9a5b7bfd17857f1148292b61e092296255db84c0 |  12 | 合约账号，上游有很多交易所账号
 0x3f8621f995dce20f444331eb4fd6fc2c0a93c90f |  12 | 合约账号，上游有很多交易所账号
 0xdac17f958d2ee523a2206206994597c13d831ec7 |  12 | Tether: USDT Stablecoin
 0x6ecbe2cba8adb756a7ac74beac87c422ead8d496 |  12 | 上下游都有合约账号和类似交易所账号
 0xca1caf2222eea0e046e0f653e647566d8d18df95 |  12 | 下游大部分是TOken
 0x2bde5d7733a578c3ff1c79c25b990917b316d084 |  12 | -
 0x1f97505874067e5c926b4e40d0524d4fe0fdbc62 |  12 | 下游大部分是TOken
 0xd4db7ff4c078f73203913e27a90af39226086c87 |  12 | 
 0xe5782724e87bcd5a1f48737ff6cfeaf875ab5873 |  12 | 
 0x5c985e89dde482efe97ea9f1950ad149eb73829b |  12 | Huobi5  
 
六. Binance
0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be

postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1 ;
   count   
-----------
 661884304
 
postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1  where from1 = '0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be';
  count  
---------
 3136598
(1 row)


postgres=#  SELECT count(*) from orc_t_ethereum_nm_ta1  where to1 = '0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be';
 count  
--------
 4067381
(1 row)

postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1  where from1 = '0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be' and to1 
= '0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be';
 count 
-------
   233
(1 row)



--汇给Binance 交易所的过渡账户，去重
SELECT count(*) from
 (
 SELECT  from1, to1  
 FROM orc_t_ethereum_nm_ta1  
 where to1 = '0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be' and from1 != '0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be'
 GROUP BY from1, to1
 ) C;
 
 count  
--------
 924413
(1 row)


	
CREATE TABLE T_Binance(from1 TEXT, to1 TEXT) 
with (appendonly = true, orientation = orc, compresstype = lz4, dicthreshold = 0.8);


--汇给 Binance 交易所的过渡账户的所有交易，去重
--1945010
 INSERT INTO T_Binance
 SELECT
  from1, to1
  FROM orc_t_ethereum_nm_ta1
  where from1 IN (
  SELECT from1 
  FROM orc_t_ethereum_nm_ta1
  WHERE to1 = '0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be' and from1 != '0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be' 
  )GROUP BY from1, to1;
 
--结果
SELECT
 a.to1, 
 a.cnt,
 b.name
 FROM
 (
 SELECT
 to1, 
 count(to1) as cnt
 FROM
  T_Binance 
 GROUP BY to1
 ) a
 LEFT JOIN
 name b
 ON 
 a.to1 = b.hash
 ORDER BY 2 DESC;

                    to1                     |  cnt   |                   name                   
--------------------------------------------+--------+------------------------------------------
 0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be | 924413 | Binance
 0xdac17f958d2ee523a2206206994597c13d831ec7 |  92429 | 
 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48 |  28698 | 
 0xb8c77482e45f1f44de1745f52c74426c631bdd52 |  24921 | Binance: BNB Token
 0xe41d2489571d322189246dafa5ebde1f4699f498 |  23791 | 
 0x1f9840a85d5af5bf1d1762f925bdaddc4201f984 |  23194 | 
 0x514910771af9ca656af840dff83e8264ecf986ca |  20513 | 
 0x0d8775f648430679a709e98d2b0cb6250d2887ef |  20451 | 
 0xa15c7ebe1f07caf6bff097d8a589fb8ac49ae5b3 |  18315 | 
 0xd26114cd6ee289accf82350c8d8487fedb8a0c07 |  18293 | 
 0x6c6ee5e31d828de241282b9606c8e98ea48526e2 |  15186 | 
 0x05f4a42e251f2d52b8ed15e9fedaacfcef1fad27 |  14358 | 
 0xd850942ef8811f2a866692a623011bde52a462c1 |  11229 | 
 0xf629cbd94d3791c9250152bd8dfbdf380e2a3b9c |  10355 | 
 0x0000000000085d4780b73119b644ae5ecd22b376 |  10216 | 
 0xf230b790e05390fc8295f4d3f60332c93bed42e2 |  10158 | 
 0x809826cceab68c387726af962713b64cb5cb3cca |   7910 | 
 0xdd974d5c2e2928dea5f71b9825b8b646686bd200 |   7829 | 
 0x9992ec3cf6a55b00978cddf2b27bc6882d88d1ec |   7751 | 
 0xa74476443119a942de498590fe1f2454d7d4ac0d |   7502 | 
 0xf0ee6b27b759c9893ce4f094b49ad28fd15a23e4 |   6922 | 
 0x595832f8fc6bf59c85c527fec3740a1b7a361269 |   6887 | 
 0x80fb784b7ed66730e8b1dbd9820afd29931aab03 |   6755 | 
 0x3597bfd533a99c9aa083587b074434e61eb0a258 |   6235 | 
 0xb63b606ac810a52cca15e44bb630fd42d8d1d83d |   5884 | 
 0x0f5d2fb29fb7d3cfee444a200298f468908cc942 |   5532 | 
 0x8e870d67f660d95d5be530380d0ec0bd388289e1 |   5354 | 
 0x5732046a883704404f284ce41ffadd5b007fd668 |   5295 | 
 0x1985365e9f78359a9b6ad760e32412f4a445e862 |   5287 | 
 0xfa1a856cfa3409cfa145fa4e20eb270df3eb21ab |   5197 | 
 0xea26c4ac16d4a5a106820bc8aee85fd0b7b2b664 |   5044 | 
 0x8f8221afbb33998d8584a2b05749ba73c37a938a |   4985 | 
 0x0abdace70d3790235af448c88547603b945604ea |   4885 | 
 0x5af2be193a6abca9c8817001f45744777db30756 |   4821 | 
 0x744d70fdbe2ba4cf95131626614a1763df805b9e |   4780 | 
 0x41e5560054824ea6b0732e656e3ad64e20e94e45 |   4775 | 
 0x419d0d8bdd9af5e606ae2232ed285aff190e711b |   4619 | 
 0xb7cb1c96db6b22b0d3d9536e0108d062bd488f74 |   4513 | 
 0x408e41876cccdc0f92210600ef50372656052a38 |   4482 | 
 0x6b175474e89094c44da98b954eedeac495271d0f |   4446 | 
 0x4e15361fd6b4bb609fa63c81a2be19d873717870 |   4419 | 
 0xd4c435f5b09f855c3317c8524cb1f586e42795fa |   4419 | 
 0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0 |   4388 | 
 0x4dc3643dbc642b72c158e7f3d2ff232df61cb6ce |   4341 | 
 0xbf2179859fc6d5bee9bf9158632dc51678a4100e |   4147 | 
 0xf85feea2fdd81d51177f6b8f35f0e6734ce45f5f |   4079 | 
 0x0e0989b1f9b8a38983c2ba8053269ca62ec9b195 |   4011 | 
 0x8eb24319393716668d768dcec29356ae9cffe285 |   3978 | 
 0xa4e8c3ec456107ea67d3075bf9e3df3a75823db0 |   3971 | 
 0xd4fa1460f537bb9085d22c7bccb5dd450ef28e3a |   3954 | 
 0x4ceda7906a5ed2179785cd3a40a69ee8bc99c466 |   3927 | 
 0x1f573d6fb3f13d689ff844b4ce37794d79a7ff1c |   3893 | 
 0x8207c1ffc5b6804f6024322ccf34f29c3541ae26 |   3879 | 
 0x08f5a9235b08173b7569f83645d2c7fb55e8ccd8 |   3865 | 
 0x5b2e4a700dfbc560061e957edec8f6eeeb74a320 |   3616 | 
 0x4156d3342d5c385a87d264f90653733592000581 |   3601 | 
 0x8ce9137d39326ad0cd6491fb5cc0cba0e089b6a9 |   3566 | 
 0x5ca9a71b1d01849c0a95490cc00559717fcf0d1d |   3565 | 
 0xef68e7c694f40c8202821edf525de3782458639f |   3433 | 
 0x99ea4db9ee77acd40b119bd1dc4e33e1c070b80d |   3422 | 
 0xdf2c7238198ad8b389666574f2d8bc411a4b7428 |   3368 | 
 0x1d287cc25dad7ccaf76a26bc660c5f7c8e2a05bd |   3315 | 
 0x86fa049857e0209aa7d9e616f7eb3b3b78ecfdb0 |   3258 | 
 0xf433089366899d83a9f26a773d59ec7ecf30355e |   3193 | 
 0x6fb3e0a217407efff7ca062d46c26e5d60a14d69 |   3168 | 
 0x4470bb87d77b963a013db939be332f927f2b992e |   3162 | 
 0xd0a4b8946cb52f0661273bfbc6fd0e0c75fc6433 |   3108 | 
 0x607f4c5bb672230e8672085532f7e901544a7375 |   3103 | 
 0x3883f5e181fccaf8410fa61e12b59bad963fb645 |   3014 | 
 0xe5dada80aa6477e85d09747f2842f7993d0df71c |   2970 | 
 0x558ec3152e2eb2174905cd19aea4e34a23de9ad6 |   2968 | 
 0x103c3a209da59d3e7c4a89307e66521e081cfdf0 |   2943 | 
 0x8dd5fbce2f6a956c3022ba3663759011dd51e73e |   2938 | 
 0x0b95993a39a363d99280ac950f5e4536ab5c5566 |   2821 | Binance: Contract               
 0xb64ef51c888972c908cfacf59b47c1afbc0ab8ac |   2755 | 
 0x27054b13b1b798b345b591a4d22e6562d47ea75a |   2749 | 
 0xb5a73f5fc8bbdbce59bfd01ca8d35062e0dad801 |   2746 | 
 0x4f9254c83eb525f9fcf346490bbb3ed28a81c667 |   2602 | 
 0x3506424f91fd33084466f402d5d97f05f8e3b4af |   2577 | 
 0x4cf488387f035ff08c371515562cba712f9015d4 |   2547 | 
 0x0cf0ee63788a0849fe5297f3407f701e122cc023 |   2476 | 
 0xf3db5fa2c66b7af3eb0c0b782510816cbe4813b8 |   2392 | 
 0x1a7a8bd9106f2b8d977e08582dc7d24c723ab0db |   2386 | 
 0x6b3595068778dd592e39a122f4f5a5cf09c90fe2 |   2332 | 
 0xc5bbae50781be1669306b9e001eff57a2957b09d |   2320 | 
 0xba11d00c5f74255f56a5e366f4f77f5a186d7f55 |   2289 | 
 0x8d75959f1e61ec2571aa72798237101f084de63a |   2215 | 
 0xe0b7927c4af23765cb51314a0e0521a9645f0e2a |   2147 | 
 0xba5f11b16b155792cf3b2e6880e8706859a8aeb6 |   2135 | 
 0xaf4dce16da2877f8c9e00544c93b62ac40631f16 |   2102 | 
 0x4cc19356f2d37338b9802aa8e8fc58b0373296e7 |   2008 | 
 0xd533a949740bb3306d119cc777fa900ba034cd52 |   1981 | 
 0x1c4481750daa5ff521a2a7490d9981ed46465dbd |   1978 | 
 0x12480e24eb5bec1a9d4369cab6a80cad3c0a377a |   1963 | 
 0x255aa6df07540cb5d3d297f0d0d4d84cb52bc8e6 |   1953 | 
 0x5cf04716ba20127f1e2297addcf4b5035000c9eb |   1952 | 
 0x2c4e8f2d746113d0696ce89b35f0d8bf88e0aeca |   1940 | 
 0xc00e94cb662c3520282e6f5717214004a7f26888 |   1909 | 
 0xf9986d445ced31882377b5d6a5f58eaea72288c3 |   1875 | 
 0x4fabb145d64652a948d72533023f6e7a623c7c53 |   1875 | BinanceUSD         


七. Binance2
0xd551234ae421e3bcba99a0da6d736074f22192ff

postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1 ;
   count   
-----------
 661884304
 
postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1  where from1 = '0xd551234ae421e3bcba99a0da6d736074f22192ff';
  count  
---------
 2255596
(1 row)


postgres=#  SELECT count(*) from orc_t_ethereum_nm_ta1  where to1 = '0xd551234ae421e3bcba99a0da6d736074f22192ff';
 count  
--------
 1913
(1 row)

postgres=# SELECT count(*) from orc_t_ethereum_nm_ta1  where from1 = '0xd551234ae421e3bcba99a0da6d736074f22192ff' and to1 
= '0xd551234ae421e3bcba99a0da6d736074f22192ff';
 count 
-------
   199
(1 row)


--汇给Binance2 交易所的过渡账户，去重
SELECT count(*) from
 (
 SELECT  from1, to1  
 FROM orc_t_ethereum_nm_ta1  
 where to1 = '0xd551234ae421e3bcba99a0da6d736074f22192ff' and from1 != '0xd551234ae421e3bcba99a0da6d736074f22192ff'
 GROUP BY from1, to1
 ) C;
 
 count  
--------
 158
(1 row)


	
CREATE TABLE T_Binance2(from1 TEXT, to1 TEXT) 
with (appendonly = true, orientation = orc, compresstype = lz4, dicthreshold = 0.8);


--汇给okex1 交易所的过渡账户的所有交易，去重
--1363948
 INSERT INTO T_Binance2
 SELECT
  from1, to1
  FROM orc_t_ethereum_nm_ta1
  where from1 IN (
  SELECT from1 
  FROM orc_t_ethereum_nm_ta1
  WHERE to1 = '0xd551234ae421e3bcba99a0da6d736074f22192ff' and from1 != '0xd551234ae421e3bcba99a0da6d736074f22192ff' 
  )GROUP BY from1, to1;
 
--结果
SELECT
 a.to1, 
 a.cnt,
 b.name
 FROM
 (
 SELECT
 to1, 
 count(to1) as cnt
 FROM
  T_Binance2 
 GROUP BY to1
 ) a
 LEFT JOIN
 name b
 ON 
 a.to1 = b.hash
 ORDER BY 2 DESC;
 
                    to1                     | cnt |                   name                   
--------------------------------------------+-----+------------------------------------------
 0xd551234ae421e3bcba99a0da6d736074f22192ff | 158 | Binance2        
 0x54ae4ccb5378b8b7f03c8bbf450d36278262a196 |  46 | 
 0x7a250d5630b4cf539739df2c5dacb4c659f2488d |  14 | 
 0x1f9840a85d5af5bf1d1762f925bdaddc4201f984 |  12 | 
 0x090d4613473dee047c3f2706764f49e0821d256e |  10 | 
 0xdac17f958d2ee523a2206206994597c13d831ec7 |  10 | 
 0x0681d8db095565fe8a346fa0277bffde9c0edbbf |   7 | Binance4        
 0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be |   7 | Binance
 0x6b175474e89094c44da98b954eedeac495271d0f |   7 | 
 0x564286362092d8e7936f0549571a803b203aaced |   6 | Binance3
 0x2a0c0dbecc7e4d658f48e01e3fa353f44050c208 |   6 | 
 0xa15c7ebe1f07caf6bff097d8a589fb8ac49ae5b3 |   5 | 
 0xe64fd7b0bbfe2a6cb7a61e63fe43f49507f87bab |   5 | 
 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48 |   5 | 
 0xd26114cd6ee289accf82350c8d8487fedb8a0c07 |   5 | 
 0x69c71dafe921a01b1200539f7504b3137417e532 |   5 | 
 0x5385c5697ee0ea3973ec269f74f1b7ae6f9f3a2b |   5 | 
 0xd094b3342afe70fa9d325017ab97710528f7eed3 |   4 | 
 0x1709c0de7225507104015461061e1efdede94038 |   4 | 
 0x350b6697d15cabe9a5117644aedbd17e39cf6ace |   4 | 
 0x6e83e4954e0617647137b7d3c85671bbbf7f331d |   4 | 