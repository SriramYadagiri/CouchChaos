sub init()
    m.roomCodeLabel = m.top.findNode("roomCodeLabel")
    m.backBtnShadow = m.top.findNode("backBtnShadow")
    m.backBtnBg = m.top.findNode("backBtnBg")
    m.backBtnGlow = m.top.findNode("backBtnGlow")
    m.backBtnLabel = m.top.findNode("backBtnLabel")
    m.startGameBtnShadow = m.top.findNode("startGameBtnShadow")
    m.startGameBtnBg = m.top.findNode("startGameBtnBg")
    m.startGameBtnGlow = m.top.findNode("startGameBtnGlow")
    m.startGameBtnLabel = m.top.findNode("startGameBtnLabel")
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
            m.top.sceneManager.callFunc("showMainMenu")
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
                    m.top.sceneManager.callFunc("showMainMenu")
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
    if isPressed then
        m.backBtnShadow.color = "0x03070ECC"
        m.backBtnBg.translation = [68, 42]
        m.backBtnGlow.translation = [68, 42]
        m.backBtnLabel.translation = [68, 57]
    else
        m.backBtnShadow.color = "0x050D16CC"
        m.backBtnBg.translation = [60, 34]
        m.backBtnGlow.translation = [60, 34]
        m.backBtnLabel.translation = [60, 49]
    end if

    if isFocused then
        m.backBtnBg.color = "0x2ACBFFFF"
        m.backBtnGlow.color = "0xBAF3FFFF"
        m.backBtnLabel.color = "0x06111DFF"
    else
        m.backBtnBg.color = "0x224563FF"
        m.backBtnGlow.color = "0x7DA8CCFF"
        m.backBtnLabel.color = "0xDCEBFAFF"
    end if
end sub

sub applyStartButtonStyle(isFocused as Boolean, isPressed as Boolean)
    if isPressed then
        m.startGameBtnShadow.color = "0x03070ECC"
        m.startGameBtnBg.translation = [0, 402]
        m.startGameBtnGlow.translation = [0, 402]
        m.startGameBtnLabel.translation = [0, 420]
    else
        m.startGameBtnShadow.color = "0x050D16CC"
        m.startGameBtnBg.translation = [0, 394]
        m.startGameBtnGlow.translation = [0, 394]
        m.startGameBtnLabel.translation = [0, 412]
    end if

    if isFocused then
        m.startGameBtnBg.color = "0x2ACBFFFF"
        m.startGameBtnGlow.color = "0xBAF3FFFF"
        m.startGameBtnLabel.color = "0x06111DFF"
    else
        m.startGameBtnBg.color = "0x1E8FFFFF"
        m.startGameBtnGlow.color = "0x7DE3FFFF"
        m.startGameBtnLabel.color = "0x06111DFF"
    end if
end sub

sub onVoteStarted()
    refreshButtonStyles(false)
    if m.startVoteTask.roomState <> invalid and m.top.sceneManager <> invalid then
        m.top.sceneManager.callFunc("showMiniGameVote", m.top.roomCode)
    end if
end sub
