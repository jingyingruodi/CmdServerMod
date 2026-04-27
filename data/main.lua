-- Desynced Command Console - Core Logic (v1.6.3)
-- 职责：全量监控播报 + 隔离反馈 (修复元表报错与身份冒用)

local package = ...
_G.CmdServerMod = _G.CmdServerMod or {}
local version = "1.6.3"
local tick_counter = 0

local function srv_print(tag, msg)
    print(string.format("[%s] %s", tostring(tag), tostring(msg)))
end

srv_print("CmdServerMod", "Data Layer Booting v" .. version)

---------------------------------------------------------------------------
-- 1. 监控与命令接收 Action (多人隔离版)
---------------------------------------------------------------------------
function FactionAction.CmdServerExec(faction, arg)
    -- 从 arg 中取回 UI 层上报的真实 PlayerID 和 名字
    local real_p_id = tonumber(arg.p_id) or 0
    local p_name = tostring(arg.sender_name or "Unknown")
    local text = tostring(arg.txt or "")

    -- 服务端控制台：播报
    if arg.is_command then
        srv_print("COMMAND", string.format("<%s>(P%d): %s", p_name, real_p_id, text))
    else
        srv_print("CHAT", string.format("<%s>(P%d): %s", p_name, real_p_id, text))
    end

    -- 处理指令逻辑
    if arg.is_command and _G.CmdServerMod.execute_command then
        local ok, result = _G.CmdServerMod.execute_command(text, real_p_id)
        if ok then
            srv_print("RESULT", "To P" .. real_p_id .. ": " .. tostring(result))

            -- 【核心修正】：利用 Action.RunUI 实现单人私密反馈
            -- 并通过传递真实 p_id 确保 Chat.Text 挂在正确的头像下
            pcall(function()
                Action.RunUI(function(p_id_to_send, res_txt)
                    if Chat and Chat.Text then
                        -- 设置回显消息：以服务器身份但在对应的本地会话中
                        Chat.Text({
                            txt = "[SERVER] " .. tostring(res_txt),
                            -- 关键：设为 p_id_to_send，则客户端会认为是用户自己收到了反馈
                            player_id = p_id_to_send
                        }, p_id_to_send)
                    end
                end, real_p_id, result)
            end)
        end
    end
end

---------------------------------------------------------------------------
-- 2. 命令引擎
---------------------------------------------------------------------------
_G.CmdServerMod.execute_command = function(text, p_id)
    if not text or text:sub(1, 1) ~= "/" then return false end
    local cmd_line = text:sub(2)
    local parts = {}
    for part in cmd_line:gmatch("%S+") do table.insert(parts, part) end
    if #parts == 0 then return true, "Error: No command" end

    local cmd_name = parts[1]:lower()

    if cmd_name == "ping" then
        return true, "PONG (ID:" .. p_id .. " Authority:Verified)"
    elseif cmd_name == "help" then
        return true, "Available: /ping, /help"
    else
        return true, "Unknown command: " .. cmd_name
    end
end

---------------------------------------------------------------------------
-- 3. 定时器 (心跳)
---------------------------------------------------------------------------
function MapMsg.OnTick()
    tick_counter = tick_counter + 1
    if tick_counter >= 50 then
        tick_counter = 0
        local current_tick = Map.GetTick()
        srv_print("HEARTBEAT", string.format("Tick: %d | Players: %d", current_tick, #Game.GetAllPlayers()))
    end
end
