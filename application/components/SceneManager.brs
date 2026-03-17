sub init()
    print "SceneManager Loaded..."
    showMainMenu()
end sub


sub showMainMenu()

    print "showMainMenu called"
    
    menu = CreateObject("roSGNode", "MainMenu")
    menu.sceneManager = m.top

    m.top.appendChild(menu)
    menu.setFocus(true)

end sub


sub goToLobby(code as String)

    print "Go to Lobby Called"

    ' remove existing screen
    while m.top.getChildCount() > 0
        m.top.removeChild(m.top.getChild(0))
    end while

    lobby = CreateObject("roSGNode", "LobbyScene")
    lobby.sceneManager = m.top
    lobby.roomCode = code

    m.top.appendChild(lobby)
    lobby.setFocus(true)

end sub