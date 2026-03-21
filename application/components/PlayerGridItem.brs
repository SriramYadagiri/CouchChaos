sub init()
    m.playerName = m.top.findNode("playerName")
    m.statusLabel = m.top.findNode("statusLabel")
    m.card = m.top.findNode("card")
    m.accent = m.top.findNode("accent")
end sub

sub onContentChanged()
    item = m.top.itemContent
    if item = invalid then return

    if item.doesExist("title") then
        m.playerName.text = item.title
    else
        m.playerName.text = ""
    end if

    statusText = "Online"
    if item.doesExist("description") and item.description <> invalid and item.description <> "" then
        statusText = item.description
    end if
    m.statusLabel.text = statusText

    isConnected = true
    if Left(statusText, 7) = "Offline" then
        isConnected = false
    end if

    if isConnected then
        m.card.color = "0x173049FF"
        m.accent.color = "0x27C2FFFF"
        m.statusLabel.color = "0xBFD8EAFF"
    else
        m.card.color = "0x24313FFF"
        m.accent.color = "0xF5A623FF"
        m.statusLabel.color = "0xFFD18BFF"
    end if
end sub
