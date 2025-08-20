global toggle := false
global startTime := 0
global interval := 10000
global unit := "ms"
global selectedKey := "LeftClick"
global minInterval := 10
global maxInterval := 20
global nextClickTime := 0

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
MainGui.Title := "Autoclicker"
MainGui.SetFont("s10", "Segoe UI")
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

startBtn.OnEvent("Click", (*) => StartAutoclicker())
stopBtn.OnEvent("Click", (*) => StopAutoclicker())
exitBtn.OnEvent("Click", (*) => ExitApp())

MainGui.Show("w500 h300")
SetTimer(() => SetWindowIcon(MainGui.Hwnd, A_ScriptDir "\Autoclicker.ico"), -100)

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
        MsgBox("incorrect format: " txt)
        ctrl.Text := ""
    }
}

StartAutoclicker() {
    global
    intervalMode := sameRadio.Value ? 1 : 2
    unit := intervalUnit.Text
    selectedKey := keyCombo.Text

    if (intervalMode = 1) {
        ToolTip("Same mode")
        intervalInput := intervalBox.Text
        if !RegExMatch(intervalInput, "^\d+$") {
            MsgBox("invalid interval value.")
            return
        }
        minInterval := maxInterval := intervalInput
    } else if (intervalMode = 2) {
        ToolTip("Random mode")
        minInput := minIntervalBox.Text
        maxInput := maxIntervalBox.Text
        if !RegExMatch(minInput, "^\d+$") || !RegExMatch(maxInput, "^\d+$") {
            MsgBox("invalid min or max interval value.")
            return
        }
        minInterval := minInput, maxInterval := maxInput
        if (minInterval > maxInterval) {
            MsgBox("min interval needs to be less than or equal to max interval.")
            return
        }
    }

    if unit = "seconds"
        minInterval *= 1000, maxInterval *= 1000
    else if unit = "minutes"
        minInterval *= 60000, maxInterval *= 60000

    startTime := A_TickCount
    toggle := true
    statusLabel.Value := "Running"
    SetTimer(UpdateElapsed, 100)
    nextClickTime := A_TickCount + Random(minInterval, maxInterval)
    SetTimer(ClickLoop, 10)
}

ClickLoop() {
    global
    if !toggle
        return
    if (A_TickCount < nextClickTime)
        return
    selectedKey := keyCombo.Text
    if selectedKey = "LeftClick"
        Click()
    else if selectedKey = "RightClick"
        Click("Right")
    else
        Send("{" selectedKey "}")
    nextClickTime := A_TickCount + Random(minInterval, maxInterval)
}

StopAutoclicker() {
    global
    toggle := false
    statusLabel.Value := "Paused"
    ToolTip("Autoclicker paused")
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

