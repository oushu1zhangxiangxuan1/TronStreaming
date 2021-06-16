-- 导入充提币历史记录并分析打标签

-- 创建okex充币表
CREATE TABLE okex_deposit(
    token_type text,
    address text,
    amount double precision,
    txid text,
    create_time text,
    update_time text
);
-- 创建okex提币表
CREATE TABLE okex_withdraw(
    token_type text,
    address text,
    amount double precision,
    txid text,
    create_time text,
    update_time text
);
-- 创建binance充币表
CREATE TABLE binance_deposit(
    user_id text,
    currency text,
    amount double precision,
    deposit_address text,
    source_address text,
    txid text,
    create_time text,
    status text
);
-- 创建binance提币表
CREATE TABLE binance_withdraw(
    user_id text,
    currency text,
    amount double precision,
    destination_address text,
    label_tag_memo text,
    txid text,
    apply_time text,
    status text
);
-- 创建huobi充提币表



------------------------------------------------OKEX------------------------------------------------------------------
/*
导入okex对应数据
目录结构:
├── OKEX2.9
│   ├── liudefeng-in.csv
│   ├── liudefeng-out.csv
│   ├── wuhao-in.csv
│   ├── wuhao-out.csv
│   ├── �\220��\230\212.xlsx
│   ├── �\210\230德丰.xlsx
│   └── �\237�询�\223�\236\234.xlsx
├── OKEX2021.3.1
│   ├── wuhao_in.csv
│   ├── wuhao_out.csv
│   ├── xuxinyue_in.csv
│   ├── xuxinyue_out.csv
│   ├── �\220��\230\212.xlsx
│   ├── �\220�\226��\207.xlsx
│   ├── �\216\213�\214\227�\213.xlsx
│   ├── �\231\210�\225\207�\210�.xlsx
│   └── �\237�询�\223�\236\234.xlsx
├── OKEX2021.3.1.rar
├── OKEX2021.3.3
│   ├── yuankeqin_in.csv
│   ├── yuankeqin_out.csv
│   ├── zhaolixiang_in.csv
│   ├── zhaolixiang_out.csv
│   ├── �\237�\200\232欣.xlsx
│   ├── �\213\221�\205\213�\222�.xlsx
│   ├── 赵�\220\206�\203�.xlsx
│   └── �\237�询�\223�\236\234\ (1).xlsx
├── OKEX2021.3.3.rar
├── binance2021.3.29
│   ├── in_binance_29_03_2021_01.csv
│   ├── in_report_29_03_2021_02.csv
│   ├── in_report_29_03_2021_03.csv
│   ├── in_report_29_03_2021_04.csv
│   ├── in_report_29_03_2021_05.csv
│   ├── out_binance_29_03_2021_01.csv
│   ├── out_report_29_03_2021_02.csv
│   ├── out_report_29_03_2021_03.csv
│   ├── out_report_29_03_2021_04.csv
│   ├── out_report_29_03_2021_05.csv
│   ├── report_�\237�\213\217�\234\201常�\236�\202�\205��\211�\200_29_03_2021_01.xlsx
│   ├── report_�\237�\213\217�\234\201常�\236�\202�\205��\211�\200_29_03_2021_02.xlsx
│   ├── report_�\237�\213\217�\234\201常�\236�\202�\205��\211�\200_29_03_2021_03.xlsx
│   ├── report_�\237�\213\217�\234\201常�\236�\202�\205��\211�\200_29_03_2021_04.xlsx
│   └── report_�\237�\213\217�\234\201常�\236�\202�\205��\211�\200_29_03_2021_05.xlsx
├── huibi_2.csv
├── huobi2021.3.29
│   ├── 5871_forensic.xlsx
│   └── huobi_inout.csv
├── �\201��\201.xlsx
└── �\201�\2112021.3.29.rar
*/


\COPY okex_deposit FROM '~/blockchain/OKEX2.9/liudefeng-in.csv' csv header;
\COPY okex_deposit FROM '~/blockchain/OKEX2.9/wuhao-in.csv' csv header;
\COPY okex_deposit FROM '~/blockchain/OKEX2021.3.1/wuhao_in.csv' csv header;
\COPY okex_deposit FROM '~/blockchain/OKEX2021.3.1/xuxinyue_in.csv' csv header;
\COPY okex_deposit FROM '~/blockchain/OKEX2021.3.3/yuankeqin_in.csv' csv header;
\COPY okex_deposit FROM '~/blockchain/OKEX2021.3.3/zhaolixiang_in.csv' csv header;

