class 'CHUDGUI_EndStats' (GUIScript)

local kButtonClickSound = "sound/NS2.fev/common/button_click"
local kMouseHoverSound = "sound/NS2.fev/common/hovar"
local kSlideSound = "sound/NS2.fev/marine/commander/hover_ui"
Client.PrecacheLocalSound(kButtonClickSound)
Client.PrecacheLocalSound(kMouseHoverSound)
Client.PrecacheLocalSound(kSlideSound)

local kScreenScaleAspect = 1280
local screenWidth = Client.GetScreenWidth()
local screenHeight = Client.GetScreenHeight()
local aspectRatio = screenWidth/screenHeight

local kSteamProfileURL = "http://steamcommunity.com/profiles/"
local kHiveProfileURL = "http://hive.naturalselection2.com/profile/"
local kNS2StatsProfileURL = "http://ns2stats.com/player/ns2id/"

local function ScreenSmallAspect()
	return ConditionalValue(screenWidth > screenHeight, screenHeight, screenWidth)
end

local function GUILinearScale(size)
	-- 25% bigger so it's similar size to the "normal" GUIScale
	local scale = 1.25
	-- Text is hard to read on lower res, so make it bigger for them
	if screenWidth < 1920 then
		scale = 1.5
	end
	return (ScreenSmallAspect() / kScreenScaleAspect)*size*scale
end

-- To avoid printing 200.00 or things like that
local function printNum(number)
	if number and IsNumber(number) then
		if number == math.floor(number) then
			return string.format("%d", number)
		else
			return string.format("%.2f", number)
		end
	else
		return "NaN"
	end
end

local kTitleFontName = Fonts.kAgencyFB_Medium
local kSubTitleFontName = Fonts.kAgencyFB_Small
local kRowFontName = Fonts.kArial_17
local widthPercentage = ConditionalValue(aspectRatio < 1.5, 0.95, 0.75)
local kTitleSize = Vector(screenWidth*widthPercentage, GUILinearScale(74), 0)
local kCardSize = Vector(kTitleSize.x/3.5, GUILinearScale(74), 0)
local kCloseButtonSize = Vector(GUILinearScale(24), GUILinearScale(24), 0)
local scaledVector = GUILinearScale(Vector(1,1,1))
local kTopOffset = GUILinearScale(32)

local kMarineStatsColor = Color(0, 0.75, 0.88, 0.65)
local kAlienStatsColor = Color(0.84, 0.48, 0.17, 0.65)
local kCommanderStatsColor = Color(0.75, 0.75, 0, 0.65)
local kStatsHeaderBgColor = Color(0, 0, 0, 0.9)
local kStatsHeaderTextColor = Color(1, 1, 1, 1)
local kPlayerStatsTextColor = Color(1, 1, 1, 1)
local kMarinePlayerStatsEvenColor = Color(0, 0, 0, 0.75)
local kMarinePlayerStatsOddColor = Color(0, 0, 0, 0.65)
local kAlienPlayerStatsEvenColor = Color(0, 0, 0, 0.75)
local kAlienPlayerStatsOddColor = Color(0, 0, 0, 0.65)
local kCurrentPlayerStatsColor = Color(1, 1, 1, 0.75)
local kCurrentPlayerStatsTextColor = Color(0, 0, 0, 1)
local kCommanderStatsEvenColor = kMarinePlayerStatsEvenColor
local kCommanderStatsOddColor = kMarinePlayerStatsOddColor
local kHeaderRowColor = Color(0, 0, 0, 0)
local kMarineHeaderRowTextColor = Color(1, 1, 1, 1)
local kMarineHeaderRowTextHighlightColor = Color(0, 0, 0, 1)
local kAlienHeaderRowTextColor = Color(1, 1, 1, 1)
local kAlienHeaderRowTextHighlightColor = Color(0, 0, 0, 1)
local kAverageRowColor = Color(0.05, 0.05, 0.05, 0.25)
local kAverageRowTextColor = Color(1, 1, 1, 1)

local kHeaderTexture = PrecacheAsset("ui/statsheader.dds")
local kHeaderCoordsLeft = { 0, 0, 15, 64 }
local kHeaderCoordsMiddle = { 16, 0, 112, 64 }
local kHeaderCoordsRight = { 113, 0, 128, 64 }
local kMarineStatsLogo = PrecacheAsset("ui/logo_marine.dds")
local kAlienStatsLogo = PrecacheAsset("ui/logo_alien.dds")
local kLogoSize = GUILinearScale(Vector(52, 52, 0))
local kLogoOffset = GUILinearScale(4)
local kTeamNameOffset = GUILinearScale(10)
local kTextShadowOffset = GUILinearScale(2)
local kPlayerCountOffset = -GUILinearScale(20)
local kContentMaxYSize = screenHeight - GUILinearScale(128) - kTopOffset

local kRowSize = Vector(kTitleSize.x-(kLogoSize.x+kTeamNameOffset)*2, GUILinearScale(24), 0)
local kCardRowSize = Vector(kCardSize.x*0.85, GUILinearScale(24), 0)
local kTableContainerOffset = GUILinearScale(5)
local kRowBorderSize = GUILinearScale(2)
local kRowPlayerNameOffset = GUILinearScale(10)

local finalStatsTable = {}
local avgAccTable = {}
local miscDataTable = {}
local cardsTable = {}

local lastStatsMsg = -100
local lastGameEnd = 0
local kMaxAppendTime = 2.5
local loadedLastRound = false
local lastRoundFile = "config://NS2Plus/LastRoundStats.json"

local highlightedField = nil
local highlightedFieldMarine = nil
local lastSortedT1 = "kills"
local lastSortedT1WasInv = false
local lastSortedT2 = "kills"
local lastSortedT2WasInv = false

function CHUDGUI_EndStats:CreateTeamBackground(teamNumber)

	local color = kMarineStatsColor
	local teamLogo = kMarineStatsLogo
	local teamName = "Frontiersmen"
	
	if teamNumber == 2 then
		color = kAlienStatsColor
		teamLogo = kAlienStatsLogo
		teamName = "Kharaa"
	end
	
	local item = {}
	
	item.background = GUIManager:CreateGraphicItem()
	item.background:SetStencilFunc(GUIItem.NotEqual)
	item.background:SetColor(color)
	item.background:SetTexture(kHeaderTexture)
	item.background:SetTexturePixelCoordinates(unpack(kHeaderCoordsMiddle))
	item.background:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.background:SetInheritsParentAlpha(false)
	item.background:SetLayer(kGUILayerMainMenu)
	item.background:SetSize(Vector(kTitleSize.x-GUILinearScale(64), kTitleSize.y, 0))
	
	item.backgroundLeft = GUIManager:CreateGraphicItem()
	item.backgroundLeft:SetStencilFunc(GUIItem.NotEqual)
	item.backgroundLeft:SetColor(color)
	item.backgroundLeft:SetTexture(kHeaderTexture)
	item.backgroundLeft:SetTexturePixelCoordinates(unpack(kHeaderCoordsLeft))
	item.backgroundLeft:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.backgroundLeft:SetInheritsParentAlpha(false)
	item.backgroundLeft:SetLayer(kGUILayerMainMenu)
	item.backgroundLeft:SetSize(Vector(GUILinearScale(16), kTitleSize.y, 0))
	item.backgroundLeft:SetPosition(Vector(-GUILinearScale(16), 0, 0))
	item.background:AddChild(item.backgroundLeft)
	
	item.backgroundRight = GUIManager:CreateGraphicItem()
	item.backgroundRight:SetStencilFunc(GUIItem.NotEqual)
	item.backgroundRight:SetColor(color)
	item.backgroundRight:SetTexture(kHeaderTexture)
	item.backgroundRight:SetTexturePixelCoordinates(unpack(kHeaderCoordsRight))
	item.backgroundRight:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.backgroundRight:SetInheritsParentAlpha(false)
	item.backgroundRight:SetLayer(kGUILayerMainMenu)
	item.backgroundRight:SetSize(Vector(GUILinearScale(16), kTitleSize.y, 0))
	item.backgroundRight:SetPosition(Vector(kTitleSize.x-GUILinearScale(64), 0, 0))
	item.background:AddChild(item.backgroundRight)
	
	item.tableBackground = GUIManager:CreateGraphicItem()
	item.tableBackground:SetStencilFunc(GUIItem.NotEqual)
	item.tableBackground:SetColor(color)
	item.tableBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
	item.tableBackground:SetPosition(Vector(-(kRowSize.x+kRowBorderSize*2)/2, -kTableContainerOffset, 0))
	item.tableBackground:SetLayer(kGUILayerMainMenu)
	item.tableBackground:SetSize(Vector(kRowSize.x + kRowBorderSize*2, kRowBorderSize*2, 0))
	item.background:AddChild(item.tableBackground)
	
	item.logo = GUIManager:CreateGraphicItem()
	item.logo:SetStencilFunc(GUIItem.NotEqual)
	item.logo:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.logo:SetLayer(kGUILayerMainMenu)
	item.logo:SetIsVisible(true)
	item.logo:SetSize(kLogoSize)
	item.logo:SetPosition(Vector(kLogoOffset, -kLogoSize.y/2, 0))
	item.logo:SetTexture(teamLogo)
	item.background:AddChild(item.logo)
	
	item.teamNameTextShadow = GUIManager:CreateTextItem()
	item.teamNameTextShadow:SetStencilFunc(GUIItem.NotEqual)
	item.teamNameTextShadow:SetFontName(kTitleFontName)
	item.teamNameTextShadow:SetColor(Color(0,0,0,1))
	item.teamNameTextShadow:SetScale(scaledVector)
	item.teamNameTextShadow:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.teamNameTextShadow:SetText(teamName)
	item.teamNameTextShadow:SetTextAlignmentY(GUIItem.Align_Center)
	item.teamNameTextShadow:SetPosition(Vector(kLogoSize.x + kTeamNameOffset + kTextShadowOffset, kTitleSize.y/2 + kTextShadowOffset, 0))
	item.teamNameTextShadow:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.teamNameTextShadow)
	
	item.teamNameText = GUIManager:CreateTextItem()
	item.teamNameText:SetStencilFunc(GUIItem.NotEqual)
	item.teamNameText:SetFontName(kTitleFontName)
	item.teamNameText:SetColor(Color(1,1,1,1))
	item.teamNameText:SetScale(scaledVector)
	item.teamNameText:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.teamNameText:SetText(teamName)
	item.teamNameText:SetTextAlignmentY(GUIItem.Align_Center)
	item.teamNameText:SetPosition(Vector(kLogoSize.x + kTeamNameOffset, kTitleSize.y/2, 0))
	item.teamNameText:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.teamNameText)
	
	item.teamGameStatusShadow = GUIManager:CreateTextItem()
	item.teamGameStatusShadow:SetStencilFunc(GUIItem.NotEqual)
	item.teamGameStatusShadow:SetFontName(kTitleFontName)
	item.teamGameStatusShadow:SetColor(Color(0,0,0,1))
	item.teamGameStatusShadow:SetScale(scaledVector)
	item.teamGameStatusShadow:SetAnchor(GUIItem.Middle, GUIItem.Center)
	item.teamGameStatusShadow:SetText("")
	item.teamGameStatusShadow:SetTextAlignmentY(GUIItem.Align_Center)
	item.teamGameStatusShadow:SetTextAlignmentX(GUIItem.Align_Center)
	item.teamGameStatusShadow:SetPosition(Vector(kTextShadowOffset, kTextShadowOffset, 0))
	item.teamGameStatusShadow:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.teamGameStatusShadow)
	
	item.teamGameStatus = GUIManager:CreateTextItem()
	item.teamGameStatus:SetStencilFunc(GUIItem.NotEqual)
	item.teamGameStatus:SetFontName(kTitleFontName)
	item.teamGameStatus:SetColor(Color(1,1,1,1))
	item.teamGameStatus:SetScale(scaledVector)
	item.teamGameStatus:SetAnchor(GUIItem.Middle, GUIItem.Center)
	item.teamGameStatus:SetText("")
	item.teamGameStatus:SetTextAlignmentY(GUIItem.Align_Center)
	item.teamGameStatus:SetTextAlignmentX(GUIItem.Align_Center)
	item.teamGameStatus:SetPosition(Vector(0, 0, 0))
	item.teamGameStatus:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.teamGameStatus)
	
	item.teamPlayerCountShadow = GUIManager:CreateTextItem()
	item.teamPlayerCountShadow:SetStencilFunc(GUIItem.NotEqual)
	item.teamPlayerCountShadow:SetFontName(kSubTitleFontName)
	item.teamPlayerCountShadow:SetColor(Color(0,0,0,1))
	item.teamPlayerCountShadow:SetScale(scaledVector)
	item.teamPlayerCountShadow:SetAnchor(GUIItem.Right, GUIItem.Center)
	item.teamPlayerCountShadow:SetText("")
	item.teamPlayerCountShadow:SetTextAlignmentY(GUIItem.Align_Center)
	item.teamPlayerCountShadow:SetTextAlignmentX(GUIItem.Align_Max)
	item.teamPlayerCountShadow:SetPosition(Vector(kPlayerCountOffset + kTextShadowOffset, kTextShadowOffset, 0))
	item.teamPlayerCountShadow:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.teamPlayerCountShadow)
	
	item.teamPlayerCount = GUIManager:CreateTextItem()
	item.teamPlayerCount:SetStencilFunc(GUIItem.NotEqual)
	item.teamPlayerCount:SetFontName(kSubTitleFontName)
	item.teamPlayerCount:SetColor(Color(1,1,1,1))
	item.teamPlayerCount:SetScale(scaledVector)
	item.teamPlayerCount:SetAnchor(GUIItem.Right, GUIItem.Center)
	item.teamPlayerCount:SetText("")
	item.teamPlayerCount:SetTextAlignmentY(GUIItem.Align_Center)
	item.teamPlayerCount:SetTextAlignmentX(GUIItem.Align_Max)
	item.teamPlayerCount:SetPosition(Vector(kPlayerCountOffset, 0, 0))
	item.teamPlayerCount:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.teamPlayerCount)

	return item

