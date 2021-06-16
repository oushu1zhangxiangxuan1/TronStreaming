CREATE TABLE block
(
block_basic_reward text,
block_hash text,
block_height text,
block_reward text,
block_reward_percentage text,
block_reward_rmb text,
block_reward_usd text,
block_size text,
block_time_in_sec text,
created_ts text,
difficulty text,
extra_data text,
extra_data_decoded text,
fee text,
fee_rmb text,
fee_usd text,
gas_avg_price text,
gas_limit text,
gas_used text,
gas_used_percentage text,
miner_hash text,
miner_icon_url text,
miner_name text,
nonce text,
parent_hash text,
time_in_sec text,
total_difficulty text,
total_internal_tx text,
total_tx text,
total_uncle text,
uncle_ref_reward text,
rksj text,
sha3uncles text,
transactionsroot text,
stateroot text,
logsbloom text,
totalfees text,
timestamp text,
miner text,
reward text,
mineraddress text,
minerextra text,
mingasprice text,
maxgasprice text,
txfee text
)
with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);


CREATE TABLE transa
(
hash text,
blockhash text,
blocknumber text,
transactionto text,
transactionfrom text,
value text,
nonce text,
gasprice text,
gaslimit text,
gasused text,
data text,
transactionindex text,
success text,
state text,
timestamp text,
rksj text,
amount text,
fee text,
tx_type text,
created_ts text,
status text,
sender_type text,
receiver_type text,
creates text
)
with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);


CREATE TABLE dbjy
(
tx_hash text,
block_height text,
created_ts text,
time_in_sec text,
sender_hash text,
receiver_hash text,
amount text,
token_hash text,
token_name text,
token_decimal text,
unit_name text,
token_found text,
sender_name text,
receiver_name text,
sender_type text,
receiver_type text,
token_url text,
tx_type text,
token_icon_url text,
glaccount_hash text,
rksj text,
timestamp text,
tokenaddress text,
fromiscontract text,
toiscontract text,
tokenid text
)
with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);

CREATE TABLE internalTransaction
(
blocknumber text,
timestamp text,
transactionhash text,
tokenaddress text,
from1 text,
to1 text,
fromiscontract text,
toiscontract text,
value text,
rksj text,
blockhash text,
type text
)
with (appendonly=true, orientation=orc, compresstype=lz4,dicthreshold=0.8);