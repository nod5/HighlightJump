; ---------------------------------------------------------------------
; HighlightJump
; 2020-02-18
; ---------------------------------------------------------------------
; AutoHotkey app to add, remove and jump between highlights in SumatraPDF
; Free software GPLv3
; https://github.com/nod5/HighlightJump

; See Readme.md for setup instructions
; ---------------------------------------------------------------------

#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance force
DetectHiddenWindows, On
SetBatchLines -1
; SetKeyDelay PressDuration 10 seems to make page jumps more reliable
SetKeyDelay, -1, 10
SetWinDelay, -1
SetControlDelay, -1

; highlight colors
; note: keep colorcodes lowercase like SumatraPDF does in .smx
vRed    := "ffcccc"
vGreen  := "95e495"
vBlue   := "0099ff"
vYellow := "ffff60"
JumpColor := vYellow

; initialize quick jump array
aQuickJump := []

Menu, Tray, Tip, HighlightJump
Menu, Tray, Add  ; --------------
Menu, Tray, Add, HighlightJump GitHub Page, open_github_page
Menu, Tray, Add, HighlightJump Readme, open_readme
Menu, Tray, Add, HighlightJump Shortcuts, open_info
Menu, Tray, Add, Reload, reload 
Menu, Tray, Add  ; --------------
Menu, Tray, Default, HighlightJump Shortcuts

; if not compiled then try HighlightJump.ico as trayicon
if !A_IsCompiled
  if FileExist( SubStr(A_ScriptFullPath,1,-4) ".ico")
    Menu, Tray, Icon, % SubStr(A_ScriptFullPath,1,-4) ".ico"



; ini preparation
; note: IniWrite  defaults to ANSI
; note: FileAppend defaults to UTF-8 if script is UTF-8 BOM encoded
; but no issue when our ini only uses ANSI chars