end

local function CreateScoreboardRow(container, bgColor, textColor, playerName, kills, assists, deaths, acc, pdmg, sdmg, timeBuilding, steamId)
	
	local containerSize = container:GetSize()
	container:SetSize(Vector(containerSize.x, containerSize.y + kRowSize.y, 0))
	
	local item = {}
	
	item.background = GUIManager:CreateGraphicItem()
	item.background:SetStencilFunc(GUIItem.NotEqual)
	item.background:SetColor(bgColor)
	item.background:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.background:SetPosition(Vector(kRowBorderSize, containerSize.y - kRowBorderSize, 0))
	item.background:SetLayer(kGUILayerMainMenu)
	item.background:SetSize(kRowSize)
	
	if steamId then
		item.steamId = steamId
	end
	
	container:AddChild(item.background)
	
	item.playerName = GUIManager:CreateTextItem()
	item.playerName:SetStencilFunc(GUIItem.NotEqual)
	item.playerName:SetFontName(kRowFontName)
	item.playerName:SetColor(textColor)
	item.playerName:SetScale(scaledVector)
	item.playerName:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.playerName:SetTextAlignmentY(GUIItem.Align_Center)
	item.playerName:SetPosition(Vector(kRowPlayerNameOffset, 0, 0))
	item.playerName:SetText(playerName)
	item.playerName:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.playerName)
	
	local kItemSize = GUILinearScale(50)
	local xOffset = kRowSize.x
	local kItemPaddingLarge = GUILinearScale(60)
	local kItemPaddingMedium = GUILinearScale(40)
	local kItemPaddingSmall = GUILinearScale(20)
	
	xOffset = xOffset - kItemSize
	
	item.timeBuilding = GUIManager:CreateTextItem()
	item.timeBuilding:SetStencilFunc(GUIItem.NotEqual)
	item.timeBuilding:SetFontName(kRowFontName)
	item.timeBuilding:SetColor(textColor)
	item.timeBuilding:SetScale(scaledVector)
	item.timeBuilding:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.timeBuilding:SetTextAlignmentY(GUIItem.Align_Center)
	item.timeBuilding:SetTextAlignmentX(GUIItem.Align_Center)
	item.timeBuilding:SetPosition(Vector(xOffset, 0, 0))
	item.timeBuilding:SetText(timeBuilding)
	item.timeBuilding:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.timeBuilding)
	
	xOffset = xOffset - kItemSize - kItemPaddingLarge
	
	item.sdmg = GUIManager:CreateTextItem()
	item.sdmg:SetStencilFunc(GUIItem.NotEqual)
	item.sdmg:SetFontName(kRowFontName)
	item.sdmg:SetColor(textColor)
	item.sdmg:SetScale(scaledVector)
	item.sdmg:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.sdmg:SetTextAlignmentY(GUIItem.Align_Center)
	item.sdmg:SetTextAlignmentX(GUIItem.Align_Center)
	item.sdmg:SetPosition(Vector(xOffset, 0, 0))
	item.sdmg:SetText(sdmg)
	item.sdmg:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.sdmg)
	
	xOffset = xOffset - kItemSize - kItemPaddingLarge
	
	item.pdmg = GUIManager:CreateTextItem()
	item.pdmg:SetStencilFunc(GUIItem.NotEqual)
	item.pdmg:SetFontName(kRowFontName)
	item.pdmg:SetColor(textColor)
	item.pdmg:SetScale(scaledVector)
	item.pdmg:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.pdmg:SetTextAlignmentY(GUIItem.Align_Center)
	item.pdmg:SetTextAlignmentX(GUIItem.Align_Center)
	item.pdmg:SetPosition(Vector(xOffset, 0, 0))
	item.pdmg:SetText(pdmg)
	item.pdmg:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.pdmg)
	
	xOffset = xOffset - kItemSize - kItemPaddingLarge
	
	item.acc = GUIManager:CreateTextItem()
	item.acc:SetStencilFunc(GUIItem.NotEqual)
	item.acc:SetFontName(kRowFontName)
	item.acc:SetColor(textColor)
	item.acc:SetScale(scaledVector)
	item.acc:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.acc:SetTextAlignmentY(GUIItem.Align_Center)
	item.acc:SetTextAlignmentX(GUIItem.Align_Center)
	item.acc:SetPosition(Vector(xOffset, 0, 0))
	item.acc:SetText(acc)
	item.acc:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.acc)
	
	xOffset = xOffset - kItemSize - kItemPaddingMedium
	
	item.deaths = GUIManager:CreateTextItem()
	item.deaths:SetStencilFunc(GUIItem.NotEqual)
	item.deaths:SetFontName(kRowFontName)
	item.deaths:SetColor(textColor)
	item.deaths:SetScale(scaledVector)
	item.deaths:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.deaths:SetTextAlignmentY(GUIItem.Align_Center)
	item.deaths:SetTextAlignmentX(GUIItem.Align_Center)
	item.deaths:SetPosition(Vector(xOffset, 0, 0))
	item.deaths:SetText(deaths)
	item.deaths:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.deaths)
	
	xOffset = xOffset - kItemSize - kItemPaddingSmall
	
	item.assists = GUIManager:CreateTextItem()
	item.assists:SetStencilFunc(GUIItem.NotEqual)
	item.assists:SetFontName(kRowFontName)
	item.assists:SetColor(textColor)
	item.assists:SetScale(scaledVector)
	item.assists:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.assists:SetTextAlignmentY(GUIItem.Align_Center)
	item.assists:SetTextAlignmentX(GUIItem.Align_Center)
	item.assists:SetPosition(Vector(xOffset, 0, 0))
	item.assists:SetText(assists)
	item.assists:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.assists)
	
	xOffset = xOffset - kItemSize - kItemPaddingSmall
	
	item.kills = GUIManager:CreateTextItem()
	item.kills:SetStencilFunc(GUIItem.NotEqual)
	item.kills:SetFontName(kRowFontName)
	item.kills:SetColor(textColor)
	item.kills:SetScale(scaledVector)
	item.kills:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.kills:SetTextAlignmentY(GUIItem.Align_Center)
	item.kills:SetTextAlignmentX(GUIItem.Align_Center)
	item.kills:SetPosition(Vector(xOffset, 0, 0))
	item.kills:SetText(kills)
	item.kills:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.kills)
	
	return item
	
