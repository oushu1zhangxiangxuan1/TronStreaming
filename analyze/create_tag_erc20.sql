drop TABLE t_tag_erc20;
CREATE TABLE t_tag_erc20
(
address text,
tag_name text
)
with (appendonly = true, orientation = orc, compresstype = lz4, dicthreshold = 0.8);


--okex池子单独标出来
insert into t_tag_erc20 values
('0x6cc5f688a315f3dc28a7781717a9a798a59fda7b' , 'okex_pool'),
('0x236f9f97e0e62388479bf9e5ba4889e46b0273c3' , 'okex_pool'),
('0xa7efae728d2936e78bda97dc267687568dd593f3' , 'okex_pool'),
('0x5041ed759dd4afc3a72b8192c143f72f4724081a' , 'okex_pool'),
('0x11817afb29279703c5679959417015328ca6a0d1' , 'okex_pool');

--标过渡地址，只区分okex池子和非okex池子（包括其他池子）
--1150224
INSERT INTO t_tag_erc20
 SELECT 
  from1, 'okex'
  FROM
  orc_t_ethereum_erc20
  WHERE 
  to1 in (
	'0x6cc5f688a315f3dc28a7781717a9a798a59fda7b',
    '0x236f9f97e0e62388479bf9e5ba4889e46b0273c3',
    '0xa7efae728d2936e78bda97dc267687568dd593f3',
	'0x5041ed759dd4afc3a72b8192c143f72f4724081a', 
	'0x11817afb29279703c5679959417015328ca6a0d1' 
   )
  AND 
  from1 not in (
	'0x6cc5f688a315f3dc28a7781717a9a798a59fda7b',
    '0x236f9f97e0e62388479bf9e5ba4889e46b0273c3',
    '0xa7efae728d2936e78bda97dc267687568dd593f3',
	'0x5041ed759dd4afc3a72b8192c143f72f4724081a', 
	'0x11817afb29279703c5679959417015328ca6a0d1' 
 );
  
--bithumb 池子单独标出来
insert into t_tag_erc20 values
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


--标过渡地址，只区分 bithumb 池子和非 bithumb 池子（包括其他池子）
--277167
INSERT INTO t_tag_erc20
 SELECT 
  from1, 'bithumb'
  FROM
  orc_t_ethereum_erc20
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

--bithumb_contract
INSERT INTO t_tag_erc20 values
('0x3fbe1f8fc5ddb27d428aa60f661eaaab0d2000ce', 'bithumb_contract');

--huobi_pool
INSERT INTO t_tag_erc20 values
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


--huobi_pool_old
INSERT INTO t_tag_erc20 values
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


