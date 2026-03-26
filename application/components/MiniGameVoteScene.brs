sub init()
    m.chrome = m.top.findNode("chrome")
    m.miniGameGrid = m.top.findNode("miniGameGrid")
    m.timerTrack = m.top.findNode("timerTrack")
    m.timerFill = m.top.findNode("timerFill")
    m.wordSandwichLetters = m.top.findNode("wordSandwichLetters")
    m.triviaTimer = m.top.findNode("triviaTimer")
    m.returnVoteButton = m.top.findNode("returnVoteButton")
    m.pollTask = CreateObject("roSGNode", "PlayerPollTask")
    m.startVoteTask = CreateObject("roSGNode", "StartGameVoteTask")
    m.lastFocusedIndex = 0
    m.currentGridSignature = ""
    m.currentPhase = ""
    m.isReturnButtonVisible = false
    m.focusTarget = "grid"
    m.triviaQuestionKey = ""
    m.triviaQuestionEndsAt = invalid
    m.triviaQuestionDurationMs = 0
    m.triviaCountdown = invalid
    m.top.observeField("roomCode", "onRoomCodeSet")
    m.pollTask.observeField("roomState", "onRoomUpdate")
    m.startVoteTask.observeField("roomState", "onReturnVoteStarted")
    m.triviaTimer.observeField("fire", "onTriviaTimerTick")
    m.miniGameGrid.observeField("itemFocused", "onMiniGameFocused")
    setGridInteractive(true)
    applyBackButtonStyle(false, false)
    showReturnVoteButton(false)
end sub

sub onRoomCodeSet()
    if m.top.roomCode = invalid or m.top.roomCode = "" then return

    m.pollTask.roomCode = m.top.roomCode
    m.pollTask.control = "run"
end sub

sub cleanup()
    if m.pollTask <> invalid then
        m.pollTask.control = "stop"
    end if
    if m.startVoteTask <> invalid then
        m.startVoteTask.control = "stop"
    end if
    if m.triviaTimer <> invalid then
        m.triviaTimer.control = "stop"
    end if
    m.triviaCountdown = invalid
end sub

sub onRoomUpdate()
    room = m.pollTask.roomState
    if room = invalid then return

    phase = ""
    if room.doesExist("phase") then phase = room.phase
    m.currentPhase = phase
    m.currentRoom = room

    if room.doesExist("tvView") and room.tvView <> invalid then
        updateTvView(room.tvView)
    else
        setTriviaTimerState(invalid, 0)
        showWordSandwichLetters("", false)
        setGridInteractive(false)
        m.miniGameGrid.content = CreateObject("roSGNode", "ContentNode")
        setChromeText("Vote For The Next Minigame", "Waiting for the next round.", "")
    end if

    showReturnVoteButton(phase = "trivia_leaderboard" or phase = "imposter_result")
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if key = "back" and press then
        if m.top.sceneManager <> invalid then
            applyBackButtonStyle(true, true)
            m.top.sceneManager.callFunc("goBack")
        end if
        return true
    else if key = "back" and not press then
        applyBackButtonStyle(false, false)
        return true
    end if

    if not press then return false

    if not m.isReturnButtonVisible and (m.currentPhase = "game_select" or m.currentPhase = "game_selected") then
        if (key = "up" or key = "left") and m.focusTarget = "grid" then
            m.focusTarget = "back"
            setGridInteractive(false)
            applyBackButtonStyle(true, false)
            return true
        else if (key = "down" or key = "right") and m.focusTarget = "back" then
            m.focusTarget = "grid"
            applyBackButtonStyle(false, false)
            setGridInteractive(true)
            return true
        else if key = "OK" and m.focusTarget = "back" then
            applyBackButtonStyle(true, true)
            if m.top.sceneManager <> invalid then
                m.top.sceneManager.callFunc("goBack")
            end if
            return true
        end if
    end if

    if m.isReturnButtonVisible then
        if key = "OK" then
            applyReturnVoteButtonStyle(true)
            m.startVoteTask.roomCode = m.top.roomCode
            m.startVoteTask.control = "run"
            return true
        else if key = "left" or key = "right" or key = "up" or key = "down" then
            return true
        end if
    end if

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

