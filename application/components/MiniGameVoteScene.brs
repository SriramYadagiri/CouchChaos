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

    if phase = "game_select" or phase = "game_selected" then
        updateGameSelectionView(room)
    else if phase = "trivia_question" then
        updateTriviaQuestionView(room)
    else if phase = "trivia_leaderboard" then
        updateLeaderboardView(room)
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

sub updateGameSelectionView(room as Object)
    setGridInteractive(true)
    configureGrid(3, 1, [320, 220], [95, 285])
    content = CreateObject("roSGNode", "ContentNode")
    signature = room.phase + "|"

    if room.doesExist("games") and room.games <> invalid then
        for each miniGame in room.games
            item = CreateObject("roSGNode", "MiniGameContentNode")
            item.cardkind = "game_vote"
            item.title = miniGame.name
            item.description = miniGame.description
            item.bodytext = miniGame.name
            item.cardwidth = 320
            item.cardheight = 220

            votes = 0
            if miniGame.doesExist("votes") then votes = miniGame.votes
            item.votecount = votes.ToStr()
            item.footertext = votes.ToStr() + " vote(s)"
            content.appendChild(item)
            signature = signature + miniGame.name + ":" + votes.ToStr() + "|"
        end for
    end if

    updateGridIfNeeded(content, signature)

    m.titleLabel.text = "Vote For The Next Minigame"

    if room.phase = "game_selected" and room.doesExist("selectedGame") and room.selectedGame <> invalid then
        m.subtitleLabel.text = "Selected minigame: " + room.selectedGame.name
    else
        m.subtitleLabel.text = "Players vote on their phones. Move focus to preview a game."
    end if

    if content.getChildCount() > 0 then
        updateFocusedDescription(m.lastFocusedIndex)
    else
        m.descriptionLabel.text = "Waiting for game options..."
    end if
end sub

sub updateTriviaQuestionView(room as Object)
    setGridInteractive(false)
    configureGrid(2, 2, [520, 160], [95, 290])
    m.titleLabel.text = "Trivia Toss"

    if room.doesExist("currentQuestion") and room.currentQuestion <> invalid then
        m.subtitleLabel.text = "Question " + room.currentQuestion.number.ToStr() + " of " + room.currentQuestion.total.ToStr()
        m.descriptionLabel.text = room.currentQuestion.prompt

        content = CreateObject("roSGNode", "ContentNode")
        signature = room.currentQuestion.number.ToStr() + "|"

        if room.currentQuestion.doesExist("options") and room.currentQuestion.options <> invalid then
            for each option in room.currentQuestion.options
                item = CreateObject("roSGNode", "MiniGameContentNode")
                item.cardkind = "trivia_option"
                item.title = ""
                item.description = option.text
                item.bodytext = option.text
                item.footertext = ""
                item.cardwidth = 520
                item.cardheight = 160
                if option.doesExist("cardColor") then item.cardcolor = option.cardColor
                content.appendChild(item)
                signature = signature + option.label + ":" + option.text + "|"
            end for
        end if

        updateGridIfNeeded(content, signature)
    else
        m.subtitleLabel.text = "Trivia Toss"
        m.descriptionLabel.text = "Waiting for the next question..."
        updateGridIfNeeded(CreateObject("roSGNode", "ContentNode"), "trivia-waiting")
    end if
end sub

sub updateLeaderboardView(room as Object)
    setGridInteractive(false)
    configureGrid(2, 2, [520, 160], [95, 290])
    content = CreateObject("roSGNode", "ContentNode")
    signature = "leaderboard|"

    if room.doesExist("leaderboard") and room.leaderboard <> invalid then
        for each entry in room.leaderboard
            item = CreateObject("roSGNode", "MiniGameContentNode")
            item.cardkind = "leaderboard"
            item.title = entry.name
            item.bodytext = ""
            item.footertext = entry.score.ToStr() + " pts"
            item.cardwidth = 520
            item.cardheight = 160
            content.appendChild(item)
            signature = signature + entry.name + ":" + entry.score.ToStr() + "|"
        end for
    end if

    updateGridIfNeeded(content, signature)
    m.titleLabel.text = "Trivia Toss Results"
    m.subtitleLabel.text = "Leaderboard"
    m.descriptionLabel.text = "Returning to minigame voting shortly."
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
