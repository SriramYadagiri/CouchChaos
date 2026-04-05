sub init()
    m.titleLabel = m.top.findNode("titleLabel")
    m.descriptionLabel = m.top.findNode("descriptionLabel")
    m.voteLabel = m.top.findNode("voteLabel")
    m.card = m.top.findNode("card")
    m.shadow = m.top.findNode("shadow")
    m.accent = m.top.findNode("accent")
    m.voterIconGroup = m.top.findNode("voterIconGroup")

    m.voterIcons = []
    for i = 0 to 11
        m.voterIcons.push(m.top.findNode("voterIcon" + i.ToStr()))
    end for

    m.wordGuessProgressGroup = m.top.findNode("wordGuessProgressGroup")
    m.progressMetaLabel = m.top.findNode("progressMetaLabel")
    m.progressTiles = []
    m.progressTileLabels = []
    for i = 0 to 4
        m.progressTiles.push(m.top.findNode("progressTile" + i.ToStr()))
        m.progressTileLabels.push(m.top.findNode("progressTileLabel" + i.ToStr()))
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
    resetCardVisualState(cardWidth, cardHeight)
    hideWordGuessProgressGroup()

    hasCardColor = false
    if item.doesExist("cardcolor") and item.cardcolor <> invalid and item.cardcolor <> "" then
        hasCardColor = true
    end if
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
    if item.doesExist("bodytext") and item.bodytext <> invalid then
        bodyText = item.bodytext
    end if
    m.descriptionLabel.text = bodyText

    if item.doesExist("footertext") and item.footertext <> invalid then
        m.voteLabel.text = item.footertext
    else if item.doesExist("votecount") and item.votecount <> invalid then
        m.voteLabel.text = item.votecount + " vote(s)"
    end if

    if hasCardColor then
        applyCardColor(m.card, item.cardcolor)
    end if

    if cardKind = "leaderboard_bar" then
        renderLeaderboardBar(item, cardWidth, cardHeight)
        hideAllVoterIcons()
        return
    end if

    if cardKind = "word_guess_progress" then
        renderWordGuessProgressRow(item, cardWidth, cardHeight)
        hideAllVoterIcons()
        return
    end if

    if cardKind = "trivia_reveal" then
        isCorrect = item.doesExist("votecount") and item.votecount = "correct"

        if hasCardColor then
            applyCardColor(m.card, item.cardcolor)
            applyCardColor(m.accent, item.cardcolor)
        end if

        m.titleLabel.text = ""
        m.voteLabel.text = ""
        m.descriptionLabel.vertAlign = "center"
        m.descriptionLabel.horizAlign = "center"
        m.descriptionLabel.numLines = 4
        m.descriptionLabel.color = "0xFFFFFFFF"

        if isCorrect then
            m.accent.color = "0xFFFFFFFF"
            m.descriptionLabel.text = "Correct: " + bodyText
        else
            m.card.opacity = 0.3
        end if

        hideAllVoterIcons()
        return
    end if

    if cardKind = "game_vote" then
        m.accent.color = "0x27C2FFFF"
        m.titleLabel.text = itemTitle
        m.titleLabel.translation = [22, 24]
        m.titleLabel.width = cardWidth - 44
        m.titleLabel.height = 40
        m.titleLabel.horizAlign = "center"
        m.titleLabel.numLines = 1

        m.voteLabel.text = ""
        m.descriptionLabel.translation = [24, 78]
        m.descriptionLabel.width = cardWidth - 48
        m.descriptionLabel.height = 56
        m.descriptionLabel.text = bodyText
        m.descriptionLabel.numLines = 2
        m.descriptionLabel.vertAlign = "center"
        m.descriptionLabel.horizAlign = "center"

        if item.doesExist("footertext") and item.footertext <> invalid and item.footertext <> "" then
            m.voteLabel.text = item.footertext
            m.voteLabel.translation = [20, cardHeight - 64]
            m.voteLabel.width = cardWidth - 40
            m.voteLabel.height = 24
            m.voteLabel.horizAlign = "center"
        end if

        renderVoterIcons(item, cardWidth, cardHeight)
        return
    end if

    if cardKind = "trivia_option" then
        m.titleLabel.text = ""
        m.voteLabel.text = ""
        if hasCardColor then
            applyCardColor(m.accent, item.cardcolor)
        end if
        m.descriptionLabel.vertAlign = "center"
        m.descriptionLabel.horizAlign = "center"
        m.descriptionLabel.numLines = 5
        hideAllVoterIcons()
        return
    end if

    if cardKind = "leaderboard" then
        m.accent.color = "0x64D2FFFF"
        m.descriptionLabel.text = ""
        m.descriptionLabel.numLines = 1
        m.descriptionLabel.vertAlign = "top"
        m.descriptionLabel.horizAlign = "center"
        hideAllVoterIcons()
        return
    end if


    if cardKind = "status_grid" then
        m.accent.color = "0x27C2FFFF"
        m.titleLabel.translation = [18, 18]
        m.titleLabel.width = cardWidth - 36
        m.titleLabel.height = 40
        m.titleLabel.font = "font:MediumBoldSystemFont"
        m.titleLabel.horizAlign = "center"
        m.titleLabel.numLines = 2

        m.descriptionLabel.translation = [18, 66]
        m.descriptionLabel.width = cardWidth - 36
        m.descriptionLabel.height = 48
        m.descriptionLabel.numLines = 2
        m.descriptionLabel.vertAlign = "center"
        m.descriptionLabel.horizAlign = "center"
        m.descriptionLabel.font = "font:SmallSystemFont"
        m.descriptionLabel.color = "0xF4F7FBFF"

        m.voteLabel.translation = [18, cardHeight - 42]
        m.voteLabel.width = cardWidth - 36
        m.voteLabel.height = 24
        m.voteLabel.horizAlign = "center"
        m.voteLabel.font = "font:SmallBoldSystemFont"
        m.voteLabel.color = "0x7FD8FFFF"

        if item.doesExist("footertext") and item.footertext <> invalid and item.footertext <> "" then
            footerValue = LCase(item.footertext)
            if Instr(1, footerValue, "speaking") > 0 or Instr(1, footerValue, "current turn") > 0 then
                m.card.color = "0x1C3D5EFF"
                m.accent.color = "0x4DDB8AFF"
                m.voteLabel.color = "0xB5F2CDFF"
            else if Instr(1, footerValue, "imposter") > 0 then
                m.card.color = "0x3A1E3AFF"
                m.accent.color = "0xFF6C81FF"
                m.voteLabel.color = "0xFFD0D8FF"
            end if
        end if

        hideAllVoterIcons()
        return
    end if

    if hasCardColor then
        m.titleLabel.text = ""
        m.voteLabel.text = ""
    else if bodyText = "" and itemTitle <> "" then
        m.titleLabel.text = ""
        m.descriptionLabel.text = itemTitle
        m.descriptionLabel.numLines = 2
    end if

    hideAllVoterIcons()
