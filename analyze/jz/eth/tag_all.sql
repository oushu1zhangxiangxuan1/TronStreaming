CREATE TABLE tag_all
(
 address text,
 tag_name text
)
with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

--1. okex
insert into tag_all values
('0x6cc5f688a315f3dc28a7781717a9a798a59fda7b' , 'okex_pool'),
('0x236f9f97e0e62388479bf9e5ba4889e46b0273c3' , 'okex_pool'),
('0xa7efae728d2936e78bda97dc267687568dd593f3' , 'okex_pool'),
('0x5041ed759dd4afc3a72b8192c143f72f4724081a' , 'okex_pool'),
('0x11817afb29279703c5679959417015328ca6a0d1' , 'okex_pool'),
('0xdec87ed2dcdf63043917df0712a5f8866e12cc24' , 'okex_pool');


--1.1 根据充币表的交易hash查出过渡地址
 SELECT
  to1
  FROM
  orc_t_ethereum_nmta a
  WHERE EXISTS(
  SELECT 1
  FROM okex_deposit_txid_eth b
  WHERE a.transactionHash = b.lower
  )
  GROUP BY to1;
  
 0xda7e4d200e594738aaddd0715b97d8ec19b816ac
 0xa00a186a9ac56ddb39b4e0741fc72fb903db4751
 0xdac17f958d2ee523a2206206994597c13d831ec7
 0xe6fcc5cbde8867d653e213280e86101972005073
 0xa5b5435879607bd16b2caa8eec19b7612de7a29a
 0xeb3b6fee0b1022a3a0e31ccaa5615af2cdd8fb29
 
 --1.2 根据过渡地址查出okex_pool
 SELECT
 to1
 FROM
 orc_t_ethereum_nmta  
 WHERE
 from1 in
 (
   SELECT
  to1
  FROM
  orc_t_ethereum_nmta a
  WHERE EXISTS(
  SELECT 1
  FROM okex_deposit_txid_eth b
  WHERE a.transactionHash = b.lower
  )
  GROUP BY to1
 )
 GROUP BY to1;
 
 0x6cc5f688a315f3dc28a7781717a9a798a59fda7b 在已知的okex_pool中
 0xa7efae728d2936e78bda97dc267687568dd593f3 在已知的okex_pool中
 0xdac17f958d2ee523a2206206994597c13d831ec7 USDT
  
--1.3 根据提币表的交易hash查出from1作为okex_pool
SELECT 
 from1
 FROM 
  orc_t_ethereum_nmta a
 WHERE EXISTS
 (
  SELECT 1
  FROM okex_withdraw_txid_eth b
  WHERE a.transactionHash = b.lower
 )
 GROUP BY from1;
 
--结果都在已知的okex_pool中：
 0x6cc5f688a315f3dc28a7781717a9a798a59fda7b
 0x5041ed759dd4afc3a72b8192c143f72f4724081a
 0x11817afb29279703c5679959417015328ca6a0d1
 0xa7efae728d2936e78bda97dc267687568dd593f3
 
 
 --1.4 给过渡地址打 okex 标签
INSERT INTO tag_all
 SELECT
  from1, 'okex'
  FROM
  orc_t_ethereum_nmta
  WHERE 
  to1 in (
	'0x6cc5f688a315f3dc28a7781717a9a798a59fda7b',
    '0x236f9f97e0e62388479bf9e5ba4889e46b0273c3',
    '0xa7efae728d2936e78bda97dc267687568dd593f3',
	'0x5041ed759dd4afc3a72b8192c143f72f4724081a', 
	'0x11817afb29279703c5679959417015328ca6a0d1',
    '0xdec87ed2dcdf63043917df0712a5f8866e12cc24'    
   )
  AND 
  from1 not in (
	'0x6cc5f688a315f3dc28a7781717a9a798a59fda7b',
    '0x236f9f97e0e62388479bf9e5ba4889e46b0273c3',
    '0xa7efae728d2936e78bda97dc267687568dd593f3',
	'0x5041ed759dd4afc3a72b8192c143f72f4724081a', 
	'0x11817afb29279703c5679959417015328ca6a0d1',
    '0xdec87ed2dcdf63043917df0712a5f8866e12cc24'    
 );
--1611431
 
