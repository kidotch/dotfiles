#Requires AutoHotkey v2.0

global modeActive := false

SC029::  ; 半角/全角キー
{
    global modeActive
    modeActive := !modeActive  ; ON/OFFを反転させる

    if (modeActive) {
        ToolTip "モード: ON (テンキー入力)"
        SoundBeep 1000, 150  ; 高い音で通知
    } else {
        ToolTip "モード: OFF (通常入力)"
        SoundBeep 500, 150   ; 低い音で通知
    }
    
    ; 1.5秒後にツールチップ（メッセージ）を消す
    SetTimer () => ToolTip(), -1500
}

#HotIf modeActive  ; ここから下の設定は modeActive が真の時だけ有効
    q::4
    w::5
    e::6
    a::7
    s::8
    d::9
    z::0
    x::Send "^v"
    c::Send "{Enter}"
#HotIf  ; 条件設定の終了（ここから下は常に有効になる）

F8::
{
    weztermWin := "ahk_class org.wezfurlong.wezterm"
    hwnd := WinExist(weztermWin)
    if !hwnd
        return
    ControlSend("{Esc}yyp", , "ahk_id " hwnd)
}

F9::
{

    targetExe := "ahk_exe mpc-be64.exe"  ; 64bit版
    ; targetExe := "ahk_exe mpc-be.exe"    ; 32bit版
    weztermWin := "ahk_class org.wezfurlong.wezterm"

    ; MPC-BEが起動していなければ何もしない
    hwndMpc := WinExist(targetExe)
    if !hwndMpc
        return

    WinActivate("ahk_id " hwndMpc)
    if !WinWaitActive("ahk_id " hwndMpc, , 4)
    {
        ToolTip "MPC-BEをアクティブにできませんでした"
        SetTimer () => ToolTip(), -2000
        return
    }

    BackupClip := A_Clipboard ; 現在のクリップボードを保存（念のため）
    A_Clipboard := ""         ; クリップボードをクリア

    Send("^g")
    Sleep(150)
    Send("^a")
    Sleep(80)
    Send("^c")

    if !ClipWait(2)           ; コピー失敗時は終了
    {
        MsgBox "テキストのコピーに失敗しました。"
        return
    }

    text := Trim(A_Clipboard) ; 余計な空白を除去

    ; 正規表現で「数字:数字.数字」のパターンを取得
    ; m[1] = 分, m[2] = 秒(小数点含む)
    if RegExMatch(text, "^(\d+):(\d+(\.\d+)?)$", &m)
    {
        minutes := m[1]
        seconds := m[2]
        
        ; 計算処理: 分×60 ＋ 秒
        rawTotal := (minutes * 60) + seconds
        totalSeconds := Format("{:.1f}", rawTotal)

        ; クリップボードに結果をセット
        A_Clipboard := totalSeconds
        
        ; 成功したことをツールチップで通知（2秒後に消える）
        ToolTip "変換完了: " totalSeconds
        SetTimer () => ToolTip(), -2000
    }
    else
    {
        ; フォーマットが合わない場合は元のコピー内容のままにするか、警告を出す
        ToolTip "フォーマットが一致しませんでした (MM:SS.ms)"
        SetTimer () => ToolTip(), -2000
    }
    Sleep(80)
    Send("{Enter}")
    Sleep(80)
    Send("{Enter}")

    ; WezTerm をアクティブにして 2rc を入力
    hwnd := WinExist(weztermWin)
    if !hwnd
        return
    ControlSend("{Esc}2rc", , "ahk_id " hwnd)

}

F10::
{

    targetExe := "ahk_exe mpc-be64.exe"  ; 64bit版
    ; targetExe := "ahk_exe mpc-be.exe"    ; 32bit版
    weztermWin := "ahk_class org.wezfurlong.wezterm"

    ; MPC-BEが起動していなければ何もしない
    hwndMpc := WinExist(targetExe)
    if !hwndMpc
        return

    WinActivate("ahk_id " hwndMpc)
    if !WinWaitActive("ahk_id " hwndMpc, , 4)
    {
        ToolTip "MPC-BEをアクティブにできませんでした"
        SetTimer () => ToolTip(), -2000
        return
    }

    BackupClip := A_Clipboard ; 現在のクリップボードを保存（念のため）
    A_Clipboard := ""         ; クリップボードをクリア

    Send("^g")
    Sleep(150)
    Send("^a")
    Sleep(80)
    Send("^c")

    if !ClipWait(2)           ; コピー失敗時は終了
    {
        MsgBox "テキストのコピーに失敗しました。"
        return
    }

    text := Trim(A_Clipboard) ; 余計な空白を除去

    ; 正規表現で「数字:数字.数字」のパターンを取得
    ; m[1] = 分, m[2] = 秒(小数点含む)
    if RegExMatch(text, "^(\d+):(\d+(\.\d+)?)$", &m)
    {
        minutes := m[1]
        seconds := m[2]
        
        ; 計算処理: 分×60 ＋ 秒
        rawTotal := (minutes * 60) + seconds
        totalSeconds := Format("{:.1f}", rawTotal)

        ; クリップボードに結果をセット
        A_Clipboard := totalSeconds
        
        ; 成功したことをツールチップで通知（2秒後に消える）
        ToolTip "変換完了: " totalSeconds
        SetTimer () => ToolTip(), -2000
    }
    else
    {
        ; フォーマットが合わない場合は元のコピー内容のままにするか、警告を出す
        ToolTip "フォーマットが一致しませんでした (MM:SS.ms)"
        SetTimer () => ToolTip(), -2000
    }
    Sleep(80)
    Send("{Enter}")
    Sleep(80)
    Send("{Enter}")

    ; WezTerm をアクティブにして 3rc を入力
    hwnd := WinExist(weztermWin)
    if !hwnd
        return
    ControlSend("{Esc}3rc", , "ahk_id " hwnd)

}

F11::
{
    edgeExe := "ahk_exe msedge.exe"
    weztermWin := "ahk_class org.wezfurlong.wezterm"

    if !WinExist(edgeExe)
        return
    WinActivate(edgeExe)
    if !WinWaitActive(edgeExe, , 4)
        return

    Send("{Esc}")
    Sleep(80)
    Send("{Shift down}l{Shift up}")  ; Shiftのスタックを防止
    KeyWait("Shift")  ; Shiftが完全に離されるまで待機
    Sleep(50)

    ; アルファベット2文字 or アルファベット1文字+Enter を待機（入力はEdgeに送信される）
    ih := InputHook("L2 V")  ; 最大2文字で終了、"V"で入力を可視（Edgeに送信）
    ih.KeyOpt("{Enter}", "E")  ; Enterキーで終了
    ih.KeyOpt("{Escape}", "E")  ; Escapeでキャンセル
    ih.Start()
    ih.Wait()

    ; Escapeでキャンセルされた場合は終了
    if (ih.EndKey = "Escape")
        return

    ; 入力が空または条件を満たさない場合は終了
    if (ih.Input = "" || !RegExMatch(ih.Input, "^[a-zA-Z]{1,2}$"))
        return

    Sleep(300)
    SendInput("ct")  ; Vimiumでクリップボードにコピー（素早く送信）
    Sleep(300)
    Send("{Esc}")
    Sleep(80)

    hwnd := WinExist(weztermWin)
    if !hwnd
        return
    ControlSend("{Esc}4rq", , "ahk_id " hwnd)
}