end

function CHUDGUI_EndStats:CreateGraphicHeader(text, color, logoTexture, logoCoords, logoSizeX, logoSizeY)

	local item = {}
	
	item.background = GUIManager:CreateGraphicItem()
	item.background:SetStencilFunc(GUIItem.NotEqual)
	item.background:SetColor(color)
	item.background:SetTexture(kHeaderTexture)
	item.background:SetTexturePixelCoordinates(unpack(kHeaderCoordsMiddle))
	item.background:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.background:SetInheritsParentAlpha(false)
	item.background:SetLayer(kGUILayerMainMenu)
	item.background:SetSize(Vector(kCardSize.x-GUILinearScale(32), kCardSize.y, 0))
	self.background:AddChild(item.background)
	
	item.backgroundLeft = GUIManager:CreateGraphicItem()
	item.backgroundLeft:SetStencilFunc(GUIItem.NotEqual)
	item.backgroundLeft:SetColor(color)
	item.backgroundLeft:SetTexture(kHeaderTexture)
	item.backgroundLeft:SetTexturePixelCoordinates(unpack(kHeaderCoordsLeft))
	item.backgroundLeft:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.backgroundLeft:SetInheritsParentAlpha(false)
	item.backgroundLeft:SetLayer(kGUILayerMainMenu)
	item.backgroundLeft:SetSize(Vector(GUILinearScale(16), kCardSize.y, 0))
	item.backgroundLeft:SetPosition(Vector(-GUILinearScale(16), 0, 0))
	item.background:AddChild(item.backgroundLeft)
	
	item.backgroundRight = GUIManager:CreateGraphicItem()
	item.backgroundRight:SetStencilFunc(GUIItem.NotEqual)
	item.backgroundRight:SetColor(color)
	item.backgroundRight:SetTexture(kHeaderTexture)
	item.backgroundRight:SetTexturePixelCoordinates(unpack(kHeaderCoordsRight))
	item.backgroundRight:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.backgroundRight:SetInheritsParentAlpha(false)
	item.backgroundRight:SetLayer(kGUILayerMainMenu)
	item.backgroundRight:SetSize(Vector(GUILinearScale(16), kCardSize.y, 0))
	item.backgroundRight:SetPosition(Vector(kCardSize.x-GUILinearScale(32), 0, 0))
	item.background:AddChild(item.backgroundRight)
	
	local xOffset = kLogoOffset
	
	if logoTexture then
		item.logo = GUIManager:CreateGraphicItem()
		item.logo:SetStencilFunc(GUIItem.NotEqual)
		item.logo:SetAnchor(GUIItem.Left, GUIItem.Center)
		item.logo:SetLayer(kGUILayerMainMenu)
		item.logo:SetIsVisible(true)
		item.logo:SetSize(Vector(logoSizeX, logoSizeY, 0))
		item.logo:SetPosition(Vector(kLogoOffset, -logoSizeY/2, 0))
		item.logo:SetTexture(logoTexture)
		if logoCoords then
			item.logo:SetTexturePixelCoordinates(unpack(logoCoords))
		end
		item.background:AddChild(item.logo)
		
		xOffset = xOffset + logoSizeX + kTeamNameOffset
	end
	
	item.textShadow = GUIManager:CreateTextItem()
	item.textShadow:SetStencilFunc(GUIItem.NotEqual)
	item.textShadow:SetFontName(kTitleFontName)
	item.textShadow:SetColor(Color(0,0,0,1))
	item.textShadow:SetScale(scaledVector)
	item.textShadow:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.textShadow:SetText(text)
	item.textShadow:SetTextAlignmentY(GUIItem.Align_Center)
	item.textShadow:SetPosition(Vector(xOffset + kTextShadowOffset, kCardSize.y/2 + kTextShadowOffset, 0))
	item.textShadow:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.textShadow)
	
	item.text = GUIManager:CreateTextItem()
	item.text:SetStencilFunc(GUIItem.NotEqual)
	item.text:SetFontName(kTitleFontName)
	item.text:SetColor(Color(1,1,1,1))
	item.text:SetScale(scaledVector)
	item.text:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.text:SetText(text)
	item.text:SetTextAlignmentY(GUIItem.Align_Center)
	item.text:SetPosition(Vector(xOffset, kCardSize.y/2, 0))
	item.text:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.text)
	
	item.tableBackground = GUIManager:CreateGraphicItem()
	item.tableBackground:SetStencilFunc(GUIItem.NotEqual)
	item.tableBackground:SetColor(color)
	item.tableBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
	item.tableBackground:SetPosition(Vector(-(kCardRowSize.x+kRowBorderSize*2)/2, -kTableContainerOffset, 0))
	item.tableBackground:SetLayer(kGUILayerMainMenu)
	item.tableBackground:SetSize(Vector(kCardRowSize.x + kRowBorderSize*2, kRowBorderSize*2, 0))
	item.background:AddChild(item.tableBackground)
	
	return item
end

local function CreateHeaderRow(container, bgColor, textColor, leftText, rightText)
	
	local containerSize = container:GetSize()
	container:SetSize(Vector(containerSize.x, containerSize.y + kCardRowSize.y, 0))
	
	local item = {}
	
	item.background = GUIManager:CreateGraphicItem()
	item.background:SetStencilFunc(GUIItem.NotEqual)
	item.background:SetColor(bgColor)
	item.background:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.background:SetPosition(Vector(kRowBorderSize, containerSize.y - kRowBorderSize, 0))
	item.background:SetLayer(kGUILayerMainMenu)
	item.background:SetSize(kCardRowSize)
	
	container:AddChild(item.background)
	
	item.leftText = GUIManager:CreateTextItem()
	item.leftText:SetStencilFunc(GUIItem.NotEqual)
	item.leftText:SetFontName(kRowFontName)
	item.leftText:SetColor(textColor)
	item.leftText:SetScale(scaledVector)
	item.leftText:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.leftText:SetTextAlignmentY(GUIItem.Align_Center)
	item.leftText:SetPosition(Vector(GUILinearScale(5), 0, 0))
	item.leftText:SetText(leftText)
	item.leftText:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.leftText)
	
	item.rightText = GUIManager:CreateTextItem()
	item.rightText:SetStencilFunc(GUIItem.NotEqual)
	item.rightText:SetFontName(kRowFontName)
	item.rightText:SetColor(textColor)
	item.rightText:SetScale(scaledVector)
	item.rightText:SetAnchor(GUIItem.Right, GUIItem.Center)
	item.rightText:SetTextAlignmentX(GUIItem.Align_Max)
	item.rightText:SetTextAlignmentY(GUIItem.Align_Center)
	item.rightText:SetPosition(Vector(-GUILinearScale(5), 0, 0))
	item.rightText:SetText(rightText)
	item.rightText:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.rightText)
	
	return item
	
end

function CHUDGUI_EndStats:SetPlayerCount(teamItem, playerCount)
	if playerCount and IsNumber(playerCount) then
		local playerString = string.format("%d %s", playerCount, ConditionalValue(playerCount == 1, Locale.ResolveString("PLAYER"), Locale.ResolveString("PLAYERS")))
		teamItem.teamPlayerCountShadow:SetText(playerString)
		teamItem.teamPlayerCount:SetText(playerString)
	else
		teamItem.teamPlayerCountShadow:SetText("")
		teamItem.teamPlayerCount:SetText("")
	end
end

function CHUDGUI_EndStats:SetGameResult(teamItem, result)
	teamItem.teamGameStatusShadow:SetText(result)
	teamItem.teamGameStatus:SetText(result)
end

function CHUDGUI_EndStats:SetTeamName(teamItem, teamName)
	if teamName == nil then
		teamName = ""
	end
	teamItem.teamNameTextShadow:SetText(teamName)
	teamItem.teamNameText:SetText(teamName)
end

