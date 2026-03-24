sub init()
    m.playerName = m.top.findNode("playerName")
    m.statusLabel = m.top.findNode("statusLabel")
    m.card = m.top.findNode("card")
    m.accent = m.top.findNode("accent")
    m.characterIcon = m.top.findNode("characterIcon")
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

    ' Load character icon if provided
    characterUrl = ""
    if item.doesExist("characterUrl") and item.characterUrl <> invalid and item.characterUrl <> "" then
        characterUrl = item.characterUrl
    end if

    if characterUrl <> "" then
        m.characterIcon.uri = characterUrl
        m.characterIcon.visible = true
        ' Shift labels right to make room for icon
        m.playerName.translation = [70, 14]
        m.playerName.width = 138
        m.statusLabel.translation = [70, 54]
        m.statusLabel.width = 138
    else
        m.characterIcon.uri = ""
        m.characterIcon.visible = false
        ' Use full-width layout when no icon
        m.playerName.translation = [14, 14]
        m.playerName.width = 194
        m.statusLabel.translation = [14, 54]
        m.statusLabel.width = 194
    end if
end sub