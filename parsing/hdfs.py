# from hdfs import InsecureClient
# import csv

# client = InsecureClient('http://192.168.43.142:50070', user='hdfs')
# writer = client.write('/tron.csv', append=True)
# with client.write('/tron.csv', append=True) as writer:


import pyhdfs

client = pyhdfs.HdfsClient(hosts="192.168.43.142:50070", user_name="hdfs")

response = client.open("/user/hadoop/speech_text.txt")

response.read()
