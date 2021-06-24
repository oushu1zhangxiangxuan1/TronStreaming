import sha3

a = [
    "name()",
    "symbol()",
    "totalSupply()",
    "balanceOf(address)",
    "ownerOf(uint256)",
    "approve(address,uint256)",
    "transfer(address,uint256)",
    "transfer(address,address,uint256)",
    "approve(address,address,uint256)",
    "transferFrom(address,address,uint256)",
    "tokensOfOwner(address)",
    "tokenMetadata(uint256,string)",
    "Transfer(address,uint256)",
    "Approval(address,uint256)",
    "Transfer(address,address,uint256)",
    "Approval(address,address,uint256)",
]

# transfer(address _to,uint256 _value)
for s in a:
    k = sha3.keccak_256()
    k.update(s.encode())
    k.hexdigest()

# "06fdde0383f15d582d1a74511486c9ddf862a882fb7904b3d9fe9b8b8e58a796"
# "95d89b41e2f5f391a79ec54e9d87c79d6e777c63e32c28da95b4e9e4a79250ec"
# "18160ddd7f15c72528c2f94fd8dfe3c8d5aa26e2c50c7d81f4bc7bee8d4b7932"
# "70a08231b98ef4ca268c9cc3f6b4590e4bfec28280db06bb5d45e689f2a360be"
# "6352211e6566aa027e75ac9dbf2423197fbd9b82b9d981a3ab367d355866aa1c"
# "095ea7b334ae44009aa867bfb386f5c3b4b443ac6f0ee573fa91c4608fbadfba"
# "a9059cbb2ab09eb219583f4a59a5d0623ade346d962bcd4e46b11da047c9049b"
# "beabacc8ffedac16e9a60acdb2ca743d80c2ebb44977a93fa8e483c74d2b35a8"
# "e1f21c67180317619fcafa578cb44275002011f9ad81f61220c62be2c4415336"
# "23b872dd7302113369cda2901243429419bec145408fa8b352b3dd92b66c680b"
# "8462151cfcc0f257319f78db464014651918f3905b3d4bdab48d3f4618c542c1"
# "0560ff44c470b66135b184f41c47840de0a42f8d70ee772ca647210e9eb3c8fd"
# "69ca02dd4edd7bf0a4abb9ed3b7af3f14778db5d61921c7dc7cd545266326de2"
# "1e4109814b4fb1210f81ef6540a9bf7e5834ff79536859d16d6398f0e417c44f"
# "ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
# "8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"

"""
https://tronscan.org/#/transaction/f5b54e2bf7caaca5aa8a0489caf7e77f4494e61a480e3f282d1d69cf21469683
对应的topic 0 为 ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef 不在以上的结果中
"""
"""transaction_info结果
{
    "id": "f5b54e2bf7caaca5aa8a0489caf7e77f4494e61a480e3f282d1d69cf21469683",
    "fee": 1518440,
    "blockNumber": 31323374,
    "blockTimeStamp": 1624441182000,
    "contractResult": [
        "0000000000000000000000000000000000000000000000000000000000000000"
    ],
    "contract_address": "41a614f803b6fd780986a42c78ec9c7f77e6ded13c",
    "receipt": {
        "energy_fee": 1518440,
        "origin_energy_usage": 3785,
        "energy_usage_total": 14631,
        "net_usage": 345,
        "result": "SUCCESS"
    },
    "log": [
        {
            "address": "a614f803b6fd780986a42c78ec9c7f77e6ded13c",
            "topics": [
                "ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
                "000000000000000000000000ddc57be9d3ba267ae5f537551fc1a9f91b210407",
                "00000000000000000000000073eea152d966b1a4643f5ea49af36e226dcecfd4"
            ],
            "data": "000000000000000000000000000000000000000000000000000000000a6e49c0"
        }
    ]
}
"""

import hashlib

for s in a:
    k = hashlib.sha256(s.encode())
    k.hexdigest()

# '1581f81c1a8d369245edd6d2b5154e31497fd55e8c53e4f09e64959ca87bdaf7'
# '25967ca55846a2be3dd71526d99f3491222c879c52d0c060ede7e143d250b690'
# 'a368022e521d31b63c6d374fc6ca34d3541bae2aa44c8c20f59c649dc135c9a7'
# '5b46f8f6abe86fe49ac381972fa285e012f43b979dfa796e790003b0445642ef'
# '06f6d69b54b1d54e6ad2425388813e471536b5de2ce509c78b3713b12ec57a75'
# '9f0bb8a9deafa4881b85d434c1fccdb064584a4809dbcba57a86f5b4c559246b'
# '3b88ef57741163446a56d5b602d54622bc234e5511bc6ce011ceec1cfb8e0578'
# '4b6685e79c4a3b3365313e3a4e432f1cebfdaa641363ae7abd71dcbce486f261'
# '38889b39d29f6ad9dfddfc8d7d796c5046301ccb401d696f1fe010344a1c8a5e'
# 'bf00cb014e19249ff4c8aff0e0e5d502910518f41937d95f4cd46ad5f392c28c'