end sub


sub hideWordGuessProgressGroup()
    if m.wordGuessProgressGroup <> invalid then m.wordGuessProgressGroup.visible = false
    if m.progressMetaLabel <> invalid then m.progressMetaLabel.text = ""
    for i = 0 to 4
        if m.progressTiles[i] <> invalid then
            m.progressTiles[i].visible = false
            m.progressTiles[i].color = "0x203246FF"
            m.progressTiles[i].translation = [0, 0]
            m.progressTiles[i].width = 62
            m.progressTiles[i].height = 62
        end if
        if m.progressTileLabels[i] <> invalid then
            m.progressTileLabels[i].visible = false
            m.progressTileLabels[i].text = ""
            m.progressTileLabels[i].translation = [0, 0]
            m.progressTileLabels[i].width = 62
            m.progressTileLabels[i].height = 62
        end if
    end for
end sub

sub renderWordGuessProgressRow(item as Object, cardWidth as Float, cardHeight as Float)
    hideWordGuessProgressGroup()

    rankText = ""
    if item.doesExist("votecount") and item.votecount <> invalid then rankText = item.votecount

    playerName = ""
    if item.doesExist("title") and item.title <> invalid then playerName = item.title

    footerText = ""
    if item.doesExist("footertext") and item.footertext <> invalid then footerText = item.footertext

    scoreText = ""
    if item.doesExist("scoretext") and item.scoretext <> invalid then scoreText = item.scoretext

    characterSlug = ""
    if item.doesExist("description") and item.description <> invalid then characterSlug = item.description

    guessText = ""
    if item.doesExist("bodytext") and item.bodytext <> invalid then guessText = UCase(item.bodytext)

    progressStates = []
    if item.doesExist("progressstates") and item.progressstates <> invalid and item.progressstates <> "" then
        progressStates = item.progressstates.split(",")
    end if

    leftPad = 16
    rightPad = 16
    rankWidth = 28
    iconSize = 42
    if cardHeight < 90 then iconSize = 34
    nameWidth = 170
    if cardWidth < 900 then nameWidth = 150
    tileSize = 46
    tileGap = 6
    if cardHeight < 108 then
        tileSize = 40
        tileGap = 4
    end if
    tilesWidth = (tileSize * 5) + (tileGap * 4)
    scoreWidth = 100

    iconX = leftPad + rankWidth + 10
    nameX = iconX + iconSize + 10
    tilesX = nameX + nameWidth + 18
    scoreX = cardWidth - rightPad - scoreWidth
    if tilesX + tilesWidth > scoreX - 8 then
        nameWidth = scoreX - tilesWidth - 8 - nameX - 18
        if nameWidth < 96 then nameWidth = 96
        tilesX = nameX + nameWidth + 18
    end if

    centerY = Int((cardHeight - iconSize) / 2)
    labelY = Int((cardHeight - 32) / 2)
    tileY = Int((cardHeight - tileSize) / 2) - 8
    metaY = tileY + tileSize + 8

    m.card.color = "0x0A1C2CFF"
    m.accent.color = "0x27C2FFFF"
    m.accent.translation = [0, 0]
    m.accent.width = cardWidth
    m.accent.height = 8

    m.titleLabel.text = rankText + "."
    m.titleLabel.translation = [leftPad, labelY]
    m.titleLabel.width = rankWidth
    m.titleLabel.height = 32
    m.titleLabel.horizAlign = "right"
    m.titleLabel.vertAlign = "center"
    m.titleLabel.font = "font:SmallBoldSystemFont"
    m.titleLabel.color = "0x7FD8FFFF"
    m.titleLabel.numLines = 1

    m.descriptionLabel.text = playerName
    m.descriptionLabel.translation = [nameX, labelY - 10]
    m.descriptionLabel.width = nameWidth
    m.descriptionLabel.height = 28
    m.descriptionLabel.horizAlign = "left"
    m.descriptionLabel.vertAlign = "center"
    m.descriptionLabel.font = "font:MediumBoldSystemFont"
    m.descriptionLabel.color = "0xFFFFFFFF"
    m.descriptionLabel.numLines = 1

    m.voteLabel.text = scoreText
    m.voteLabel.translation = [scoreX, labelY - 10]
    m.voteLabel.width = scoreWidth
    m.voteLabel.height = 28
    m.voteLabel.horizAlign = "right"
    m.voteLabel.vertAlign = "center"
    m.voteLabel.font = "font:SmallBoldSystemFont"
    m.voteLabel.color = "0x7FD8FFFF"
    m.voteLabel.numLines = 1

    hideAllVoterIcons()
    if characterSlug <> "" then
        icon = m.voterIcons[0]
        icon.uri = characterPosterUri(characterSlug)
        icon.width = iconSize
        icon.height = iconSize
        icon.translation = [iconX, centerY]
        icon.visible = true
        m.voterIconGroup.visible = true
    end if

    if m.wordGuessProgressGroup <> invalid then
        m.wordGuessProgressGroup.visible = true
    end if

    tileStartX = tilesX
    normalizedGuess = guessText
    if Len(normalizedGuess) < 5 then
        while Len(normalizedGuess) < 5
            normalizedGuess = normalizedGuess + " "
        end while
    end if

    for i = 0 to 4
        tileColor = "0x203246FF"
        if i < progressStates.count() then
            state = LCase(progressStates[i])
            if state = "correct" or state = "green" then
                tileColor = "0x4DDB8AFF"
            else if state = "present" or state = "yellow" then
                tileColor = "0xEAB308FF"
            else if state = "absent" or state = "gray" or state = "grey" then
                tileColor = "0x5D6B7CFF"
            end if
        end if

        letter = ""
        if i < Len(normalizedGuess) then
            letter = Mid(normalizedGuess, i + 1, 1)
        end if
        if letter = " " then letter = ""

        tile = m.progressTiles[i]
        label = m.progressTileLabels[i]
        tile.translation = [tileStartX + (i * (tileSize + tileGap)), tileY]
        tile.width = tileSize
        tile.height = tileSize
        tile.color = tileColor
        tile.visible = true

        label.translation = tile.translation
        label.width = tileSize
        label.height = tileSize
        label.text = letter
        label.visible = true
    end for

    m.progressMetaLabel.translation = [tileStartX, metaY]
    m.progressMetaLabel.width = tilesWidth
    m.progressMetaLabel.height = 24
    m.progressMetaLabel.text = footerText
    m.progressMetaLabel.visible = footerText <> ""
