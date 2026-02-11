#Requires AutoHotkey v2.0
#SingleInstance Force

; 强制以管理员权限运行
if not A_IsAdmin
{
    try {
        Run "*RunAs " A_ScriptFullPath
    } catch {
        MsgBox "错误：需要管理员权限才能在游戏中运行脚本。", "权限不足", 0x10
    }
    ExitApp
}

; ==============================================================================
; 1. 配置加载与冲突检测
; ==============================================================================

ConfigFile := A_ScriptDir "\settings.ini"

; 用于存储所有配置的 Map对象 (变量名 -> 键位值)
Global Config := Map()
; 用于存储配置的元数据 (变量名 -> [INI区域, INI键名(中英双语), 默认值, 描述])
ConfigsMeta := Map(
    ; [游戏内键位] -> 对应 Arknights 模拟器里的键位
    "Game_Speed",   ["GameKeys (游戏内键位)", "Speed (倍速键)",   "m",   "游戏-倍速键"],
    "Game_Skill",   ["GameKeys (游戏内键位)", "Skill (技能键)",   "p",   "游戏-技能键"],
    "Game_Retreat", ["GameKeys (游戏内键位)", "Retreat (撤退键)", "o",   "游戏-撤退键"],
    "Game_Pause",   ["GameKeys (游戏内键位)", "Pause (暂停键)",   "Esc", "游戏-暂停键"],
    
    ; [脚本触发键] -> 对应你按键盘触发功能的键
    "Key_Pause",    ["Hotkeys (自定义键位)", "Script_Pause (脚本暂停)",  "f",     "脚本-暂停"],
    "Key_Speed",    ["Hotkeys (自定义键位)", "Script_Speed (脚本倍速)",  "Space", "脚本-倍速"],
    "Key_Double",   ["Hotkeys (自定义键位)", "Script_Double (双击过帧)", "e",     "脚本-过帧"],
    "Key_Skill",    ["Hotkeys (自定义键位)", "Script_Skill (释放技能)",  "d",     "脚本-开技能"],
    "Key_Select",   ["Hotkeys (自定义键位)", "Script_Select (自动选人)", "s",     "脚本-选人"],
    "Key_Retreat",  ["Hotkeys (自定义键位)", "Script_Retreat (自动撤退)", "a",     "脚本-撤退"],
)

; --- 第一步：读取配置 ---
LoadAllConfigs()
{
    ; --- 第一阶段：如果文件不存在，生成带空行的完美模板 ---
    if not FileExist(ConfigFile)
    {
        ; 准备要写入的内容，`n 代表换行
        ; 你可以在这里随意调整格式，加空行，加注释
        Content := ""
        
        ; [GameKeys] 区域
        Content .= "[GameKeys (游戏内键位)]`n"
        Content .= "Speed (倍速键) = m`n"
        Content .= "Skill (技能键) = p`n"
        Content .= "Retreat (撤退键) = o`n"
        Content .= "Pause (暂停键) = Esc`n"
        
        ; 这里插入两个空行，让文件看起来宽敞
        Content .= "`n`n"
        
        ; [Hotkeys] 区域
        Content .= "[Hotkeys (自定义键位)]`n"
        Content .= "Script_Pause (脚本暂停) = f`n"
        Content .= "Script_Speed (脚本倍速) = Space`n"
        Content .= "Script_Double (双击过帧) = e`n"
        Content .= "Script_Skill (释放技能) = d`n"
        Content .= "Script_Select (自动选人) = s`n"
        Content .= "Script_Retreat (自动撤退) = a`n"

        ; 将内容一次性写入文件，使用 UTF-16 编码（完美支持中文）
        try {
            FileAppend(Content, ConfigFile, "UTF-16")
        } catch as err {
            MsgBox "无法创建配置文件: " err.Message
        }
    }

    ; --- 第二阶段：正常读取配置 ---
    ; 无论文件是刚才生成的，还是原来就有的，都通过这里读取到内存中
    for VarName, Meta in ConfigsMeta {
        Section := Meta[1]
        Key     := Meta[2]
        Default := Meta[3]
        
        try {
            ; 读取 INI
            Val := IniRead(ConfigFile, Section, Key)
        } catch {
            ; 如果某个具体的键被用户删了，这里补回去（不带空行，但这属于修复逻辑）
            IniWrite(Default, ConfigFile, Section, Key)
            Val := Default
        }
        Config[VarName] := Trim(Val)  ; 加上 Trim()，把值两边的空格删干净
    }
    Config["Key_Suspend"] := "F1"
    Config["Key_ShowUI"] := "F2"
    Config["Key_Exit"] := "F4"
    Config["Key_Reload"] := "F5"
}

