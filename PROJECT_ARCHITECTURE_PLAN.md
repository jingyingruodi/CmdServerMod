# CmdServerMod - 项目架构与开发规划

⚠️ **快速导航**：
- [ARCHITECTURE_WARNING.md](ARCHITECTURE_WARNING.md) - 快速了解当前问题
- [ARCHITECTURE_PROBLEMS_ANALYSIS.md](ARCHITECTURE_PROBLEMS_ANALYSIS.md) - 详细分析

## 第一部分：当前问题分析

### 问题 1：服务端日志不显示活动

**症状**：
- ✅ 客户端正常工作
- ❌ 服务端 `Server日志.log` 中没有玩家输入活动记录

**可能原因**：
1. 环境检测失败 —— `is_dedicated_server` 变量判断错误
2. Hook 点选择错误 —— `UI.SendChatGlobal()` 可能不是正确的拦截点
3. 玩家 ID 信息丢失 —— `arg.player_id` 可能不存在或为空

**需要进一步调查**：
- 在服务端上，玩家输入实际流经哪些函数
- `UI.SendChatGlobal()` 是否真的会被调用
- 是否需要 hook 更基础的函数（如 `Chat.Text()` 本身）

### 问题 2：项目架构不清晰

**当前问题**：
- 命令逻辑与消息处理混在一起
- 无法轻易添加新的命令
- 没有权限系统的预留扩展点
- 服务端和客户端的代码路径重复

**需要改进**：
- 将命令系统、权限系统、消息路由分离
- 建立清晰的数据流向
- 为未来功能预留接口

---

## 第二部分：项目结构规划

### 当前文件结构

```
CmdServerMod/
├── def.json                           # 模组定义
├── simulation/
│   └── main.lua                       # 所有 Simulation 逻辑（需要重构）
├── ui/
│   └── main.lua                       # 所有 UI 逻辑（需要优化）
├── README.md                          # 用户文档
├── DEVELOPMENT.md                     # 开发文档
├── CONTRIBUTING.md                    # 贡献指南
└── 其他文档...
```

### 改进方向（v1.1 重构）

```
CmdServerMod/
├── def.json
├── simulation/
│   ├── main.lua                       # 入口点（200行以内）
│   ├── command_system.lua             # 命令注册与执行（核心）
│   ├── message_router.lua             # 消息路由（客户端vs服务端）
│   ├── environment.lua                # 环境检测与初始化
│   └── builtin_commands.lua           # 内置命令（/help /test /info /settings）
├── ui/
│   ├── main.lua                       # 入口点（安全检查）
│   └── message_filter.lua             # 隐私过滤逻辑
├── permissions/                       # [v1.3] 权限系统（预留）
│   └── stub.lua                       # 占位符
├── docs/
│   ├── ARCHITECTURE.md                # 架构文档
│   ├── SERVER_COMPATIBILITY.md        # 服务端兼容说明
│   ├── EXTENDING_COMMANDS.md          # 扩展命令指南
│   └── PERMISSION_SYSTEM.md           # 权限系统设计（未来）
└── tests/                             # [v1.2] 测试脚本（预留）
    └── mock_environment.lua           # 测试环境模拟
```

---

## 第三部分：数据流与函数调用链

### 关键发现：服务端消息流向

基于服务端源码分析，需要澄清两个关键点：

**1. 主 UI 的加载顺序**

在 `def.json` 中：
```json
"packages": {
    "UI": { "entry": "ui/ui.lua" },
    "Data": { "entry": "data/data.lua" },
    "CmdServerMod/UI": { "entry": "ui/main.lua" },
    "CmdServerMod/Simulation": { "entry": "simulation/main.lua" }
}
```

**问题**：主 UI 的 `TextChat.lua` 在第一个加载（行 163），而我们的 Simulation 在最后加载（行 348）

**顺序**：
```
[BOOT] Loading Main/UI       ← 主UI加载，定义 Chat.Text()
[BOOT] Loading Main/Data     ← 数据层加载
[BOOT] Loading CmdServerMod/UI       ← 我们的UI加载，尝试 hook UI.Run()
[BOOT] Loading CmdServerMod/Simulation ← 我们的Simulation加载，尝试 hook UI.SendChatGlobal()
```

**问题**：在主 UI 的 `TextChat.lua` 中：
```lua
function Chat.Text(arg, player_id)
    arg.player_id = player_id
    UI.Run("OnReceivedChat", arg)  -- ❌ 在服务端，UI.Run 不存在！
end
```

