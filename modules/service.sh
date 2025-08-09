#!/system/bin/sh

rm -f /data/adb/ADPDEDT/log/ADPDEDT.log
echo "本脚本为开机自动触发脚本"
sleep 60


echo "检查 自动清理 开关......" | tee /data/adb/ADPDEDT/log/ADPDEDT.log

# 定义开关文件路径
FILE="/data/adb/ADPDEDT/auto-delete-disjunctor.txt"
# 读取文件内容并删除首尾空白字符
CONTENT=$(<"$FILE" tr -d '[:space:]')

# 判断自动清理是否开启
if [ "$CONTENT" = "0" ]; then
    echo "自动清理 已关闭，忽略后续指令并退出" | tee -a /data/adb/ADPDEDT/log/ADPDEDT.log
    exit 0
fi


echo "自动清理 已开启，继续执行后续指令" | tee -a /data/adb/ADPDEDT/log/ADPDEDT.log
sh /data/adb/modules/ADPDEDT/delete.sh 2>&1 | tee -a /data/adb/ADPDEDT/log/ADPDEDT.log
exit 0