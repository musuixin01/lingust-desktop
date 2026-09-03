# Agent Working Guidelines & Project Conventions

## 核心工作规约 (Mandatory Rule)

### 变动与文档实时同步规约 (Real-time Documentation Sync)
**在任何代码修改、功能新增、重构或缺陷修复时，必须同步将变动详情记录到项目文档中，保持实时更新：**

1. **变动记录日志 (`docs/CHANGELOG.md`)**：
   - 每次代码变更必须在 `docs/CHANGELOG.md` 中按最新版本号/日期追加更新记录。
   - 遵循规范的语义化分类：`[Added]`（新增功能）、`[Changed]`（优化变更）、`[Refactored]`（架构重构）、`[Fixed]`（问题修复）、`[Docs]`（文档更新）。
   - 清晰列出涉及的文件与影响范围。

2. **核心业务文档同步**：
   - 若涉及 UI 视觉组件、交互模态、颜色或排版调整，必须严格遵从并实时同步更新 `docs/DESIGN_SYSTEM.md`。
   - 若涉及新增/修改 API，必须实时同步更新 `docs/API.md`。
   - 若涉及系统拓扑、组件拆分或架构演进，必须实时同步更新 `docs/ARCHITECTURE.md` 与 `docs/HANDOVER.md`。
   - 若涉及用户端功能入口或安装配置变动，必须实时同步更新 `README.md`。
