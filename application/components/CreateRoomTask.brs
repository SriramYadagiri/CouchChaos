sub init()
    m.top.functionName = "createRoom"
end sub

function createRoom()
    url = "http://192.168.1.104:3000/api/create-room"

    transfer = CreateObject("roUrlTransfer")
    transfer.SetUrl(url)
    transfer.SetRequest("POST")

    response = transfer.GetToString()
    print response

    if response <> invalid then
        data = ParseJson(response)
        m.top.roomData = data
    end if

end function
