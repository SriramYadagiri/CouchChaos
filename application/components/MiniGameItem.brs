sub init()
    m.titleLabel = m.top.findNode("titleLabel")
    m.descriptionLabel = m.top.findNode("descriptionLabel")
    m.voteLabel = m.top.findNode("voteLabel")
    m.card = m.top.findNode("card")
    m.shadow = m.top.findNode("shadow")
    m.accent = m.top.findNode("accent")
    m.voterIconGroup = m.top.findNode("voterIconGroup")

    ' Cache references to all 12 voter icon Posters
    m.voterIcons = []
    for i = 0 to 11
        m.voterIcons.push(m.top.findNode("voterIcon" + i.ToStr()))
    end for
end sub

sub onContentChanged()
    item = m.top.itemContent
    if item = invalid then return

    cardWidth = 320
    cardHeight = 220
    if item.doesExist("cardwidth") and item.cardwidth <> invalid and item.cardwidth > 0 then
        cardWidth = item.cardwidth
    end if
    if item.doesExist("cardheight") and item.cardheight <> invalid and item.cardheight > 0 then
        cardHeight = item.cardheight
    end if

    applyCardLayout(cardWidth, cardHeight)

    m.card.color = "0x173049FF"
    m.accent.color = "0x27C2FFFF"
    hasCardColor = item.doesExist("cardcolor")
    cardKind = ""
    if item.doesExist("cardkind") and item.cardkind <> invalid then
        cardKind = item.cardkind
    end if

    itemTitle = ""
    if item.doesExist("title") and item.title <> invalid then
        itemTitle = item.title
    end if
    m.titleLabel.text = itemTitle

    bodyText = ""
    if item.doesExist("bodytext") then
        bodyText = item.bodytext
    end if
    m.descriptionLabel.text = bodyText

    if item.doesExist("footertext") then
        m.voteLabel.text = item.footertext
    else if item.doesExist("votecount") then
        m.voteLabel.text = item.votecount + " vote(s)"
    else
        m.voteLabel.text = ""
    end if

    if item.doesExist("cardcolor") then
        m.card.color = item.cardcolor
    end if

    if cardKind = "game_vote" then
        m.accent.color = "0x27C2FFFF"
        m.titleLabel.text = ""
        if itemTitle <> "" then
            m.descriptionLabel.text = itemTitle
        end if
        m.descriptionLabel.numLines = 2
        m.descriptionLabel.vertAlign = "center"
        m.descriptionLabel.horizAlign = "center"
    else if cardKind = "trivia_option" then
        m.titleLabel.text = ""
        m.voteLabel.text = ""
        if hasCardColor then
            m.accent.color = item.cardcolor
        end if
        m.descriptionLabel.vertAlign = "center"
        m.descriptionLabel.horizAlign = "center"
    else if cardKind = "leaderboard" then
        m.accent.color = "0x64D2FFFF"
        m.descriptionLabel.text = ""
        m.descriptionLabel.numLines = 1
        m.descriptionLabel.vertAlign = "top"
        m.descriptionLabel.horizAlign = "center"
    else if hasCardColor then
        m.titleLabel.text = ""
        m.voteLabel.text = ""
    else if bodyText = "" and itemTitle <> "" then
        m.titleLabel.text = ""
        m.descriptionLabel.text = itemTitle
        m.descriptionLabel.numLines = 2
    end if

    ' Render voter character icons (only on game_vote cards)
    if cardKind = "game_vote" then
        renderVoterIcons(item, cardWidth, cardHeight)
    else
        hideAllVoterIcons()
    end if
end sub

sub renderVoterIcons(item as Object, cardWidth as Float, cardHeight as Float)
    ' Parse the comma-separated voter character URL list
    voterUrls = []
    if item.doesExist("votercharacterurls") and item.votercharacterurls <> invalid and item.votercharacterurls <> "" then
        voterUrls = item.votercharacterurls.split(",")
    end if

    iconCount = voterUrls.count()
    if iconCount = 0 then
        hideAllVoterIcons()
        return
    end if

    ' Layout: icon strip sits just above the footer label
    ' Each icon is 28x28, spaced 4px apart, centered horizontally
    iconSize = 28
    iconSpacing = 4
    maxIcons = 12
    if iconCount > maxIcons then iconCount = maxIcons

    totalWidth = (iconSize * iconCount) + (iconSpacing * (iconCount - 1))
    startX = Int((cardWidth - totalWidth) / 2)
    ' Position strip just above the voteLabel (which sits at cardHeight - 35)
    iconY = Int(cardHeight - 35 - iconSize - 6)

    m.voterIconGroup.visible = true
    m.voterIconGroup.translation = [0, 0]

    for i = 0 to 11
        icon = m.voterIcons[i]
        if i < iconCount then
            icon.uri = voterUrls[i]
            icon.translation = [startX + (i * (iconSize + iconSpacing)), iconY]
            icon.visible = true
        else
            icon.uri = ""
            icon.visible = false
        end if
    end for
end sub

sub hideAllVoterIcons()
    m.voterIconGroup.visible = false
    for i = 0 to 11
        m.voterIcons[i].visible = false
        m.voterIcons[i].uri = ""
    end for
end sub

sub applyCardLayout(cardWidth as Float, cardHeight as Float)
    m.shadow.width = cardWidth
    m.shadow.height = cardHeight
    m.card.width = cardWidth
    m.card.height = cardHeight
    m.accent.width = cardWidth
    m.accent.height = 10

    m.titleLabel.translation = [20, 20]
    m.titleLabel.width = cardWidth - 40
    m.titleLabel.height = 40

    m.descriptionLabel.translation = [20, 60]
    m.descriptionLabel.width = cardWidth - 40
    m.descriptionLabel.height = cardHeight - 100

    m.voteLabel.translation = [20, cardHeight - 35]
    m.voteLabel.width = cardWidth - 40
    m.voteLabel.height = 28

    if cardWidth >= 500 then
        m.descriptionLabel.translation = [24, 30]
        m.descriptionLabel.width = cardWidth - 48
        m.descriptionLabel.height = cardHeight - 60
        m.descriptionLabel.numLines = 4
        m.voteLabel.translation = [20, cardHeight - 32]
    else
        m.descriptionLabel.numLines = 5
    end if

    if cardWidth <= 320 then
        m.descriptionLabel.vertAlign = "center"
        m.descriptionLabel.horizAlign = "center"
    else
        m.descriptionLabel.vertAlign = "top"
        m.descriptionLabel.horizAlign = "center"
    end if
end sub