--2. binance
INSERT INTO tag_all values
('0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be' , 'binance_pool'),
('0x85b931a32a0725be14285b66f1a22178c672d69b' , 'binance_pool'),
('0x708396f17127c42383e3b9014072679b2f60b82f' , 'binance_pool'),
('0xe0f0cfde7ee664943906f17f7f14342e76a5cec7' , 'binance_pool'),
('0x8f22f2063d253846b53609231ed80fa571bc0c8f' , 'binance_pool'),
('0x28c6c06298d514db089934071355e5743bf21d60' , 'binance_pool'),
('0x21a31ee1afc51d94c2efccaa2092ad1028285549' , 'binance_pool'),
('0xdfd5293d8e347dfe59e90efd55b2956a1343963d' , 'binance_pool'),
('0x56eddb7aa87536c09ccc2793473599fd21a8b17f' , 'binance_pool'),
('0x9696f59e4d72e237be84ffd425dcad154bf96976' , 'binance_pool'),
('0xd551234ae421e3bcba99a0da6d736074f22192ff' , 'binance_pool'),
('0x564286362092d8e7936f0549571a803b203aaced' , 'binance_pool'),
('0x0681d8db095565fe8a346fa0277bffde9c0edbbf' , 'binance_pool'),
('0xfe9e8709d3215310075d67e3ed32a380ccf451c8' , 'binance_pool'),
('0x4e9ce36e442e55ecd9025b9a6e0d88485d628a67' , 'binance_pool'),
('0xbe0eb53f46cd790cd13851d5eff43d12404d33e8' , 'binance_pool'),
('0xf977814e90da44bfa03b6295a0616a897441acec' , 'binance_pool'),
('0x001866ae5b3de6caa5a51543fd9fb64f524f5478' , 'binance_pool');


--2.1 根据充币表的交易hash查出过渡地址
 SELECT
  to1
  FROM
  orc_t_ethereum_nmta a
  WHERE EXISTS(
  SELECT 1
  FROM binance_deposit_txid_eth b
  WHERE a.transactionHash = b.lower
  )
  GROUP BY to1;
  
0xdd1e17e5ca0d0db87d1eb2e6a700fc45bd8683c7
0x967da4048cd07ab37855c090aaf366e4ce1b9f48
0xdac17f958d2ee523a2206206994597c13d831ec7
0x15c8fdd0eeb7537e24e72f0aaef0c65c52f487fe
0xb8baa0e4287890a5f79863ab62b7f175cecbd433
0x7f543404a7d62f82842efd56398366590b137b7a
0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48
 
--2.2 根据过渡地址查出 binance_pool
 SELECT
 to1
 FROM
 orc_t_ethereum_nmta  
 WHERE
 from1 in
 (
   SELECT
  to1
  FROM
  orc_t_ethereum_nmta a
  WHERE EXISTS(
  SELECT 1
  FROM binance_deposit_txid_eth b
  WHERE a.transactionHash = b.lower
  )
  GROUP BY to1
 )
 GROUP BY to1;
 
 0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be  已知
 0xb8baa0e4287890a5f79863ab62b7f175cecbd433  SWRV Token
 0xdac17f958d2ee523a2206206994597c13d831ec7  USDT
 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48  USDcoin
  
--2.3 根据提币表的交易hash查出from1作为 binance_pool
SELECT 
 from1
 FROM 
  orc_t_ethereum_nmta a
 WHERE EXISTS
 (
  SELECT 1
  FROM binance_withdraw_txid_eth b
  WHERE a.transactionHash = b.lower
 )
 GROUP BY from1;
 
--结果都在已知的 binance_pool 中：
 0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be
 0x85b931a32a0725be14285b66f1a22178c672d69b
 0x0681d8db095565fe8a346fa0277bffde9c0edbbf
 0xe0f0cfde7ee664943906f17f7f14342e76a5cec7
 0x564286362092d8e7936f0549571a803b203aaced
 0xd551234ae421e3bcba99a0da6d736074f22192ff
 0x708396f17127c42383e3b9014072679b2f60b82f
 
