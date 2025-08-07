global toggle := false
global startTime := 0
global interval := 10000
global unit := "ms"
global selectedKey := "LeftClick"

;Icon

SetWindowIcon(hwnd, iconPath) {
    hIcon := DllCall("LoadImage", "Ptr", 0, "Str", iconPath, "UInt", 1, "Int", 0, "Int", 0, "UInt", 0x10, "Ptr")
    if !hwnd || !hIcon
        return
    SendMessage(0x80, 1, hIcon,, "ahk_id " hwnd)
    SendMessage(0x80, 0, hIcon,, "ahk_id " hwnd)
}

;Settings

MainGui := Gui("+MinSize500x500 +MaxSize500x500")
MainGui.Title := "AutoClicker"
MainGui.SetFont("s10", "Segoe UI")

; THE ONE WE'RE WORKING ON

MainGui.Add("GroupBox", "x20 y80 w220 h60", "Interval Mode")
sameRadio := MainGui.Add("Radio", "x40 y100 vintervalMode Checked", "Same")
randomRadio := MainGui.Add("Radio", "x120 y100", "Random")

MainGui.Add("GroupBox", "x20 y20 w460 h60", "Session Info")
MainGui.Add("Text", "x40 y40", "Status:")
statusLabel := MainGui.Add("Text", "x100 y40 w120", "Paused")
MainGui.Add("Text", "x240 y40", "Elapsed:")
elapsedLabel := MainGui.Add("Text", "x310 y40 w100", "0s")

MainGui.Add("GroupBox", "x20 y150 w220 h80", "Click Interval")
amountLabel := MainGui.Add("Text", "x40 y170", "Amount:")
intervalBox := MainGui.Add("Edit", "x120 y170 w60", "10")
minLabel := MainGui.Add("Text", "x40 y170", "Min:")
minIntervalBox := MainGui.Add("Edit", "x120 y170 w60", "10")
maxLabel := MainGui.Add("Text", "x40 y200", "Max:")
maxIntervalBox := MainGui.Add("Edit", "x120 y200 w60", "20")

MainGui.Add("GroupBox", "x260 y150 w220 h80", "Units")

MainGui.Add("Text", "x280 y170", "Units:")
intervalUnit := MainGui.Add("DropDownList", "x360 y170 w100", ["milliseconds", "seconds", "minutes"])
intervalUnit.Value := 2

MainGui.Add("GroupBox", "x260 y80 w220 h60", "Click Action")
MainGui.Add("Text", "x280 y100", "Key/Button:")
keyCombo := MainGui.Add("ComboBox", "x360 y100 w100", ["LeftClick", "RightClick", "Enter", "Space", "Tab", "F1", "F2"])
keyCombo.OnEvent("LoseFocus", ValidateDropdownInput)


MainGui.Add("GroupBox", "x20 y230 w460 h70", "Controls")
startBtn := MainGui.Add("Button", "x60 y250 w100", "Start")
stopBtn := MainGui.Add("Button", "x190 y250 w100", "Stop")
exitBtn := MainGui.Add("Button", "x320 y250 w100", "Exit")

startBtn.OnEvent("Click", (*) => StartAutoClicker())
stopBtn.OnEvent("Click", (*) => StopAutoClicker())
exitBtn.OnEvent("Click", (*) => ExitApp())

MainGui.Show("w500 h300")
SetTimer(() => SetWindowIcon(MainGui.Hwnd, A_ScriptDir "\AutoClicker.ico"), -100)

minLabel.Visible := false
minIntervalBox.Visible := false
maxLabel.Visible := false
maxIntervalBox.Visible := false

;Functions

sameRadio.OnEvent("Click", (*) => (
    amountLabel.Visible := true,
    intervalBox.Visible := true,
    minLabel.Visible := false,
    minIntervalBox.Visible := false,
    maxLabel.Visible := false,
    maxIntervalBox.Visible := false
))
randomRadio.OnEvent("Click", (*) => (
    amountLabel.Visible := false,
    intervalBox.Visible := false,
    minLabel.Visible := true,
    minIntervalBox.Visible := true,
    maxLabel.Visible := true,
    maxIntervalBox.Visible := true
))

ValidateDropdownInput(ctrl, info) {
    txt := ctrl.Text
    try {
        Send("{" txt "}")
    } catch {
        MsgBox("Invalid key/button: " txt)
        ctrl.Text := ""
    }
}

StartAutoClicker() {
    global
    minInput := minIntervalBox.Text
    maxInput := maxIntervalBox.Text
    unit := intervalUnit.Text
    selectedKey := keyCombo.Text

    if !RegExMatch(minInput, "^\d+$") || !RegExMatch(maxInput, "^\d+$") {
        MsgBox("Invalid min/max interval value.")
        return
    }
    minInterval := minInput, maxInterval := maxInput
    if unit = "seconds"
        minInterval *= 1000, maxInterval *= 1000
    else if unit = "minutes"
        minInterval *= 60000, maxInterval *= 60000

    if (minInterval > maxInterval) {
        MsgBox("Min interval must be less than or equal to Max interval.")
        return
    }

    startTime := A_TickCount
    toggle := true
    statusLabel.Value := "Running"
    ToolTip("AutoClicker Active - Key: " . selectedKey . ", Interval: " . minInput . "-" . maxInput . " " . unit)
    SetTimer(UpdateElapsed, 100)
    SetTimer(() => ClickLoop(minInterval, maxInterval), 10)
}

ClickLoop(minInterval, maxInterval) {
    global
    selectedKey := keyCombo.Text
    if toggle {
        if selectedKey = "LeftClick"
            Click()
        else if selectedKey = "RightClick"
            Click("Right")
        else
            Send("{" selectedKey "}")
        ; Schedule next click at a random interval
        nextInterval := Random(minInterval, maxInterval)
        SetTimer(() => ClickLoop(minInterval, maxInterval), -nextInterval)
    }
}

StopAutoClicker() {
    global
    toggle := false
    statusLabel.Value := "Paused"
    ToolTip("AutoClicker Paused")
    SetTimer(ClickLoop, 0)
    SetTimer(UpdateElapsed, 0)
    elapsedLabel.Value := "0s"
    SetTimer(() => ToolTip(), -500)
}

UpdateElapsed() {
    global
    if toggle && startTime > 0 {
        elapsed := (A_TickCount - startTime) // 1000
        elapsedLabel.Value := Format("{}s", elapsed)
    }
}

Esc::ExitApp()

