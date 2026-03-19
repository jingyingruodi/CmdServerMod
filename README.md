# Desynced Command Console Mod

English | [中文](#中文)

A multiplayer-friendly in-game command system for Desynced. Execute commands via the chat interface with private command result feedback—only the command sender sees their own results.

## Features

- 🎮 **Chat-integrated commands**: Type commands directly in the game chat (`/help`, `/test`, `/settings`, `/info`)
- 🔒 **Private command results**: Each player only sees their own command output (not broadcasted to others)
- 🛠️ **Extensible system**: Easy to add new commands via simple registration API
- 📊 **Game info access**: Query map settings, current game tick, day/year info
- ✅ **Error handling**: Graceful command failures with user-friendly error messages
- 🎯 **Multi-player safe**: Works correctly in multiplayer sessions without interfering with normal chat

## Installation

1. Extract this mod into your Desynced mods folder:
   - **Windows**: `%AppData%/Local/Desynced/Mods/`
   - **Steam**: `<Steam>/steamapps/common/Desynced/Desynced/Content/mods/`

2. Launch Desynced and enable "Command Console" in mod list

3. Start a new game or load existing game

## Quick Start

### Available Commands

#### `/help` - Show all commands
```
/help                    # List all available commands
/help <command>          # Show detailed help for a command
```

#### `/test` - Test command
```
/test                    # Simple test to verify mod is working
```

#### `/settings` - View map settings
```
/settings                # Show all map settings
/settings <key>          # Show specific setting value
```

#### `/info` - Game information
```
/info                    # Display current game info (tick, days, year, sunrise/sunset)
```

### Usage Example

In any multiplayer game, press `K` (default) or click the chat icon to open chat:
```
/test
↓
Output (private): "测试命令已执行!"

/help
↓
Output (private): Shows all available commands
```

## Architecture

The mod works in two layers:

### Simulation Layer (`simulation/main.lua`)
- Intercepts chat messages via `UI.Run("OnReceivedChat")`
- Parses command prefix (`/`)
- Executes registered commands
- Marks results with `[CMD_RESULT:player_id]` tag
- Returns result only to the command executor

### UI Layer (`ui/main.lua`)
- Re-intercepts `UI.Run("OnReceivedChat")`
- Detects `[CMD_RESULT:player_id]` messages
- Uses `Game.IsLocalPlayer(player_id)` to filter
- **Only displays results to the target player**
- Normal chat messages pass through unchanged

**Why this design?**
- Commands must be executed server-side (Simulation)
- Results must be filtered client-side (UI)
- Each player's chat only shows their own results → no spoilers/privacy violation
- Normal chat is completely unaffected

## Extending the Mod

To add new commands, edit `simulation/main.lua` and add:

```lua
register_command("mycommand", "Description", "[args]", function(args)
    output_to_chat("Your command executed!")
end)
```

See `EXTENSION_GUIDE.lua` for detailed examples.

## Development

### Project Structure
```
CmdServerMod/
├── def.json                 # Mod metadata
├── simulation/main.lua      # Command engine & execution (191 lines)
├── ui/main.lua             # UI filtering layer (41 lines)
├── README.md               # This file
├── DEVELOPMENT.md          # Architecture details
├── CONTRIBUTING.md         # Contribution guidelines (TODO)
└── docs/
    └── architecture.md     # Detailed flow diagrams (TODO)
```

### Code Quality
- **Lua**: ~230 total lines (production code)
- **Error handling**: All commands wrapped in `pcall()` for safety
- **Logging**: Debug logs prefixed with `[CmdServerMod]` and `[CMD-*]`
- **Testing**: Manual testing in single/multiplayer games

## Version History

### v1.0.1 (2026-03-19)
- ✅ Core command system operational
- ✅ Private command result filtering (multiplayer-safe)
- ✅ Basic commands: `/help`, `/test`, `/settings`, `/info`
- ⚠️ Placeholder for `/set`, `/speed` commands (framework present, implementation pending)

### v1.0 (Earlier)
- Initial command framework

## Known Limitations & Future Work

### Current Limitations
- No permission/admin system (all players can execute all commands)
- Text-only interface (no GUI)
- Limited command set (extensible but currently only `/test`, `/help`, `/settings`, `/info`)
- Some settings changes may require map reload to take effect

### Planned Features
- [ ] Command aliases & macros
- [ ] Permission levels (admin-only commands)
- [ ] Command history & autocomplete
- [ ] Simple UI overlay for command palette
- [ ] Log file recording of command history
- [ ] Configuration preset system
- [ ] `/set` and `/speed` command implementation

## Troubleshooting

**Q: Commands not showing up?**
- Ensure mod is enabled in mod list
- Try `/help` to verify mod loaded
- Check game log for errors (look for `[CmdServerMod]` prefix)

**Q: Why can't other players see my command results?**
- By design! Results are private to prevent spam/confusion. Only you see your output.
- Normal chat messages are still broadcasted normally.

**Q: Does this affect normal chat?**
- No. Messages that don't start with `/` are processed normally.

## Contributing

We welcome contributions! Please see `CONTRIBUTING.md` for:
- Code style guidelines
- Pull request process
- Testing requirements
- AI-assisted development notes

## License

MIT License - See LICENSE file

## Support

- Report bugs: GitHub Issues
- Suggestions: GitHub Discussions
- Questions: README FAQ section

---

# 中文

## Desynced 命令台模组

一个多人友好的 Desynced 游戏内命令系统。通过聊天界面执行命令，命令结果只有发送者能看到（私聊风格）。

## 功能

- 🎮 **聊天集成命令**：在游戏聊天中输入命令（`/help`、`/test`、`/settings`、`/info`）
- 🔒 **私聊命令反馈**：每个玩家只看到自己的命令输出（不广播给其他人）
- 🛠️ **易扩展系统**：通过简单的注册 API 添加新命令
- 📊 **游戏信息访问**：查询地图设置、游戏 Tick、天数/年份
- ✅ **错误处理**：友好的命令错误提示
- 🎯 **多人安全**：支持多人模式，不影响正常聊天

## 安装

1. 解压至 Desynced mods 文件夹
2. 在游戏中启用"Command Console"
3. 开始游戏

## 快速开始

### 可用命令

```
/help                   # 显示所有命令
/test                   # 测试命令
/settings               # 查看地图设置
/info                   # 显示游戏信息
```

使用示例：按 `K` 打开聊天，输入 `/test`，只有你能看到结果。

## 架构

**Simulation 层** (`simulation/main.lua`)
- 拦截聊天消息，检测 `/` 前缀
- 执行命令，标记结果为 `[CMD_RESULT:player_id]`

**UI 层** (`ui/main.lua`)
- 再次拦截聊天消息
- 用 `Game.IsLocalPlayer()` 过滤
- **只显示目标玩家的结果**

这样保证了多人游戏中的隐私性和安全性。

## 版本

**v1.0.1** (2026-03-19)
- ✅ 核心命令系统工作
- ✅ 私聊过滤（多人安全）
- ✅ 基础命令：`/help`、`/test`、`/settings`、`/info`

## 许可证

MIT

## 贡献

欢迎提交 Pull Request！见 `CONTRIBUTING.md`。