--2.4 给过渡地址打 okex 标签
INSERT INTO tag_all
 SELECT
  from1, 'binance'
  FROM
  orc_t_ethereum_nmta
  WHERE 
  to1 in (
'0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be' ,
'0x85b931a32a0725be14285b66f1a22178c672d69b' ,
'0x708396f17127c42383e3b9014072679b2f60b82f' ,
'0xe0f0cfde7ee664943906f17f7f14342e76a5cec7' ,
'0x8f22f2063d253846b53609231ed80fa571bc0c8f' ,
'0x28c6c06298d514db089934071355e5743bf21d60' ,
'0x21a31ee1afc51d94c2efccaa2092ad1028285549' ,
'0xdfd5293d8e347dfe59e90efd55b2956a1343963d' ,
'0x56eddb7aa87536c09ccc2793473599fd21a8b17f' ,
'0x9696f59e4d72e237be84ffd425dcad154bf96976' ,
'0xd551234ae421e3bcba99a0da6d736074f22192ff' ,
'0x564286362092d8e7936f0549571a803b203aaced' ,
'0x0681d8db095565fe8a346fa0277bffde9c0edbbf' ,
'0xfe9e8709d3215310075d67e3ed32a380ccf451c8' ,
'0x4e9ce36e442e55ecd9025b9a6e0d88485d628a67' ,
'0xbe0eb53f46cd790cd13851d5eff43d12404d33e8' ,
'0xf977814e90da44bfa03b6295a0616a897441acec' ,
'0x001866ae5b3de6caa5a51543fd9fb64f524f5478'
)
AND 
from1 not in
(
'0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be' ,
'0x85b931a32a0725be14285b66f1a22178c672d69b' ,
'0x708396f17127c42383e3b9014072679b2f60b82f' ,
'0xe0f0cfde7ee664943906f17f7f14342e76a5cec7' ,
'0x8f22f2063d253846b53609231ed80fa571bc0c8f' ,
'0x28c6c06298d514db089934071355e5743bf21d60' ,
'0x21a31ee1afc51d94c2efccaa2092ad1028285549' ,
'0xdfd5293d8e347dfe59e90efd55b2956a1343963d' ,
'0x56eddb7aa87536c09ccc2793473599fd21a8b17f' ,
'0x9696f59e4d72e237be84ffd425dcad154bf96976' ,
'0xd551234ae421e3bcba99a0da6d736074f22192ff' ,
'0x564286362092d8e7936f0549571a803b203aaced' ,
'0x0681d8db095565fe8a346fa0277bffde9c0edbbf' ,
'0xfe9e8709d3215310075d67e3ed32a380ccf451c8' ,
'0x4e9ce36e442e55ecd9025b9a6e0d88485d628a67' ,
'0xbe0eb53f46cd790cd13851d5eff43d12404d33e8' ,
'0xf977814e90da44bfa03b6295a0616a897441acec' ,
'0x001866ae5b3de6caa5a51543fd9fb64f524f5478' 
);
--INSERT 0 8503418

