# Development Guide - Command Console Mod

This document explains the technical design, architecture, and implementation details of the Command Console mod.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Message Flow](#message-flow)
3. [Code Structure](#code-structure)
4. [Command System](#command-system)
5. [Extending Commands](#extending-commands)
6. [Testing](#testing)

---

## Architecture Overview

The Command Console mod operates in two distinct Lua execution contexts:

### Layer 1: Simulation (Server-side)
- **File**: `simulation/main.lua`
- **Responsibility**: Command parsing, execution, and result generation
- **Context**: Runs once on the server/host
- **Key Hook**: Intercepts `UI.Run("OnReceivedChat", arg)` calls

### Layer 2: UI (Client-side)
- **File**: `ui/main.lua`
- **Responsibility**: Filtering results by player and displaying locally
- **Context**: Runs once per player client
- **Key Hook**: Re-intercepts `UI.Run("OnReceivedChat", arg)` calls

### Why Two Layers?

In Desynced's architecture:
- **Simulation** has access to all game state and Map API (server authority)
- **UI** runs locally on each client and controls what's displayed

**Problem**: If we only hook in Simulation, results are broadcasted globally.  
**Solution**: Hook twice:
1. Simulation: Execute command, mark result with `[CMD_RESULT:player_id]`
2. UI: Detect marked messages, filter by `Game.IsLocalPlayer()`, only display locally

This ensures:
✅ Commands execute server-side (fair, authoritative)  
✅ Results only visible to command sender (privacy)  
✅ Normal chat unaffected (`[CMD_RESULT:]` prefix auto-tags)

---

## Message Flow

### Normal Chat Message Path

```
Player A types: "hello"
         ↓
    Chat.Text() [defined in game]
         ↓
    UI.Run("OnReceivedChat", {txt: "hello", player_id: 0})
         ↓
    [Simulation intercepts]
    - Check: message starts with "/"? NO
    - Pass through: return original_ui_run("OnReceivedChat", arg)
         ↓
    [UI intercepts]
    - Check: starts with "[CMD_RESULT:"? NO
    - Pass through: return original_ui_run("OnReceivedChat", arg)
         ↓
    UIMsg.OnReceivedChat(arg) [game's original handler]
         ↓
    TextChat displays: "[A] hello" (all players see it)
```

### Command Message Path

```
Player A types: "/test"
         ↓
    Chat.Text() [defined in game]
         ↓
    UI.Run("OnReceivedChat", {txt: "/test", player_id: 0})
         ↓
    [Simulation intercepts]
    - Check: starts with "/"? YES
    - Execute: execute_command("/test", 0)
    - Get result: "测试命令已执行!"
    - Tag result: {txt: "[CMD_RESULT:0] 测试命令已执行!", player_id: 0}
    - Broadcast: return original_ui_run("OnReceivedChat", tagged_arg)
         ↓
    [UI intercepts]
    - Check: starts with "[CMD_RESULT:"? YES
    - Extract: target_player_id = 0, content = "测试命令已执行!"
    - Filter: if Game.IsLocalPlayer(0)? YES (player A's client)
    - Reformat: {txt: "[CMD] 测试命令已执行!", player_id: 0}
    - Display: return original_ui_run("OnReceivedChat", reformatted_arg)
         ↓
    UIMsg.OnReceivedChat(arg) [game's original handler]
         ↓
    TextChat displays: "[系统] [CMD] 测试命令已执行!" (ONLY on Player A's screen)
```

### Same Command Message on Player B's Client

```
Message arrives on network: {txt: "[CMD_RESULT:0] 测试命令已执行!", player_id: 0}
         ↓
    [UI intercepts on Player B's client]
    - Check: starts with "[CMD_RESULT:"? YES
    - Extract: target_player_id = 0, content = "..."
    - Filter: if Game.IsLocalPlayer(0)? NO (player B's ID is 1)
    - Discard: return (empty return, message blocked)
         ↓
    [Message does NOT reach game's original handler]
         ↓
    TextChat displays: (nothing - message filtered out)
```

---

## Code Structure

### simulation/main.lua (191 lines)

```lua
-- Configuration
local config = { command_prefix = "/", debug_log = true }
local commands = {}
local output_buffer = {}

-- Utilities
local function split_string(str, delimiter)     -- Parse "arg1 arg2 arg3" → {"arg1", "arg2", "arg3"}
local function output_to_chat(message)          -- Buffer output message
local function get_buffered_output()            -- Retrieve and clear buffer

-- Command System
local function register_command(name, desc, args, handler)  -- Register a command
local function show_help(cmd_name)              -- Display help
local function execute_command(message, player_id)  -- Main dispatcher

-- Hook Layer
local original_ui_run = UI.Run
function UI.Run(func_name, ...)                 -- Intercept UI.Run calls
    if func_name == "OnReceivedChat" then
        -- Parse command vs normal chat
        -- Execute if command
        -- Return tagged result
    end
end

-- Command Definitions
register_command("help", ..., handler_function)
register_command("test", ..., handler_function)
register_command("settings", ..., handler_function)
register_command("info", ..., handler_function)
```

### ui/main.lua (41 lines)

```lua
-- Hook Layer
local original_ui_run = UI.Run

function UI.Run(func_name, ...)
    if func_name == "OnReceivedChat" then
        -- Detect [CMD_RESULT:player_id] pattern
        -- Check: is this for local player?
        -- If yes: format and display
        -- If no: block message (return early)
    else
        -- Pass other functions through
    end
end
```

---

## Command System

### Command Registration

Commands are registered using:

```lua
register_command(
    "commandname",           -- name (no "/" prefix)
    "Help description",      -- displayed in /help
    "[optional args]",       -- argument description
    function(args)           -- handler function
        output_to_chat("Result message")
    end
)
```

### Handler Function Signature

```lua
function(args)
    -- args is a table: args[1], args[2], etc.
    -- Example: "/mycommand foo bar"
    --          args = {"foo", "bar"}
    
    -- Output must use output_to_chat()
    output_to_chat("Success!")
end
```

### Command Execution Flow

1. User types: `/help mycommand`
2. Game calls: `Chat.Text({txt: "/help mycommand", player_id: X})`
3. Our `UI.Run` intercepts
4. Simulation layer:
   - Extracts prefix: "/" → is command
   - Splits args: ["help", "mycommand"]
   - Looks up: `commands["help"]`
   - Calls: `handler(["mycommand"])`
   - Handler calls: `output_to_chat("...")`
   - Messages buffer in `output_buffer[]`
   - Joins with newlines: `"line1\nline2\nline3"`
   - Tags: `"[CMD_RESULT:0] " .. result`
   - Broadcasts via `UI.Run("OnReceivedChat", modified_arg)`
5. UI layer:
   - Detects `[CMD_RESULT:0]` tag
   - Checks `Game.IsLocalPlayer(0)` → true
   - Reformats to `"[CMD] " .. content`
   - Calls original `UI.Run("OnReceivedChat", reformatted)`
6. Game displays in chat

### Error Handling

Commands are wrapped in `pcall()`:

```lua
local success, error_msg = pcall(cmd.handler, cmd_args)
if not success then
    output_to_chat("执行出错: " .. tostring(error_msg))
end
```

This prevents one broken command from crashing the entire system.

---

## Extending Commands

### Adding a Simple Command

Edit `simulation/main.lua` and add before the initialization section:

```lua
register_command("echo", "Echo a message", "<text>", function(args)
    if #args == 0 then
        output_to_chat("Usage: /echo <text>")
    else
        local text = table.concat(args, " ")
        output_to_chat("Echo: " .. text)
    end
end)
```

### Adding a Command That Queries Game State

```lua
register_command("daycount", "Show total days passed", "", function(args)
    output_to_chat("Total days: " .. tostring(Map.GetTotalDays()))
end)
```

### Adding a Command That Modifies State

```lua
register_command("pause", "Pause/unpause game", "", function(args)
    Map.SetTimeDilation(0)  -- Example (actual API may differ)
    output_to_chat("Game paused")
end)
```

### Guidelines

✅ **DO**
- Use `output_to_chat()` for all output
- Check argument count: `#args`
- Validate inputs before using
- Provide helpful error messages
- Use `table.concat()` for multi-word args

❌ **DON'T**
- Use `print()` directly (goes to game log, not chat)
- Assume arguments exist
- Access `player_id` without being passed it
- Modify global state without care
- Create infinite loops or blocking operations

---

## Testing

### Manual Testing Steps

1. **Load game with mod enabled**
2. **Test basic commands**:
   ```
   /help              → Should list all commands
   /test              → Should output "测试命令已执行!"
   /settings          → Should list map settings
   /info              → Should show game info
   ```
3. **Test with multiple players**:
   - Player A: `/test`
   - Only Player A should see the result
   - Player B should NOT see it in chat
4. **Test normal chat still works**:
   - Type: "hello world" (no `/`)
   - All players should see it broadcasted

### Debug Logging

The mod outputs debug info if `config.debug_log = true` in `simulation/main.lua`:

Look for log lines starting with:
- `[CHAT-LOG]` - Chat input detection
- `[CHAT-PASS]` - Normal chat messages
- `[CMD-OUTPUT]` - Command output lines
- `[CMD-EXECUTED]` - Command execution confirmation
- `[CMD-UI]` - UI filtering decisions

### Checking Mod is Loaded

Look in game log for:
```
[CmdServerMod] 命令台模组已加载!
[CmdServerMod] UI.Run 处理器已激活
[CmdServerMod UI] UI模块已加载
```

If you don't see these, the mod didn't load (check game mod list).

---

## Implementation Details

### Why `UI.Run` Hook Instead of Replacing Functions?

Desynced's API doesn't allow direct replacement of `UIMsg.OnReceivedChat` (you'll get error: "Use UI.Run(...) to call bound UIMsg functions"). So we hook at the `UI.Run` level, which is the official way to intercept.

### Message Tagging Strategy

We use a simple prefix pattern `[CMD_RESULT:player_id]` because:
- ✅ Easy to parse with regex
- ✅ Won't conflict with normal chat (unusual pattern)
- ✅ Visible if accidentally broadcast (debugging aid)
- ✅ No special characters that break Lua strings

### Multi-player Safety

The `[CMD_RESULT:]` tag is crucial for multiplayer:
1. Simulation broadcasts all results (server can't know which client will receive it)
2. Each client receives all messages
3. Each client's UI layer filters locally based on `player_id`
4. Only the intended recipient displays it

This is a standard multiplayer pattern (client-side filtering).

---

## Future Improvements

### Planned
- [ ] Implement `/set` and `/speed` commands (framework exists)
- [ ] Add permission levels (admin-only commands)
- [ ] Command aliases and shortcuts
- [ ] Command history in chat memory

### Architecture Considerations
- Consider moving command definitions to separate `commands/` directory
- May want a Lua config file for user-customizable commands
- Consider persistent command history/logging to file

---

## References

- **Game Docs**: See `Desynced Lua API.html`, `Modding - Desynced Wiki.html`
- **Command Registration**: `simulation/main.lua` lines ~120
- **Message Filtering**: `ui/main.lua` lines ~20-30

## Questions?

See `CONTRIBUTING.md` for how to ask questions or report issues.
