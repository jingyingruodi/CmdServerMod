# 快速参考卡片

用于快速查找相关文档和信息的索引。

**首先**：查看 [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) 了解项目全貌！

---

## 🚀 我是新手，想快速开始

### 用户
1. 阅读 [README.md](README.md) - 功能与安装说明
2. 启动游戏，试试命令 `/help`

### 开发者  
1. 阅读 [README.md](README.md) - 项目概览
2. 阅读 [ARCHITECTURE_WARNING.md](ARCHITECTURE_WARNING.md) - 理解当前限制
3. 阅读 [DEVELOPMENT.md](DEVELOPMENT.md) - 深入技术细节

---

## ⚠️ 我想了解架构问题

按照以下顺序阅读：

1. **[ARCHITECTURE_WARNING.md](ARCHITECTURE_WARNING.md)** (5分钟)
   - 问题快速概览
   - 当前工作/不工作的场景
   - 正确做法原则

2. **[ARCHITECTURE_PROBLEMS_ANALYSIS.md](ARCHITECTURE_PROBLEMS_ANALYSIS.md)** (20分钟)
   - 详细问题分析
   - 与正确架构的对比
   - 安全隐患说明
   - 改进建议

3. **[PROJECT_ARCHITECTURE_PLAN.md](PROJECT_ARCHITECTURE_PLAN.md)** (15分钟)
   - 长期规划
   - 版本路线
   - 实施细节

---

## 💻 我想贡献代码

1. 阅读 [CONTRIBUTING.md](CONTRIBUTING.md) - 贡献流程
2. 阅读 [ARCHITECTURE_WARNING.md](ARCHITECTURE_WARNING.md) - **重要！** 了解架构限制
3. 在 DEVELOPMENT.md 中查找相关部分
4. 查看 [DEVELOPMENT_MANAGEMENT.md](DEVELOPMENT_MANAGEMENT.md) - 代码标准
5. 开始编码

**关键提醒**：
- ❌ 不要在现有架构上实现权限系统
- ✅ 可以改进已有命令
- 💡 可以提议架构改进（先讨论）

---

## 🔧 我要修复一个 bug

1. 找到 [DEVELOPMENT.md](DEVELOPMENT.md) 中的"已知问题"部分
2. 查看 [DUAL_COMPATIBILITY_IMPLEMENTATION.md](DUAL_COMPATIBILITY_IMPLEMENTATION.md) 了解当前实现
3. 查阅 [DEVELOPMENT_MANAGEMENT.md](DEVELOPMENT_MANAGEMENT.md) 中的测试流程

---

## 📋 我想了解整个项目

按照以下顺序：

1. **快速概览** (10分钟)
   - [README.md](README.md) - 用户视角
   - [ARCHITECTURE_WARNING.md](ARCHITECTURE_WARNING.md) - 问题概览

2. **技术细节** (30分钟)
   - [DEVELOPMENT.md](DEVELOPMENT.md) - 代码结构
   - [ARCHITECTURE_PROBLEMS_ANALYSIS.md](ARCHITECTURE_PROBLEMS_ANALYSIS.md) - 为什么这样设计

3. **深入规划** (20分钟)
   - [PROJECT_ARCHITECTURE_PLAN.md](PROJECT_ARCHITECTURE_PLAN.md) - 未来计划
   - [DEVELOPMENT_MANAGEMENT.md](DEVELOPMENT_MANAGEMENT.md) - 开发规范

---

## 🗂️ 完整文档列表