--3. huobi
INSERT INTO tag_all values
('0xab5c66752a9e8167967685f1450532fb96d5d24f' , 'huobi_pool'),	
('0x6748f50f686bfbca6fe8ad62b22228b87f31ff2b' , 'huobi_pool'),	
('0xfdb16996831753d5331ff813c29a93c76834a0ad' , 'huobi_pool'),	
('0xeee28d484628d41a82d01e21d12e2e78d69920da' , 'huobi_pool'),	
('0x5c985e89dde482efe97ea9f1950ad149eb73829b' , 'huobi_pool'),	
('0xdc76cd25977e0a5ae17155770273ad58648900d3' , 'huobi_pool'),	
('0xadb2b42f6bd96f5c65920b9ac88619dce4166f94' , 'huobi_pool'),	
('0xa8660c8ffd6d578f657b72c0c811284aef0b735e' , 'huobi_pool'),	
('0x1062a747393198f70f71ec65a582423dba7e5ab3' , 'huobi_pool'),	
('0xe93381fb4c4f14bda253907b18fad305d799241a' , 'huobi_pool'),
('0xfa4b5be3f2f84f56703c42eb22142744e95a2c58' , 'huobi_pool'),
('0x46705dfff24256421a05d056c29e81bdc09723b8' , 'huobi_pool'),
('0x32598293906b5b17c27d657db3ad2c9b3f3e4265' , 'huobi_pool'),
('0x5861b8446a2f6e19a067874c133f04c578928727' , 'huobi_pool'),
('0x926fc576b7facf6ae2d08ee2d4734c134a743988' , 'huobi_pool'),
('0xeec606a66edb6f497662ea31b5eb1610da87ab5f' , 'huobi_pool'),
('0x7ef35bb398e0416b81b019fea395219b65c52164' , 'huobi_pool'),
('0x229b5c097f9b35009ca1321ad2034d4b3d5070f6' , 'huobi_pool'),
('0xd8a83b72377476d0a66683cde20a8aad0b628713' , 'huobi_pool'),
('0x90e9ddd9d8d5ae4e3763d0cf856c97594dea7325' , 'huobi_pool'),
('0x18916e1a2933cb349145a280473a5de8eb6630cb' , 'huobi_pool'),
('0x6f48a3e70f0251d1e83a989e62aaa2281a6d5380' , 'huobi_pool'),
('0xf056f435ba0cc4fcd2f1b17e3766549ffc404b94' , 'huobi_pool'),
('0x137ad9c4777e1d36e4b605e745e8f37b2b62e9c5' , 'huobi_pool'),
('0x5401dbf7da53e1c9dbf484e3d69505815f2f5e6e' , 'huobi_pool'),
('0x034f854b44d28e26386c1bc37ff9b20c6380b00d' , 'huobi_pool'), 
('0x0577a79cfc63bbc0df38833ff4c4a3bf2095b404' , 'huobi_pool'),
('0x0c6c34cdd915845376fb5407e0895196c9dd4eec' , 'huobi_pool'),
('0x794d28ac31bcb136294761a556b68d2634094153' , 'huobi_pool'),
('0xfd54078badd5653571726c3370afb127351a6f26' , 'huobi_pool'),
('0xb4cd0386d2db86f30c1a11c2b8c4f4185c1dade9' , 'huobi_pool'),
('0x4d77a1144dc74f26838b69391a6d3b1e403d0990' , 'huobi_pool'),
('0x28ffe35688ffffd0659aee2e34778b0ae4e193ad' , 'huobi_pool'),
('0xcac725bef4f114f728cbcfd744a731c2a463c3fc' , 'huobi_pool'),
('0x73f8fc2e74302eb2efda125a326655acf0dc2d1b' , 'huobi_pool'),
('0x0a98fb70939162725ae66e626fe4b52cff62c2e5' , 'huobi_pool'),
('0xf66852bc122fd40bfecc63cd48217e88bda12109' , 'huobi_pool');

INSERT INTO tag_all values
('0x1d1e10e8c66b67692f4c002c0cb334de5d485e41' , 'huobi_pool_old'), 
('0x1b93129f05cc2e840135aab154223c75097b69bf' , 'huobi_pool_old'),
('0xeb6d43fe241fb2320b5a3c9be9cdfd4dd8226451' , 'huobi_pool_old'),
('0x956e0dbecc0e873d34a5e39b25f364b2ca036730' , 'huobi_pool_old'),
('0x6f50c6bff08ec925232937b204b0ae23c488402a' , 'huobi_pool_old'),
('0xdf95de30cdff4381b69f9e4fa8dddce31a0128df' , 'huobi_pool_old'),
('0x25c6459e5c5b01694f6453e8961420ccd1edf3b1' , 'huobi_pool_old'),
('0x04645af26b54bd85dc02ac65054e87362a72cb22' , 'huobi_pool_old'),
('0xb2a48f542dc56b89b24c04076cbe565b3dc58e7b' , 'huobi_pool_old'),
('0xea0cfef143182d7b9208fbfeda9d172c2aced972' , 'huobi_pool_old'),
('0x0c92efa186074ba716d0e2156a6ffabd579f8035' , 'huobi_pool_old'),
('0x91dfa9d9e062a50d2f351bfba0d35a9604993dac' , 'huobi_pool_old'),
('0x8e8bc99b79488c276d6f3ca11901e9abd77efea4' , 'huobi_pool_old'),
('0xb9a4873d8d2c22e56b8574e8605644d08e047549' , 'huobi_pool_old'),
('0x170af0a02339743687afd3dc8d48cffd1f660728' , 'huobi_pool_old'),
('0xf775a9a0ad44807bc15936df0ee68902af1a0eee' , 'huobi_pool_old'),
('0x75a83599de596cbc91a1821ffa618c40e22ac8ca' , 'huobi_pool_old'),
('0x48ab9f29795dfb44b36587c50da4b30c0e84d3ed' , 'huobi_pool_old'),
('0x90f49e24a9554126f591d28174e157ca267194ba' , 'huobi_pool_old'),
('0xe3314bbf3334228b257779e28228cfb86fa4261b' , 'huobi_pool_old'),
('0x6edb9d6547befc3397801c94bb8c97d2e8087e2f' , 'huobi_pool_old'),
('0x8aabba0077f1565df73e9d15dd3784a2b0033dad' , 'huobi_pool_old'),
('0xd3a2f775e973c1671f2047e620448b8662dcd3ca' , 'huobi_pool_old'),
('0x1c515eaa87568c850043a89c2d2c2e8187adb056' , 'huobi_pool_old'),
('0x60b45f993223dcb8bdf05e3391f7630e5a51d787' , 'huobi_pool_old'),
('0xa23d7dd4b8a1060344caf18a29b42350852af481' , 'huobi_pool_old'),
('0x9eebb2815dba2166d8287afa9a2c89336ba9deaa' , 'huobi_pool_old'),
('0xd10e08325c0e95d59c607a693483680fe5b755b3' , 'huobi_pool_old'),
('0xc837f51a0efa33f8eca03570e3d01a4b2cf97ffd' , 'huobi_pool_old'),
('0xf7a8af16acb302351d7ea26ffc380575b741724c' , 'huobi_pool_old'),
('0x636b76ae213358b9867591299e5c62b8d014e372' , 'huobi_pool_old'),
('0x9a755332d874c893111207b0b220ce2615cd036f' , 'huobi_pool_old'),
('0xecd8b3877d8e7cd0739de18a5b545bc0b3538566' , 'huobi_pool_old'),
('0xef54f559b5e3b55b783c7bc59850f83514b6149c' , 'huobi_pool_old');