\COPY okex_withdraw FROM '~/blockchain/OKEX2.9/liudefeng-out.csv' csv header;
\COPY okex_withdraw FROM '~/blockchain/OKEX2.9/wuhao-out.csv' csv header;
\COPY okex_withdraw FROM '~/blockchain/OKEX2021.3.1/wuhao_out.csv' csv header;
\COPY okex_withdraw FROM '~/blockchain/OKEX2021.3.1/xuxinyue_out.csv' csv header;
\COPY okex_withdraw FROM '~/blockchain/OKEX2021.3.3/yuankeqin_out.csv' csv header;
\COPY okex_withdraw FROM '~/blockchain/OKEX2021.3.3/zhaolixiang_out.csv' csv header;


/*
单独取okex的txid

okex_deposit表的交易的to标识为okex

to的to为okex_pool(TODO: 如果是USDT代币，需要验证)

需要过滤地址为eth的(以0x开头)

需要都转换为小写
*/
SELECT distinct(lower(txid))
INTO okex_deposit_txid_eth
FROM okex_deposit
WHERE lower(txid) like '0x%';


/*
单独取okex的txid

okex_withdraw表的交易的from标识为okex_pool

需要过滤地址为eth的(以0x开头)

需要都转换为小写
*/
SELECT distinct(lower(txid))
INTO okex_withdraw_txid_eth
FROM okex_withdraw
WHERE lower(txid) like '0x%';

/*
打标签之前先统计原来okex和okex_pool的数量
然后重新打标签 @fangmiao
之后重新通过两个标签的数量
*/
SELECT tag_name, count(1) 
FROM t_tag
WHERE tag_name like 'okex%'
GROUP BY tag_name;


------------------------------------------------BINANCE------------------------------------------------------------------


-- 导入binance数据
\COPY binance_deposit FROM '~/blockchain/binance2021.3.29/in_binance_29_03_2021_01.csv' csv header;
\COPY binance_deposit FROM '~/blockchain/binance2021.3.29/in_report_29_03_2021_02.csv' csv header;
\COPY binance_deposit FROM '~/blockchain/binance2021.3.29/in_report_29_03_2021_03.csv' csv header;
\COPY binance_deposit FROM '~/blockchain/binance2021.3.29/in_report_29_03_2021_04.csv' csv header;
\COPY binance_deposit FROM '~/blockchain/binance2021.3.29/in_report_29_03_2021_05.csv' csv header;

\COPY binance_withdraw FROM '~/blockchain/binance2021.3.29/out_binance_29_03_2021_01.csv' csv header;
\COPY binance_withdraw FROM '~/blockchain/binance2021.3.29/out_report_29_03_2021_02.csv' csv header;
\COPY binance_withdraw FROM '~/blockchain/binance2021.3.29/out_report_29_03_2021_03.csv' csv header;
\COPY binance_withdraw FROM '~/blockchain/binance2021.3.29/out_report_29_03_2021_04.csv' csv header;
\COPY binance_withdraw FROM '~/blockchain/binance2021.3.29/out_report_29_03_2021_05.csv' csv header;


/*
单独取binance的txid

binance_deposit表的交易的to标识为binance

to的to为binance_pool(TODO: 如果是USDT代币，需要验证)

需要过滤地址为eth的(以0x开头)

需要都转换为小写
*/
SELECT distinct(lower(txid))
INTO binance_deposit_txid_eth
FROM binance_deposit
WHERE lower(txid) like '0x%';


/*
单独取binance的txid

binance_withdraw表的交易的from标识为binance_pool

需要过滤地址为eth的(以0x开头)

需要都转换为小写
*/
SELECT distinct(lower(txid))
INTO binance_withdraw_txid_eth
FROM binance_withdraw
WHERE lower(txid) like '0x%';

/*
打标签之前先统计原来binance和binance_pool的数量
然后重新打标签 @fangmiao
之后重新通过两个标签的数量
*/
SELECT tag_name, count(1) 
FROM t_tag
WHERE tag_name like 'binance%'
GROUP BY tag_name;
