sub init()
    m.chrome = m.top.findNode("chrome")
    m.playfield = m.top.findNode("playfield")
    m.playfieldAccent = m.top.findNode("playfieldAccent")
    m.targetGroup = m.top.findNode("targetGroup")
    m.selector = m.top.findNode("selector")
    m.scoreLabel = m.top.findNode("scoreLabel")
    m.timerLabel = m.top.findNode("timerLabel")
    m.streakLabel = m.top.findNode("streakLabel")
    m.missLabel = m.top.findNode("missLabel")
    m.reactionLabel = m.top.findNode("reactionLabel")
    m.currentTileLabel = m.top.findNode("currentTileLabel")
    m.overlayLabel = m.top.findNode("overlayLabel")
    m.gameTimer = m.top.findNode("gameTimer")
    m.gameTimer.observeField("fire", "onTimerFire")

    m.targets = []
    m.targetLabels = []
    for i = 0 to 8
        m.targets.push(m.top.findNode("target" + i.ToStr()))
        m.targetLabels.push(m.top.findNode("targetLabel" + i.ToStr()))
    end for

    m.designWidth = 1280
    m.designHeight = 720
    m.gridColumns = 3
    m.cursorIndex = 4
    m.activeTargetIndex = 4
    m.gameDurationMs = 45000
    m.isRunning = false
    m.score = 0
    m.misses = 0
    m.currentStreak = 0
    m.bestStreak = 0
    m.lastReactionMs = invalid
    m.roundClock = invalid
    m.targetClock = invalid

    applyResponsiveLayout()
    updateSelectorPosition()
    updateTargetHighlights()
    updateStats()
    m.top.setFocus(true)
end sub

sub cleanup()
    m.isRunning = false
    if m.gameTimer <> invalid then m.gameTimer.control = "stop"
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "back" then
        cleanup()
        if m.top.sceneManager <> invalid then m.top.sceneManager.callFunc("goBack")
        return true
    end if

    if not m.isRunning then
        if key = "OK" then
            startTraining()
            return true
        end if
        if key = "left" or key = "right" or key = "up" or key = "down" then
            moveCursor(key)
            return true
        end if
        return false
    end if

    if key = "left" or key = "right" or key = "up" or key = "down" then
        moveCursor(key)
        return true
    else if key = "OK" then
        handleHitAttempt()
        return true
    end if

    return false
end function

sub startTraining()
    m.isRunning = true
    m.score = 0
    m.misses = 0
    m.currentStreak = 0
    m.bestStreak = 0
    m.lastReactionMs = invalid
    m.cursorIndex = 4
    m.roundClock = CreateObject("roTimespan")
    m.roundClock.Mark()
    chooseNextTarget()
    updateSelectorPosition()
    updateTargetHighlights()
    updateStats()
    m.overlayLabel.text = "Hit the highlighted tile as quickly as you can."
    m.chrome.subtitle = "Move with the arrows. Press OK when the selector lands on the bright tile."
    m.chrome.bodyText = "This is a gentle coordination trainer that helps players practice directional input and OK timing."
    m.gameTimer.control = "start"
end sub

sub finishTraining()
    m.isRunning = false
    if m.gameTimer <> invalid then m.gameTimer.control = "stop"

    summary = "Session complete. Hits: " + m.score.ToStr() + ". Misses: " + m.misses.ToStr() + ". Best streak: " + m.bestStreak.ToStr() + "."
    if m.lastReactionMs <> invalid then
        summary = summary + " Last reaction: " + Int(m.lastReactionMs).ToStr() + " ms."
    end if

    m.overlayLabel.text = summary + " Press OK to play again, or Back to return to the menu."
    m.chrome.subtitle = "Great work. Press OK to restart the training session."
    m.chrome.bodyText = "Remote Coach is designed to help players build comfort with Roku navigation using a calm, focused target drill."
    updateTargetHighlights()
end sub

sub onTimerFire()
    if not m.isRunning or m.roundClock = invalid then return

    elapsedMs = m.roundClock.TotalMilliseconds()
    remainingMs = m.gameDurationMs - elapsedMs
    if remainingMs < 0 then remainingMs = 0
    m.timerLabel.text = "Time: " + formatSeconds(remainingMs) + "s"

    if remainingMs <= 0 then
        finishTraining()
    end if
end sub

