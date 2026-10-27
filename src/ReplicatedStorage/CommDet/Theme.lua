-- theme
local Theme = {}

local rgb = Color3.fromRGB

Theme.C = {
	desk = rgb(20, 15, 12),
	deskGrain = rgb(34, 25, 19),
	cork = rgb(158, 120, 80),
	corkDark = rgb(126, 93, 60),
	corkSpeck = rgb(98, 70, 44),
	wood = rgb(52, 34, 22),
	woodLight = rgb(78, 52, 34),

	paper = rgb(237, 228, 207),
	paperShade = rgb(214, 202, 176),
	paperWhite = rgb(245, 241, 231),
	card = rgb(243, 238, 224),
	cardLine = rgb(150, 174, 196),
	cardMargin = rgb(190, 82, 78),
	manila = rgb(208, 172, 112),
	manilaDark = rgb(172, 138, 82),
	tape = rgb(232, 222, 190),

	ink = rgb(30, 25, 21),
	inkSoft = rgb(72, 62, 54),
	inkFaint = rgb(124, 112, 99),
	red = rgb(164, 36, 40),
	redBright = rgb(196, 46, 46),
	blue = rgb(36, 60, 112),
	green = rgb(46, 98, 58),

	photo = rgb(60, 67, 76),
	photoLight = rgb(140, 148, 156),
	silhouette = rgb(17, 18, 21),
	screen = rgb(234, 235, 238),
	bubble = rgb(255, 255, 255),
	bubbleOwn = rgb(214, 228, 244),
	blueprint = rgb(34, 62, 100),
	blueprintLine = rgb(196, 216, 238),

	lamp = rgb(255, 210, 140),
	black = rgb(0, 0, 0),
}

local function fam(name)
	return "rbxasset://fonts/families/" .. name .. ".json"
end

Theme.F = {
	type = Font.new(fam("SpecialElite")),                    
	hand = Font.new(fam("Kalam")),                            
	handBold = Font.new(fam("Kalam"), Enum.FontWeight.Bold),
	serif = Font.new(fam("Merriweather")),                   
	serifItalic = Font.new(fam("Merriweather"), Enum.FontWeight.Regular, Enum.FontStyle.Italic),
	serifBold = Font.new(fam("Merriweather"), Enum.FontWeight.Bold),
	sans = Font.new(fam("BuilderSans")),                     
	sansBold = Font.new(fam("BuilderSans"), Enum.FontWeight.Bold),
	mono = Font.new(fam("RobotoMono")),
}

return Theme
