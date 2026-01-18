#Requires AutoHotkey v2.0

#SingleInstance Force

TraySetIcon("C:\Users\ahcha\AutoHotkey\AHK-ico.ico")
A_IconTip := "デフォルト"

zenhanPath := "C:\Users\ahcha\bin\zenhan\bin64\zenhan.exe"

vkf0::Esc
~Esc::
{
    Run(zenhanPath " 0", , "Hide")
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
*/

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

/*
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
*/

F10::Send("{Volume_Up}")
F9::Send("{Volume_Down}")
