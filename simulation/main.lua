-- Desynced Command Console Mod
-- 直接在Simulation层处理聊天命令，并通过UI返回结果

local config = { 
    command_prefix = "/",
    debug_log = true  -- 设置为 true 时在日志中显示命令返回结果
}
local commands = {}
local output_buffer = {}

-- 工具函数
local function split_string(str, delimiter)
    local result = {}
    local pattern = "([^" .. delimiter .. "]+)"
    for match in str:gmatch(pattern) do
        table.insert(result, match)
    end
    return result
end

-- 向聊天栏输出消息
local function output_to_chat(message)
    if config.debug_log then
        print("[CMD-OUTPUT] " .. message)
    end
    table.insert(output_buffer, message)
end

-- 获取缓冲的所有输出消息
local function get_buffered_output()
    local result = ""
    for i, msg in ipairs(output_buffer) do
        result = result .. msg
        if i < #output_buffer then
            result = result .. "\n"
        end
    end
    output_buffer = {}
    return result
end

-- 注册命令
local function register_command(name, description, args_info, handler)
    commands[name:lower()] = {
        name = name,
        description = description,
        args = args_info,
        handler = handler
    }
end

-- 显示帮助
local function show_help(cmd_name)
    if cmd_name then
        local cmd = commands[cmd_name:lower()]
        if cmd then
            output_to_chat("[帮助] /" .. cmd.name .. " " .. cmd.args)
            output_to_chat("       " .. cmd.description)
        else
            output_to_chat("未找到命令: " .. cmd_name)
        end
    else
        output_to_chat("========== 可用命令 ==========")
        for cmd_key, cmd in pairs(commands) do
            output_to_chat("  /" .. cmd.name .. " " .. cmd.args .. " - " .. cmd.description)
        end
        output_to_chat("使用 /help <命令名> 获取详细信息")
    end
end

-- 执行命令，返回是否为命令以及命令结果
local function execute_command(message, player_id)
    if message:sub(1, #config.command_prefix) ~= config.command_prefix then
        return false, nil  -- 不是命令
    end
    
    local cmd_line = message:sub(#config.command_prefix + 1):match("^%s*(.-)%s*$")
    if cmd_line == "" then
        return false, nil
    end
    
    local parts = split_string(cmd_line, " ")
    if #parts == 0 then
        return false, nil
    end
    
    local cmd_name = parts[1]:lower()
    local cmd_args = {}
    for i = 2, #parts do
        table.insert(cmd_args, parts[i])
    end
    
    local cmd = commands[cmd_name]
    if not cmd then
        output_to_chat("未知命令: " .. cmd_name .. " (使用 /help 查看帮助)")
        local result = get_buffered_output()
        return true, result  -- 是命令，返回结果
    end
    
    local success, error_msg = pcall(cmd.handler, cmd_args)
    if not success then
        output_to_chat("执行出错: " .. tostring(error_msg))
    end
    
    local result = get_buffered_output()
    return true, result  -- 是命令，返回结果
end

-- ============================================================================
-- 命令注册
-- ============================================================================

register_command("help", "显示帮助信息", "[命令名]", function(args)
    if #args == 0 then
        show_help()
    else
        show_help(args[1])
    end
end)

register_command("test", "测试命令", "", function(args)
    output_to_chat("测试命令已执行!")
end)

register_command("settings", "显示地图设置", "[设置名]", function(args)
    local settings = Map.GetSettings()
    
    if #args == 0 then
        output_to_chat("========== 地图设置 ==========")
        for key, value in pairs(settings) do
            local val_str = tostring(value)
            if type(value) == "boolean" then
                val_str = value and "true" or "false"
            end
            output_to_chat("  " .. key .. " = " .. val_str)
        end
    else
        local setting_name = args[1]
        if settings[setting_name] then
            output_to_chat(setting_name .. " = " .. tostring(settings[setting_name]))
        else
            output_to_chat("未知设置: " .. setting_name)
        end
    end
end)

register_command("info", "显示游戏信息", "", function(args)
    output_to_chat("========== 游戏信息 ==========")
    output_to_chat("  当前时刻: " .. tostring(Map.GetTick()))
    output_to_chat("  总天数: " .. tostring(Map.GetTotalDays()))
    output_to_chat("  年份: " .. tostring(Map.GetYear()))
    
    local sunrise, sunset = Map.GetSunriseAndSunset()
    if sunrise and sunset then
        output_to_chat("  日出时刻: " .. tostring(sunrise))
        output_to_chat("  日落时刻: " .. tostring(sunset))
    end
end)

-- ============================================================================
-- 聊天消息拦截 - 核心函数
-- ============================================================================
-- 在 Simulation 层拦截聊天消息并执行命令
-- 直接调用 UI.Run 让游戏正常的 Chat.Text 处理

local original_ui_run = UI.Run

-- 劫持 UI.Run 来拦截 OnReceivedChat 消息
function UI.Run(func_name, ...)
    if func_name == "OnReceivedChat" then
        local arg = select(1, ...)
        if arg and arg.txt and arg.player_id ~= nil then
            local message = arg.txt
            local player_id = arg.player_id
            
            -- 在日志中记录所有玩家的聊天
            print("[CHAT-LOG] 玩家" .. tostring(player_id) .. ": " .. message)
            
            -- 尝试作为命令执行
            local is_command, cmd_result = execute_command(message, player_id)
            
            if is_command then
                -- 是命令，结果用特殊标记发送，UI层会根据标记决定谁能看到
                print("[CMD-EXECUTED] 玩家" .. tostring(player_id) .. " 执行命令: " .. message)
                
                -- 修改消息标记，UI层会识别并仅在目标玩家显示
                arg.txt = "[CMD_RESULT:" .. tostring(player_id) .. "] " .. cmd_result
                print("[CMD-MSG] 已发送命令结果给UI层")
                -- 继续传递修改后的消息
                return original_ui_run(func_name, arg)
            else
                -- 不是命令，正常处理
                print("[CHAT-PASS] 玩家" .. tostring(player_id) .. " 的聊天已放行")
                return original_ui_run(func_name, arg)
            end
        end
    end
    -- 对于其他函数，直接调用原始 UI.Run
    return original_ui_run(func_name, ...)
end

-- ============================================================================
-- 初始化
-- ============================================================================

print("[CmdServerMod] 命令台模组已加载!")
print("[CmdServerMod] UI.Run 处理器已激活")
print("[CmdServerMod] 可以在游戏聊天中输入命令了，例如: /help")

