-- main screen
local Viewer = require(script.Parent.Viewer)
local Config = require(script.Parent.Parent.Config)

local Board = {}

-- leads
local function plural(n, one, many)
	if n % 10 == 1 and n % 100 ~= 11 then
		return n .. " " .. one
	end
	return n .. " " .. many
end

local function rotatePoint(center, offset, deg)
	local r = math.rad(deg)
	local c, s = math.cos(r), math.sin(r)
	return center + Vector2.new(offset.X * c - offset.Y * s, offset.X * s + offset.Y * c)
end

function Board.build(app, root)
	local UI = app.UI
	local C, F = UI.C, UI.F
	local case, state = app.case, app.state
	local conns = {}
	state.threadSeen = state.threadSeen or {}

	--------------------------------------------------------------------
	-- case board
	--------------------------------------------------------------------
	local _, woodSheet = UI.paper(root, { pos = UDim2.fromOffset(12, 12), size = UDim2.fromOffset(684, 516), color = C.wood, age = false, shadowY = 8, shadowT = 0.45 })
	local cork = UI.frame({ Name = "Cork", BackgroundColor3 = C.cork, Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 1, -24), Parent = woodSheet })
	UI.stroke(C.woodLight, 2).Parent = cork
	UI.new("UIGradient", { Rotation = 70, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 200, 195)), Parent = cork })
	local rng = Random.new(42)
	for _ = 1, 170 do
		local sz = rng:NextInteger(2, 4)
		UI.frame({ BackgroundColor3 = rng:NextNumber() < 0.6 and C.corkSpeck or C.corkDark, BackgroundTransparency = rng:NextNumber(0.2, 0.65),
			Position = UDim2.fromOffset(rng:NextInteger(2, 655), rng:NextInteger(2, 488)), Size = UDim2.fromOffset(sz, sz), Parent = cork })
	end

	local nodes = {}

	-- case title
	local lh, ls = UI.paper(cork, { pos = UDim2.fromOffset(14, 10), size = UDim2.fromOffset(176, 54), rot = -1.5, color = C.paperWhite, age = false })
	UI.text({ Text = "LIETA Nr. " .. case.number, FontFace = F.type, TextSize = 12, TextColor3 = C.inkFaint, Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 16), Parent = ls })
	UI.text({ Text = UI.upper(case.title), FontFace = F.type, TextSize = 15, TextWrapped = false, Position = UDim2.fromOffset(10, 25), Size = UDim2.new(1, -20, 0, 22), Parent = ls })
	UI.tape(lh, UDim2.fromOffset(4, 4), -40, 34)

	-- main q
	local qh, qs = UI.indexCard(cork, { pos = UDim2.fromOffset(212, 226), size = UDim2.fromOffset(196, 70), rot = -1.5, lineTop = 26, lineGap = 20 })
	UI.text({ Text = case.question, FontFace = F.handBold, TextSize = 19, TextColor3 = C.red, Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 1, -10),
		TextYAlignment = Enum.TextYAlignment.Center, TextXAlignment = Enum.TextXAlignment.Center, Parent = qs })
	UI.pin(qh, UDim2.new(0.5, 0, 0, 6), C.ink)
	nodes.question = Vector2.new(212 + 98, 226 + 6)

	-- goal
	local sh, ss = UI.paper(cork, { pos = UDim2.fromOffset(530, 168), size = UDim2.fromOffset(116, 86), rot = 3, color = Color3.fromRGB(236, 214, 140), age = false })
	UI.text({ Text = "PIEKTDIEN\n15.00", FontFace = F.type, TextSize = 15, Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 40), TextXAlignment = Enum.TextXAlignment.Center, Parent = ss })
	UI.text({ Text = "vajag vismaz " .. Config.TEAM_NEEDED, FontFace = F.handBold, TextSize = 17, TextColor3 = C.red, Position = UDim2.fromOffset(8, 48), Size = UDim2.new(1, -16, 0, 30), TextXAlignment = Enum.TextXAlignment.Center, Parent = ss })
	UI.tape(sh, UDim2.new(0.5, 0, 0, 0), -4, 50)

	--------------------------------------------------------------------
	-- evidence cards
	--------------------------------------------------------------------
	local cardRefs = {}

	local function miniLines(parent, x, y, w, n, gap, color)
		local r = Random.new(#parent.Name + n)
		for i = 1, n do
			UI.frame({ BackgroundColor3 = color or C.inkFaint, BackgroundTransparency = 0.45, Position = UDim2.fromOffset(x, y + (i - 1) * gap),
				Size = UDim2.fromOffset(math.floor(w * r:NextNumber(0.55, 1)), 2), Parent = parent })
		end
	end

	local function plainText(parts)
		local t = {}
		for _, p in parts do
			table.insert(t, type(p) == "table" and p[1] or p)
		end
		return table.concat(t)
	end

	local function buildCard(ev, dropIn)
		local b = ev.board
		local colors = { email = C.paperWhite, chat = C.screen, plan = C.blueprint, table = C.paper, note = C.card }
		local holder, sheet = UI.paper(cork, { name = ev.id, pos = UDim2.fromOffset(b.x, b.y), size = UDim2.fromOffset(b.w, b.h), rot = b.rot,
			color = colors[ev.kind], age = ev.kind ~= "plan" and ev.kind ~= "chat" })
		local w, h = b.w, b.h - 20

		if ev.kind == "email" then
			UI.text({ Text = "No: Ilze Kalniņa", FontFace = F.mono, TextSize = 9, TextColor3 = C.inkSoft, Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(w - 16, 12), Parent = sheet })
			UI.text({ Text = "Temats: Robotikas darbnīcas", FontFace = F.mono, TextSize = 9, TextColor3 = C.inkSoft, Position = UDim2.fromOffset(8, 20), Size = UDim2.fromOffset(w - 16, 12), TextTruncate = Enum.TextTruncate.AtEnd, Parent = sheet })
			miniLines(sheet, 8, 40, w - 16, 6, 8)
		elseif ev.kind == "chat" then
			local bar = UI.frame({ BackgroundColor3 = Color3.fromRGB(32, 35, 41), Size = UDim2.new(1, 0, 0, 16), Parent = sheet })
			UI.text({ Text = ev.chatTitle, FontFace = F.sansBold, TextSize = 10, TextColor3 = Color3.new(1, 1, 1), Position = UDim2.fromOffset(6, 2), Size = UDim2.new(1, -12, 1, -2), Parent = bar })
			local y = 24
			for i, m in ev.messages do
				if y > h - 18 then break end
				local bub = UI.frame({ BackgroundColor3 = C.bubble, Position = UDim2.fromOffset(6, y), Size = UDim2.fromOffset(w - 20, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = sheet })
				UI.corner(4).Parent = bub
				UI.stroke(Color3.fromRGB(205, 208, 214), 1).Parent = bub
				UI.pad(3, 5).Parent = bub
				local t = UI.text({ Text = plainText(m.parts), FontFace = F.sans, TextSize = i == 1 and 11 or 10, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = bub })
				t.TextTruncate = Enum.TextTruncate.AtEnd
				y += (i == 1 and (ev.id == "E2" and 56 or 44) or 24)
			end
		elseif ev.kind == "plan" then
			for _, r in { { 8, 8, 0.5, 0.36 }, { 0.58, 8, 0.36, 0.36 }, { 8, 0.5, 0.86, 0.4 } } do
				local fx = r[1] < 1 and UDim.new(r[1], 0) or UDim.new(0, r[1])
				local fy = r[2] < 1 and UDim.new(r[2], 0) or UDim.new(0, r[2])
				local f = UI.frame({ BackgroundTransparency = 1, Position = UDim2.new(fx, fy), Size = UDim2.new(r[3], 0, r[4], -4), Parent = sheet })
				UI.stroke(C.blueprintLine, 1).Parent = f
			end
			UI.text({ Text = "LAB?", FontFace = F.type, TextSize = 11, TextColor3 = C.blueprintLine, Position = UDim2.fromOffset(12, 14), Size = UDim2.fromOffset(40, 14), Parent = sheet })
		elseif ev.kind == "table" then
			for i = 0, 5 do
				UI.frame({ BackgroundColor3 = C.ink, BackgroundTransparency = i == 1 and 0.2 or 0.65, Position = UDim2.fromOffset(8, 10 + i * 12), Size = UDim2.fromOffset(w - 16, 1), Parent = sheet })
			end
			UI.frame({ BackgroundColor3 = C.ink, BackgroundTransparency = 0.65, Position = UDim2.fromOffset(w * 0.45, 10), Size = UDim2.fromOffset(1, 60), Parent = sheet })
			UI.text({ Text = "14.10  15.00", FontFace = F.mono, TextSize = 9, TextColor3 = C.inkSoft, Position = UDim2.fromOffset(w * 0.45 + 4, 36), Size = UDim2.fromOffset(w * 0.55, 12), Parent = sheet })
		elseif ev.kind == "note" then
			for i = 0, 3 do
				UI.frame({ BackgroundColor3 = C.cardLine, BackgroundTransparency = 0.4, Position = UDim2.fromOffset(0, 14 + i * 14), Size = UDim2.new(1, 0, 0, 1), Parent = sheet })
			end
			UI.text({ Text = "Robotikas darbnīca rīt, ceturtdien…", FontFace = F.hand, TextSize = 10, TextColor3 = C.blue, Position = UDim2.fromOffset(6, 4), Size = UDim2.fromOffset(w - 12, 40), Parent = sheet })
			UI.frame({ BackgroundColor3 = C.ink, BackgroundTransparency = 0.2, Position = UDim2.fromOffset(4, 22), Size = UDim2.fromOffset(w - 10, 2), Rotation = -3, Parent = sheet })
			UI.text({ Text = "neviens nelasīs", FontFace = F.handBold, TextSize = 12, Position = UDim2.fromOffset(20, 52), Size = UDim2.fromOffset(w - 24, 16), Rotation = -4, Parent = sheet })
		end

		-- bottom label
		local lab = UI.frame({ BackgroundColor3 = C.paperWhite, Position = UDim2.new(0, 0, 1, -20), Size = UDim2.new(1, 0, 0, 20), Parent = sheet })
		UI.frame({ BackgroundColor3 = C.ink, BackgroundTransparency = 0.8, Size = UDim2.new(1, 0, 0, 1), Parent = lab })
		UI.text({ Text = ev.id .. " · " .. UI.upper(ev.short or ev.label), FontFace = F.type, TextSize = 11, Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -36, 1, 0),
			TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Parent = lab })
		local prog = UI.text({ FontFace = F.handBold, TextSize = 14, TextColor3 = C.red, Position = UDim2.new(1, -36, 0, 0), Size = UDim2.fromOffset(32, 20),
			TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Center, Parent = lab })

		UI.pin(holder, UDim2.new(0.5, 0, 0, 6))

		local hit = UI.hit({ Name = "Open", ZIndex = 25, Parent = holder })
		hit.MouseEnter:Connect(function()
			UI.tween(holder, 0.12, { Rotation = b.rot * 0.4, Position = UDim2.fromOffset(b.x, b.y - 3) })
		end)
		hit.MouseLeave:Connect(function()
			UI.tween(holder, 0.12, { Rotation = b.rot, Position = UDim2.fromOffset(b.x, b.y) })
		end)
		hit.Activated:Connect(function()
			Viewer.open(app, ev)
		end)

		local center = Vector2.new(b.x + b.w / 2, b.y + b.h / 2)
		nodes[ev.id] = rotatePoint(center, Vector2.new(0, 6 - b.h / 2), b.rot)
		cardRefs[ev.id] = { holder = holder, sheet = sheet, prog = prog, ev = ev }

		if dropIn then
			holder.Position = UDim2.fromOffset(b.x, b.y - 40)
			UI.tween(holder, 0.35, { Position = UDim2.fromOffset(b.x, b.y) }, Enum.EasingStyle.Bounce)
		end
	end

	local function refreshCards()
		for _, ref in cardRefs do
			local n, t = Viewer.progress(state, ref.ev)
			ref.prog.Text = n .. "/" .. t
			ref.prog.TextColor3 = n == t and C.ink or C.red
		end
	end

	--------------------------------------------------------------------
	-- hidden clue
	--------------------------------------------------------------------
	local threadLayer
	local drawThreads
	local refreshTokens

	local function buildCrumpled(ev)
		local ball = UI.frame({ Name = "Crumpled", BackgroundTransparency = 1, Position = UDim2.fromOffset(70, 404), Size = UDim2.fromOffset(58, 50), Parent = cork })
		local r = Random.new(5)
		UI.frame({ BackgroundColor3 = C.black, BackgroundTransparency = 0.55, Position = UDim2.fromOffset(4, 6), Size = UDim2.fromScale(1, 1), Parent = ball }).Parent = ball
		local sh = ball:GetChildren()[1]
		UI.corner(UDim.new(0.45, 0)).Parent = sh
		for i = 1, 6 do
			local f = UI.frame({
				BackgroundColor3 = (i % 2 == 0) and C.paper or C.paperShade,
				Position = UDim2.fromOffset(r:NextInteger(0, 18), r:NextInteger(0, 14)),
				Size = UDim2.fromOffset(r:NextInteger(30, 42), r:NextInteger(26, 36)),
				Rotation = r:NextInteger(-40, 40),
				Parent = ball,
			})
			UI.corner(UDim.new(0.3, 0)).Parent = f
			UI.stroke(C.inkFaint, 1, 0.55).Parent = f
		end
		local hit = UI.hit({ ZIndex = 25, Size = UDim2.new(1, 20, 1, 20), Position = UDim2.fromOffset(-10, -10), Parent = ball })
		hit.MouseEnter:Connect(function() UI.tween(ball, 0.15, { Rotation = 8 }) end)
		hit.MouseLeave:Connect(function() UI.tween(ball, 0.15, { Rotation = 0 }) end)
		hit.Activated:Connect(function()
			if state:reveal(ev.id) then
				ball:Destroy()
				buildCard(ev, true)
				refreshCards()
				app:toast("Saburzīta lapa — Markusa melnraksts! Tev ir vēl viena saruna.", C.red)
				if refreshTokens then refreshTokens() end
				if threadLayer then threadLayer.ZIndex = threadLayer.ZIndex end
			end
		end)
	end

	for _, ev in case.evidence do
		if state:isVisible(ev) then
			buildCard(ev)
		elseif ev.hidden then
			buildCrumpled(ev)
		end
	end

	--------------------------------------------------------------------
	-- witnesses
	--------------------------------------------------------------------
	local witnessRefs = {}
	local rots = { -3, 2, -2, 3 }

	local function confirmInterview(wid)
		local ch = case.characters[wid]
		app:openModal(function(m, close)
			local h, s = UI.indexCard(m, { pos = UDim2.fromOffset(480, 270), anchor = Vector2.new(0.5, 0.5), size = UDim2.fromOffset(440, 230), rot = -1, lineTop = 56, lineGap = 26 })
			UI.pin(h, UDim2.new(0.5, 0, 0, 8))
			UI.text({ Text = "SARUNA: " .. UI.upper(ch.full), FontFace = F.type, TextSize = 19, Position = UDim2.fromOffset(20, 18), Size = UDim2.new(1, -40, 0, 26), Parent = s })
			UI.text({
				Text = ("%s.\nSaruna aizņems laiku. Atlikušās sarunas: %d."):format(ch.role, state.tokens),
				FontFace = F.hand, TextSize = 19, TextColor3 = C.blue, Position = UDim2.fromOffset(20, 54), Size = UDim2.new(1, -40, 0, 80), LineHeight = 1.05, Parent = s,
			})
			UI.button(s, "Runāt", { pos = UDim2.new(1, -20, 1, -18), anchor = Vector2.new(1, 1), size = UDim2.fromOffset(150, 42), onClick = function()
				if state:startInterview(wid) then
					app:go("Interview", { witness = wid })
				else
					close()
				end
			end })
			UI.button(s, "Vēl ne", { style = "paper", pos = UDim2.new(0, 20, 1, -18), anchor = Vector2.new(0, 1), size = UDim2.fromOffset(120, 42), onClick = close })
		end, { closeOnDim = true })
	end

	for i, wid in case.witnessOrder do
		local ch = case.characters[wid]
		local x, y, w, h = 196 + (i - 1) * 112, 330, 98, 122
		local holder, sheet, photo = UI.polaroid(cork, { name = wid, pos = UDim2.fromOffset(x, y), size = UDim2.fromOffset(w, h), rot = rots[i],
			look = ch.look, small = ch.small, caption = ch.name, captionSize = 16 })
		UI.pin(holder, UDim2.new(0.5, 0, 0, 5))
		local center = Vector2.new(x + w / 2, y + h / 2)
		nodes[wid] = rotatePoint(center, Vector2.new(0, 5 - h / 2), rots[i])
		local hit = UI.hit({ ZIndex = 25, Parent = holder })
		hit.MouseEnter:Connect(function() UI.tween(holder, 0.12, { Position = UDim2.fromOffset(x, y - 4) }) end)
		hit.MouseLeave:Connect(function() UI.tween(holder, 0.12, { Position = UDim2.fromOffset(x, y) }) end)
		hit.Activated:Connect(function()
			if state.interviewed[wid] then
				app:go("Interview", { witness = wid })
			elseif state.tokens > 0 then
				confirmInterview(wid)
			else
				app:toast("Laika sarunām vairs nav. Atliek pierādījumi.", C.red)
			end
		end)
		witnessRefs[wid] = { holder = holder, photo = photo }
	end

	local function refreshWitnesses()
		for wid, ref in witnessRefs do
			local old = ref.photo:FindFirstChild("Status")
			if old then old:Destroy() end
			if state.interviewed[wid] then
				local st = UI.stamp(ref.photo, "Nopratināts", { size = 11, rot = -14, animate = false, thick = 1.5 })
				st.Name = "Status"
				st.BackgroundColor3 = C.paperWhite
				st.BackgroundTransparency = 0.15
			elseif state.tokens <= 0 then
				local g = UI.frame({ Name = "Status", BackgroundColor3 = C.black, BackgroundTransparency = 0.45, Size = UDim2.fromScale(1, 1), Parent = ref.photo })
				UI.text({ Text = "NAV LAIKA", FontFace = F.type, TextSize = 11, TextColor3 = C.paper, TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = g })
			end
		end
	end

	--------------------------------------------------------------------
	-- connecting lines
	--------------------------------------------------------------------
	threadLayer = UI.frame({ Name = "Threads", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = cork })
	local drawn = {}
	drawThreads = function()
		for _, id in state.foundOrder do
			local clue = case.clues[id]
			local link = clue and clue.link
			if link then
				local key = link[1] .. ">" .. link[2]
				local a, b = nodes[link[1]], nodes[link[2]]
				if not drawn[key] and a and b then
					drawn[key] = true
					local isNew = not state.threadSeen[key]
					state.threadSeen[key] = true
					UI.thread(threadLayer, a, b, { animate = isNew, z = 5 })
					for _, p in { a, b } do
						UI.pin(threadLayer, UDim2.fromOffset(p.X, p.Y), C.red, 6)
					end
				end
			end
		end
	end

	--------------------------------------------------------------------
	-- notepad
	--------------------------------------------------------------------
	local nbH, nb = UI.paper(root, { pos = UDim2.fromOffset(712, 18), size = UDim2.fromOffset(232, 318), rot = 0, color = C.card, age = false })
	for i = 0, 9 do
		local ring = UI.frame({ BackgroundColor3 = C.desk, Position = UDim2.fromOffset(14 + i * 21, -6), Size = UDim2.fromOffset(9, 14), Parent = nb })
		UI.corner(4).Parent = ring
		UI.stroke(Color3.fromRGB(150, 150, 150), 1.5).Parent = ring
	end
	local y = 50
	while y < 316 do
		UI.frame({ BackgroundColor3 = C.cardLine, BackgroundTransparency = 0.5, Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 1), Parent = nb })
		y += 24
	end
	UI.frame({ BackgroundColor3 = C.cardMargin, BackgroundTransparency = 0.4, Position = UDim2.fromOffset(24, 0), Size = UDim2.new(0, 1, 1, 0), Parent = nb })
	local nbTitle = UI.text({ FontFace = F.type, TextSize = 16, Position = UDim2.fromOffset(32, 16), Size = UDim2.new(1, -40, 0, 22), Parent = nb })
	local list = UI.new("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(30, 46), Size = UDim2.new(1, -36, 1, -52),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ScrollBarImageColor3 = C.inkFaint,
		ScrollingDirection = Enum.ScrollingDirection.Y, Parent = nb,
	})
	UI.list(nil, 0).Parent = list

	local function refreshNotes()
		for _, ch in list:GetChildren() do
			if ch:IsA("GuiObject") then ch:Destroy() end
		end
		local n = #state.foundOrder
		nbTitle.Text = "PIEZĪMES (" .. n .. ")"
		if n == 0 then
			UI.text({ Text = "Pagaidām tukšs.", FontFace = F.hand, TextSize = 17, TextColor3 = C.inkFaint, Size = UDim2.new(1, 0, 0, 24), Parent = list })
			return
		end
		for i = n, 1, -1 do
			local id = state.foundOrder[i]
			local clue = case.clues[id]
			local e = UI.new("TextButton", {
				Text = clue.title, FontFace = F.hand, TextSize = 16, TextColor3 = clue.kind == "fact" and C.blue or C.red,
				BackgroundTransparency = 1, AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.new(1, -4, 0, 24), LayoutOrder = n - i, Parent = list,
			})
			e.Activated:Connect(function()
				app:toast(clue.note, clue.kind == "fact" and C.blue or C.red)
			end)
		end
	end

	--------------------------------------------------------------------
	-- clues, hints, conclusions
	--------------------------------------------------------------------
	local tokRow = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(714, 352), Size = UDim2.fromOffset(230, 30), Parent = root })
	UI.text({ Text = "SARUNAS", FontFace = F.type, TextSize = 14, TextColor3 = C.paperShade, Size = UDim2.fromOffset(84, 30), TextYAlignment = Enum.TextYAlignment.Center, Parent = tokRow })
	local tokBox = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(90, 3), Size = UDim2.fromOffset(140, 24), Parent = tokRow })
	UI.list(Enum.FillDirection.Horizontal, 6).Parent = tokBox

	refreshTokens = function()
		tokBox:ClearAllChildren()
		UI.list(Enum.FillDirection.Horizontal, 6).Parent = tokBox
		local used = 0
		for _ in state.interviewed do used += 1 end
		local total = used + state.tokens
		local sqSize = math.min(22, math.floor(140 / math.max(1, total)) - 6)
		for i = 1, total do
			local avail = i > used
			local sq = UI.frame({ BackgroundColor3 = avail and C.paper or C.desk, Size = UDim2.fromOffset(sqSize, sqSize), LayoutOrder = i, Parent = tokBox })
			UI.stroke(C.paperShade, 1.5).Parent = sq
			if not avail then
				UI.text({ Text = "×", FontFace = F.handBold, TextSize = 22, TextColor3 = C.redBright, Size = UDim2.fromScale(1, 1),
					TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, Parent = sq })
			end
		end
		refreshWitnesses()
	end

	local _, hintApi
	local function hintLabel()
		return ("Mājiens (%d)"):format(state.hintsLeft)
	end
	_, hintApi = UI.button(root, hintLabel(), {
		style = "paper",
		pos = UDim2.fromOffset(714, 392),
		size = UDim2.fromOffset(230, 40),
		onClick = function()
			local text = state:useHint()
			if not text then
				app:toast("Mājieni ir beigušies. Tagad viss atkarīgs no tevis.")
				return
			end
			hintApi.setText(hintLabel())
			if state.hintsLeft <= 0 then hintApi.setEnabled(false) end
			app:openModal(function(m, close)
				local pol = UI.polaroid(m, { pos = UDim2.fromOffset(200, 150), size = UDim2.fromOffset(150, 184), rot = -5, look = case.characters.chief.look, caption = case.characters.chief.name })
				local h, s = UI.indexCard(m, { pos = UDim2.fromOffset(380, 160), size = UDim2.fromOffset(380, 190), rot = 1.5, lineTop = 50, lineGap = 26 })
				UI.pin(h, UDim2.new(0.5, 0, 0, 8))
				UI.text({ Text = "MĀJIENS", FontFace = F.type, TextSize = 16, TextColor3 = C.inkFaint, Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(200, 22), Parent = s })
				UI.text({ Text = "— " .. text, FontFace = F.serif, TextSize = 17, Position = UDim2.fromOffset(18, 50), Size = UDim2.new(1, -36, 1, -100), Parent = s })
				UI.text({ Text = "(katrs mājiens nedaudz samazina vērtējumu)", FontFace = F.hand, TextSize = 14, TextColor3 = C.inkFaint,
					Position = UDim2.new(0, 18, 1, -40), Size = UDim2.new(1, -36, 0, 20), Parent = s })
				UI.button(m, "Skaidrs", { pos = UDim2.fromOffset(600, 370), size = UDim2.fromOffset(150, 42), onClick = close })
			end, { closeOnDim = true })
		end,
	})
	if state.hintsLeft <= 0 then hintApi.setEnabled(false) end
	UI.text({ Text = "mājieni samazina vērtējumu", FontFace = F.hand, TextSize = 13, TextColor3 = C.inkFaint, Position = UDim2.fromOffset(714, 434), Size = UDim2.fromOffset(230, 16),
		TextXAlignment = Enum.TextXAlignment.Center, Parent = root })

	UI.button(root, "Secinājumi →", {
		pos = UDim2.fromOffset(714, 466),
		size = UDim2.fromOffset(230, 52),
		textSize = 19,
		onClick = function()
			local problems = 0
			for _, id in state.foundOrder do
				if case.clues[id].kind == "problem" then problems += 1 end
			end
			if problems >= 6 then
				app:go("Deduction")
				return
			end
			app:openModal(function(m, close)
				local h, s = UI.indexCard(m, { pos = UDim2.fromOffset(480, 270), anchor = Vector2.new(0.5, 0.5), size = UDim2.fromOffset(440, 210), rot = -1, lineTop = 50, lineGap = 26 })
				UI.pin(h, UDim2.new(0.5, 0, 0, 8))
				UI.text({ Text = "PAR AGRU?", FontFace = F.type, TextSize = 19, Position = UDim2.fromOffset(20, 16), Size = UDim2.new(1, -40, 0, 26), Parent = s })
				UI.text({ Text = ("Pagaidām esi atradis tikai %s par to, kas nogāja greizi. Bez pierādījumiem secinājumi ir tikai minējumi."):format(plural(problems, "pavedienu", "pavedienus")),
					FontFace = F.hand, TextSize = 18, TextColor3 = C.blue, Position = UDim2.fromOffset(20, 50), Size = UDim2.new(1, -40, 0, 80), Parent = s })
				UI.button(s, "Tomēr turpināt", { pos = UDim2.new(1, -20, 1, -16), anchor = Vector2.new(1, 1), size = UDim2.fromOffset(190, 40), textSize = 15, onClick = function() app:go("Deduction") end })
				UI.button(s, "Meklēt vēl", { style = "paper", pos = UDim2.new(0, 20, 1, -16), anchor = Vector2.new(0, 1), size = UDim2.fromOffset(140, 40), onClick = close })
			end, { closeOnDim = true })
		end,
	})

	--------------------------------------------------------------------
	-- tutorial hints
	--------------------------------------------------------------------
	local tutor
	local pulse
	local function refreshTutorial()
		if tutor then tutor:Destroy() tutor = nil end
		if pulse then pulse:Destroy() pulse = nil end
		local text
		if not state.tutorial.firstClue then
			text = "Sāc ar E2 — pulčiņa čatu.\nPieskaries mirgojošajai kartītei."
			local e2 = cardRefs.E2
			if e2 then
				pulse = UI.stroke(C.redBright, 3, 0)
				pulse.Parent = e2.sheet
				task.spawn(function()
					local p = pulse
					while p.Parent do
						UI.tween(p, 0.6, { Transparency = 0.85 }).Completed:Wait()
						if not p.Parent then break end
						UI.tween(p, 0.6, { Transparency = 0 }).Completed:Wait()
					end
				end)
			end
		elseif next(state.interviewed) == nil and #state.foundOrder >= 3 then
			text = "Lejā ir liecinieki. Katra saruna\naizņem laiku, tāpēc izvēlies gudri."
		end
		if text then
			local h, s = UI.paper(cork, { pos = UDim2.fromOffset(420, 262), size = UDim2.fromOffset(170, 58), rot = 2, color = Color3.fromRGB(240, 226, 160), age = false })
			local tl = UI.text({ Text = text, FontFace = F.handBold, TextSize = 15, TextColor3 = C.ink, Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 1, -8),
				TextYAlignment = Enum.TextYAlignment.Center, TextScaled = true, Parent = s })
			UI.new("UITextSizeConstraint", { MaxTextSize = 15, MinTextSize = 10, Parent = tl })
			h.ZIndex = 8
			tutor = h
		end
	end

	--------------------------------------------------------------------
	-- refresh
	--------------------------------------------------------------------
	local function refreshAll()
		refreshCards()
		refreshNotes()
		refreshTokens()
		drawThreads()
		refreshTutorial()
	end
	refreshAll()
	table.insert(conns, state.changed.Event:Connect(function()
		refreshAll()
	end))

	return function()
		for _, c in conns do c:Disconnect() end
	end
end

return Board
