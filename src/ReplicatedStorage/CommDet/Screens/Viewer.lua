-- Evidence viewer (modal): a full document with tappable phrases + a note card.
local Viewer = {}

-- All clue ids inside one piece of evidence
function Viewer.clueIds(ev)
	local set, list = {}, {}
	local function scan(parts)
		if type(parts) ~= "table" then return end
		for _, p in parts do
			if type(p) == "table" and p.clue and not set[p.clue] then
				set[p.clue] = true
				table.insert(list, p.clue)
			end
		end
	end
	for _, para in ev.paragraphs or {} do scan(para) end
	for _, m in ev.messages or {} do scan(m.parts); scan({ m.time }) end
	for _, r in ev.rows or {} do scan(r) end
	if ev.footnote then scan(ev.footnote) end
	for _, l in ev.lines or {} do scan(l) end
	if ev.scribble then scan({ ev.scribble }) end
	for _, ph in ev.photos or {} do scan({ ph.caption }) end
	return list
end

function Viewer.progress(state, ev)
	local ids = Viewer.clueIds(ev)
	local n = 0
	for _, id in ids do if state:has(id) then n += 1 end end
	return n, #ids
end

function Viewer.open(app, ev)
	local UI = app.UI
	local C, F = UI.C, UI.F
	local case, state = app.case, app.state

	app:openModal(function(root, close)
		----------------------------------------------------------------
		-- Right column
		----------------------------------------------------------------
		local side = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(624, 30), Size = UDim2.fromOffset(310, 480), Parent = root })
		local tagH, tag = UI.paper(side, { pos = UDim2.fromOffset(0, 0), size = UDim2.fromOffset(300, 64), rot = 1, color = C.paperWhite, age = false })
		UI.text({ Text = ev.id .. " · " .. UI.upper(ev.label), FontFace = F.type, TextSize = 17, Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 22),
			TextTruncate = Enum.TextTruncate.AtEnd, Parent = tag })
		local prog = UI.text({ FontFace = F.hand, TextSize = 17, TextColor3 = C.red, Position = UDim2.fromOffset(14, 34), Size = UDim2.new(1, -28, 0, 22), Parent = tag })
		local function updateProg()
			local n, t = Viewer.progress(state, ev)
			prog.Text = ("clues found here: %d of %d"):format(n, t)
		end
		updateProg()
		UI.tape(tagH, UDim2.new(0, 10, 0, 4), -30, 40)

		UI.text({
			Text = state.tutorial.firstClue and "Tap the phrases that seem suspicious."
				or "Tap words and phrases that seem suspicious: vague promises, missing facts, hidden numbers.\nCareful: not everything odd is a clue.",
			FontFace = F.hand, TextSize = 18, TextColor3 = C.paper, Position = UDim2.fromOffset(4, 82), Size = UDim2.fromOffset(296, 110), Parent = side,
		})

		local noteSlot = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 196), Size = UDim2.fromOffset(300, 220), Parent = side })
		local function showNote(title, body, color, badge)
			noteSlot:ClearAllChildren()
			local h, s = UI.indexCard(noteSlot, { pos = UDim2.fromOffset(0, 0), size = UDim2.fromOffset(300, 200), rot = -1.5, lineTop = 44, lineGap = 24 })
			UI.text({ Text = title, FontFace = F.type, TextSize = 16, TextColor3 = color, Position = UDim2.fromOffset(14, 12), Size = UDim2.new(1, -28, 0, 24),
				TextTruncate = Enum.TextTruncate.AtEnd, Parent = s })
			local bl = UI.text({ Text = body, FontFace = F.hand, TextSize = 18, TextColor3 = C.blue, Position = UDim2.fromOffset(14, 42),
				Size = UDim2.new(1, -28, 1, -64), LineHeight = 1.1, TextScaled = true, Parent = s })
			UI.new("UITextSizeConstraint", { MaxTextSize = 18, MinTextSize = 12, Parent = bl })
			if badge then
				UI.stamp(h, badge, { pos = UDim2.new(1, -46, 1, -40), rot = -10, size = 13, color = color, z = 40 })
			end
			UI.pin(h, UDim2.new(0.5, 0, 0, 8))
		end

		UI.button(side, "Back", { pos = UDim2.fromOffset(0, 430), size = UDim2.fromOffset(300, 46), onClick = close })

		----------------------------------------------------------------
		-- Tapping logic
		----------------------------------------------------------------
		local function onPart(part, btn)
			if not part or (not part.clue and not part.decoy) then
				UI.shake(btn, 2)
				return
			end
			if part.clue then
				local clue = case.clues[part.clue]
				local isNew = state:find(part.clue)
				UI.marker(btn, C.redBright, true)
				local color = clue.kind == "fact" and C.blue or (clue.kind == "rumour" and C.inkSoft or C.red)
				local badge = isNew and (clue.kind == "fact" and "Fact" or (clue.kind == "rumour" and "Rumour" or "Clue")) or nil
				showNote(clue.title, clue.note, color, badge)
				if isNew and not state.tutorial.firstClue then
					state.tutorial.firstClue = true
					app:toast("Clue saved to your notebook. You can use it as evidence later.")
				end
				updateProg()
			else
				local d = case.decoys[part.decoy]
				local isNew = state:markDecoy(part.decoy)
				UI.pencilMark(btn)
				showNote("Nothing wrong here", d and d.note or "", C.inkSoft, isNew and "Miss" or nil)
			end
		end

		local allButtons = {}
		local function flow(parent, parts, o)
			o = o or {}
			o.onPart = onPart
			local box, buttons = UI.flow(parent, parts, o)
			for _, b in buttons do table.insert(allButtons, b) end
			return box
		end
		local function tapButton(parent, part, props)
			local b = UI.new("TextButton", props)
			b.AutoButtonColor = false
			b.BorderSizePixel = 0
			b.Parent = parent
			b.Activated:Connect(function() onPart(part, b) end)
			if part then table.insert(allButtons, { part = part, button = b }) end
			return b
		end

		----------------------------------------------------------------
		-- Document
		----------------------------------------------------------------
		local doc = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 24), Size = UDim2.fromOffset(570, 492), Parent = root })

		if ev.kind == "news" or ev.kind == "doc" then
			local _, s = UI.paper(doc, { size = UDim2.fromScale(1, 1), rot = 0, color = ev.paperColor or C.paperWhite })
			local y = 20
			if ev.kind == "news" then
				UI.text({ Text = ev.masthead, FontFace = F.type, TextSize = 14, TextColor3 = C.inkSoft, Position = UDim2.fromOffset(24, y), Size = UDim2.new(1, -48, 0, 18), Parent = s })
				UI.frame({ BackgroundColor3 = C.ink, Position = UDim2.fromOffset(24, y + 22), Size = UDim2.new(1, -48, 0, 2), Parent = s })
				UI.text({ Text = ev.headline, FontFace = F.serifBold, TextSize = 28, Position = UDim2.fromOffset(24, y + 34), Size = UDim2.new(1, -48, 0, 70), Parent = s })
				y += 112
			else
				UI.text({ Text = ev.docTitle, FontFace = F.type, TextSize = 16, Position = UDim2.fromOffset(24, y), Size = UDim2.new(1, -48, 0, 40), Parent = s })
				y += 44
				for _, row in ev.header or {} do
					UI.text({ Text = row[1], FontFace = F.mono, TextSize = 14, TextColor3 = C.inkFaint, Position = UDim2.fromOffset(24, y), Size = UDim2.fromOffset(80, 20), Parent = s })
					UI.text({ Text = row[2], FontFace = F.mono, TextSize = 14, Position = UDim2.fromOffset(100, y), Size = UDim2.new(1, -124, 0, 20),
						TextTruncate = Enum.TextTruncate.AtEnd, Parent = s })
					y += 21
				end
				UI.frame({ BackgroundColor3 = C.inkFaint, BackgroundTransparency = 0.4, Position = UDim2.fromOffset(24, y + 6), Size = UDim2.new(1, -48, 0, 1), Parent = s })
				y += 16
			end
			local body = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(24, y), Size = UDim2.new(1, -48, 1, -(y + 12)), Parent = s })
			UI.list(nil, 12).Parent = body
			for i, para in ev.paragraphs do
				flow(body, para, { size = 17, order = i, lineHeight = 25 })
			end

		elseif ev.kind == "chat" then
			local _, s = UI.paper(doc, { size = UDim2.fromScale(1, 1), rot = 0.5, color = C.screen, age = false })
			local bar = UI.frame({ BackgroundColor3 = Color3.fromRGB(32, 35, 41), Size = UDim2.new(1, 0, 0, 56), Parent = s })
			UI.text({ Text = ev.chatTitle, FontFace = F.sansBold, TextSize = 19, TextColor3 = Color3.new(1, 1, 1), Position = UDim2.fromOffset(20, 8), Size = UDim2.new(1, -40, 0, 22), Parent = bar })
			UI.text({ Text = ev.chatSub, FontFace = F.sans, TextSize = 13, TextColor3 = Color3.fromRGB(160, 166, 176), Position = UDim2.fromOffset(20, 31), Size = UDim2.new(1, -40, 0, 18), Parent = bar })
			local day = UI.text({ Text = ev.dayLabel, FontFace = F.sans, TextSize = 12, TextColor3 = C.inkSoft, BackgroundColor3 = Color3.fromRGB(214, 216, 222), BackgroundTransparency = 0,
				TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 68),
				Size = UDim2.fromOffset(190, 22), Parent = s })
			UI.corner(11).Parent = day
			local list = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 100), Size = UDim2.new(1, -40, 1, -120), Parent = s })
			UI.list(nil, 10).Parent = list
			for i, m in ev.messages do
				local bubble = UI.frame({ BackgroundColor3 = C.bubble, Size = UDim2.fromOffset(470, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = i, Parent = list })
				UI.corner(12).Parent = bubble
				UI.stroke(Color3.fromRGB(205, 208, 214), 1).Parent = bubble
				UI.pad(8, 14, 6, 14).Parent = bubble
				UI.list(nil, 2).Parent = bubble
				UI.text({ Text = m.from, FontFace = F.sansBold, TextSize = 14, TextColor3 = C.blue, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1, Parent = bubble })
				flow(bubble, m.parts, { size = 18, font = F.sans, order = 2, lineHeight = 25, spaceWidth = 5 })
				local tr = UI.frame({ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 3, Parent = bubble })
				local tpart = m.time
				tapButton(tr, tpart.clue and tpart or nil, {
					Name = "Time", Text = tpart[1], FontFace = F.mono, TextSize = 13, TextColor3 = C.inkFaint, BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(46, 16), TextXAlignment = Enum.TextXAlignment.Right,
				})
			end

		elseif ev.kind == "table" then
			local _, s = UI.paper(doc, { size = UDim2.fromScale(1, 1), rot = 0.7, color = C.paper })
			UI.text({ Text = UI.upper(ev.title), FontFace = F.type, TextSize = 18, Position = UDim2.fromOffset(30, 26), Size = UDim2.new(1, -60, 0, 26), Parent = s })
			local tbl = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 76), Size = UDim2.new(1, -60, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = s })
			UI.list().Parent = tbl
			local function row(cells, order, header)
				local r = UI.frame({ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48), LayoutOrder = order, Parent = tbl })
				UI.frame({ BackgroundColor3 = C.ink, BackgroundTransparency = header and 0 or 0.7, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, header and 2 or 1), Parent = r })
				for ci, cell in cells do
					local part = type(cell) == "table" and cell or nil
					local text = part and part[1] or cell
					local x, w = ci == 1 and 0 or 0.5, 0.5
					if header or not part then
						UI.text({ Text = text, FontFace = header and F.type or F.mono, TextSize = header and 15 or 18, TextColor3 = header and C.inkSoft or C.ink,
							TextYAlignment = Enum.TextYAlignment.Center, Position = UDim2.fromScale(x, 0), Size = UDim2.fromScale(w, 1), Parent = r })
					else
						tapButton(r, part, { Text = text, FontFace = F.mono, TextSize = 18, TextColor3 = C.ink, BackgroundTransparency = 1,
							TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(x, 0), Size = UDim2.new(0, 160, 1, 0) })
					end
				end
			end
			row(ev.columns, 0, true)
			for i, cells in ev.rows do row(cells, i, false) end
			if ev.footnote then
				local fn = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 300), Size = UDim2.new(1, -60, 0, 150), Parent = s })
				flow(fn, ev.footnote, { size = 15, font = F.serifItalic, lineHeight = 24, color = C.inkSoft })
			end

		elseif ev.kind == "photo" then
			local _, s = UI.paper(doc, { size = UDim2.fromScale(1, 1), rot = 0, color = C.wood, age = false })
			for i, ph in ev.photos do
				local pol = UI.frame({ BackgroundColor3 = C.paperWhite, Position = UDim2.fromOffset(24 + (i - 1) * 274, 70), Size = UDim2.fromOffset(250, 320),
					Rotation = i == 1 and -2 or 2, Parent = s })
				local pic = UI.frame({ BackgroundColor3 = i == 1 and Color3.fromRGB(26, 30, 40) or Color3.fromRGB(150, 160, 150), Position = UDim2.fromOffset(12, 12),
					Size = UDim2.fromOffset(226, 226), ClipsDescendants = true, Parent = pol })
				UI.frame({ BackgroundColor3 = i == 1 and Color3.fromRGB(40, 48, 56) or Color3.fromRGB(110, 120, 104), Position = UDim2.new(0, 0, 0.55, 0), Size = UDim2.new(1, 0, 0.45, 0), Parent = pic })
				if ph.plume then
					UI.frame({ BackgroundColor3 = Color3.fromRGB(70, 72, 76), Position = UDim2.new(0, 0, 0.5, -6), Size = UDim2.fromOffset(90, 20), Parent = pic })
					for k = 1, 6 do
						local puff = UI.frame({ BackgroundColor3 = Color3.fromRGB(190, 192, 184), BackgroundTransparency = 0.4 + k * 0.08,
							Position = UDim2.new(0, 80 + k * 18, 0.55, k * 6), Size = UDim2.fromOffset(46 + k * 6, 22), Parent = pic })
						UI.corner(UDim.new(0.5, 0)).Parent = puff
					end
					local moon = UI.frame({ BackgroundColor3 = Color3.fromRGB(230, 228, 200), Position = UDim2.fromOffset(170, 24), Size = UDim2.fromOffset(28, 28), Parent = pic })
					UI.corner(UDim.new(0.5, 0)).Parent = moon
				end
				if ph.fish then
					local r = Random.new(4)
					for _ = 1, 9 do
						local f = UI.frame({ BackgroundColor3 = Color3.fromRGB(214, 214, 200), Position = UDim2.fromOffset(r:NextInteger(10, 190), r:NextInteger(130, 210)),
							Size = UDim2.fromOffset(r:NextInteger(18, 30), 8), Rotation = r:NextInteger(-30, 30), Parent = pic })
						UI.corner(UDim.new(0.5, 0)).Parent = f
					end
				end
				local cap = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 246), Size = UDim2.fromOffset(226, 66), Parent = pol })
				flow(cap, { ph.caption }, { size = 17, font = F.hand, color = C.blue, lineHeight = 24 })
			end

		elseif ev.kind == "note" then
			local _, s = UI.indexCard(doc, { pos = UDim2.fromOffset(10, 30), size = UDim2.fromOffset(550, 420), rot = -1, lineTop = 70, lineGap = 40 })
			UI.text({ Text = ev.heading or "", FontFace = F.type, TextSize = 16, TextColor3 = C.inkSoft, Position = UDim2.fromOffset(30, 22), Size = UDim2.new(1, -60, 0, 24), Parent = s })
			local body = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(36, 66), Size = UDim2.new(1, -72, 0, 200), Parent = s })
			UI.list().Parent = body
			for i, l in ev.lines do
				flow(body, l, { size = 22, font = F.mono, color = C.ink, order = i, lineHeight = 40, spaceWidth = 6 })
			end
			for _, i in ev.strike or {} do
				UI.frame({ BackgroundColor3 = C.redBright, BackgroundTransparency = 0.15, Position = UDim2.fromOffset(30, 66 + (i - 1) * 40 + 20),
					Size = UDim2.new(1, -120, 0, 3), Rotation = -1, ZIndex = 3, Parent = s })
			end
			if ev.scribble then
				local sc = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(170, 250), Size = UDim2.fromOffset(360, 60), Rotation = -5, Parent = s })
				flow(sc, { ev.scribble }, { size = 30, font = F.handBold, color = C.redBright, lineHeight = 50 })
			end
		end

		-- phrases already found are marked
		for _, item in allButtons do
			local p = item.part
			if p.clue and state:has(p.clue) then
				UI.marker(item.button, C.redBright, false)
			elseif p.decoy and state.decoys[p.decoy] then
				UI.pencilMark(item.button)
			end
		end
	end, { dim = 0.12 })
end

return Viewer
