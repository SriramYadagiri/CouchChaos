sub init()
    m.top.functionName = "pollRoom"
end sub

function pollRoom()
    while m.top.control <> "stop"
        url = "http://192.168.1.104:3000/api/room/" + m.top.roomCode
        transfer = CreateObject("roUrlTransfer")
        transfer.SetUrl(url)

        response = transfer.GetToString()
        if response <> invalid and response <> "" then
            data = ParseJson(response)
            if data <> invalid then
                m.top.roomState = data
            end if
        end if

        if m.top.control = "stop" then exit while
        sleep(500)
    end while
end function