| 文档 | 用途 | 读者 | 优先级 |
|------|------|------|--------|
| [README.md](README.md) | 项目概览 | 所有人 | 🔴 必读 |
| [ARCHITECTURE_WARNING.md](ARCHITECTURE_WARNING.md) | 架构问题概览 | 开发者 | 🔴 必读 |
| [ARCHITECTURE_PROBLEMS_ANALYSIS.md](ARCHITECTURE_PROBLEMS_ANALYSIS.md) | 详细问题分析 | 架构师/开发者 | 🟠 应读 |
| [DEVELOPMENT.md](DEVELOPMENT.md) | 代码结构说明 | 开发者 | 🟠 应读 |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 贡献流程 | 贡献者 | 🟠 应读 |
| [PROJECT_ARCHITECTURE_PLAN.md](PROJECT_ARCHITECTURE_PLAN.md) | 长期规划 | 架构师/PM | 🟡 可选 |
| [DUAL_COMPATIBILITY_IMPLEMENTATION.md](DUAL_COMPATIBILITY_IMPLEMENTATION.md) | 当前实现细节 | 高级开发者 | 🟡 可选 |
| [DEVELOPMENT_MANAGEMENT.md](DEVELOPMENT_MANAGEMENT.md) | 开发规范 | 开发者 | 🟡 可选 |
| [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) | 文档导航 | 想了解全景的人 | 🟡 可选 |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | 快速查找（本文件） | 所有人 | 🟡 参考 |
| [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) | 项目全景信息 | 所有人 | 🟡 参考 |
| [DOCUMENTATION_STATUS_v1.0.2.md](DOCUMENTATION_STATUS_v1.0.2.md) | 文档完成报告 | 项目管理者 | ⚪ 参考 |
| [v1.0.2_SUMMARY.md](v1.0.2_SUMMARY.md) | 版本总结 | 所有人 | ⚪ 参考 |

---

## 🎯 常见问题

### Q: 什么时候合并 PR？
→ 查看 [DEVELOPMENT_MANAGEMENT.md](DEVELOPMENT_MANAGEMENT.md) 中的"代码审查标准"

### Q: 应该创建哪类 issue？
→ 查看 [CONTRIBUTING.md](CONTRIBUTING.md) 中的"报告问题"部分

### Q: 如何测试修改？
→ 查看 [DEVELOPMENT_MANAGEMENT.md](DEVELOPMENT_MANAGEMENT.md) 中的"测试流程"

### Q: 权限系统什么时候实现？
→ 查看 [ARCHITECTURE_WARNING.md](ARCHITECTURE_WARNING.md)
→ 当前架构不支持安全的权限系统（v1.1 计划修复）

### Q: 我想添加新命令
→ 查看 [DEVELOPMENT.md](DEVELOPMENT.md) 中的"扩展命令"部分

### Q: 日志中看不到服务端的命令输出
→ 查看 [ARCHITECTURE_WARNING.md](ARCHITECTURE_WARNING.md) - 这是已知的架构限制

---

## 📚 按读取时间排序

| 时间 | 最小化阅读 | 标准阅读 | 完整理解 |
|------|-----------|---------|---------|
| 5分钟 | README.md | + ARCHITECTURE_WARNING.md | + ARCHITECTURE_PROBLEMS_ANALYSIS.md 前3部分 |
| 15分钟 | + DEVELOPMENT.md 前半部分 | + DEVELOPMENT.md 全部 | + PROJECT_ARCHITECTURE_PLAN.md 前2部分 |
| 30分钟 | 完成 | + CONTRIBUTING.md | + 全部规划文档 |
| 45分钟 | — | 完成 | + DEVELOPMENT_MANAGEMENT.md |
| 60分钟 | — | — | 完成 |

---

## 🔗 相关链接速查

### 架构与设计
- 🚨 快速警告：[ARCHITECTURE_WARNING.md](ARCHITECTURE_WARNING.md)
- 📊 详细分析：[ARCHITECTURE_PROBLEMS_ANALYSIS.md](ARCHITECTURE_PROBLEMS_ANALYSIS.md)
- 📋 规划方案：[PROJECT_ARCHITECTURE_PLAN.md](PROJECT_ARCHITECTURE_PLAN.md)
- 🔧 当前实现：[DUAL_COMPATIBILITY_IMPLEMENTATION.md](DUAL_COMPATIBILITY_IMPLEMENTATION.md)

### 开发指南
- 👨‍💻 代码结构：[DEVELOPMENT.md](DEVELOPMENT.md)
- 🤝 如何贡献：[CONTRIBUTING.md](CONTRIBUTING.md)
- 📋 开发规范：[DEVELOPMENT_MANAGEMENT.md](DEVELOPMENT_MANAGEMENT.md)

### 用户文档
- 📘 功能说明：[README.md](README.md)
- 🎓 扩展指南：[EXTENSION_GUIDE.lua](EXTENSION_GUIDE.lua)

### 导航与索引
- 🗂️ 完整索引：[DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)
- 📝 版本总结：[v1.0.2_SUMMARY.md](v1.0.2_SUMMARY.md)

---

**最后更新**：2026-03-20
**当前版本**：v1.0.2
