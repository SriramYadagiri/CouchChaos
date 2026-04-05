sub init()
    m.chrome = m.top.findNode("chrome")
    m.gameGrid = m.top.findNode("gameGrid")
    m.createTask = CreateObject("roSGNode", "CreateRoomTask")
    m.createTask.observeField("roomData", "onRoomCreated")
    m.pendingPartyMode = ""
    m.isCreatingRoom = false

    m.games = [
        {
            id: "couch_chaos",
            title: "Couch Chaos",
            description: "Party bundle. Host Trivia Toss, Word Sandwiches, Imposter, or Word Match from one shared room.",
            footer: "Party Hub"
        },
        {
            id: "trivia-toss",
            title: "Trivia Toss",
            description: "Fast multiplayer trivia. Players answer on phones while the TV handles questions and scoring.",
            footer: "Party Game"
        },
        {
            id: "word-sandwiches",
            title: "Word Sandwiches",
            description: "Find words around the center letters on your phone while the TV tracks the leaderboard.",
            footer: "Party Game"
        },
        {
            id: "imposter",
            title: "Imposter",
            description: "One player does not know the word. Give clues, vote carefully, and catch the imposter.",
            footer: "Party Game"
        },
        {
            id: "word-match",
            title: "Word Match",
            description: "Everyone guesses the same hidden word on their phone. Faster solves with fewer tries score higher.",
            footer: "Party Game"
        },
        {
            id: "shark_game",
            title: "Fish Race",
            description: "Single player TV game. Dodge the incoming hazards and survive as long as possible.",
            footer: "TV Game"
        },
        {
            id: "karaoke",
            title: "Karaoke",
            description: "TV lyrics mode. Follow the words on screen at a steady pace for a sing-along session.",
            footer: "TV Game"
        },
        {
            id: "remote_coach",
            title: "Remote Coach",
            description: "A coordination trainer for Roku remotes. Move to the highlighted tile and press OK as quickly as you can.",
            footer: "TV Game"
        }
    ]

    populateGrid()
    m.gameGrid.observeField("itemFocused", "onGameFocused")
    activate()
end sub

sub activate()
    if m.gameGrid = invalid then return

    index = m.gameGrid.itemFocused
    if index = invalid or index < 0 or index >= m.games.Count() then
        index = 0
    end if

    m.gameGrid.jumpToItem = index
    m.gameGrid.setFocus(true)
    updateFocusedDescription(index)
end sub

sub cleanup()
end sub

sub populateGrid()
    content = CreateObject("roSGNode", "ContentNode")

    for each game in m.games
        item = CreateObject("roSGNode", "MiniGameContentNode")
        item.cardkind = "status_grid"
        item.title = game.title
        item.description = game.description
        item.bodytext = game.description
        item.footertext = game.footer
        item.cardwidth = 256
        item.cardheight = 176
        content.appendChild(item)
    end for

    m.gameGrid.content = content
    m.gameGrid.jumpToItem = 0
    updateFocusedDescription(0)
end sub

sub onGameFocused()
    updateFocusedDescription(m.gameGrid.itemFocused)
end sub

sub updateFocusedDescription(index as Integer)
    if index < 0 or index >= m.games.Count() then return

    game = m.games[index]
    if m.chrome <> invalid then
        m.chrome.bodyText = game.description + "  " + game.footer
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "OK" then
        launchSelectedGame()
        return true
    end if

    return false
end function

sub launchSelectedGame()
    if m.isCreatingRoom then return

    index = m.gameGrid.itemFocused
    if index < 0 or index >= m.games.Count() then return

    game = m.games[index]

    if game.footer = "Party Game" or game.id = "couch_chaos" then
        m.pendingPartyMode = game.id
        m.isCreatingRoom = true
        if m.chrome <> invalid then
            m.chrome.subtitle = "Creating room..."
        end if
        m.createTask.control = "RUN"
        return
    end if

    if game.id = "shark_game" then
        if m.top.sceneManager <> invalid then m.top.sceneManager.callFunc("showSharkGame")
    else if game.id = "karaoke" then
        if m.top.sceneManager <> invalid then m.top.sceneManager.callFunc("showKaraoke")
    else if game.id = "remote_coach" then
        if m.top.sceneManager <> invalid then m.top.sceneManager.callFunc("showRemoteCoach")
    end if
end sub

sub onRoomCreated()
    room = m.createTask.roomData
    m.isCreatingRoom = false
    if m.chrome <> invalid then
        m.chrome.subtitle = "Pick any game directly, or open Couch Chaos for the full party bundle."
    end if

    if room = invalid or not room.doesExist("code") then return

    mode = m.pendingPartyMode
    if mode = "" then mode = "couch_chaos"
    if m.top.sceneManager <> invalid then
        m.top.sceneManager.callFunc("showPartyLobby", room.code, mode)
    end if
end sub
