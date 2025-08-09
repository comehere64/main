# 替换为具体包名
PKG="com.example.problem.app"  

echo "诊断报告: $PKG"
echo "1. 包是否存在: $(pm path $PKG 2>&1)"
echo "2. 用户状态: $(dumpsys package $PKG | grep -e userId -e 'enabled=')"
echo "3. 数据目录: $(ls -ld /data/data/$PKG 2>&1)"
echo "4. SELinux标签: $(ls -Z /data/data/$PKG 2>&1)"