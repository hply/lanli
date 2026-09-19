# 栏历 — macOS 状态栏中国日历

原生 SwiftUI 菜单栏应用，Apple Silicon（M 系列）arm64。点击菜单栏日期弹出月历：农历、节气、国务院放假调休（休/班）。

## 系统要求

- macOS 14 Sonoma 或更高
- Apple Silicon（M1 / M2 / M3 / M4）
- Xcode 16 或更高

## 在 Xcode 里运行

1. 用 Xcode 打开 `Lanli.xcodeproj`
2. 顶部目标选 **My Mac**
3. 按 `⌘R` 运行
4. 菜单栏右上角出现日期，点击即弹出月历

这是菜单栏应用（`LSUIElement`），不占用程序埩。退出：齿轮打开设置后，菜单栏 **栏历 → 退出栏历**。

## 功能

- 公历 + 农历、二十四节气、干支生肖（年份 1900–2100）
- 2024–2026 国务院放假调休（休 / 班），数据在 `Lanli/Resources/Holidays.json`
- 农历黄历表 `Lanli/Resources/Almanac.json`（2020–2035）
- 自订节假日保存在本机，可覆盖官方条目
- 开机时启动（设置里开关，使用 `SMAppService`）
- 状态栏格式：月日 / 月日周 / 月日周时分 / 月日周时分秒 / 只显示图标
- 时区固定 `Asia/Shanghai`

## 节假日维护

弹出月历后点齿轮，进入设置窗口，可增改某一天的休 / 班 / 节日名称。