; --- 第二步：冲突检测 ---
CheckConflicts()
{
    UsedKeys := Map() ; 格式: Map("键位小写" -> "功能描述")
    ConflictMsg := ""

    for VarName, KeyValue in Config {
        ; --- 修改开始：安全获取描述 ---
        
        ; 1. 如果在元数据里有定义（是 ini 里读出来的）
        if ConfigsMeta.Has(VarName) {
            Desc := ConfigsMeta[VarName][4]
        }
        ; 2. 如果是硬编码的特殊键（F1/F5），手动给个描述
        else if (VarName == "Key_Suspend") {
            Desc := "全局-停用/启用 (F1)"
        }
        else if (VarName == "Key_ShowUI") {
            Desc := "全局-查看键位 (F2)"
        }
        else if (VarName == "Key_Reload") {
            Desc := "全局-退出 (F4)"
        }
        else if (VarName == "Key_Reload") {
            Desc := "全局-重启 (F5)"
        }
        ; 3. 防止未来添加了其他键忘了写描述导致报错
        else {
            Desc := "内置功能 (" VarName ")"
        }
        ; --- 修改结束 ---

        ; 统一转小写进行比较
        CheckKey := StrLower(Trim(KeyValue))
        
        if (CheckKey == "")
            continue

        if UsedKeys.Has(CheckKey)
        {
            ; 发现冲突！
            PrevDesc := UsedKeys[CheckKey]
            ConflictMsg .= Format("冲突按键: [{1}]`n  功能1: {2}`n  功能2: {3}`n`n", KeyValue, PrevDesc, Desc)
        }
        else
        {
            UsedKeys[CheckKey] := Desc
        }
    }

    if (ConflictMsg != "")
    {
        MsgBox "错误：检测到键位冲突！脚本无法启动。`n`n请修改 settings.ini 后重启脚本。`n`n" ConflictMsg, "键位冲突警告", 0x10
        ExitApp ; 直接退出，防止错误运行
    }
}

; 执行加载和检查
LoadAllConfigs()
CheckConflicts()

; --- 第三步：将 Map 的值赋给全局变量供后续调用 ---
; 这一步是为了让下面的 Action_Wait 等函数能直接用 Game_Skill 这样的变量名，保持代码可读性
Game_Skill   := Config["Game_Skill"]
Game_Retreat := Config["Game_Retreat"]
Game_Pause   := Config["Game_Pause"]
Game_Speed   := Config["Game_Speed"]

Key_Pause    := Config["Key_Pause"]
Key_Speed    := Config["Key_Speed"]
Key_Double   := Config["Key_Double"]
Key_Skill    := Config["Key_Skill"]
Key_Select   := Config["Key_Select"]
Key_Retreat  := Config["Key_Retreat"]

Key_Suspend  := Config["Key_Suspend"]
Key_ShowUI   := Config["Key_ShowUI"]
Key_Exit   := Config["Key_Exit"]
Key_Reload   := Config["Key_Reload"]


