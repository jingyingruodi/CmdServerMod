# Desynced 命令台模组 - 开发文档

## 概述

本文档详细说明了 Desynced 命令台模组的设计、实现和扩展方式。

## 项目结构

```
CmdSettingsMod/
├── def.json                    # 模组定义和元数据
├── simulation/
│   └── main.lua               # 主要Lua实现文件
├── README.md                  # 用户使用指南
├── EXTENSION_GUIDE.lua        # 扩展和开发指南
└── DEVELOPMENT.md             # 本开发文档
```

## 模组配置 (def.json)

```json
{
    "id": "CmdSettingsMod",              // 模组唯一标识符
    "name": "Command Console",            // 显示名称
    "author": "镜影若滴",                 // 作者
    "version_name": "1.0",                // 版本名称
    "version_code": 1,                    // 版本号（用于兼容性）
    "description": "...",                 // 模组描述
    "packages": {                         // 包定义
        "Simulation": {
            "name": "Simulation Logic",
            "entry": "simulation/main.lua", // 入口文件
            "type": "Addon"                // 类型（Addon = 附加模组）
        }
    }
}
```

## 核心架构

### 1. 命令系统

命令系统基于简单的注册-执行模式：

```
输入 (/help)
    ↓
前缀检查
    ↓
分割和解析
    ↓
查找命令
    ↓
执行处理器
    ↓
输出结果
```

### 2. 主要组件

#### CommandHandler（命令处理器）
- 注册命令：`register_command()`
- 执行命令：`execute_command()`
- 显示帮助：`show_help()`

#### 命令注册系统
每个命令包含：
- `name`: 命令名称
- `description`: 帮助文本
- `args`: 参数说明
- `handler`: 处理函数

#### 消息系统
- `print_to_chat()`: 将消息发送到游戏聊天
- 使用 `UI.Run()` 在UI上下文执行

### 3. 已实现的命令

| 命令 | 描述 | 用法 |
|------|------|------|
| `/help` | 显示帮助 | `/help [命令名]` |
| `/settings` | 查看设置 | `/settings [设置名]` |
| `/set` | 修改设置 | `/set <设置名> <值>` |
| `/speed` | 游戏速度 | `/speed [值]` |
| `/info` | 游戏信息 | `/info` |
| `/seed` | 地图种子 | `/seed [值]` |
| `/version` | 版本信息 | `/version` |

## 实现细节

### 字符串分割

```lua
local function split_string(str, delimiter)
    local result = {}
    local pattern = "([^" .. delimiter .. "]+)"
    for match in str:gmatch(pattern) do
        table.insert(result, match)
    end
    return result
end
```

### 类型转换

支持自动类型转换：
- **布尔值**: "true"/"false", "yes"/"no", "1"/"0", "on"/"off"
- **数值**: 使用 `tonumber()` 转换
- **字符串**: 直接使用

### 错误处理

使用 `pcall()` 进行安全的函数调用：

```lua
local success, result = pcall(cmd.handler, cmd_args, sender_id)
if not success then
    print_to_chat("[CMD] 执行出错: " .. tostring(result))
end
```

## API使用情况

### Map 模块
- `Map.GetSettings()` - 获取当前地图设置
- `Map.ModifySettings()` - 修改地图设置
- `Map.SetGameSpeed()` - 设置游戏速度
- `Map.GetGameSpeed()` - 获取游戏速度
- `Map.GetTick()` - 获取当前 tick
- `Map.GetTotalDays()` - 获取总天数
- `Map.GetYear()` - 获取当前年份
- `Map.GetSunriseAndSunset()` - 获取日出日落时间
- `Map.GetSave()` - 获取模组保存数据

### UI 模块
- `UI.Run()` - 在UI上下文执行代码
- `UI.SendChatGlobal()` - 发送全局聊天消息

### Tool 模块
- `Tool.Copy()` - 深拷贝表
- `Tool.TableToString()` - 表序列化
- `Tool.StringToTable()` - 表反序列化

