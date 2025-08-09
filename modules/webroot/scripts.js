// 全局标记，防止重复执行操作
let actionRunning = false;

// 记录初始双指距离，用于字体缩放计算
let initialPinchDistance = null;

// 当前终端字体大小（像素）
let currentFontSize = 14;

// 字体缩放的最小限制
const MIN_FONT_SIZE = 8;

// 字体缩放的最大限制
const MAX_FONT_SIZE = 24;

/**
 * 使用 KernelSU 执行 shell 命令
 * @param {string} command - 要执行的 shell 命令
 * @returns {Promise<string>} 返回包含命令输出的 Promise
 */
async function execCommand(command) {
    // 生成唯一回调函数名（使用时间戳避免冲突）
    const callbackName = `exec_callback_${Date.now()}`;
    
    return new Promise((resolve, reject) => {
        // 在全局对象上定义临时回调函数
        window[callbackName] = (errno, stdout, stderr) => {
            // 执行后立即删除回调函数（避免内存泄漏）
            delete window[callbackName];
            // 根据错误码判断执行结果
            errno === 0 ? resolve(stdout) : reject(stderr);
        };
        
        // 调用 KernelSU 执行命令
        // 参数：命令字符串，空选项对象，回调函数名
        ksu.exec(command, "{}", callbackName);
    });
}

/** 初始化按钮事件监听器 */
function applyButtonEventListeners() {
    // 获取所有按钮元素
    const script1Button = document.getElementById('script1');
    const script2Button = document.getElementById('script2');
    const script3Button = document.getElementById('script3');
    const script4Button = document.getElementById('script4');
    const script5Button = document.getElementById('script5');
    
    // 获取清除终端按钮元素
    const clearButton = document.querySelector('.clear-terminal');

    // 为所有按钮添加点击事件监听器
    script1Button.addEventListener('click', runScript1);
    script2Button.addEventListener('click', runScript2);
    script3Button.addEventListener('click', runScript3);
    script4Button.addEventListener('click', runScript4);
    script5Button.addEventListener('click', runScript5);
    
    // 为清除按钮添加点击事件监听器
    clearButton.addEventListener('click', () => {
        // 获取输出终端的内容容器
        const output = document.querySelector('.output-terminal-content');
        // 清空所有输出内容
        output.innerHTML = '';
        // 重置字体大小为默认值
        currentFontSize = 14;
        // 应用新的字体大小
        updateFontSize(currentFontSize);
    });

    // 获取终端输出区域元素
    const terminal = document.querySelector('.output-terminal-content');
    
    // 添加触摸开始事件监听器（双指手势检测）
    terminal.addEventListener('touchstart', (e) => {
        // 当检测到两个触摸点时
        if (e.touches.length === 2) {
            // 阻止默认滚动行为
            e.preventDefault();
            // 计算并存储初始双指距离
            initialPinchDistance = getDistance(e.touches[0], e.touches[1]);
        }
    }, { passive: false }); // 允许 preventDefault 阻止滚动

    // 添加触摸移动事件监听器（双指缩放）
    terminal.addEventListener('touchmove', (e) => {
        // 当两个触摸点移动时
        if (e.touches.length === 2) {
            // 阻止默认滚动行为
            e.preventDefault();
            // 计算当前双指距离
            const currentDistance = getDistance(e.touches[0], e.touches[1]);
            
            // 如果尚未设置初始距离（首次移动）
            if (initialPinchDistance === null) {
                // 设置当前距离为初始距离
                initialPinchDistance = currentDistance;
                return;
            }

            // 计算缩放比例（当前距离 / 初始距离）
            const scale = currentDistance / initialPinchDistance;
            // 基于当前字体计算新字体大小
            const newFontSize = currentFontSize * scale;
            // 应用新的字体大小（含边界限制）
            updateFontSize(newFontSize);
            // 更新初始距离为当前距离（用于下次计算）
            initialPinchDistance = currentDistance;
        }
    }, { passive: false }); // 允许 preventDefault 阻止滚动

    // 添加触摸结束事件监听器
    terminal.addEventListener('touchend', () => {
        // 重置初始距离（手势结束）
        initialPinchDistance = null;
    });
}

/** 从模块配置文件中加载版本号 */
async function loadVersionFromModuleProp() {
    // 获取显示版本的 DOM 元素
    const versionElement = document.getElementById('version-text');
    try {
        // 执行 shell 命令获取版本号：
        // 1. 在 module.prop 中查找 version= 开头的行
        // 2. 提取等号后的值
        const version = await execCommand(
            "grep '^version=' /data/adb/modules/ADPDEDT/module.prop | cut -d'=' -f2"
        );
        // 去除两端空白后显示在界面上
        versionElement.textContent = version.trim();
    } catch (error) {
        // 错误处理：在终端显示错误信息
        appendToOutput("[!] Failed to read version from module.prop");
        // 在控制台打印详细错误
        console.error("Failed to read version from module.prop:", error);
    }
}

