
#Requires AutoHotkey v2.0
#SingleInstance Force

#HotIf WinActive("ahk_exe ONENOTE.EXE")

^!g:: {
    fields := [
        "Source Project ID",
        "Destination Project ID",
        "Source IP",
        "Destination IP",
        "Port",
        "Source Subnet",
        "Destination Subnet"
    ]

    for index, field in fields {
        SendText field
        Sleep 80
        Send "{Tab}"
        Sleep 80

        if (index < fields.Length) {
            Send "{Enter}"
            Sleep 80
        }
    }
}

#HotIf