sub handleHitAttempt()
    if not m.isRunning then return

    if m.cursorIndex = m.activeTargetIndex then
        m.score = m.score + 1
        m.currentStreak = m.currentStreak + 1
        if m.currentStreak > m.bestStreak then m.bestStreak = m.currentStreak
        if m.targetClock <> invalid then
            m.lastReactionMs = m.targetClock.TotalMilliseconds()
        end if
        chooseNextTarget()
    else
        m.misses = m.misses + 1
        m.currentStreak = 0
        m.overlayLabel.text = "Close. Move to the bright tile, then press OK."
    end if

    updateTargetHighlights()
    updateStats()
end sub

sub chooseNextTarget()
    nextIndex = Int(Rnd(0) * 9)
    if nextIndex = m.activeTargetIndex then
        nextIndex = (nextIndex + 3) mod 9
    end if
    m.activeTargetIndex = nextIndex
    m.targetClock = CreateObject("roTimespan")
    m.targetClock.Mark()
    m.overlayLabel.text = "Move to the bright tile and press OK."
end sub

sub moveCursor(key as String)
    row = Int(m.cursorIndex / m.gridColumns)
    col = m.cursorIndex mod m.gridColumns

    if key = "left" and col > 0 then col = col - 1
    if key = "right" and col < m.gridColumns - 1 then col = col + 1
    if key = "up" and row > 0 then row = row - 1
    if key = "down" and row < m.gridColumns - 1 then row = row + 1

    m.cursorIndex = row * m.gridColumns + col
    updateSelectorPosition()
    updateTargetHighlights()
    updateStats()
end sub

sub updateSelectorPosition()
    if m.selector = invalid then return
    if m.cellPositions = invalid then return
    cellPos = m.cellPositions[m.cursorIndex]
    m.selector.translation = [cellPos[0] - Int(m.selectorBorder / 2), cellPos[1] - Int(m.selectorBorder / 2)]
end sub

sub updateTargetHighlights()
    for i = 0 to 8
        target = m.targets[i]
        label = m.targetLabels[i]
        if target <> invalid and label <> invalid then
            target.borderWidth = 0
            target.borderColor = "0x00000000"

            if i = m.activeTargetIndex then
                target.color = "0x2AD18FFF"
                label.color = "0x0A1827FF"
            else if i = m.cursorIndex then
                target.color = "0x2E5B8AFF"
                label.color = "0xFFFFFFFF"
            else
                target.color = "0x203246FF"
                label.color = "0xC8DAEFFF"
            end if

            if i = m.activeTargetIndex and i = m.cursorIndex then
                target.color = "0x7EF7B8FF"
                target.borderWidth = 4
                target.borderColor = "0xE8FFF6FF"
                label.color = "0x0A1827FF"
            else if i = m.activeTargetIndex then
                target.borderWidth = 4
                target.borderColor = "0xB7FFE0FF"
            else if i = m.cursorIndex then
                target.borderWidth = 4
                target.borderColor = "0x8AE8FFFF"
            end if
        end if
    end for
end sub

sub updateStats()
    m.scoreLabel.text = "Hits: " + m.score.ToStr()
    if not m.isRunning then
        m.timerLabel.text = "Time: 45.0s"
    end if
    m.streakLabel.text = "Best Streak: " + m.bestStreak.ToStr()
    m.missLabel.text = "Misses: " + m.misses.ToStr()
    if m.lastReactionMs = invalid then
        m.reactionLabel.text = "Last Hit: --"
    else
        m.reactionLabel.text = "Last Hit: " + Int(m.lastReactionMs).ToStr() + " ms"
    end if
    if m.currentTileLabel <> invalid then
        m.currentTileLabel.text = "Current Tile: " + (m.cursorIndex + 1).ToStr()
    end if
end sub