这会导致 `Chat.Text()` 调用时在服务端崩溃。

**2. 客户端发送聊天的实际流向**

```
客户端 TextChat:on_commit()
    ↓
UI.SendChatGlobal("Text", { txt = "..." })  [TextChat.lua:38]
    ↓
Chat.Text(arg, player_id)  [Game 内部调用]
    ↓
UI.Run("OnReceivedChat", arg)
    ↓
UIMsg.OnReceivedChat()  [TextChat.lua:56+]
```

**在服务端上的问题**：
- `Chat.Text()` 会被调用（这是底层的)
- 但它尝试调用 `UI.Run()`，而服务端没有 UI.Run
- 因此崩溃，后续的任何 hook 都无效

---

## 第四部分：正确的双端兼容策略

### 方案 A（当前实现）的问题

```lua
-- Simulation 层
local is_dedicated_server = not (UI and UI.Run)

if is_dedicated_server then
    function UI.SendChatGlobal(msg_type, arg)
        -- hook UI.SendChatGlobal
    end
end
```

**问题**：
- `UI.SendChatGlobal()` 可能在 `Chat.Text()` 之后被调用
- 但 `Chat.Text()` 已经在主 UI 加载时就定义了，并且包含 `UI.Run()` 调用
- 在服务端，`Chat.Text()` 执行时会立即崩溃，无法到达我们的 hook

### 方案 B（推荐）：保护 Chat.Text()

```lua
-- 在 Simulation 层的最开始
local is_dedicated_server = not (UI and UI.Run)

if is_dedicated_server then
    -- 保护 Chat.Text，使其不会调用 UI.Run
    local original_chat_text = Chat.Text
    
    function Chat.Text(arg, player_id)
        if arg and arg.txt then
            print("[SERVER-INPUT] 玩家" .. tostring(player_id) .. ": " .. arg.txt)
            
            local is_command, cmd_result = execute_command(arg.txt, player_id)
            
            if is_command then
                print("[SERVER-CMD] 玩家" .. tostring(player_id) .. " 执行: " .. arg.txt)
                for line in cmd_result:gmatch("[^\n]+") do
                    print("[SERVER-CMD]   " .. line)
                end
                -- 不继续传播
                return
            end
        end
        
        -- 普通聊天，不调用原函数（因为原函数会尝试调用 UI.Run）
        -- 我们的责任已完成，让游戏处理其余部分
        return
    end
end
```

**为什么这样做**：
1. **阻止崩溃**：不调用原 `Chat.Text()`，避免它尝试调用 `UI.Run()`
2. **正确拦截**：在最底层拦截 `Chat.Text()`，无论它从哪里被调用
3. **简化流程**：不需要 hook 多个不同的函数

---

## 第五部分：长期架构设计

### 1. 命令系统设计

#### 核心思想：分离关注点

```
┌─────────────────────────┐
│  消息入口层              │
│  Chat.Text()            │
│  (环境适配)             │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│  命令识别层              │
│  是否为命令？            │
│  提取命令名和参数        │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│  权限检查层   [v1.3]     │
│  用户是否有权限          │
│  执行这个命令？          │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│  命令执行层              │
│  调用对应的处理函数      │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│  结果处理层              │
│  返回结果给用户          │
│  (环境适配)             │
└─────────────────────────┘
```

#### 核心接口

```lua
-- command_system.lua

-- 命令注册接口（用户通过这个扩展新命令）
function CommandSystem.register(name, handler, meta)
    -- name: 命令名
    -- handler: function(player_id, args) -> string (结果)
    -- meta: { description, args_info, permission = "default" }
end

-- 命令执行接口（内部使用）
function CommandSystem.execute(message, player_id)
    -- 返回: is_command, result
end

-- 内置命令列表
CommandSystem.builtin = {
    help = { ... },
    test = { ... },
    settings = { ... },
    info = { ... }
}
```

### 2. 权限系统预留（v1.3）

```lua
-- permissions/system.lua [v1.3]

PermissionSystem = {
    LEVEL_EVERYONE = 0,
    LEVEL_MODERATOR = 1,
    LEVEL_ADMIN = 2,
    LEVEL_HOST = 3
}

function PermissionSystem.check(player_id, command_name)
    -- 返回: boolean (是否有权限)
end

function PermissionSystem.set_level(player_id, level)
    -- 设置玩家权限等级
end
```

### 3. 消息路由器（环境适配）

