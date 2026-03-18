sub init()
    m.top.functionName = "pollRoom"
end sub

function pollRoom()

    while true

        url = "http://192.168.86.69:3000/api/room/" + m.top.roomCode

        transfer = CreateObject("roUrlTransfer")
        transfer.SetUrl(url)

        response = transfer.GetToString()

        print "Polling URL: "; url
        print "Response: "; response

        if response <> invalid
            data = ParseJson(response)
            m.top.roomState = data
        end if

        sleep(500)

    end while

end function