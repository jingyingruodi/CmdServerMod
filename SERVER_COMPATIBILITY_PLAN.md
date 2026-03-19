# 服务端与客户端双端兼容方案

## 1. 架构现状分析

### 1.1 当前代码的问题

**老版本（GitHub 3c9e762）**：
```lua
-- simulation/main.lua
function Chat.Text(arg, player_id)
    if is_command then
        UI.Run("OnReceivedChat", arg)  -- ❌ 在服务端会崩溃！
    else
        UI.Run("OnReceivedChat", arg)  -- ❌ 在服务端会崩溃！
    end
end
```

**问题**：
- 在服务端，`UI.Run()` 不存在（服务端没有 UI 系统）
- 导致服务端加载模组时崩溃

### 1.2 环境特征对比

| 特征 | 客户端 | 专用服务端 |
|------|--------|----------|
| `Chat.Text` 存在 | ✅ 是 | ✅ 是 |
| `UI.Run()` 存在 | ✅ 是 | ❌ 否 |
| `Game.IsLocalPlayer()` | ✅ 是 | ✅ 是 |
| `Map.GetSettings()` | ✅ 是 | ✅ 是 |
| 用户界面 | ✅ 有 UI 层 | ❌ 无 UI 层 |
| 聊天显示方式 | 游戏内聊天栏 | 控制台后台日志 |

## 2. 双端兼容的设计思路

### 2.1 核心问题

多人游戏中：
- **主机（Host）**：同时运行 Simulation 和 UI（作为玩家）
- **客户端（Client）**：也同时运行 Simulation 和 UI（需要显示结果）
- **专用服务端（Dedicated Server）**：只运行 Simulation，**不运行 UI**

但是，`Chat.Text` 在所有环境都会被调用！

### 2.2 消息流向分析

**客户端环境**（普通多人游戏）：
```
玩家输入 → Chat.Text (Simulation) → UI.Run() → 游戏显示在聊天栏
```

**服务端环境**（专用服务端）：
```
客户端发送 → Chat.Text (Simulation) → 需要处理，但无法调用 UI.Run()
```

## 3. 双端兼容实现方案

### 3.1 环境检测

在 Simulation 层的初始化时检测环境：

```lua
-- 检测是否为服务端环境
local function detect_environment()
    -- 方法：检查 UI 系统是否存在
    if not UI or not UI.Run then
        return "SERVER"  -- 专用服务端
    elseif UI and UI.Run then
        return "CLIENT"  -- 客户端（单人、主机或客户端）
    end
end

local environment = detect_environment()
```

### 3.2 处理流程设计

#### 方案 A：在 Simulation 层处理所有命令

**Simulation 层的职责**：
1. ✅ 捕获 `Chat.Text` 调用
2. ✅ 识别和执行命令
3. ✅ 生成命令结果
4. ✅ 根据环境决定如何传递结果

**UI 层的职责**（仅客户端）：
1. ✅ 过滤私密消息（`[CMD_RESULT:player_id]`）
2. ✅ 确保只有目标玩家看到命令结果

#### 流程图

**客户端流程**：
```
Chat.Text(arg, player_id)
    ↓
[Simulation] 识别命令？
    ↓ YES（是命令）
[Simulation] 执行命令
    ↓
[Simulation] 标记结果：[CMD_RESULT:player_id]
    ↓
[Simulation] 调用 UI.Run("OnReceivedChat", arg)
    ↓
[UI] 拦截并过滤
    ↓
只显示给目标玩家
```

**服务端流程**：
```
Chat.Text(arg, player_id)
    ↓
[Simulation] 识别命令？
    ↓ YES（是命令）
[Simulation] 执行命令
    ↓
[Simulation] 打印结果到后台日志
    ↓
[Simulation] 返回（不继续传播）
    ↓
命令结果不广播给客户端
```

### 3.3 核心代码结构