end sub

sub renderLeaderboardBar(item as Object, cardWidth as Float, cardHeight as Float)
    barRatio = 0.0
    if item.doesExist("description") and item.description <> "" then
        parts = item.description.split("|")
        if parts.count() >= 2 then barRatio = Val(parts[1])
    end if

    rank = 0
    if item.doesExist("votecount") and item.votecount <> "" then
        rank = Val(item.votecount)
    end if

    playerName = ""
    if item.doesExist("title") then playerName = item.title

    scoreLabel = ""
    if item.doesExist("footertext") then scoreLabel = item.footertext

    characterSlug = ""
    if item.doesExist("bodytext") then characterSlug = item.bodytext

    leftPad = 16
    rightPad = 16
    iconSize = 40
    if cardHeight < 64 then iconSize = cardHeight - 12
    if iconSize < 24 then iconSize = 24
    rankWidth = 28
    scoreLabelWidth = 90
    nameLabelWidth = 140
    iconX = leftPad + rankWidth + 8
    nameX = iconX + iconSize + 8
    barX = nameX + nameLabelWidth + 10
    barWidth = cardWidth - barX - scoreLabelWidth - rightPad - 8
    if barWidth < 20 then barWidth = 20
    barHeight = 16
    if cardHeight < 64 then barHeight = 10
    centerLabelHeight = 30
    if cardHeight < 64 then centerLabelHeight = 24
    barY = Int((cardHeight - barHeight) / 2)
    centerY = Int((cardHeight - centerLabelHeight) / 2)

    m.titleLabel.text = rank.ToStr() + "."
    m.titleLabel.translation = [leftPad, centerY]
    m.titleLabel.width = rankWidth
    m.titleLabel.height = centerLabelHeight
    m.titleLabel.horizAlign = "right"
    m.titleLabel.color = "0x7FD8FFFF"
    m.titleLabel.font = "font:SmallBoldSystemFont"

    m.descriptionLabel.text = playerName
    m.descriptionLabel.translation = [nameX, centerY]
    m.descriptionLabel.width = nameLabelWidth
    m.descriptionLabel.height = centerLabelHeight
    m.descriptionLabel.numLines = 1
    m.descriptionLabel.vertAlign = "center"
    m.descriptionLabel.horizAlign = "left"
    m.descriptionLabel.color = "0xFFFFFFFF"
    m.descriptionLabel.font = "font:MediumBoldSystemFont"

    m.voteLabel.text = scoreLabel
    m.voteLabel.translation = [cardWidth - scoreLabelWidth - rightPad, centerY]
    m.voteLabel.width = scoreLabelWidth
    m.voteLabel.height = centerLabelHeight
    m.voteLabel.horizAlign = "right"
    m.voteLabel.color = "0x7FD8FFFF"
    m.voteLabel.font = "font:SmallBoldSystemFont"

    if rank = 1 then
        m.card.color = "0x0D2E4EFF"
        m.accent.color = "0x27C2FFFF"
    else if rank = 2 then
        m.card.color = "0x0E2840FF"
        m.accent.color = "0xA78BFAFF"
    else if rank = 3 then
        m.card.color = "0x0E2234FF"
        m.accent.color = "0xF59E0BFF"
    else
        m.card.color = "0x0A1C2CFF"
        m.accent.color = "0x3A5F7DFF"
    end if

    if characterSlug <> "" then
        icon = m.voterIcons[0]
        icon.uri = characterPosterUri(characterSlug)
        icon.width = iconSize
        icon.height = iconSize
        icon.translation = [iconX, Int((cardHeight - iconSize) / 2)]
        icon.visible = true
    else
        m.voterIcons[0].visible = false
    end if

    for i = 1 to 11
        m.voterIcons[i].visible = false
        m.voterIcons[i].uri = ""
    end for
    m.voterIconGroup.visible = characterSlug <> ""

    m.shadow.width = barWidth
    m.shadow.height = barHeight
    m.shadow.translation = [barX, barY]
    m.shadow.color = "0x1A3A55FF"

    fillWidth = Int(barWidth * barRatio)
    if fillWidth < 4 then fillWidth = 4
    if fillWidth > barWidth then fillWidth = barWidth

    m.accent.translation = [barX, barY]
    m.accent.width = fillWidth
    m.accent.height = barHeight
