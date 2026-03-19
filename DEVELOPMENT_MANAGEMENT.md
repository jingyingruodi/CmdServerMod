# 项目开发管理规范

## 1. 文件夹和文件管理

### 1.1 严格禁止

**❌ 不要在模组文件夹中放置解压的游戏源文件**

```
# 这是错误的做法
F:\Program Files (x86)\Steam\steamapps\common\Desynced\Desynced\Content\mods\CmdServerMod
├── main_server_extracted/  ❌ ← 不要这样做！
├── main_extracted/         ❌ ← 不要这样做！
└── ...
```

**为什么**：
- 游戏会尝试加载这些文件夹作为模组
- 可能导致版本冲突和加载错误
- 浪费磁盘空间
- 污染 Git 仓库

### 1.2 正确做法

**✅ 在外部临时文件夹进行研究**

```
# 临时研究文件夹（不提交到 Git）
C:\Temp\Desynced_Research\
├── main_server_extracted/      ✅ 可以
├── texture_analysis/           ✅ 可以
└── api_documentation/          ✅ 可以
```

**✅ 项目内的文件夹结构**

```
CmdServerMod/
├── def.json
├── simulation/
├── ui/
├── docs/                   # 文档（提交）
│   ├── ARCHITECTURE.md
│   ├── SERVER_COMPATIBILITY.md
│   └── EXTENDING_COMMANDS.md
├── research/              # 研究记录（不含解压文件）
│   ├── API_NOTES.md
│   └── SERVER_ANALYSIS.md
└── .gitignore             # 明确忽略规则
```

### 1.3 .gitignore 规范

```
# 临时文件和解压产物
*_extracted/
*.zip
*.tmp
*.backup
*.swp
*.swo
*~

# 系统文件
.DS_Store
Thumbs.db
desktop.ini

# 日志文件（运行时生成）
*.log
日志.log
Server日志.log

# IDE 文件
.vscode/
.idea/
*.sublime-project
*.sublime-workspace

# 编译产物
dist/
build/

# OS 特定
.DS_Store
$RECYCLE.BIN/
```

---

## 2. 版本管理和发布流程

### 2.1 版本号规范

使用语义化版本（Semantic Versioning）：

```
v主版本.副版本.补丁版本
v1.0.2 = 主版本:1, 副版本:0, 补丁版本:2
```

**版本含义**：
- **主版本**：重大功能变更或架构改变
- **副版本**：新增功能，向后兼容
- **补丁版本**：Bug 修复

### 2.2 发布计划

```
v1.0.x 系列 - 基础阶段（当前）
  ├─ v1.0.0 - 初始发布（命令系统基础）
  ├─ v1.0.1 - 文档完善，快速修复
  └─ v1.0.2 - 双端兼容修复✅当前目标

v1.1.x 系列 - 架构重构
  ├─ v1.1.0 - 重构命令系统，改进双端兼容
  └─ v1.1.1 - 优化和修复

v1.2.x 系列 - 功能扩展
  ├─ v1.2.0 - 添加新命令（/set, /restart 等）
  └─ v1.2.1 - 性能优化

v1.3.x 系列 - 权限系统
  ├─ v1.3.0 - 基础权限框架
  └─ v1.3.1 - 权限管理命令

v2.0.x 系列 - 主要升级
  ├─ v2.0.0 - GUI 界面、插件系统等重大功能
```

### 2.3 发布前检查清单

在每次 Git 提交前：

```
代码质量
☐ 运行 Lua 语法检查
☐ 确保没有调试代码
☐ 移除注释掉的代码

功能测试
☐ 在客户端环境完整测试
☐ 在服务端环境完整测试
☐ 测试所有命令
☐ 测试多人场景（如适用）

文件管理
☐ 没有解压的源文件被提交
☐ 生成的日志文件没有被提交
☐ .gitignore 包含所有临时文件

文档
☐ README.md 已更新
☐ CHANGELOG.md 已更新
☐ 代码有适当注释

Git
☐ Commit 消息清晰（中文或英文）
☐ 没有 merge conflict
☐ 分支干净（无多余文件）
```

---

## 3. 代码质量标准

### 3.1 Lua 编码规范

#### 命名规范

```lua
-- 常量：大写 + 下划线
local MAX_RETRIES = 3
local ERROR_CODE_TIMEOUT = 1001

-- 函数：小写 + 下划线
local function get_player_name(player_id)
end

-- 局部变量：小写 + 下划线
local player_count = 0
local is_enabled = true

-- 全局导出：CamelCase（首字母大写）
CommandSystem = {}
MessageRouter = {}
```

#### 日志输出规范

```lua
-- 格式：[模块名] 消息内容
-- 前缀约定：

-- 服务端输出
print("[SERVER-INPUT] 玩家0: /help")
print("[SERVER-CMD] 命令执行成功")
print("[SERVER-ERROR] 命令执行失败: ...")

-- 客户端输出
print("[CHAT-LOG] 玩家0: 聊天内容")
print("[CMD-EXECUTED] 玩家0 执行命令: /help")
print("[CMD-RESULT] 命令结果内容")

-- 初始化输出
print("[CmdServerMod] 模块已加载")
print("[CmdServerMod] 检测到服务端环境")

-- 错误输出
print("[ERROR] 描述错误信息")
```

