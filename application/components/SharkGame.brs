sub init()
    m.gameOverMsg = m.top.findNode("gameOverMsg")
    m.fish = m.top.findNode("Fish")
    m.Shark1 = m.top.findNode("Shark1")
    m.Shark2 = m.top.findNode("Shark2")
    m.Shark3 = m.top.findNode("Shark3")
    m.Whale = m.top.findNode("Whale")
    m.timer = m.top.findNode("timer")
    m.timer2 = m.top.findNode("timer2")
    m.timer3 = m.top.findNode("timer3")
    m.timer4 = m.top.findNode("timer4")
    m.scoreLabel = m.top.findNode("scoreLabel")
    m.controlsLabel = m.top.findNode("controlsLabel")
    m.background = m.top.findNode("background")
    m.mainMenu = m.top.findNode("MainMenu")

    m.timer.observeField("fire", "onTimerFire")
    m.timer2.observeField("fire", "onTimerFire2")
    m.timer3.observeField("fire", "onTimerFire3")
    m.timer4.observeField("fire", "onTimerFire4")

    m.currentThemeIndex = 0
    m.score = 0
    m.isRunning = false
    m.designWidth = 1280
    m.designHeight = 720
    m.baseFishPoint = [100, 250]
    m.baseLaneYs = [50, 150, 250, 350]
    m.baseSpawnX = 1400
    m.baseFishSize = [150, 100]
    m.baseHazardSize = [150, 100]
    m.hazardStep = 18
    m.currentLane = 2

    m.hazards = [
        { node: m.Shark1, timer: m.timer, laneIndex: 0, points: 5 },
        { node: m.Shark2, timer: m.timer2, laneIndex: 1, points: 6 },
        { node: m.Shark3, timer: m.timer3, laneIndex: 2, points: 7 },
        { node: m.Whale, timer: m.timer4, laneIndex: 3, points: 8 }
    ]

    m.themes = [
        {
            name: "Sharks & Fish",
            Background: "pkg:/SharkGameImages/Ocean.png",
            Fish: "pkg:/SharkGameImages/Fish.png",
            Shark1: "pkg:/SharkGameImages/Shark1.png",
            Shark2: "pkg:/SharkGameImages/Shark2.png",
            Shark3: "pkg:/SharkGameImages/Shark3.png",
            Whale: "pkg:/SharkGameImages/Whale.png"
        },
        {
            name: "Birds & Worm",
            Background: "pkg:/SharkGameImages/Sky.png",
            Fish: "pkg:/SharkGameImages/Worm.png",
            Shark1: "pkg:/SharkGameImages/Bird1.png",
            Shark2: "pkg:/SharkGameImages/Bird2.png",
            Shark3: "pkg:/SharkGameImages/Bird3.png",
            Whale: "pkg:/SharkGameImages/Bird4.png"
        },
        {
            name: "Planes",
            Background: "pkg:/SharkGameImages/Sky.png",
            Fish: "pkg:/SharkGameImages/Plane.png",
            Shark1: "pkg:/SharkGameImages/EPlane.png",
            Shark2: "pkg:/SharkGameImages/EPlane.png",
            Shark3: "pkg:/SharkGameImages/EPlane.png",
            Whale: "pkg:/SharkGameImages/EPlane.png"
        },
        {
            name: "Savannah",
            Background: "pkg:/SharkGameImages/Savanah.png",
            Fish: "pkg:/SharkGameImages/Squirrel.png",
            Shark1: "pkg:/SharkGameImages/Lion.png",
            Shark2: "pkg:/SharkGameImages/Hyena.png",
            Shark3: "pkg:/SharkGameImages/Coyote.png",
            Whale: "pkg:/SharkGameImages/Bobcat.png"
        }
    ]

    applyResponsiveLayout()
    applyTheme()
    m.mainMenu.setFocus(true)
    m.mainMenu.observeField("buttonSelected", "onButtonSelected")
end sub

sub cleanup()
    m.isRunning = false
    m.timer.control = "stop"
    m.timer2.control = "stop"
    m.timer3.control = "stop"
    m.timer4.control = "stop"
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "back" then
        cleanup()
        if m.top.sceneManager <> invalid then m.top.sceneManager.callFunc("goBack")
        return true
    end if

    if m.gameOverMsg.visible = true then
        if key = "OK" then
            m.gameOverMsg.visible = false
            m.mainMenu.visible = true
            m.mainMenu.setFocus(true)
            return true
        end if
        return false
    end if

    if m.isRunning then
        if key = "up" then
            if m.currentLane > 0 then
                m.currentLane = m.currentLane - 1
                updateFishPosition()
            end if
            return true
        else if key = "down" then
            if m.currentLane < m.baseLaneYs.Count() - 1 then
                m.currentLane = m.currentLane + 1
                updateFishPosition()
            end if
            return true
        end if
    end if

    return false
end function

function randomSpeed(base as Float) as Float
    return base + (Rnd(0) * 0.06)
end function

sub onTimerFire()
    moveHazard(m.hazards[0])
end sub

sub onTimerFire2()
    moveHazard(m.hazards[1])
end sub

sub onTimerFire3()
    moveHazard(m.hazards[2])
end sub

sub onTimerFire4()
    moveHazard(m.hazards[3])
end sub

sub moveHazard(hazardInfo as Object)
    if not m.isRunning then return

    hazard = hazardInfo.node
    currentPos = hazard.translation
    stepSize = Int(m.hazardStep * m.scale)
    if stepSize < 8 then stepSize = 8

    if currentPos[0] >= m.leftResetX then
        hazard.translation = [currentPos[0] - stepSize, currentPos[1]]
    else
        m.score = m.score + hazardInfo.points
        m.scoreLabel.text = "Score: " + m.score.ToStr()
        hazard.translation = [m.spawnX, m.laneYs[hazardInfo.laneIndex]]
        hazardInfo.timer.duration = randomSpeed(0.09)
    end if

    xDist = Abs(hazard.translation[0] - m.fish.translation[0])
    if xDist < m.collisionThreshold and hazardInfo.laneIndex = m.currentLane then
        stopGame()
    end if
