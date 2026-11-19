-- Town hall hearing (finale): object to false statements with clues, keep the room's trust,
-- read your statement to residents, then the council votes.
-- (README: SDG 16.7 participatory decisions, 16.3 fair and evidence-based, 12.8 informing people.)
local Audio = require(script.Parent.Parent.Systems.Audio)

local Hearing = {}

local function qualityTrust(q)
	return ({ clear = 5, vague = -2, panic = -8, accusation = -10, exclusive = -4, wrong = -10 })[q] or 0
end

function Hearing.build(app, root)
	local UI = app.UI
	local C, F = UI.C, UI.F
	local case, state = app.case, app.state
	local H = case.hearing
	local d = state.decisions
	local trust = H.start
	local alive = true

	--------------------------------------------------------------------
	-- Hall
	--------------------------------------------------------------------
	local hall = UI.frame({ BackgroundColor3 = Color3.fromRGB(40, 28, 20), Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(936, 516), Parent = root })
	UI.stroke(C.wood, 4).Parent = hall
	for i = 0, 8 do
		UI.frame({ BackgroundColor3 = Color3.fromRGB(52, 36, 26), Position = UDim2.fromOffset(i * 104, 0), Size = UDim2.new(0, 2, 1, 0), Parent = hall })
	end
	local heads = {}
	for i = 1, 9 do
		local hx = 150 + (i - 1) * 74
		local head = UI.frame({ BackgroundColor3 = C.silhouette, Position = UDim2.fromOffset(hx, 18), Size = UDim2.fromOffset(30, 30), Parent = hall })
		UI.corner(UDim.new(0.5, 0)).Parent = head
		local body = UI.frame({ BackgroundColor3 = C.silhouette, Position = UDim2.fromOffset(hx - 10, 44), Size = UDim2.fromOffset(50, 26), Parent = hall })
		UI.corner(UDim.new(0.4, 0)).Parent = body
		heads[i] = { head = head, body = body }
	end
	UI.frame({ BackgroundColor3 = Color3.fromRGB(96, 64, 40), Position = UDim2.fromOffset(120, 64), Size = UDim2.fromOffset(700, 28), Parent = hall })
	UI.text({ Text = "VECUPE TOWN COUNCIL · PERMIT #114", FontFace = F.type, TextSize = 13, TextColor3 = C.paper, TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center, Position = UDim2.fromOffset(120, 64), Size = UDim2.fromOffset(700, 28), Parent = hall })

	-- speaker
	local speakerSlot = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 118), Size = UDim2.fromOffset(180, 230), Parent = root })
	local function setSpeaker(who)
		speakerSlot:ClearAllChildren()
		local ch = case.characters[who]
		local look = ch and ch.look or { "hood" }
		local name = ch and ch.name or "You"
		UI.polaroid(speakerSlot, { pos = UDim2.fromOffset(4, 4), size = UDim2.fromOffset(170, 208), rot = -3, look = look, caption = name, captionSize = 18 })
	end

	-- statement paper
	local _, paper = UI.paper(root, { pos = UDim2.fromOffset(226, 116), size = UDim2.fromOffset(500, 190), color = C.paper })
	local who = UI.text({ FontFace = F.type, TextSize = 14, TextColor3 = C.red, Position = UDim2.fromOffset(20, 14), Size = UDim2.new(1, -40, 0, 18), Parent = paper })
	local say = UI.text({ FontFace = F.serif, TextSize = 21, Position = UDim2.fromOffset(20, 40), Size = UDim2.new(1, -40, 1, -70), LineHeight = 1.1, TextScaled = true, Parent = paper })
	UI.new("UITextSizeConstraint", { MaxTextSize = 21, MinTextSize = 11, Parent = say })
	local counter = UI.text({ FontFace = F.mono, TextSize = 12, TextColor3 = C.inkFaint, Position = UDim2.new(0, 20, 1, -24), Size = UDim2.new(1, -40, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Right, Parent = paper })

	-- trust meter
	local meter = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(756, 112), Size = UDim2.fromOffset(170, 360), Parent = root })
	UI.text({ Text = "ROOM'S TRUST", FontFace = F.type, TextSize = 14, TextColor3 = C.paper, Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Enum.TextXAlignment.Center, Parent = meter })
	local barBack = UI.frame({ BackgroundColor3 = C.desk, Position = UDim2.fromOffset(60, 26), Size = UDim2.fromOffset(50, 280), Parent = meter })
	UI.stroke(C.paperShade, 2).Parent = barBack
	local fill = UI.frame({ BackgroundColor3 = C.lamp, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, trust / 100), Parent = barBack })
	local need = UI.frame({ BackgroundColor3 = C.redBright, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -12, 1 - H.needed / 100, 0), Size = UDim2.new(1, 24, 0, 3), ZIndex = 3, Parent = barBack })
	UI.text({ Text = "majority", FontFace = F.handBold, TextSize = 13, TextColor3 = C.redBright, Position = UDim2.new(1, 8, 0, -10), Size = UDim2.fromOffset(60, 18), Parent = need })
	local trustNum = UI.text({ Text = tostring(trust), FontFace = F.type, TextSize = 28, TextColor3 = C.paper, Position = UDim2.fromOffset(0, 312), Size = UDim2.new(1, 0, 0, 32),
		TextXAlignment = Enum.TextXAlignment.Center, Parent = meter })

	local function changeTrust(delta)
		trust = math.clamp(trust + delta, 0, 100)
		UI.tween(fill, 0.5, { Size = UDim2.fromScale(1, trust / 100) })
		trustNum.Text = tostring(trust)
		local pop = UI.text({ Text = (delta >= 0 and "+" or "") .. delta, FontFace = F.handBold, TextSize = 30, TextColor3 = delta >= 0 and C.lamp or C.redBright,
			Position = UDim2.fromOffset(116, 140), Size = UDim2.fromOffset(60, 34), Parent = meter })
		UI.tween(pop, 1.2, { Position = UDim2.fromOffset(116, 100), TextTransparency = 1 })
		task.delay(1.3, function() pop:Destroy() end)
	end

	-- controls + feedback
	local controls = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(226, 318), Size = UDim2.fromOffset(500, 50), Parent = root })
	local feedback = UI.text({ FontFace = F.hand, TextSize = 20, TextColor3 = C.paper, Position = UDim2.fromOffset(226, 376), Size = UDim2.fromOffset(500, 90), Parent = root })

	local choice = Instance.new("BindableEvent")
	local function clearControls() controls:ClearAllChildren() end
	local function waitFor(buttons)
		clearControls()
		UI.list(Enum.FillDirection.Horizontal, 12).Parent = controls
		for i, b in buttons do
			local _, api = UI.button(controls, b.text, { style = b.style or "ink", order = i, textSize = 15, size = UDim2.fromOffset(b.w or 240, 46),
				onClick = function() choice:Fire(b.id) end })
			if b.red then api.instance.BackgroundColor3 = C.red end
		end
		return choice.Event:Wait()
	end

	local function speak(whoId, text, n, total)
		for _, ch in paper:GetChildren() do
			if ch.Name == "Stamp" then ch:Destroy() end
		end
		setSpeaker(whoId)
		local ch = case.characters[whoId]
		who.Text = UI.upper(ch and ch.full or "You, the detective")
		say.Text = "\u{201C}" .. text .. "\u{201D}"
		counter.Text = n and ("statement %d of %d"):format(n, total) or ""
		feedback.Text = ""
		local tw = UI.typewrite(say, 70)
		while alive and not tw.done do task.wait() end
	end

	local function pickClue()
		local picked = Instance.new("BindableEvent")
		app:openModal(function(m, close)
			UI.text({ Text = "Which clue proves this wrong?", FontFace = F.type, TextSize = 22, TextColor3 = C.paper, Position = UDim2.fromOffset(60, 28), Size = UDim2.fromOffset(700, 30), Parent = m })
			local grid = UI.new("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(50, 76), Size = UDim2.fromOffset(860, 390),
				CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5, Parent = m })
			UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(200, 70), CellPadding = UDim2.fromOffset(12, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
			UI.pad(6).Parent = grid
			for i, id in state.foundOrder do
				local clue = case.clues[id]
				local cell = UI.frame({ BackgroundTransparency = 1, LayoutOrder = i, Parent = grid })
				local h, s = UI.indexCard(cell, { size = UDim2.fromOffset(200, 70), rot = (i % 3 - 1) * 1.2, lineTop = 28, lineGap = 20 })
				local t = UI.text({ Text = clue.title, FontFace = F.handBold, TextSize = 16, TextColor3 = clue.kind == "fact" and C.blue or C.red,
					Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 1, -8), TextYAlignment = Enum.TextYAlignment.Center, TextScaled = true, Parent = s })
				UI.new("UITextSizeConstraint", { MaxTextSize = 16, MinTextSize = 11, Parent = t })
				local hit = UI.hit({ ZIndex = 10, Parent = h })
				hit.Activated:Connect(function() close() picked:Fire(id) end)
			end
			UI.button(m, "Cancel", { style = "paper", pos = UDim2.fromOffset(50, 480), size = UDim2.fromOffset(150, 40), onClick = function() close() picked:Fire(nil) end })
		end, { dim = 0.15 })
		return picked.Event:Wait()
	end

	--------------------------------------------------------------------
	-- Statement to residents (text blocks)
	--------------------------------------------------------------------
	local function noticeStep()
		setSpeaker("you")
		who.Text = "YOUR STATEMENT TO THE RESIDENTS"
		say.Text = ""
		counter.Text = ""
		feedback.Text = "Half of the room are pensioners, parents and fishermen. Build a statement they can act on."
		clearControls()
		local N = case.notice
		local sel = state.notice
		local preview = UI.text({ FontFace = F.serif, TextSize = 15, Position = UDim2.fromOffset(20, 40), Size = UDim2.new(1, -40, 1, -70), TextScaled = true, Parent = paper })
		UI.new("UITextSizeConstraint", { MaxTextSize = 17, MinTextSize = 10, Parent = preview })
		local function compose()
			local parts = {}
			for _, slot in N.slots do
				local o = sel[slot.id] and slot.options[sel[slot.id]]
				table.insert(parts, o and o.text or "____")
			end
			preview.Text = table.concat(parts, " ")
		end
		compose()

		local strips = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 354), Size = UDim2.fromOffset(696, 132), Parent = root })
		UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(344, 60), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = strips })
		feedback.Position = UDim2.fromOffset(226, 316)
		feedback.Size = UDim2.fromOffset(500, 34)
		feedback.TextSize = 15

		local done = Instance.new("BindableEvent")
		local readBtn
		local function allSet()
			for _, slot in N.slots do if not sel[slot.id] then return false end end
			return true
		end
		local function buildStrips()
			for _, c in strips:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
			for si, slot in N.slots do
				local o = sel[slot.id] and slot.options[sel[slot.id]]
				local b = UI.new("TextButton", { Text = "", BackgroundColor3 = o and C.paperWhite or C.paper, BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = si, Parent = strips })
				UI.stroke(C.ink, 1, 0.5).Parent = b
				UI.text({ Text = UI.upper(slot.label), FontFace = F.type, TextSize = 11, TextColor3 = C.inkSoft, Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 14), Parent = b })
				local v = UI.text({ Text = o and o.text or "tap to choose…", FontFace = o and F.serif or F.hand, TextSize = 14, TextColor3 = o and C.ink or C.inkFaint,
					Position = UDim2.fromOffset(10, 19), Size = UDim2.new(1, -20, 1, -22), TextScaled = true, Parent = b })
				UI.new("UITextSizeConstraint", { MaxTextSize = 15, MinTextSize = 10, Parent = v })
				b.Activated:Connect(function()
					app:openModal(function(m, close)
						UI.text({ Text = UI.upper(slot.label), FontFace = F.type, TextSize = 22, TextColor3 = C.paper, Position = UDim2.fromOffset(120, 50), Size = UDim2.fromOffset(720, 30), Parent = m })
						local col = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(120, 100), Size = UDim2.fromOffset(720, 340), Parent = m })
						UI.list(nil, 12).Parent = col
						for oi, opt in slot.options do
							local unlocked = state:isOptionUnlocked(opt)
							local cell = UI.frame({ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 60), LayoutOrder = oi, Parent = col })
							local h, s = UI.paper(cell, { size = UDim2.fromScale(1, 1), rot = (oi % 2 == 0) and 0.6 or -0.6, color = unlocked and C.paper or C.paperShade, age = false })
							local t = UI.text({ Text = unlocked and opt.text or "██████  You need evidence you haven't found.", FontFace = unlocked and F.serif or F.type,
								TextSize = 17, TextColor3 = unlocked and C.ink or C.inkFaint, Position = UDim2.fromOffset(18, 0), Size = UDim2.new(1, -36, 1, 0),
								TextYAlignment = Enum.TextYAlignment.Center, TextScaled = true, Parent = s })
							UI.new("UITextSizeConstraint", { MaxTextSize = 17, MinTextSize = 11, Parent = t })
							if unlocked then
								local hit = UI.hit({ ZIndex = 10, Parent = h })
								hit.Activated:Connect(function()
									sel[slot.id] = oi
									close()
									compose()
									buildStrips()
								end)
							end
						end
						UI.button(m, "Cancel", { style = "paper", pos = UDim2.fromOffset(120, 470), size = UDim2.fromOffset(140, 40), onClick = close })
					end, { closeOnDim = true, dim = 0.2 })
				end)
			end
			if readBtn then readBtn.setEnabled(allSet()) end
		end
		local _, api = UI.button(root, "Read it out", { pos = UDim2.fromOffset(756, 478), size = UDim2.fromOffset(180, 46), textSize = 15, onClick = function()
			if allSet() then done:Fire() end
		end })
		readBtn = api
		buildStrips()
		done.Event:Wait()
		api.instance:Destroy()
		strips:Destroy()
		preview:Destroy()
		feedback.Position = UDim2.fromOffset(226, 376)
		feedback.Size = UDim2.fromOffset(500, 90)
		feedback.TextSize = 18

		local total, notes = 0, {}
		for _, slot in N.slots do
			local o = slot.options[sel[slot.id]]
			state.noticeQuality[slot.id] = o.q
			total += qualityTrust(o.q)
			if o.why and o.q ~= "clear" then table.insert(notes, o.why) end
		end
		local text = {}
		for _, slot in N.slots do table.insert(text, slot.options[sel[slot.id]].text) end
		speak("you", table.concat(text, " "))
		changeTrust(total)
		feedback.Text = #notes == 0 and "Clear, calm and useful. People nod; someone writes it down." or notes[1]
		waitFor({ { id = "next", text = "The council votes →" } })
	end

	--------------------------------------------------------------------
	-- Sequence
	--------------------------------------------------------------------
	local queue = {}
	if d.bribe == "accepted" then table.insert(queue, { event = H.events.accepted }) end
	for i, st in H.statements do
		table.insert(queue, { statement = st })
		if i == 1 and d.journalist == "published" then table.insert(queue, { event = H.events.published }) end
		if st.who == "arturs" and d.bribe == "saved" then table.insert(queue, { event = H.events.saved }) end
	end

	task.spawn(function()
		task.wait(0.6)
		local nStatements = #H.statements
		local sIndex = 0
		for _, item in queue do
			if not alive then return end
			if item.event then
				local ev = item.event
				speak(ev.who, ev.text)
				changeTrust(ev.trust)
				feedback.Text = ev.trust >= 0 and "The room goes quiet. Then murmurs — on your side." or "The room turns against you."
				waitFor({ { id = "next", text = "Continue" } })
			else
				local st = item.statement
				sIndex += 1
				speak(st.who, st.text, sIndex, nStatements)
				local pick = waitFor({
					{ id = "object", text = "Objection! Present a clue", red = true, w = 260 },
					{ id = "pass", text = "Let it pass", style = "paper", w = 200 },
				})
				clearControls()
				if pick == "object" then
					if st.truthful then
						changeTrust(-10)
						feedback.Text = st.lose
					else
						local id = pickClue()
						if id and table.find(st.counters, id) then
							changeTrust(12)
							Audio.play("gavel")
							UI.stamp(paper, "Sustained", { pos = UDim2.new(1, -80, 1, -30), rot = -8, size = 18, z = 40 })
							feedback.Text = st.win
						elseif id then
							changeTrust(-5)
							UI.stamp(paper, "Overruled", { pos = UDim2.new(1, -80, 1, -30), rot = 8, size = 18, z = 40, color = C.inkSoft })
							feedback.Text = "That clue doesn't disprove it. The lawyer smiles."
						else
							changeTrust(-5)
							feedback.Text = "You stood up and said nothing. The room noticed."
						end
					end
				else
					if st.truthful then
						changeTrust(4)
						feedback.Text = "Fair. You don't fight facts — and the room respects that."
					else
						changeTrust(-5)
						feedback.Text = "The room nods along with the lawyer."
					end
				end
				waitFor({ { id = "next", text = "Next" } })
			end
		end
		if not alive then return end

		noticeStep()
		if not alive then return end

		-- Vote
		clearControls()
		state.hearingTrust = trust
		local stopped = trust >= H.needed and d.bribe ~= "accepted"
		local against = stopped and (trust >= 80 and 6 or 5) or (trust < 30 and 2 or 4)
		setSpeaker("arturs")
		who.Text = "THE VOTE"
		say.Text = "Extend the discharge permit of the Zaļā Druva fertiliser plant for ten years?"
		counter.Text = ""
		feedback.Text = ""
		task.wait(1)
		local order = { 5, 4, 6, 3, 7, 2, 8, 1, 9 }
		for k, idx in order do
			if not alive then return end
			local no = k <= against
			local color = no and Color3.fromRGB(96, 170, 110) or C.redBright
			UI.tween(heads[idx].head, 0.3, { BackgroundColor3 = color })
			UI.tween(heads[idx].body, 0.3, { BackgroundColor3 = color })
			task.wait(0.35)
		end
		feedback.Text = ("%d against, %d for."):format(against, 9 - against)
		Audio.play("verdict")
		UI.stamp(paper, stopped and "Permit frozen" or "Permit extended", { pos = UDim2.fromScale(0.5, 0.62), rot = -7, size = 30, z = 40,
			color = stopped and C.green or C.redBright })
		task.wait(0.8)
		waitFor({ { id = "next", text = "Three months later →", w = 280 } })
		app:go("Ending")
	end)

	return function()
		alive = false
	end
end

return Hearing
