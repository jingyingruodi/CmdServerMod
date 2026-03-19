-- ============================================================================
-- Desynced 命令台模组 - 扩展指南
-- ============================================================================

--[[
本文件说明如何为命令台模组添加新的命令或功能。

主要的命令注册函数在 main.lua 中定义为：
  register_command(name, description, args_info, handler)

参数说明：
  - name (string): 命令的名称（不需要包含 / 前缀）
  - description (string): 命令的描述文本
  - args_info (string): 参数描述（用于帮助文本）
  - handler (function): 命令的处理函数

处理函数的签名：
  function(args, sender_id)
    - args (table): 命令参数数组，args[1] 是第一个参数
    - sender_id (integer): 发送命令的玩家ID
]]

-- ============================================================================
-- 示例 1: 添加一个简单的命令
-- ============================================================================

--[[
添加一个查询地图尺寸的命令：

register_command("mapsize", "显示地图大小", "", function(args, sender_id)
    local chunk_width = Map.GetSettings().width or 100
    local chunk_height = Map.GetSettings().height or 100
    
    print_to_chat("[CMD] 地图大小: " .. chunk_width .. " x " .. chunk_height)
end)
]]

-- ============================================================================
-- 示例 2: 添加一个需要参数的命令
-- ============================================================================

--[[
添加一个设置特定单位属性的命令：

register_command("units", "显示或修改单位信息", "[属性] [值]", function(args, sender_id)
    if #args == 0 then
        -- 显示所有单位信息
        print_to_chat("[CMD] 单位信息显示功能")
    elseif #args == 1 then
        -- 显示特定属性
        print_to_chat("[CMD] 属性: " .. args[1])
    else
        -- 修改属性
        print_to_chat("[CMD] 设置 " .. args[1] .. " 为 " .. args[2])
    end
end)
]]

-- ============================================================================
-- 示例 3: 添加带有复杂逻辑的命令
-- ============================================================================

--[[
添加一个统计命令：

register_command("stats", "显示游戏统计数据", "[类型]", function(args, sender_id)
    if #args == 0 then
        -- 显示所有统计信息
        local player_faction = Game.GetLocalPlayerFaction()
        if player_faction then
            -- 统计此阵营的实体数量
            local entities = Map.GetComponents("health")
            print_to_chat("[CMD] 总实体数: " .. #entities)
        end
    else
        local stat_type = args[1]:lower()
        if stat_type == "health" then
            print_to_chat("[CMD] 健康统计信息")
        elseif stat_type == "resources" then
            print_to_chat("[CMD] 资源统计信息")
        else
            print_to_chat("[CMD] 未知统计类型: " .. stat_type)
        end
    end
end)
]]

-- ============================================================================
-- 示例 4: 添加一个交互式命令
-- ============================================================================

--[[
添加一个设置管理器，允许保存和加载预设：

register_command("preset", "管理设置预设", "<save|load|list> <名称>", function(args, sender_id)
    if #args < 1 then
        print_to_chat("[CMD] 用法: /preset <save|load|list> [预设名称]")
        return
    end
    
    local action = args[1]:lower()
    local mod_data = Map.GetSave("CmdServerMod")
    
    if not mod_data.presets then
        mod_data.presets = {}
    end
    
    if action == "save" then
        if #args < 2 then
            print_to_chat("[CMD] 用法: /preset save <预设名称>")
            return
        end
        local name = args[2]
        mod_data.presets[name] = Tool.Copy(Map.GetSettings())
        print_to_chat("[CMD] 预设已保存: " .. name)
        
    elseif action == "load" then
        if #args < 2 then
            print_to_chat("[CMD] 用法: /preset load <预设名称>")
            return
        end
        local name = args[2]
        if mod_data.presets[name] then
            local preset = mod_data.presets[name]
            -- 应用所有预设中的设置
            for key, value in pairs(preset) do
                Map.ModifySettings(key, value)
            end
            print_to_chat("[CMD] 预设已加载: " .. name)
        else
            print_to_chat("[CMD] 预设不存在: " .. name)
        end
        
    elseif action == "list" then
        if next(mod_data.presets) == nil then
            print_to_chat("[CMD] 没有保存的预设")
        else
            print_to_chat("[CMD] 已保存的预设:")
            for name, _ in pairs(mod_data.presets) do
                print_to_chat("[CMD]   - " .. name)
            end
        end
    else
        print_to_chat("[CMD] 未知操作: " .. action)
    end
end)
]]

-- ============================================================================
-- 最佳实践
-- ============================================================================

--[[
1. 错误处理：
   - 总是检查参数的个数和类型
   - 提供有用的错误消息
   - 使用 try-catch (pcall) 处理可能的异常

2. 用户体验：
   - 提供清晰的命令描述
   - 参数名称要有意义
   - 返回操作的结果反馈

3. 数据持久化：
   - 使用 Map.GetSave() 存储模组数据
   - 正确处理数据的初始化
   - 备份重要数据

4. 性能：
   - 避免在每次命令执行时进行重型计算
   - 缓存重复使用的数据
   - 对于大量数据操作，考虑使用 Map.Defer()

5. 兼容性：
   - 不要修改其他模组的数据
   - 使用模组ID进行数据隔离
   - 检查API的可用性

-- ============================================================================
-- 高级特性
-- ============================================================================

-- 1. 执行延迟操作
Map.Defer(function()
    -- 这个代码将在组件处理后执行
end)

-- 2. 定时任务
Map.Delay("MyDelayedFunction", 60)  -- 延迟60个tick

function Delay.MyDelayedFunction(arg)
    -- 处理延迟函数
end

-- 3. 与UI交互
UI.Run(function()
    -- 这段代码在UI上下文中执行
    -- 可以访问玩家相关的UI信息
end)

-- 4. 事件监听
-- 注册MapMsg处理器
function MapMsg.MyCustomEvent(data)
    -- 处理自定义事件
end

-- 5. 数据序列化
local settings = Map.GetSettings()
local encoded = Tool.TableToString(settings)
local decoded = Tool.StringToTable(encoded)

--]]

-- ============================================================================
-- 调试技巧
-- ============================================================================

--[[
1. 打印调试信息：
   print("[DEBUG] 变量值: " .. tostring(value))

2. 检查数据结构：
   print("[DEBUG] " .. Tool.TableToString(my_table))

3. 条件断点（通过命令）：
   register_command("debug", "调试命令", "", function(args, sender_id)
       -- 检查内部状态
       local mod_data = Map.GetSave("CmdServerMod")
       print("[DEBUG] " .. Tool.TableToString(mod_data))
   end)

4. 性能分析：
   local start = Map.GetTick()
   -- ... 执行代码 ...
   local elapsed = Map.GetTick() - start
   print("[PERF] 耗时: " .. elapsed .. " ticks")

--]]

print("[INFO] 命令台模组扩展指南已加载")
