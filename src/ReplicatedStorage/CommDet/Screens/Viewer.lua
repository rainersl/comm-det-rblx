-- evidence viewer
local Viewer = {}

function Viewer.clueIds(ev)
	local set, list = {}, {}
	local function scan(parts)
		if type(parts) ~= "table" then return end
		for _, p in parts do
			if type(p) == "table" then
				if p.clue and not set[p.clue] then
					set[p.clue] = true
					table.insert(list, p.clue)
				end
			end
		end
	end
	for _, para in ev.paragraphs or {} do scan(para) end
	for _, m in ev.messages or {} do
		scan(m.parts)
		scan({ m.time })
	end
	for _, fl in ev.floors or {} do scan(fl.rooms) end
	for _, r in ev.rows or {} do scan(r) end
	for _, l in ev.lines or {} do scan(l) end
	if ev.scribble then scan({ ev.scribble }) end
	return list
end

function Viewer.progress(state, ev)
	local ids = Viewer.clueIds(ev)
	local n = 0
	for _, id in ids do
		if state:has(id) then n += 1 end
	end
	return n, #ids
end

function Viewer.open(app, ev)
	local UI = app.UI
	local C, F = UI.C, UI.F
	local case, state = app.case, app.state

	app:openModal(function(root, close)
		local side = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(624, 30), Size = UDim2.fromOffset(310, 480), Parent = root })

		local tagH, tag = UI.paper(side, { pos = UDim2.fromOffset(0, 0), size = UDim2.fromOffset(300, 64), rot = 1, color = C.paperWhite, age = false })
		UI.text({ Text = ev.id .. " · " .. UI.upper(ev.label), FontFace = F.type, TextSize = 18, Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 22), Parent = tag })
		local prog = UI.text({ FontFace = F.hand, TextSize = 17, TextColor3 = C.red, Position = UDim2.fromOffset(14, 34), Size = UDim2.new(1, -28, 0, 22), Parent = tag })
		local function updateProg()
			local n, t = Viewer.progress(state, ev)
			prog.Text = ("atrasti pavedieni: %d no %d"):format(n, t)
		end
		updateProg()
		UI.tape(tagH, UDim2.new(0, 10, 0, 4), -30, 40)

		UI.text({
			Text = state.tutorial.firstClue and "Pieskaries frāzēm, kas šķiet aizdomīgas."
				or "Pieskaries vārdiem un frāzēm, kas šķiet neskaidras, nepilnīgas vai divdomīgas.\nUzmanies: ne viss dīvainais ir kļūda.",
			FontFace = F.hand,
			TextSize = 18,
			TextColor3 = C.paper,
			Position = UDim2.fromOffset(4, 82),
			Size = UDim2.fromOffset(296, 110),
			Parent = side,
		})

		local noteSlot = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 196), Size = UDim2.fromOffset(300, 200), Parent = side })

		local function showNote(title, body, color, badge)
			noteSlot:ClearAllChildren()
			local h, s = UI.indexCard(noteSlot, { pos = UDim2.fromOffset(0, 0), size = UDim2.fromOffset(300, 176), rot = -1.5, lineTop = 44, lineGap = 24 })
			UI.text({ Text = title, FontFace = F.type, TextSize = 17, TextColor3 = color, Position = UDim2.fromOffset(14, 12), Size = UDim2.new(1, -28, 0, 24), TextTruncate = Enum.TextTruncate.AtEnd, Parent = s })
			local bl = UI.text({ Text = body, FontFace = F.hand, TextSize = 18, TextColor3 = C.blue, Position = UDim2.fromOffset(14, 42), Size = UDim2.new(1, -28, 1, -64), LineHeight = 1.12, TextScaled = true, Parent = s })
			UI.new("UITextSizeConstraint", { MaxTextSize = 18, MinTextSize = 12, Parent = bl })
			if badge then
				UI.stamp(h, badge, { pos = UDim2.new(1, -40, 1, -14), rot = -10, size = 13, color = color, z = 40 })
			end
			UI.pin(h, UDim2.new(0.5, 0, 0, 8))
		end

		UI.button(side, "Atpakaļ pie dēļa", {
			pos = UDim2.fromOffset(0, 430),
			size = UDim2.fromOffset(300, 46),
			onClick = close,
		})


		local function onPart(part, btn)
			if not part or (not part.clue and not part.decoy) then
				UI.shake(btn, 2)
				return
			end
			if part.clue then
				local clue = case.clues[part.clue]
				local isNew = state:find(part.clue)
				UI.marker(btn, C.redBright, true)
				local badge = isNew and (clue.kind == "fact" and "Fakts" or "Pavediens") or nil
				showNote(clue.title, clue.note, clue.kind == "fact" and C.blue or C.red, badge)
				if isNew and not state.tutorial.firstClue then
					state.tutorial.firstClue = true
					app:toast("Pavediens pierakstīts piezīmēs. Meklē tālāk!")
				end
				updateProg()
			elseif part.decoy then
				local d = case.decoys[part.decoy]
				local isNew = state:markDecoy(part.decoy)
				UI.pencilMark(btn)
				showNote("Te viss kārtībā", d and d.note or "", C.inkSoft, isNew and "Garām" or nil)
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

		local doc = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 24), Size = UDim2.fromOffset(570, 492), Parent = root })

		if ev.kind == "email" then
			local h, s = UI.paper(doc, { size = UDim2.fromScale(1, 1), rot = -0.6, color = C.paperWhite })
			UI.text({ Text = "E-PASTS · IZDRUKA", FontFace = F.mono, TextSize = 11, TextColor3 = C.inkFaint, Position = UDim2.fromOffset(24, 14), Size = UDim2.fromOffset(300, 16), Parent = s })
			local y = 36
			for _, row in ev.header do
				UI.text({ Text = row[1], FontFace = F.mono, TextSize = 14, TextColor3 = C.inkFaint, Position = UDim2.fromOffset(24, y), Size = UDim2.fromOffset(80, 20), Parent = s })
				UI.text({ Text = row[2], FontFace = F.mono, TextSize = 14, Position = UDim2.fromOffset(100, y), Size = UDim2.new(1, -124, 0, 20), TextTruncate = Enum.TextTruncate.AtEnd, Parent = s })
				y += 21
			end
			UI.frame({ BackgroundColor3 = C.inkFaint, BackgroundTransparency = 0.4, Position = UDim2.fromOffset(24, y + 8), Size = UDim2.new(1, -48, 0, 1), Parent = s })
			local body = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(24, y + 20), Size = UDim2.new(1, -48, 1, -(y + 30)), Parent = s })
			UI.list(nil, 9).Parent = body
			for i, para in ev.paragraphs do
				flow(body, para, { size = 16, order = i, lineHeight = 23 })
			end

		elseif ev.kind == "chat" then
			local h, s = UI.paper(doc, { size = UDim2.fromScale(1, 1), rot = 0.5, color = C.screen, age = false })
			local bar = UI.frame({ BackgroundColor3 = Color3.fromRGB(32, 35, 41), Size = UDim2.new(1, 0, 0, 56), Parent = s })
			UI.text({ Text = ev.chatTitle, FontFace = F.sansBold, TextSize = 19, TextColor3 = Color3.new(1, 1, 1), Position = UDim2.fromOffset(20, 8), Size = UDim2.new(1, -40, 0, 22), Parent = bar })
			UI.text({ Text = ev.chatSub, FontFace = F.sans, TextSize = 13, TextColor3 = Color3.fromRGB(160, 166, 176), Position = UDim2.fromOffset(20, 31), Size = UDim2.new(1, -40, 0, 18), Parent = bar })
			local day = UI.text({ Text = ev.dayLabel, FontFace = F.sans, TextSize = 12, TextColor3 = C.inkSoft, BackgroundColor3 = Color3.fromRGB(214, 216, 222), BackgroundTransparency = 0,
				TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70),
				Size = UDim2.fromOffset(190, 22), Parent = s })
			UI.corner(11).Parent = day
			local list = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 106), Size = UDim2.new(1, -40, 1, -130), Parent = s })
			UI.list(nil, 12).Parent = list
			for i, m in ev.messages do
				local bubble = UI.frame({ BackgroundColor3 = C.bubble, Size = UDim2.fromOffset(440, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = i, Parent = list })
				UI.corner(12).Parent = bubble
				UI.stroke(Color3.fromRGB(205, 208, 214), 1).Parent = bubble
				UI.pad(10, 14, 8, 14).Parent = bubble
				UI.list(nil, 2).Parent = bubble
				UI.text({ Text = m.from, FontFace = F.sansBold, TextSize = 14, TextColor3 = C.blue, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1, Parent = bubble })
				flow(bubble, m.parts, { size = 20, font = F.sans, order = 2, lineHeight = 28, spaceWidth = 5 })
				local tr = UI.frame({ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 3, Parent = bubble })
				local tpart = m.time
				local isTap = tpart.clue ~= nil
				tapButton(tr, isTap and tpart or nil, {
					Name = "Time",
					Text = tpart[1],
					FontFace = F.mono,
					TextSize = 13,
					TextColor3 = C.inkFaint,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.fromOffset(46, 18),
					TextXAlignment = Enum.TextXAlignment.Right,
				})
			end
			if ev.footer then
				UI.text({ Text = ev.footer, FontFace = F.sans, TextSize = 13, TextColor3 = C.inkFaint, TextXAlignment = Enum.TextXAlignment.Right,
					Position = UDim2.new(0, 20, 1, -30), Size = UDim2.new(1, -40, 0, 18), Parent = s })
			end

		elseif ev.kind == "plan" then
			local h, s = UI.paper(doc, { size = UDim2.fromScale(1, 1), rot = -0.8, color = C.blueprint, age = false })
			for i = 1, 18 do
				UI.frame({ BackgroundColor3 = C.blueprintLine, BackgroundTransparency = 0.9, Position = UDim2.fromOffset(i * 32, 0), Size = UDim2.new(0, 1, 1, 0), Parent = s })
			end
			for i = 1, 15 do
				UI.frame({ BackgroundColor3 = C.blueprintLine, BackgroundTransparency = 0.9, Position = UDim2.fromOffset(0, i * 32), Size = UDim2.new(1, 0, 0, 1), Parent = s })
			end
			UI.text({ Text = UI.upper(ev.title), FontFace = F.type, TextSize = 18, TextColor3 = C.blueprintLine, Position = UDim2.fromOffset(24, 18), Size = UDim2.new(1, -48, 0, 24), Parent = s })
			for fi, fl in ev.floors do
				local box = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(24 + (fi - 1) * 268, 82), Size = UDim2.fromOffset(250, 370), Parent = s })
				UI.stroke(C.blueprintLine, 2).Parent = box
				UI.text({ Text = fl.name, FontFace = F.type, TextSize = 14, TextColor3 = C.blueprintLine, Position = UDim2.fromOffset(0, -24), Size = UDim2.new(1, 0, 0, 20), Parent = box })
				for _, r in fl.rooms do
					local isTap = r.clue or r.decoy
					local b = tapButton(box, isTap and r or nil, {
						Name = "Room",
						Text = r[1],
						FontFace = F.type,
						TextSize = 15,
						TextWrapped = true,
						TextColor3 = Color3.new(1, 1, 1),
						BackgroundColor3 = C.blueprintLine,
						BackgroundTransparency = 0.92,
						Position = UDim2.fromScale(r[2], r[3]),
						Size = UDim2.fromScale(r[4], r[5]),
					})
					UI.stroke(C.blueprintLine, 1.2, 0.2).Parent = b
					UI.pad(6).Parent = b
				end
			end

		elseif ev.kind == "table" then
			local h, s = UI.paper(doc, { size = UDim2.fromScale(1, 1), rot = 0.7, color = C.paper })
			UI.text({ Text = UI.upper(ev.title), FontFace = F.type, TextSize = 20, Position = UDim2.fromOffset(30, 26), Size = UDim2.new(1, -60, 0, 26), Parent = s })
			local tbl = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 80), Size = UDim2.new(1, -60, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = s })
			UI.list().Parent = tbl
			local function row(cells, order, header)
				local r = UI.frame({ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 52), LayoutOrder = order, Parent = tbl })
				UI.frame({ BackgroundColor3 = C.ink, BackgroundTransparency = header and 0 or 0.7, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, header and 2 or 1), Parent = r })
				for ci, cell in cells do
					local part = type(cell) == "table" and cell or nil
					local text = part and part[1] or cell
					local x = ci == 1 and 0 or 0.45
					local w = ci == 1 and 0.45 or 0.55
					if header or not part then
						UI.text({ Text = text, FontFace = header and F.type or F.serif, TextSize = header and 15 or 18, TextColor3 = header and C.inkSoft or C.ink,
							TextYAlignment = Enum.TextYAlignment.Center, Position = UDim2.fromScale(x, 0), Size = UDim2.fromScale(w, 1), Parent = r })
					else
						tapButton(r, part, { Text = text, FontFace = F.mono, TextSize = 20, TextColor3 = C.ink, BackgroundTransparency = 1,
							TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(x, 0), Size = UDim2.new(0, 150, 1, 0) })
					end
				end
			end
			row(ev.columns, 0, true)
			for i, cells in ev.rows do
				row(cells, i, false)
			end

		elseif ev.kind == "note" then
			local h, s = UI.indexCard(doc, { pos = UDim2.fromOffset(10, 30), size = UDim2.fromOffset(550, 420), rot = -2, lineTop = 70, lineGap = 40 })
			UI.text({ Text = "Markusa piezīmes", FontFace = F.hand, TextSize = 16, TextColor3 = C.inkFaint, Position = UDim2.fromOffset(30, 22), Size = UDim2.fromOffset(300, 24), Parent = s })
			local body = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(36, 66), Size = UDim2.new(1, -72, 0, 200), Parent = s })
			UI.list().Parent = body
			for i, l in ev.lines do
				flow(body, l, { size = 24, font = F.hand, color = C.blue, order = i, lineHeight = 40, spaceWidth = 6 })
			end
			for i = 1, #ev.lines do
				UI.frame({ BackgroundColor3 = C.ink, BackgroundTransparency = 0.25, Position = UDim2.fromOffset(30, 66 + (i - 1) * 40 + 22),
					Size = UDim2.new(1, -90, 0, 2), Rotation = (i % 2 == 0) and 1 or -1, ZIndex = 3, Parent = s })
			end
			local sc = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(150, 250), Size = UDim2.fromOffset(360, 60), Rotation = -5, Parent = s })
			flow(sc, { ev.scribble }, { size = 30, font = F.handBold, color = C.ink, lineHeight = 50 })
		end

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