## 扩展机制

### 添加新命令

1. 调用 `register_command()`：

```lua
register_command("mycommand", "描述", "[参数]", function(args, sender_id)
    -- 处理逻辑
    print_to_chat("[CMD] 结果")
end)
```

2. 参数处理：

```lua
if #args == 0 then
    -- 无参数
elseif #args == 1 then
    local param = args[1]
    -- 处理单个参数
else
    local all_params = table.concat(args, " ")
    -- 处理多个参数
end
```

### 数据持久化

```lua
local mod_data = Map.GetSave("CmdSettingsMod")
mod_data.my_custom_data = "value"
-- 数据自动保存
```

## 测试建议

### 功能测试

1. **命令识别**：
   - `/help` - 应显示所有命令
   - `/unknown_cmd` - 应报告未知命令

2. **参数解析**：
   - `/set seed 12345` - 应正确解析种子值
   - `/set key multi word value` - 应正确处理多词参数

3. **类型转换**：
   - `/set bool_setting true` - 应正确转换为布尔值
   - `/set num_setting 42.5` - 应正确转换为数值

4. **错误处理**：
   - 无效参数应产生有意义的错误信息
   - 类型不匹配应报告具体错误

### 性能测试

- 大量命令执行：确保没有内存泄漏
- 大型设置表：确保显示不会冻结游戏

## 已知问题和限制

1. **聊天消息拦截**
   - 当前实现依赖于 MapMsg 处理
   - 可能需要根据实际游戏版本调整

2. **权限系统**
   - 当前所有玩家都可以执行命令
   - 未来可添加权限检查

3. **实时性**
   - 某些设置修改可能需要游戏重新加载
   - 大型地图的设置可能需要等待

## 版本兼容性

当前版本 (1.0) 针对 Desynced 的最新版本开发。

版本更新时的注意事项：
- 在 `def.json` 中更新 `version_code`
- 在 README 中更新版本历史
- 测试新版本的 API 兼容性

## 调试建议

### 启用调试输出

在 main.lua 开头添加：

```lua
local DEBUG = true
local function debug_print(msg)
    if DEBUG then
        print("[DEBUG] " .. msg)
    end
end
```

### 监视变量

```lua
debug_print("设置: " .. Tool.TableToString(Map.GetSettings()))
debug_print("参数: " .. Tool.TableToString(args))
```

### 性能分析

```lua
local tick_start = Map.GetTick()
-- ... 执行代码 ...
local tick_elapsed = Map.GetTick() - tick_start
print("[PERF] 耗时: " .. tick_elapsed .. " ticks")
```

## 最佳实践

1. **代码风格**
   - 使用有意义的变量名
   - 添加注释说明复杂逻辑
   - 保持函数简洁

2. **错误处理**
   - 总是验证用户输入
   - 提供有用的错误消息
   - 使用 pcall 保护关键函数

3. **性能**
   - 避免在每次命令执行时重新计算
   - 缓存频繁访问的数据
   - 使用 Map.Defer 处理延迟操作

4. **可维护性**
   - 保持命令的独立性
   - 使用统一的消息格式
   - 定期审查和重构代码

## 参考资源

### Desynced API 文档位置
- `Desynced Lua API.html` - 完整API参考
- `Modding - Desynced Wiki.html` - 开发指南

### 关键模块
- Map 模块：地图和模拟相关操作
- UI 模块：用户界面和聊天相关操作
- Tool 模块：工具函数（序列化、复制等）

## 未来改进方向

- [ ] 权限和角色系统
- [ ] 命令宏和脚本支持
- [ ] 配置文件支持
- [ ] 条件命令（if/else）
- [ ] 命令历史和撤销
- [ ] 更详细的统计信息
- [ ] UI界面（配置窗口）
- [ ] 命令别名
- [ ] 国际化支持

## 许可证

本模组作为 Desynced 社区模组发布。

## 联系和支持

如有问题或建议，欢迎反馈。

---

最后更新：2026年3月19日
文档版本：1.0
