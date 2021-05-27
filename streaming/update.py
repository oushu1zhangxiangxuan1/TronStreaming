# -*- encoding: utf-8 -*-

"""
1. 解析配置，验证hawq连接性
2. 验证outputdir存在且是dir，获取开始块号
3. 如果开始块号对应的文件不存在，则报错
"""

"""
1. 读取开始块号文件
2. 解析并写block表
3. 解析并写trans表
4. 解析并写contract相关表
5. 更新account等信息: 新增用户、余额变动、asset余额变动、frozen等变动
6. 将区块号加一并循环第一步
7. 如果找不到文件则sleep interval秒
"""
