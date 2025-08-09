#!/system/bin/sh

echo "开启 自动清理..."
rm -f /data/adb/ADPDEDT/auto-delete-disjunctor.txt
echo "1" > /data/adb/ADPDEDT/auto-delete-disjunctor.txt
echo "成功"
exit 0