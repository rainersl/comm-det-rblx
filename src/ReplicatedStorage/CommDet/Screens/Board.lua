-- Case board: evidence, people met, red threads between connected clues
-- and a notebook of clues (tap a clue to read what it means).
local Viewer = require(script.Parent.Viewer)

local Board = {}

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
	-- Cork board
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

	local lh, ls = UI.paper(cork, { pos = UDim2.fromOffset(14, 10), size = UDim2.fromOffset(176, 54), rot = -1.5, color = C.paperWhite, age = false })
	UI.text({ Text = "CASE No. " .. case.number, FontFace = F.type, TextSize = 12, TextColor3 = C.inkFaint, Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 16), Parent = ls })
	UI.text({ Text = UI.upper(case.title), FontFace = F.type, TextSize = 17, TextWrapped = false, Position = UDim2.fromOffset(10, 25), Size = UDim2.new(1, -20, 0, 22), Parent = ls })
	UI.tape(lh, UDim2.fromOffset(4, 4), -40, 34)

	local qh, qs = UI.indexCard(cork, { pos = UDim2.fromOffset(186, 228), size = UDim2.fromOffset(186, 70), rot = -1.5, lineTop = 26, lineGap = 20 })
	local ql = UI.text({ Text = case.question, FontFace = F.handBold, TextSize = 18, TextColor3 = C.red, Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 1, -10),
		TextYAlignment = Enum.TextYAlignment.Center, TextXAlignment = Enum.TextXAlignment.Center, TextScaled = true, Parent = qs })
	UI.new("UITextSizeConstraint", { MaxTextSize = 18, MinTextSize = 11, Parent = ql })
	UI.pin(qh, UDim2.new(0.5, 0, 0, 6), C.ink)

	--------------------------------------------------------------------
	-- Evidence cards
	--------------------------------------------------------------------
	local cardRefs = {}
	local function miniLines(parent, x, y, w, n, gap)
		local r = Random.new(n * 7 + w)
		for i = 1, n do
			UI.frame({ BackgroundColor3 = C.inkFaint, BackgroundTransparency = 0.45, Position = UDim2.fromOffset(x, y + (i - 1) * gap),
				Size = UDim2.fromOffset(math.floor(w * r:NextNumber(0.55, 1)), 2), Parent = parent })
		end
	end
	local function plainText(parts)
		local t = {}
		for _, p in parts do table.insert(t, type(p) == "table" and p[1] or p) end
		return table.concat(t)
	end

	local function buildCard(ev)
		local b = ev.board
		local colors = { news = C.paperWhite, doc = ev.paperColor or C.paperWhite, chat = C.screen, table = C.paper, note = C.card, photo = C.paperWhite }
		local holder, sheet = UI.paper(cork, { name = ev.id, pos = UDim2.fromOffset(b.x, b.y), size = UDim2.fromOffset(b.w, b.h), rot = b.rot,
			color = colors[ev.kind] or C.paper, age = ev.kind ~= "chat" })
		local w, h = b.w, b.h - 20
		if ev.kind == "news" then
			UI.text({ Text = "VECUPE NEWS", FontFace = F.type, TextSize = 9, TextColor3 = C.inkSoft, Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(w - 16, 12), Parent = sheet })
			UI.text({ Text = ev.headline, FontFace = F.serifBold, TextSize = 12, Position = UDim2.fromOffset(8, 18), Size = UDim2.fromOffset(w - 16, 30), Parent = sheet })
			miniLines(sheet, 8, 54, w - 16, 4, 8)
		elseif ev.kind == "doc" then
			local dt = UI.text({ Text = ev.docTitle, FontFace = F.type, TextSize = 8, TextColor3 = C.inkSoft, Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(w - 16, 22), TextScaled = true, Parent = sheet })
			UI.new("UITextSizeConstraint", { MaxTextSize = 9, MinTextSize = 6, Parent = dt })
			miniLines(sheet, 8, 34, w - 16, math.floor((h - 34) / 8), 8)
		elseif ev.kind == "chat" then
			local bar = UI.frame({ BackgroundColor3 = Color3.fromRGB(32, 35, 41), Size = UDim2.new(1, 0, 0, 16), Parent = sheet })
			local ct = UI.text({ Text = ev.chatTitle, FontFace = F.sansBold, TextSize = 10, TextScaled = true, TextWrapped = false, TextColor3 = Color3.new(1, 1, 1), Position = UDim2.fromOffset(6, 2), Size = UDim2.new(1, -26, 1, -4), Parent = bar })
		UI.new("UITextSizeConstraint", { MaxTextSize = 10, MinTextSize = 7, Parent = ct })
			local y = 22
			for _, m in ev.messages do
				if y > h - 22 then break end
				local bub = UI.frame({ BackgroundColor3 = C.bubble, Position = UDim2.fromOffset(6, y), Size = UDim2.fromOffset(w - 20, 22), Parent = sheet })
				UI.corner(4).Parent = bub
				UI.text({ Text = plainText(m.parts), FontFace = F.sans, TextSize = 9, Position = UDim2.fromOffset(4, 1), Size = UDim2.new(1, -8, 1, -2), TextTruncate = Enum.TextTruncate.AtEnd, Parent = bub })
				y += 27
			end
		elseif ev.kind == "table" then
			for i = 0, 4 do
				UI.frame({ BackgroundColor3 = C.ink, BackgroundTransparency = i == 1 and 0.2 or 0.65, Position = UDim2.fromOffset(8, 10 + i * 12), Size = UDim2.fromOffset(w - 16, 1), Parent = sheet })
			end
			UI.text({ Text = "0.6  0.5  0.7", FontFace = F.mono, TextSize = 9, TextColor3 = C.inkSoft, Position = UDim2.fromOffset(w * 0.45, 36), Size = UDim2.fromOffset(w * 0.55, 12), Parent = sheet })
		elseif ev.kind == "photo" then
			for i = 0, 1 do
				local p = UI.frame({ BackgroundColor3 = i == 0 and Color3.fromRGB(26, 30, 40) or Color3.fromRGB(150, 160, 150), Position = UDim2.fromOffset(6 + i * (w / 2 - 2), 6),
					Size = UDim2.fromOffset(w / 2 - 10, h - 12), Parent = sheet })
				UI.stroke(C.paperWhite, 2).Parent = p
			end
		elseif ev.kind == "note" then
			for i = 0, 3 do
				UI.frame({ BackgroundColor3 = C.cardLine, BackgroundTransparency = 0.4, Position = UDim2.fromOffset(0, 14 + i * 14), Size = UDim2.new(1, 0, 0, 1), Parent = sheet })
			end
			UI.text({ Text = "4.6 mg/L", FontFace = F.mono, TextSize = 11, Position = UDim2.fromOffset(8, 22), Size = UDim2.fromOffset(w - 16, 14), Parent = sheet })
			UI.frame({ BackgroundColor3 = C.redBright, Position = UDim2.fromOffset(6, 29), Size = UDim2.fromOffset(w - 30, 2), Rotation = -2, Parent = sheet })
			UI.text({ Text = "do not include", FontFace = F.handBold, TextSize = 12, TextColor3 = C.redBright, Position = UDim2.fromOffset(20, 48), Size = UDim2.fromOffset(w - 24, 16), Rotation = -4, Parent = sheet })
		end

		local lab = UI.frame({ BackgroundColor3 = C.paperWhite, Position = UDim2.new(0, 0, 1, -20), Size = UDim2.new(1, 0, 0, 20), Parent = sheet })
		UI.frame({ BackgroundColor3 = C.ink, BackgroundTransparency = 0.8, Size = UDim2.new(1, 0, 0, 1), Parent = lab })
		UI.text({ Text = ev.id .. " · " .. UI.upper(ev.short or ev.label), FontFace = F.type, TextSize = 11, Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -36, 1, 0),
			TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Parent = lab })
		local prog = UI.text({ FontFace = F.handBold, TextSize = 14, TextColor3 = C.red, Position = UDim2.new(1, -32, 0, 0), Size = UDim2.fromOffset(28, 20),
			TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Center, Parent = lab })
		UI.pin(holder, UDim2.new(0.5, 0, 0, 6))

		local hit = UI.hit({ Name = "Open", ZIndex = 25, Parent = holder })
		hit.MouseEnter:Connect(function() UI.tween(holder, 0.12, { Rotation = b.rot * 0.4, Position = UDim2.fromOffset(b.x, b.y - 3) }) end)
		hit.MouseLeave:Connect(function() UI.tween(holder, 0.12, { Rotation = b.rot, Position = UDim2.fromOffset(b.x, b.y) }) end)
		hit.Activated:Connect(function() Viewer.open(app, ev) end)

		local center = Vector2.new(b.x + b.w / 2, b.y + b.h / 2)
		nodes[ev.id] = rotatePoint(center, Vector2.new(0, 6 - b.h / 2), b.rot)
		cardRefs[ev.id] = { prog = prog, ev = ev }
	end

	local function buildPlaceholder(ev)
		local b = ev.board
		local ph = UI.frame({ BackgroundColor3 = C.corkDark, BackgroundTransparency = 0.6, Position = UDim2.fromOffset(b.x, b.y), Size = UDim2.fromOffset(b.w, b.h),
			Rotation = b.rot, Parent = cork })
		UI.stroke(C.paperShade, 1.5, 0.5).Parent = ph
		UI.text({ Text = "?", FontFace = F.type, TextSize = 34, TextColor3 = C.paperShade, TextTransparency = 0.3, TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = ph })
	end

	for _, ev in case.evidence do
		if state:isVisible(ev) then buildCard(ev) else buildPlaceholder(ev) end
	end

	local function refreshCards()
		for _, ref in cardRefs do
			local n, t = Viewer.progress(state, ref.ev)
			ref.prog.Text = n .. "/" .. t
			ref.prog.TextColor3 = n == t and C.green or C.red
		end
	end

	--------------------------------------------------------------------
	-- People (polaroids)
	--------------------------------------------------------------------
	local rots = { -3, 2, -2, 3, -1 }
	for i, wid in case.witnessOrder do
		local ch = case.characters[wid]
		local x, y, w, h = 186 + (i - 1) * 94, 330, 86, 108
		local met = state.visited[wid]
		local holder, _, photo = UI.polaroid(cork, { name = wid, pos = UDim2.fromOffset(x, y), size = UDim2.fromOffset(w, h), rot = rots[i],
			look = ch.look, small = ch.small, caption = met and ch.name or "?", captionSize = 14 })
		UI.pin(holder, UDim2.new(0.5, 0, 0, 5))
		if not met then
			UI.frame({ BackgroundColor3 = C.black, BackgroundTransparency = 0.5, Size = UDim2.fromScale(1, 1), ZIndex = photo.ZIndex, Parent = photo })
		end
		local center = Vector2.new(x + w / 2, y + h / 2)
		nodes[wid] = rotatePoint(center, Vector2.new(0, 5 - h / 2), rots[i])
	end

	--------------------------------------------------------------------
	-- Red threads
	--------------------------------------------------------------------
	local threadLayer = UI.frame({ Name = "Threads", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = cork })
	local drawn = {}
	local function drawThreads()
		for _, id in state.foundOrder do
			local link = case.clues[id] and case.clues[id].link
			if link then
				local key = link[1] .. ">" .. link[2]
				local a, b = nodes[link[1]], nodes[link[2]]
				if not drawn[key] and a and b then
					drawn[key] = true
					local isNew = not state.threadSeen[key]
					state.threadSeen[key] = true
					UI.thread(threadLayer, a, b, { animate = isNew, z = 5 })
					for _, p in { a, b } do UI.pin(threadLayer, UDim2.fromOffset(p.X, p.Y), C.red, 6) end
				end
			end
		end
	end

	--------------------------------------------------------------------
	-- Notebook
	--------------------------------------------------------------------
	local _, nb = UI.paper(root, { pos = UDim2.fromOffset(712, 18), size = UDim2.fromOffset(232, 340), color = C.card, age = false })
	for i = 0, 9 do
		local ring = UI.frame({ BackgroundColor3 = C.desk, Position = UDim2.fromOffset(14 + i * 21, -6), Size = UDim2.fromOffset(9, 14), Parent = nb })
		UI.corner(4).Parent = ring
		UI.stroke(Color3.fromRGB(150, 150, 150), 1.5).Parent = ring
	end
	UI.frame({ BackgroundColor3 = C.cardMargin, BackgroundTransparency = 0.4, Position = UDim2.fromOffset(24, 0), Size = UDim2.new(0, 1, 1, 0), Parent = nb })
	local nbTitle = UI.text({ FontFace = F.type, TextSize = 16, Position = UDim2.fromOffset(32, 16), Size = UDim2.new(1, -40, 0, 22), Parent = nb })
	local list = UI.new("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(30, 46), Size = UDim2.new(1, -36, 1, -52),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ScrollBarImageColor3 = C.inkFaint,
		ScrollingDirection = Enum.ScrollingDirection.Y, Parent = nb,
	})
	UI.list(nil, 2).Parent = list

	local function openClue(id)
		local clue = case.clues[id]
		app:openModal(function(m, close)
			local h, s = UI.indexCard(m, { pos = UDim2.fromOffset(480, 270), anchor = Vector2.new(0.5, 0.5), size = UDim2.fromOffset(560, clue.learn and 260 or 190), rot = -0.6, lineTop = 50, lineGap = 26 })
			UI.pin(h, UDim2.new(0.5, 0, 0, 8))
			UI.text({ Text = clue.title, FontFace = F.type, TextSize = 19, TextColor3 = clue.kind == "fact" and C.blue or C.red, Position = UDim2.fromOffset(22, 16), Size = UDim2.new(1, -44, 0, 26), Parent = s })
			UI.text({ Text = clue.note, FontFace = F.hand, TextSize = 18, TextColor3 = C.blue, Position = UDim2.fromOffset(22, 52), Size = UDim2.new(1, -44, 0, 56), Parent = s })
			local y = 112
			if clue.learn then
				local l = UI.text({ Text = clue.learn, FontFace = F.serif, TextSize = 14, Position = UDim2.fromOffset(22, y), Size = UDim2.new(1, -44, 0, 70), TextScaled = true, Parent = s })
				UI.new("UITextSizeConstraint", { MaxTextSize = 14, MinTextSize = 10, Parent = l })
				y += 76
			end
			UI.button(s, "Close", { style = "paper", pos = UDim2.new(1, -20, 1, -14), anchor = Vector2.new(1, 1), size = UDim2.fromOffset(110, 34), textSize = 13, onClick = close })
		end, { closeOnDim = true })
	end

	local function refreshNotes()
		for _, ch in list:GetChildren() do if ch:IsA("GuiObject") then ch:Destroy() end end
		local n = #state.foundOrder
		local _, total = state:countFound()
		nbTitle.Text = ("NOTEBOOK (%d/%d)"):format(n, total)
		if n == 0 then
			UI.text({ Text = "Empty for now.", FontFace = F.hand, TextSize = 17, TextColor3 = C.inkFaint, Size = UDim2.new(1, 0, 0, 24), Parent = list })
			return
		end
		for i = n, 1, -1 do
			local id = state.foundOrder[i]
			local clue = case.clues[id]
			local e = UI.new("TextButton", {
				Text = clue.title, FontFace = F.hand, TextSize = 15,
				TextColor3 = clue.kind == "fact" and C.blue or (clue.kind == "rumour" and C.inkFaint or C.red),
				BackgroundTransparency = 1, AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.new(1, -4, 0, 22), LayoutOrder = n - i, Parent = list,
			})
			e.Activated:Connect(function() openClue(id) end)
		end
	end

	UI.text({ Text = "Tap a card to examine it. Tap a note in your notebook to read what it means. Red threads connect clues that belong together.",
		FontFace = F.hand, TextSize = 15, TextColor3 = C.paperShade, Position = UDim2.fromOffset(712, 372), Size = UDim2.fromOffset(232, 90), Parent = root })
	UI.button(root, "← Back to the map", { pos = UDim2.fromOffset(712, 474), size = UDim2.fromOffset(232, 48), textSize = 16, onClick = function() app:go("Map") end })

	local function refreshAll()
		refreshCards()
		refreshNotes()
		drawThreads()
	end
	refreshAll()
	table.insert(conns, state.changed.Event:Connect(refreshAll))

	return function()
		for _, c in conns do c:Disconnect() end
	end
end

return Board
