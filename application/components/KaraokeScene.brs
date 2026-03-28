sub init()
    m.chrome = m.top.findNode("chrome")
    m.currentLineLabel = m.top.findNode("currentLine")
    m.nextLineLabel = m.top.findNode("nextLine")
    m.statusLabel = m.top.findNode("statusLabel")
    m.lyricTimer = m.top.findNode("lyricTimer")
    m.lyricTimer.observeField("fire", "onLyricTimerFire")

    m.lines = [
        "City lights are waking up, the room begins to glow",
        "Every voice is rising now, we feel the music grow",
        "Hands are tapping to the beat, we lean into the sound",
        "Laughing through the chorus while the rhythm spins around",
        "Take a breath and sing it loud, let every wall reply",
        "Shadows turn to color when the melody lifts high",
        "Hold the note and keep it warm, the whole couch sings along",
        "One more line and one more smile, tonight feels like a song",
        "When the final echo fades, the energy still stays",
        "We keep the room alive with sound and bright electric haze"
    ]

    m.currentIndex = 0
    m.isPlaying = true
    updateLyrics()
    m.lyricTimer.control = "start"
    m.top.setFocus(true)
end sub

sub cleanup()
    if m.lyricTimer <> invalid then
        m.lyricTimer.control = "stop"
    end if
end sub

sub updateLyrics()
    if m.lines.Count() = 0 then return

    if m.currentIndex < 0 then m.currentIndex = 0
    if m.currentIndex >= m.lines.Count() then m.currentIndex = 0

    m.currentLineLabel.text = m.lines[m.currentIndex]

    nextIndex = m.currentIndex + 1
    if nextIndex >= m.lines.Count() then
        m.nextLineLabel.text = "Next: back to the beginning"
    else
        m.nextLineLabel.text = "Next: " + m.lines[nextIndex]
    end if

    if m.isPlaying then
        m.statusLabel.text = "Playing"
    else
        m.statusLabel.text = "Paused"
    end if
end sub

sub onLyricTimerFire()
    if not m.isPlaying then return
    m.currentIndex = m.currentIndex + 1
    if m.currentIndex >= m.lines.Count() then
        m.currentIndex = 0
    end if
    updateLyrics()
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "back" then
        cleanup()
        if m.top.sceneManager <> invalid then
            m.top.sceneManager.callFunc("goBack")
        end if
        return true
    end if

    if key = "OK" then
        m.isPlaying = not m.isPlaying
        if m.isPlaying then
            m.lyricTimer.control = "start"
        else
            m.lyricTimer.control = "stop"
        end if
        updateLyrics()
        return true
    end if

    if key = "right" or key = "down" then
        m.currentIndex = m.currentIndex + 1
        if m.currentIndex >= m.lines.Count() then m.currentIndex = 0
        updateLyrics()
        return true
    end if

    if key = "left" or key = "up" then
        m.currentIndex = m.currentIndex - 1
        if m.currentIndex < 0 then m.currentIndex = m.lines.Count() - 1
        updateLyrics()
        return true
    end if

    return false
end function
