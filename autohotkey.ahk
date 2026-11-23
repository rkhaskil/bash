#Requires AutoHotkey v2.0
#SingleInstance Force

; Ctrl + Alt + G inserts an editable two-column network table in desktop OneNote.
; Click on a blank line OUTSIDE an existing table before using the shortcut.

#HotIf WinActive("ahk_exe ONENOTE.EXE")
^!g::InsertNetworkTemplate()
#HotIf

InsertNetworkTemplate() {
    fields := [
        "Source Project ID:",
        "Destination Project ID:",
        "Source IP:",
        "Destination IP:",
        "Port:",
        "Source Subnet:",
        "Destination Subnet:"
    ]

    rows := ""
    fallbackText := ""
    for field in fields {
        rows .= '<tr>'
            . '<td style="border:1px solid #999; padding:5px; width:220px;">' field '</td>'
            . '<td style="border:1px solid #999; padding:5px; width:240px;">&nbsp;</td>'
            . '</tr>'
        fallbackText .= field "`t`r`n"
    }
    html := '<table border="1" cellspacing="0" cellpadding="5" '
        . 'style="border-collapse:collapse; font-family:Calibri; font-size:11pt;">'
        . rows . '</table>'

    savedClipboard := ClipboardAll()
    if !PutHtmlOnClipboard(html, fallbackText) {
        A_Clipboard := savedClipboard
        MsgBox "Could not prepare the formatted table on the clipboard."
        return
    }

    Sleep 120
    Send "^v"  ; Normal formatted paste, NOT Ctrl+Shift+V (paste as plain text).
    Sleep 1100   ; Allow OneNote to finish reading the clipboard.
    A_Clipboard := savedClipboard
}

PutHtmlOnClipboard(fragment, plainText) {
    ; Windows HTML clipboard format (CF_HTML): byte offsets, UTF-8 payload.
    startMark := "<!--StartFragment-->"
    endMark := "<!--EndFragment-->"
    document := "<html><body>" startMark fragment endMark "</body></html>"

    headerTemplate := "Version:1.0`r`n"
        . "StartHTML:0000000000`r`n"
        . "EndHTML:0000000000`r`n"
        . "StartFragment:0000000000`r`n"
        . "EndFragment:0000000000`r`n"

    startHtml := StrPut(headerTemplate, "UTF-8") - 1
    startFragmentPart := SubStr(document, 1,
        InStr(document, startMark) + StrLen(startMark) - 1)
    endFragmentPart := SubStr(document, 1, InStr(document, endMark) - 1)
    startFragment := startHtml + StrPut(startFragmentPart, "UTF-8") - 1
    endFragment := startHtml + StrPut(endFragmentPart, "UTF-8") - 1
    endHtml := startHtml + StrPut(document, "UTF-8") - 1

    header := Format("Version:1.0`r`nStartHTML:{:010}`r`nEndHTML:{:010}`r`n"
        . "StartFragment:{:010}`r`nEndFragment:{:010}`r`n",
        startHtml, endHtml, startFragment, endFragment)
    payload := header document

    htmlHandle := AllocClipboardText(payload, "UTF-8")
    textHandle := AllocClipboardText(plainText, "UTF-16")
    if !htmlHandle || !textHandle {
        if htmlHandle
            DllCall("GlobalFree", "Ptr", htmlHandle, "Ptr")
        if textHandle
            DllCall("GlobalFree", "Ptr", textHandle, "Ptr")
        return false
    }

    cfHtml := DllCall("RegisterClipboardFormat", "Str", "HTML Format", "UInt")
    if !cfHtml || !DllCall("OpenClipboard", "Ptr", A_ScriptHwnd, "Int") {
        DllCall("GlobalFree", "Ptr", htmlHandle, "Ptr")
        DllCall("GlobalFree", "Ptr", textHandle, "Ptr")
        return false
    }

    DllCall("EmptyClipboard")
    htmlSet := DllCall("SetClipboardData", "UInt", cfHtml,
        "Ptr", htmlHandle, "Ptr")
    textSet := DllCall("SetClipboardData", "UInt", 13,
        "Ptr", textHandle, "Ptr") ; CF_UNICODETEXT
    DllCall("CloseClipboard")

    ; Clipboard owns each successfully transferred memory handle.
    if !htmlSet
        DllCall("GlobalFree", "Ptr", htmlHandle, "Ptr")
    if !textSet
        DllCall("GlobalFree", "Ptr", textHandle, "Ptr")
    return !!(htmlSet && textSet)
}

AllocClipboardText(value, encoding) {
    units := StrPut(value, encoding) ; Includes terminating NUL.
    bytes := (encoding = "UTF-16") ? units * 2 : units
    handle := DllCall("GlobalAlloc", "UInt", 0x42, "UPtr", bytes, "Ptr")
    if !handle
        return 0
    pointer := DllCall("GlobalLock", "Ptr", handle, "Ptr")
    if !pointer {
        DllCall("GlobalFree", "Ptr", handle, "Ptr")
        return 0
    }
    StrPut(value, pointer, units, encoding)
    DllCall("GlobalUnlock", "Ptr", handle)
    return handle
}
