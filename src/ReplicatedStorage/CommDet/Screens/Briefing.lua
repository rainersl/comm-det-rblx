-- instructor
local Briefing = {}

function Briefing.build(app, root)
	local UI = app.UI
	local C, F = UI.C, UI.F
	local case = app.case
	local chief = case.characters.chief

	local pol = UI.polaroid(root, {
		pos = UDim2.fromOffset(60, 70),
		size = UDim2.fromOffset(200, 244),
		rot = -4,
		look = chief.look,
		caption = chief.full,
		captionSize = 20,
	})
	UI.tape(pol, UDim2.new(0.5, 0, 0, 0), 3, 80)
	UI.text({
		Text = UI.upper(chief.role),
		FontFace = F.type,
		TextSize = 13,
		TextColor3 = C.paperShade,
		Position = UDim2.fromOffset(60, 330),
		Size = UDim2.fromOffset(200, 20),
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = root,
	})

	local holder, sheet = UI.paper(root, {
		pos = UDim2.fromOffset(300, 40),
		size = UDim2.fromOffset(620, 420),
		rot = 0,
		color = C.paper,
	})
	UI.pin(holder, UDim2.new(0.5, 0, 0, 10))
	UI.text({
		Text = "LIETA Nr. " .. case.number .. " — " .. UI.upper(case.title),
		FontFace = F.type,
		TextSize = 18,
		Position = UDim2.fromOffset(30, 28),
		Size = UDim2.new(1, -60, 0, 24),
		Parent = sheet,
	})
	UI.frame({ BackgroundColor3 = C.ink, Position = UDim2.fromOffset(30, 56), Size = UDim2.new(1, -60, 0, 1), Parent = sheet })

	local log = UI.new("ScrollingFrame", {
		Name = "Log",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(30, 70),
		Size = UDim2.new(1, -50, 1, -136),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.inkFaint,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = sheet,
	})
	UI.list(nil, 12).Parent = log
	UI.pad(0, 10, 0, 0).Parent = log
	log:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
		log.CanvasPosition = Vector2.new(0, math.max(0, log.AbsoluteCanvasSize.Y - log.AbsoluteWindowSize.Y))
	end)

	local hint = UI.text({
		Text = "pieskaries, lai turpinātu →",
		FontFace = F.hand,
		TextSize = 16,
		TextColor3 = C.inkFaint,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(0, 30, 1, -46),
		Size = UDim2.new(1, -60, 0, 24),
		Parent = sheet,
	})

	local index = 0
	local current
	local finished = false

	local function showNext()
		if current and not current.done then
			current.skip()
			return
		end
		index += 1
		local line = case.briefing[index]
		if not line then
			if not finished then
				finished = true
				hint.Visible = false
				UI.button(sheet, "Pie dēļa", {
					pos = UDim2.new(1, -30, 1, -24),
					anchor = Vector2.new(1, 1),
					size = UDim2.fromOffset(180, 42),
					z = 5,
					onClick = function()
						app:go("Board")
					end,
				})
			end
			return
		end
		for _, ch in log:GetChildren() do
			if ch:IsA("TextLabel") then
				ch.TextTransparency = 0.45
			end
		end
		local isChief = line.who == "chief"
		local lbl = UI.text({
			Text = isChief and ("— " .. line.text) or line.text,
			FontFace = isChief and F.serif or F.serifItalic,
			TextSize = 18,
			TextColor3 = isChief and C.ink or C.inkSoft,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = index,
			Parent = log,
		})
		current = UI.typewrite(lbl, 55)
	end

	local hit = UI.hit({ Parent = root, ZIndex = 1 })
	hit.Activated:Connect(showNext)
	holder.ZIndex = 2
	sheet.ZIndex = 2
	for _, d in sheet:GetDescendants() do
		if d:IsA("GuiObject") then d.ZIndex = math.max(d.ZIndex, 2) end
	end

	local sheetHit = UI.hit({ Parent = sheet, ZIndex = 3 })
	sheetHit.Activated:Connect(showNext)

	UI.button(root, "Izlaist", {
		style = "paper",
		pos = UDim2.fromOffset(60, 470),
		textSize = 13,
		padY = 6, padX = 12,
		z = 5,
		onClick = function()
			app:go("Board")
		end,
	})

	task.delay(0.4, showNext)
end

return Briefing