; ==============================================================================
; [新增] 1.5 游戏键位合法性检测
; ==============================================================================
; 因为 Send "{Key down}" 语法不支持组合键(如 ^s)，且必须是合法按键名
; 所以必须在启动时检查，防止运行时报错
CheckGameKeys()
{
    ; 定义需要检查的游戏内键位 (描述 -> 变量值)
    ; 注意：这里只检查发送给游戏的键，不检查触发脚本的热键
    GameKeysToCheck := [
        {Val: Game_Skill,   Desc: "游戏-技能键"},
        {Val: Game_Retreat, Desc: "游戏-撤退键"},
        {Val: Game_Pause,   Desc: "游戏-暂停键"},
        {Val: Game_Speed,   Desc: "游戏-倍速键"}
    ]

    for item in GameKeysToCheck {
        try {
            ; 1. 检查是否为空
            if (item.Val == "")
                throw Error("键位设置为空")

            ; 2. 核心检测：尝试获取按键的虚拟码
            ; 如果键名无效（比如 "Hahaha"），GetKeyVK 会直接抛出错误
            GetKeyVK(item.Val)
            
            ; 3. 额外检测：因为你的脚本用了 "{Key down}" 这种写法
            ; 这种写法不支持 "Ctrl+C" 这种组合键，只支持单键
            ; 如果用户填了 "^s"，GetKeyVK 可能通过，但 Send 会报错
            if (StrLen(item.Val) > 1 && InStr("!^+ #", SubStr(item.Val, 1, 1)))
                throw Error("游戏内键位不能包含修饰符 (Ctrl/Alt/Shift)`n请直接填写按键名称 (如 p, Enter)")

        } catch as err {
            MsgBox "❌ 游戏键位配置错误！`n`n"
                 . "出错的项目: " item.Desc "`n"
                 . "填写的数值: [" item.Val "]`n`n"
                 . "原因: " err.Message "`n`n"
                 . "脚本无法启动，请修改 settings.ini。", 
                 "键位检测未通过", 0x10
            ExitApp
        }
    }
}

; 执行检测
CheckGameKeys()


; ==============================================================================
; 2. 动作函数
; ==============================================================================

Action_Pause() 
{
    Send "{" Game_Pause " down}"  ; 按下 Esc
    Sleep 5                       ; 保持 5ms
    Send "{" Game_Pause " up}"    ; 松开 Esc
}

Action_Skill()
{
    Send "{" Game_Skill " down}"
    Sleep 10
    Send "{" Game_Skill " up}"
}

Action_Retreat()
{
    Send "{" Game_Retreat " down}"
    Sleep 10
    Send "{" Game_Retreat " up}"
}

Action_Press(key, duration)
{
    Send "{" key " down}"
    Sleep duration
    Send "{" key " up}"
}

; ==============================================================================
; 3. 动态注册热键
; ==============================================================================

IsGameActive(ThisHotkey) 
{
    return WinActive("ahk_exe Arknights.exe")
}

HotIf IsGameActive

    ; 定义一个列表，包含：[键位变量值, 对应的函数, 功能描述]
    ; 这样我们就可以通过循环来注册，一旦出错就能知道是哪一项
    HotkeyList := [
        {Key: Key_Pause,   Action: Logic_Pause,   Name: "脚本-暂停 (Key_Pause)"},
        {Key: Key_Speed,   Action: Logic_Speed,   Name: "脚本-倍速 (Key_Speed)"},
        {Key: Key_Double,  Action: Logic_Double,  Name: "脚本-过帧 (Key_Double)"},
        {Key: Key_Skill,   Action: Logic_Skill,   Name: "脚本-开技能 (Key_Skill)"},
        {Key: Key_Select,  Action: Logic_Select,  Name: "脚本-选人 (Key_Select)"},
        {Key: Key_Retreat, Action: Logic_Retreat, Name: "脚本-撤退 (Key_Retreat)"},
        {Key: Key_Suspend, Action: Global_Suspend, Name: "全局-停用/启用 (Key_Suspend)", Exempt: true},
        {Key: Key_ShowUI, Action: Global_ShowUI, Name: "全局-查看键位 (Key_ShowUI)", Exempt: true},
        {Key: Key_Exit, Action: Global_Exit, Name: "全局-退出 (Key_Exit)", Exempt: true},
        {Key: Key_Reload, Action: Global_Reload, Name: "全局-重启 (Key_Reload)", Exempt: true}
    ]

    ; 遍历列表逐个注册
    for item in HotkeyList {
        try {
            ; 尝试注册热键
            ; 检查是否有 Exempt 属性，且为 true
            Options := (item.HasOwnProp("Exempt") && item.Exempt) ? "S" : ""
            
            ; 注册热键：参数3是选项
            Hotkey item.Key, item.Action, Options
        } catch as err {
            MsgBox "❌ 注册热键失败！`n`n"
                 . "出错的功能: " item.Name "`n"
                 . "填写的键位: [" item.Key "]`n`n"
                 . "系统错误信息: " err.Message, 
                 "热键注册错误", 0x10
            ExitApp
        }
    }

HotIf

