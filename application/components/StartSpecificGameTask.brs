sub init()
    m.top.functionName = "startSpecificGame"
    m.serverBase = "https://couchchaos.onrender.com"
end sub

sub startSpecificGame()
    if m.top.roomCode = invalid then return
    if m.top.roomCode = "" then return
    if m.top.gameId = invalid then return
    if m.top.gameId = "" then return

    transfer = CreateObject("roUrlTransfer")
    sourceMode = ""
    if m.top.sourceMode <> invalid then sourceMode = m.top.sourceMode

    query = "gameId=" + transfer.Escape(m.top.gameId)
    if sourceMode <> "" then
        query = query + "&sourceMode=" + transfer.Escape(sourceMode)
    end if

    url = m.serverBase + "/api/room/" + m.top.roomCode + "/start-game?" + query
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
