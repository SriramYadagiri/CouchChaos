sub init()
    m.titleLabel = m.top.findNode("titleLabel")
    m.miniGameGrid = m.top.findNode("miniGameGrid")
    m.subtitleLabel = m.top.findNode("subtitleLabel")
    m.descriptionLabel = m.top.findNode("descriptionLabel")
    m.pollTask = CreateObject("roSGNode", "PlayerPollTask")
    m.lastFocusedIndex = 0
    m.currentGridSignature = ""
    m.currentPhase = ""

    m.top.observeField("roomCode", "onRoomCodeSet")
    m.pollTask.observeField("roomState", "onRoomUpdate")
    m.miniGameGrid.observeField("itemFocused", "onMiniGameFocused")
    setGridInteractive(true)
end sub

sub onRoomCodeSet()
    if m.top.roomCode = invalid or m.top.roomCode = "" then return

    m.pollTask.roomCode = m.top.roomCode
    m.pollTask.control = "run"
end sub

sub onRoomUpdate()
    room = m.pollTask.roomState
    if room = invalid then return

    phase = ""
    if room.doesExist("phase") then phase = room.phase
    m.currentPhase = phase

    if room.doesExist("tvView") and room.tvView <> invalid then
        updateTvView(room.tvView)
    else
        setGridInteractive(false)
        m.miniGameGrid.content = CreateObject("roSGNode", "ContentNode")
        m.titleLabel.text = "Vote For The Next Minigame"
        m.subtitleLabel.text = "Waiting for the next round."
        m.descriptionLabel.text = ""
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if m.currentPhase = "trivia_question" then
        if key = "left" or key = "right" or key = "up" or key = "down" or key = "OK" then
            return true
        end if
    end if

    return false
end function

sub onMiniGameFocused()
    if m.currentPhase <> "game_select" and m.currentPhase <> "game_selected" then return
    m.lastFocusedIndex = m.miniGameGrid.itemFocused
    updateFocusedDescription(m.lastFocusedIndex)
end sub

sub updateFocusedDescription(index as Integer)
    content = m.miniGameGrid.content
    if content = invalid then return
    if index < 0 or index >= content.getChildCount() then return

    focusedItem = content.getChild(index)
    if focusedItem = invalid then return

    description = ""
    if focusedItem.doesExist("description") then
        description = focusedItem.description
    end if

    if focusedItem.doesExist("votecount") then
        description = description + " Votes: " + focusedItem.votecount
    end if

    m.descriptionLabel.text = description
end sub

sub updateTvView(tvView as Object)
    layout = ""
    if tvView.doesExist("layout") then layout = tvView.layout

    if layout = "game_vote" then
        renderCardGrid(tvView, true, 3, 1, [320, 220], [95, 285], "game_vote")
    else if layout = "trivia_question" then
        renderCardGrid(tvView, false, 2, 2, [520, 160], [95, 290], "trivia_option")
    else if layout = "leaderboard" then
        renderCardGrid(tvView, false, 2, 2, [520, 160], [95, 290], "leaderboard")
    else if layout = "player_grid" then
        renderCardGrid(tvView, false, 2, 2, [520, 160], [95, 290], "leaderboard")
    else
        setGridInteractive(false)
        m.titleLabel.text = tvView.title
        m.subtitleLabel.text = tvView.subtitle
        m.descriptionLabel.text = tvView.description
        updateGridIfNeeded(CreateObject("roSGNode", "ContentNode"), "message|" + tvView.title + "|" + tvView.subtitle + "|" + tvView.description)
    end if
end sub

sub renderCardGrid(tvView as Object, interactive as Boolean, numColumns as Integer, numRows as Integer, itemSize as Object, translation as Object, cardKind as String)
    setGridInteractive(interactive)
    configureGrid(numColumns, numRows, itemSize, translation)
    content = CreateObject("roSGNode", "ContentNode")
    signature = cardKind + "|"

    if tvView.doesExist("cards") and tvView.cards <> invalid then
        for each card in tvView.cards
            item = CreateObject("roSGNode", "MiniGameContentNode")
            item.cardkind = cardKind
            item.title = ""
            item.description = ""
            item.bodytext = ""
            item.footertext = ""
            if card.doesExist("title") then item.title = card.title
            if card.doesExist("description") then
                item.description = card.description
                item.bodytext = card.description
            end if
            if card.doesExist("footer") then item.footertext = card.footer
            item.cardwidth = itemSize[0]
            item.cardheight = itemSize[1]
            if card.doesExist("cardColor") then item.cardcolor = card.cardColor
            if interactive and card.doesExist("footer") then item.votecount = card.footer
            content.appendChild(item)
            signature = signature + item.title + "|" + item.bodytext + "|" + item.footertext + "|"
        end for
    end if

    updateGridIfNeeded(content, signature)
    m.titleLabel.text = tvView.title
    m.subtitleLabel.text = tvView.subtitle
    m.descriptionLabel.text = tvView.description

    if interactive and content.getChildCount() > 0 then
        updateFocusedDescription(m.lastFocusedIndex)
    end if
end sub

sub configureGrid(numColumns as Integer, numRows as Integer, itemSize as Object, translation as Object)
    m.miniGameGrid.numColumns = numColumns
    m.miniGameGrid.numRows = numRows
    m.miniGameGrid.itemSize = itemSize
    m.miniGameGrid.translation = translation
    if numColumns = 2 and numRows = 2 then
        m.miniGameGrid.itemSpacing = [20, 20]
    else
        m.miniGameGrid.itemSpacing = [30, 30]
    end if
end sub

sub setGridInteractive(isInteractive as Boolean)
    m.miniGameGrid.drawFocusFeedback = isInteractive
    if isInteractive then
        m.miniGameGrid.setFocus(true)
    else
        m.top.setFocus(true)
    end if
end sub

sub updateGridIfNeeded(content as Object, signature as String)
    if signature = m.currentGridSignature then return
    m.currentGridSignature = signature
    setGridContentPreservingFocus(content)
end sub

sub setGridContentPreservingFocus(content as Object)
    targetIndex = m.lastFocusedIndex

    m.miniGameGrid.content = content

    itemCount = content.getChildCount()
    if itemCount <= 0 then
        m.lastFocusedIndex = 0
        return
    end if

    if targetIndex < 0 then targetIndex = 0
    if targetIndex >= itemCount then targetIndex = itemCount - 1

    m.lastFocusedIndex = targetIndex
    m.miniGameGrid.jumpToItem = targetIndex
end sub
