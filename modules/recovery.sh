#!/system/bin/sh

# 配置文件路径
PACKAGE_FILE="/data/adb/modules/ADPDEDT/Environment_Detection_Tools_list.txt"
ANDROID_DATA_DIR="/sdcard/Android/data"
EXT_DATA_RW_GID=1078  # SD卡读写组ID

# 安全创建目录函数
clean_create_dir() {
    # 去除首尾空格
    local path="${1%"${1##*[![:space:]]}"}"  # 尾部
    path="${path#"${path%%[![:space:]]*}"}"  # 首部
    
    # 创建目录并返回规范路径
    mkdir -p "$path" 2>/dev/null
    echo "$path"
}

# 三方案获取UID方案
get_uid() {
    pkg="$1"
    # 清理包名空格
    pkg="${pkg#"${pkg%%[![:space:]]*}"}"
    pkg="${pkg%"${pkg##*[![:space:]]}"}"
    
    local uid=""
    
    ################################################################
    ### 方案1：dumpsys（首选方案）
    ################################################################
    uid=$(dumpsys package "$pkg" 2>/dev/null | 
        grep -Eo 'userId=[0-9]+' | 
        cut -d= -f2)
    
    ################################################################
    ### 方案2：pm命令（Android 6.0+ 通用备选）
    ################################################################
    [ -z "$uid" ] && 
    uid=$(pm list packages -U --show-versioncode 2>/dev/null | 
        grep "$pkg" | 
        sed -E 's/.*:([0-9]+).*/\1/')
    
    ################################################################
    ### 方案3：数据目录检查（最终回退）
    ################################################################
    if [ -z "$uid" ] && [ -d "/data/data/$pkg" ]; then
        # stat获取目录所属UID
        uid=$(stat -c "%u" "/data/data/$pkg" 2>/dev/null)
        
        # 特殊设备busybox兼容
        [ -z "$uid" ] && 
        uid=$(ls -ldn "/data/data/$pkg" | awk '{print $3}' 2>/dev/null)
    fi
    
    # 返回最终结果（可能为空）
    echo "$uid"
}

# 处理主逻辑
android_dir=$(clean_create_dir "$ANDROID_DATA_DIR")

while IFS= read -r raw_line || [ -n "$raw_line" ]; do
    # 清理行内容
    pkg="${raw_line%"${raw_line##*[![:space:]]}"}"
    pkg="${pkg#"${pkg%%[![:space:]]*}"}"
    
    # 跳过空行/注释
    [ -z "$pkg" ] || [ "${pkg:0:1}" = "#" ] && continue
    
    # 构建路径
    pkg_dir="$android_dir/${pkg}"
    
    # 跳过已存在目录
    [ -d "$pkg_dir" ] && {
        echo "[已存在] $pkg_dir"
        continue
    }
    
    # 三重方案获取UID
    uid=$(get_uid "$pkg")
    
    # 诊断无法获取UID的情况
    if [ -z "$uid" ]; then
        echo "[错误] 无法获取 $pkg 的UID"
        echo "|-- 可能原因:"
        echo "|   1. 应用未安装 (pm path $pkg)"
        echo "|   2. 多用户环境 (dumpsys package $pkg | grep userId)"
        echo "|   3. SELinux限制 (dmesg | grep avc)"
        continue
    fi
    
    # 创建目录
    if cleaned_path=$(clean_create_dir "$pkg_dir"); then
        # 设置权限和安全上下文
        if chown "$uid:$uid" "$cleaned_path" &&
           chown :$EXT_DATA_RW_GID "$cleaned_path" &&
           chmod 771 "$cleaned_path" &&
           chcon u:object_r:app_data_file:s0 "$cleaned_path" 2>/dev/null
        then
            echo "[成功] $cleaned_path"
            echo "|-- UID: $uid, GID: $EXT_DATA_RW_GID, 权限: 771"
        else
            # 回滚创建失败的目录
            rmdir "$cleaned_path" 2>/dev/null
            echo "[权限错误] $pkg (可能缺乏root权限)"
        fi
    else
        echo "[创建失败] $pkg_dir (文件系统只读？)"
    fi
done < "$PACKAGE_FILE"

echo "执行完毕"