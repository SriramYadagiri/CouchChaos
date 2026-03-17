sub init()

    m.createBtn = m.top.findNode("createBtn")

    m.createBtn.setFocus(true)

    m.createTask = createObject("roSGNode", "CreateRoomTask")
    m.createTask.observeField("roomData", "onRoomCreated")

end sub

function onKeyEvent(key, press) as Boolean
    handled = false

    if key = "OK" and press then
        print "OK button pressed"
        m.createTask.control = "RUN"

        handled = true
    end if
    
    return handled
end function

sub onRoomCreated()

    room = m.createTask.roomData
    print "Room created: "; room.code

    m.top.sceneManager.callFunc("goToLobby", room.code)

end sub