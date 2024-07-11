; Surface Pro X AutoHotkey
; Original Project: https://github.com/jonathanyip/Surface-Pro-3-AutoHotkey
;
; Last Updated: July 11, 2024

; Set up our pen constants
global PEN_HOVERING := 0x04          ; Pen is hovering above screen.
global PEN_ERASER_HOVERING := 0x0C   ; eraser button is pressed.
global PEN_BTN_HOVERING := 0x24      ; button is pressed.
global PEN_TOUCHING := 0x05          ; Pen is touching screen.
global PEN_ERASER_TOUCHING := 0x1C   ; eraser button is pressed, pen is touching screen.
global PEN_BTN_TOUCHING := 0x25      ; button is pressed, pen is touching screen.
global PEN_NOT_HOVERING := 0x0       ; Pen is moved away from screen.

; Respond to the pen inputs
; Fill this section with your favorite AutoHotkey scripts!
; lastInput is the last input that was detected before a state change.
PenCallback(input, lastInput) {
    ; is the user selecting a region?
    static selecting := false
    ; has the user touched the screen while selecting?
    static has_selected := false

    if (WinActive("ahk_exe paintdotnet.exe")) {
        if (!selecting) && (input = PEN_BTN_HOVERING) {
            ; want to select something (and was not previously selecting)
            ; note: first we select the pencil to make sure that it was not in some "select-related" tool
            Send, pss
            selecting := true
            has_selected := false
        }

        if (selecting) && (input = PEN_BTN_TOUCHING) {
            has_selected := true
        }

        ; there's a bug with PEN_HOVERING when coming from PEN_NOT_HOVERING
        if (selecting) && (lastInput != PEN_NOT_HOVERING && input = PEN_HOVERING) {
            if (has_selected) {
                ; previously selecting and done; cut&paste to modify
                Send, {LControl Down}xv{LControl Up}
            }
            else {
                ; nothing was selected (back to the brush)
                Send, b
            }
            selecting := false
        }

        if (input = PEN_ERASER_HOVERING) {
            ; activate eraser
            Send, e
        }

        if (lastInput = PEN_ERASER_HOVERING || lastInput = PEN_ERASER_TOUCHING) && (input != PEN_ERASER_HOVERING && input != PEN_ERASER_TOUCHING) {
            ; no longer using the eraser - deactivate (back to the brush)
            Send, b
        }
    }
}

; Include AHKHID
#include AHKHID.ahk

; Set up other constants
; USAGE_PAGE and USAGE might change on different devices...
WM_INPUT := 0xFF
USAGE_PAGE := 13
USAGE := 2

; Set up AHKHID constants
AHKHID_UseConstants()

; Register the pen
AHKHID_AddRegister(1)
AHKHID_AddRegister(USAGE_PAGE, USAGE, A_ScriptHwnd, RIDEV_INPUTSINK)
AHKHID_Register()

; Intercept WM_INPUT
OnMessage(WM_INPUT, "InputMsg")

; Callback for WM_INPUT
; Isolates the bits responsible for the pen states from the raw data.
InputMsg(wParam, lParam) {
    Local type, inputInfo, inputData, raw, proc
    Critical

    type := AHKHID_GetInputInfo(lParam, II_DEVTYPE)

    if (type = RIM_TYPEHID) {
        inputInfo := AHKHID_GetInputInfo(lParam, II_DEVHANDLE)
        inputData := AHKHID_GetInputData(lParam, uData)

        raw := NumGet(uData, 0, "UInt")
        proc := (raw >> 24) 

        LimitPenCallback(proc)
    }
}

; Limits the callback only to when the pen changes state.
; This stop the repetitive firing that goes on when the pen moves around.
LimitPenCallback(input) {
    static lastInput := PEN_NOT_HOVERING

    if (input != lastInput) {
        PenCallback(input, lastInput)
        lastInput := input
    }
}