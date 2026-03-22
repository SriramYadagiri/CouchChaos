sub init()
    ' Initialize the nodes
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
    m.music = m.top.findNode("GameMusic")
    m.music2 = m.top.findNode("GameOver")
    m.scoreLabel = m.top.findNode("scoreLabel")
    m.background = m.top.findNode("background")
    m.mainMenu = m.top.findNode("MainMenu")

    m.timer.repeat = true
    m.timer.duration = Rnd(0) / 10
    m.timer.observeField("fire", "onTimerFire")

    m.timer2.repeat = true
    m.timer2.duration = Rnd(0) / 10
    m.timer2.observeField("fire", "onTimerFire2")

    m.timer3.repeat = true
    m.timer3.duration = Rnd(0) / 10
    m.timer3.observeField("fire", "onTimerFire3")

    m.timer4.repeat = true
    m.timer4.duration = Rnd(0) / 10
    m.timer4.observeField("fire", "onTimerFire4")

    m.currentThemeIndex = 0
    m.score = 0

    musicContent = createObject("roSGNode", "ContentNode")
    musicContent.url = "pkg:/audio/GameSound.mp3"
    m.music.content = musicContent

    deathContent = createObject("roSGNode", "ContentNode")
    deathContent.url = "pkg:/audio/GameOver.mp3"
    m.music2.content = deathContent

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

    m.mainMenu.setFocus(true)
    m.mainMenu.observeField("buttonSelected", "onButtonSelected")
end sub

' Called by SceneManager when navigating away — stop all timers and audio cleanly
sub cleanup()
    m.timer.control = "stop"
    m.timer2.control = "stop"
    m.timer3.control = "stop"
    m.timer4.control = "stop"
    m.music.control = "stop"
    m.music2.control = "stop"
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    ' Back key: if in game over screen or main menu, go back to SinglePlayerScene
    if key = "back" then
        cleanup()
        if m.top.sceneManager <> invalid then
            m.top.sceneManager.callFunc("goBack")
        end if
        return true
    end if

    ' Game over screen: OK restarts, back exits (handled above)
    if m.gameOverMsg.visible = true then
        if key = "OK" then
            m.gameOverMsg.visible = false
            m.mainMenu.visible = true
            m.fish.visible = false
            m.Shark1.visible = false
            m.Shark2.visible = false
            m.Shark3.visible = false
            m.Whale.visible = false
            m.mainMenu.setFocus(true)
            m.mainMenu.observeField("buttonSelected", "onButtonSelected")
            return true
        end if
        return false
    end if

    ' In-game movement — only active when the menu is hidden
    if m.mainMenu.visible = false then
        currPos = m.fish.translation
        if key = "up" then
            if currPos[1] > 50
                m.fish.translation = [currPos[0], currPos[1] - 100]
            end if
            return true
        else if key = "down" then
            if currPos[1] < 350
                m.fish.translation = [currPos[0], currPos[1] + 100]
            end if
            return true
        end if
    end if

    return false
end function

sub onTimerFire()
    currentPos = m.Shark1.translation
    newY = currentPos[1]
    if currentPos[0] >= 100 then
        m.Shark1.translation = [currentPos[0] - 5, newY]
    else
        m.score = m.score + 1
        m.scoreLabel.text = "Score: " + m.score.ToStr()
        m.Shark1.translation = [1400, newY]
        m.timer.duration = Rnd(0) / 10
    end if
    xDist = Abs(m.Shark1.translation[0] - m.fish.translation[0])
    if xDist < 135 and m.Shark1.translation[1] = m.fish.translation[1] then
        stopGame()
    end if
end sub

sub onTimerFire2()
    currentPos = m.Shark2.translation
    newY = currentPos[1]
    if currentPos[0] >= 100 then
        m.Shark2.translation = [currentPos[0] - 5, newY]
    else
        m.score = m.score + 1
        m.scoreLabel.text = "Score: " + m.score.ToStr()
        m.Shark2.translation = [1400, newY]
        m.timer2.duration = Rnd(0) / 10
    end if
    xDist = Abs(m.Shark2.translation[0] - m.fish.translation[0])
    if xDist < 135 and m.Shark2.translation[1] = m.fish.translation[1] then
        stopGame()
    end if
