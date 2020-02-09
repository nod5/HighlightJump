// Edits last tested on SumatraPDF master 2020-02-04

// -------------------------------------------
// Add above the line "void AssociateExeWithPdfExtension() {"
// -------------------------------------------
// HighlightJump
// based on parts from FormatCursorPosition() and UpdateCursorPositionHelper()
long GetCursorCanvasPos(WindowInfo* win, PointI pos) {
    CrashIf(!win->AsFixed());
    EngineBase* engine = win->AsFixed()->GetEngine();
    PointD pt = win->AsFixed()->CvtFromScreen(pos);

    if (pt.x < 0)
        pt.x = 0;
    if (pt.y < 0)
        pt.y = 0;
    pt.x /= engine->GetFileDPI();
    pt.y /= engine->GetFileDPI();
    long XPosition = pt.x * 72;
    long YPosition = pt.y * 72;
    
    // Return LONG with x and y cursor canvas position in pt units.
    // LRESULT then returns that LONG to external SendMessage caller,
    // which can then extract the x y data.
    // Reliable because x and y are each always 3 digits or fewer
    // and LONG is at least a 32-bit signed integer (range up to 2147483648).
    // Custom format to store data in the LONG:
    // 1XXXXYYYY where XXXX and YYYY are the X Y 3 digit values (zero padded)
    // Example: if x=305 and y=21 then 103050021
    return 100000000 + (XPosition * 10000) + YPosition;
}

// HighlightJump
// based on OnFrameKeyM()
long ReturnCursorPos(WindowInfo* win) {
    if (!win->AsFixed()) {
        return 0;
    }
    PointI pt;
    if (GetCursorPosInHwnd(win->hwndCanvas, pt)) {
        return GetCursorCanvasPos(win, pt);
    }
    return 0;
}
// -------------------------------------------
// -------------------------------------------






// ------------------------------------------
// Add above the line "static void OnMenuRenameFile(WindowInfo* win) {"
// ------------------------------------------

// HighlightJump
// based on
// - CopySelectionToClipboard() 
// - IDM_SHOW_IN_FOLDER/OnMenuShowInFolder()
// - L228+ in SumatraStartup.cpp
    long SendMessageFilePathToCaller(WindowInfo* win, HWND callerHwnd) {
    if (!HasPermission(Perm_DiskAccess)) {
        return 0;
    }
    if (!win->IsDocLoaded()) {
        return 0;
    }
    if (gPluginMode) {
        return 0;
    }
    auto* ctrl = win->ctrl;
    auto srcFileName = ctrl->FilePath();
    if (!srcFileName) {
        return 0;
    }

    // Send active SumatraPDF document filepath string back to caller app
    //COPYDATASTRUCT has three members
    //1 dwData: optional short message. We opt for: 0x44646557 ("DdeW")
    //2 cbData: data length in bytes
    //3 lpData: data
    
    // Works if SumatraPDF is compiled as 32-bit
    // Both 32-bit and 64-bit AutoHotkey unicode scripts can then read lpData ok
    // Does not work if SumatraPDF is compiled as 64-bit
    // Both 32-bit and 64-bit AutoHotkey scripts will the get garbled lpData string

    //note: must use const for lpData since srcFileName is const, else compiler error
    //note: must use (PVOID) to cast const wchar * to pvoid, else compiler error
    //note: also works to skip lpData var and use srcFileName directly
    const WCHAR * lpData = srcFileName;
    DWORD cbData = (str::Len(lpData) + 1) * sizeof(WCHAR);
    COPYDATASTRUCT cds = {0x44646557, cbData, (PVOID)lpData};

    LRESULT res = SendMessage(callerHwnd, WM_COPYDATA, 0, (LPARAM)&cds);
    if (res) {
        return 1;
    }
    return 0;
}
// -------------------------------------------

// -------------------------------------------






    // --------------------------------------------
    // Add below the line "int wmId = LOWORD(wParam);"
    // --------------------------------------------
    // HighlightJump
    HWND callerHwnd = (HWND)lParam;
    // -------------------------------------------

    // -------------------------------------------






// ------------------------------------------
// Add above the line "case IDM_SELECT_ALL:"
// ------------------------------------------
        // HighlightJump
        // Based on: IDM_COPY_SELECTION
        case IDM_COPY_FILE_PATH:
            if (win->currentTab)
                return SendMessageFilePathToCaller(win, callerHwnd);
            break;

        // HighlightJump
        case IDM_REPLY_PT_POS:
            //return is sent as LONG LRESULT back to SendMessage caller
            return ReturnCursorPos(win);
            break;
// ------------------------------------------

// ------------------------------------------