sub onReturnVoteStarted()
    applyReturnVoteButtonStyle(false)
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

    if m.chrome <> invalid then
        m.chrome.bodyText = description
    end if
end sub

sub updateTvView(tvView as Object)
    layout = ""
    if tvView.doesExist("layout") then layout = tvView.layout

    if layout = "game_vote" then
        setTriviaTimerState(invalid, 0)
        showWordSandwichLetters("", false)
        renderCardGrid(tvView, true, 3, 1, [320, 220], [95, 242], "game_vote")

    else if layout = "trivia_question" then
        questionEndsAt = invalid
        questionDurationMs = 0
        if tvView.doesExist("questionEndsAt") then questionEndsAt = tvView.questionEndsAt
        if tvView.doesExist("questionDurationMs") then questionDurationMs = tvView.questionDurationMs
        setTriviaTimerState(questionEndsAt, questionDurationMs)
        showWordSandwichLetters("", false)

        ' Build subtitle including answer count
        subtitle = tvView.subtitle
        if tvView.doesExist("answerCount") and tvView.doesExist("totalPlayers") then
            subtitle = subtitle + " · " + tvView.answerCount.ToStr() + "/" + tvView.totalPlayers.ToStr() + " answered"
        end if

        ' Temporarily override subtitle for rendering
        patchedView = buildPatchedView(tvView, subtitle)
        renderCardGrid(patchedView, false, 2, 2, [520, 160], [95, 242], "trivia_option")

    else if layout = "trivia_reveal" then
        ' Show correct answer overlay — stop timer bar
        setTriviaTimerState(invalid, 0)
        showWordSandwichLetters("", false)

        subtitle = tvView.subtitle
        if tvView.doesExist("answerCount") and tvView.doesExist("totalPlayers") then
            subtitle = subtitle + " · " + tvView.answerCount.ToStr() + "/" + tvView.totalPlayers.ToStr() + " answered"
        end if
        if tvView.doesExist("correctColor") and tvView.correctColor <> invalid then
            subtitle = subtitle + " · Correct: " + UCase(tvView.correctColor)
        end if

        patchedView = buildPatchedView(tvView, subtitle)
        renderCardGrid(patchedView, false, 2, 2, [520, 160], [95, 242], "trivia_reveal")

    else if layout = "trivia_leaderboard" then
        setTriviaTimerState(invalid, 0)
        showWordSandwichLetters("", false)
        ' Use a tall single-column leaderboard bar layout
        renderLeaderboardBars(tvView)

    else if layout = "word_sandwiches" then
        setTriviaTimerState(invalid, 0)
        renderWordSandwichesBoard(tvView)

    else if layout = "word_sandwiches_results" then
        setTriviaTimerState(invalid, 0)
        renderWordSandwichesBoard(tvView)

    else if layout = "leaderboard" then
        setTriviaTimerState(invalid, 0)
        showWordSandwichLetters("", false)
        renderCardGrid(tvView, false, 2, 2, [520, 160], [95, 242], "leaderboard")

    else if layout = "player_grid" then
        setTriviaTimerState(invalid, 0)
        showWordSandwichLetters("", false)
        renderCardGrid(tvView, false, 2, 2, [520, 160], [95, 242], "leaderboard")

    else
        setTriviaTimerState(invalid, 0)
        showWordSandwichLetters("", false)
        setGridInteractive(false)
        setChromeText(tvView.title, tvView.subtitle, tvView.description)
        updateGridIfNeeded(CreateObject("roSGNode", "ContentNode"), "message|" + tvView.title + "|" + tvView.subtitle + "|" + tvView.description)
    end if
