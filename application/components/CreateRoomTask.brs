sub init()
    m.top.functionName = "createRoom"
end sub

function createRoom()
    url = "http://192.168.1.104:3000/api/create-room"

    transfer = CreateObject("roUrlTransfer")
    transfer.SetUrl(url)
    transfer.SetRequest("POST")

    response = transfer.GetToString()
    if response <> invalid and response <> "" then
        data = ParseJson(response)
        if data <> invalid then
            m.top.roomData = data
        end if
    end if
end function
