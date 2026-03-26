sub init()
    m.buttonInner    = m.top.findNode("buttonInner")
    m.shadowGroup    = m.top.findNode("shadowGroup")
    m.baseGroup      = m.top.findNode("baseGroup")
    m.focusGroup     = m.top.findNode("focusGroup")
    m.glowStrip      = m.top.findNode("glowStrip")
    m.label          = m.top.findNode("label")

    ' Animation nodes
    m.hoverAnim       = m.top.findNode("hoverAnim")
    m.hoverInterp     = m.top.findNode("hoverInterp")
    m.focusScaleAnim  = m.top.findNode("focusScaleAnim")
    m.unfocusScaleAnim = m.top.findNode("unfocusScaleAnim")

    onSizeChanged()
    onTextChanged()
    onStateChanged()
end sub

sub onTextChanged()
    m.label.text = m.top.text
end sub

sub onSizeChanged()
    buttonWidth  = intValue(m.top.buttonWidth,  240)
    buttonHeight = intValue(m.top.buttonHeight, 56)
    capWidth     = 8

    ' Update the hover interpolator keyValue so the float arc stays
    ' centred on the current button dimensions.
    midX = Int(buttonWidth / 2)
    midY = Int(buttonHeight / 2)
    m.buttonInner.scaleRotateCenter = [midX, midY]

    layoutTriplet(m.top.findNode("shadowLeft"), m.top.findNode("shadowCenter"), m.top.findNode("shadowRight"), buttonWidth, buttonHeight, capWidth)
    layoutTriplet(m.top.findNode("baseLeft"),   m.top.findNode("baseCenter"),   m.top.findNode("baseRight"),   buttonWidth, buttonHeight, capWidth)
    layoutTriplet(m.top.findNode("focusLeft"),  m.top.findNode("focusCenter"),  m.top.findNode("focusRight"),  buttonWidth, buttonHeight, capWidth)

    m.shadowGroup.translation = [8, 8]
    m.baseGroup.translation   = [0, 0]
    m.focusGroup.translation  = [0, 0]

    m.glowStrip.translation = [capWidth + 8, 6]
    m.glowStrip.width  = buttonWidth - ((capWidth + 8) * 2)
    if m.glowStrip.width < 0 then m.glowStrip.width = 0
    m.glowStrip.height = 8

    m.label.width  = buttonWidth
    m.label.height = buttonHeight
    m.label.translation = [0, 0]
end sub

sub onStateChanged()
    ' ── Press offset (shifts inner group only when pressed) ──────────
    if m.top.isPressed then
        m.buttonInner.translation = [8, 8]
        m.glowStrip.translation   = [16, 14]

        ' Stop the float while pressed so it doesn't fight the press offset
        m.hoverAnim.control = "stop"
        m.buttonInner.translation = [8, 8]
    else
        m.glowStrip.translation = [16, 6]

        ' Restore float when released (if still focused)
        if m.top.isFocused then
            m.buttonInner.translation = [0, 0]
            m.hoverAnim.control = "start"
        else
            m.buttonInner.translation = [0, 0]
        end if
    end if

    ' ── Colour tinting ───────────────────────────────────────────────
    setTripletColor(m.top.findNode("baseLeft"),  m.top.findNode("baseCenter"),  m.top.findNode("baseRight"),  m.top.buttonColor)
    setTripletColor(m.top.findNode("focusLeft"), m.top.findNode("focusCenter"), m.top.findNode("focusRight"), m.top.focusedButtonColor)

    ' ── Focus / unfocus visuals + animation ──────────────────────────
    if m.top.isFocused then
        m.focusGroup.opacity    = 1.0
        m.glowStrip.blendColor = "0xBAF3FFFF"
        m.label.color          = m.top.focusedTextColor

        ' Pop in and start floating (only if not pressed)
        if not m.top.isPressed then
            m.unfocusScaleAnim.control = "stop"
            m.focusScaleAnim.control   = "start"
            m.hoverAnim.control        = "start"
        end if
    else
        m.focusGroup.opacity    = 0.0
        m.glowStrip.blendColor = "0x7DE3FFFF"
        m.label.color          = m.top.textColor

        ' Stop floating, shrink back to rest
        m.hoverAnim.control       = "stop"
        m.focusScaleAnim.control  = "stop"
        m.buttonInner.translation = [0, 0]
        m.unfocusScaleAnim.control = "start"
    end if
end sub

' ── Helpers ──────────────────────────────────────────────────────────────

sub layoutTriplet(leftPoster as Object, centerPoster as Object, rightPoster as Object, width as Integer, height as Integer, capWidth as Integer)
    leftPoster.width   = capWidth
    leftPoster.height  = height
    centerPoster.width = width - (capWidth * 2)
    if centerPoster.width < 0 then centerPoster.width = 0
    centerPoster.height = height
    centerPoster.translation = [capWidth, 0]
    rightPoster.width  = capWidth
    rightPoster.height = height
    rightPoster.translation = [capWidth + centerPoster.width, 0]
end sub

sub setTripletColor(leftPoster as Object, centerPoster as Object, rightPoster as Object, color as Dynamic)
    if color = invalid then return
    leftPoster.blendColor   = color
    centerPoster.blendColor = color
    rightPoster.blendColor  = color
end sub

function intValue(value as Dynamic, fallback as Integer) as Integer
    if value = invalid then return fallback
    return Int(value)
end function