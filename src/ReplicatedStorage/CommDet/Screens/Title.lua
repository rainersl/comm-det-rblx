-- Title screen: rain outside the window, the bureau's name on paper, the case folder
local Title = {}

function Title.build(app, root)
	local UI = app.UI
	local C, F = UI.C, UI.F
	local case = app.case
	local alive = true

	-- Window with rain
	local window = UI.frame({
		Name = "Window",
		BackgroundColor3 = Color3.fromRGB(28, 34, 42),
		Position = UDim2.fromOffset(40, 40),
		Size = UDim2.fromOffset(420, 460),
		ClipsDescendants = true,
		Parent = root,
	})
	UI.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(70, 82, 96), Color3.fromRGB(20, 24, 30)), Parent = window })
	local rng = Random.new(3)
	-- factory chimney on the horizon
	UI.frame({ BackgroundColor3 = Color3.fromRGB(12, 14, 18), Position = UDim2.new(0, 300, 1, -300), Size = UDim2.fromOffset(18, 120), Parent = window })
	for i = 1, 5 do
		local puff = UI.frame({ BackgroundColor3 = Color3.fromRGB(90, 96, 104), BackgroundTransparency = 0.55 + i * 0.07,
			Position = UDim2.new(0, 296 + i * 10, 1, -330 - i * 26), Size = UDim2.fromOffset(26 + i * 6, 26 + i * 6), Parent = window })
		UI.corner(UDim.new(0.5, 0)).Parent = puff
	end
	local x = 0
	while x < 420 do
		local w = rng:NextInteger(36, 70)
		local h = rng:NextInteger(90, 200)
		local b = UI.frame({ BackgroundColor3 = Color3.fromRGB(12, 14, 18), Position = UDim2.new(0, x, 1, -h - 60), Size = UDim2.fromOffset(w, h), Parent = window })
		for _ = 1, rng:NextInteger(0, 4) do
			UI.frame({ BackgroundColor3 = C.lamp, BackgroundTransparency = rng:NextNumber(0.2, 0.6),
				Position = UDim2.fromOffset(rng:NextInteger(6, w - 12), rng:NextInteger(10, h - 20)), Size = UDim2.fromOffset(5, 7), Parent = b })
		end
		x += w + rng:NextInteger(0, 6)
	end
	-- the river
	UI.frame({ BackgroundColor3 = Color3.fromRGB(58, 62, 52), Position = UDim2.new(0, 0, 1, -60), Size = UDim2.new(1, 0, 0, 60), Parent = window })
	for i = 1, 6 do
		UI.frame({ BackgroundColor3 = Color3.fromRGB(110, 112, 92), BackgroundTransparency = 0.6,
			Position = UDim2.new(0, rng:NextInteger(0, 380), 1, -54 + i * 8), Size = UDim2.fromOffset(rng:NextInteger(30, 90), 2), Parent = window })
	end
	local drops = {}
	for _ = 1, 46 do
		local d = UI.frame({ BackgroundColor3 = Color3.fromRGB(170, 190, 210), BackgroundTransparency = rng:NextNumber(0.45, 0.8),
			Size = UDim2.fromOffset(1, rng:NextInteger(14, 30)), Rotation = 12,
			Position = UDim2.fromOffset(rng:NextInteger(-40, 440), rng:NextInteger(-40, 460)), Parent = window })
		table.insert(drops, { f = d, speed = rng:NextNumber(380, 620) })
	end
	UI.frame({ BackgroundColor3 = C.wood, Position = UDim2.new(0.5, -5, 0, 0), Size = UDim2.new(0, 10, 1, 0), Parent = window })
	UI.frame({ BackgroundColor3 = C.wood, Position = UDim2.new(0, 0, 0.45, -5), Size = UDim2.new(1, 0, 0, 10), Parent = window })
	UI.stroke(C.wood, 10).Parent = window

	task.spawn(function()
		while alive do
			local dt = task.wait()
			for _, d in drops do
				local p = d.f.Position
				local ny = p.Y.Offset + d.speed * dt
				local nx = p.X.Offset - d.speed * dt * 0.2
				if ny > 480 then
					ny = -30
					nx = rng:NextInteger(-20, 460)
				end
				d.f.Position = UDim2.fromOffset(nx, ny)
			end
		end
	end)

	-- Name of the bureau
	local holder, sheet = UI.paper(root, { pos = UDim2.fromOffset(500, 60), size = UDim2.fromOffset(410, 210), rot = 1.5, color = C.paper })
	UI.pin(holder, UDim2.new(0.5, 0, 0, 8))
	UI.text({
		Text = "COMM-DET\nCOMMUNITY DETECTIVE",
		FontFace = F.type,
		TextSize = 32,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(16, 34),
		Size = UDim2.new(1, -32, 0, 90),
		Parent = sheet,
	})
	UI.frame({ BackgroundColor3 = C.ink, Position = UDim2.fromOffset(60, 128), Size = UDim2.new(1, -120, 0, 2), Parent = sheet })
	UI.text({
		Text = "We follow the evidence —\nwherever the river takes it.",
		FontFace = F.serifItalic,
		TextSize = 16,
		TextColor3 = C.inkSoft,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(16, 140),
		Size = UDim2.new(1, -32, 0, 50),
		Parent = sheet,
	})

	-- Case folder
	local fHolder, folder = UI.paper(root, { pos = UDim2.fromOffset(530, 300), size = UDim2.fromOffset(360, 170), rot = -2, color = C.manila })
	local tab = UI.frame({ BackgroundColor3 = C.manila, Position = UDim2.fromOffset(18, -18), Size = UDim2.fromOffset(120, 22), Parent = fHolder })
	UI.corner(4).Parent = tab
	UI.text({ Text = "CASE No. " .. case.number, FontFace = F.type, TextSize = 13, Position = UDim2.fromOffset(10, 3), Size = UDim2.new(1, -10, 1, 0), Parent = tab })
	UI.text({ Text = UI.upper(case.title), FontFace = F.type, TextSize = 30, Position = UDim2.fromOffset(22, 22), Size = UDim2.new(1, -44, 0, 40), Parent = folder })
	UI.text({ Text = case.question, FontFace = F.hand, TextSize = 19, TextColor3 = C.red, Position = UDim2.fromOffset(22, 64), Size = UDim2.new(1, -44, 0, 30), Rotation = -1, Parent = folder })
	UI.stamp(folder, "Urgent", { pos = UDim2.new(1, -70, 1, -38), rot = 9, size = 16, animate = false })
	UI.button(folder, "Open the case", {
		pos = UDim2.new(0, 22, 1, -60),
		size = UDim2.fromOffset(200, 44),
		onClick = function() app:go("Briefing") end,
	})

	return function() alive = false end
end

return Title