vIniFile := A_ScriptFullPath ".ini"
If !FileExist(vIniFile)
  ; create default ini file
  FileAppend,[Settings]`nRedGreenRG=1`nExperimental=0`nQShortcut=0`nSelectionLabel=0`nCapsLockErase=0, % vIniFile

Hotkey, IfWinActive, ahk_class SUMATRA_PDF_FRAME

; read ini and set color annotation hotkeys
IniRead, vRedGreenRG, % vIniFile, Settings, RedGreenRG, %A_Space%
if vRedGreenRG
{
  ; new mnemonic keys
  Hotkey, r, highlight_red    , on
  Hotkey, g, highlight_green  , on
  Hotkey, y, highlight_yellow , on
  Hotkey, ^+r, filter_red     , on
  Hotkey, ^+g, filter_green   , on
  Hotkey, ^+y, filter_yellow  , on
  Hotkey, ^+d, filter_blue    , on
  ; R above overrides R for "reload" in SumatraPDF. We set Ctrl+R as replacement.
  Hotkey, ^r, RefreshSumatraDocument, on
  ; G above overrides G for "go to" in SumatraPDF. But Ctrl+G for "go to" works.
}
else
{
  ; older keys
  Hotkey, y, highlight_red    , on
  Hotkey, u, highlight_green  , on
  Hotkey, ^+y, filter_red     , on
  Hotkey, ^+u, filter_green   , on
  Hotkey, ^+d, filter_blue    , on
}

; read ini and set Q shortcut alias for Quick Jump menu on/off
; note: Q overrides Q for "quit" in SumatraPDF. But Ctrl+Q for "quit" works.
IniRead, vQShortcut, % vIniFile, Settings, QShortcut, %A_Space%
If vQShortcut
  Hotkey, q, quick_jump_menu, on

; read ini and set use selected text as Quick Jump label on/off
IniRead, vSelectionLabel, % vIniFile, Settings, SelectionLabel, %A_Space%

; read ini and set experimental features on or off
IniRead, vExperimental, % vIniFile, Settings, Experimental, %A_Space%

; If ini has "Experimental=1" 
; Then use experimental SendMessage methods to get document filepath and canvas position
;   advantages: silent, fast, reliable, no "FullPathInTitle = true" requirement
;   note: requires custom SumatraPDF compiled with C++ edits, see GitHub
;   note: currently only works with SumatraPDF 32-bit (not 64-bit)
; Else use slower, non-silent legacy methods
;   note: requires SumatraPDF Settings > Advanced Options > FullPathInTitle = true
;   note: position notification will sometimes be briefly visible in SumatraPDF
global vLegacyMethods := vExperimental ? 0 : 1
; prepare variable used in experimental methods functions
global vFilepathReturn := ""
; note: global above makes the vars super-global
; https://www.autohotkey.com/docs/Functions.htm#SuperGlobal

; read ini and set CapsLock as alias hotkey for E (erase under mouse) on or off
IniRead, vCapsLockErase, % vIniFile, Settings, CapsLockErase, %A_Space%
if vCapsLockErase
  Hotkey, CapsLock, erase_under_mouse, on

Hotkey, IfWinActive, ahk_class SUMATRA_PDF_FRAME


; list of extensions that HighlightJump supports
vSupportedExtensions := "|pdf|djvu|djv|chm|epub|mobi|txt|log|"
; note: used to check if document extension is unsupported
; - if unsupported and single char hotkey     then pass key to SumatraPDF and stop
; - if unsupported and mouse/modifier hotkey  then stop

; list of extensions that require .epub pt position bug/issue workaround
vEpubExtensions      := "|chm|epub|mobi|txt|log|"

Return


open_info:
vShortcuts =
  (LTrim
  ▄▄▄▄▄▄▄      HighlightJump      ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
  
  version 2020-02-18    https://github.com/nod5/HighlightJump

  ▄▄▄▄▄▄▄  Keyboard Shortcuts  ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

  A or Y = Highlight selection Yellow
  R / G = Highlight selection Red / Green
  D = Make a Blue square dot at the mouse pointer ("D for dot")
  A (hold) = cycle highlight color yellow -> red -> green -> cancel
  
  E (hold) = Remove all highlighting mouse moves over ("E for erase")
  Ctrl + Delete = Remove all highlighting on active page
  Win + A = Hide/Show all highlighting

  Ctrl + PgUp/PgDn = Jump to next/prev page with highlight
  Ctrl + Home/End = Jump to first/last page with highlight

  Shift + Ctrl + Y/R/G/D = select jump filter color
  Shift + Ctrl + A = cycle jump filter colors
  Shift + Ctrl + PgUp/PgDn = Jump to next/prev filter color page
  Shift + Ctrl + Home/End = Jump to first/last filter color page

  ▄▄▄▄▄▄▄  Quick Jump Keys  ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

  1 2 3 4 = (hold) store current page, (tap) jump to stored page
  5 = show stored page list

  ▄▄▄▄▄▄▄  Mouse Shortcuts  ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

  Lbutton + Rbutton = Highlight selected text yellow
  Lbutton + Rbutton (hold) = Cycle highlight color

  Rbutton + Mbutton = Make a blue square dot at the mouse pointer
  Rbutton + Lbutton (hold) = Remove all highlighting mouse moves over
  Rbutton + Scroll Up/Down = Jump to next/prev page with highlight

  Ctrl + Lbutton (click drag) = draw rectangle, then A/Y/R/G to highlight
  )
  MsgBox, % vShortcuts
Return

open_github_page:
  Run https://github.com/nod5/HighlightJump
Return

open_readme:
  If FileExist(A_ScriptDir "\readme.html")
    Run % A_ScriptDir "\readme.html"
Return

reload: 
  Reload
Return


; ------------------------------------------
; ---- SUMATRAPDF .SMX HIGHLIGHT FORMAT ----
; ------------------------------------------
; ...
;
; [highlight]
; page = 15
; rect = 105 154 151 12
; color = #ffff60
; opacity = 0.8
;
; [...
; ------------------------------------------
; Notes:
; - rect values are: X Y W H where 0 0 is canvas upper left corner
; - Unit is "pt", see position notification ("m" shortcut) in SumatraPDF.
; - Highlights from text selection have whole number values.
; - Highlights from drawn rectangle (Ctrl + Lbutton) have decimal values.
;   Example: rect = 91.9728 228.302 186.451 122.296
; - Edge case: X Y value can be negative e.g. -0.42761 
;   if Ctrl+A (select all on page) + A (highlight)
; ------------------------------------------


#IfWinActive, ahk_class SUMATRA_PDF_FRAME


; -----------------------------------------
; quick jump keys
; -----------------------------------------
; 1 2 3 4: quick jump keys
; hold      = store current page
; tap       = jump to stored page
; tap again = jump back to previous page
; store with filepath as level1 key and retain until script closes

1::
2::
3::
4::
  ; note: must use A_ThisLabel here because also called by menu
  If PassthroughIfNotCanvasFocus(A_ThisLabel)
    Return
  GetFile(vFile) ; ByRef
  If PassthroughIfNotSupportedExt(vFile, vSupportedExtensions, A_ThisLabel)
    Return
  
  ToolTip
  vStorePage := 0
  ; if key down then start timer to detect press duration
  if GetKeyState(A_ThisLabel, "P")
  {
    t1 := A_TickCount
    SetTimer, quick_jump_key_duration, 10
    KeyWait, % A_ThisLabel, T0.4
    SetTimer, quick_jump_key_duration, off
  }

  If !GetPageLen(vPage, vLen) ; ByRef
    Return
  
  If vStorePage
  {
    ; case: key hold

    vJumpLabel := ""
    ; get and store current page
    If !vLegacyMethods
    {
      ; if only one page visible or only one nearly fully visible then use that
      ; else let user click to select a page
      vPage := SmartPageSelect("store quick jump")
    }
    if !vPage
      return

    If vSelectionLabel
    {
      ; use any selection as label for quick jump menu
      ; todo: verify that selection is on vPage
      SumatraCopySelection(vJumpLabel)  ; ByRef
      ; max 30 characters, lowercase
      vJumpLabel := SubStr(vJumpLabel, 1, 30)
      vJumpLabel := Format("{:L}", vJumpLabel)
    }
    
    ToolTip stored
    ; note: concat "" to treat as string, otherwise error if leading zeros
    aQuickJump["" vFile, "" A_ThisLabel] := "" vPage
    aQuickJump["" vFile, "" A_ThisLabel "label"] := "" vJumpLabel
    sleep 800
  }
  Else
  {
    ; case: key tap
    ; if already at stored page and last hotkey was this hotkey
    ; then jump to previous page via SumatraPDF shortcut
    If (aQuickJump["" vFile, "" A_ThisLabel] = vPage) and (A_ThisLabel = A_PriorHotkey)
      Send !{Left}
    ; else jump to stored page
    Else If vNewPage := aQuickJump["" vFile, "" A_ThisLabel]
      SumatraGotoPageDDE(vFile, vNewPage)
  }
  ToolTip
Return


quick_jump_key_duration:
  vDuration := A_TickCount - t1
  if (vDuration < 400)
    Return
  vStorePage := 1
  SetTimer, quick_jump_key_duration, off
  ;Send {%A_ThisHotkey% Up}
Return


; menu overview of quick jump stored pages
5::
quick_jump_menu:
  If PassthroughIfNotCanvasFocus(A_ThisHotkey)
    Return
  GetFile(vFile) ; ByRef
  If PassthroughIfNotSupportedExt(vFile, vSupportedExtensions, A_ThisHotkey)
    Return
  If !vFile
    Return
  ; clear any old menu
  Menu, QuickJumpMenu, Add, menu_no_action
  Menu, QuickJumpMenu, Delete
  vOneOrMoreStored := 0
  ; make new menu if stored pages
  Loop, 4
    If aQuickJump["" vFile, "" A_Index]
    {
      vJumpLabel := aQuickJump["" vFile, "" A_Index "label"]
      vJumpLabel := vJumpLabel ? "  [" vJumpLabel "]" : ""
      vMenuText  := A_Index ": page " aQuickJump["" vFile, "" A_Index] vJumpLabel
      Menu, QuickJumpMenu, Add, % vMenuText, % A_Index
      vOneOrMoreStored := 1
    }
  if vOneOrMoreStored
    Menu, QuickJumpMenu, Show
Return

; temp label needed to clear any old menu
menu_no_action:
Return

; -----------------------------------------
; end quick jump keys
; -----------------------------------------




; Win + A: Hide/Show all highlighting
; note: state "off" also disables page jumps, erase under mouse, and delete all on page
;       but shortcuts to add highlight still work and will toggle highlights on
#a::
  If !CanvasFocused()
    Return
  GetFile(vFile) ; ByRef
  If !SupportedExtension(vFile, vSupportedExtensions)
    Return
  if !vFile
    Return
  
  Tooltip, % FileExist(vFile ".smx") ? "highlights off" : "highlights on"
  ToggleHighlightsOnOff(vFile)
  SetTimer, tooltip_timeout, -600
Return

tooltip_timeout:
  ToolTip
Return


; Ctrl + Delete: Remove all highlighting on active page
^Del::
  If !CanvasFocused()
    Return
  GetFile(vFile) ; ByRef
  If !SupportedExtension(vFile, vSupportedExtensions)
    Return
  If !vFile or !GetSmx(vSmx, vFile) or !GetPageLen(vPage, vLen) ; ByRef vSmx ; ByRef
    Return

  If !vLegacyMethods
    vPage := SmartPageSelect("erase highlights")

  If !vPage
    return

  ; remove each [highlight] that contains "page = <active page number>"
  ; note: RegExReplace defaults to replacing each match
  vOldSmx := vSmx
  vSmx := RegExReplace(vSmx, "Us)\[highlight]\Rpage = " vPage "\R.*opacity.*(?:\R\R|\R)", "")
  if (vSmx != vOldSmx)
    SaveSmx(vFile, vSmx)
Return


; Remove all highlights that the mouse moves over while key/button is held
Rbutton & Lbutton::
  Send {Lbutton up}
erase_under_mouse:
e::
  If PassthroughIfNotCanvasFocus(A_ThisHotkey)
    Return
  GetFile(vFile) ; ByRef
  If PassthroughIfNotSupportedExt(vFile, vSupportedExtensions, A_ThisHotkey)
    Return
  If !vFile or !GetSmx(vSmx, vFile) or !GetPageLen(vPage, vLen) ; ByRef vSmx ; ByRef
    Return

  Sleep 50

  If vLegacyMethods
  {  
    ; prepare SumatraPDF UI notification for document pt position reading
    If !( PrepareForCanvasPosCheck() )
      Return
  }
  Else
    ; change system cursor to cross during highlight removal
    SetSystemCursor("CROSS")

  ; is document epub or pdf?
  vIsEpub := RequiresEpubFix(vFile, vEpubExtensions)
  
  ; timer to delete all highlights under mouse until hotkey release
  vOldSmx := vSmx
  SetTimer, remove_highlight_under_mouse, 10
  
  ; wait for held hotkey release
  If (A_ThisHotkey = "Rbutton & Lbutton")
  {
    KeyWait, Lbutton
    KeyWait, Rbutton
  }
  Else
    KeyWait, %A_ThisHotkey%
  
  SetTimer, remove_highlight_under_mouse, Off
  
  If vLegacyMethods
    ; close popup to change SumatraPDF mouse pointer back from cross to arrow
    Send {Esc}
  Else
    ; restore default system cursors
    SetSystemCursor("")
  
  ; save to .smx if any highlights were removed
  if (vSmx != vOldSmx)
    SaveSmx(vFile, vSmx)
Return

remove_highlight_under_mouse:

  If vLegacyMethods
    ; Read UI notification to get mouse position in SumatraPDF canvas in pt units (one decimal)
    SumatraGetCanvasPosFromNotification(mx, my) ; ByRef
  Else
  {
    ; SendMessage method to get mouse position in SumatraPDF canvas in pt units (no decimals)
    SumatraGetCanvasPos(mx, my) ; ByRef
    ; SendMessage method to get page num at point under mouse in SumatraPDF canvas
    SumatraGetPageAtPoint(vPage) ; Byref
  }

  if !mx or !my or !vPage
    Return

  ; SumatraPDF .epub pt position bug/issue:
  ; In .epub with "UseFixedPageUI = true" the "m" shortcut popup pt x y data is incorrect
  ; To get correct pt values multiply with 1.346364632809646 (4/3)
  ; For details see https://github.com/sumatrapdfreader/sumatrapdf/issues/884
  ; Note: this only ensures that highlights show at the same position as when they were created.
  ; But if the user changes the Advanced Settings default .epub Font/FontSize values
  ;   EbookUI [
  ;   FontName = Georgia
  ;   FontSize = 12.5
  ; then the text will reflow and no longer line up with the highlights.
  ; There is no workaround for that at the moment.
  ; Note: same issue for filetypes |epub|mobi|chm|txt|log| and maybe more
  vMultiplier := vIsEpub ? 1.346364632809646 : 1
  ; note: rounding always needed if vLegacyMethods because then mx/my has decimal
  mx := round(mx * vMultiplier)
  my := round(my * vMultiplier)

  ; split smx to array of highlight items
  aHighlights := StrSplit(vSmx, "[highlight]")

  For Key, Value in aHighlights
  {
    ; check page
    If !InStr(Value, "page = " vPage "`r")
      Continue
    ; check if mouse pointer within highlight rectangle
    ; note: check for sign on first two values (see edge case note elsewhere)
    RegExMatch(Value, "rect = ([-0-9\.]+) ([-0-9\.]+) ([0-9\.]+) ([0-9\.]+)", vRect)
    If ( mx >= round(vRect1) and mx <= round(vRect1 + vRect3) and my >= round(vRect2) and my <= round(vRect2 + vRect4) )
      ; remove highlight
      vSmx := RegExReplace(vSmx, "Us)\[highlight]\Rpage = " vPage "\Rrect = " vRect1 " " vRect2 " " vRect3 " " vRect4 ".*opacity.*(?:\R\R|\R)", "")
  }
