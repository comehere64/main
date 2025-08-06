#!/system/bin/sh

echo "开机自动触发，开始执行......"
sleep 60
rm -f /data/adb/ADPDEDT/log/ADPDEDT.log
sh /data/adb/modules/ADPDEDT/main.sh 2>&1 | tee /data/adb/ADPDEDT/log/ADPDEDT.log
exit 0