copy error_block_num from '/data2/20210425/block_parsed/error_block_num/29000000-29617378.csv' csv;
copy block from '/data2/20210425/block_parsed/block/29000000-29617378.csv' csv;
copy trans from '/data2/20210425/block_parsed/trans/29000000-29617378.csv' csv;
copy trans_market_order_detail from '/data2/20210425/block_parsed/trans_market_order_detail/29000000-29617378.csv' csv;
copy trans_auths from '/data2/20210425/block_parsed/trans_auths/29000000-29617378.csv' csv;
copy account_create_contract from '/data2/20210425/block_parsed/account_create_contract/29000000-29617378.csv' csv;
copy transfer_contract from '/data2/20210425/block_parsed/transfer_contract/29000000-29617378.csv' csv;
copy transfer_asset_contract from '/data2/20210425/block_parsed/transfer_asset_contract/29000000-29617378.csv' csv;
copy vote_asset_contract from '/data2/20210425/block_parsed/vote_asset_contract/29000000-29617378.csv' csv;
copy vote_witness_contract from '/data2/20210425/block_parsed/vote_witness_contract/29000000-29617378.csv' csv;
copy witness_create_contract from '/data2/20210425/block_parsed/witness_create_contract/29000000-29617378.csv' csv;
copy asset_issue_contract from '/data2/20210425/block_parsed/asset_issue_contract/29000000-29617378.csv' csv;
copy asset_issue_contract_frozen_supply from '/data2/20210425/block_parsed/asset_issue_contract_frozen_supply/29000000-29617378.csv' csv;
copy witness_update_contract from '/data2/20210425/block_parsed/witness_update_contract/29000000-29617378.csv' csv;
copy participate_asset_issue_contract from '/data2/20210425/block_parsed/participate_asset_issue_contract/29000000-29617378.csv' csv;
copy account_update_contract from '/data2/20210425/block_parsed/account_update_contract/29000000-29617378.csv' csv;
copy freeze_balance_contract from '/data2/20210425/block_parsed/freeze_balance_contract/29000000-29617378.csv' csv;
copy unfreeze_balance_contract from '/data2/20210425/block_parsed/unfreeze_balance_contract/29000000-29617378.csv' csv;
copy withdraw_balance_contract from '/data2/20210425/block_parsed/withdraw_balance_contract/29000000-29617378.csv' csv;
copy unfreeze_asset_contract from '/data2/20210425/block_parsed/unfreeze_asset_contract/29000000-29617378.csv' csv;
copy update_asset_contract from '/data2/20210425/block_parsed/update_asset_contract/29000000-29617378.csv' csv;
copy proposal_create_contract from '/data2/20210425/block_parsed/proposal_create_contract/29000000-29617378.csv' csv;
copy proposal_approve_contract from '/data2/20210425/block_parsed/proposal_approve_contract/29000000-29617378.csv' csv;
copy proposal_delete_contract from '/data2/20210425/block_parsed/proposal_delete_contract/29000000-29617378.csv' csv;
copy set_account_id_contract from '/data2/20210425/block_parsed/set_account_id_contract/29000000-29617378.csv' csv;
copy create_smart_contract from '/data2/20210425/block_parsed/create_smart_contract/29000000-29617378.csv' csv;
copy trigger_smart_contract from '/data2/20210425/block_parsed/trigger_smart_contract/29000000-29617378.csv' csv;
copy update_setting_contract from '/data2/20210425/block_parsed/update_setting_contract/29000000-29617378.csv' csv;
copy exchange_create_contract from '/data2/20210425/block_parsed/exchange_create_contract/29000000-29617378.csv' csv;
copy exchange_inject_contract from '/data2/20210425/block_parsed/exchange_inject_contract/29000000-29617378.csv' csv;
copy exchange_withdraw_contract from '/data2/20210425/block_parsed/exchange_withdraw_contract/29000000-29617378.csv' csv;
copy exchange_transaction_contract from '/data2/20210425/block_parsed/exchange_transaction_contract/29000000-29617378.csv' csv;
copy update_energy_limit_contract from '/data2/20210425/block_parsed/update_energy_limit_contract/29000000-29617378.csv' csv;
copy account_permission_update_contract from '/data2/20210425/block_parsed/account_permission_update_contract/29000000-29617378.csv' csv;
copy clear_abi_contract from '/data2/20210425/block_parsed/clear_abi_contract/29000000-29617378.csv' csv;
copy update_brokerage_contract from '/data2/20210425/block_parsed/update_brokerage_contract/29000000-29617378.csv' csv;
copy shielded_transfer_contract from '/data2/20210425/block_parsed/shielded_transfer_contract/29000000-29617378.csv' csv;