Return


; Note: Required to prevent R&L combo hotkey from blocking single Rbutton clicks
Rbutton::
  If !GetKeyState("Lbutton", "P") 
    Send {Rbutton}
return
; Note: The above prevention method is better than (~Rbutton:: <linebreak> Return)
; which unwantedly shows SumatraPDF's "hand" cursor icon during R+LButton hold




; jump to first/last page with highlight
^Home::
^End::
; jump to first/last page with (color filter) highlight
+^Home::
+^End::
  If !CanvasFocused()
    Return
  GetFile(vFile) ; ByRef
  If !SupportedExtension(vFile, vSupportedExtensions)
    Return
  If !vFile or !GetSmx(vSmx, vFile) or !GetPageLen(vPage, vLen) ; ByRef vSmx ; ByRef
    Return

  ; split smx to array of highlights
  aHighlights := StrSplit(vSmx, "[highlight]")

  ; trim text before first highlight section
  aHighlights.Remove(1,1)

  ; subset array of filter color highlights
  If InStr(A_ThisLabel, "+")
  {
    aColHighlights := Object() 
    For Key, Value in aHighlights
    If InStr(Value, JumpColor)
      aColHighlights.insert(Value)
  }
  
  ; regular or filter jump?
  aJumpArray := InStr(A_ThisLabel, "+") ? aColHighlights : aHighlights

  vMax := 0
  vMin := 99999

  For Key, Value in aJumpArray
  {
    RegExMatch(Value, "U)page = (\d+)\R",vPage)
    If (vPage1 > vLen)
      continue
    If (vPage1 > vMax)
      vMax := vPage1
    If (vPage1 < vMin)
      vMin := vPage1
  }

  ; home or end jump?
  vNewPage := InStr(A_ThisLabel, "Home") ? vMin : vMax

  If (vNewPage = 0 or vNewPage = 99999)
    Return
  ; SendMessage DDE string method: go to pdf page in active SumatraPDF window
  SumatraGotoPageDDE(vFile, vNewPage)
Return


; set jump filter color
filter_yellow:
filter_red:
filter_green:
filter_blue:

Switch StrReplace(A_ThisLabel, "filter_", "")
{
  Case "yellow" : FlashColorSquare(100, JumpColor := vYellow )
  Case "red"    : FlashColorSquare(100, JumpColor := vRed    )
  Case "green"  : FlashColorSquare(100, JumpColor := vGreen  )
  Case "blue"   : FlashColorSquare(100, JumpColor := vBlue   )
} 
Return


; cycle jump filter color
+^a::
  If !CanvasFocused()
    Return
  Switch JumpColor
  {
    Case vRed     : JumpColor := vGreen
    Case vGreen   : JumpColor := vBlue
    Case vBlue    : JumpColor := vYellow
    Case vYellow  : JumpColor := vRed
  }
  ; show new color in rectangle on screen
  FlashColorSquare(100, JumpColor)
