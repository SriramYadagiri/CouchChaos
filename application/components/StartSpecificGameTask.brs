sub init()
    m.top.functionName = "startSpecificGame"
end sub

sub startSpecificGame()
    if m.top.roomCode = invalid then return
    if m.top.roomCode = "" then return
    if m.top.gameId = invalid then return
    if m.top.gameId = "" then return

    url = "https://couchchaos.onrender.com/api/room/" + m.top.roomCode + "/start-game?gameId=" + m.top.gameId + "&sourceMode=" + m.top.sourceMode

    transfer = CreateObject("roUrlTransfer")
    sourceMode = ""
    if m.top.sourceMode <> invalid then sourceMode = m.top.sourceMode

    query = "gameId=" + transfer.Escape(m.top.gameId)
    if sourceMode <> "" then
        query = query + "&sourceMode=" + transfer.Escape(sourceMode)
    end if

    url = "http://192.168.1.104:3000/api/room/" + m.top.roomCode + "/start-game?" + query
    transfer.SetUrl(url)
    transfer.SetRequest("POST")

    response = transfer.GetToString()
    if response <> invalid and response <> "" then
        data = ParseJson(response)
        if data <> invalid then
            m.top.roomState = data
        end if
    end if
end sub