```lua
-- simulation/main.lua

-- 1. 环境检测
local is_server = not (UI and UI.Run)

-- 2. 原始函数保存（可选，服务端不需要但不影响）
local original_chat_text = Chat.Text

-- 3. 拦截 Chat.Text
function Chat.Text(arg, player_id)
    if not (arg and arg.txt and player_id ~= nil) then
        return original_chat_text(arg, player_id)
    end
    
    local message = arg.txt
    
    -- 4. 尝试执行命令
    local is_command, cmd_result = execute_command(message, player_id)
    
    if is_command then
        -- 是命令
        if is_server then
            -- 服务端：只在后台显示，不广播
            print("[CMD-RESULT] 玩家" .. player_id .. " 的命令结果:")
            for line in cmd_result:gmatch("[^\n]+") do
                print("  " .. line)
            end
            return  -- 不继续传播
        else
            -- 客户端：标记后继续传播给 UI.Run 处理
            arg.player_id = player_id
            arg.txt = "[CMD_RESULT:" .. tostring(player_id) .. "] " .. cmd_result
            return original_chat_text(arg, player_id)
        end
    else
        -- 不是命令，正常传播
        arg.player_id = player_id
        return original_chat_text(arg, player_id)
    end
end

-- 初始化信息
if is_server then
    print("[CmdServerMod] 专用服务端模式已激活")
else
    print("[CmdServerMod] 客户端模式已激活")
end
```

## 4. UI 层的角色（仅客户端存在）

```lua
-- ui/main.lua

-- 检查是否为服务端（服务端没有 UI.Run）
if not UI or not UI.Run then
    print("[CmdServerMod UI] 服务端环境，UI 模块禁用")
    return
end

local original_ui_run = UI.Run

function UI.Run(func_name, ...)
    if func_name == "OnReceivedChat" then
        local arg = select(1, ...)
        
        -- 检查是否为命令结果消息
        if arg and arg.txt and arg.txt:match("^%[CMD_RESULT:") then
            -- 解析目标玩家 ID
            local target_player_id = tonumber(arg.txt:match("^%[CMD_RESULT:(%d+)%]"))
            
            if Game.IsLocalPlayer(target_player_id) then
                -- 只有目标玩家才显示
                arg.txt = arg.txt:gsub("^%[CMD_RESULT:%d+%]%s*", "[CMD] ")
                return original_ui_run(func_name, arg)
            else
                -- 其他玩家不显示
                return
            end
        end
    end
    
    return original_ui_run(func_name, ...)
end
```

## 5. 文件责任划分

| 文件 | 环境 | 职责 |
|------|------|------|
| `simulation/main.lua` | 两端都运行 | 命令执行、消息路由、环境适配 |
| `ui/main.lua` | 仅客户端 | 隐私过滤、结果显示 |

## 6. 测试清单

- [ ] **客户端单人模式**：命令执行，结果在聊天栏显示
- [ ] **多人客户端**：命令结果仅显示给执行者
- [ ] **服务端模式**：命令结果在后台日志显示，不广播给客户端
- [ ] **模组下载同步**：加入服务器的客户端自动下载模组，能正常运行

## 7. 预期的日志输出

**客户端**：
```
[CHAT-LOG] 玩家 0: /help
[CMD-EXECUTED] 玩家 0 执行命令: /help
[CMD-UI] 命令结果显示给玩家 0
```

**服务端**：
```
[CHAT-INPUT] 玩家 0: /help
[CMD-EXECUTED] 玩家 0 执行命令: /help
[CMD-RESULT] 玩家 0 的命令结果:
  ========== 可用命令 ==========
  /help [命令名] - 显示帮助信息
  ...
```

## 8. 关键注意事项

1. **不要在服务端调用 UI.Run()**：检查环境后分开处理
2. **保留原始 Chat.Text 的调用**：确保普通聊天正常工作
3. **命令结果的标记必须一致**：UI 层和 Simulation 层要用同样的格式
4. **环境检测要放在模组初始化时**：避免重复检测
