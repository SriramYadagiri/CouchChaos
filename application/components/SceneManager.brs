sub init()
    print "SceneManager Loaded..."
    showMainMenu()
end sub

sub showMainMenu()
    print "showMainMenu called"

    cleanupCurrentChild()

    while m.top.getChildCount() > 0
        m.top.removeChild(m.top.getChild(0))
    end while

    menu = CreateObject("roSGNode", "MainMenu")
    menu.sceneManager = m.top

    m.top.appendChild(menu)
    menu.setFocus(true)
end sub

sub goToLobby(code as String)
    print "Go to Lobby Called"

    cleanupCurrentChild()

    while m.top.getChildCount() > 0
        m.top.removeChild(m.top.getChild(0))
    end while

    lobby = CreateObject("roSGNode", "LobbyScene")
    lobby.sceneManager = m.top
    lobby.roomCode = code

    m.top.appendChild(lobby)
    lobby.setFocus(true)
end sub

sub showMiniGameVote(code as String)
    cleanupCurrentChild()

    while m.top.getChildCount() > 0
        m.top.removeChild(m.top.getChild(0))
    end while

    miniGameVote = CreateObject("roSGNode", "MiniGameVoteScene")
    miniGameVote.sceneManager = m.top
    miniGameVote.roomCode = code

    m.top.appendChild(miniGameVote)
    miniGameVote.setFocus(true)
end sub

sub cleanupCurrentChild()
    if m.top.getChildCount() <= 0 then return

    child = m.top.getChild(0)
    if child = invalid then return

    child.callFunc("cleanup")
end sub