--标过渡地址，只区分 huobi 池子和非 huobi 池子（包括其他池子）
--3217070
INSERT INTO t_tag_erc20
 SELECT 
  from1, 'huobi'
  FROM
  orc_t_ethereum_erc20
  WHERE 
  to1 in (
	'0xab5c66752a9e8167967685f1450532fb96d5d24f' ,
	'0x6748f50f686bfbca6fe8ad62b22228b87f31ff2b' ,
	'0xfdb16996831753d5331ff813c29a93c76834a0ad' ,
	'0xeee28d484628d41a82d01e21d12e2e78d69920da' ,
	'0x5c985e89dde482efe97ea9f1950ad149eb73829b' ,
	'0xdc76cd25977e0a5ae17155770273ad58648900d3' ,
	'0xadb2b42f6bd96f5c65920b9ac88619dce4166f94' ,
	'0xa8660c8ffd6d578f657b72c0c811284aef0b735e' ,
	'0x1062a747393198f70f71ec65a582423dba7e5ab3' ,
	'0xe93381fb4c4f14bda253907b18fad305d799241a' ,
	'0xfa4b5be3f2f84f56703c42eb22142744e95a2c58' ,
	'0x46705dfff24256421a05d056c29e81bdc09723b8' ,
	'0x32598293906b5b17c27d657db3ad2c9b3f3e4265' ,
	'0x5861b8446a2f6e19a067874c133f04c578928727' ,
	'0x926fc576b7facf6ae2d08ee2d4734c134a743988' ,
	'0xeec606a66edb6f497662ea31b5eb1610da87ab5f' ,
	'0x7ef35bb398e0416b81b019fea395219b65c52164' ,
	'0x229b5c097f9b35009ca1321ad2034d4b3d5070f6' ,
	'0xd8a83b72377476d0a66683cde20a8aad0b628713' ,
	'0x90e9ddd9d8d5ae4e3763d0cf856c97594dea7325' ,
	'0x18916e1a2933cb349145a280473a5de8eb6630cb' ,
	'0x6f48a3e70f0251d1e83a989e62aaa2281a6d5380' ,
	'0xf056f435ba0cc4fcd2f1b17e3766549ffc404b94' ,
	'0x137ad9c4777e1d36e4b605e745e8f37b2b62e9c5' ,
	'0x5401dbf7da53e1c9dbf484e3d69505815f2f5e6e' ,
	'0x034f854b44d28e26386c1bc37ff9b20c6380b00d' ,
	'0x0577a79cfc63bbc0df38833ff4c4a3bf2095b404' ,
	'0x0c6c34cdd915845376fb5407e0895196c9dd4eec' ,
	'0x794d28ac31bcb136294761a556b68d2634094153' ,
	'0xfd54078badd5653571726c3370afb127351a6f26' ,
	'0xb4cd0386d2db86f30c1a11c2b8c4f4185c1dade9' ,
	'0x4d77a1144dc74f26838b69391a6d3b1e403d0990' ,
	'0x28ffe35688ffffd0659aee2e34778b0ae4e193ad' ,
	'0xcac725bef4f114f728cbcfd744a731c2a463c3fc' ,
	'0x73f8fc2e74302eb2efda125a326655acf0dc2d1b' ,
	'0x0a98fb70939162725ae66e626fe4b52cff62c2e5' ,
	'0xf66852bc122fd40bfecc63cd48217e88bda12109' ,
	'0x1d1e10e8c66b67692f4c002c0cb334de5d485e41',
	'0x1b93129f05cc2e840135aab154223c75097b69bf',
	'0xeb6d43fe241fb2320b5a3c9be9cdfd4dd8226451',
	'0x956e0dbecc0e873d34a5e39b25f364b2ca036730',
	'0x6f50c6bff08ec925232937b204b0ae23c488402a',
	'0xdf95de30cdff4381b69f9e4fa8dddce31a0128df',
	'0x25c6459e5c5b01694f6453e8961420ccd1edf3b1',
	'0x04645af26b54bd85dc02ac65054e87362a72cb22',
	'0xb2a48f542dc56b89b24c04076cbe565b3dc58e7b',
	'0xea0cfef143182d7b9208fbfeda9d172c2aced972',
	'0x0c92efa186074ba716d0e2156a6ffabd579f8035',
	'0x91dfa9d9e062a50d2f351bfba0d35a9604993dac',
	'0x8e8bc99b79488c276d6f3ca11901e9abd77efea4',
	'0xb9a4873d8d2c22e56b8574e8605644d08e047549',
	'0x170af0a02339743687afd3dc8d48cffd1f660728',
	'0xf775a9a0ad44807bc15936df0ee68902af1a0eee',
	'0x75a83599de596cbc91a1821ffa618c40e22ac8ca',
	'0x48ab9f29795dfb44b36587c50da4b30c0e84d3ed',
	'0x90f49e24a9554126f591d28174e157ca267194ba',
	'0xe3314bbf3334228b257779e28228cfb86fa4261b',
	'0x6edb9d6547befc3397801c94bb8c97d2e8087e2f',
	'0x8aabba0077f1565df73e9d15dd3784a2b0033dad',
	'0xd3a2f775e973c1671f2047e620448b8662dcd3ca',
	'0x1c515eaa87568c850043a89c2d2c2e8187adb056',
	'0x60b45f993223dcb8bdf05e3391f7630e5a51d787',
	'0xa23d7dd4b8a1060344caf18a29b42350852af481',
	'0x9eebb2815dba2166d8287afa9a2c89336ba9deaa',
	'0xd10e08325c0e95d59c607a693483680fe5b755b3',
	'0xc837f51a0efa33f8eca03570e3d01a4b2cf97ffd',
	'0xf7a8af16acb302351d7ea26ffc380575b741724c',
	'0x636b76ae213358b9867591299e5c62b8d014e372',
	'0x9a755332d874c893111207b0b220ce2615cd036f',
	'0xecd8b3877d8e7cd0739de18a5b545bc0b3538566',
	'0xef54f559b5e3b55b783c7bc59850f83514b6149c'
  )
  AND 
  from1 not in (
	'0xab5c66752a9e8167967685f1450532fb96d5d24f' ,
	'0x6748f50f686bfbca6fe8ad62b22228b87f31ff2b' ,
	'0xfdb16996831753d5331ff813c29a93c76834a0ad' ,
	'0xeee28d484628d41a82d01e21d12e2e78d69920da' ,
	'0x5c985e89dde482efe97ea9f1950ad149eb73829b' ,
	'0xdc76cd25977e0a5ae17155770273ad58648900d3' ,
	'0xadb2b42f6bd96f5c65920b9ac88619dce4166f94' ,
	'0xa8660c8ffd6d578f657b72c0c811284aef0b735e' ,
	'0x1062a747393198f70f71ec65a582423dba7e5ab3' ,
	'0xe93381fb4c4f14bda253907b18fad305d799241a' ,
	'0xfa4b5be3f2f84f56703c42eb22142744e95a2c58' ,
	'0x46705dfff24256421a05d056c29e81bdc09723b8' ,
	'0x32598293906b5b17c27d657db3ad2c9b3f3e4265' ,
	'0x5861b8446a2f6e19a067874c133f04c578928727' ,
	'0x926fc576b7facf6ae2d08ee2d4734c134a743988' ,
	'0xeec606a66edb6f497662ea31b5eb1610da87ab5f' ,
	'0x7ef35bb398e0416b81b019fea395219b65c52164' ,
	'0x229b5c097f9b35009ca1321ad2034d4b3d5070f6' ,
	'0xd8a83b72377476d0a66683cde20a8aad0b628713' ,
	'0x90e9ddd9d8d5ae4e3763d0cf856c97594dea7325' ,
	'0x18916e1a2933cb349145a280473a5de8eb6630cb' ,
	'0x6f48a3e70f0251d1e83a989e62aaa2281a6d5380' ,
	'0xf056f435ba0cc4fcd2f1b17e3766549ffc404b94' ,
	'0x137ad9c4777e1d36e4b605e745e8f37b2b62e9c5' ,
	'0x5401dbf7da53e1c9dbf484e3d69505815f2f5e6e' ,
	'0x034f854b44d28e26386c1bc37ff9b20c6380b00d' ,
	'0x0577a79cfc63bbc0df38833ff4c4a3bf2095b404' ,
	'0x0c6c34cdd915845376fb5407e0895196c9dd4eec' ,
	'0x794d28ac31bcb136294761a556b68d2634094153' ,
	'0xfd54078badd5653571726c3370afb127351a6f26' ,
	'0xb4cd0386d2db86f30c1a11c2b8c4f4185c1dade9' ,
	'0x4d77a1144dc74f26838b69391a6d3b1e403d0990' ,
	'0x28ffe35688ffffd0659aee2e34778b0ae4e193ad' ,
	'0xcac725bef4f114f728cbcfd744a731c2a463c3fc' ,
	'0x73f8fc2e74302eb2efda125a326655acf0dc2d1b' ,
	'0x0a98fb70939162725ae66e626fe4b52cff62c2e5' ,
	'0xf66852bc122fd40bfecc63cd48217e88bda12109' ,
	'0x1d1e10e8c66b67692f4c002c0cb334de5d485e41',
	'0x1b93129f05cc2e840135aab154223c75097b69bf',
	'0xeb6d43fe241fb2320b5a3c9be9cdfd4dd8226451',
	'0x956e0dbecc0e873d34a5e39b25f364b2ca036730',
	'0x6f50c6bff08ec925232937b204b0ae23c488402a',
	'0xdf95de30cdff4381b69f9e4fa8dddce31a0128df',
	'0x25c6459e5c5b01694f6453e8961420ccd1edf3b1',
	'0x04645af26b54bd85dc02ac65054e87362a72cb22',
	'0xb2a48f542dc56b89b24c04076cbe565b3dc58e7b',
	'0xea0cfef143182d7b9208fbfeda9d172c2aced972',
	'0x0c92efa186074ba716d0e2156a6ffabd579f8035',
	'0x91dfa9d9e062a50d2f351bfba0d35a9604993dac',
	'0x8e8bc99b79488c276d6f3ca11901e9abd77efea4',
	'0xb9a4873d8d2c22e56b8574e8605644d08e047549',
	'0x170af0a02339743687afd3dc8d48cffd1f660728',
	'0xf775a9a0ad44807bc15936df0ee68902af1a0eee',
	'0x75a83599de596cbc91a1821ffa618c40e22ac8ca',
	'0x48ab9f29795dfb44b36587c50da4b30c0e84d3ed',
	'0x90f49e24a9554126f591d28174e157ca267194ba',
	'0xe3314bbf3334228b257779e28228cfb86fa4261b',
	'0x6edb9d6547befc3397801c94bb8c97d2e8087e2f',
	'0x8aabba0077f1565df73e9d15dd3784a2b0033dad',
	'0xd3a2f775e973c1671f2047e620448b8662dcd3ca',
	'0x1c515eaa87568c850043a89c2d2c2e8187adb056',
	'0x60b45f993223dcb8bdf05e3391f7630e5a51d787',
	'0xa23d7dd4b8a1060344caf18a29b42350852af481',
	'0x9eebb2815dba2166d8287afa9a2c89336ba9deaa',
	'0xd10e08325c0e95d59c607a693483680fe5b755b3',
	'0xc837f51a0efa33f8eca03570e3d01a4b2cf97ffd',
	'0xf7a8af16acb302351d7ea26ffc380575b741724c',
	'0x636b76ae213358b9867591299e5c62b8d014e372',
	'0x9a755332d874c893111207b0b220ce2615cd036f',
	'0xecd8b3877d8e7cd0739de18a5b545bc0b3538566',
	'0xef54f559b5e3b55b783c7bc59850f83514b6149c'
);