end sub

sub renderVoterIcons(item as Object, cardWidth as Float, cardHeight as Float)
    voterUrls = []
    if item.doesExist("votercharacterurls") and item.votercharacterurls <> invalid and item.votercharacterurls <> "" then
        voterUrls = item.votercharacterurls.split(",")
    end if

    iconCount = voterUrls.count()
    if iconCount = 0 then
        hideAllVoterIcons()
        return
    end if

    iconSize = 42
    iconSpacing = 6
    maxIcons = 12
    if iconCount > maxIcons then iconCount = maxIcons

    totalWidth = (iconSize * iconCount) + (iconSpacing * (iconCount - 1))
    startX = Int((cardWidth - totalWidth) / 2)
    iconY = Int(cardHeight - 40 - iconSize)

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

sub resetCardVisualState(cardWidth as Float, cardHeight as Float)
    m.shadow.translation = [6, 8]
    m.shadow.color = "0x08111DCC"
    m.card.opacity = 1.0
    m.card.color = "0x173049FF"
    m.accent.translation = [0, 0]
    m.accent.width = cardWidth
    m.accent.height = 10
    m.accent.color = "0x27C2FFFF"

    m.titleLabel.text = ""
    m.titleLabel.color = "0xFFFFFFFF"
    m.titleLabel.font = "font:MediumBoldSystemFont"
    m.titleLabel.horizAlign = "left"
    m.titleLabel.vertAlign = "center"
    m.titleLabel.numLines = 2

    m.descriptionLabel.text = ""
    m.descriptionLabel.color = "0xF4F7FBFF"
    m.descriptionLabel.font = "font:MediumSystemFont"
    m.descriptionLabel.numLines = 5
    m.descriptionLabel.horizAlign = "center"
    m.descriptionLabel.vertAlign = "top"

    m.voteLabel.text = ""
    m.voteLabel.color = "0xD7E3FFFF"
    m.voteLabel.font = "font:SmallBoldSystemFont"
    m.voteLabel.horizAlign = "center"
    m.voteLabel.vertAlign = "center"
    m.voteLabel.numLines = 2

    hideAllVoterIcons()
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
    m.titleLabel.height = 54

    m.descriptionLabel.translation = [20, 66]
    m.descriptionLabel.width = cardWidth - 40
    m.descriptionLabel.height = cardHeight - 108

    m.voteLabel.translation = [20, cardHeight - 35]
    m.voteLabel.width = cardWidth - 40
    m.voteLabel.height = 34

    if cardWidth >= 500 then
        m.descriptionLabel.translation = [24, 30]
        m.descriptionLabel.width = cardWidth - 48
        m.descriptionLabel.height = cardHeight - 70
        m.descriptionLabel.numLines = 5
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

function characterPosterUri(characterSlug as String) as String
    if characterSlug = invalid or characterSlug = "" then return ""
    return "pkg:/images/Characters/" + characterSlug + ".png"
end function


sub applyCardColor(target as Object, colorValue as Dynamic)
    if target = invalid or colorValue = invalid then return
    if Type(colorValue) = "roString" or Type(colorValue) = "String" then
        if colorValue <> "" then target.color = colorValue
        return
    end if
    target.color = colorValue
end sub
