sub init()
    m.chrome = m.top.findNode("chrome")
    m.singlePlayerButton = m.top.findNode("singlePlayerButton")
    m.createButton = m.top.findNode("createButton")
    m.createTask = createObject("roSGNode", "CreateRoomTask")
    m.createTask.observeField("roomData", "onRoomCreated")
    m.currentFocus = "singlePlayer"
    m.singlePlayerButton.isFocused = true
    m.createButton.isFocused = false
end sub

function onKeyEvent(key, press) as Boolean
    handled = false

    if press then
        if key = "OK" then
            if m.currentFocus = "create" then
                print "Create Room button pressed"
                m.createButton.isPressed = true
                m.createTask.control = "RUN"
            else if m.currentFocus = "singlePlayer" then
                print "Single Player Games button pressed"
                m.singlePlayerButton.isPressed = true
                if m.top.sceneManager <> invalid then
                    m.top.sceneManager.callFunc("showSinglePlayer")
                end if
            end if
            handled = true
        else if key = "down" then
            if m.currentFocus = "singlePlayer" then
                m.currentFocus = "create"
                m.singlePlayerButton.isFocused = false
                m.createButton.isFocused = true
                handled = true
            end if
        else if key = "up" then
            if m.currentFocus = "create" then
                m.currentFocus = "singlePlayer"
                m.createButton.isFocused = false
                m.singlePlayerButton.isFocused = true
                handled = true
            end if
        end if
    else
        if key = "OK" then
            if m.currentFocus = "create" then
                m.createButton.isPressed = false
            else if m.currentFocus = "singlePlayer" then
                m.singlePlayerButton.isPressed = false
            end if
            handled = true
        end if
    end if
    
    return handled
end function

sub applyCreateButtonStyle(isFocused as Boolean, isPressed as Boolean)
    m.createButton.isFocused = isFocused
    m.createButton.isPressed = isPressed
end sub

sub onRoomCreated()
    room = m.createTask.roomData
    m.createButton.isPressed = false
    print "Room created: "; room.code

    m.top.sceneManager.callFunc("goToLobby", room.code)
end sub

sub cleanup()
end sub