end sub

sub stopGame()
    m.isRunning = false
    m.timer.control = "stop"
    m.timer2.control = "stop"
    m.timer3.control = "stop"
    m.timer4.control = "stop"
    m.gameOverMsg.visible = true
    m.fish.opacity = 0.35
end sub

sub resetGame()
    m.score = 0
    m.scoreLabel.text = "Score: 0"
    m.fish.visible = true
    m.Shark1.visible = true
    m.Shark2.visible = true
    m.Shark3.visible = true
    m.Whale.visible = true
    m.currentLane = 2
    updateFishPosition()
    for each hazardInfo in m.hazards
        hazardInfo.node.translation = [m.spawnX, m.laneYs[hazardInfo.laneIndex]]
    end for
    m.gameOverMsg.visible = false
    m.fish.opacity = 1.0
    m.timer.duration = randomSpeed(0.10)
    m.timer2.duration = randomSpeed(0.12)
    m.timer3.duration = randomSpeed(0.14)
    m.timer4.duration = randomSpeed(0.16)
end sub

sub onButtonSelected()
    buttonIndex = m.mainMenu.buttonSelected

    if buttonIndex = 0 then
        StartGame()
    else if buttonIndex = 1 then
        ThemeChange()
    else if buttonIndex = 2 then
        cleanup()
        if m.top.sceneManager <> invalid then m.top.sceneManager.callFunc("goBack")
    end if
end sub

sub applyTheme()
    activeTheme = m.themes[m.currentThemeIndex]
    m.background.uri = activeTheme.Background
    m.fish.uri = activeTheme.Fish
    m.Shark1.uri = activeTheme.Shark1
    m.Shark2.uri = activeTheme.Shark2
    m.Shark3.uri = activeTheme.Shark3
    m.Whale.uri = activeTheme.Whale
    m.mainMenu.buttons = ["Play", "Theme: " + activeTheme.name, "Exit"]
end sub

sub ThemeChange()
    m.currentThemeIndex = (m.currentThemeIndex + 1) MOD m.themes.Count()
    applyTheme()
    m.mainMenu.setFocus(true)
end sub

sub StartGame()
    m.mainMenu.visible = false
    m.mainMenu.setFocus(false)
    m.top.setFocus(true)
    m.isRunning = true
    resetGame()
    m.timer.control = "start"
    m.timer2.control = "start"
    m.timer3.control = "start"
    m.timer4.control = "start"
end sub

sub applyResponsiveLayout()
    viewport = getViewportSize()
    m.scale = viewport.scale
    m.offsetX = viewport.offsetX
    m.offsetY = viewport.offsetY
    m.viewportWidth = viewport.width
    m.viewportHeight = viewport.height
    m.laneYs = []

    m.background.width = m.viewportWidth
    m.background.height = m.viewportHeight
    m.background.translation = [0, 0]

    fishSize = [scaleValue(m.baseFishSize[0]), scaleValue(m.baseFishSize[1])]
    hazardSize = [scaleValue(m.baseHazardSize[0]), scaleValue(m.baseHazardSize[1])]
    if fishSize[0] < 120 then fishSize[0] = 120
    if fishSize[1] < 80 then fishSize[1] = 80

    m.fish.width = fishSize[0]
    m.fish.height = fishSize[1]
    m.Shark1.width = hazardSize[0]
    m.Shark1.height = hazardSize[1]
    m.Shark2.width = hazardSize[0]
    m.Shark2.height = hazardSize[1]
    m.Shark3.width = hazardSize[0]
    m.Shark3.height = hazardSize[1]
    m.Whale.width = hazardSize[0]
    m.Whale.height = hazardSize[1]

    for each laneY in m.baseLaneYs
        m.laneYs.push(scalePoint([0, laneY])[1])
    end for

    m.spawnX = scalePoint([m.baseSpawnX, 0])[0]
    m.leftResetX = scalePoint([100, 0])[0]
    m.collisionThreshold = scaleValue(120)
    if m.collisionThreshold < 90 then m.collisionThreshold = 90

    scorePos = scalePoint([100, 40])
    controlsPos = scalePoint([890, 44])
    menuPos = scalePoint([100, 100])
    msgPos = scalePoint([0, 0])

    m.scoreLabel.translation = scorePos
    m.controlsLabel.translation = controlsPos
    m.mainMenu.translation = menuPos
    m.gameOverMsg.translation = msgPos
    m.gameOverMsg.width = m.viewportWidth
    m.gameOverMsg.height = m.viewportHeight

    updateFishPosition()
    for each hazardInfo in m.hazards
        hazardInfo.node.translation = [m.spawnX, m.laneYs[hazardInfo.laneIndex]]
    end for
end sub

sub updateFishPosition()
    m.fish.translation = [scalePoint(m.baseFishPoint)[0], m.laneYs[m.currentLane]]
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

    scaleX = width / m.designWidth
    scaleY = height / m.designHeight
    scale = scaleX
    if scaleY < scale then scale = scaleY

    return {
        width: width,
        height: height,
        scale: scale,
        offsetX: Int((width - (m.designWidth * scale)) / 2),
        offsetY: Int((height - (m.designHeight * scale)) / 2)
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

function scalePoint(point as Object) as Object
    return [m.offsetX + Int(point[0] * m.scale), m.offsetY + Int(point[1] * m.scale)]
end function

function scaleValue(value as Float) as Integer
    return Int(value * m.scale)
end function