function CHUDGUI_EndStats:Initialize()

	self.header = GUIManager:CreateGraphicItem()
	self.header:SetColor(Color(0, 0, 0, 0.5))
	self.header:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.header:SetSize(kTitleSize)
	self.header:SetPosition(Vector(-kTitleSize.x/2, kTopOffset, 0))
	self.header:SetLayer(kGUILayerMainMenu)
	
	self.closeButton = GUIManager:CreateGraphicItem()
	self.closeButton:SetAnchor(GUIItem.Right, GUIItem.Top)
	self.closeButton:SetSize(kCloseButtonSize)
	self.closeButton:SetPosition(Vector(GUILinearScale(8), 0, 0))
	self.closeButton:SetLayer(kGUILayerMainMenu)
	self.header:AddChild(self.closeButton)
	
	self.closeText = GUIManager:CreateTextItem()
	self.closeText:SetColor(Color(1, 1, 1, 1))
	self.closeText:SetAnchor(GUIItem.Middle, GUIItem.Center)
	self.closeText:SetText("X")
	self.closeText:SetScale(scaledVector)
	self.closeText:SetFontName(kSubTitleFontName)
	self.closeText:SetTextAlignmentX(GUIItem.Align_Center)
	self.closeText:SetTextAlignmentY(GUIItem.Align_Center)
	self.closeText:SetPosition(Vector(0, GUILinearScale(2), 0))
	self.closeText:SetLayer(kGUILayerMainMenu)
	self.closeButton:AddChild(self.closeText)
	
	self.roundDate = GUIManager:CreateTextItem()
	self.roundDate:SetFontName(kSubTitleFontName)
	self.roundDate:SetColor(Color(1,1,1,1))
	self.roundDate:SetScale(scaledVector)
	self.roundDate:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.roundDate:SetPosition(Vector(GUILinearScale(10), GUILinearScale(4), 0))
	self.roundDate:SetLayer(kGUILayerMainMenu)
	self.header:AddChild(self.roundDate)
	
	self.serverName = GUIManager:CreateTextItem()
	self.serverName:SetFontName(kSubTitleFontName)
	self.serverName:SetColor(Color(1,1,1,1))
	self.serverName:SetScale(scaledVector)
	self.serverName:SetAnchor(GUIItem.Left, GUIItem.Bottom)
	self.serverName:SetPosition(Vector(GUILinearScale(10), GUILinearScale(-4), 0))
	self.serverName:SetTextAlignmentY(GUIItem.Align_Max)
	self.serverName:SetLayer(kGUILayerMainMenu)
	self.header:AddChild(self.serverName)
	
	self.gameLength = GUIManager:CreateTextItem()
	self.gameLength:SetFontName(kSubTitleFontName)
	self.gameLength:SetColor(Color(1,1,1,1))
	self.gameLength:SetScale(scaledVector)
	self.gameLength:SetAnchor(GUIItem.Right, GUIItem.Top)
	self.gameLength:SetPosition(Vector(GUILinearScale(-10), GUILinearScale(4), 0))
	self.gameLength:SetTextAlignmentX(GUIItem.Align_Max)
	self.gameLength:SetLayer(kGUILayerMainMenu)
	self.header:AddChild(self.gameLength)
	
	self.mapName = GUIManager:CreateTextItem()
	self.mapName:SetFontName(kSubTitleFontName)
	self.mapName:SetColor(Color(1,1,1,1))
	self.mapName:SetScale(scaledVector)
	self.mapName:SetAnchor(GUIItem.Right, GUIItem.Bottom)
	self.mapName:SetPosition(Vector(GUILinearScale(-10), GUILinearScale(-4), 0))
	self.mapName:SetTextAlignmentX(GUIItem.Align_Max)
	self.mapName:SetTextAlignmentY(GUIItem.Align_Max)
	self.mapName:SetLayer(kGUILayerMainMenu)
	self.header:AddChild(self.mapName)
	
	self.team1UI = self:CreateTeamBackground(1)
	self.team1UI.playerRows = {}
	table.insert(self.team1UI.playerRows, CreateScoreboardRow(self.team1UI.tableBackground, kHeaderRowColor, kMarineHeaderRowTextColor, "Player name", "Kills", "Assists", "Deaths", "Acc. (No Onos)", "Player dmg", "Structure dmg", "Time building"))
	self.team2UI = self:CreateTeamBackground(2)
	self.team2UI.playerRows = {}
	table.insert(self.team2UI.playerRows, CreateScoreboardRow(self.team2UI.tableBackground, kHeaderRowColor, kAlienHeaderRowTextColor, "Player name", "Kills", "Assists", "Deaths", "Accuracy", "Player dmg", "Structure dmg", "Time building"))
	
	self.sliderBarBg = GUIManager:CreateGraphicItem()
	self.sliderBarBg:SetColor(Color(0,0,0,0.5))
	self.sliderBarBg:SetSize(Vector(GUILinearScale(8), kContentMaxYSize, 0))
	self.sliderBarBg:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.sliderBarBg:SetPosition(Vector((kTitleSize.x+GUILinearScale(32))/2, GUILinearScale(128), 0))
	self.sliderBarBg:SetLayer(kGUILayerMainMenu)
	
	self.slider = GUIManager:CreateGraphicItem()
	self.slider:SetColor(Color(1,1,1,1))
	self.slider:SetSize(Vector(GUILinearScale(16), GUILinearScale(8), 0))
	self.slider:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.slider:SetLayer(kGUILayerMainMenu)
	self.sliderBarBg:AddChild(self.slider)
	
	self.contentBackground = GUIManager:CreateGraphicItem()
	self.contentBackground:SetColor(Color(0,0,0,0.5))
	self.contentBackground:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.contentBackground:SetPosition(Vector(-kTitleSize.x/2, GUILinearScale(128), 0))
	self.contentBackground:SetSize(Vector(kTitleSize.x, kContentMaxYSize, 0))
	self.contentBackground:SetLayer(kGUILayerMainMenu)
	
	self.contentStencil = GUIManager:CreateGraphicItem()
	self.contentStencil:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.contentStencil:SetPosition(Vector(-kTitleSize.x/2, GUILinearScale(128), 0))
	self.contentStencil:SetSize(Vector(kTitleSize.x, kContentMaxYSize, 0))
	self.contentStencil:SetIsStencil(true)
	self.contentStencil:SetClearsStencilBuffer(true)
	self.contentStencil:SetLayer(kGUILayerMainMenu)
	
	self.background = GUIManager:CreateGraphicItem()
	self.background:SetColor(Color(0,0,0,0))
	self.background:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.background:SetPosition(Vector(-(kTitleSize.x-GUILinearScale(32))/2, GUILinearScale(128), 0))
	self.background:SetLayer(kGUILayerMainMenu)
	self.background:AddChild(self.team1UI.background)
	self.background:AddChild(self.team2UI.background)
	
	self.teamStatsTextShadow = GUIManager:CreateTextItem()
	self.teamStatsTextShadow:SetStencilFunc(GUIItem.NotEqual)
	self.teamStatsTextShadow:SetFontName(kTitleFontName)
	self.teamStatsTextShadow:SetColor(Color(0,0,0,1))
	self.teamStatsTextShadow:SetScale(scaledVector)
	self.teamStatsTextShadow:SetText("TEAM STATS")
	self.teamStatsTextShadow:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.teamStatsTextShadow:SetTextAlignmentX(GUIItem.Align_Center)
	self.teamStatsTextShadow:SetLayer(kGUILayerMainMenu)
	self.background:AddChild(self.teamStatsTextShadow)
	
	self.teamStatsText = GUIManager:CreateTextItem()
	self.teamStatsText:SetStencilFunc(GUIItem.NotEqual)
	self.teamStatsText:SetFontName(kTitleFontName)
	self.teamStatsText:SetColor(Color(1,1,1,1))
	self.teamStatsText:SetScale(scaledVector)
	self.teamStatsText:SetText("TEAM STATS")
	self.teamStatsText:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.teamStatsText:SetTextAlignmentX(GUIItem.Align_Center)
	self.teamStatsText:SetPosition(Vector(-kTextShadowOffset, -kTextShadowOffset, 0))
	self.teamStatsText:SetLayer(kGUILayerMainMenu)
	self.teamStatsTextShadow:AddChild(self.teamStatsText)
	
	self.yourStatsTextShadow = GUIManager:CreateTextItem()
	self.yourStatsTextShadow:SetStencilFunc(GUIItem.NotEqual)
	self.yourStatsTextShadow:SetFontName(kTitleFontName)
	self.yourStatsTextShadow:SetColor(Color(0,0,0,1))
	self.yourStatsTextShadow:SetScale(scaledVector)
	self.yourStatsTextShadow:SetText("YOUR STATS")
	self.yourStatsTextShadow:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.yourStatsTextShadow:SetTextAlignmentX(GUIItem.Align_Center)
	self.yourStatsTextShadow:SetLayer(kGUILayerMainMenu)
	self.background:AddChild(self.yourStatsTextShadow)
	
	self.yourStatsText = GUIManager:CreateTextItem()
	self.yourStatsText:SetStencilFunc(GUIItem.NotEqual)
	self.yourStatsText:SetFontName(kTitleFontName)
	self.yourStatsText:SetColor(Color(1,1,1,1))
	self.yourStatsText:SetScale(scaledVector)
	self.yourStatsText:SetText("YOUR STATS")
	self.yourStatsText:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.yourStatsText:SetTextAlignmentX(GUIItem.Align_Center)
	self.yourStatsText:SetPosition(Vector(-kTextShadowOffset, -kTextShadowOffset, 0))
	self.yourStatsText:SetLayer(kGUILayerMainMenu)
	self.yourStatsTextShadow:AddChild(self.yourStatsText)
	
	self.teamStatsTextShadow:SetPosition(Vector((kTitleSize.x-GUILinearScale(32))/2, GUILinearScale(16), 0))
	local yPos = GUILinearScale(48)
	self.team1UI.background:SetPosition(Vector(GUILinearScale(16), yPos, 0))
	yPos = yPos + self.team1UI.tableBackground:GetSize().y + self.team1UI.background:GetSize().y
	self.team2UI.background:SetPosition(Vector(GUILinearScale(16), yPos, 0))
	yPos = yPos + self.team2UI.tableBackground:GetSize().y + self.team2UI.background:GetSize().y + GUILinearScale(32)
	self.yourStatsTextShadow:SetPosition(Vector((kTitleSize.x-GUILinearScale(32))/2, yPos, 0))
	
	self.contentSize = yPos
	
	self.statsCards = {}
	
	self.saved = false
	self.prevRequestKey = false
	self.prevScoreKey = false
	self.isDragging = false
	self.slidePercentage = 0
	self.displayed = false
	
	lastSortedT1 = "kills"
	lastSortedT1WasInv = false
	lastSortedT2 = "kills"
	lastSortedT2WasInv = false
	
	if not loadedLastRound and GetFileExists(lastRoundFile) then
		local openedFile = io.open(lastRoundFile, "r")
		if openedFile then
		
			local parsedFile = json.decode(openedFile:read("*all"))
			io.close(openedFile)
			
			if parsedFile then
				finalStatsTable = parsedFile.finalStatsTable or {}
				avgAccTable = parsedFile.avgAccTable or {}
				miscDataTable = parsedFile.miscDataTable or {}
				cardsTable = parsedFile.cardsTable or {}
			end
			
			self.saved = true
			loadedLastRound = true
		end
	end
	
	self.actionIconGUI = GetGUIManager():CreateGUIScript("GUIActionIcon")
	self.actionIconGUI:SetColor(kWhite)
	self.actionIconGUI.pickupIcon:SetLayer(kGUILayerPlayerHUD)
	self.actionIconGUI:Hide()
	
	self.hoverMenu = GetGUIManager():CreateGUIScriptSingle("GUIHoverMenu")
	self.lastRow = nil
	
	self.background:SetIsVisible(false)
	self.header:SetIsVisible(false)
	self.sliderBarBg:SetIsVisible(false)
	self.contentBackground:SetIsVisible(false)
	self.contentStencil:SetIsVisible(false)
	
	CHUDEndStatsVisible = false
end

function CHUDGUI_EndStats:Uninitialize()

	if self:GetIsVisible() then
		MouseTracker_SetIsVisible(false)
	end
	
	GUI.DestroyItem(self.background)
	GUI.DestroyItem(self.header)
	GUI.DestroyItem(self.sliderBarBg)
	GUI.DestroyItem(self.contentBackground)
	GUI.DestroyItem(self.contentStencil)
	
	GetGUIManager():DestroyGUIScript(self.actionIconGUI)
	self.actionIconGUI = nil

