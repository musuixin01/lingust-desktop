# Windows 构建、安装与发布

发布前必须阅读并更新 [全局功能验证记录](./VALIDATION.md)，明确自动化通过项与仍需真实媒体、密钥或桌面交互确认的边界。

当前版本说明见 [Linguist v0.1.0](./RELEASE_NOTES_0.1.0.md)。

## 发布结构

`scripts/package_windows.ps1` 负责四件事：以单线程 Release 模式稳定编译、使用 Qt 官方 `windeployqt` 收集运行库、生成独立运行目录、调用 Inno Setup 生成用户级安装包。安装程序默认写入 `%LOCALAPPDATA%\Programs\Linguist`，无需管理员权限，并创建开始菜单入口与完整卸载项。

离线 ECDICT 数据体积较大，当前安装包不内置 `data/ecdict-sqlite-28.zip`。未配置云端密钥时，程序会使用免密在线兜底；需要离线词典时，应将解压后的 `stardict.db` 放到安装目录下的 `data` 文件夹。

## 生成安装包

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\package_windows.ps1 -InstallPackagingTool
```

首次执行可通过 `winget` 安装 Inno Setup 7；之后无需再传 `-InstallPackagingTool`。默认 Qt 路径为 `D:\DevTools\QT\6.11.2\mingw_64`，其他环境使用 `-QtBin` 指定。

输出文件：

- `artifacts/Linguist-Setup-0.1.0-win64.exe`
- `artifacts/Linguist-Setup-0.1.0-win64.exe.sha256`
- `artifacts/Linguist-0.1.0-win64/`（免安装运行目录）

## 发布前验证

1. 运行 QML 回归、OCR 桥接测试和真实桌面探针。
2. 使用 `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /DIR=...` 安装到临时目录。
3. 从临时安装目录启动，确认窗口、托盘和运行库完整。
4. 执行卸载器并确认程序文件删除。
5. 比对安装包 SHA-256，检查 Git 工作区、远端可见性与提交哈希后再推送。

安装包暂未进行代码签名，因此 Windows SmartScreen 可能显示未知发布者。正式公开分发时，应为安装程序和 `lingust.exe` 增加可信代码签名。