end sub

' Build a lightweight patched view AA with a replacement subtitle
function buildPatchedView(tvView as Object, newSubtitle as String) as Object
    patched = {}
    patched.layout = tvView.layout
    patched.title = tvView.title
    patched.subtitle = newSubtitle
    if tvView.doesExist("description") then patched.description = tvView.description else patched.description = ""
    if tvView.doesExist("cards") then patched.cards = tvView.cards else patched.cards = []
    if tvView.doesExist("questionEndsAt") then patched.questionEndsAt = tvView.questionEndsAt
    if tvView.doesExist("questionDurationMs") then patched.questionDurationMs = tvView.questionDurationMs
    return patched
end function

' Render horizontal bar leaderboard for end-of-game results
sub renderLeaderboardBars(tvView as Object)
    setGridInteractive(false)
    showWordSandwichLetters("", false)

    ' Determine max score for scaling bars
    maxScore = 1
    if tvView.doesExist("maxScore") and tvView.maxScore > 0 then
        maxScore = tvView.maxScore
    end if

    ' Build content nodes — each card gets a barRatio field
    content = CreateObject("roSGNode", "ContentNode")
    signature = "trivia_leaderboard|"

    cards = []
    if tvView.doesExist("cards") and tvView.cards <> invalid then
        cards = tvView.cards
    end if

    for each card in cards
        item = CreateObject("roSGNode", "MiniGameContentNode")
        item.cardkind = "leaderboard_bar"
        item.title = ""
        if card.doesExist("title") then item.title = card.title
        item.footertext = ""
        if card.doesExist("footer") then item.footertext = card.footer

        ' Pack score and bar ratio into the description field as "score|ratio"
        barRatio = 0
        if card.doesExist("barRatio") then barRatio = card.barRatio
        score = 0
        if card.doesExist("score") then score = card.score
        item.description = score.ToStr() + "|" + barRatio.ToStr()

        ' Character info
        if card.doesExist("character") and card.character <> invalid then
            item.bodytext = card.character
        else
            item.bodytext = ""
        end if

        ' Rank
        rank = 0
        if card.doesExist("rank") then rank = card.rank
        item.votecount = rank.ToStr()

        item.cardwidth = 1060
        item.cardheight = 80

        signature = signature + item.title + "|" + item.description + "|"
        content.appendChild(item)
    end for

    ' Reconfigure grid for single-column bar layout
    configureGrid(1, cards.count(), [1060, 80], [90, 210])
    setChromeText(tvView.title, tvView.subtitle, "")
    updateGridIfNeeded(content, signature)
end sub

sub renderWordSandwichesBoard(tvView as Object)
    setGridInteractive(false)

    letters = ""
    if tvView.doesExist("letters") and tvView.letters <> invalid then
        letters = tvView.letters
    end if
    showWordSandwichLetters(letters, true)

    cards = []
    if tvView.doesExist("cards") and tvView.cards <> invalid then
        cards = tvView.cards
    end if

    maxScore = 1
    if tvView.doesExist("maxScore") and tvView.maxScore > 0 then
        maxScore = tvView.maxScore
    end if

    rowCount = cards.count()
    if rowCount <= 0 then rowCount = 1
    rowHeight = Int(410 / rowCount)
    if rowHeight > 72 then rowHeight = 72
    if rowHeight < 46 then rowHeight = 46

    content = CreateObject("roSGNode", "ContentNode")
    signature = "word_sandwiches|" + letters + "|"

    for each card in cards
        item = CreateObject("roSGNode", "MiniGameContentNode")
        item.cardkind = "leaderboard_bar"
        item.title = ""
        if card.doesExist("title") then item.title = card.title
        item.footertext = ""
        if card.doesExist("footer") then item.footertext = card.footer

        barRatio = 0
        if card.doesExist("barRatio") then barRatio = card.barRatio
        score = 0
        if card.doesExist("score") then score = card.score
        item.description = score.ToStr() + "|" + barRatio.ToStr()

        if card.doesExist("character") and card.character <> invalid then
            item.bodytext = card.character
        else
            item.bodytext = ""
        end if

        rank = 0
        if card.doesExist("rank") then rank = card.rank
        item.votecount = rank.ToStr()

        item.cardwidth = 1060
        item.cardheight = rowHeight

        signature = signature + item.title + "|" + item.footertext + "|" + item.description + "|"
        content.appendChild(item)
    end for

    gridRows = cards.count()
    if gridRows < 1 then gridRows = 1
    configureGrid(1, gridRows, [1060, rowHeight], [90, 262])
    setChromeText(tvView.title, tvView.subtitle, tvView.description)
    updateGridIfNeeded(content, signature)