Return




; jump to next/prev page with highlight
Rbutton & WheelDown::
Rbutton & WheelUp::
^PgDn::
^PgUp::
; jump to next/prev page with (color filter) highlight
+^PgDn::
+^PgUp::
  If !CanvasFocused()
    Return
  GetFile(vFile) ; ByRef
  If !SupportedExtension(vFile, vSupportedExtensions)
    Return
  If !vFile or !GetSmx(vSmx, vFile) or !GetPageLen(vPage, vLen) ; ByRef vSmx ; ByRef
    Return

  ; Max number of pages to loop through when looking for nearest jump point
  vLoopLen := InStr(A_ThisLabel, "Up") ? vPage : vLen - vPage  
  ; example: If we are at page 70 in a 100 page document
  ;         then if prev page jump the value is 70
  ;              if next page jump the value is 30

  ; regular or filter jump?
  colorFilter := InStr(A_ThisLabel, "+") ? ".*\Rcolor = #" JumpColor : ""

  ; loop through pages looking for nearest jump point
  vNewPage := vPage
  Loop, % vLoopLen
  {
    ; step one page back/forward
    vNewPage := InStr(A_ThisLabel, "Up") ? vPage - A_Index : vPage + A_Index

    ; match page (and color)
    If !colorFilter
    {
      ; note: InStr is faster than RegEx
      If InStr(vSmx, "page = " vNewPage "`r")
      {
        SumatraGotoPageDDE(vFile, vNewPage)
        Return
      }
    }
    Else If RegExMatch(vSmx, "page = " vNewPage "\R" colorFilter)
    {
      SumatraGotoPageDDE(vFile, vNewPage)
      Return
    }
  }
Return




; Make blue rectangle highlight at mouse pointer
Rbutton & Mbutton::
d::
  If PassthroughIfNotCanvasFocus(A_ThisHotkey)
    Return
  GetFile(vFile) ; ByRef
  If PassthroughIfNotSupportedExt(vFile, vSupportedExtensions, A_ThisHotkey)
    Return

  If !vFile or !GetPageLen(vPage, vLen) ; ByRef
    Return

  ToggleHighlightsOnOff(vFile, "on")
  
  If vLegacyMethods
  {
    ; prepare SumatraPDF UI notification for document pt position reading
    If !( PrepareForCanvasPosCheck() )
      Return
    ; Read UI notification to get mouse position in SumatraPDF canvas in pt units (one decimal)
    SumatraGetCanvasPosFromNotification(vPosX, vPosY) ; ByRef
    ; close popup to change SumatraPDF mouse pointer back from crosshair to arrow
    Send {Esc}
  }
  Else
  {
    ; SendMessage method to get mouse position in SumatraPDF canvas in pt units (no decimal)
    SumatraGetCanvasPos(vPosX, vPosY) ; ByRef
    ; SendMessage method to get page num at point under mouse in SumatraPDF canvas
    SumatraGetPageAtPoint(vPage) ; Byref
  }

  if !vPosX or !vPosY or !vPage
    Return

  ; workaround for SumatraPDF .epub pt position bug/issue (see earlier code comments)
  vIsEpub := RequiresEpubFix(vFile, vEpubExtensions)
    
  vMultiplier := vIsEpub ? 1.346364632809646 : 1
  ; note: rounding always needed if vLegacyMethods because then mx/my has decimal
  vPosX := round(vPosX * vMultiplier)
  vPosY := round(vPosY * vMultiplier)

  ; centre blue rect at mouse pointer, bounded by document edge
  vPosX := vPosX-4 < 1 ? 1 : vPosX-4
  vPosY := vPosY-4 < 1 ? 1 : vPosY-4

  ; prepare blue rectangle
  vRectHighlight = 
  (LTrim

  [highlight]
  page = %vPage%
  rect = %vPosX% %vPosY% 9 9
  color = #%vBlue%
  opacity = 0.8

  )  

  If !FileExist(vFile ".smx")
    SmxCreateWithHeader(vFile)

  FileAppend, % vRectHighlight, % vFile ".smx", UTF-8-RAW
  RefreshSumatraDocument()
Return




; highlight selected text and save to .smx

a::  ; yellow, or longpress to cycle yellow -> red -> green -> cancel
highlight_yellow:
highlight_red:
highlight_green:
Lbutton & Rbutton::  ; yellow, or longpress to cycle
  If PassthroughIfNotCanvasFocus(A_ThisHotkey)
    Return
  GetFile(vFile) ; ByRef
  If PassthroughIfNotSupportedExt(vFile, vSupportedExtensions, A_ThisHotkey)
    Return
  If !vFile
    Return

  vFlashColor := ""

  If (A_ThisLabel = "a") or (A_ThisLabel = "Lbutton & Rbutton")
  {
    ; start timer to set highlight color based on press duration
    ; cycles through values yellow -> red -> green
    
    t1 := A_TickCount
    SetTimer, cycle_highlight_color_mode, 10
    
    vWaitKey := (A_ThisLabel = "a") ? "a" : "Rbutton"
      KeyWait, % vWaitKey

    SetTimer, cycle_highlight_color_mode, off
    Gui, Destroy
    
    If (A_ThisLabel = "Lbutton & Rbutton")
      Send {Rbutton up}{Lbutton up}
    
    If (vFlashColor = "cancel")
      return
  }

  ToggleHighlightsOnOff(vFile, "on")

  ; set color based on which key (A/Y/U) or longpress A flashcolor
  Switch A_ThisLabel
  {
    Case "highlight_yellow" : vHighlightColor := vYellow
    Case "highlight_red"    : vHighlightColor := vRed
    Case "highlight_green"  : vHighlightColor := vGreen
  } 
  
  If vFlashColor
    vHighlightColor := vFlashColor

  ; If non-yellow highlight action then first get .smx length before new annotation
  If (vHighlightColor != vYellow)
  {
    GetSmx(vSmx, vFile) ; ByRef vSmx
    ; note: sets length 0 if no smx file yet exists
    vSmxLen := StrLen(vSmx)
  }
  
  ; Make annotation (yellow)
  Send a
  
  ; Save annotation to .smx (still yellow)  
  SaveAnnotationToSmx()
  
  ; If non-yellow highlight action then change new annotation color in .smx file
  If (vHighlightColor != vYellow)
  {
    ; Wait for SumatraPDF to finish writing .smx
    ; Method: Try renaming file to itself, returns ErrorLevel true while .smx is written
    ; ---------------------------------------------
    ; Background on SumatraPDF C++ source
    ; ---------------------------------------------
    ; - In SumatraPDF.cpp function SaveFileModifications() calls FileWrite()
    ;   and in FileUtil.cpp FileWrite() calls CreateFileW() with member "FILE_SHARE_READ"
    ; - https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilew
    ;   says other processes can delete or move the file only if "FILE_SHARE_DELETE" is used
    ; - Therefore our FileMove attempts should error until SumatraPDF .smx write is finished
    ; ---------------------------------------------

    Loop
    {
      FileMove, % vFile ".smx" , % vFile ".smx"
      if !ErrorLevel
        break
      sleep 20
      ; cancel after trying for 4 seconds, to avoid hanging if some error
      If (A_Index = 160)
        Return
    }

    ; Read updated .smx
    If !GetSmx(vSmx, vFile) ; ByRef vSmx
      Return

    ; Change color of the last (newest) highlights
    ; Note: SumatraPDF always updates the .smx by appending (not sorted by page)
    ; therefore we only need to operate on new sections at the end of the file
    if vSmxLen
    {
      vOldSmx := SubStr(vSmx, 1      , vSmxLen)
      vNewSmx := SubStr(vSmx, vSmxLen)
    }
    else
    {
      ; first annotation to new smx file
      vOldSmx := ""
      vNewSmx := vSmx
    }

    ; Replace color data in each new [highlight] section
    vNewSmx := StrReplace(vNewSmx, "color = #" vYellow, "color = #" vHighlightColor)
    
    SaveSmx(vFile, vSmx := vOldSmx vNewSmx)
  }
