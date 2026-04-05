sub init()
    m.chrome = m.top.findNode("chrome")
    m.roomCodeLabel = m.top.findNode("roomCodeLabel")
    m.joinHintLabel = m.top.findNode("joinHintLabel")
    m.startHintLabel = m.top.findNode("startHintLabel")
    m.startGameButton = m.top.findNode("startGameButton")
    m.playerGrid = m.top.findNode("playerGrid")
    m.focusTarget = "start"
    m.serverBase = "https://couchchaos.onrender.com"

    m.pollTask = CreateObject("roSGNode", "PlayerPollTask")
    m.connectedCount = 0
    m.startVoteTask = CreateObject("roSGNode", "StartGameVoteTask")
    m.startTask = CreateObject("roSGNode", "StartSpecificGameTask")

    m.top.observeField("roomCode", "onRoomCodeSet")
    m.top.observeField("gameMode", "onGameModeSet")
    m.pollTask.observeField("roomState", "onRoomUpdate")
    m.startVoteTask.observeField("roomState", "onVoteStarted")
    m.startTask.observeField("roomState", "onGameStarted")
    applyModeContent()
    m.top.setFocus(true)
    refreshButtonStyles(false)
end sub

sub onGameModeSet()
    applyModeContent()
end sub

sub applyModeContent()
    mode = getGameMode()

    if mode = "couch_chaos" then
        m.chrome.title = "Couch Chaos Lobby"
        m.chrome.subtitle = "Players appear on the right as they connect."
        m.chrome.bodyText = "Start with Trivia Toss, Word Sandwiches, Imposter, or Word Match."
        m.joinHintLabel.text = "Scan the code or enter the room code on your phone to join Couch Chaos."
        m.startGameButton.text = "Choose Starting Game"
        m.startHintLabel.text = "The TV host can open the Couch Chaos picker and start any multiplayer game right away."
    else if mode = "trivia-toss" then
        m.chrome.title = "Trivia Toss Lobby"
        m.chrome.subtitle = "Players join on their phones, then the host starts the trivia round."
        m.chrome.bodyText = "Fast party trivia with color-coded answers and TV score reveals."
        m.joinHintLabel.text = "Scan the code or enter the room code on your phone to join Trivia Toss."
        m.startGameButton.text = "Start Trivia Toss"
        m.startHintLabel.text = "Once at least one player joins, the host can start the round from the TV."
    else if mode = "word-sandwiches" then
        m.chrome.title = "Word Sandwiches Lobby"
        m.chrome.subtitle = "Players join on their phones, then race to build words around the center letters."
        m.chrome.bodyText = "Balanced sandwiches earn a bonus."
        m.joinHintLabel.text = "Scan the code or enter the room code on your phone to join Word Sandwiches."
        m.startGameButton.text = "Start Word Sandwiches"
        m.startHintLabel.text = "Once players are in, the host can start the puzzle round from the TV."
    else if mode = "imposter" then
        m.chrome.title = "Imposter Lobby"
        m.chrome.subtitle = "Players join on their phones, get their secret role, and wait for the host."
        m.chrome.bodyText = "At least 3 players are recommended. Everyone except one player will know the word."
        m.joinHintLabel.text = "Scan the code or enter the room code on your phone to join Imposter."
        m.startGameButton.text = "Start Imposter"
        m.startHintLabel.text = "The TV will show whose turn it is, the vote flow, and the final reveal."
    else if mode = "word-match" then
        m.chrome.title = "Word Match Lobby"
        m.chrome.subtitle = "Players join on their phones, then race to solve the same hidden word."
        m.chrome.bodyText = "Score rewards quick solves and fewer tries. Everyone gets the same word each round."
        m.joinHintLabel.text = "Scan the code or enter the room code on your phone to join Word Match."
        m.startGameButton.text = "Start Word Match"
        m.startHintLabel.text = "Word Match can start with one player. Green means right spot, yellow means wrong spot, and gray means the letter is not in the word."
    end if
end sub

function getGameMode() as String
    if m.top.gameMode = invalid or m.top.gameMode = "" then return "couch_chaos"
    return m.top.gameMode
end function

sub onRoomCodeSet()
    if m.top.roomCode = invalid or m.top.roomCode = "" then return

    m.roomCodeLabel.text = m.top.roomCode

    m.qrCode = m.top.findNode("qrCode")
    joinUrl = m.serverBase + "/join?code=" + m.top.roomCode

    transfer = CreateObject("roUrlTransfer")
    encodedUrl = joinUrl
    if transfer <> invalid then
        encodedUrl = transfer.escape(joinUrl)
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
    m.connectedCount = connectedCount

    mode = getGameMode()
    subtitle = connectedCount.ToStr() + " player(s) connected. "
    if mode = "imposter" and connectedCount < 3 then
        subtitle = subtitle + "3 or more players is best for a full round."
    else if connectedCount = 0 then
        subtitle = subtitle + "Players can join by scanning the QR code."
    else if mode = "word-match" and connectedCount = 1 then
        subtitle = subtitle + "One player is enough to start Word Match."
    else
        subtitle = subtitle + "Ready to start whenever you are."
    end if
    if m.chrome <> invalid then
        m.chrome.bodyText = subtitle
    end if
end sub

sub cleanup()
    if m.pollTask <> invalid then m.pollTask.control = "stop"
    if m.startVoteTask <> invalid then m.startVoteTask.control = "stop"
    if m.startTask <> invalid then m.startTask.control = "stop"
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
                mode = getGameMode()
                if m.connectedCount <= 0 then
                    if m.chrome <> invalid then m.chrome.bodyText = "At least one player needs to join before you can start."
                    refreshButtonStyles(false)
                    return true
                end if

                if mode = "imposter" and m.connectedCount < 3 then
                    if m.chrome <> invalid then m.chrome.bodyText = "Imposter needs at least 3 connected players before the host can start."
                    refreshButtonStyles(false)
                    return true
                end if

                if mode = "couch_chaos" then
                    m.startVoteTask.roomCode = m.top.roomCode
                    m.startVoteTask.sourceMode = mode
                    m.startVoteTask.control = "run"
                else
                    m.startTask.roomCode = m.top.roomCode
                    m.startTask.gameId = mode
                    m.startTask.sourceMode = mode
                    m.startTask.control = "run"
                end if
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
        m.top.sceneManager.callFunc("showMiniGameVote", m.top.roomCode, getGameMode())
    end if
end sub

sub onGameStarted()
    refreshButtonStyles(false)
    if m.top.sceneManager <> invalid then
        m.top.sceneManager.callFunc("showMiniGameVote", m.top.roomCode, getGameMode())
    end if
end sub
