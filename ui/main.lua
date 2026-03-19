-- Desynced Command Console - UI Module
-- 在UI层拦截并处理命令结果的私聊显示

-- 玩家本地ID
local local_player_id = nil

-- 原始的聊天消息处理函数
local Chat = Chat or {}
local original_text_handler = Chat.Text

-- 获取本地玩家ID
local function get_local_player_id()
    if not local_player_id then
        -- 在UI层，通常本地玩家ID为1（主视角）或通过API获取
        if UI.GetLocalPlayerId then
            local_player_id = UI.GetLocalPlayerId()
        else
            -- 尝试从Player对象获取
            local_player_id = 1  -- 默认为1
        end
    end
    return local_player_id
end

-- 在UI层处理 OnReceivedChat
local function OnReceivedChat(arg)
    if arg and arg.txt then
        -- 检查是否是命令结果标记
        local cmd_result_match = arg.txt:match("^%[CMD_RESULT:(%d+)%](.+)$")
        
        if cmd_result_match then
            -- 这是一条命令结果消息
            local target_player_id = tonumber(cmd_result_match:match("^(%d+)"))
            local content = arg.txt:match("^%[CMD_RESULT:%d+%]%s*(.*)$")
            
            local local_id = get_local_player_id()
            
            print("[CMD-UI] 命令结果: 目标玩家=" .. tostring(target_player_id) .. ", 本地玩家=" .. tostring(local_id) .. ", 内容=" .. content)
            
            -- 只有目标玩家才会看到这条消息
            if local_id == target_player_id then
                -- 显示命令结果
                arg.txt = "[CMD] " .. content
                -- 显示到聊天框
                TextChat.AddChatMessage(arg)
                print("[CMD-UI] 命令结果已显示给玩家 " .. tostring(local_id))
            else
                -- 过滤掉不是给本玩家的命令结果
                print("[CMD-UI] 命令结果被过滤，不是给本玩家的")
                return
            end
        else
            -- 这是普通聊天，正常显示
            if original_text_handler then
                original_text_handler(arg)
            else
                -- 如果没有原始处理器，尝试直接显示
                TextChat.AddChatMessage(arg)
            end
        end
    end
end

-- 注册处理器
Chat.Text = OnReceivedChat

print("[CmdSettingsMod UI] UI模块已加载")
