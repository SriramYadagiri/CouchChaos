sub init()
    m.playerName = m.top.findNode("playerName")
end sub

sub onContentChanged()
    item = m.top.itemContent
    if item <> invalid and item.doesExist("title") then
        m.playerName.text = item.title
    end if
end sub