#### 错误处理

```lua
-- ✅ 正确：使用 pcall 保护可能出错的代码
local success, error_msg = pcall(cmd.handler, cmd_args)
if not success then
    output_to_chat("执行出错: " .. tostring(error_msg))
end

-- ❌ 错误：忽略错误
cmd.handler(cmd_args)  -- 如果出错会导致游戏崩溃

-- ✅ 正确：验证输入
if not (arg and arg.txt and player_id ~= nil) then
    return  -- 早期返回，避免后续问题
end
```

### 3.2 注释规范

```lua
-- 单行注释用 --
local count = 0  -- 计数器

-- 多行注释
--[[
这是多行注释
用于说明复杂逻辑
]]

-- 函数文档注释（类似 JSDoc）
--[[ 
function execute_command(message, player_id)
    描述：执行聊天命令
    参数：
      - message: string 用户输入的消息
      - player_id: number 执行命令的玩家ID
    返回值：
      - is_command: boolean 是否为命令
      - result: string 命令结果或错误信息
]]
```

---

## 4. 调试和测试流程

### 4.1 日志分析方法

#### 查看客户端日志

```powershell
# 实时查看日志
Get-Content -Path "f:\...\日志.log" -Tail 50 -Wait

# 搜索特定错误
Select-String -Path "f:\...\日志.log" "ERROR|Error"

# 查看最后执行的命令
Select-String -Path "f:\...\日志.log" "\[CMD"
```

#### 查看服务端日志

```powershell
# 类似的方法
Get-Content -Path "D:\DesyncedDedicatedServerTest\...\Server日志.log" -Tail 100

# 搜索服务端特定前缀
Select-String -Path "D:\...\Server日志.log" "\[SERVER-"
```

### 4.2 测试场景

#### 客户端测试

```
1. 单人游戏
   □ /help 命令
   □ /test 命令
   □ /settings 命令
   □ /info 命令
   □ 普通聊天不被中断

2. 多人游戏（2+ 玩家）
   □ 玩家A的命令结果仅显示给A
   □ 玩家B看不到A的命令结果
   □ 普通聊天所有玩家都能看到

3. 错误情况
   □ 输入无效命令时的反馈
   □ 命令参数错误时的提示
```

#### 服务端测试

```
1. 服务器启动
   □ 模组正确加载
   □ [CmdServerMod] 日志显示
   □ [SERVER-] 前缀日志显示

2. 玩家连接
   □ 看到玩家输入日志
   □ 见到玩家执行命令日志

3. 命令执行
   □ [SERVER-CMD] 日志显示
   □ 命令结果在后台显示（不发送给客户端）
   □ 普通聊天仍被记录
```

---

## 5. 沟通和文档

### 5.1 Git Commit 消息规范

```
格式：
[type] 简述（中英文混用可以）

可选详细说明（新起一行）

示例：
[fix] 修复服务端日志不显示的问题
修改了 Chat.Text() 的 hook 点，从 UI.SendChatGlobal() 改为直接 hook Chat.Text()

[feat] 添加项目架构规划文档
- 详细说明了客户端和服务端的消息流向
- 规划了 v1.1-v1.3 的功能路线图

[docs] 更新开发规范文档
- 添加了 .gitignore 规范
- 添加了代码质量标准

[refactor] 重构命令系统
- 分离命令注册和执行逻辑
- 为权限系统预留扩展点
```

### 5.2 Commit 类型

- **[feat]**：新增功能
- **[fix]**：修复问题
- **[docs]**：文档更新
- **[refactor]**：代码重构
- **[test]**：测试相关
- **[chore]**：琐碎事务（依赖更新等）

---

## 6. 项目里程碑

### 当前进度（v1.0.2）

```
✅ v1.0.0 - 基础命令系统完成
✅ v1.0.1 - 文档整理和修正
🔄 v1.0.2 - 双端兼容修复（进行中）
   └─ 修复服务端日志显示问题
   └─ 完善项目架构规划
   └─ 建立开发管理规范

📋 v1.1.0 - 架构重构计划
   ├─ 将 simulation/main.lua 拆分为多个模块
   ├─ 创建 command_system.lua
   ├─ 创建 message_router.lua
   └─ 完整的双端兼容性测试

📋 v1.2.0 - 功能扩展计划
   ├─ /set 命令
   ├─ /restart 命令
   └─ 更好的命令帮助系统

📋 v1.3.0 - 权限系统计划
   └─ 基础权限框架
```

---

## 总结

这份规范建立了：
1. **清晰的文件管理** - 避免污染项目
2. **版本化的发布流程** - 可追溯的历史
3. **高质量的代码标准** - 易于维护和扩展
4. **系统的测试方法** - 确保双端兼容
5. **长期的发展路线** - 为未来扩展预留空间

遵循这个规范，项目将更容易管理、更容易扩展、更容易协作。
