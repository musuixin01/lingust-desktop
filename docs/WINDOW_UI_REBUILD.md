# 窗口与界面重建交接

## 范围与技术决定

用户已确认项目外 `lingust-border-drag-test/border_drag_test.cpp` 的边框稳定，本轮直接复用其中 GDI+ 四圆弧路径、抗锯齿参数、内描边、DIB 与 UpdateLayeredWindow 提交逻辑。Windows 代码放 Platform；Core 控制状态和离屏 QML；QML 仅负责内容与交互。

保留 Qt/QML，避免另引浏览器或更换翻译业务层。Qt Quick 性能建议要求减少每帧绑定与复杂布局计算；本轮把卡片改为固定顶部、底部和单一滚动内容区。交互只改变颜色/透明度，手动拉伸不叠加布局动画。模式切换只由宿主改变尺寸，取消 QML 的第二套缩放动画。

来源：https://doc.qt.io/qt-6/qtquick-performance.html
来源：https://developer.apple.com/design/human-interface-guidelines/motion

## 文件职责

- `platform/windows/window/WindowsResizeSession.*`：测试框路径、GDI+ 生命周期、内容合成、原子提交、物理像素锚点。
- `core/window/TranslatorWindow.*`：持久内容画布、窗口模式、输入转发、可中断尺寸过渡。
- `ui/Main.qml`：模式装配和独立设置/历史/音乐/截图窗口。
- `ui/card/CardView.qml`：清晰的标题栏、内容、操作栏；窄窗口将次要操作放入菜单。
- `ui/components/IconButton.qml`：即时按下反馈、键盘焦点、辅助名称、提示。
- `ui/card/WordDetailView.qml`：单词、音标、发音独立区域，保留现有词典结果功能。

## 视觉约定

苹果式深色工具窗：32 逻辑像素大圆角，细白内描边，克制的蓝色强调，正文优先。按钮固定占位，不因悬停变宽。窄屏保留搜索、译文和展开/更多入口；长词换行。设置等长内容使用独立窗口，不强塞入最小卡片。

## 验收与证据边界

构建、QML 行为检查、实际桌面截图、八向拉伸分别记录。拖动必须发生实际位移才计入有效结果；分别检查原生固定边和可见圆角。零像素测量只代表采样条件，不能保证所有硬件/缩放/后台负载绝对零延迟。保留原子提交路径并对再现问题继续测量。

修改前恢复包：`build/before-test-shell-ui.zip`。

## 本轮验证记录

- `build/test-shell-native-fixed.json`：125% DPI，八向拖动各实际移动 300 物理像素；固定边漂移 0，圆角切入轮廓变化 0。
- `build/rebuild-ui-final-qml.log`：92 项通过，包括 160px 起的布局、防重叠、最矮布局、药丸图标、长词/音标、键盘和即时按下反馈。
- 原生事件过滤器对可空返回指针进行防护；测试发现问题后通过调试器定位，已修复并重新通过八向拖动。
- `scripts/check_desktop_ui.py` 验证实际独立操作窗口及 Escape 关闭，并保留应用窗口局部截图；不会把进程存在当作界面可用。
- 内容区鼠标输入与测试边框共用原生窗口过程，再换算为逻辑坐标投递给离屏 QML 场景；发布前已移除诊断日志。