end sub

sub setTriviaTimerState(questionEndsAt as Dynamic, questionDurationMs as Integer)
    isVisible = questionEndsAt <> invalid and questionDurationMs > 0
    m.timerTrack.visible = isVisible
    m.timerFill.visible = isVisible

    if not isVisible then
        m.triviaQuestionKey = ""
        m.triviaQuestionEndsAt = invalid
        m.triviaQuestionDurationMs = 0
        m.triviaCountdown = invalid
        m.triviaTimer.control = "stop"
        m.timerFill.width = m.timerTrack.width
        return
    end if

    questionKey = questionEndsAt.ToStr() + "|" + questionDurationMs.ToStr()
    if questionKey <> m.triviaQuestionKey then
        m.triviaQuestionKey = questionKey
        m.triviaQuestionEndsAt = questionEndsAt
        m.triviaQuestionDurationMs = questionDurationMs
        m.triviaCountdown = CreateObject("roTimespan")
        m.triviaCountdown.Mark()
        m.timerFill.width = m.timerTrack.width
        m.timerFill.color = "0x27C2FFFF"
    end if

    updateTriviaTimerBar()
    m.triviaTimer.control = "start"
end sub

sub showWordSandwichLetters(text as String, isVisible as Boolean)
    if m.wordSandwichLetters = invalid then return
    m.wordSandwichLetters.visible = isVisible
    if isVisible then
        m.wordSandwichLetters.text = text
    else
        m.wordSandwichLetters.text = ""
    end if
end sub

sub onTriviaTimerTick()
    updateTriviaTimerBar()
end sub

sub updateTriviaTimerBar()
    if m.triviaCountdown = invalid or m.triviaQuestionDurationMs <= 0 then return

    elapsedMs = m.triviaCountdown.TotalMilliseconds()
    remainingMs = m.triviaQuestionDurationMs - elapsedMs
    if remainingMs < 0 then remainingMs = 0

    ratio = remainingMs / m.triviaQuestionDurationMs
    if ratio < 0 then ratio = 0
    if ratio > 1 then ratio = 1

    fillWidth = Int(m.timerTrack.width * ratio)
    if fillWidth < 0 then fillWidth = 0
    m.timerFill.width = fillWidth

    if ratio <= 0.25 then
        m.timerFill.color = "0xE74C3CFF"
    else if ratio <= 0.5 then
        m.timerFill.color = "0xF1C40FFF"
    else
        m.timerFill.color = "0x27C2FFFF"
    end if

    if remainingMs <= 0 then
        m.triviaTimer.control = "stop"
    end if
end sub

function buildVoterCharacterUrls(card as Object) as String
    if not card.doesExist("voterCharacters") then return ""
    voters = card.voterCharacters
    if voters = invalid then return ""

    urls = ""
    for each slug in voters
        if slug <> invalid and slug <> "" then
            url = "pkg:/images/Characters/" + slug + ".png"
            if urls = "" then
                urls = url
            else
                urls = urls + "," + url
            end if
        end if
    end for
    return urls