/**
 * 向输出终端添加内容
 * @param {string} content - 要输出的内容
 */
function appendToOutput(content) {
    // 获取输出终端的内容容器
    const output = document.querySelector('.output-terminal-content');
    
    // 检查是否为空内容（仅包含空白）
    if (content.trim() === "") {
        // 创建换行元素
        const lineBreak = document.createElement('br');
        // 添加到终端
        output.appendChild(lineBreak);
    } else {
        // 创建段落元素
        const line = document.createElement('p');
        // 设置 CSS 类名
        line.className = 'output-content';
        // 设置文本内容（安全方法，防止 XSS）
        line.textContent = content;
        // 添加到终端
        output.appendChild(line);
    }
    // 自动滚动到底部（确保新内容可见）
    output.scrollTop = output.scrollHeight;
}




/** 执行脚本1 */
async function runScript1() {
    if (actionRunning) return;
    actionRunning = true;
    
    try {
        appendToOutput('[+] 清理 "环境检测工具"私有目录...');
        await new Promise(resolve => setTimeout(resolve, 200));
        
        // 运行对应脚本
        const scriptOutput = await execCommand(
            "sh /data/adb/modules/ADPDEDT/start-delete.sh"
        );
        
        const lines = scriptOutput.split('\n');
        lines.forEach(line => {
            appendToOutput(line)
        });
        appendToOutput("");
    } catch (error) {
        console.error('执行失败:', error);
        appendToOutput("[!] 脚本执行失败");
    }
    actionRunning = false;
}

/** 执行脚本2 */
async function runScript2() {
    if (actionRunning) return;
    actionRunning = true;
    
    try {
        appendToOutput('[+] 还原 "环境检测工具"私有目录...');
        await new Promise(resolve => setTimeout(resolve, 200));
        
        // 运行对应脚本
        const scriptOutput = await execCommand(
            "sh /data/adb/modules/ADPDEDT/start-recovery.sh"
        );
        
        const lines = scriptOutput.split('\n');
        lines.forEach(line => {
            appendToOutput(line)
        });
        appendToOutput("");
    } catch (error) {
        console.error('执行失败:', error);
        appendToOutput("[!] 脚本执行失败");
    }
    actionRunning = false;
}

/** 执行脚本3 */
async function runScript3() {
    if (actionRunning) return;
    actionRunning = true;
    
    try {
        appendToOutput("[+] 开启 自动清理...");
        await new Promise(resolve => setTimeout(resolve, 200));
        
        // 运行对应脚本
        const scriptOutput = await execCommand(
            "sh /data/adb/modules/ADPDEDT/turn-on-ADDisjunctor.sh"
        );
        
        const lines = scriptOutput.split('\n');
        lines.forEach(line => {
            appendToOutput(line)
        });
        appendToOutput("");
    } catch (error) {
        console.error('执行失败:', error);
        appendToOutput("[!] 脚本执行失败");
    }
    actionRunning = false;
}

/** 执行脚本4 */
async function runScript4() {
    if (actionRunning) return;
    actionRunning = true;
    
    try {
        appendToOutput("[+] 关闭 自动清理...");
        await new Promise(resolve => setTimeout(resolve, 200));
        
        // 运行对应脚本
        const scriptOutput = await execCommand(
            "sh /data/adb/modules/ADPDEDT/turn-off-ADDisjunctor.sh"
        );
        
        const lines = scriptOutput.split('\n');
        lines.forEach(line => {
            appendToOutput(line)
        });
        appendToOutput("");
    } catch (error) {
        console.error('执行失败:', error);
        appendToOutput("[!] 脚本执行失败");
    }
    actionRunning = false;
}



/** 执行脚本5 */
async function runScript5() {
    if (actionRunning) return;
    actionRunning = true;
    
    try {
        appendToOutput("[+] 查看日志...");
        await new Promise(resolve => setTimeout(resolve, 200));
        
        // 运行对应脚本
        const scriptOutput = await execCommand(
            "cat /data/adb/ADPDEDT/log/ADPDEDT.log"
        );
        
        const lines = scriptOutput.split('\n');
        lines.forEach(line => {
            appendToOutput(line)
        });
        appendToOutput("");
    } catch (error) {
        console.error('执行失败:', error);
        appendToOutput("[!] 脚本执行失败");
    }
    actionRunning = false;
}