Return


; timer: set highlight color based on button press duration
cycle_highlight_color_mode:
  
  vDuration := A_TickCount - t1
  
  if (vDuration >= 1300)
  {
    vFlashColor := "cancel"
    Gui, Destroy
    Return
  }
  vFlashColor := vDuration < 400 ? vYellow : vDuration < 800 ? vRed : vGreen

  if (vFlashColor != vOldFlashColor) and (vDuration > 400)
    FlashColorSquare(30, vFlashColor, "mouse", 0)
  vOldFlashColor := vFlashColor
Return


; Note: Required to prevent L&R combo hotkey from blocking single Lbutton clicks
~Lbutton::
Return


#IfWinActive




; function: toggle or set highlights on/off
; - add/remove suffix "_OFF" to .smx filename
; - refresh SumatraPDF on change only
ToggleHighlightsOnOff(vFile, vOnOff := "") {
  If !vOnOff
    vOnOff := FileExist(vFile ".smx") ? "off" : FileExist(vFile "_OFF.smx")  ? "on" : ""

  If (vOnOff = "on") and FileExist(vFile "_OFF.smx")
    FileMove, % vFile "_OFF.smx", % vFile ".smx", 1
  Else if (vOnOff = "off") and FileExist(vFile ".smx")
    FileMove, % vFile ".smx", % vFile "_OFF.smx", 1
  Else
    Return
  
  Sleep 50
  RefreshSumatraDocument()
}



; function: check if file is type that need workaround for position bug/issue
; note: vEpubExtensions format: "|epub| ... |xyz|"
RequiresEpubFix(vFile, vEpubExtensions) {
  SplitPath, vFile, , , vExtension
  If InStr(vEpubExtensions, "|" vExtension "|")
    Return 1
}



; function: pass hotkey string to SumatraPDF if focused control is not SUMATRA_PDF_CANVAS1 (document canvas)
; note: does not pass mouse hotkeys or hotkeys with modifiers
PassthroughIfNotCanvasFocus(vHotkey) {
  If CanvasFocused()
    Return
  Passthrough(vHotkey)
  Return 1
}

; function: check if focused control is SUMATRA_PDF_CANVAS1 (document canvas)
CanvasFocused() {
  ; note: ControlGetFocus does not get "SUMATRA_PDF_CANVAS1" even when canvas is active
  ; possible explanation: SumatraPDF gives no keyboard focus to canvas?
  ; https://www.autohotkey.com/docs/commands/ControlGetFocus.htm
  ; workaround (incomplete?): check if other SumatraPDF UI controls have focus
  ;   note: only two other controls given #IfWinActive ahk_class SUMATRA_PDF_FRAME
  ;   Edit1 = go to editbox, Edit2 = find editbox
  ControlGetFocus, vActiveControl, A
  If !(vActiveControl = "Edit1") and !(vActiveControl = "Edit2")
    Return 1
}

; function: pass hotkey string to SumatraPDF
; note: filters out mouse hotkeys or hotkeys with modifiers
Passthrough(vHotkey)
{
  ; only pass single character keys (a, e, 1, ...)
  If (StrLen(vHotkey) = 1)
    Send % vHotkey
}

; function: pass hotkey string to SumatraPDF if unsupported document extension
PassthroughIfNotSupportedExt(vFile, vSupportedExtensions, vHotkey)
{
  if SupportedExtension(vFile, vSupportedExtensions)
    Return
  Passthrough(vHotkey)
  Return 1
}

; function: check if file extension is supported by HighlightJump
; note: vSupportedExtensions format: "|pdf|epub| ... |xyz|"
SupportedExtension(vFile, vSupportedExtensions) {
  SplitPath, vFile, , , vExtension
  If InStr(vSupportedExtensions, "|" vExtension "|")
    Return 1
}



; function: briefly flash new jump filter color in colored rectangle
FlashColorSquare(vSquareSize, vJumpColor, vSquarePos := "window", vTimeout := 1)
{
  vWinId := WinExist("A")
  If (vSquarePos = "mouse")
  {
    ; show square near mouse pointer
    CoordMode, Mouse, Screen
    MouseGetPos, x, y
    x -= Round(vSquareSize/2)
    y -= Round(vSquareSize/2)
  }
  Else
  {
    ; show square in window centre
    WinGetActiveStats, wint, winw, winh, winx, winy
    x := Round(winx + winw/2 - vSquareSize/2)
    y := Round(winy + winh/2 - vSquareSize/2)
  }
  Gui +ToolWindow -SysMenu -Caption -resize +AlwaysOnTop +Disabled
  Gui, Color, %vJumpColor%
  Gui, Show, x%x% y%y% w%vSquareSize% h%vSquareSize%
  WinActivate, % "ahk_id " vWinId

  If vTimeout
  {
    Sleep 200
    Gui, Destroy
  }
}
Return


; function: save new highlight to .smx file
SaveSmx(vFile, vSmx) {
  If !FileExist(vFile ".smx")
    Return
  
  FileDelete, % vFile ".smx"
  FileAppend, % vSmx, % vFile ".smx", UTF-8-RAW
  
  RefreshSumatraDocument()
}


; function: create .smx with standard header data
SmxCreateWithHeader(vFile)
{
  ; -------------------------
  ; .smx header format
  ; -------------------------
  ; # SumatraPDF: modifications to "Example File.pdf"
  ; [@meta]
  ; version = 3.2
  ; filesize = 1065035
  ; timestamp = 2020-01-30T19:23:12Z
  ;
  ; -------------------------
  
  SplitPath, vFile, vFilename
  FileGetSize, vBytes, % vFile
  FormatTime, vTimestamp,, yyyy-MM-ddTHH:mm:ssZ
  
  vSmxHeader =
  (LTrim
  # SumatraPDF: modifications to "%vFilename%"
  [@meta]
  version = 3.2
  filesize = %vBytes%
  timestamp = %vTimestamp%
  )
  
  FileAppend, % vSmxHeader, % vFile ".smx", UTF-8-RAW
}


