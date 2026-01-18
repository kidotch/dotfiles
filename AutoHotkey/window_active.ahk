#Requires AutoHotkey v2.0
#SingleInstance Force

; =========================
; 画面サイズ
; =========================
screenW := A_ScreenWidth
screenH := A_ScreenHeight

; =========================
; ホットキー
; =========================
#vkBA::ActivateZone("left")
#[::ActivateZone("right_top")
#]::ActivateZone("right_bottom")

; =========================
; ゾーン切替本体
; =========================
ActivateZone(zone) {
    global screenW, screenH

    WinList := WinGetList()

    for hwnd in WinList {

        ; 最小化ウィンドウ除外
        if WinGetMinMax(hwnd) != 0
            continue

        ; タイトルなし除外
        if !WinGetTitle(hwnd)
            continue

        ; ===== ツールウィンドウ除外（KeyCastOW対策）=====
        if (WinGetExStyle(hwnd) & 0x80) ; WS_EX_TOOLWINDOW
            continue

        WinGetPos(&x, &y, &w, &h, hwnd)

        ; ウィンドウ中心座標
        cx := x + w / 2
        cy := y + h / 2

        if IsInZone(cx, cy, zone, screenW, screenH) {
            ;ToolTip("Hit: " WinGetTitle(hwnd))
            ;Sleep 300
            ;ToolTip()
            WinActivate(hwnd)
            return
        }
    }
}

; =========================
; ゾーン定義
; =========================
IsInZone(cx, cy, zone, sw, sh) {
    switch zone {

        case "left":
            return cx < sw / 2

        case "right_top":
            return (cx >= sw / 2 && cy < sh / 2)

        case "right_bottom":
            return (cx >= sw / 2 && cy >= sh / 2)
    }
    return false
}
