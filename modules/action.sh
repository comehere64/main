#!/system/bin/sh

# rm -f /data/adb/ADPDEDT/log/ADPDEDT.log
sh /data/adb/modules/ADPDEDT/main.sh 2>&1 | tee /data/adb/ADPDEDT/log/ADPDEDT.log
exit 0