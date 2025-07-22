global toggle := false
global startTime := 0
global interval := 10000

SetWindowIcon(hwnd, iconPath) {
    hIcon := DllCall("LoadImage", "Ptr", 0, "Str", iconPath, "UInt", 1, "Int", 0, "Int", 0, "UInt", 0x10, "Ptr")
    SendMessage(0x80, 1, hIcon,, "ahk_id " hwnd)
    SendMessage(0x80, 0, hIcon,, "ahk_id " hwnd)
}


MainGui := Gui("+Resize")
MainGui.Title := "ClickBot"
MainGui.SetFont("s10", "Segoe UI")



MainGui.Add("Text", , "Status:")
statusLabel := MainGui.Add("Text", , "Paused")

MainGui.Add("Text", , "Click Interval (ms):")
intervalBox := MainGui.Add("Edit", "w100", "10000")

MainGui.Add("Text", , "Time Elapsed:")
elapsedLabel := MainGui.Add("Text", , "0s")

startBtn := MainGui.Add("Button", "w150", "Start")
stopBtn := MainGui.Add("Button", "w150", "Stop")
exitBtn := MainGui.Add("Button", "w150", "Exit")

startBtn.OnEvent("Click", StartClickBot)
stopBtn.OnEvent("Click", StopClickBot)
exitBtn.OnEvent("Click", (*) => ExitApp)

MainGui.Show("w500 h250")
SetWindowIcon(MainGui.Hwnd, "clickbot.ico")
MainGui.Add("Picture", "x100 y10 w400 h230", "clickbot.png")

ClickLoop() {
    global toggle
    if toggle {
        Click
    }
}

StartClickBot(*) {
    global toggle, interval, startTime
    toggle := true
    statusLabel.Value := "Running"
    ToolTip("ClickBot Active")

    input := intervalBox.Text
    if RegExMatch(input, "^\d+$") {
        interval := input
    } else {
        MsgBox("PUT A NUMBER, OK?????")
        return
    }

    startTime := A_TickCount
    SetTimer(UpdateElapsed, 1000)
    SetTimer(ClickLoop, interval)
}

StopClickBot(*) {
    global toggle
    toggle := false
    statusLabel.Value := "Paused"
    ToolTip("ClickBot Paused")
    SetTimer(ClickLoop, 0)
    SetTimer(UpdateElapsed, 0)
    elapsedLabel.Value := "0s"
    Sleep(500)
    ToolTip()
}

UpdateElapsed() {
    global startTime, elapsedLabel
    elapsed := (A_TickCount - startTime) // 1000
    elapsedLabel.Value := elapsed "s"
}
