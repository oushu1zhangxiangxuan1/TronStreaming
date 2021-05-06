#  新加坡 包含内部交易
#  http://47.74.159.117/saveInternalTx/backup20210425/FullNode_output-directory.tgz


starttime=`date +'%Y-%m-%d %H:%M:%S'`

echo "==== start download: ${starttime} ===="
echo
wget -nv http://47.74.159.117/saveInternalTx/backup20210425/FullNode_output-directory.tgz
wget -nv http://47.74.159.117/saveInternalTx/backup20210425/FullNode_output-directory.tgz.md5sum
downloadtime=`date +'%Y-%m-%d %H:%M:%S'`
echo "==== start decompress: ${downloadtime} ===="
echo
tar zxvf ./FullNode_output-directory.tgz

endtime=`date +'%Y-%m-%d %H:%M:%S'`
echo "==== done: ${endtime} ===="
echo

start_seconds=$(date --date="$starttime" +%s);
end_seconds=$(date --date="$endtime" +%s);
down_seconds=$(date --date="$downloadtime" +%s);

echo "下载时间： "$((down_seconds-start_seconds))"s"
echo
echo "解压时间： "$((end_seconds-down_seconds))"s"
echo
echo "本次运行时间： "$((end_seconds-start_seconds))"s"
echo