```lua
-- message_router.lua

local MessageRouter = {}

function MessageRouter.handle_command_result(player_id, result, environment)
    if environment == "server" then
        -- 服务端：打印到后台
        print("[SERVER-CMD] 结果:")
        for line in result:gmatch("[^\n]+") do
            print("[SERVER-CMD]   " .. line)
        end
    else
        -- 客户端：标记并继续传播给 UI
        return {
            txt = "[CMD_RESULT:" .. player_id .. "] " .. result,
            player_id = player_id
        }
    end
end

return MessageRouter
```

### 4. 环境检测与初始化

```lua
-- environment.lua

local Environment = {}

function Environment.detect()
    return {
        is_server = not (UI and UI.Run),
        has_ui = UI and UI.Run ~= nil,
        version = "1.0.17604",  -- from logs
    }
end

function Environment.initialize()
    local env = Environment.detect()
    
    if env.is_server then
        print("[CmdServerMod] 检测到服务端环境")
        -- 初始化服务端特定逻辑
    else
        print("[CmdServerMod] 检测到客户端环境")
        -- 初始化客户端特定逻辑
    end
    
    return env
end

return Environment
```

---

## 第六部分：项目开发管理规范

### 1. 文件夹管理

#### 禁止事项
- ❌ 不要在 `Content/mods/` 文件夹中解压游戏源文件
- ❌ 不要放置临时的 `*_extracted` 文件夹

#### 允许事项
- ✅ 在 **外部临时文件夹**（如 `C:\Temp\`) 中进行源码研究
- ✅ 在项目文件夹中维护 `/docs` 或 `/research` 用于文档

### 2. Git 管理

**永远不要提交的文件**（`.gitignore`）：
```
# 临时文件
*_extracted/
*.tmp
*.backup

# 系统文件
.DS_Store
Thumbs.db

# 编辑器文件
*.swp
*.swo
*~

# 构建产物
dist/
build/

# 日志
*.log
```

### 3. 版本号管理

```
v1.0.x - 基础命令系统
  v1.0.0 - 初始版本
  v1.0.1 - Bug 修复
  v1.0.2 - 文档改进

v1.1.x - 架构重构 & 双端兼容优化
  v1.1.0 - 重构命令系统，完整的双端兼容
  
v1.2.x - 更多命令
  v1.2.0 - 添加 /set /speed /seed 等命令
  
v1.3.x - 权限系统
  v1.3.0 - 基础权限系统
```

### 4. 代码审查清单

在提交前，检查：
- [ ] 没有解压的源文件被提交
- [ ] 有适当的错误处理（`pcall`）
- [ ] 有清晰的日志输出 ([前缀] 消息)
- [ ] 代码在客户端和服务端都测试过
- [ ] 没有硬编码的玩家 ID 或魔法数字
- [ ] 有必要的注释解释复杂逻辑

---

## 第七部分：下一步行动计划

### 立即修复（v1.0.2）

1. **深入分析服务端日志问题**
   - 打印更多调试信息
   - 确认 `Chat.Text()` 是否被调用
   - 验证环境检测是否成功

2. **修复 `Chat.Text()` hook**
   - 使用方案 B：直接 hook `Chat.Text()`
   - 不再依赖 `UI.SendChatGlobal()`

3. **添加防守性编程**
   - 更多的 `pcall()` 包装
   - 更详细的日志输出

### 中期计划（v1.1）

1. **架构重构**
   - 创建 `command_system.lua`
   - 创建 `message_router.lua`
   - 创建 `environment.lua`

2. **改进双端兼容**
   - 彻底测试所有场景
   - 添加自动化测试框架

3. **文档完善**
   - 编写 ARCHITECTURE.md
   - 编写 EXTENDING_COMMANDS.md

### 长期规划（v1.2+）

1. **新命令**
   - `/set <key> <value>` - 修改地图设置
   - `/restart` - 重启服务器
   - `/whitelist` - 白名单管理

2. **权限系统**（v1.3）
   - 基础权限等级
   - 命令权限控制

3. **性能优化**
   - 缓存命令注册
   - 优化消息路由

---

## 总结

这个项目从简单的聊天命令系统演变成需要：
1. **清晰的架构** - 分离关注点
2. **双环境兼容** - 客户端和服务端
3. **可扩展性** - 为权限系统预留空间
4. **可维护性** - 清晰的代码组织和规范

当前的问题（服务端日志不显示）是因为 hook 点选择不当。应该改为直接 hook `Chat.Text()`，而不是依赖更高层的函数。
