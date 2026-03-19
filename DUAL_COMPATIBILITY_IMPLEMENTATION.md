# 双端兼容实现总结

⚠️ **架构提示**：本文档描述的是当前（v1.0）实现。请先阅读 [ARCHITECTURE_WARNING.md](ARCHITECTURE_WARNING.md) 了解当前架构的限制。

## 修改的文件

### 1. simulation/main.lua

**关键改动**：添加了环境检测和条件分支处理

```lua
-- 行 163：环境检测
local is_dedicated_server = not (UI and UI.Run)

if is_dedicated_server then
    -- 服务端模式（行 165-207）
    -- Hook: UI.SendChatGlobal()
    -- 行为: 命令结果只打印到后台日志，不广播
    
else
    -- 客户端模式（行 209-254）
    -- Hook: UI.Run() 
    -- 行为: 命令结果标记为 [CMD_RESULT:player_id]，继续传递给UI层
end
```

**为什么这样做**：

1. **服务端环境的特殊性**：
   - 服务端没有 `UI.Run()` 函数
   - 直接 hook `UI.Run()` 会导致错误
   - 需要 hook 更上层的 `UI.SendChatGlobal()` 来捕获聊天消息

2. **Hook 点选择**：
   - **客户端**：`UI.Run("OnReceivedChat", arg)` 是游戏内聊天系统的中枢
   - **服务端**：`UI.SendChatGlobal("Text", arg)` 是玩家客户端发送聊天时的入口

3. **命令结果处理**：
   - **客户端**：标记为 `[CMD_RESULT:player_id]`，由 UI 层过滤
   - **服务端**：直接打印到后台日志（`[SERVER-CMD]`），不返回给客户端

### 2. ui/main.lua

**关键改动**：添加了服务端环境检查

```lua
-- 行 3-6：安全防护
if not UI or not UI.Run then
    print("[CmdServerMod UI] 检测到服务端环境，UI 模块已禁用")
    return  -- 提前退出，避免后续代码执行
end
```

**为什么这样做**：

1. **防护措施**：确保 UI 层代码不会在服务端环境尝试执行
2. **快速失败**：通过 `return` 提前退出，避免后续的 `UI.Run` hook 代码在服务端崩溃
3. **清晰的日志**：打印消息让开发者知道 UI 模块在服务端被正确禁用

## 架构流程

### 客户端流程（保持原有）

```
玩家输入聊天 → UI.SendChatGlobal("Text", arg)
    ↓
[Simulation] UI.Run("OnReceivedChat", arg) 被拦截
    ↓
[Simulation] 判断是否为命令？
    ↓ YES
[Simulation] 执行命令，结果标记为 [CMD_RESULT:player_id]
    ↓
[Simulation] 继续调用 original_ui_run(func_name, arg)
    ↓
[UI] UI.Run("OnReceivedChat", arg) 被再次拦截
    ↓
[UI] 检查 [CMD_RESULT:player_id] 标记
    ↓
[UI] 调用 Game.IsLocalPlayer(player_id) 判断
    ↓
只显示给目标玩家
```

### 服务端流程（新增）

```
客户端发送聊天 → 服务端接收
    ↓
[Simulation] UI.SendChatGlobal("Text", arg) 被拦截
    ↓
[Simulation] 判断是否为命令？
    ↓ YES
[Simulation] 执行命令，结果打印到后台日志 [SERVER-CMD]
    ↓
[Simulation] 直接返回（不调用 original_send_chat_global）
    ↓
命令结果不会广播给客户端
```

## 环境检测原理

```lua
local is_dedicated_server = not (UI and UI.Run)
```

**逻辑**：
- `UI` 对象存在于所有环境
- `UI.Run` 函数仅存在于有 UI 系统的环境
- 专用服务端既然没有 UI 系统，就不会有 `UI.Run` 函数
- 因此可以通过检查 `UI.Run` 是否存在来判断是否为服务端

## 日志标记对比

| 环境 | 命令日志前缀 | 输入日志前缀 | 结果日志前缀 |
|------|------------|------------|-----------|
| 客户端 | `[CMD-EXECUTED]` | `[CHAT-LOG]` | `[CMD-RESULT]` |
| 服务端 | `[SERVER-CMD]` | `[SERVER-CHAT]` | `[SERVER-CMD]` |

## 测试清单

- [ ] **客户端**：玩家输入命令，结果在聊天栏显示
- [ ] **客户端多人**：玩家A的命令结果仅显示给玩家A
- [ ] **服务端**：玩家输入命令，结果在服务端后台日志显示
- [ ] **服务端普通聊天**：普通聊天内容无改变
- [ ] **服务端客户端同步**：加入服务器的客户端自动下载模组并正常运行

## 关键差异点

| 方面 | 客户端 | 服务端 |
|------|--------|--------|
| Hook 点 | `UI.Run()` | `UI.SendChatGlobal()` |
| 是否调用原函数 | 是（继续传播） | 否（命令时不传播） |
| 结果显示方式 | 游戏内聊天栏 | 控制台后台日志 |
| 隐私过滤 | UI 层负责 | 不需要（不广播） |
| 普通聊天处理 | 正常传播 | 正常传播 |

## 潜在改进方向

1. **更精确的命令返回**：考虑使用 `UI.SendChatGlobal` 的 `player_id` 参数确定发送者
2. **服务端日志美化**：可考虑在后台输出中添加时间戳或其他信息
3. **命令权限系统**：为将来的权限系统预留扩展点（v1.3）
