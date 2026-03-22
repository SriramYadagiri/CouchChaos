sub init()
    m.chrome = m.top.findNode("chrome")
    m.roomCodeLabel = m.top.findNode("roomCodeLabel")
    m.roomCodeTitle = m.top.findNode("roomCodeTitle")
    m.playersTitle = m.top.findNode("playersTitle")
    m.playersSubtitle = m.top.findNode("playersSubtitle")
    m.startGameButton = m.top.findNode("startGameButton")
    m.playerGrid = m.top.findNode("playerGrid")
    m.startVoteTask = CreateObject("roSGNode", "StartGameVoteTask")
    m.focusTarget = "start"

    m.top.observeField("roomCode", "onRoomCodeSet")
    m.startVoteTask.observeField("roomState", "onVoteStarted")
    m.top.setFocus(true)
    refreshButtonStyles(false)
end sub

sub onRoomCodeSet()
    print "Lobby Scene Loaded..."
    print "Room Code: "; m.top.roomCode

    m.roomCodeLabel.text = m.top.roomCode

    m.qrCode = m.top.findNode("qrCode")
    joinUrl = "http://192.168.86.69:3000/join?code=" + m.top.roomCode

    transfer = CreateObject("roUrlTransfer")
    encodedUrl = joinUrl
    if transfer <> invalid then
        encodedUrl = transfer.escape(joinUrl)
    end if

    m.qrCode.uri = "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=" + encodedUrl

    m.pollTask = CreateObject("roSGNode", "PlayerPollTask")
    m.pollTask.roomCode = m.top.roomCode
    m.pollTask.observeField("roomState", "onRoomUpdate")
    m.pollTask.control = "run"
end sub

sub onRoomUpdate()
    room = m.pollTask.roomState
    if room = invalid or not room.doesExist("players") then return

    content = CreateObject("roSGNode", "ContentNode")

    for each player in room.players
        item = content.createChild("ContentNode")
        item.title = player.name
        item.description = "Online"
        if player.doesExist("isConnected") and player.isConnected = false then
            item.description = "Offline - reconnecting"
        end if
    end for

    m.playerGrid.content = content

end sub

sub cleanup()
    if m.pollTask <> invalid then
        m.pollTask.control = "stop"
    end if
    if m.startVoteTask <> invalid then
        m.startVoteTask.control = "stop"
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
                    m.chrome.callFunc("applyBackButtonStyle", true)
                    m.top.sceneManager.callFunc("goBack")
                end if
            else
                m.startVoteTask.roomCode = m.top.roomCode
                m.startVoteTask.control = "run"
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

sub onVoteStarted()
    refreshButtonStyles(false)
    if m.startVoteTask.roomState <> invalid and m.top.sceneManager <> invalid then
        m.top.sceneManager.callFunc("showMiniGameVote", m.top.roomCode)
    end if
end sub
