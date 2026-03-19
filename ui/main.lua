-- Desynced Command Console - UI Module
-- 在UI层拦截 OnReceivedChat 消息，处理命令结果的显示

-- 安全检查：服务端没有 UI 系统，此模块不应在服务端运行
if not UI or not UI.Run then
    print("[CmdServerMod UI] 检测到服务端环境，UI 模块已禁用")
    return
end

-- 保存原始的 UI.Run 处理器
local original_ui_run = UI.Run

function UI.Run(func_name, ...)
    if func_name == "OnReceivedChat" then
        local arg = select(1, ...)
        if arg and arg.txt then
            -- 检查是否是命令结果标记
            local target_player_id_str, content = arg.txt:match("^%[CMD_RESULT:(%d+)%]%s*(.*)$")
            
            if target_player_id_str then
                -- 这是一条命令结果消息
                local target_player_id = tonumber(target_player_id_str)
                
                print("[CMD-UI] 命令结果拦截: 目标玩家=" .. tostring(target_player_id) .. ", 内容长度=" .. #content)
                
                -- 使用游戏提供的 API 判断是否为本地玩家
                if Game.IsLocalPlayer(target_player_id) then
                    -- 只有本地玩家才能看到，修改消息后继续
                    arg.txt = "[CMD] " .. content
                    print("[CMD-UI] 命令结果显示给本地玩家")
                    return original_ui_run(func_name, arg)
                else
                    -- 其他玩家直接返回，不显示
                    print("[CMD-UI] 命令结果过滤，不显示给其他玩家")
                    return
                end
            else
                -- 普通聊天，继续传递
                return original_ui_run(func_name, ...)
            end
        end
    end
    -- 其他函数直接调用原始
    return original_ui_run(func_name, ...)
end

print("[CmdServerMod UI] UI 模块已加载")
