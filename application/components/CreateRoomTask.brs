sub init()
    m.top.functionName = "createRoom"
end sub

function createRoom()

    url = "http://192.168.86.69:3000/create-room"

    transfer = CreateObject("roUrlTransfer")
    transfer.SetUrl(url)
    transfer.SetRequest("POST")

    response = transfer.GetToString()

    print response

    if response <> invalid
        data = ParseJson(response)
        m.top.roomData = data
    end if

end function