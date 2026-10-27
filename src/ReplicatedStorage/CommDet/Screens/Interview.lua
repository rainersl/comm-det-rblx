-- interview
local Interview = {}

function Interview.build(app, root, args)
	local UI = app.UI
	local C, F = UI.C, UI.F
	local case, state = app.case, app.state
	local wid = args.witness
	local ch = case.characters[wid]
	local data = case.witnesses[wid]
	state.asked[wid] = state.asked[wid] or {}
	state.transcripts = state.transcripts or {}
	state.transcripts[wid] = state.transcripts[wid] or {}
	local transcript = state.transcripts[wid]

	local pol = UI.polaroid(root, { pos = UDim2.fromOffset(34, 40), size = UDim2.fromOffset(210, 256), rot = -3, look = ch.look, small = ch.small, caption = ch.full, captionSize = 22 })
	UI.tape(pol, UDim2.new(0.5, 0, 0, 0), -2, 80)
	local infoH, info = UI.paper(root, { pos = UDim2.fromOffset(34, 316), size = UDim2.fromOffset(210, 80), rot = 1, color = C.paperWhite, age = false })
	UI.text({ Text = UI.upper(ch.role), FontFace = F.type, TextSize = 13, Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 1, -20), Parent = info })

	UI.button(root, "← Atpakaļ pie dēļa", {
		style = "paper",
		pos = UDim2.fromOffset(34, 470),
		size = UDim2.fromOffset(210, 42),
		onClick = function() app:go("Board") end,
	})

	local ph, paper = UI.paper(root, { pos = UDim2.fromOffset(276, 24), size = UDim2.fromOffset(660, 330), rot = 0, color = C.paper })
	UI.text({ Text = "PROTOKOLS · LIECINIEKS: " .. UI.upper(ch.full), FontFace = F.type, TextSize = 16, Position = UDim2.fromOffset(24, 16), Size = UDim2.new(1, -48, 0, 20), Parent = paper })
	UI.frame({ BackgroundColor3 = C.ink, Position = UDim2.fromOffset(24, 40), Size = UDim2.new(1, -48, 0, 1), Parent = paper })
	local scroll = UI.new("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(24, 48), Size = UDim2.new(1, -36, 1, -60),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5, ScrollBarImageColor3 = C.inkFaint,
		ScrollingDirection = Enum.ScrollingDirection.Y, Parent = paper,
	})
	UI.list(nil, 8).Parent = scroll
	UI.pad(0, 12, 8, 0).Parent = scroll

	local order = 0
	local typing
	local function scrollDown()
		task.defer(function()
			scroll.CanvasPosition = Vector2.new(0, math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteWindowSize.Y))
		end)
	end

	-- who: "narr" | "you" | "them"
	local function addLine(who, text, animate, record)
		order += 1
		if record ~= false then
			table.insert(transcript, { who = who, text = text })
		end
		local row = UI.frame({ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, Parent = scroll })
		local label
		if who == "narr" then
			label = UI.text({ Text = text, FontFace = F.serifItalic, TextSize = 15, TextColor3 = C.inkFaint, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = row })
		else
			local name = who == "you" and "DETEKTĪVS" or UI.upper(ch.name)
			UI.text({ Text = name, FontFace = F.type, TextSize = 13, TextColor3 = who == "you" and C.blue or C.red, Size = UDim2.fromOffset(110, 22), Parent = row })
			label = UI.text({ Text = text, FontFace = who == "you" and F.serifItalic or F.serif, TextSize = 16, TextColor3 = who == "you" and C.inkSoft or C.ink,
				Position = UDim2.fromOffset(112, 0), Size = UDim2.new(1, -112, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LineHeight = 1.1, Parent = row })
		end
		if animate then
			typing = UI.typewrite(label, 70)
		end
		scrollDown()
		return label
	end

	local function playLines(lines, done)
		task.spawn(function()
			for _, l in lines do
				if type(l) == "table" then
					addLine(l.who == "narr" and "narr" or "them", l.text, true)
				else
					addLine("them", l, true)
				end
				while typing and not typing.done do task.wait() end
				task.wait(0.25)
			end
			if done then done() end
		end)
	end

	local actions = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(276, 368), Size = UDim2.fromOffset(660, 150), Parent = root })
	local actLayout = UI.list(Enum.FillDirection.Horizontal, 10)
	actLayout.Wraps = true
	actLayout.Parent = actions

	local busy = false
	local refreshActions

	local function giveClue(id)
		if id and state:find(id) then
			local clue = case.clues[id]
			app:toast("Jauns pavediens: " .. clue.title, clue.kind == "fact" and C.blue or C.red)
		end
	end

	local function presentEvidence(ti, topic)
		local claim = topic.claim
		app:openModal(function(m, close)
			UI.text({ Text = "Kādu pierādījumu parādīt?", FontFace = F.type, TextSize = 22, TextColor3 = C.paper, Position = UDim2.fromOffset(60, 28), Size = UDim2.fromOffset(700, 30), Parent = m })
			UI.text({ Text = "„" .. claim.text .. "”", FontFace = F.serifItalic, TextSize = 16, TextColor3 = C.paperShade, Position = UDim2.fromOffset(60, 62), Size = UDim2.fromOffset(840, 40), Parent = m })
			local grid = UI.new("ScrollingFrame", {
				BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(50, 110), Size = UDim2.fromOffset(860, 350),
				CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5, Parent = m,
			})
			local gl = UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(200, 74), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
			UI.pad(6).Parent = grid
			if #state.foundOrder == 0 then
				UI.text({ Text = "Tev vēl nav neviena pavediena. Vispirms izpēti pierādījumus.", FontFace = F.hand, TextSize = 19, TextColor3 = C.paper, Size = UDim2.fromOffset(600, 40), Parent = grid })
			end
			for i, id in state.foundOrder do
				local clue = case.clues[id]
				local cell = UI.frame({ BackgroundTransparency = 1, LayoutOrder = i, Parent = grid })
				local h, s = UI.indexCard(cell, { size = UDim2.fromOffset(200, 74), rot = (i % 3 - 1) * 1.2, lineTop = 30, lineGap = 20 })
				UI.text({ Text = clue.title, FontFace = F.handBold, TextSize = 16, TextColor3 = clue.kind == "fact" and C.blue or C.red,
					Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 1, -8), TextYAlignment = Enum.TextYAlignment.Center, Parent = s })
				local hit = UI.hit({ ZIndex = 10, Parent = h })
				hit.MouseEnter:Connect(function() UI.tween(h, 0.1, { Rotation = 0, Position = UDim2.fromOffset(0, -3) }) end)
				hit.MouseLeave:Connect(function() UI.tween(h, 0.1, { Rotation = (i % 3 - 1) * 1.2, Position = UDim2.fromOffset(0, 0) }) end)
				hit.Activated:Connect(function()
					close()
					busy = true
					refreshActions()
					addLine("you", "Paskaties uz šo: " .. clue.title, false)
					-- (teksts atkārtojas protokolā tikai īsi)
					if table.find(claim.accepts, id) then
						state.resolved[wid .. ti] = true
						local st = UI.stamp(root, "Pretruna!", { pos = UDim2.fromOffset(600, 190), rot = -9, size = 34, z = 60 })
						task.delay(1.6, function() if st.Parent then UI.tween(st, 0.3, { TextTransparency = 1 }) st:Destroy() end end)
						playLines(claim.success, function()
							giveClue(claim.gives)
							busy = false
							refreshActions()
						end)
					else
						state.claimFails += 1
						playLines({ claim.fail }, function()
							busy = false
							refreshActions()
						end)
					end
				end)
			end
			UI.button(m, "Atcelt", { style = "paper", pos = UDim2.fromOffset(50, 476), size = UDim2.fromOffset(150, 42), onClick = close })
		end, { closeOnDim = true, dim = 0.15 })
	end

	local function ask(ti, topic)
		if busy then return end
		busy = true
		state.asked[wid][ti] = true
		refreshActions()
		addLine("you", topic.ask, false)
		task.wait(0.2)
		if topic.claim then
			playLines({ topic.claim.text }, function()
				busy = false
				refreshActions()
				if not state.tutorial.claim then
					state.tutorial.claim = true
					app:toast("Tas ir apgalvojums. Ja tev ir pierādījums, kas to apgāž, iebilsti!", C.red)
				end
			end)
		else
			playLines(topic.lines, function()
				giveClue(topic.gives)
				busy = false
				refreshActions()
			end)
		end
	end

	refreshActions = function()
		for _, c in actions:GetChildren() do
			if c:IsA("GuiObject") then c:Destroy() end
		end
		local n = 0
		for ti, topic in data.topics do
			if not topic.requires or state:has(topic.requires) then
				n += 1
				local asked = state.asked[wid][ti]
				local claimOpen = topic.claim and asked and not state.resolved[wid .. ti]
				if claimOpen then
					local _, api = UI.button(actions, "Iebilst — parādīt pierādījumu", {
						style = "ink", order = n, textSize = 14, padY = 9, padX = 14,
						onClick = function()
							if not busy then presentEvidence(ti, topic) end
						end,
					})
					api.instance.BackgroundColor3 = C.red
					if busy then api.setEnabled(false) end
				elseif not asked then
					local _, api = UI.button(actions, topic.ask, {
						style = "tag", order = n, font = F.serif, textSize = 15, padY = 9, padX = 18,
						onClick = function()
							task.spawn(ask, ti, topic)
						end,
					})
					api.instance.FontFace = F.serif
					if busy then api.setEnabled(false) end
				end
			end
		end
		if #actions:GetChildren() <= 1 then
			UI.text({ Text = "Vairāk jautājumu nav. Vari atgriezties pie dēļa.", FontFace = F.hand, TextSize = 18, TextColor3 = C.paperShade, Size = UDim2.fromOffset(400, 30), Parent = actions })
		end
	end

	if #transcript > 0 then
		for _, l in transcript do
			addLine(l.who, l.text, false, false)
		end
		refreshActions()
	else
		busy = true
		refreshActions()
		playLines({ { who = "narr", text = data.intro }, data.opening }, function()
			busy = false
			refreshActions()
		end)
	end

	local skip = UI.hit({ ZIndex = 2, Parent = paper })
	skip.Activated:Connect(function()
		if typing and not typing.done then typing.skip() end
	end)
	scroll.ZIndex = 3
end

return Interview
