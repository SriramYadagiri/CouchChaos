sub init()
    m.roomCodeLabel = m.top.findNode("roomCodeLabel")
    m.startGameBtnShadow = m.top.findNode("startGameBtnShadow")
    m.startGameBtnBg = m.top.findNode("startGameBtnBg")
    m.startGameBtnGlow = m.top.findNode("startGameBtnGlow")
    m.startGameBtnLabel = m.top.findNode("startGameBtnLabel")
    m.playerGrid = m.top.findNode("playerGrid")
    m.startVoteTask = CreateObject("roSGNode", "StartGameVoteTask")

    m.top.observeField("roomCode", "onRoomCodeSet")
    m.startVoteTask.observeField("roomState", "onVoteStarted")
    m.top.setFocus(true)
    applyStartButtonStyle(true, false)
end sub

sub onRoomCodeSet()
    print "Lobby Scene Loaded..."
    print "Room Code: "; m.top.roomCode

    m.roomCodeLabel.text = m.top.roomCode

    m.qrCode = m.top.findNode("qrCode")
    joinUrl = "http://192.168.86.69:3000/join?code=" + m.top.roomCode

    encodedUrl = joinUrl ' works fine, but better to encode
    encodedUrl = CreateObject("roUrlTransfer").escape(joinUrl)

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
    end for

    m.playerGrid.content = content

end sub

function onKeyEvent(key, press) as Boolean
    if key = "OK" then
        if press then
            applyStartButtonStyle(true, true)
            m.startVoteTask.roomCode = m.top.roomCode
            m.startVoteTask.control = "run"
            return true
        else
            applyStartButtonStyle(true, false)
            return true
        end if
    end if

    return false
end function

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
    applyStartButtonStyle(true, false)
    if m.startVoteTask.roomState <> invalid and m.top.sceneManager <> invalid then
        m.top.sceneManager.callFunc("showMiniGameVote", m.top.roomCode)
    end if
end sub