--huobi_token
INSERT INTO t_tag_erc20 values
('0x9d6d492bd500da5b33cf95a5d610a73360fcaaa0' , 'huobiMiningPool'),
('0xa66daa57432024023db65477ba87d4e7f5f95213' , 'huobiPoolToken'),	
('0x6f259637dcd74c767781e37bc6133cd6a68aa161' , 'huobiToken'),		
('0x0316eb71485b0ab14103307bf65a021042c6d380' , 'huobiHBTCToken');

--binance
INSERT INTO t_tag_erc20 values
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

--标过渡地址，只区分 Binance 池子和非 Binance 池子（包括其他池子）
--4068730
INSERT INTO t_tag_erc20
 SELECT 
  from1, 'binance'
  FROM
  orc_t_ethereum_erc20
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
  from1 not in (
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

--binance_token
INSERT INTO t_tag_erc20 values
('0x8b99f3660622e21f2910ecca7fbe51d654a1517d' , 'binanceCharity'),			
('0xab83d182f3485cf1d6ccdd34c7cfef95b4c08da4' , 'binanceJEX'),				
('0x4fabb145d64652a948d72533023f6e7a623c7c53' , 'binanceUSD'),				
('0xc9a2c4868f0f96faaa739b59934dc9cb304112ec' , 'binanceBGBPToken'),		
('0xb8c77482e45f1f44de1745f52c74426c631bdd52' , 'binanceBNBToken'),		
('0x0b95993a39a363d99280ac950f5e4536ab5c5566' , 'binanceContract'),		
('0x2f47a1c2db4a3b78cda44eade915c3b19107ddcc' , 'binanceEth2Depositor');

--upbit_pool
INSERT INTO t_tag_erc20 values
('0x390de26d772d2e2005c6d1d24afc902bae37a4bb' , 'upbit_pool'), 
('0xba826fec90cefdf6706858e5fbafcb27a290fbe0' , 'upbit_pool'), 
('0x5e032243d507c743b061ef021e2ec7fcc6d3ab89' , 'upbit_pool');


--标过渡地址，只区分 upbit 池子和非 upbit 池子（包括其他池子）
--845711
INSERT INTO t_tag_erc20
 SELECT 
  from1, 'upbit'
  FROM
  orc_t_ethereum_erc20
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

--UpbitColdWallet
INSERT INTO t_tag_erc20 values
('0xc9cf0ec93d764f5c9571fd12f764bae7fc87c84e' , 'UpbitColdWallet');

--coinone_pool
INSERT INTO t_tag_erc20 values
('0x167a9333bf582556f35bd4d16a7e80e191aa6476' , 'coinone'),	
('0x1e2fcfd26d36183f1a5d90f0e6296915b02bcb40' , 'coinone'),
('0x35da6abcb08f2b6164fe380bb6c47bd8f2304d55' , 'coinone'); 

--标过渡地址，只区分 coinone 池子和非 coinone 池子（包括其他池子）
--139857
INSERT INTO t_tag_erc20
 SELECT 
  from1, 'coinone'
  FROM
  orc_t_ethereum_erc20
  WHERE 
  to1 in (
 '0x167a9333bf582556f35bd4d16a7e80e191aa6476' ,
 '0x1e2fcfd26d36183f1a5d90f0e6296915b02bcb40' ,
 '0x35da6abcb08f2b6164fe380bb6c47bd8f2304d55' 
  )
  AND 
  from1 not in (
 '0x167a9333bf582556f35bd4d16a7e80e191aa6476' ,
 '0x1e2fcfd26d36183f1a5d90f0e6296915b02bcb40' ,
 '0x35da6abcb08f2b6164fe380bb6c47bd8f2304d55' 
);

