sub init()
    m.titleLabel = m.top.findNode("titleLabel")
    m.subtitleLabel = m.top.findNode("subtitleLabel")
    m.bodyLabel = m.top.findNode("bodyLabel")
    m.backButton = m.top.findNode("backButton")
    onContentChanged()
    onBackStateChanged()
    setBackButtonState(false, false)
end sub

sub onContentChanged()
    m.titleLabel.text = valueOrEmpty(m.top.title)
    m.subtitleLabel.text = valueOrEmpty(m.top.subtitle)
    m.bodyLabel.text = valueOrEmpty(m.top.bodyText)
end sub

sub onBackStateChanged()
    isVisible = m.top.showBackButton
    m.backButton.visible = isVisible
    m.backButton.text = valueOrEmpty(m.top.backLabel)

    if isVisible then
        m.titleLabel.translation = [290, 52]
        m.titleLabel.width = 700
        m.subtitleLabel.translation = [290, 96]
        m.subtitleLabel.width = 780
        m.bodyLabel.translation = [90, 138]
        m.bodyLabel.width = 1070
    else
        m.titleLabel.translation = [90, 52]
        m.titleLabel.width = 900
        m.subtitleLabel.translation = [90, 96]
        m.subtitleLabel.width = 980
        m.bodyLabel.translation = [90, 138]
        m.bodyLabel.width = 1070
    end if
end sub

sub setBackButtonState(isFocused as Boolean, isPressed as Boolean)
    if not m.top.showBackButton then return
    m.backButton.isFocused = isFocused
    m.backButton.isPressed = isPressed
end sub

function valueOrEmpty(value as Dynamic) as String
    if value = invalid then return ""
    return value
end function
