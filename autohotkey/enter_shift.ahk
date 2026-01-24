#Requires AutoHotkey v2.0

SC079::
{
    isShort := KeyWait("SC079", "T0.2")

    if isShort {
        Send "{Enter}"
        KeyWait "SC079"
    } else {
        Send "{Shift Down}"
        KeyWait "SC079"
        Send "{Shift Up}"
    }
}
