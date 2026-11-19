-- Interview: polaroid on the left, transcript on the right, questions below.
-- A claim can be disproved by presenting the right clue from the notebook.
local Interview = {}

function Interview.build(app, root, args)
	local UI = app.UI
	local C, F = UI.C, UI.F
	local case, state = app.case, app.state
	local wid = args.witness
	local ch = case.characters[wid]
	local data = case.witnesses[wid]
	state.visited[wid] = true
	state.asked[wid] = state.asked[wid] or {}
	state.transcripts[wid] = state.transcripts[wid] or {}
	local transcript = state.transcripts[wid]

	local pol = UI.polaroid(root, { pos = UDim2.fromOffset(34, 40), size = UDim2.fromOffset(210, 256), rot = -3, look = ch.look, small = ch.small, caption = ch.full, captionSize = 18 })
	UI.tape(pol, UDim2.new(0.5, 0, 0, 0), -2, 80)
	local _, info = UI.paper(root, { pos = UDim2.fromOffset(34, 316), size = UDim2.fromOffset(210, 80), rot = 1, color = C.paperWhite, age = false })
	UI.text({ Text = UI.upper(ch.role), FontFace = F.type, TextSize = 13, Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 1, -20), Parent = info })

	UI.button(root, "← Back to the map", { style = "paper", pos = UDim2.fromOffset(34, 470), size = UDim2.fromOffset(210, 42),
		onClick = function() app:go("Map") end })

	-- Transcript
	local _, paper = UI.paper(root, { pos = UDim2.fromOffset(276, 24), size = UDim2.fromOffset(660, 330), rot = 0, color = C.paper })
	UI.text({ Text = "TRANSCRIPT · WITNESS: " .. UI.upper(ch.full), FontFace = F.type, TextSize = 16, Position = UDim2.fromOffset(24, 16), Size = UDim2.new(1, -48, 0, 20), Parent = paper })
	UI.frame({ BackgroundColor3 = C.ink, Position = UDim2.fromOffset(24, 40), Size = UDim2.new(1, -48, 0, 1), Parent = paper })
	local scroll = UI.new("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(24, 48), Size = UDim2.new(1, -36, 1, -60),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5, ScrollBarImageColor3 = C.inkFaint,
		ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 3, Parent = paper,
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

	local function addLine(who, text, animate, record)
		order += 1
		if record ~= false then table.insert(transcript, { who = who, text = text }) end
		local row = UI.frame({ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, Parent = scroll })
		local label
		if who == "narr" then
			label = UI.text({ Text = text, FontFace = F.serifItalic, TextSize = 15, TextColor3 = C.inkFaint, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = row })
		else
			local name = who == "you" and "DETECTIVE" or UI.upper(ch.name)
			UI.text({ Text = name, FontFace = F.type, TextSize = 12, TextColor3 = who == "you" and C.blue or C.red, Size = UDim2.fromOffset(120, 22), Parent = row })
			label = UI.text({ Text = text, FontFace = who == "you" and F.serifItalic or F.serif, TextSize = 16, TextColor3 = who == "you" and C.inkSoft or C.ink,
				Position = UDim2.fromOffset(122, 0), Size = UDim2.new(1, -122, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LineHeight = 1.1, Parent = row })
		end
		if animate then typing = UI.typewrite(label, 70) end
		scrollDown()
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

	-- Questions
	local actions = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(276, 368), Size = UDim2.fromOffset(660, 150), Parent = root })
	local layout = UI.list(Enum.FillDirection.Horizontal, 10)
	layout.Wraps = true
	layout.Parent = actions

	local busy = false
	local refreshActions

	local function reward(topicOrClaim)
		if topicOrClaim.gives and state:find(topicOrClaim.gives) then
			local clue = case.clues[topicOrClaim.gives]
			app:toast("New clue: " .. clue.title, clue.kind == "fact" and C.blue or C.red)
		end
		if topicOrClaim.reveal and state:reveal(topicOrClaim.reveal) then
			for _, ev in case.evidence do
				if ev.id == topicOrClaim.reveal then
					app:toast("New evidence: " .. ev.label .. ". It's on your case board.", C.red)
				end
			end
		end
	end

	local function presentEvidence(ti, topic)
		local claim = topic.claim
		app:openModal(function(m, close)
			UI.text({ Text = "Which clue disproves this?", FontFace = F.type, TextSize = 22, TextColor3 = C.paper, Position = UDim2.fromOffset(60, 28), Size = UDim2.fromOffset(700, 30), Parent = m })
			UI.text({ Text = "\"" .. claim.text .. "\"", FontFace = F.serifItalic, TextSize = 16, TextColor3 = C.paperShade, Position = UDim2.fromOffset(60, 62), Size = UDim2.fromOffset(840, 40), Parent = m })
			local grid = UI.new("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(50, 110), Size = UDim2.fromOffset(860, 350),
				CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5, Parent = m })
			UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(200, 74), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
			UI.pad(6).Parent = grid
			if #state.foundOrder == 0 then
				UI.text({ Text = "You have no clues yet. Examine the evidence first.", FontFace = F.hand, TextSize = 19, TextColor3 = C.paper, Size = UDim2.fromOffset(600, 40), Parent = grid })
			end
			for i, id in state.foundOrder do
				local clue = case.clues[id]
				local cell = UI.frame({ BackgroundTransparency = 1, LayoutOrder = i, Parent = grid })
				local h, s = UI.indexCard(cell, { size = UDim2.fromOffset(200, 74), rot = (i % 3 - 1) * 1.2, lineTop = 30, lineGap = 20 })
				local t = UI.text({ Text = clue.title, FontFace = F.handBold, TextSize = 16, TextColor3 = clue.kind == "fact" and C.blue or C.red,
					Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 1, -8), TextYAlignment = Enum.TextYAlignment.Center, TextScaled = true, Parent = s })
				UI.new("UITextSizeConstraint", { MaxTextSize = 16, MinTextSize = 11, Parent = t })
				local hit = UI.hit({ ZIndex = 10, Parent = h })
				hit.MouseEnter:Connect(function() UI.tween(h, 0.1, { Rotation = 0, Position = UDim2.fromOffset(0, -3) }) end)
				hit.MouseLeave:Connect(function() UI.tween(h, 0.1, { Rotation = (i % 3 - 1) * 1.2, Position = UDim2.fromOffset(0, 0) }) end)
				hit.Activated:Connect(function()
					close()
					busy = true
					refreshActions()
					addLine("you", "Look at this: " .. clue.title, false)
					if table.find(claim.accepts, id) then
						state.resolved[wid .. ti] = true
						local st = UI.stamp(root, "Contradiction!", { pos = UDim2.fromOffset(600, 190), rot = -9, size = 32, z = 60 })
						task.delay(1.6, function() if st.Parent then st:Destroy() end end)
						playLines(claim.success, function()
							reward(claim)
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
			UI.button(m, "Cancel", { style = "paper", pos = UDim2.fromOffset(50, 476), size = UDim2.fromOffset(150, 42), onClick = close })
		end, { closeOnDim = true, dim = 0.15 })
	end

	local function available(topic)
		if not topic.requires then return true end
		return state:hasAny(topic.requires)
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
					app:toast("That's a claim. If a clue in your notebook disproves it — object!", C.red)
				end
			end)
		else
			playLines(topic.lines, function()
				reward(topic)
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
			if available(topic) then
				n += 1
				local asked = state.asked[wid][ti]
				local claimOpen = topic.claim and asked and not state.resolved[wid .. ti]
				if claimOpen then
					local _, api = UI.button(actions, "Object — present a clue", { style = "ink", order = n, textSize = 14, padY = 9, padX = 14,
						onClick = function() if not busy then presentEvidence(ti, topic) end end })
					api.instance.BackgroundColor3 = C.red
					if busy then api.setEnabled(false) end
				elseif not asked then
					local _, api = UI.button(actions, topic.ask, { style = "tag", order = n, textSize = 15, padY = 9, padX = 18,
						onClick = function() task.spawn(ask, ti, topic) end })
					api.instance.FontFace = F.serif
					if busy then api.setEnabled(false) end
				end
			end
		end
		if #actions:GetChildren() <= 1 then
			UI.text({ Text = "No more questions for now. Some may open up when you find new clues.", FontFace = F.hand, TextSize = 17, TextColor3 = C.paperShade,
				Size = UDim2.fromOffset(600, 30), Parent = actions })
		end
	end

	if #transcript > 0 then
		for _, l in transcript do addLine(l.who, l.text, false, false) end
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
end

return Interview