end sub

sub onTimerFire3()
    currentPos = m.Shark3.translation
    newY = currentPos[1]
    if currentPos[0] >= 100 then
        m.Shark3.translation = [currentPos[0] - 5, newY]
    else
        m.score = m.score + 1
        m.scoreLabel.text = "Score: " + m.score.ToStr()
        m.Shark3.translation = [1400, newY]
        m.timer3.duration = Rnd(0) / 10
    end if
    xDist = Abs(m.Shark3.translation[0] - m.fish.translation[0])
    if xDist < 135 and m.Shark3.translation[1] = m.fish.translation[1] then
        stopGame()
    end if
end sub

sub onTimerFire4()
    currentPos = m.Whale.translation
    newY = currentPos[1]
    if currentPos[0] >= 100 then
        m.Whale.translation = [currentPos[0] - 5, newY]
    else
        m.score = m.score + 1
        m.scoreLabel.text = "Score: " + m.score.ToStr()
        m.Whale.translation = [1400, newY]
        m.timer4.duration = Rnd(0) / 10
    end if
    xDist = Abs(m.Whale.translation[0] - m.fish.translation[0])
    if xDist < 135 and m.Whale.translation[1] = m.fish.translation[1] then
        stopGame()
    end if
end sub

sub stopGame()
    m.timer.control = "stop"
    m.timer2.control = "stop"
    m.timer3.control = "stop"
    m.timer4.control = "stop"
    m.gameOverMsg.visible = true
    m.fish.opacity = 0.3
    m.music.control = "stop"
    m.music2.control = "play"
end sub

sub resetGame()
    m.score = 0
    m.scoreLabel.text = "Score: 0"
    m.fish.visible = true
    m.Shark1.visible = true
    m.Shark2.visible = true
    m.Shark3.visible = true
    m.Whale.visible = true
    m.fish.translation = [100, 250]
    m.Shark1.translation = [1400, 50]
    m.Shark2.translation = [1400, 250]
    m.Shark3.translation = [1400, 450]
    m.Whale.translation = [1400, 650]
    m.gameOverMsg.visible = false
    m.fish.opacity = 1.0
    m.music2.control = "stop"
    m.music.control = "stop"
    m.music.control = "play"
    m.timer.control = "start"
    m.timer2.control = "start"
    m.timer3.control = "start"
    m.timer4.control = "start"
end sub

sub onButtonSelected()
    buttonIndex = m.mainMenu.buttonSelected

    if buttonIndex = 0 then
        StartGame()
    else if buttonIndex = 1 then
        ThemeChange()
    else if buttonIndex = 2 then
        ' Exit back to SinglePlayerScene instead of killing the app
        cleanup()
        if m.top.sceneManager <> invalid then
            m.top.sceneManager.callFunc("goBack")
        end if
    end if
end sub

sub ThemeChange()
    m.currentThemeIndex = (m.currentThemeIndex + 1) MOD m.themes.Count()
    activeTheme = m.themes[m.currentThemeIndex]

    m.fish.uri = ""
    m.Shark1.uri = ""
    m.Shark2.uri = ""
    m.Shark3.uri = ""
    m.Whale.uri = ""
    m.background.uri = ""

    if activeTheme.Background <> invalid then
        m.background.uri = activeTheme.Background
    end if

    m.fish.uri = activeTheme.Fish
    m.Shark1.uri = activeTheme.Shark1
    m.Shark2.uri = activeTheme.Shark2
    m.Shark3.uri = activeTheme.Shark3
    m.Whale.uri = activeTheme.Whale

    m.mainMenu.buttons = ["Play", "Theme: " + activeTheme.name, "Exit"]
    m.mainMenu.setFocus(true)
end sub

sub StartGame()
    m.mainMenu.visible = false
    m.mainMenu.setFocus(false)
    m.top.setFocus(true)
    resetGame()
end sub