end function

sub renderCardGrid(tvView as Object, interactive as Boolean, numColumns as Integer, numRows as Integer, itemSize as Object, translation as Object, cardKind as String)
    if interactive then
        m.miniGameGrid.drawFocusFeedback = true
        if m.focusTarget = "grid" then
            setGridInteractive(true)
        else
            m.miniGameGrid.drawFocusFeedback = false
        end if
    else
        setGridInteractive(false)
    end if
    configureGrid(numColumns, numRows, itemSize, translation)
    content = CreateObject("roSGNode", "ContentNode")
    signature = cardKind + "|"
    if tvView.doesExist("title") then signature = signature + tvView.title + "|"
    if tvView.doesExist("subtitle") then signature = signature + tvView.subtitle + "|"
    if tvView.doesExist("description") then signature = signature + tvView.description + "|"
    if tvView.doesExist("questionEndsAt") and tvView.questionEndsAt <> invalid then signature = signature + tvView.questionEndsAt.ToStr() + "|"
    if tvView.doesExist("questionDurationMs") then signature = signature + tvView.questionDurationMs.ToStr() + "|"

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

            ' For trivia_reveal, mark the correct card
            if cardKind = "trivia_reveal" then
                if card.doesExist("isCorrect") and card.isCorrect = true then
                    item.votecount = "correct"
                else
                    item.votecount = "wrong"
                end if
            end if

            if cardKind = "game_vote" then
                voterUrls = buildVoterCharacterUrls(card)
                item.votercharacterurls = voterUrls
                signature = signature + item.title + "|" + item.bodytext + "|" + item.footertext + "|" + voterUrls + "|"
            else
                signature = signature + item.title + "|" + item.bodytext + "|" + item.footertext + "|"
                if cardKind = "trivia_reveal" and card.doesExist("isCorrect") then
                    signature = signature + card.isCorrect.ToStr() + "|"
                end if
            end if

            content.appendChild(item)
        end for
    end if

    updateGridIfNeeded(content, signature)
    setChromeText(tvView.title, tvView.subtitle, tvView.description)

    if interactive and content.getChildCount() > 0 then
        updateFocusedDescription(m.lastFocusedIndex)
    end if
end sub

sub showReturnVoteButton(isVisible as Boolean)
    m.isReturnButtonVisible = isVisible
    m.returnVoteButton.visible = isVisible
    applyReturnVoteButtonStyle(false)
end sub

sub applyBackButtonStyle(isFocused as Boolean, isPressed as Boolean)
    if m.chrome = invalid then return
    m.chrome.callFunc("setBackButtonState", isFocused, isPressed)
end sub

sub applyReturnVoteButtonStyle(isPressed as Boolean)
    if not m.isReturnButtonVisible then return
    m.returnVoteButton.isFocused = true
    m.returnVoteButton.isPressed = isPressed
end sub

sub configureGrid(numColumns as Integer, numRows as Integer, itemSize as Object, translation as Object)
    m.miniGameGrid.numColumns = numColumns
    m.miniGameGrid.numRows = numRows
    m.miniGameGrid.itemSize = itemSize
    m.miniGameGrid.translation = translation
    if numColumns = 2 and numRows = 2 then
        m.miniGameGrid.itemSpacing = [20, 20]
    else if numColumns = 1 then
        m.miniGameGrid.itemSpacing = [0, 10]
    else
        m.miniGameGrid.itemSpacing = [30, 30]
    end if
end sub

sub setGridInteractive(isInteractive as Boolean)
    m.miniGameGrid.drawFocusFeedback = isInteractive
    if isInteractive then
        m.focusTarget = "grid"
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

sub setChromeText(title as String, subtitle as String, bodyText as String)
    if m.chrome = invalid then return
    m.chrome.title = title
    m.chrome.subtitle = subtitle
    m.chrome.bodyText = bodyText
end sub
