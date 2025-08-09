#!/system/bin/sh

# 文件名：recovery.sh
# 功能：批量创建/修复指定应用的Android数据目录
# 用法：sh recovery.sh [配置文件路径]，具体有3种用法:

# 方式1：使用默认配置文件（/data/adb/modules/ADPDEDT/Environment_Detection_Tools_list.txt）
# su -c sh recovery.sh
# 方式2：指定自定义配置文件
# su -c sh recovery.sh /path/to/your/config.txt
# 方式3：直接将包名作为参数传递给脚本
# su -c sh recovery.sh "com.app1,com.app2,com.app3"



# 默认配置文件路径
CONFIG_FILE="/data/adb/modules/ADPDEDT/Environment_Detection_Tools_list.txt"

# 使用自定义配置文件（如果提供了参数）
if [ $# -ge 1 ]; then
    CONFIG_FILE="$1"
fi

# 检查root权限
if [ "$(whoami)" != "root" ]; then
    echo "错误：需要root权限！请使用'su -c'执行"
    exit 1
fi

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "配置文件不存在: $CONFIG_FILE"
    echo "创建示例配置文件..."
    
    # 创建示例配置文件
    echo "# 需要恢复数据目录的应用包名列表" > "$CONFIG_FILE"
    echo "# 每行一个包名，空行和#开头行会被忽略" >> "$CONFIG_FILE"
    echo "# 示例：" >> "$CONFIG_FILE"
    echo "# com.example.app1" >> "$CONFIG_FILE"
    echo "# com.company.app2" >> "$CONFIG_FILE"
    echo "com.spotify.music" >> "$CONFIG_FILE"
    echo "com.instagram.android" >> "$CONFIG_FILE"
    
    echo "已创建示例配置文件: $CONFIG_FILE"
    echo "请编辑此文件后重新运行脚本"
    exit 0
fi

# 主处理函数
process_app() {
    local pkg="$1"
    local base_dir="$2"
    local target_dir="${base_dir}/${pkg}"
    
    # 获取应用的UID
    local uid=$(pm list packages -U | grep "$pkg" | head -1 | cut -d':' -f3)
    
    if [ -z "$uid" ]; then
        echo "  [!] 包名未安装: $pkg"
        return 1
    fi
    
    # 创建目录（如果不存在）
    if [ ! -d "$target_dir" ]; then
        echo "  [+] 创建目录: $target_dir"
        mkdir -p "$target_dir"
        
        # 设置所有权和权限
        chown "$uid:$uid" "$target_dir"
        chmod 771 "$target_dir"
        
        # 修复SELinux上下文（如果可用）
        if command -v restorecon &>/dev/null; then
            restorecon "$target_dir"
        fi
    else
        # 修复现有目录的权限
        local current_owner=$(stat -c '%u' "$target_dir" 2>/dev/null)
        
        if [ "$current_owner" != "$uid" ]; then
            echo "  [!] 修复所有权: $target_dir (原UID:$current_owner -> 新UID:$uid)"
            chown "$uid:$uid" "$target_dir"
        fi
    fi
}

# 检查是否支持多个用户
echo "检测设备存储配置..."
USER_IDS=("0")  # 默认主用户

# 检测多用户支持（Android for Work等）
if pm list users &>/dev/null; then
    echo "检测到多用户支持..."
    USER_IDS=$(pm list users | grep 'UserInfo' | sed -E 's/.*UserInfo\{([0-9]+).*/\1/')
fi

# 处理所有包名
echo "处理配置文件中的应用程序..."
while IFS= read -r line; do
    # 跳过注释行和空行
    [[ "$line" =~ ^# || -z "$line" ]] && continue
    
    # 去除空格
    pkg=$(echo "$line" | tr -d '[:space:]')
    
    # 处理每个用户的存储空间
    for user_id in $USER_IDS; do
        # 确定基础目录路径
        if [ -d "/storage/emulated/${user_id}" ]; then
            base_dir="/storage/emulated/${user_id}/Android/data"
        elif [ -d "/data/media/${user_id}" ]; then
            base_dir="/data/media/${user_id}/Android/data"
        else
            echo "  [!] 用户${user_id}存储不可访问"
            continue
        fi
        
        # 确保父目录存在
        if [ ! -d "$base_dir" ]; then
            mkdir -p "$base_dir"
            chown root:root "$base_dir"
            chmod 770 "$base_dir"
        fi
        
        # 处理应用
        echo "[用户 $user_id] 处理: $pkg"
        process_app "$pkg" "$base_dir"
    done
done < "$CONFIG_FILE"

echo "操作完成!"
echo "已处理所有在配置文件中的应用程序"
echo "配置文件位置: $CONFIG_FILE"