sub applyResponsiveLayout()
    viewport = getViewportSize()
    scale = viewport.scale
    offsetX = viewport.offsetX
    offsetY = viewport.offsetY

    m.playfield.translation = scalePoint([120, 200], scale, offsetX, offsetY)
    m.playfield.width = scaleValue(760, scale)
    m.playfield.height = scaleValue(440, scale)
    m.playfieldAccent.translation = m.playfield.translation
    m.playfieldAccent.width = m.playfield.width
    m.playfieldAccent.height = scaleValue(10, scale)

    gridOrigin = scalePoint([170, 250], scale, offsetX, offsetY)
    m.targetGroup.translation = gridOrigin

    cellWidth = scaleValue(150, scale)
    cellHeight = scaleValue(90, scale)
    gapX = scaleValue(36, scale)
    gapY = scaleValue(34, scale)
    selectorPad = scaleValue(6, scale)
    m.selectorBorder = scaleValue(5, scale)

    m.cellPositions = []
    for i = 0 to 8
        row = Int(i / 3)
        col = i mod 3
        x = col * (cellWidth + gapX)
        y = row * (cellHeight + gapY)
        m.cellPositions.push([x, y])
        target = m.targets[i]
        label = m.targetLabels[i]
        if target <> invalid then
            target.translation = [x, y]
            target.width = cellWidth
            target.height = cellHeight
        end if
        if label <> invalid then
            label.translation = [x, y]
            label.width = cellWidth
            label.height = cellHeight
        end if
    end for

    m.selector.width = cellWidth + selectorPad * 2
    m.selector.height = cellHeight + selectorPad * 2
    m.selector.borderWidth = m.selectorBorder

    statsPos = scalePoint([920, 220], scale, offsetX, offsetY)
    statsGroup = m.top.findNode("statsGroup")
    if statsGroup <> invalid then statsGroup.translation = statsPos

    m.overlayLabel.translation = scalePoint([900, 430], scale, offsetX, offsetY)
    m.overlayLabel.width = scaleValue(320, scale)
    m.overlayLabel.height = scaleValue(150, scale)

    updateSelectorPosition()
end sub

function getViewportSize() as Object
    di = CreateObject("roDeviceInfo")
    width = 1280
    height = 720
    resolutionName = "HD"

    if di <> invalid then
        rawResolution = di.GetUIResolution()
        info = normalizeResolutionInfo(rawResolution)
        if info.width > 0 then width = info.width
        if info.height > 0 then height = info.height
        if info.name <> "" then resolutionName = info.name
    end if

    if width <= 0 or height <= 0 then
        width = 1280
        height = 720
        if Instr(1, resolutionName, "UHD") > 0 or Instr(1, resolutionName, "4K") > 0 then
            width = 3840
            height = 2160
        else if Instr(1, resolutionName, "FHD") > 0 or Instr(1, resolutionName, "1080") > 0 then
            width = 1920
            height = 1080
        end if
    end if

    scaleX = width / 1280
    scaleY = height / 720
    scale = scaleX
    if scaleY < scale then scale = scaleY

    return {
        width: width,
        height: height,
        scale: scale,
        offsetX: Int((width - (1280 * scale)) / 2),
        offsetY: Int((height - (720 * scale)) / 2)
    }
end function

function normalizeResolutionInfo(rawResolution as Dynamic) as Object
    info = { width: 0, height: 0, name: "" }
    if rawResolution = invalid then return info

    rawType = Type(rawResolution)
    if rawType = "String" or rawType = "roString" then
        info.name = UCase(rawResolution)
        return info
    end if

    if rawType <> "roAssociativeArray" and rawType <> "AssociativeArray" then
        return info
    end if

    if rawResolution.DoesExist("width") and rawResolution.width <> invalid then info.width = Int(rawResolution.width)
    if rawResolution.DoesExist("height") and rawResolution.height <> invalid then info.height = Int(rawResolution.height)
    if rawResolution.DoesExist("name") and rawResolution.name <> invalid then
        if Type(rawResolution.name) = "String" or Type(rawResolution.name) = "roString" then
            info.name = UCase(rawResolution.name)
        end if
    end if

    if (info.width <= 0 or info.height <= 0) and rawResolution.DoesExist("uiResolution") and rawResolution.uiResolution <> invalid then
        nested = normalizeResolutionInfo(rawResolution.uiResolution)
        if info.width <= 0 then info.width = nested.width
        if info.height <= 0 then info.height = nested.height
        if info.name = "" then info.name = nested.name
    end if

    return info
end function

function scalePoint(point as Object, scale as Float, offsetX as Integer, offsetY as Integer) as Object
    return [offsetX + Int(point[0] * scale), offsetY + Int(point[1] * scale)]
end function

function scaleValue(value as Float, scale as Float) as Integer
    return Int(value * scale)
end function

function formatSeconds(ms as Integer) as String
    if ms < 0 then ms = 0
    totalTenths = Int(ms / 100)
    wholeSeconds = Int(totalTenths / 10)
    tenths = totalTenths mod 10
    return wholeSeconds.ToStr() + "." + tenths.ToStr()
end function
