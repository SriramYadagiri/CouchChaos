sub init()
    m.createBtnShadow = m.top.findNode("createBtnShadow")
    m.createBtnBg = m.top.findNode("createBtnBg")
    m.createBtnGlow = m.top.findNode("createBtnGlow")
    m.createBtnLabel = m.top.findNode("createBtnLabel")
    m.createTipLabel = m.top.findNode("createTipLabel")
    m.createTask = createObject("roSGNode", "CreateRoomTask")
    m.createTask.observeField("roomData", "onRoomCreated")
    m.top.setFocus(true)
    applyCreateButtonStyle(true, false)
end sub

function onKeyEvent(key, press) as Boolean
    handled = false

    if key = "OK" then
        if press then
            print "OK button pressed"
            applyCreateButtonStyle(true, true)
            m.createTask.control = "RUN"
            handled = true
        else
            applyCreateButtonStyle(true, false)
            handled = true
        end if
    end if
    
    return handled
end function

sub applyCreateButtonStyle(isFocused as Boolean, isPressed as Boolean)
    if isPressed then
        m.createBtnShadow.color = "0x03070ECC"
        m.createBtnBg.translation = [220, 485]
        m.createBtnGlow.translation = [220, 485]
        m.createBtnLabel.translation = [220, 507]
    else
        m.createBtnShadow.color = "0x050D16CC"
        m.createBtnBg.translation = [212, 476]
        m.createBtnGlow.translation = [212, 476]
        m.createBtnLabel.translation = [212, 498]
    end if

    if isFocused then
        m.createBtnBg.color = "0x2ACBFFFF"
        m.createBtnGlow.color = "0xBAF3FFFF"
        m.createBtnLabel.color = "0x06111DFF"
    else
        m.createBtnBg.color = "0x1E8FFFFF"
        m.createBtnGlow.color = "0x7DE3FFFF"
        m.createBtnLabel.color = "0x06111DFF"
    end if
end sub

sub onRoomCreated()
    room = m.createTask.roomData
    applyCreateButtonStyle(true, false)
    print "Room created: "; room.code

    m.top.sceneManager.callFunc("goToLobby", room.code)
end sub
