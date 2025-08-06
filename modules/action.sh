#!/system/bin/sh

rm -f /data/adb/ADPDEDT/log/ADPDEDT.log
echo "手动触发，开始执行......" | tee /data/adb/ADPDEDT/log/ADPDEDT.log
sh /data/adb/modules/ADPDEDT/main.sh 2>&1 | tee -a /data/adb/ADPDEDT/log/ADPDEDT.log
exit 0