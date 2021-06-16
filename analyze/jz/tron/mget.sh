#!/bin/bash

while :
do

    if [[ -a ~/list_ftp_file ]]; then 
        rm -rf ~/list_ftp_file
    fi;

#获取ftp的文件列表
    ftp -v -n 50.56.76.48 <<EOF
	open  50.56.76.48 21
	user jz_ws njws
	binary
	cd /oushu/data/stream_data/2961_2965w/streaming/data/
	lcd ~
	nlist * list_ftp_file
	prompt
	close
	bye
EOF

	#避免list_ftp_file文件未写完就读取导致偏移量不准确
	sleep 2
	#获取ftp服务器最旧的文件，不带.json
	min_ftp_file=`cat ~/list_ftp_file | head -n 1 | awk -F "." '{print $1}'`

	#获取ftp服务器最新的文件，不带.json
	max_ftp_file=`cat ~/list_ftp_file | tail -n 1 | awk -F "." '{print $1}'`

	#获取本地最新文件，不带.json
	max_local_file=`ls -v /DATA/oushu/data/stream_data/2961_2965w/streaming/data | tail -n  1 | awk -F "." '{print $1}'`


	echo "最小的ftp文件是："${min_ftp_file}
	
	echo "最大的ftp文件是："${max_ftp_file}
	
	echo "最大的local文件是："${max_local_file}


	#如果本地目录文件夹为空
	if [ ! ${max_local_file} ]; then
		echo "本地无文件，准备下载全部文件..."
		for((i=${min_ftp_file};i<=${max_ftp_file};i++))
			do
				 ftp -v -n 50.56.76.48 <<EOF
				 open  50.56.76.48 21
				 user jz_ws njws
				 binary
				 cd   /oushu/data/stream_data/2961_2965w/streaming/data/
				 lcd /DATA/oushu/data/stream_data/2961_2965w/streaming/data
				 prompt
				 get $i.json
				 close
				 bye
EOF
				#sleep 0.1
			done
		sleep 1

	#否则下载本地中没有的文件
	else
		for((i=${max_local_file}+1;i<=${max_ftp_file};i++))
			do
				 ftp -v -n 50.56.76.48 <<EOF
				 open  50.56.76.48 21
				 user jz_ws njws
				 binary
				 cd   /oushu/data/stream_data/2961_2965w/streaming/data/
				 lcd /DATA/oushu/data/stream_data/2961_2965w/streaming/data
				 prompt
				 get $i.json
				 close
				 bye
EOF
				#sleep 0.1
			done
		sleep 1
	fi
done