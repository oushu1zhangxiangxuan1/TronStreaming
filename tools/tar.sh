压缩
tar -czvf /path/to/file.tar.gz file

解压
tar -xzvf /path/to/file.tar.gz /path/to

加密压缩
tar -czvf - file | openssl des3 -salt -k password -out /path/to/file.tar.gz

解密解压
openssl des3 -d -k password -salt -in /path/to/file.tar.gz | tar xzf -
# ————————————————
# 版权声明：本文为CSDN博主「u010359663」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
# 原文链接：https://blog.csdn.net/u010359663/article/details/84923693

pip install -i https://pypi.tuna.tsinghua.edu.cn/simple