INSERT INTO tag_all values
('0xd19141a9b74f7a02cc2b4919039f2961e988732f' , 'huobi_pool'), 
('0x1ff41b4d3db633f91cfa29d4bf8cff8903edefe2' , 'huobi_pool');


INSERT INTO tag_all values
 ('0xf5613e4da78cee6a1bffdf9c235d56bbf6d01d8d' , 'huobi_pool'),
 ('0x39d9f4640b98189540a9c0edcfa95c5e657706aa' , 'huobi_pool'),
 ('0x86e6df2933f88a00caa11ad19413123c3abef3de' , 'huobi_pool'),
 ('0x3c979fb790c86e361738ed17588c1e8b4c4cc49a' , 'huobi_pool'),
 ('0xe21bc8d4f47dbd9e4dd29229333d1999c33d0e87' , 'huobi_pool'),
 ('0x27e9f4748a2eb776be193a1f7dec2bb6daafe9cf' , 'huobi_pool'),
 ('0xf726dc178d1a4d9292a8d63f01e0fa0a1235e65c' , 'huobi_pool'),
 ('0x58c2cb4a6bee98c309215d0d2a38d7f8aa71211c' , 'huobi_pool'),
 ('0xeb574cd5a407fefa5610fcde6aec13d983ba527c' , 'huobi_pool'),
 ('0x8d328ef333645115937f2bcfd6bcfa73b532630d' , 'huobi_pool'),
 ('0x8d9cc1d96cc7f98b73fb9c70df1b2f50daec6166' , 'huobi_pool'),
 ('0x99ab46812d1e6d2bfbb7a337418da10b15aa159f' , 'huobi_pool'),
 ('0xda92c68565b6f8b4ee5ce619fabd880f6e485604' , 'huobi_pool'),
 ('0xde7286bd7e0b25fb9f425b01a013ac85cf473408' , 'huobi_pool'),
 ('0xcc555bd1d5359f2fc4fcc3302018386aec2c4171' , 'huobi_pool'),
 ('0xd897fe50cc3f57ddea02c8c21d5ff3eb03387310' , 'huobi_pool'),
 ('0xc9610be2843f1618edfedd0860dc43551c727061' , 'huobi_pool'),
 ('0x4ce9f39d3a0426d8d1f2ad4fcff0b92e86b9b914' , 'huobi_pool');
 
INSERT INTO tag_all values
 ('0x82ab4851dcc3e6f18c9e904e86aefedb13576cfe' , 'huobi_pool'),
 ('0x3b0e20b3bea1fd1e24dfbbc9d3fcafd30fde8ff8' , 'huobi_pool'),
 ('0x42dc966b7ecc3c6cc73e7bc04862859d5bddce65' , 'huobi_pool'),
 ('0xf881bcb3705926cea9c598ab05a837cf41a833a9' , 'huobi_pool');

--3.1 根据充币表的交易hash查出过渡地址
 SELECT
  to1
  FROM
  orc_t_ethereum_nmta a
  WHERE EXISTS(
  SELECT 1
  FROM huobi_deposit_txid_eth b
  WHERE a.transactionHash = '0x' || b.lower
  )
  GROUP BY to1;
  
 0x83f997587f007b59ce35894350e78b27056760b5
 0xfe44bbb1339d2dc9c088b1f4a258d02b5f9ad963
 
