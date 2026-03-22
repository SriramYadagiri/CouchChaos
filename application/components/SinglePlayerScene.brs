sub init()
    m.chrome = m.top.findNode("chrome")
    m.gameGrid = m.top.findNode("gameGrid")
    m.launchButton = m.top.findNode("launchButton")

    m.lastFocusedIndex = 0
    m.focusTarget = "grid"

    ' Define available single-player games
    m.games = [
        {
            id: "shark_game",
            title: "Shark Game",
            description: "Dodge sharks, whales, and more as they swim toward you. How long can you survive?",
            footer: "1 Player"
        }
    ]

    populateGrid()
    applyBackButtonStyle(false, false)
    applyLaunchButtonStyle(false, false)
    m.gameGrid.setFocus(true)
    m.focusTarget = "grid"
end sub

sub cleanup()
end sub

sub populateGrid()
    content = CreateObject("roSGNode", "ContentNode")

    for each game in m.games
        item = CreateObject("roSGNode", "MiniGameContentNode")
        item.cardkind = "game_vote"
        item.title = game.title
        item.description = game.description
        item.bodytext = game.description
        item.footertext = game.footer
        item.cardwidth = 320
        item.cardheight = 220
        content.appendChild(item)
    end for

    m.gameGrid.content = content
    m.gameGrid.jumpToItem = 0
    updateFocusedDescription(0)
end sub

sub updateFocusedDescription(index as Integer)
    if index < 0 or index >= m.games.Count() then return

    game = m.games[index]
    description = game.description
    if m.chrome <> invalid then
        m.chrome.bodyText = description
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    ' Back key — always go back
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

    ' Navigation between grid and launch button
    if m.focusTarget = "grid" then
        if key = "down" then
            m.focusTarget = "launch"
            m.gameGrid.drawFocusFeedback = false
            m.top.setFocus(true)
            applyLaunchButtonStyle(true, false)
            return true
        else if key = "up" or key = "left" then
            ' Move up/left from grid goes to back button
            m.focusTarget = "back"
            m.gameGrid.drawFocusFeedback = false
            m.top.setFocus(true)
            applyBackButtonStyle(true, false)
            return true
        end if
    else if m.focusTarget = "launch" then
        if key = "up" then
            m.focusTarget = "grid"
            applyLaunchButtonStyle(false, false)
            m.gameGrid.drawFocusFeedback = true
            m.gameGrid.setFocus(true)
            return true
        else if key = "OK" then
            applyLaunchButtonStyle(true, true)
            launchSelectedGame()
            return true
        end if
    else if m.focusTarget = "back" then
        if key = "down" or key = "right" then
            m.focusTarget = "grid"
            applyBackButtonStyle(false, false)
            m.gameGrid.drawFocusFeedback = true
            m.gameGrid.setFocus(true)
            return true
        else if key = "OK" then
            applyBackButtonStyle(true, true)
            if m.top.sceneManager <> invalid then
                m.top.sceneManager.callFunc("goBack")
            end if
            return true
        end if
    end if

    ' Track focused item in grid
    if m.focusTarget = "grid" then
        if key = "left" or key = "right" then
            ' Let the grid handle it, then read back itemFocused
            return false
        end if
    end if

    return false
end function

' Called when grid focus changes
sub onGameFocused()
    m.lastFocusedIndex = m.gameGrid.itemFocused
    updateFocusedDescription(m.lastFocusedIndex)
end sub

sub launchSelectedGame()
    index = m.lastFocusedIndex
    if index < 0 or index >= m.games.Count() then return

    game = m.games[index]

    if game.id = "shark_game" then
        if m.top.sceneManager <> invalid then
            m.top.sceneManager.callFunc("showSharkGame")
        end if
    end if
end sub

sub applyBackButtonStyle(isFocused as Boolean, isPressed as Boolean)
    if m.chrome = invalid then return
    m.chrome.callFunc("setBackButtonState", isFocused, isPressed)
end sub

sub applyLaunchButtonStyle(isFocused as Boolean, isPressed as Boolean)
    m.launchButton.isFocused = isFocused
    m.launchButton.isPressed = isPressed
end sub