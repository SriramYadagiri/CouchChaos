sub init()
    m.top.functionName = "startSpecificGame"
end sub

sub startSpecificGame()
    if m.top.roomCode = invalid then return
    if m.top.roomCode = "" then return
    if m.top.gameId = invalid then return
    if m.top.gameId = "" then return

    url = "http://192.168.1.104:3000/api/room/" + m.top.roomCode + "/start-game?gameId=" + m.top.gameId + "&sourceMode=" + m.top.sourceMode

    transfer = CreateObject("roUrlTransfer")
    transfer.SetUrl(url)
    transfer.SetRequest("POST")

    response = transfer.GetToString()

    if response <> invalid then
        data = ParseJson(response)
        m.top.roomState = data
    end if
end sub
