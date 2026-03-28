sub init()
    m.chrome = m.top.findNode("chrome")
    m.roomCodeLabel = m.top.findNode("roomCodeLabel")
    m.startGameButton = m.top.findNode("startGameButton")
    m.playerGrid = m.top.findNode("playerGrid")
    m.focusTarget = "start"
    m.serverBase = "http://192.168.1.104:3000"

    m.pollTask = CreateObject("roSGNode", "PlayerPollTask")
    m.startTask = CreateObject("roSGNode", "StartSpecificGameTask")
    m.startTask.gameId = "imposter"

    m.top.observeField("roomCode", "onRoomCodeSet")
    m.pollTask.observeField("roomState", "onRoomUpdate")
    m.startTask.observeField("roomState", "onGameStarted")
    m.top.setFocus(true)
    refreshButtonStyles(false)
end sub

sub onRoomCodeSet()
    if m.top.roomCode = invalid or m.top.roomCode = "" then return

    m.roomCodeLabel.text = m.top.roomCode

    m.qrCode = m.top.findNode("qrCode")
    joinUrl = m.serverBase + "/join?code=" + m.top.roomCode

    transfer = CreateObject("roUrlTransfer")
    encodedUrl = joinUrl
    if transfer <> invalid then
        encodedUrl = transfer.Escape(joinUrl)
    end if

    m.qrCode.uri = "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=" + encodedUrl

    m.pollTask.roomCode = m.top.roomCode
    m.pollTask.control = "run"
end sub

sub onRoomUpdate()
    room = m.pollTask.roomState
    if room = invalid or not room.doesExist("players") then return

    content = CreateObject("roSGNode", "ContentNode")
    connectedCount = 0

    for each player in room.players
        item = content.createChild("ContentNode")
        item.title = player.name
        item.description = "Online"
        if player.doesExist("isConnected") and player.isConnected = false then
            item.description = "Offline - reconnecting"
        else
            connectedCount = connectedCount + 1
        end if

        if player.doesExist("character") and player.character <> invalid and player.character <> "" then
            item.addField("characterUrl", "string", false)
            item.characterUrl = "pkg:/images/Characters/" + player.character + ".png"
        end if
    end for

    m.playerGrid.content = content

    subtitle = connectedCount.ToStr() + " player(s) connected. "
    if connectedCount < 3 then
        subtitle = subtitle + "3 or more players is best for a full round."
    else
        subtitle = subtitle + "Ready to start whenever you are."
    end if
    if m.chrome <> invalid then
        m.chrome.bodyText = subtitle
    end if
end sub

sub cleanup()
    if m.pollTask <> invalid then
        m.pollTask.control = "stop"
    end if
    if m.startTask <> invalid then
        m.startTask.control = "stop"
    end if
end sub

function onKeyEvent(key, press) as Boolean
    if press and key = "back" then
        if m.top.sceneManager <> invalid then
            m.top.sceneManager.callFunc("goBack")
        end if
        return true
    end if

    if press and (key = "left" or key = "up") then
        m.focusTarget = "back"
        refreshButtonStyles(false)
        return true
    end if

    if press and (key = "right" or key = "down") then
        m.focusTarget = "start"
        refreshButtonStyles(false)
        return true
    end if

    if key = "OK" then
        if press then
            refreshButtonStyles(true)
            if m.focusTarget = "back" then
                if m.top.sceneManager <> invalid then
                    applyBackButtonStyle(true, true)
                    m.top.sceneManager.callFunc("goBack")
                end if
            else
                m.startTask.roomCode = m.top.roomCode
                m.startTask.control = "run"
            end if
            return true
        else
            refreshButtonStyles(false)
            return true
        end if
    end if

    return false
end function

sub refreshButtonStyles(isPressed as Boolean)
    applyBackButtonStyle(m.focusTarget = "back", isPressed and m.focusTarget = "back")
    applyStartButtonStyle(m.focusTarget = "start", isPressed and m.focusTarget = "start")
end sub

sub applyBackButtonStyle(isFocused as Boolean, isPressed as Boolean)
    if m.chrome = invalid then return
    m.chrome.callFunc("setBackButtonState", isFocused, isPressed)
end sub

sub applyStartButtonStyle(isFocused as Boolean, isPressed as Boolean)
    m.startGameButton.isFocused = isFocused
    m.startGameButton.isPressed = isPressed
end sub

sub onGameStarted()
    refreshButtonStyles(false)
    if m.startTask.roomState <> invalid and m.top.sceneManager <> invalid then
        m.top.sceneManager.callFunc("showMiniGameVote", m.top.roomCode)
    end if
end sub