--3.2 根据过渡地址查出 huobi_pool
 SELECT
 to1
 FROM
 orc_t_ethereum_nmta  
 WHERE
 from1 in
 (
   SELECT
  to1
  FROM
  orc_t_ethereum_nmta a
  WHERE EXISTS(
  SELECT 1
  FROM huobi_deposit_txid_eth b
  WHERE a.transactionHash = '0x' || b.lower
  )
  GROUP BY to1
 )
 GROUP BY to1;
 
 0x0c92efa186074ba716d0e2156a6ffabd579f8035
 0x6f48a3e70f0251d1e83a989e62aaa2281a6d5380
 0x926fc576b7facf6ae2d08ee2d4734c134a743988
 0xb64ef51c888972c908cfacf59b47c1afbc0ab8ac -- Storj Token
 0xd19141a9b74f7a02cc2b4919039f2961e988732f --
 0x1ff41b4d3db633f91cfa29d4bf8cff8903edefe2 --
 0x9a755332d874c893111207b0b220ce2615cd036f
 0xf66852bc122fd40bfecc63cd48217e88bda12109
 0x86fa049857e0209aa7d9e616f7eb3b3b78ecfdb0 --EOS Token
 0xb2a48f542dc56b89b24c04076cbe565b3dc58e7b
 0xd26114cd6ee289accf82350c8d8487fedb8a0c07 --OMGToken
 0xeec606a66edb6f497662ea31b5eb1610da87ab5f
 0xdac17f958d2ee523a2206206994597c13d831ec7 USDT
  
  
--3.3 根据提币表的交易hash查出from1作为 huobi_pool
SELECT 
 from1
 FROM 
  orc_t_ethereum_nmta a
 WHERE EXISTS
 (
  SELECT 1
  FROM huobi_withdraw_txid_eth b
  WHERE a.transactionHash = '0x' || b.lower
 )
 GROUP BY from1;
 
--结果都在已知的 huobi_pool 中：
 0xd8a83b72377476d0a66683cde20a8aad0b628713
 0xf7a8af16acb302351d7ea26ffc380575b741724c
 0x170af0a02339743687afd3dc8d48cffd1f660728
 0x6f48a3e70f0251d1e83a989e62aaa2281a6d5380
 0x034f854b44d28e26386c1bc37ff9b20c6380b00d
 0x1c515eaa87568c850043a89c2d2c2e8187adb056
 0x926fc576b7facf6ae2d08ee2d4734c134a743988
 0x04645af26b54bd85dc02ac65054e87362a72cb22
 0xef54f559b5e3b55b783c7bc59850f83514b6149c
 0x60b45f993223dcb8bdf05e3391f7630e5a51d787
 0x5401dbf7da53e1c9dbf484e3d69505815f2f5e6e
 0xf66852bc122fd40bfecc63cd48217e88bda12109
 0x28ffe35688ffffd0659aee2e34778b0ae4e193ad
 0x1b93129f05cc2e840135aab154223c75097b69bf
 0x0577a79cfc63bbc0df38833ff4c4a3bf2095b404
 0xeec606a66edb6f497662ea31b5eb1610da87ab5f
 0x1d1e10e8c66b67692f4c002c0cb334de5d485e41
 0x75a83599de596cbc91a1821ffa618c40e22ac8ca
 0x91dfa9d9e062a50d2f351bfba0d35a9604993dac
 0xf056f435ba0cc4fcd2f1b17e3766549ffc404b94
 0x6f50c6bff08ec925232937b204b0ae23c488402a
 0xcac725bef4f114f728cbcfd744a731c2a463c3fc
 0x5861b8446a2f6e19a067874c133f04c578928727
 0x9a755332d874c893111207b0b220ce2615cd036f
 0xecd8b3877d8e7cd0739de18a5b545bc0b3538566
 0x956e0dbecc0e873d34a5e39b25f364b2ca036730
 0xb9a4873d8d2c22e56b8574e8605644d08e047549
 0xc837f51a0efa33f8eca03570e3d01a4b2cf97ffd
 0xdf95de30cdff4381b69f9e4fa8dddce31a0128df
 0xeb6d43fe241fb2320b5a3c9be9cdfd4dd8226451
 0xf775a9a0ad44807bc15936df0ee68902af1a0eee
 0x137ad9c4777e1d36e4b605e745e8f37b2b62e9c5
 0x25c6459e5c5b01694f6453e8961420ccd1edf3b1
 0x73f8fc2e74302eb2efda125a326655acf0dc2d1b
 0x794d28ac31bcb136294761a556b68d2634094153
 0x90e9ddd9d8d5ae4e3763d0cf856c97594dea7325
 0xe3314bbf3334228b257779e28228cfb86fa4261b
 0x8aabba0077f1565df73e9d15dd3784a2b0033dad
 0xb2a48f542dc56b89b24c04076cbe565b3dc58e7b
 0xd10e08325c0e95d59c607a693483680fe5b755b3
 0xd3a2f775e973c1671f2047e620448b8662dcd3ca
 