/** 为按钮应用涟漪点击效果 */
function applyRippleEffect() {
    // 遍历所有带涟漪效果的元素
    document.querySelectorAll('.ripple-element').forEach(element => {
        // 检查是否已添加事件监听器
        if (element.dataset.rippleListener !== "true") {
            // 添加指针按下事件（支持鼠标/触摸）
            element.addEventListener("pointerdown", function (event) {
                // 创建涟漪元素
                const ripple = document.createElement("span");
                // 添加涟漪样式类
                ripple.classList.add("ripple");

                // 获取目标元素的边界矩形
                const rect = element.getBoundingClientRect();
                // 元素宽度
                const width = rect.width;
                // 计算涟漪大小（取宽高中较大值）
                const size = Math.max(rect.width, rect.height);
                // 计算涟漪位置（基于点击坐标）
                const x = event.clientX - rect.left - size / 2;
                const y = event.clientY - rect.top - size / 2;

                // 计算动画持续时间（基于元素宽度动态调整）
                let duration = 0.2 + (width / 800) * 0.4;
                // 限制在 0.2-0.8 秒范围内
                duration = Math.min(0.8, Math.max(0.2, duration));

                // 设置涟漪样式
                ripple.style.width = ripple.style.height = `${size}px`;
                ripple.style.left = `${x}px`;
                ripple.style.top = `${y}px`;
                ripple.style.animationDuration = `${duration}s`;
                ripple.style.transition = `opacity ${duration}s ease`;

                // 获取元素实际背景色
                const computedStyle = window.getComputedStyle(element);
                const bgColor = computedStyle.backgroundColor || "rgba(0, 0, 0, 0)";
                
                // 判断背景色是否为深色
                const isDarkColor = (color) => {
                    // 提取 RGB 值
                    const rgb = color.match(/\d+/g);
                    if (!rgb) return false;
                    // 计算亮度（Luma 公式）
                    const [r, g, b] = rgb.map(Number);
                    return (r * 0.299 + g * 0.587 + b * 0.114) < 96;
                };
                
                // 深色背景使用白色涟漪，浅色背景使用默认黑色
                ripple.style.backgroundColor = isDarkColor(bgColor) 
                    ? "rgba(255, 255, 255, 0.2)" 
                    : "";

                // 添加涟漪到元素
                element.appendChild(ripple);
                
                // 定义指针释放处理函数
                const handlePointerUp = () => {
                    // 添加结束类（触发淡出动画）
                    ripple.classList.add("end");
                    // 动画结束后移除元素
                    setTimeout(() => {
                        ripple.classList.remove("end");
                        ripple.remove();
                    }, duration * 1000);
                    // 移除事件监听器
                    element.removeEventListener("pointerup", handlePointerUp);
                    element.removeEventListener("pointercancel", handlePointerUp);
                };
                
                // 添加指针释放事件
                element.addEventListener("pointerup", handlePointerUp);
                element.addEventListener("pointercancel", handlePointerUp);
            });
            
            // 标记元素已添加涟漪监听器
            element.dataset.rippleListener = "true";
        }
    });
}

/**
 * 计算两点间距离
 * @param {Touch} touch1 - 第一个触摸点
 * @param {Touch} touch2 - 第二个触摸点
 * @returns {number} 两点间欧几里得距离
 */
function getDistance(touch1, touch2) {
    // 使用勾股定理计算距离
    return Math.hypot(
        touch1.clientX - touch2.clientX,
        touch1.clientY - touch2.clientY
    );
}

/**
 * 更新终端字体大小
 * @param {number} newSize - 目标字体大小
 */
function updateFontSize(newSize) {
    // 限制字体大小在范围内
    currentFontSize = Math.min(Math.max(newSize, MIN_FONT_SIZE), MAX_FONT_SIZE);
    // 获取终端元素
    const terminal = document.querySelector('.output-terminal-content');
    // 应用新字体大小
    terminal.style.fontSize = `${currentFontSize}px`;
}


async function checkMMRL() {
  if (typeof ksu !== 'undefined' && ksu.mmrl) {
    try {
      // 请求API权限
      $playintegrityfix.requestAdvancedKernelSUAPI();
      // 测试命令执行权限
      await execCommand("whoami");
    } catch (error) {
      appendToOutput("[!] 请授予KernelSU API权限");
      // 显示权限引导信息...
    }
  }
}


// 当 DOM 加载完成后初始化
document.addEventListener('DOMContentLoaded', async () => {
    // 权限检查
    await checkMMRL();
    // 加载模块版本号
    loadVersionFromModuleProp();
    // 初始化按钮事件
    applyButtonEventListeners();
    // 初始化涟漪效果
    applyRippleEffect();
});