; function: reload active SumatraPDF document, keeps current page view
; https://github.com/sumatrapdfreader/sumatrapdf/blob/master/src/resource.h
; IDM_REFRESH  := 406
; WM_COMMAND   := 0x111
RefreshSumatraDocument() {
  vWinId := WinExist("A")
  SendMessage, 0x111, 406,0,, % "ahk_class SUMATRA_PDF_FRAME ahk_id " vWinId
}


; function: save annotation in active SumatraPDF document
; https://github.com/sumatrapdfreader/sumatrapdf/blob/master/src/resource.h
; IDM_SAVE_ANNOTATIONS_SMX  := 439
; WM_COMMAND   := 0x111
; Note: In SumatraPDF prerelease older than 2020-02-02: crash if no new annotation
;       See https://github.com/sumatrapdfreader/sumatrapdf/issues/1442
SaveAnnotationToSmx() {
  vWinId := WinExist("A")
  SendMessage, 0x111, 439,0,, % "ahk_class SUMATRA_PDF_FRAME ahk_id " vWinId
}


; function: go to page in active SumatraPDF window via SendMessage
; references
; https://github.com/sumatrapdfreader/sumatrapdf/issues/1398
; https://gist.github.com/nod5/4d172a31a3740b147d3621e7ed9934aa
SumatraGotoPageDDE(vFile, vPage) {
  ; Control a SumatraPDF window from AutoHotkey unicode 32bit/64bit scripts
  ; through DDE command text packed in SendMessage WM_COPYDATA
  
  WinTitle := "ahk_id " WinExist("A")
  
  ; Required data to tell SumatraPDF to interpret lpData as DDE command text, always 0x44646557
  dwData := 0x44646557

  ; SumatraPDF DDE command unicode text, https://www.sumatrapdfreader.org/docs/DDE-Commands.html
  ; Example: [GotoPage("C:\file.pdf", 4)]
  ; Remember to escape " in AutoHotkey expressions with ""
  lpData := "[GotoPage(""" vFile """, " vPage ")]"

  Send_WM_COPYDATA(WinTitle, dwData, lpData)
}


; function: prepare copydatastruct and send wm_copydata message
; Notes:
; The this code differs from the AutoHotkey docs WM_COPYDATA example #4 at
; https://www.autohotkey.com/docs/commands/OnMessage.htm#SendString
; in that example #4 does not set a specific dwData value.
; If a specific dwData value is required or not depends on the target application.
; Further references:
; https://docs.microsoft.com/en-us/windows/win32/dataxchg/wm-copydata
; https://docs.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-copydatastruct
; https://www.autohotkey.com/docs/commands/PostMessage.htm

Send_WM_COPYDATA(WinTitle, dwData, lpData) {
  static WM_COPYDATA := 0x4A
  VarSetCapacity(COPYDATASTRUCT, 3*A_PtrSize, 0)
    cbData := (StrLen(lpData) + 1) * (A_IsUnicode ? 2 : 1)
    NumPut(dwData,  COPYDATASTRUCT, 0*A_PtrSize)
    NumPut(cbData,  COPYDATASTRUCT, 1*A_PtrSize)
    NumPut(&lpData, COPYDATASTRUCT, 2*A_PtrSize)
  
  SendMessage, WM_COPYDATA, 0, &COPYDATASTRUCT,, % WinTitle
  return ErrorLevel == "FAIL" ? false : true
}


; function: get filepath to current document in active SumatraPDF window
GetFile(ByRef vFile){
  if vLegacyMethods ; super-global variable
    vFile := SumatraGetActiveDocumentFilePathFromTitle()
  else
    vFile := SumatraGetActiveDocumentFilepath()
  if vFile
    Return 1
}


; function: get .smx file data
GetSmx(ByRef vSmx, vFile := "") {
If vFile
  FileRead, vSmx, %vFile%.smx
If vSmx
  Return 1
}


; function: get page number and document length from SumatraPDF go to control
GetPageLen(ByRef vPage, ByRef vLen) {
  ; note: reading the control works even if toolbar is hidden
  ControlGetText, vPage, Edit1, A
  ; Get adjacent text
  ControlGetText, vRightText, Static3, A

  ; ------------------------------------------------
  ; Notes on how pagenumbers are shown in the SumatraPDF UI
  ; ------------------------------------------------
  ; - The SumatraPDF goto editbox can show virtual or real pagenumbers
  ; - Examples of virtual pagenumbers: i ii iii D1 toc 24 ...
  ; - Detect which by examining the adjacent UI text:
  ;     case1: "(6 / 102)" -> virtual number in editbox, real number is 6
  ;     case2: "/ 102"     -> real    number in editbox
  ; - Use real pagenumber to control SumatraPDF via DDE or command line
  ; - The number after the frontslash is document length in real pagenumbers
  ; ------------------------------------------------
  
  ; if case1: get real (not virtual) pagenumber from adjacent text
  RegExMatch(vRightText, "\((\d+)", vRealPageCheck)
  If vRealPageCheck
    vPage := vRealPageCheck1

  ; get document length: "/ 102" -> 102
  ; use pattern that handles both case1 and case2 text
  RegExMatch(vRightText, "^.*/ (\d+)(?:\D|)", vLenMatch)
  vLen := vLenMatch1

  If (vPage and vLen)
    Return 1
}




; function: get cursor canvas x y pos in pt units from active SumatraPDF window
; dependency: SumatraPDF source code edits in Resource.h , SumatraPDF.cpp
; IDM_REPLY_PT_POS                522
; note: SumatraPDF returns up to 10 digits (, 32-bit signed integer, range up to 2147483648)
; with postion data packed in format XXXXXYYYYY
; X < 21474. Y <= 99999. Y is zero padded.
SumatraGetCanvasPos(ByRef x, ByRef y) {
  if !WinActive("ahk_class SUMATRA_PDF_FRAME")
    Return
  SendMessage, 0x111, 522, 0,, A
  vReturn := ErrorLevel
  if vReturn
  {
    ;get X Y (add 0 to remove zero-padding)
    y := 0 + SubStr(vReturn, -4)    ;last 5 digits
    x := 0 + SubStr(vReturn, 1, -5) ;all except last 5 digits
  }
}




; function: get pagenumber under mouse cursor from active SumatraPDF window
; dependency: SumatraPDF source code edits in Resource.h , SumatraPDF.cpp
; IDM_REPLY_PAGE_NUM              523
; note: SumatraPDF returns 0 if cursor not over any page
SumatraGetPageAtPoint(ByRef vPage) {
  if !WinActive("ahk_class SUMATRA_PDF_FRAME")
    Return

  SendMessage, 0x111, 523, 0,, A
  vPage := ErrorLevel = "FAIL" ? 0 : ErrorLevel
}




; function: show tooltip asking user to click page and return its page number
; dependency: SumatraPDF source code edits in Resource.h , SumatraPDF.cpp (in called functions)
ClickPageGetPageNumber(vToolTipText) {
  ; show tooltip and wait for Lbutton, cancel via Esc or timeout
  ToolTip, % vToolTipText
  t := A_TickCount
  ; loop multiple keywait with short timeouts
  ; todo: better method? cleanup?
  Loop
  {
    KeyWait, Lbutton, D T0.02
    If !ErrorLevel
      break
    KeyWait, Esc, D T0.02
    If !ErrorLevel or (A_TickCount > t + 3000) or !WinActive("ahk_class SUMATRA_PDF_FRAME")
    {
      ToolTip
      return
    }
  }
  ToolTip
  SumatraGetPageAtPoint(vPage) ; ByRef
  Return vPage
}




; function: get the only (near fully) visible page or else let user click to select page
; dependency: SumatraPDF source code edits in Resource.h , SumatraPDF.cpp (in called functions)
; vToolTipText = string to fill blank in tooltip "Click a page to _____ (Esc = cancel)"
SmartPageSelect(vToolTipText)
{
  ; if only one page is visible or only one is near fully visible
  ; then return that page number
  ; else ask user to click page to return its page number
  SumatraGetCountPagesVisible(vVisiblePagesCount, vNearFullyVisibleCount, vLastNearFullyVisible)
  ; case1: only one page visible
  ; case2: many visible but only one near fully visible (>= 80%)
  If (vVisiblePagesCount = 1) or (vNearFullyVisibleCount = 1)
  {
    If vLastNearFullyVisible
      vPage := vLastNearFullyVisible
  }
  ; case3: many near fully visible *or* function returned 0: ask user to click to select page
  Else
  {
    ; show tooltip and wait for Lbutton, cancel via Esc or timeout
    vToolTipText := "Click a page to " vToolTipText "`n(Esc = cancel)"
    vPage := ClickPageGetPageNumber(vToolTipText)
  }
  Return vPage
}




; function: get pagenumber under mouse cursor from active SumatraPDF window
; dependency: SumatraPDF source code edits in Resource.h , SumatraPDF.cpp
; IDM_COPY_SELECTION              420
SumatraCopySelection(ByRef vClip) {
  if !WinActive("ahk_class SUMATRA_PDF_FRAME")
    Return
  vClipBackup := clipboardall
  Clipboard := ""
  ; copy selection
  SendMessage, 0x111, 420, 0,, A
  ; hide SumatraPDF notification "Select content with Ctrl+left mouse button" shown if no selection
  Control, Hide, , SUMATRA_PDF_NOTIFICATION_WINDOW1, A
  vClip := Clipboard
  Clipboard := vClipBackup
  vClipBackup := ""
}




; function: get number of pages visible in active SumatraPDF window
; dependency: SumatraPDF source code edits in Resource.h , SumatraPDF.cpp
; IDM_REPLY_PAGES_VISIBLE         524
; returned data is packed in format LLLLLNNVV where
; V = number of visible pages               >  0%  visible
; N = number of near fully visible pages    >= 80% visible
; L = pagenumber for last near fully visible page
SumatraGetCountPagesVisible(ByRef vVisiblePagesCount, ByRef vNearFullyVisibleCount, ByRef vLastNearFullyVisible) {
  if !WinActive("ahk_class SUMATRA_PDF_FRAME")
    Return
  SendMessage, 0x111, 524, 0,, A
  vReturn := ErrorLevel
  vVisiblePagesCount := vNearFullyVisibleCount := vLastNearFullyVisible := 0
  if (vReturn != "FAIL")
  {
    ; note: add 0 to remove zero-padding
    vVisiblePagesCount       := 0 + SubStr(vReturn, -1)     ; VV
    if (StrLen(vReturn) > 2)
      vNearFullyVisibleCount  := 0 + SubStr(vReturn, -3, 2) ; FF
    if (StrLen(vReturn) > 4)
      vLastNearFullyVisible   := 0 + SubStr(vReturn, 1, -4) ; LLLLL
  }
}




; function: get filepath for active document in active SumatraPDF window
; dependency: SumatraPDF source code edits in Resource.h , SumatraPDF.cpp
; - make SumatraPDF return data via WM_COPYDATA
; - IDM_COPY_FILE_PATH          520
; - Note: Works if SumatraPDF is compiled 32bit and AutoHotkey 32bit/64bit unicode
;         Fails if SumatraPDF is compiled 64bit
SumatraGetActiveDocumentFilepath() {
  
  if !WinActive("ahk_class SUMATRA_PDF_FRAME")
    Return
  vWinId := WinExist("A")
  DetectHiddenWindows, On
  ; start listener for WM_COPYDATA that SumatraPDF will send after we first call
  OnMessage(0x4a, "Receive_WM_COPYDATA")
  ; clear super-global variable
  vFilepathReturn := ""
  ; make first call to SumatraPDF
  ; - 0x111 is WM_COMMAND
  ; - IDM_COPY_FILE_PATH = 520
  ; - A_SCriptHwnd is Hwnd to this script's hidden window
  ;   Note: A_SCriptHwnd is hex, WinTitle ahk_id accepts both hex and dec values
  SendMessage, 0x111, 520, A_ScriptHwnd, , % "ahk_id " vWinId
  
  ; after Receive_WM_COPYDATA has reacted, stop listener
  OnMessage(0x4a, "Receive_WM_COPYDATA", 0)
  
  ; check for \ to ensure filepath an not only filename
  If InStr(vFilepathReturn, "\")
    return vFilepathReturn
}


Receive_WM_COPYDATA(wParam, lParam)
{
  ; https://docs.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-copydatastruct
  ; ULONG_PTR dwData;  = unsigned __int64 
  ; DWORD     cbData;
  ; PVOID     lpData;
  
  ; https://www.autohotkey.com/docs/commands/NumGet.htm
  ; defaults to "UPtr"
  ; "Unsigned 64-bit integers are not supported, as AutoHotkey's native integer type is Int64"
  
  ; works if modified SumatraPDF 32bit sends to AutoHotkey 32bit/64bit unicode
  ; fails if SumatraPDF 64bit

  ; note: dwData only works if treated as utf-8, why? String is also backwards, endianness issue?
  dwData := StrGet(lParam, A_PtrSize, "UTF-8")
  cbData := NumGet(lParam + 1*A_PtrSize)
  lpDataAdress := NumGet(lParam + 2*A_PtrSize) ; default type "UPtr"
  lpData := StrGet(lpDataAdress)
  ; set super-global variable
  vFilepathReturn := lpData

  ; MsgBox % dwData "|" cbData "|" lpData
  Return
}


; function: SetSystemCursor() set custom system cursor or restore default cursor
; - no parameter     : restore default cursor
; - parameter "CROSS": change custom system cursor to cross
; original function by Flipeador , https://www.autohotkey.com/boards/viewtopic.php?p=206703#p206703
SetSystemCursor(Cursor := "")
{
  Static Cursors := {APPSTARTING: 32650, ARROW: 32512, CROSS: 32515, HAND: 32649, HELP: 32651, IBEAM: 32513
                    , NO: 32648, SIZEALL: 32646, SIZENESW: 32643, SIZENS: 32645
                    , SIZENWSE: 32642, SIZEWE: 32644, UPARROW: 32516, WAIT: 32514}

  If (Cursor == "")
    ; Restore default cursors
    Return DllCall("User32.dll\SystemParametersInfoW", "UInt", 0x0057, "UInt", 0, "Ptr", 0, "UInt", 0)

  ; Replace default cursors with custom cursor
  Cursor := InStr(Cursor, "3") ? Cursor : Cursors[Cursor]
  For Each, ID in Cursors
  {
    ; 2 = IMAGE_CURSOR | 0x00008000 = LR_SHARED
    hCursor := DllCall("User32.dll\LoadImageW", "Ptr", 0, "Int", Cursor, "UInt", 2, "Int", 0, "Int", 0, "UInt", 0x00008000, "Ptr")
    hCursor := DllCall("User32.dll\CopyIcon", "Ptr", hCursor, "Ptr")
    DllCall("User32.dll\SetSystemCursor", "Ptr", hCursor, "UInt",  ID)
  }
} ; https://msdn.microsoft.com/en-us/library/windows/desktop/ms648395(v=vs.85).aspx



; -------------------------------------------------------------
; LegacyMethods start
; -------------------------------------------------------------

; LegacyMethods
; function: prepare SumatraPDF for document pt position check
; Returns 1 if prepared
PrepareForCanvasPosCheck()
{

  ; ------------------------------------------
  ; notes on SumatraPDF position helper notification
  ; ------------------------------------------
  ; Shortcut "m" shows position helper notification in top left document corner.
  ; Reports X Y document canvas position that the mouse is over.
  ;   Example: top right document corner reports 0 0 in fixed page mode.
  ; Press "m" again to cycle notification units: pt -> mm -> in
  ; .smx files use unit pt for highlight rect corner data.
  ; Once notification exists we can hide it and still read with ControlGetText.
  ; "Esc" closes the notification even when hidden.

  ; Notification text format:
  ; "Cursor position: 51,0 x 273,5 pt"
  ; "Cursor position: 18,0 x 96,4 mm"
  ; "Cursor position: 0,71 x 3,8 in"
  ;
  ; Note: do not use the "," in regex because it is char "." on some PCs
  ; Note: do not use the ":" in regex because not present in all translations
  ; Example: Dutch language setting: "Cursor positie 0,0 x 4,77 in"
  ; 
  ; Note: The pt/mm/in unit string is not translated so can be used as pattern.
  ; Check via SubStr since InStr could give false positive in some language.
  ; ------------------------------------------

  ; check if popup exists (hidden or visible)
  ControlGetText, vPos, SUMATRA_PDF_NOTIFICATION_WINDOW1, A

  ; if not exist then send "m" to create popup
  ; note: SumatraPDF changes the mouse cursor to a cross while the popup exists
  ; note: use SubStr since InStr could give false positive in some language.
  If !(SubStr(vPos, -1) = "pt")
  {
    Loop, 3
    {
      ; show popup
      Send m
      ; hide popup (we can still read it and toggle its unit)
      Control, Hide, , SUMATRA_PDF_NOTIFICATION_WINDOW1, A
      ; read popup
      ControlGetText, vPos, SUMATRA_PDF_NOTIFICATION_WINDOW1, A
      If (SubStr(vPos, -1) = "pt")
        Break
      Sleep 30
    }
  }

  If (SubStr(vPos, -1) = "pt")
    Return 1
}


; LegacyMethods
; function: Read SumatraPDF notification to get mouse position in canvas pt units
SumatraGetCanvasPosFromNotification(ByRef x, Byref y) {
  
  ; get mouse position in SumatraPDF canvas in pt units (one decimal)
  ControlGetText, vPos, SUMATRA_PDF_NOTIFICATION_WINDOW1, A
  ; extract X Y pos with decimals and round later
  ; note: do not use the "," in regex because it is char "." on some PCs
  ; note: do not use the ":" in regex because not present in all translations
  ; test after discussion at https://github.com/nod5/HighlightJump/issues/6
  ; mockup hybrid strings to show possible combinations of digits and separators (space comma dot)
  ; ": 4.401 000,3 x 341,000.3 pt"
  ; "a 4.401 000,3 x 341,000.3 pt"
  ; regex sandbox: https://regex101.com/r/QAU3Kt/1
  ; first step regex pattern
  vPattern := "\D ([\d \.,]+)[\.,](\d+) x ([\d \.,]+)[\.,](\d+) pt$"
  RegExMatch(vPos, vPattern, vPos)
  ; remove separators to get integers
  vPos1 := RegExReplace(vPos1, "[ \.,]", "")
  vPos3 := RegExReplace(vPos3, "[ \.,]", "")
  ; concatenate (integer)(dot-separator)(fraction)
  x := vPos1 "." vPos2
  y := vPos3 "." vPos4
}


; LegacyMethods
; function: Get document filepath by parsing window title
; Dependency: SumatraPDF > Advanced Options > FullPathInTitle = true
SumatraGetActiveDocumentFilePathFromTitle()
{
  WinGetTitle, vTitle, A

  ; ---------------------------------------------
  ; SumatraPDF window title format with advanced setting "FullPathInTitle = true"
  ; ---------------------------------------------
  ; format1 "<filepath> - [<metadata document title>] - SumatraPDF"
  ; format2 "<filepath> - SumatraPDF"
  ; --------------------------------------------
  ; note: in format1 both filepath and metadata can use characters "-"  "["  and  " "
  ; That enables edge cases like "C:\a.pdf - [.pdf - [x] - SumatraPDF"
  ; which has two possible solutions
  ; 1 "C:\a.pdf"          with metadata ".pdf - [x"
  ; 2 "C:\a.pdf - [.pdf"  with metadata "x"
  ; and more complex cases with even more solutions.
  ; In format2 there is always one solution.
  
  ; Detect format1 or format2
  If (SubStr(vTitle, -13) = "] - SumatraPDF")
  {
    ; format1: try each instance of " - [" until a file exist
    ; probably good enough in most circumstances
    Loop, 20
    {
      vFilepathLen := InStr(vTitle, " - [", , , A_Index) - 1
      vFile := SubStr(vTitle, 1, vFilepathLen)
      if FileExist(vFile)
        break
    }
  }
  Else
  {
    ; format2: find last instance of " - SumatraPDF"
    vFilepathLen := InStr(vTitle, " - SumatraPDF") - 1
    vFile := SubStr(vTitle, 1, vFilepathLen)
  }

  ; Check for :\ and existance to ensure string is filepath and not only filename
  If InStr(vFile, ":\") and FileExist(vFile)
    Return vFile
}

; -------------------------------------------------------------
; LegacyMethods end
; -------------------------------------------------------------