; ==============================================================================
; 4. 逻辑实现区
; ==============================================================================

; 暂停
Logic_Pause(ThisHotkey)
{
    Sleep 1
    Action_Press(Game_Pause, 5)
}

; 倍速
Logic_Speed(ThisHotkey)
{
    Sleep 1
    Action_Press(Game_Speed, 10)
}

; 过帧
Logic_Double(ThisHotkey)
{
    Sleep 1
    Action_Pause()
    Sleep 10
    Action_Pause()
}

; 选人
Logic_Select(ThisHotkey)
{
    Sleep 1
    Click "down"
    Sleep 1
    Send "{" Game_Pause " down}"
    Sleep 1
    Click "up"
    Sleep 0
    Send "{" Game_Pause " up}"
    Sleep 1
    Action_Pause()
}

; 技能
Logic_Skill(ThisHotkey)
{
    Click       ; 点击鼠标左键
    Sleep 100
    Action_Skill()
}

; 撤退
Logic_Retreat(ThisHotkey)
{
    Click       ; 点击鼠标左键
    Sleep 100
    Action_Retreat()
}

; ==============================================================================
; 4. 启动成功提示面板 (UI)
; ==============================================================================

ShowStartupPanel()
{
    ; 创建一个无边框的 GUI
    UI := Gui("+AlwaysOnTop -Caption +ToolWindow +Owner", "脚本状态")
    UI.BackColor := "1E1E1E"  ; 深色背景
    UI.SetFont("s10 cWhite", "Microsoft YaHei") ; 白色文字

    ; 标题
    UI.SetFont("s12 w700 c66CCFF")
    UI.Add("Text", "Center w250", "🚀 脚本已启动")
    
    ; 分隔线
    UI.SetFont("s8 cGray")
    UI.Add("Text", "Center w250 y+5", "--------------------------------")
    UI.SetFont("s10 cWhite")

    ; 动态列出所有触发键
    DisplayText := ""
    for item in HotkeyList {
        ; 格式化文本： 左边是功能名，右边是键位
        Line := Format("{:-10}  👉  [{:}]", item.Name, StrUpper(item.Key))
        UI.Add("Text", "x30 y+5", Line)
    }

    ; 底部提示
    UI.SetFont("s8 cGray")
    UI.Add("Text", "Center w250 y+15", "按 F1 开关脚本 | 按 F5 重载配置")

    ; 显示窗口 (不抢焦点)
    UI.Show("NoActivate AutoSize") ; 显示在左上角，或者去掉 x y 居中

    ; 3.5秒后自动销毁窗口
    SetTimer () => UI.Destroy(), -3500
}

; 调用显示面板
ShowStartupPanel()


; ==============================================================================
; [新增] 退出提示面板 (UI)
; ==============================================================================
ShowExitPanel()
{
    ; 创建无边框 GUI
    UI := Gui("+AlwaysOnTop -Caption +ToolWindow +Owner", "脚本退出")
    UI.BackColor := "1E1E1E"  ; 深色背景
    
    ; 标题 (使用淡红色强调退出状态)
    UI.SetFont("s12 w700 cFF6666", "Microsoft YaHei")
    UI.Add("Text", "Center w250", "👋 脚本即将退出...")
    
    ; 分隔线
    UI.SetFont("s8 cGray")
    UI.Add("Text", "Center w250 y+5", "--------------------------------")
    
    ; 提示信息
    UI.SetFont("s10 cWhite")
    UI.Add("Text", "Center w250 y+10", "功能已停止")

    ; 显示窗口 (居中显示)
    UI.Show("NoActivate AutoSize")
    
    ; 【重要】强制等待 1.2 秒，让用户看清提示后再关闭进程
    Sleep 1200
}

; ==============================================================================
; 5. 全局控制逻辑
; ==============================================================================

Global_Suspend(ThisHotkey)
{
    Suspend -1  ; 切换开关
    if (A_IsSuspended)
        SoundBeep 500, 200 ; 低音（关）
    else
        SoundBeep 1000, 200 ; 高音（开）
}

Global_ShowUI(ThisHotkey)
{
    ShowStartupPanel()
}

Global_Exit(ThisHotkey)
{
    Critical "On"
    ShowExitPanel()
    ExitApp
}

Global_Reload(ThisHotkey)
{
    Reload
}