-- SELECT
select count(1) from error_block_num;
select count(1) from block;
select count(1) from trans;
select count(1) from trans_market_order_detail;
select count(1) from trans_auths;
select count(1) from account_create_contract;
select count(1) from transfer_contract;
select count(1) from transfer_asset_contract;
select count(1) from vote_asset_contract;
select count(1) from vote_witness_contract;
select count(1) from witness_create_contract;
select count(1) from asset_issue_contract;
select count(1) from asset_issue_contract_frozen_supply;
select count(1) from witness_update_contract;
select count(1) from participate_asset_issue_contract;
select count(1) from account_update_contract;
select count(1) from freeze_balance_contract;
select count(1) from unfreeze_balance_contract;
select count(1) from withdraw_balance_contract;
select count(1) from unfreeze_asset_contract;
select count(1) from update_asset_contract;
select count(1) from proposal_create_contract;
select count(1) from proposal_approve_contract;
select count(1) from proposal_delete_contract;
select count(1) from set_account_id_contract;
select count(1) from create_smart_contract;
select count(1) from trigger_smart_contract;
select count(1) from update_setting_contract;
select count(1) from exchange_create_contract;
select count(1) from exchange_inject_contract;
select count(1) from exchange_withdraw_contract;
select count(1) from exchange_transaction_contract;
select count(1) from update_energy_limit_contract;
select count(1) from account_permission_update_contract;
select count(1) from clear_abi_contract;
select count(1) from update_brokerage_contract;
select count(1) from shielded_transfer_contract;




select * from error_block_num limit 5;
select * from block limit 5;
select * from trans limit 5;
select * from trans_market_order_detail limit 5;
select * from trans_auths limit 5;
select * from account_create_contract limit 5;
select * from transfer_contract limit 5;
select * from transfer_asset_contract limit 5;
select * from vote_asset_contract limit 5;
select * from vote_witness_contract limit 5;
select * from witness_create_contract limit 5;
select * from asset_issue_contract limit 5;
select * from asset_issue_contract_frozen_supply limit 5;
select * from witness_update_contract limit 5;
select * from participate_asset_issue_contract limit 5;
select * from account_update_contract limit 5;
select * from freeze_balance_contract limit 5;
select * from unfreeze_balance_contract limit 5;
select * from withdraw_balance_contract limit 5;
select * from unfreeze_asset_contract limit 5;
select * from update_asset_contract limit 5;
select * from proposal_create_contract limit 5;
select * from proposal_approve_contract limit 5;
select * from proposal_delete_contract limit 5;
select * from set_account_id_contract limit 5;
select * from create_smart_contract limit 5;
select * from trigger_smart_contract limit 5;
select * from update_setting_contract limit 5;
select * from exchange_create_contract limit 5;
select * from exchange_inject_contract limit 5;
select * from exchange_withdraw_contract limit 5;
select * from exchange_transaction_contract limit 5;
select * from update_energy_limit_contract limit 5;
select * from account_permission_update_contract limit 5;
select * from clear_abi_contract limit 5;
select * from update_brokerage_contract limit 5;
select * from shielded_transfer_contract limit 5;


-- trans
select id, block_num, contract_type,asset_issue_id from trans where asset_issue_id is not null limit 5;
select    
    id,
    block_num ,
    asset_issue_id ,
    order_id ,
    -- ret END--
    -- raw START
    ref_block_hash ,
    scripts ,
    scripts_decode ,
    data ,
    data_decode ,
    -- raw END
    signature   FROM trans
limit 5;


select    
    id,
    block_num ,
    scripts ,
    scripts_decode ,
    data ,
    data_decode ,
    -- raw END
    signature 
    FROM trans
    where scripts is not null
limit 5;