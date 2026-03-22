sub init()
    print "SceneManager Loaded..."
    m.navigationStack = []
    m.currentScreenEntry = invalid
    showMainMenu()
end sub

sub showMainMenu()
    print "showMainMenu called"
    m.navigationStack = []
    showScreen("MainMenu", invalid, false)
end sub

sub goToLobby(code as String)
    print "Go to Lobby Called"
    fields = {
        roomCode: code
    }
    showScreen("LobbyScene", fields, true)
end sub

sub showMiniGameVote(code as String)
    fields = {
        roomCode: code
    }
    showScreen("MiniGameVoteScene", fields, true)
end sub

sub showSinglePlayer()
    showScreen("SinglePlayerScene", invalid, true)
end sub

sub showSharkGame()
    showScreen("SharkGame", invalid, true)
end sub

sub goBack()
    if m.navigationStack = invalid or m.navigationStack.count() <= 0 then
        showMainMenu()
        return
    end if

    previousEntry = m.navigationStack.pop()
    showScreen(previousEntry.componentName, previousEntry.fields, false)
end sub

sub showScreen(componentName as String, fields as Dynamic, rememberCurrent as Boolean)
    currentChild = invalid
    if m.top.getChildCount() > 0 then
        currentChild = m.top.getChild(0)
    end if

    if rememberCurrent and m.currentScreenEntry <> invalid then
        m.navigationStack.push(createNavigationEntry(m.currentScreenEntry.componentName, m.currentScreenEntry.fields))
    end if

    cleanupCurrentChild()

    while m.top.getChildCount() > 0
        m.top.removeChild(m.top.getChild(0))
    end while

    nextScreen = CreateObject("roSGNode", componentName)
    nextScreen.sceneManager = m.top
    applyScreenFields(nextScreen, fields)
    m.top.appendChild(nextScreen)
    m.currentScreenEntry = createNavigationEntry(componentName, fields)
    nextScreen.setFocus(true)
end sub

sub cleanupCurrentChild()
    if m.top.getChildCount() <= 0 then return

    child = m.top.getChild(0)
    if child = invalid then return

    child.callFunc("cleanup")
end sub

function createNavigationEntry(componentName as String, fields as Dynamic) as Object
    entry = {
        componentName: componentName,
        fields: {}
    }

    if fields <> invalid and fields.doesExist("roomCode") then
        entry.fields.roomCode = fields.roomCode
    end if

    return entry
end function

sub applyScreenFields(screen as Object, fields as Dynamic)
    if fields = invalid then return

    if fields.doesExist("roomCode") then
        screen.roomCode = fields.roomCode
    end if
end sub