end

function CHUDGUI_EndStats:SetIsVisible(visible)
	-- Don't try to display it if there is no content visible
	local gameInfo = GetGameInfoEntity()
	local teamStatsVisible = gameInfo and gameInfo.showEndStatsTeamBreakdown
	local visibleStats = teamStatsVisible and self.teamStatsTextShadow:GetIsVisible() or #self.statsCards > 0
	if visible ~= self:GetIsVisible() and ((visible and visibleStats) or not visible) then
		self.background:SetIsVisible(visible)
		self.header:SetIsVisible(visible)
		self.sliderBarBg:SetIsVisible(visible)
		self.contentBackground:SetIsVisible(visible)
		self.contentStencil:SetIsVisible(visible)
		
		CHUDEndStatsVisible = visible
		self.slidePercentage = 0
		
		if not visible then
			self.hoverMenu:Hide()
		end
		
		MouseTracker_SetIsVisible(visible)
	end
end

function CHUDGUI_EndStats:GetIsVisible()
	return self.background:GetIsVisible()
end

local function repositionStatsCards(self)
	-- Every row will have 3 items
	local numItemsPerRow = 3
	local numRows = math.ceil(#self.statsCards/numItemsPerRow)
	-- Determine the last row with 3 elements
	local last3Row = numItemsPerRow*(numRows-1)
	local cardSize = (kCardSize.x-GUILinearScale(32))
	local row = 0
	local tallestElem = 0
	local yPos = 0
	local xPos = 0
	local remainingElems = 0
	
	if #self.statsCards > 0 then
		yPos = self.yourStatsTextShadow:GetPosition().y + GUILinearScale(32)
		for index, card in ipairs(self.statsCards) do
			local curRow = math.ceil(index/3)
			local relativeIndex = index-((curRow-1)*numItemsPerRow)
			local ySize = card.tableBackground:GetSize().y + card.background:GetSize().y + GUILinearScale(16)
			if row == curRow and ySize > tallestElem then
				tallestElem = ySize
			elseif row ~= curRow then
				row = curRow
				yPos = yPos + tallestElem
				tallestElem = ySize
				remainingElems = #self.statsCards - index + 1
			end
			if index <= last3Row or remainingElems == 3 then
				xPos = (relativeIndex-2)*GUILinearScale(32)-cardSize*1.5+(relativeIndex-1)*cardSize
			elseif remainingElems == 2 then
				xPos = -cardSize+(2-relativeIndex)*cardSize+ConditionalValue(relativeIndex == 1, 1, -1)*GUILinearScale(32)
			else
				xPos = -cardSize/2
			end
			card.background:SetPosition(Vector((kTitleSize.x-GUILinearScale(32))/2 + xPos, yPos, 0))
		end
	end
	
	return yPos + tallestElem
end

local function repositionStats(self)
		local yPos = GUILinearScale(16)
		
		if CHUDGetOption("endstatsorder") == 1 then
			self.yourStatsTextShadow:SetPosition(Vector((kTitleSize.x-GUILinearScale(32))/2, yPos, 0))
			yPos = yPos + repositionStatsCards(self)
		end
		
		if self.team1UI.background:GetIsVisible() then
			self.teamStatsTextShadow:SetPosition(Vector((kTitleSize.x-GUILinearScale(32))/2, yPos, 0))
			yPos = yPos + GUILinearScale(32)
			self.team1UI.background:SetPosition(Vector(GUILinearScale(16), yPos, 0))
			yPos = yPos + self.team1UI.tableBackground:GetSize().y + self.team1UI.background:GetSize().y
			self.team2UI.background:SetPosition(Vector(GUILinearScale(16), yPos, 0))
			yPos = yPos + self.team2UI.tableBackground:GetSize().y + self.team2UI.background:GetSize().y + GUILinearScale(32)
		end
		
		if CHUDGetOption("endstatsorder") == 0 then
			self.yourStatsTextShadow:SetPosition(Vector((kTitleSize.x-GUILinearScale(32))/2, yPos, 0))
			yPos = repositionStatsCards(self)
		end
		
		self.contentSize = math.max(self.contentSize, yPos)
end

local function HandleSlidebarClicked(self)

	local mouseX, mouseY = Client.GetCursorPosScreen()
	if self.sliderBarBg:GetIsVisible() and self.isDragging then
		local topPos = GUILinearScale(128)
		local bottomPos = screenHeight - kTopOffset
		mouseY = Clamp(mouseY, topPos, bottomPos)
		self.slidePercentage = (mouseY - topPos) / (bottomPos - topPos) * 100
	end
	
end

local function CheckRowHighlight(self, row, mouseX, mouseY)
	if GUIItemContainsPoint(row.background, mouseX, mouseY) and row.steamId then
		if not row.originalColor then
			row.originalColor = row.background:GetColor()
		end
		local color = row.originalColor * 0.75
		row.background:SetColor(color)
		self.lastRow = row
	elseif row.originalColor then
		row.background:SetColor(row.originalColor)
		row.originalColor = nil
	end
end

local function SortByColumn(self, isMarine, sortField, inv)
	local playerRows = isMarine and self.team1UI.playerRows or self.team2UI.playerRows
	local sortTable = {}
	for _, row in ipairs(playerRows) do
		if row.originalOrder and row.message then
			table.insert(sortTable, row)
		end
	end
	
	table.sort(sortTable, function(a, b)
		if a.message[sortField] == b.message[sortField] then
			return a.originalOrder < b.originalOrder
		elseif sortField == "lowerCaseName" and not inv or sortField ~= "lowerCaseName" and inv then
			return a.message[sortField] < b.message[sortField]
		else
			return a.message[sortField] > b.message[sortField]
		end
	end)
	
	for index, row in ipairs(sortTable) do
		local bgColor = isMarine and kMarinePlayerStatsOddColor or kAlienPlayerStatsOddColor
		if index % 2 == 0 then
			bgColor = isMarine and kMarinePlayerStatsEvenColor or kAlienPlayerStatsEvenColor
		end
		
		row.background:SetPosition(Vector(kRowBorderSize, kRowBorderSize + index*kRowSize.y, 0))
		-- Our own row is colored correctly already
		if row.message.steamId ~= Client.GetSteamId() then
			row.background:SetColor(bgColor)
		end
	end
end

function CHUDGUI_EndStats:Update(deltaTime)

	local timeSinceRoundEnd = lastStatsMsg > 0 and Shared.GetTime() - lastGameEnd or 0
	local gameInfo = GetGameInfoEntity()

	if self:GetIsVisible() then
		local mouseX, mouseY = Client.GetCursorPosScreen()
		
		-- When going back to the RR sometimes we'll lose the cursor
		if not MouseTracker_GetIsVisible() then
			MouseTracker_SetIsVisible(true)
		end
		
		self.yourStatsTextShadow:SetIsVisible(#self.statsCards > 0)
		
		-- Hide the stats when the game starts if we're on a team
		if PlayerUI_GetHasGameStarted() and (Client.GetLocalPlayer():GetTeamNumber() ~= kTeamReadyRoom and Client.GetLocalPlayer():GetTeamNumber() ~= kSpectatorIndex) then
			self:SetIsVisible(false)
			self.actionIconGUI:Hide()
		end
		
		-- Handle row highlighting
		if not self.hoverMenu.background:GetIsVisible() then
			self.lastRow = nil
			highlightedField = nil
			for index, row in ipairs(self.team1UI.playerRows) do
				if index == 1 then
					local highlightColor = kMarineHeaderRowTextHighlightColor
					local textColor = kMarineHeaderRowTextColor
					for fieldName, item in pairs(row) do
						if item.GetText and item:GetText() ~= "" then
							if GUIItemContainsPoint(item, mouseX, mouseY) then
								highlightedField = fieldName
								highlightedFieldMarine = true
								item:SetColor(highlightColor)
							else
								item:SetColor(textColor)
							end
						end
					end
				else
					CheckRowHighlight(self, row, mouseX, mouseY)
				end
			end
			for index, row in ipairs(self.team2UI.playerRows) do
				if index == 1 then
					local highlightColor = kAlienHeaderRowTextHighlightColor
					local textColor = kAlienHeaderRowTextColor
					for fieldName, item in pairs(row) do
						if item.GetText and item:GetText() ~= "" then
							if GUIItemContainsPoint(item, mouseX, mouseY) then
								highlightedField = fieldName
								highlightedFieldMarine = false
								item:SetColor(highlightColor)
							else
								item:SetColor(textColor)
							end
						end
					end
				else
					CheckRowHighlight(self, row, mouseX, mouseY)
				end
			end
			
			-- Change it to the field name on the message table for proper sorting
			if highlightedField == "acc" then
				highlightedField = "realAccuracy"
			elseif highlightedField == "timeBuilding" then
				highlightedField = "minutesBuilding"
			elseif highlightedField == "playerName" then
				highlightedField = "lowerCaseName"
			end
		end
		
		-- Handle sliderbar position and display
		if self.sliderBarBg:GetIsVisible() and self.mousePressed and self.isDragging then
			HandleSlidebarClicked(self)
		end
		
		-- Check if it's visible again since we hide the menu if the game starts
		local showSlidebar = self.contentSize > kContentMaxYSize and self:GetIsVisible()
		local slideOffset = -(self.slidePercentage * self.contentSize/100)+(self.slidePercentage * kContentMaxYSize/100)
		local sliderPos = (self.slidePercentage * kContentMaxYSize/100)
		self.background:SetPosition(Vector(-(kTitleSize.x-GUILinearScale(32))/2, GUILinearScale(128)+slideOffset, 0))
		if sliderPos < self.slider:GetSize().y/2 then
			sliderPos = 0
		end
		if sliderPos > kContentMaxYSize - self.slider:GetSize().y then
			sliderPos = kContentMaxYSize - self.slider:GetSize().y
		end
		
		if math.abs(self.slider:GetPosition().y - sliderPos) > 2.5 then
			StartSoundEffect(kSlideSound)
		end
		
		self.slider:SetPosition(Vector(-GUILinearScale(8), sliderPos, 0))
		self.sliderBarBg:SetIsVisible(showSlidebar)
		
		-- Close button
		local kCloseButtonColor = Color(1, 0, 0, 0.5)
		local kCloseButtonHighlightColor = Color(1, 0, 0, 0.75)
		
		if GUIItemContainsPoint(self.closeButton, mouseX, mouseY) then
			if self.closeButton:GetColor() ~= kCloseButtonHighlightColor then
				self.closeButton:SetColor(kCloseButtonHighlightColor)
				StartSoundEffect(kMouseHoverSound)
			end
		elseif self.closeButton:GetColor() ~= kCloseButtonColor then
			self.closeButton:SetColor(kCloseButtonColor)
			StartSoundEffect(kMouseHoverSound)
		end
	else
		self.lastRow = nil
	end

	-- Automatic data display on round end
	if timeSinceRoundEnd > 2.5 and Shared.GetTime() > lastStatsMsg + kMaxAppendTime then
		if CHUDGetOption("deathstats") > 0 and timeSinceRoundEnd < 7.5 and not self.displayed then
			self.actionIconGUI:ShowIcon(BindingsUI_GetInputValue("RequestMenu"), nil, "Last round stats", nil)
		else
			self.actionIconGUI:Hide()
		end
		
		if timeSinceRoundEnd > 7.5 and lastGameEnd > 0 and not self.displayed then
			self:SetIsVisible(gameInfo and gameInfo.showEndStatsAuto and CHUDGetOption("deathstats") > 1)
			self.displayed = true
		end
	end
	
	-- Enough time has passed, so let's save the stats we received
	if Shared.GetTime() > lastStatsMsg + kMaxAppendTime and (#finalStatsTable > 0 or #cardsTable > 0 or #miscDataTable > 0) and gameInfo then
		table.sort(finalStatsTable, function(a, b)
			a.teamNumber = a.isMarine and 1 or 2
			b.teamNumber = b.isMarine and 1 or 2
			a.realAccuracy = a.accuracyOnos == -1 and a.accuracy or a.accuracyOnos
			b.realAccuracy = b.accuracyOnos == -1 and b.accuracy or b.accuracyOnos
			a.lowerCaseName = string.UTF8Lower(a.playerName)
			b.lowerCaseName = string.UTF8Lower(b.playerName)
			if a.teamNumber == b.teamNumber then
				if a.kills == b.kills then
					if a.assists == b.assists then
						if a.deaths == b.deaths then
							if a.realAccuracy == b.realAccuracy then
								if a.pdmg == b.pdmg then
									if a.sdmg == b.sdmg then
										if a.minutesBuilding == b.minutesBuilding then
											return a.lowerCaseName < b.lowerCaseName
										else
											return a.minutesBuilding > b.minutesBuilding
										end
									else
										return a.sdmg > b.sdmg
									end
								else
									return a.pdmg > b.pdmg
								end
							else
								return a.accuracy > b.accuracy
							end
						else
							return a.deaths < b.deaths
						end
					else
						return a.assists > b.assists
					end
				else
					return a.kills > b.kills
				end
			else
				return a.teamNumber < b.teamNumber
			end
		end)
		
		table.sort(cardsTable, function(a, b)
			if a.teamNumber == b.teamNumber and a.message.kills and b.message.kills then
				a.message.realAccuracy = a.message.accuracyOnos == -1 and a.message.accuracy or a.message.accuracyOnos
				b.message.realAccuracy = b.message.accuracyOnos == -1 and b.message.accuracy or b.message.accuracyOnos
				if a.message.kills == b.message.kills then
					return a.message.realAccuracy > b.message.realAccuracy
				else
					return a.message.kills > b.message.kills
				end
			elseif a.teamNumber == b.teamNumber and a.order and b.order then
				return a.order < b.order
			else
				return a.teamNumber > b.teamNumber
			end
		end)
		
		local totalKills1 = 0
		local totalKills2 = 0
		local totalAssists1 = 0
		local totalAssists2 = 0
		local totalDeaths1 = 0
		local totalDeaths2 = 0
		local totalPdmg1 = 0
		local totalPdmg2 = 0
		local totalSdmg1 = 0
		local totalSdmg2 = 0
		local totalTimeBuilding1 = 0
		local totalTimeBuilding2 = 0
		local avgAccuracy1 = 0
		local avgAccuracy1Onos = 0
		local avgAccuracy2 = 0
		
		self:Uninitialize()
		self:Initialize()
		
		for _, message in ipairs(finalStatsTable) do
			local minutes = math.floor(message.minutesBuilding)
			local seconds = (message.minutesBuilding % 1)*60
			
			local isMarine = message.isMarine
			
			local teamObj
			
			if isMarine then
				teamObj = self.team1UI
				totalKills1 = totalKills1 + message.kills
				totalAssists1 = totalAssists1 + message.assists
				totalDeaths1 = totalDeaths1 + message.deaths
				totalPdmg1 = totalPdmg1 + message.pdmg
				totalSdmg1 = totalSdmg1 + message.sdmg
				totalTimeBuilding1 = totalTimeBuilding1 + message.minutesBuilding
				avgAccuracy1 = avgAccTable.marineAcc
				avgAccuracy1Onos = avgAccTable.marineOnosAcc
			else
				teamObj = self.team2UI
				totalKills2 = totalKills2 + message.kills
				totalAssists2 = totalAssists2 + message.assists
				totalDeaths2 = totalDeaths2 + message.deaths
				totalPdmg2 = totalPdmg2 + message.pdmg
				totalSdmg2 = totalSdmg2 + message.sdmg
				totalTimeBuilding2 = totalTimeBuilding2 + message.minutesBuilding
				avgAccuracy2 = avgAccTable.alienAcc
			end
			
			local playerCount = #teamObj.playerRows
			local bgColor = isMarine and kMarinePlayerStatsOddColor or kAlienPlayerStatsOddColor
			local playerTextColor = kPlayerStatsTextColor
			if playerCount % 2 == 0 then
				bgColor = isMarine and kMarinePlayerStatsEvenColor or kAlienPlayerStatsEvenColor
			end
			
			-- Color our own row in a different color
			if message.steamId == Client.GetSteamId() then
				bgColor = kCurrentPlayerStatsColor
				playerTextColor = kCurrentPlayerStatsTextColor
			end
			
			table.insert(teamObj.playerRows, CreateScoreboardRow(teamObj.tableBackground, bgColor, playerTextColor, message.playerName, printNum(message.kills), printNum(message.assists), printNum(message.deaths), message.accuracyOnos == -1 and string.format("%s%%", printNum(message.accuracy)) or string.format("%s%% (%s%%)", printNum(message.accuracy), printNum(message.accuracyOnos)), printNum(message.pdmg), printNum(message.sdmg), string.format("%d:%02d", minutes, seconds), message.steamId))
			-- Store some of the original info so we can sort afterwards
			teamObj.playerRows[#teamObj.playerRows].originalOrder = playerCount
			teamObj.playerRows[#teamObj.playerRows].message = message
		end
		
		local numPlayers1 = #self.team1UI.playerRows-1
		local numPlayers2 = #self.team2UI.playerRows-1
		self:SetPlayerCount(self.team1UI, numPlayers1)
		self:SetPlayerCount(self.team2UI, numPlayers2)
		miscDataTable.team1PlayerCount = numPlayers1
		miscDataTable.team2PlayerCount = numPlayers2
		self:SetTeamName(self.team1UI, miscDataTable.team1Name or "Frontiersmen")
		self:SetTeamName(self.team2UI, miscDataTable.team2Name or "Kharaa")
		local team1Result, team2Result = "DRAW", "DRAW"
		if miscDataTable.winningTeam > 0 then
			team1Result = miscDataTable.winningTeam == kMarineTeamType and "WINNER" or "LOSER"
			team2Result = miscDataTable.winningTeam == kAlienTeamType and "WINNER" or "LOSER"
		end
		self:SetGameResult(self.team1UI, team1Result)
		self:SetGameResult(self.team2UI, team2Result)
		
		local minutes1 = math.floor(totalTimeBuilding1)
		local seconds1 = (totalTimeBuilding1 % 1)*60
		totalTimeBuilding1 = totalTimeBuilding1/numPlayers1
		local minutes1Avg = math.floor(totalTimeBuilding1)
		local seconds1Avg = (totalTimeBuilding1 % 1)*60
		local minutes2 = math.floor(totalTimeBuilding2)
		local seconds2 = (totalTimeBuilding2 % 1)*60
		totalTimeBuilding2 = totalTimeBuilding2/numPlayers2
		local minutes2Avg = math.floor(totalTimeBuilding2)
		local seconds2Avg = (totalTimeBuilding2 % 1)*60
		
		-- When there's only one player in a team, the total and the average will be the same
		-- Don't even bother displaying this, it looks odd
		if numPlayers1 > 1 then
			table.insert(self.team1UI.playerRows, CreateScoreboardRow(self.team1UI.tableBackground, kHeaderRowColor, kMarineHeaderRowTextColor, "Total", printNum(totalKills1), printNum(totalAssists1), printNum(totalDeaths1), " ", printNum(totalPdmg1), printNum(totalSdmg1), string.format("%d:%02d", minutes1, seconds1)))
			table.insert(self.team1UI.playerRows, CreateScoreboardRow(self.team1UI.tableBackground, kAverageRowColor, kAverageRowTextColor, "Average", printNum(totalKills1/numPlayers1), printNum(totalAssists1/numPlayers1), printNum(totalDeaths1/numPlayers1), avgAccuracy1Onos == -1 and string.format("%s%%", printNum(avgAccuracy1)) or string.format("%s%% (%s%%)", printNum(avgAccuracy1), printNum(avgAccuracy1Onos)), printNum(totalPdmg1/numPlayers1), printNum(totalSdmg1/numPlayers1), string.format("%d:%02d", minutes1Avg, seconds1Avg)))
		end
		if numPlayers2 > 1 then
			table.insert(self.team2UI.playerRows, CreateScoreboardRow(self.team2UI.tableBackground, kHeaderRowColor, kAlienHeaderRowTextColor, "Total", printNum(totalKills2), printNum(totalAssists2), printNum(totalDeaths2), " ", printNum(totalPdmg2), printNum(totalSdmg2), string.format("%d:%02d", minutes2, seconds2)))
			table.insert(self.team2UI.playerRows, CreateScoreboardRow(self.team2UI.tableBackground, kAverageRowColor, kAverageRowTextColor, "Average", printNum(totalKills2/numPlayers2), printNum(totalAssists2/numPlayers2), printNum(totalDeaths2/numPlayers2), string.format("%s%%", printNum(avgAccuracy2)), printNum(totalPdmg2/numPlayers2), printNum(totalSdmg2/numPlayers2), string.format("%d:%02d", minutes2Avg, seconds2Avg)))
		end
		
		local teamStatsVisible = gameInfo.showEndStatsTeamBreakdown

		self.team1UI.background:SetIsVisible(teamStatsVisible)
		self.team2UI.background:SetIsVisible(teamStatsVisible)
		self.teamStatsTextShadow:SetIsVisible(teamStatsVisible)
		
		self.roundDate:SetText("Round date: " .. miscDataTable.roundDateString)
		self.gameLength:SetText("Game length: " .. miscDataTable.gameLength)
		self.serverName:SetText("Server name: " .. miscDataTable.serverName)
		self.mapName:SetText("Map: " .. miscDataTable.mapName)
		
		for _, card in ipairs(cardsTable) do
			local bgColor
			if card.teamNumber == 1 then
				bgColor = kMarineStatsColor
			elseif card.teamNumber == 2 then
				bgColor = kAlienStatsColor
			else
				bgColor = kCommanderStatsColor
			end
			local statCard = self:CreateGraphicHeader(card.text, bgColor, card.logoTexture, card.logoCoords, card.logoSizeX, card.logoSizeY)
			statCard.rows = {}
			
			for index, row in ipairs(card.rows) do
				if card.teamNumber == 1 then
					bgColor = ConditionalValue(index % 2 == 0, kMarinePlayerStatsEvenColor, kMarinePlayerStatsOddColor)
				elseif card.teamNumber == 2 then
					bgColor = ConditionalValue(index % 2 == 0, kAlienPlayerStatsEvenColor, kAlienPlayerStatsOddColor)
				else
					bgColor = ConditionalValue(index % 2 == 0, kCommanderStatsEvenColor, kCommanderStatsOddColor)
				end
				
				table.insert(statCard.rows, CreateHeaderRow(statCard.tableBackground, bgColor, Color(1,1,1,1), row.title, row.value))
			end
			table.insert(self.statsCards, statCard)
		end
		
		repositionStats(self)
		
		if not self.saved then
			local savedStats = {}
			savedStats.finalStatsTable = finalStatsTable
			savedStats.avgAccTable = avgAccTable
			savedStats.miscDataTable = miscDataTable
			savedStats.cardsTable = cardsTable
			
			local savedFile = io.open(lastRoundFile, "w+")
			if savedFile then
				savedFile:write(json.encode(savedStats, { indent = true }))
				io.close(savedFile)
			end
			self.saved = true
		end
		
		finalStatsTable = {}
		avgAccTable = {}
		miscDataTable = {}
		cardsTable = {}
	end
end

Script.Load("lua/GUIGameEnd.lua")
local originalGameEnded
originalGameEnded = Class_ReplaceMethod( "GUIGameEnd", "SetGameEnded",
	function(self, playerWon, playerDraw, playerTeamType)
		originalGameEnded(self, playerWon, playerDraw, playerTeamType)
		
		local playerIsMarine = playerTeamType == kMarineTeamType
		miscDataTable.team1Name = InsightUI_GetTeam1Name()
		miscDataTable.team2Name = InsightUI_GetTeam2Name()
		miscDataTable.winningTeam = 0
		if playerWon then
			miscDataTable.winningTeam = playerIsMarine and kMarineTeamType or kAlienTeamType
		elseif not playerDraw then
			miscDataTable.winningTeam = playerIsMarine and kAlienTeamType or kMarineTeamType
		end
		
		miscDataTable.roundDateString = CHUDFormatDateTimeString(Shared.GetSystemTime())
		miscDataTable.gameLength = CHUDGetGameTime()
		miscDataTable.serverName = Client.GetServerIsHidden() and "Hidden" or Client.GetConnectedServerName()
		miscDataTable.mapName = Shared.GetMapName()
		
		lastGameEnd = Shared.GetTime()
	end)

local function CHUDSetPlayerStats(message)
	
	if message and message.playerName then
		table.insert(finalStatsTable, message)
	elseif message and message.marineAcc then
		avgAccTable = message
	end
	
	lastStatsMsg = Shared.GetTime()
end

local kFriendlyWeaponNames = { }
kFriendlyWeaponNames[kTechId.LerkBite] = "Lerk Bite"
kFriendlyWeaponNames[kTechId.Swipe] = "Swipe"
kFriendlyWeaponNames[kTechId.Spit] = "Spit"
kFriendlyWeaponNames[kTechId.Spray] = "Spray"
kFriendlyWeaponNames[kTechId.GrenadeLauncher] = "Grenade Launcher"
kFriendlyWeaponNames[kTechId.LayMines] = "Mines"
kFriendlyWeaponNames[kTechId.PulseGrenade] = "Pulse grenade"
kFriendlyWeaponNames[kTechId.ClusterGrenade] = "Cluster grenade"
kFriendlyWeaponNames[kTechId.GasGrenade] = "Gas grenade"
kFriendlyWeaponNames[kTechId.WhipBomb] = "Whip bilebomb"
if rawget( kTechId, "HeavyMachineGun" ) then
	kFriendlyWeaponNames[kTechId.HeavyMachineGun] = "Heavy Machine Gun"
end

local function CHUDSetWeaponStats(message)
	
	local weaponName
	
	local wTechId = message.wTechId

	if wTechId > 1 and wTechId ~= kTechId.None then
		if kFriendlyWeaponNames[wTechId] then
			weaponName = kFriendlyWeaponNames[wTechId]
		else
			local techdataName = LookupTechData(wTechId, kTechDataMapName) or Locale.ResolveString(LookupTechData(wTechId, kTechDataDisplayName))
			weaponName = techdataName:gsub("^%l", string.upper)
		end
	else
		weaponName = "Others"
	end
	
	local cardEntry = {}
	cardEntry.text = weaponName
	cardEntry.teamNumber = message.teamNumber
	cardEntry.logoTexture = kInventoryIconsTexture
	cardEntry.logoCoords = { GetTexCoordsForTechId(wTechId) }
	cardEntry.logoSizeX = 64
	cardEntry.logoSizeY = 32
	cardEntry.message = message
	
	cardEntry.rows = {}
	
	local row = {}
	row.title = "Kills"
	row.value = printNum(message.kills)
	table.insert(cardEntry.rows, row)
	
	if message.accuracy > 0 then
		row = {}
		row.title = "Accuracy"
		row.value = printNum(message.accuracy) .. "%"
		table.insert(cardEntry.rows, row)
		
		if message.accuracyOnos > -1 then
			row = {}
			row.title = "Accuracy (No Onos)"
			row.value = printNum(message.accuracyOnos) .. "%"
			table.insert(cardEntry.rows, row)
		end
	end
	
	if message.pdmg > 0 then
		row = {}
		row.title = "Player damage"
		row.value = printNum(message.pdmg)
		table.insert(cardEntry.rows, row)
	end
	
	if message.sdmg > 0 then
		row = {}
		row.title = "Structure damage"
		row.value = printNum(message.sdmg)
		table.insert(cardEntry.rows, row)
	end

	table.insert(cardsTable, cardEntry)
	
	lastStatsMsg = Shared.GetTime()
end

local function CHUDSetCommStats(message)
	
	if message.medpackAccuracy then
		
		if message.medpackResUsed + message.medpackResExpired > 0 then
			local cardEntry = {}
			cardEntry.text = "Medpacks"
			cardEntry.teamNumber = 3
			cardEntry.logoTexture = "ui/buildmenu.dds"
			cardEntry.logoCoords = GetTextureCoordinatesForIcon(kTechId.MedPack)
			cardEntry.logoSizeX = 32
			cardEntry.logoSizeY = 32
			cardEntry.message = message
			cardEntry.order = 1
			
			cardEntry.rows = {}
			
			local row = {}
			row.title = "Accuracy"
			row.value = printNum(message.medpackAccuracy) .. "%"
			table.insert(cardEntry.rows, row)
			
			local row = {}
			row.title = "Amount healed"
			row.value = printNum(message.medpackRefill)
			table.insert(cardEntry.rows, row)
			
			local row = {}
			row.title = "Res spent on used medpacks"
			row.value = printNum(message.medpackResUsed)
			table.insert(cardEntry.rows, row)
			
			local row = {}
			row.title = "Res spent on expired medpacks"
			row.value = printNum(message.medpackResExpired)
			table.insert(cardEntry.rows, row)
			
			local row = {}
			row.title = "Efficiency (used vs expired)"
			row.value = printNum(message.medpackEfficiency) .. "%"
			table.insert(cardEntry.rows, row)
			
			table.insert(cardsTable, cardEntry)
		end
		
		if message.ammopackResUsed + message.ammopackResExpired > 0 then
			local cardEntry = {}
			cardEntry.text = "Ammopacks"
			cardEntry.teamNumber = 3
			cardEntry.logoTexture = "ui/buildmenu.dds"
			cardEntry.logoCoords = GetTextureCoordinatesForIcon(kTechId.AmmoPack)
			cardEntry.logoSizeX = 32
			cardEntry.logoSizeY = 32
			cardEntry.message = message
			cardEntry.order = 2
			
			cardEntry.rows = {}
			
			local row = {}
			row.title = "Ammo refilled"
			row.value = printNum(message.ammopackRefill)
			table.insert(cardEntry.rows, row)
			
			local row = {}
			row.title = "Res spent on used ammopacks"
			row.value = printNum(message.ammopackResUsed)
			table.insert(cardEntry.rows, row)
			
			local row = {}
			row.title = "Res spent on expired ammopacks"
			row.value = printNum(message.ammopackResExpired)
			table.insert(cardEntry.rows, row)
			
			local row = {}
			row.title = "Efficiency (used vs expired)"
			row.value = printNum(message.ammopackEfficiency) .. "%"
			table.insert(cardEntry.rows, row)
			
			table.insert(cardsTable, cardEntry)
		end
		
		if message.catpackResUsed + message.catpackResExpired > 0 then
			local cardEntry = {}
			cardEntry.text = "Catpacks"
			cardEntry.teamNumber = 3
			cardEntry.logoTexture = "ui/buildmenu.dds"
			cardEntry.logoCoords = GetTextureCoordinatesForIcon(kTechId.CatPack)
			cardEntry.logoSizeX = 32
			cardEntry.logoSizeY = 32
			cardEntry.message = message
			cardEntry.order = 3
			
			cardEntry.rows = {}
			
			local row = {}
			row.title = "Res spent on used catpacks"
			row.value = printNum(message.catpackResUsed)
			table.insert(cardEntry.rows, row)
			
			local row = {}
			row.title = "Res spent on expired catpacks"
			row.value = printNum(message.catpackResExpired)
			table.insert(cardEntry.rows, row)
			
			local row = {}
			row.title = "Efficiency (used vs expired)"
			row.value = printNum(message.catpackEfficiency) .. "%"
			table.insert(cardEntry.rows, row)
			
			table.insert(cardsTable, cardEntry)
		end
		
	end
	
	lastStatsMsg = Shared.GetTime()
end

local lastDisplayStatus = false
local lastDown = 0
local kKeyTapTiming = 0.2
function CHUDGUI_EndStats:SendKeyEvent(key, down)

	local _, pgp = Shine and Shine:IsExtensionEnabled( "pregameplus" )
	local pgpEnabled = pgp and pgp.dt and pgp.dt.Enabled
	if GetIsBinding(key, "RequestMenu") and CHUDGetOption("deathstats") > 0 and (not PlayerUI_GetHasGameStarted() or pgpEnabled or Client.GetLocalPlayer():GetTeamNumber() == kTeamReadyRoom or Client.GetLocalPlayer():GetTeamNumber() == kSpectatorIndex) and not ChatUI_EnteringChatMessage() and not MainMenu_GetIsOpened() and self.prevRequestKey ~= down then
		
		self.prevRequestKey = down
		
		if down then
			lastDown = Shared.GetTime()
			
		-- Only show stats when the player hasn't selected something from the request menu first
		-- Disable for fullscreen windowed until the bug where the cursor is not centered is fixed
		elseif not down then
			local isVisible = self:GetIsVisible()
			if isVisible then
				self:SetIsVisible(false)
			elseif lastDown+kKeyTapTiming > Shared.GetTime() then
				self:SetIsVisible(true)
			end
		end
	end
	
	if self:GetIsVisible() then
		if key == InputKey.Escape and down then
			self:SetIsVisible(false)
			return true
		elseif key == InputKey.MouseButton0 and down then
			local mouseX, mouseY = Client.GetCursorPosScreen()
			
			if GUIItemContainsPoint(self.closeButton, mouseX, mouseY) then
				StartSoundEffect(kButtonClickSound)
				self:SetIsVisible(false)
				return true
			end
			
			if self.lastRow and not self.hoverMenu.background:GetIsVisible() then
				local function openSteamProf()
					Client.ShowWebpage(string.format("%s[U:1:%s]", kSteamProfileURL, self.lastRow.steamId))
				end
				local function openHiveProf()
					Client.ShowWebpage(string.format("%s%s", kHiveProfileURL, self.lastRow.steamId))
				end
				local function openNS2StatsProf()
					Client.ShowWebpage(string.format("%s%s", kNS2StatsProfileURL, self.lastRow.steamId))
				end
				
				self.hoverMenu:ResetButtons()
				
				local textColor = Color(1, 1, 1, 1)
				local nameBgColor = Color(0, 0, 0, 0)
				local teamColorHighlight = self.lastRow.background:GetParent():GetColor() * 0.25
				teamColorHighlight.a = 1
				local teamColorBg = self.lastRow.background:GetParent():GetColor() * 0.5
				teamColorBg.a = 1
				local bgColor = self.lastRow.background:GetParent():GetColor() * 0.75
				bgColor.a = 0.9
				
				self.hoverMenu:SetBackgroundColor(bgColor)
				self.hoverMenu:AddButton(self.lastRow.playerName:GetText(), nameBgColor, nameBgColor, textColor)
				self.hoverMenu:AddButton(Locale.ResolveString("SB_MENU_STEAM_PROFILE"), teamColorBg, teamColorHighlight, textColor, openSteamProf)
				self.hoverMenu:AddButton(Locale.ResolveString("SB_MENU_HIVE_PROFILE"), teamColorBg, teamColorHighlight, textColor, openHiveProf)
				self.hoverMenu:AddButton("NS2Stats profile", teamColorBg, teamColorHighlight, textColor, openNS2StatsProf, found)
				
				StartSoundEffect(kButtonClickSound)
				self.hoverMenu:Show()
				
				return true
			elseif self.lastRow and self.hoverMenu.background:GetIsVisible() and not GUIItemContainsPoint(self.hoverMenu.background, mouseX, mouseY) then
				self.hoverMenu:Hide()
			end
			
			if highlightedField ~= nil then
				if highlightedFieldMarine then
					if lastSortedT1 == highlightedField then
						lastSortedT1WasInv = not lastSortedT1WasInv
					else
						lastSortedT1WasInv = false
						lastSortedT1 = highlightedField
					end
				else
					if lastSortedT2 == highlightedField then
						lastSortedT2WasInv = not lastSortedT2WasInv
					else
						lastSortedT2WasInv = false
						lastSortedT2 = highlightedField
					end
				end
				
				StartSoundEffect(kButtonClickSound)
				SortByColumn(self, highlightedFieldMarine, highlightedField, highlightedFieldMarine and lastSortedT1WasInv or lastSortedT2WasInv)
				return true
			end
		end
	end
	
	if GetIsBinding(key, "Scoreboard") and self.prevScoreKey ~= down then
		self.prevScoreKey = down
		if down then
			lastDisplayStatus = self:GetIsVisible()
			if lastDisplayStatus then
				self:SetIsVisible(false)
			end
		elseif lastDisplayStatus and not self:GetIsVisible() then
			self:SetIsVisible(lastDisplayStatus)
		end
	end
	
	if self.sliderBarBg:GetIsVisible() and not self.hoverMenu.background:GetIsVisible() then
		if key == InputKey.MouseButton0 and self.mousePressed ~= down then
			self.mousePressed = down
			if down then
				local mouseX, mouseY = Client.GetCursorPosScreen()
				self.isDragging = GUIItemContainsPoint(self.sliderBarBg, mouseX, mouseY) or GUIItemContainsPoint(self.slider, mouseX, mouseY)
				return true
			end
		elseif key == InputKey.MouseWheelDown then
			self.slidePercentage = math.min(self.slidePercentage + 5, 100)
			return true
		elseif key == InputKey.MouseWheelUp then
			self.slidePercentage = math.max(self.slidePercentage - 5, 0)
			return true
		elseif key == InputKey.PageDown and down then
			self.slidePercentage = math.min(self.slidePercentage + 10, 100)
			return true
		elseif key == InputKey.PageUp and down then
			self.slidePercentage = math.max(self.slidePercentage - 10, 0)
			return true
		elseif key == InputKey.Home then
			self.slidePercentage = 0
			return true
		elseif key == InputKey.End then
			self.slidePercentage = 100
			return true
		end
	end
	
	return false
end

function CHUDGUI_EndStats:OnResolutionChanged(oldX, oldY, newX, newY)
	screenWidth = newX
	screenHeight = newY
	aspectRatio = screenWidth/screenHeight
	widthPercentage = ConditionalValue(aspectRatio < 1.5, 0.95, 0.75)
	kTitleSize = Vector(screenWidth*widthPercentage, GUILinearScale(74), 0)
	kCardSize = Vector(kTitleSize.x/3.5, GUILinearScale(74), 0)
	scaledVector = GUILinearScale(Vector(1,1,1))
	kTopOffset = GUILinearScale(32)
	kLogoSize = GUILinearScale(Vector(52, 52, 0))
	kLogoOffset = GUILinearScale(4)
	kTeamNameOffset = GUILinearScale(10)
	kTextShadowOffset = GUILinearScale(2)
	kPlayerCountOffset = -GUILinearScale(20)
	kContentMaxYSize = screenHeight - GUILinearScale(128) - kTopOffset
	kRowSize = Vector(kTitleSize.x-(kLogoSize.x+kTeamNameOffset)*2, GUILinearScale(24), 0)
	kCardRowSize = Vector(kCardSize.x*0.85, GUILinearScale(24), 0)
	kTableContainerOffset = GUILinearScale(5)
	kRowBorderSize = GUILinearScale(2)
	kRowPlayerNameOffset = GUILinearScale(10)
	kCloseButtonSize = Vector(GUILinearScale(24), GUILinearScale(24), 0)
	
	-- Mark the last round as not loaded so it loads it back when we destroy the current UI
	loadedLastRound = false
	
	self:Uninitialize()
	self:Initialize()
end

local oldGetCanDisplayReqMenu = PlayerUI_GetCanDisplayRequestMenu
function PlayerUI_GetCanDisplayRequestMenu()
	return oldGetCanDisplayReqMenu() and not CHUDEndStatsVisible and lastDown+kKeyTapTiming < Shared.GetTime()
end

-- Add the missing icons so they display correctly
-- We have to call the function first so it creates the array
GetTexCoordsForTechId(kTechId.None)

gTechIdPosition[kTechId.Sentry] = kDeathMessageIcon.Sentry
gTechIdPosition[kTechId.ARC] = kDeathMessageIcon.ARC
gTechIdPosition[kTechId.Whip] = kDeathMessageIcon.Whip
gTechIdPosition[kTechId.Babbler] = kDeathMessageIcon.Babbler
gTechIdPosition[kTechId.Hydra] = kDeathMessageIcon.HydraSpike

Client.HookNetworkMessage("CHUDPlayerStats", CHUDSetPlayerStats)
Client.HookNetworkMessage("CHUDAvgAccStats", CHUDSetPlayerStats)
Client.HookNetworkMessage("CHUDEndStatsWeapon", CHUDSetWeaponStats)
Client.HookNetworkMessage("CHUDMarineCommStats", CHUDSetCommStats)