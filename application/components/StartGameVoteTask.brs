sub init()
    m.top.functionName = "startGameVote"
end sub

function startGameVote()
    url = "http://192.168.86.69:3000/api/room/" + m.top.roomCode + "/start-game-vote"

    transfer = CreateObject("roUrlTransfer")
    transfer.SetUrl(url)
    transfer.SetRequest("POST")

    response = transfer.GetToString()

    if response <> invalid
        data = ParseJson(response)
        m.top.roomState = data
    end if
end function
