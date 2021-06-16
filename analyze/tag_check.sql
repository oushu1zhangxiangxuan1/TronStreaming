set search_path to ytf;
-- 1. 查询0x0e37f798b6872f33bc373dfd90fb811ba4d946e9是否在标签表中，标签是否是bithumb
-- 不在
SELECT * FROM t_tag WHERE address = '0x0e37f798b6872f33bc373dfd90fb811ba4d946e9';

/*
2. 
查询交易表中交易hash为0x64bdec4fa600861d5cc8e229d5f145f60e716a9d33d2a61dc1c29628e8110153的记录，
to是 0xdac17f958d2ee523a2206206994597c13d831ec7 还是0x0e37f798b6872f33bc373dfd90fb811ba4d946e9
*/

SELECT * FROM orc_t_ethereum_iet WHERE transactionhash = '0x64bdec4fa600861d5cc8e229d5f145f60e716a9d33d2a61dc1c29628e8110153';
-- 不存在

SELECT * FROM orc_t_ethereum_nm_ta WHERE transactionhash = '0x64bdec4fa600861d5cc8e229d5f145f60e716a9d33d2a61dc1c29628e8110153';
-- to是0xdac17f958d2ee523a2206206994597c13d831ec7
-- 应该在erc20里面查to

/*
3. 
查询erc20表中交易hash为0x64bdec4fa600861d5cc8e229d5f145f60e716a9d33d2a61dc1c29628e8110153的记录，
to是0xdac17f958d2ee523a2206206994597c13d831ec7还是 0x0e37f798b6872f33bc373dfd90fb811ba4d946e9
*/
SELECT * FROM public.orc_t_ethereum_erc20 WHERE transactionhash = '0x64bdec4fa600861d5cc8e229d5f145f60e716a9d33d2a61dc1c29628e8110153';
-- to是0x0e37f798b6872f33bc373dfd90fb811ba4d946e9

/*
4. 
查询
0x6cc5f688a315f3dc28a7781717a9a798a59fda7b 是否在okex_pool中
*/
-- 在okex_pool中
SELECT * FROM t_tag WHERE address = '0x6cc5f688a315f3dc28a7781717a9a798a59fda7b';

/*
5.
0x3f0cbb5961e4bf6ff3baa63755dd51e553e3c9f1d16912450b87b5c1a1e6f5ae的上游地址0x5041ed759dd4afc3a72b8192c143f72f4724081a是否在标签表中，标签是否为okex_pool
*/
-- 在okex_pool中
SELECT * FROM t_tag WHERE address = '0x5041ed759dd4afc3a72b8192c143f72f4724081a';

/*
6.
查询交易表中交易hash为 0x3f0cbb5961e4bf6ff3baa63755dd51e553e3c9f1d16912450b87b5c1a1e6f5ae 的
的下游地址为0xdac17f958d2ee523a2206206994597c13d831ec7还是0x83f997587f007b59ce35894350e78b27056760b5
如果是0x83f997587f007b59ce35894350e78b27056760b5，看其是否在标签表中，标签是否为bithumb
*/
SELECT * FROM orc_t_ethereum_iet WHERE transactionhash = '0x3f0cbb5961e4bf6ff3baa63755dd51e553e3c9f1d16912450b87b5c1a1e6f5ae';
-- 不在
SELECT * FROM orc_t_ethereum_nm_ta WHERE transactionhash = '0x3f0cbb5961e4bf6ff3baa63755dd51e553e3c9f1d16912450b87b5c1a1e6f5ae';
-- 不在,说明orc_t_ethereum_nm_ta少数据
SELECT * FROM public.orc_t_ethereum_erc20 WHERE transactionhash = '0x3f0cbb5961e4bf6ff3baa63755dd51e553e3c9f1d16912450b87b5c1a1e6f5ae';
-- 在，to是0x83f997587f007b59ce35894350e78b27056760b5， 是实际收币地址
SELECT * FROM t_tag WHERE address = '0x83f997587f007b59ce35894350e78b27056760b5';
-- 标签不是bithumb，而是huobi TODO: 这里有问题
/*
7. 确认吴昊的的两个xlsx都是从okex交易所获取的，这样提币流水的from肯定是okex_pool
但是目前在吴昊1.xlsx中发现交易hash为 0x87bf433c5d297fb39775663d93a09691990c68e98c29b95b909be41fb4a2d1c4 的交易的from被浏览器标记成了huobi_pool
需要咨询时主任
*/


/*
8. 确认吴昊的的两个xlsx提币流水的to应该为什么？
*/


/*
9. 确认吴昊的的两个xlsx提币流水的to应该为什么？
*/

/*
10. 确认吴昊USDT跑出来的结果中和xlsx中的互相包含
*/
-- 不互相包含