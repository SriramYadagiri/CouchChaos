sub init()

    m.roomCodeLabel = m.top.findNode("roomCodeLabel")
    m.playersLabel = m.top.findNode("playersLabel")

    m.top.observeField("roomCode", "onRoomCodeSet")

end sub

sub onRoomCodeSet()
    roomCode = m.top.roomCode
    print "Lobby Scene Loaded..."
    print "Room Code: "; m.top.roomCode
    
    m.roomCodeLabel.text = "Room Code: " + m.top.roomCode

    m.pollTask = createObject("roSGNode", "PlayerPollTask")
    m.pollTask.roomCode = m.top.roomCode

    m.pollTask.observeField("roomState", "onRoomUpdate")
    m.pollTask.control = "run"
    
end sub

sub onRoomUpdate()
    room = m.pollTask.roomState
    if room = invalid or not room.doesExist("players") then return

    text = "Players:\n"

    for each player in room.players
        text = text + player.name + "\n"
    end for

    m.playersLabel.text = text

end sub