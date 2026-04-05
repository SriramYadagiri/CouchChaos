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
        m.titleLabel.translation = [290, 34]
        m.titleLabel.width = 670
        m.subtitleLabel.translation = [290, 90]
        m.subtitleLabel.width = 770
        m.bodyLabel.translation = [290, 144]
        m.bodyLabel.width = 840
    else
        m.titleLabel.translation = [90, 34]
        m.titleLabel.width = 860
        m.subtitleLabel.translation = [90, 90]
        m.subtitleLabel.width = 930
        m.bodyLabel.translation = [90, 144]
        m.bodyLabel.width = 1000
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
