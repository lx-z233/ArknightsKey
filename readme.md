# 📱 Arknights Helper - 明日方舟键位辅助工具 (AHK v2)

<p align="center">
  <img src="https://img.shields.io/badge/Language-AutoHotkey_v2-green.svg" alt="AHK v2">
  <img src="https://img.shields.io/badge/Platform-Windows-blue.svg" alt="Windows">
  <img src="https://img.shields.io/badge/License-MIT-orange.svg" alt="License">
</p>

> **一个轻量级、安全、防误触的《明日方舟》PC端键位映射与宏辅助工具。**  
> 告别模拟器繁琐的键位设置，体验原生的键盘操作手感。

---

## ✨ 主要功能

本工具不仅提供基础的键位映射，还包含了一些实用的“宏”功能，帮助博士们更轻松地进行战斗部署。

*   **🛡️ 智能防误触**：仅在游戏窗口激活时生效，切出窗口自动休眠，不影响打字或其他游戏。
*   **⚡ 基础键位映射**：
    *   **倍速切换** (默认 `Space`) -> 映射到游戏 `m`
    *   **暂停游戏** (默认 `f`) -> 映射到游戏 `Esc`
*   **🕹️ 宏功能**：
    *   **双击过帧 (子弹时间)** (默认 `e`)：极速暂停两次，实现“逐帧”操作，肉鸽高难必备。
    *   **自动选人** (默认 `s`)：暂停 -> 点击 -> 暂停，实现一帧开多个技能
    *   **技能释放** (默认 `d`)：鼠标放在干员上按`d`即可开技能
    *   **撤退干员** (默认 `a`)：鼠标放在干员上按`a`即可撤退
*   **⚙️ 易于配置**：
    *   **F1**：全局开启/暂停脚本
    *   **F2**：显示当前键位面板 (HUD)
    *   **F5**：重载配置文件
    *   启动时自动检查键位冲突。

---

## 🚀 使用方法

### 方式一：直接运行 (推荐普通用户)
1. 下载 Release 中的 `ArknightsKey.exe`。
2. **右键以管理员身份运行** (必须，否则无法向游戏发送按键)。
3. 启动《明日方舟》PC客户端或模拟器。
4. 看到弹窗提示“🚀 脚本已启动”即可开始使用。

### 方式二：运行源码 (推荐开发者)
1. 安装 [AutoHotkey v2](https://www.autohotkey.com/)。
2. 下载 `ArknightsKey.ahk` 文件。
3. 双击脚本文件运行。

---

## ⚙️ 配置文件 (settings.ini)

首次运行脚本后，会在同目录下自动生成 `settings.ini` 文件。你可以用记事本打开它来修改键位。

**文件结构示例：**
```ini
[GameKeys (游戏内键位)]
Speed (倍速键) = m
Skill (技能键) = p
Retreat (撤退键) = o
Pause (暂停键) = Esc


[Hotkeys (自定义键位)]
Script_Pause (脚本暂停) = f
Script_Speed (脚本倍速) = Space
Script_Double (双击过帧) = e
Script_Skill (释放技能) = d
Script_Select (自动选人) = s
Script_Retreat (自动撤退) = a
