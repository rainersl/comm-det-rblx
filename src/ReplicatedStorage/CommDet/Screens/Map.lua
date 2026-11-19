-- The town map: the hub of the investigation.
-- Places to visit, water sampling points on the river, the clock (3 days x 4 parts) and test kits.
local Config = require(script.Parent.Parent.Config)

local Map = {}

local WATER = Color3.fromRGB(118, 158, 184)
local LAND = Color3.fromRGB(226, 228, 206)

local function slotList(open)
	local names = {}
	for _, i in open do table.insert(names, string.lower(Config.SLOTS[i])) end
	return table.concat(names, ", ")
end

function Map.build(app, root)
	local UI = app.UI
	local C, F = UI.C, UI.F
	local case, state = app.case, app.state

	-- Time is over: straight to the report
	if state.timeUp then
		task.defer(function()
			app:toast("Friday, 9:00. The hearing starts in one hour.", C.red)
			app:go("Report")
		end)
		return
	end

	--------------------------------------------------------------------
	-- Map paper
	--------------------------------------------------------------------
	local _, map = UI.paper(root, { pos = UDim2.fromOffset(12, 12), size = UDim2.fromOffset(690, 516), color = LAND, age = false, shadowY = 7 })
	map.ClipsDescendants = true
	for i = 1, 14 do
		UI.frame({ BackgroundColor3 = C.inkFaint, BackgroundTransparency = 0.88, Position = UDim2.fromOffset(i * 48, 0), Size = UDim2.new(0, 1, 1, 0), Parent = map })
	end
	for i = 1, 10 do
		UI.frame({ BackgroundColor3 = C.inkFaint, BackgroundTransparency = 0.88, Position = UDim2.fromOffset(0, i * 48), Size = UDim2.new(1, 0, 0, 1), Parent = map })
	end

	local rng = Random.new(8)
	-- forests
	for _ = 1, 46 do
		local region = rng:NextNumber() < 0.55 and { 470, 680, 18, 110 } or { 14, 150, 300, 500 }
		local s = rng:NextInteger(10, 20)
		local t = UI.frame({ BackgroundColor3 = Color3.fromRGB(116, 148, 98), BackgroundTransparency = rng:NextNumber(0.15, 0.4),
			Position = UDim2.fromOffset(rng:NextInteger(region[1], region[2]), rng:NextInteger(region[3], region[4])), Size = UDim2.fromOffset(s, s), Parent = map })
		UI.corner(UDim.new(0.5, 0)).Parent = t
	end
	-- fields by the farm
	for i = 0, 2 do
		local fld = UI.frame({ BackgroundColor3 = Color3.fromRGB(232, 222, 160), Position = UDim2.fromOffset(410 + i * 48, 128), Size = UDim2.fromOffset(42, 66), Parent = map })
		for j = 0, 4 do
			UI.frame({ BackgroundColor3 = Color3.fromRGB(200, 186, 120), Position = UDim2.fromOffset(0, j * 14 + 4), Size = UDim2.new(1, 0, 0, 2), Parent = fld })
		end
	end
	UI.text({ Text = "farm", FontFace = F.hand, TextSize = 14, TextColor3 = C.inkSoft, Position = UDim2.fromOffset(456, 196), Size = UDim2.fromOffset(60, 16), Parent = map })
	-- town
	UI.frame({ BackgroundColor3 = Color3.fromRGB(196, 186, 168), Position = UDim2.fromOffset(340, 440), Size = UDim2.fromOffset(360, 5), Parent = map })
	UI.frame({ BackgroundColor3 = Color3.fromRGB(196, 186, 168), Position = UDim2.fromOffset(500, 330), Size = UDim2.fromOffset(5, 200), Parent = map })
	for _ = 1, 30 do
		local bx, by = rng:NextInteger(350, 680), rng:NextInteger(370, 500)
		UI.frame({ BackgroundColor3 = Color3.fromRGB(184, 178, 166), BackgroundTransparency = 0.2,
			Position = UDim2.fromOffset(bx, by), Size = UDim2.fromOffset(rng:NextInteger(14, 26), rng:NextInteger(10, 18)), Parent = map })
	end
	UI.text({ Text = UI.upper(case.town), FontFace = F.type, TextSize = 20, TextColor3 = C.inkSoft, TextTransparency = 0.25,
		Position = UDim2.fromOffset(370, 470), Size = UDim2.fromOffset(160, 26), Parent = map })

	-- river
	local pts = case.riverPath
	for i = 1, #pts - 1 do
		UI.thread(map, pts[i], pts[i + 1], { width = 24, color = WATER, z = 2 })
	end
	for _, p in pts do
		local j = UI.frame({ BackgroundColor3 = WATER, Size = UDim2.fromOffset(24, 24), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(p.X, p.Y), ZIndex = 2, Parent = map })
		UI.corner(UDim.new(0.5, 0)).Parent = j
	end
	for i = 1, #pts - 1 do
		UI.thread(map, pts[i], pts[i + 1], { width = 3, color = Color3.fromRGB(170, 200, 220), z = 3 })
	end
	UI.text({ Text = case.river .. " river", FontFace = F.handBold, TextSize = 16, TextColor3 = Color3.fromRGB(60, 96, 128),
		Position = UDim2.fromOffset(600, 268), Size = UDim2.fromOffset(110, 20), Rotation = 12, ZIndex = 4, Parent = map })
	UI.text({ Text = "to the Baltic Sea →", FontFace = F.hand, TextSize = 13, TextColor3 = Color3.fromRGB(60, 96, 128),
		Position = UDim2.fromOffset(566, 326), Size = UDim2.fromOffset(120, 16), Rotation = 10, ZIndex = 4, Parent = map })

	-- plant building + pipe
	local plantLoc
	for _, l in case.locations do if l.id == "plant" then plantLoc = l end end
	local pipeP
	for _, sp in case.samplePoints do if sp.id == "pipe" then pipeP = sp end end
	if plantLoc and pipeP then
		UI.thread(map, Vector2.new(plantLoc.x, plantLoc.y + 10), Vector2.new(pipeP.x, pipeP.y), { width = 4, color = Color3.fromRGB(80, 80, 84), z = 3 })
		UI.frame({ BackgroundColor3 = Color3.fromRGB(96, 98, 104), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(plantLoc.x, plantLoc.y - 4), Size = UDim2.fromOffset(74, 38), ZIndex = 3, Parent = map })
		UI.frame({ BackgroundColor3 = Color3.fromRGB(80, 82, 88), Position = UDim2.fromOffset(plantLoc.x + 18, plantLoc.y - 50), Size = UDim2.fromOffset(10, 30), ZIndex = 3, Parent = map })
	end

	-- time-of-day tint
	if state:isNight() then
		UI.frame({ BackgroundColor3 = Color3.fromRGB(16, 24, 56), BackgroundTransparency = 0.45, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = map })
	elseif state.slot == 3 then
		UI.frame({ BackgroundColor3 = Color3.fromRGB(120, 60, 30), BackgroundTransparency = 0.82, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = map })
	end

	--------------------------------------------------------------------
	-- Actions
	--------------------------------------------------------------------
	local function refresh() app:go("Map") end

	local function actionCard(title, desc, extra, actions)
		app:openModal(function(m, close)
			local cardH = 150 + (#actions + 1) * 48
			local h, s = UI.indexCard(m, { pos = UDim2.fromOffset(480, 270), anchor = Vector2.new(0.5, 0.5), size = UDim2.fromOffset(500, cardH), rot = -0.8, lineTop = 50, lineGap = 26 })
			UI.pin(h, UDim2.new(0.5, 0, 0, 8))
			UI.text({ Text = UI.upper(title), FontFace = F.type, TextSize = 20, Position = UDim2.fromOffset(22, 16), Size = UDim2.new(1, -44, 0, 26), Parent = s })
			UI.text({ Text = desc, FontFace = F.serif, TextSize = 15, Position = UDim2.fromOffset(22, 54), Size = UDim2.new(1, -44, 0, 44), Parent = s })
			if extra then
				UI.text({ Text = extra, FontFace = F.hand, TextSize = 16, TextColor3 = C.blue, Position = UDim2.fromOffset(22, 98), Size = UDim2.new(1, -44, 0, 22), Parent = s })
			end
			local col = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(22, 128), Size = UDim2.new(1, -44, 0, cardH - 140), Parent = s })
			UI.list(nil, 8).Parent = col
			for i, a in actions do
				local label = a.text .. (a.cost and a.cost > 0 and "   · 1 part of the day" or (a.cost == 0 and "   · free" or ""))
				local _, api = UI.button(col, label, { style = a.primary and "ink" or "paper", font = F.serif, textSize = 15, order = i,
					size = UDim2.new(1, 0, 0, 40), alignX = Enum.TextXAlignment.Left,
					onClick = function()
						close()
						a.run()
					end })
				api.instance.FontFace = F.serif
				if a.disabled then api.setEnabled(false) end
			end
			UI.button(col, "Not now", { style = "paper", textSize = 14, order = 99, size = UDim2.fromOffset(120, 34), onClick = close })
		end, { closeOnDim = true })
	end

	local function openLocation(loc)
		local open = state:isOpen(loc)
		local actions = {}
		if loc.id == "office" then
			table.insert(actions, { text = "Open the case board", cost = 0, primary = true, run = function() app:go("Board") end })
			table.insert(actions, { text = "Search the company register", cost = state.moneyOpened and 0 or 1, run = function()
				if not state.moneyOpened then
					state.moneyOpened = true
					app:spend(1)
				end
				app:go("MoneyTrail")
			end })
		end
		if loc.witness then
			local ch = case.characters[loc.witness]
			local met = state.visited[loc.witness]
			table.insert(actions, { text = (met and "Continue talking to " or "Talk to ") .. ch.name, cost = met and 0 or 1, primary = true,
				disabled = not open, run = function()
					if not met then
						state.visited[loc.witness] = true
						app:spend(1)
					end
					app:go("Interview", { witness = loc.witness })
				end })
		end
		if loc.brochure and not state.revealed[loc.brochure] then
			table.insert(actions, { text = "Take the plant's Green Report", cost = 0, disabled = not open, run = function()
				state:reveal(loc.brochure)
				app:toast("New evidence: the plant's Green Report. Find it on your case board.")
			end })
		end
		if loc.records and not state.recordsRequested then
			table.insert(actions, { text = "Request public records", cost = 1, disabled = not open, run = function()
				state.recordsRequested = true
				for _, ev in loc.records do state:reveal(ev) end
				app:spend(1)
				app:toast("You received the council minutes and the official lab summary.")
				refresh()
			end })
		end
		local extra = open and ("Open: " .. slotList(loc.open)) or ("Closed now. Open: " .. slotList(loc.open))
		actionCard(loc.name, loc.desc, extra, actions)
	end

	local function sampleKey(id, night) return id .. (night and "_night" or "_day") end

	local function openSample(sp)
		local night = state:isNight()
		local done = state.samples[sampleKey(sp.id, night)]
		local extra
		if done then
			extra = ("Already tested at this time: %.1f mg/L"):format(done.value)
		else
			extra = ("Test kits left: %d · it is %s now"):format(state.kits, string.lower(state:slotName()))
		end
		actionCard("Sample point: " .. sp.name, sp.desc, extra, {
			{ text = "Take a water sample", cost = 1, primary = true, disabled = state.kits <= 0 or done ~= nil, run = function()
				local slot, day = state:slotName(), state:dayName()
				state.kits -= 1
				app:spend(1)
				app:go("Sampling", { point = sp.id, night = night, slot = slot, day = day })
			end },
		})
	end

	--------------------------------------------------------------------
	-- Markers
	--------------------------------------------------------------------
	for _, loc in case.locations do
		local open = state:isOpen(loc)
		local tag = UI.new("TextButton", {
			Name = loc.id, Text = loc.name, FontFace = F.type, TextSize = 13,
			TextColor3 = open and C.ink or C.inkFaint, BackgroundColor3 = open and C.paperWhite or C.paperShade,
			BorderSizePixel = 0, AutoButtonColor = false, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0),
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(loc.x, loc.y + 10), ZIndex = 10, Parent = map,
		})
		UI.pad(4, 8).Parent = tag
		UI.stroke(C.ink, 1, 0.4).Parent = tag
		UI.pin(map, UDim2.fromOffset(loc.x, loc.y + 2), open and C.red or C.inkFaint, 11)
		if loc.witness and state.visited[loc.witness] then
			UI.text({ Text = "✓", FontFace = F.handBold, TextSize = 18, TextColor3 = C.green, Position = UDim2.new(1, 0, 0, -10), Size = UDim2.fromOffset(20, 24), ZIndex = 11, Parent = tag })
		end
		tag.MouseEnter:Connect(function() UI.tween(tag, 0.1, { BackgroundColor3 = C.manila }) end)
		tag.MouseLeave:Connect(function() UI.tween(tag, 0.1, { BackgroundColor3 = open and C.paperWhite or C.paperShade }) end)
		tag.Activated:Connect(function() openLocation(loc) end)
	end

	for _, sp in case.samplePoints do
		local dot = UI.new("TextButton", {
			Name = "Sample_" .. sp.id, Text = "●", FontFace = F.sansBold, TextSize = 12, TextColor3 = WATER,
			BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, AutoButtonColor = false,
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(sp.x, sp.y), Size = UDim2.fromOffset(24, 24), ZIndex = 9, Parent = map,
		})
		UI.corner(UDim.new(0.5, 0)).Parent = dot
		UI.stroke(Color3.fromRGB(40, 80, 120), 2).Parent = dot
		dot.Activated:Connect(function() openSample(sp) end)
		dot.MouseEnter:Connect(function() UI.tween(dot, 0.1, { Size = UDim2.fromOffset(30, 30) }) end)
		dot.MouseLeave:Connect(function() UI.tween(dot, 0.1, { Size = UDim2.fromOffset(24, 24) }) end)
		-- results next to the point
		local parts = {}
		for _, night in { false, true } do
			local r = state.samples[sampleKey(sp.id, night)]
			if r then
				table.insert(parts, (night and "night " or "day ") .. ("%.1f"):format(r.value))
			end
		end
		local label = sp.name .. (#parts > 0 and ("\n" .. table.concat(parts, " · ")) or "")
		local worst = 0
		for _, night in { false, true } do
			local r = state.samples[sampleKey(sp.id, night)]
			if r then worst = math.max(worst, r.value) end
		end
		UI.text({
			Text = label, FontFace = F.handBold, TextSize = 13, TextWrapped = false,
			TextColor3 = worst > case.sampleLimit and C.red or Color3.fromRGB(40, 70, 110),
			AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0),
			Position = UDim2.fromOffset(sp.x + 16, sp.y - 26), ZIndex = 9, Parent = map,
		})
	end

	--------------------------------------------------------------------
	-- Right panel: clock, kits, buttons
	--------------------------------------------------------------------
	local _, clock = UI.paper(root, { pos = UDim2.fromOffset(716, 14), size = UDim2.fromOffset(232, 156), color = C.paper, age = false })
	UI.text({ Text = UI.upper(state:dayName()) .. " · DAY " .. state.day .. " OF " .. Config.DAYS, FontFace = F.type, TextSize = 13, TextColor3 = C.inkSoft,
		Position = UDim2.fromOffset(14, 12), Size = UDim2.new(1, -28, 0, 18), Parent = clock })
	UI.text({ Text = UI.upper(state:slotName()), FontFace = F.type, TextSize = 30, TextColor3 = state:isNight() and C.blue or C.ink,
		Position = UDim2.fromOffset(14, 32), Size = UDim2.new(1, -28, 0, 36), Parent = clock })
	local track = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 78), Size = UDim2.new(1, -28, 0, 22), Parent = clock })
	UI.list(Enum.FillDirection.Horizontal, 2).Parent = track
	local now = state:timeIndex()
	for i = 1, state:totalSlots() do
		local past = i < now
		local sq = UI.frame({ BackgroundColor3 = i == now and C.red or (past and C.inkSoft or C.paperWhite), Size = UDim2.fromOffset(12, 18), LayoutOrder = i, Parent = track })
		UI.stroke(C.ink, 1, 0.5).Parent = sq
		if i % 4 == 0 and i < state:totalSlots() then
			UI.frame({ BackgroundTransparency = 1, Size = UDim2.fromOffset(4, 18), LayoutOrder = i, Parent = track })
		end
	end
	UI.text({ Text = "Council hearing: Friday, 10:00", FontFace = F.handBold, TextSize = 15, TextColor3 = C.red,
		Position = UDim2.fromOffset(14, 112), Size = UDim2.new(1, -28, 0, 30), Parent = clock })

	-- test kits
	local kitsRow = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(716, 182), Size = UDim2.fromOffset(232, 30), Parent = root })
	UI.text({ Text = "TEST KITS", FontFace = F.type, TextSize = 14, TextColor3 = C.paperShade, Size = UDim2.fromOffset(100, 30), TextYAlignment = Enum.TextYAlignment.Center, Parent = kitsRow })
	for i = 1, Config.TEST_KITS do
		local full = i <= state.kits
		local tube = UI.frame({ BackgroundColor3 = full and Color3.fromRGB(196, 222, 236) or C.desk, Position = UDim2.fromOffset(104 + (i - 1) * 26, 2), Size = UDim2.fromOffset(14, 26), Parent = kitsRow })
		UI.corner(UDim.new(0, 6)).Parent = tube
		UI.stroke(C.paperShade, 1.5).Parent = tube
	end

	local n, total = state:countFound()
	UI.text({ Text = ("Clues found: %d of %d"):format(n, total), FontFace = F.hand, TextSize = 16, TextColor3 = C.paper,
		Position = UDim2.fromOffset(716, 218), Size = UDim2.fromOffset(232, 22), Parent = root })

	UI.button(root, "Case board", { style = "paper", pos = UDim2.fromOffset(716, 248), size = UDim2.fromOffset(232, 42),
		onClick = function() app:go("Board") end })

	local _, hintApi
	_, hintApi = UI.button(root, ("Hint (%d left)"):format(state.hintsLeft), { style = "paper", pos = UDim2.fromOffset(716, 298), size = UDim2.fromOffset(232, 38),
		textSize = 14,
		onClick = function()
			local text = state:useHint()
			if not text then return end
			hintApi.setText(("Hint (%d left)"):format(state.hintsLeft))
			if state.hintsLeft <= 0 then hintApi.setEnabled(false) end
			app:openModal(function(m, close)
				UI.polaroid(m, { pos = UDim2.fromOffset(200, 150), size = UDim2.fromOffset(150, 184), rot = -5, look = case.characters.chief.look, caption = case.characters.chief.name })
				local h, s = UI.indexCard(m, { pos = UDim2.fromOffset(380, 160), size = UDim2.fromOffset(380, 190), rot = 1.5, lineTop = 50, lineGap = 26 })
				UI.pin(h, UDim2.new(0.5, 0, 0, 8))
				UI.text({ Text = "HINT", FontFace = F.type, TextSize = 16, TextColor3 = C.inkFaint, Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(200, 22), Parent = s })
				UI.text({ Text = "— " .. text, FontFace = F.serif, TextSize = 17, Position = UDim2.fromOffset(18, 50), Size = UDim2.new(1, -36, 1, -100), Parent = s })
				UI.text({ Text = "(each hint lowers your final evidence score a little)", FontFace = F.hand, TextSize = 14, TextColor3 = C.inkFaint,
					Position = UDim2.new(0, 18, 1, -40), Size = UDim2.new(1, -36, 0, 20), Parent = s })
				UI.button(m, "Got it", { pos = UDim2.fromOffset(600, 370), size = UDim2.fromOffset(150, 42), onClick = close })
			end, { closeOnDim = true })
		end })
	if state.hintsLeft <= 0 then hintApi.setEnabled(false) end

	UI.text({ Text = "Tap a place to visit it, or a blue dot on the river to test the water. Most actions take one part of the day. Some places close in the evening.",
		FontFace = F.hand, TextSize = 15, TextColor3 = C.paperShade, Position = UDim2.fromOffset(716, 346), Size = UDim2.fromOffset(232, 100), Parent = root })

	UI.button(root, "Go to the hearing →", { pos = UDim2.fromOffset(716, 470), size = UDim2.fromOffset(232, 50), textSize = 16,
		onClick = function()
			app:openModal(function(m, close)
				local h, s = UI.indexCard(m, { pos = UDim2.fromOffset(480, 270), anchor = Vector2.new(0.5, 0.5), size = UDim2.fromOffset(460, 220), rot = -1, lineTop = 50, lineGap = 26 })
				UI.pin(h, UDim2.new(0.5, 0, 0, 8))
				UI.text({ Text = "END THE INVESTIGATION?", FontFace = F.type, TextSize = 19, Position = UDim2.fromOffset(20, 16), Size = UDim2.new(1, -40, 0, 26), Parent = s })
				local left = state:totalSlots() - state:timeIndex() + 1
				UI.text({ Text = ("You still have %d parts of the day. Once you go to the hearing, you can't come back to the map."):format(left),
					FontFace = F.hand, TextSize = 18, TextColor3 = C.blue, Position = UDim2.fromOffset(20, 52), Size = UDim2.new(1, -40, 0, 70), Parent = s })
				UI.button(s, "Go to the hearing", { pos = UDim2.new(1, -20, 1, -16), anchor = Vector2.new(1, 1), size = UDim2.fromOffset(210, 40), textSize = 15,
					onClick = function() app:go("Report") end })
				UI.button(s, "Keep looking", { style = "paper", pos = UDim2.new(0, 20, 1, -16), anchor = Vector2.new(0, 1), size = UDim2.fromOffset(150, 40), onClick = close })
			end, { closeOnDim = true })
		end })

	-- First visit tutorial, then phone messages
	task.delay(0.5, function()
		if not root.Parent then return end
		if not state.tutorial.map then
			state.tutorial.map = true
			app:toast("Start anywhere. The newspaper and town chat are already on your case board.")
		end
		app:checkPhone()
	end)
end

return Map
