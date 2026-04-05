sub init()
    m.top.functionName = "startGameVote"
end sub

function startGameVote()
    url = "https://couchchaos.onrender.com/api/room/" + m.top.roomCode + "/start-game-vote?sourceMode=" + m.top.sourceMode
    transfer = CreateObject("roUrlTransfer")
    transfer.SetUrl(url)
    transfer.SetRequest("POST")
    response = transfer.GetToString()

    if response <> invalid then
        data = ParseJson(response)
        m.top.roomState = data
    end if
end function
