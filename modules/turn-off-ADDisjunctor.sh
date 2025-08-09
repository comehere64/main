#!/system/bin/sh

echo "关闭 自动清理..."
rm -f /data/adb/ADPDEDT/auto-delete-disjunctor.txt
echo "0" > /data/adb/ADPDEDT/auto-delete-disjunctor.txt
echo "成功"
exit 0