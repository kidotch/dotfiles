#Requires AutoHotkey v2.0

#SingleInstance Force

TraySetIcon(A_ScriptDir "\icon1.ico")
A_IconTip := "デフォルト"

userprofile := EnvGet("USERPROFILE")
zenhanPath := userprofile "\bin\zenhan\bin64\zenhan.exe"

;capslockキー
F13::
{
    ; 押下時に即座に切り替え
    Send "{sc029}"

    ; 長押し判定（0.3秒待つ）
    if !KeyWait("F13", "T0.3")
    {
        ; 長押し：離すまで待って、また切り替え（元に戻る）
        KeyWait "F13"
        Send "{sc029}"
    }
    ; 短押し：何もしない（切り替えたまま）
}
/*
{
    global imeGauge, imeProgress, imeLabel, gaugeFilled
    gaugeFilled := false

    ; ゲージGUI作成
    imeGauge := Gui("+AlwaysOnTop -Caption +ToolWindow")
    imeGauge.BackColor := "1a1a1a"
    imeGauge.SetFont("s48 cWhite Bold", "Segoe UI")
    imeLabel := imeGauge.AddText("w120 Center", "A")
    imeGauge.SetFont("s10")
    imeProgress := imeGauge.AddProgress("w120 h10 cBlue Background333333", 0)
    imeGauge.Show("NoActivate")
    WinSetTransparent(200, imeGauge)

    ; ゲージアニメーション
    startTime := A_TickCount
    duration := 250  ; 0.3秒

    while GetKeyState("F13", "P") {
        elapsed := A_TickCount - startTime
        percent := Min(100, (elapsed / duration) * 100)
        imeProgress.Value := percent

        if (percent >= 100 && !gaugeFilled) {
            gaugeFilled := true
            imeLabel.Text := "あ"
            imeLabel.SetFont("c000000")
            imeProgress.Opt("cGreen")
            imeGauge.BackColor := "e0e0e0"
        }
        Sleep(10)
    }

    ; キーを離したら実行
    if gaugeFilled {
        Run(zenhanPath " 1", , "Hide")
    } else {
        Run(zenhanPath " 0", , "Hide")
    }

    imeGauge.Destroy()
}
*/
~Esc::
{
    Run(zenhanPath " 0", , "Hide")
}

/*
$;::
{
    if GetKeyState("Shift", "P")
        Send "{Blind};"  ; Shift+; は元のまま
    else
        Send "-"
}

$-::
{
    if GetKeyState("Shift", "P")
        Send "{Blind}-"  ; Shift+- は元のまま
    else
        Send ";"
}
*/
/*
~LAlt Up::
{
    if (A_PriorKey = "LAlt")
        Send "{Escape}"
}
*/
~LCtrl Up::
{
    if (A_PriorKey = "LControl")
        Send "{Escape}"
}

+Space::Backspace

/*
Space & h::Left
Space & j::Down
Space & k::Up
Space & l::Right

; Space + asdfg zxcvb → 1234567890
Space & a::1
Space & s::2
Space & d::3
Space & f::4
Space & g::5
Space & z::6
Space & x::7
Space & c::8
Space & v::9
Space & b::0
*/
; Win+Alt+矢印でマウス操作
/*
#!Left::MouseMove(-20, 0, 0, "R")
#!Right::MouseMove(20, 0, 0, "R")
#!Up::MouseMove(0, -20, 0, "R")
#!Down::MouseMove(0, 20, 0, "R")
#!Enter::Click
#!+Enter::Click "Right"
*/
; Space単押しでスペースを、Shift+SpaceでBackspace
/*
*Space Up::
{
    if (A_PriorKey = "Space") {
        if GetKeyState("Shift", "P")
            SendInput "{Backspace}"
        else
            SendInput "{Space}"
    }
}
*/

F8::
{
    prevHwnd := WinGetID("A")
    WinActivate("ahk_exe msedge.exe")
    WinWaitActive("ahk_exe msedge.exe", , 1)
    Send("{Media_Play_Pause}")
    WinActivate(prevHwnd)
}

/*
; --- Edge のとき ---
#HotIf WinActive("ahk_exe msedge.exe")
vkf0::Esc
#HotIf

; --- Edge 以外 ---
#HotIf !WinActive("ahk_exe msedge.exe")
vkf0::F12
#HotIf


WheelRight::Send("{Volume_Up}")
WheelLeft::Send("{Volume_Down}")

^WheelUp::Send "^{WheelDown}"
^WheelDown::Send "^{WheelUp}"

RButton & WheelUp::Send("{Volume_Down}")
RButton & WheelDown::Send("{Volume_Up}")
RButton & MButton::Send("{Volume_Mute}")

RButton::Send("{RButton}")

LButton & WheelDown::Send "^{tab}"
LButton & WheelUp::Send "^+{tab}"

~LButton & RButton::
{
    if KeyWait("RButton", "T0.5")
    {
        Send "^c"
        ToolTip "Copy"
        SetTimer () => ToolTip(), -800
    }
    else
    {
        Send "^x"
        ToolTip "Cut"
        SetTimer () => ToolTip(), -800
        KeyWait "RButton"
    }
}
RButton & LButton::
{
    Send "^v"
    ToolTip "Paste"
    SetTimer () => ToolTip(), -800
}

F13::
{
    if !KeyWait("F13", "T0.3")
    {
        Send "^c"       
        Tooltip "Copied!"
        SetTimer () => Tooltip(), -1000
        KeyWait "F13"
    }
    else
    {
        Send "^v"
    }
}

F10::Send("{Volume_Up}")
F9::Send("{Volume_Down}")

*/

