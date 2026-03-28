sub init()
    m.top.functionName = "pollRoom"
end sub

function pollRoom()
    while m.top.control <> "stop"

        url = "http://192.168.1.104:3000/api/room/" + m.top.roomCode

        transfer = CreateObject("roUrlTransfer")
        transfer.SetUrl(url)

        response = transfer.GetToString()

        print "Polling URL: "; url
        print "Response: "; response

        if response <> invalid
            data = ParseJson(response)
            m.top.roomState = data
        end if

        if m.top.control = "stop" then exit while
        sleep(500)

    end while

end function