--结果不在已知的 huobi_pool 中：
 0xf5613e4da78cee6a1bffdf9c235d56bbf6d01d8d
 0x39d9f4640b98189540a9c0edcfa95c5e657706aa
 0x86e6df2933f88a00caa11ad19413123c3abef3de
 0x3c979fb790c86e361738ed17588c1e8b4c4cc49a
 0xe21bc8d4f47dbd9e4dd29229333d1999c33d0e87
 0x27e9f4748a2eb776be193a1f7dec2bb6daafe9cf
 0xf726dc178d1a4d9292a8d63f01e0fa0a1235e65c
 0x58c2cb4a6bee98c309215d0d2a38d7f8aa71211c
 0xeb574cd5a407fefa5610fcde6aec13d983ba527c
 0x8d328ef333645115937f2bcfd6bcfa73b532630d
 0x8d9cc1d96cc7f98b73fb9c70df1b2f50daec6166
 0x99ab46812d1e6d2bfbb7a337418da10b15aa159f
 0xda92c68565b6f8b4ee5ce619fabd880f6e485604
 0xde7286bd7e0b25fb9f425b01a013ac85cf473408
 0xcc555bd1d5359f2fc4fcc3302018386aec2c4171
 0xd897fe50cc3f57ddea02c8c21d5ff3eb03387310
 0xc9610be2843f1618edfedd0860dc43551c727061
 0x4ce9f39d3a0426d8d1f2ad4fcff0b92e86b9b914
 
--3.4 给过渡地址打 huobi 标签
INSERT INTO tag_all
 SELECT
  from1, 'huobi'
  FROM
  orc_t_ethereum_nmta
  WHERE 
  to1 in (
   SELECT address 
    FROM
    tag_all
    WHERE
    tag_name = 'huobi_pool'
    )
  AND
  from1 not in
 (
   SELECT address 
    FROM
    tag_all
    WHERE
    tag_name = 'huobi_pool'
  );
 
 --3702070
 
 4. bithumb
 insert into tag_all values
('0x88d34944cf554e9cccf4a24292d891f620e9c94f' , 'bithumb_pool'),
('0x3052cd6bf951449a984fe4b5a38b46aef9455c8e' , 'bithumb_pool'),
('0x2140efd7ba31169c69dfff6cdc66c542f0211825' , 'bithumb_pool'),
('0xa0ff1e0f30b5dda2dc01e7e828290bc72b71e57d' , 'bithumb_pool'),
('0xc1da8f69e4881efe341600620268934ef01a3e63' , 'bithumb_pool'),
('0xb4460b75254ce0563bb68ec219208344c7ea838c' , 'bithumb_pool'),
('0x15878e87c685f866edfaf454be6dc06fa517b35b' , 'bithumb_pool'),
('0x31d03f07178bcd74f9099afebd23b0ae30184ab5' , 'bithumb_pool'),
('0xed48dc0628789c2956b1e41726d062a86ec45bff' , 'bithumb_pool'),
('0x186549a4ae594fc1f70ba4cffdac714b405be3f9' , 'bithumb_pool'),
('0xd273bd546b11bd60214a2f9d71f22a088aafe31b' , 'bithumb_pool'),
--('0x3fbe1f8fc5ddb27d428aa60f661eaaab0d2000ce' , 'bithumb_pool'),
('0xbb5a0408fa54287b9074a2f47ab54c855e95ef82' , 'bithumb_pool'),
('0x5521a68d4f8253fc44bfb1490249369b3e299a4a' , 'bithumb_pool'),
('0x8fa8af91c675452200e49b4683a33ca2e1a34e42' , 'bithumb_pool'),
('0x3b83cd1a8e516b6eb9f1af992e9354b15a6f9672' , 'bithumb_pool');

