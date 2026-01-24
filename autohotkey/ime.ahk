#Requires AutoHotkey v2.0

userprofile := EnvGet("USERPROFILE")
zenhanPath := userprofile "\bin\zenhan\bin64\zenhan.exe"

F13::
{
    isShort := KeyWait("F13", "T0.15")
    if isShort {
        Run(zenhanPath " 0", , "Hide")
    } else {
        Run(zenhanPath " 1", , "Hide")
    }
    KeyWait("F13")
}