--给过渡地址打 bithumb 标签
INSERT INTO tag_all
 SELECT 
  from1, 'bithumb'
  FROM
  orc_t_ethereum_nmta
  WHERE 
  to1 in (
    '0x88d34944cf554e9cccf4a24292d891f620e9c94f' ,
	'0x3052cd6bf951449a984fe4b5a38b46aef9455c8e' ,
    '0x2140efd7ba31169c69dfff6cdc66c542f0211825' ,
    '0xa0ff1e0f30b5dda2dc01e7e828290bc72b71e57d' ,
    '0xc1da8f69e4881efe341600620268934ef01a3e63' ,
    '0xb4460b75254ce0563bb68ec219208344c7ea838c' ,
    '0x15878e87c685f866edfaf454be6dc06fa517b35b' ,
    '0x31d03f07178bcd74f9099afebd23b0ae30184ab5' ,
    '0xed48dc0628789c2956b1e41726d062a86ec45bff' ,
    '0x186549a4ae594fc1f70ba4cffdac714b405be3f9' ,
    '0xd273bd546b11bd60214a2f9d71f22a088aafe31b' ,
  --  '0x3fbe1f8fc5ddb27d428aa60f661eaaab0d2000ce' ,
    '0xbb5a0408fa54287b9074a2f47ab54c855e95ef82' ,
    '0x5521a68d4f8253fc44bfb1490249369b3e299a4a' ,
    '0x8fa8af91c675452200e49b4683a33ca2e1a34e42' ,
    '0x3b83cd1a8e516b6eb9f1af992e9354b15a6f9672' 
  )
  AND 
  from1 not in (
	'0x88d34944cf554e9cccf4a24292d891f620e9c94f' ,
	'0x3052cd6bf951449a984fe4b5a38b46aef9455c8e' ,
    '0x2140efd7ba31169c69dfff6cdc66c542f0211825' ,
    '0xa0ff1e0f30b5dda2dc01e7e828290bc72b71e57d' ,
    '0xc1da8f69e4881efe341600620268934ef01a3e63' ,
    '0xb4460b75254ce0563bb68ec219208344c7ea838c' ,
    '0x15878e87c685f866edfaf454be6dc06fa517b35b' ,
    '0x31d03f07178bcd74f9099afebd23b0ae30184ab5' ,
    '0xed48dc0628789c2956b1e41726d062a86ec45bff' ,
    '0x186549a4ae594fc1f70ba4cffdac714b405be3f9' ,
    '0xd273bd546b11bd60214a2f9d71f22a088aafe31b' ,
  --  '0x3fbe1f8fc5ddb27d428aa60f661eaaab0d2000ce' ,
    '0xbb5a0408fa54287b9074a2f47ab54c855e95ef82' ,
    '0x5521a68d4f8253fc44bfb1490249369b3e299a4a' ,
    '0x8fa8af91c675452200e49b4683a33ca2e1a34e42' ,
    '0x3b83cd1a8e516b6eb9f1af992e9354b15a6f9672' 
);
--417693


5. upbit
--upbit_pool
INSERT INTO tag_all values
('0x390de26d772d2e2005c6d1d24afc902bae37a4bb' , 'upbit_pool'), 
('0xba826fec90cefdf6706858e5fbafcb27a290fbe0' , 'upbit_pool'), 
('0x5e032243d507c743b061ef021e2ec7fcc6d3ab89' , 'upbit_pool');


--标过渡地址，只区分 upbit 池子和非 upbit 池子（包括其他池子）
INSERT INTO tag_all
 SELECT 
  from1, 'upbit'
  FROM
  orc_t_ethereum_nmta
  WHERE 
  to1 in (
	'0x390de26d772d2e2005c6d1d24afc902bae37a4bb' ,
	'0xba826fec90cefdf6706858e5fbafcb27a290fbe0' ,
	'0x5e032243d507c743b061ef021e2ec7fcc6d3ab89' 
  )
  AND 
  from1 not in (
	'0x390de26d772d2e2005c6d1d24afc902bae37a4bb' ,
	'0xba826fec90cefdf6706858e5fbafcb27a290fbe0' ,
	'0x5e032243d507c743b061ef021e2ec7fcc6d3ab89'
);
--1298489

