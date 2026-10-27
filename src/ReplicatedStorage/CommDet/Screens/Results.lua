-- result
local Config = require(script.Parent.Parent.Config)
local Evaluator = require(script.Parent.Parent.Systems.MessageEvaluator)

local Results = {}

function Results.build(app, root)
	local UI = app.UI
	local C, F = UI.C, UI.F
	local case, state = app.case, app.state
	local res = Evaluator.evaluateCase(case, state)
	local alive = true

	local hh, hs = UI.paper(root, { pos = UDim2.fromOffset(30, 16), size = UDim2.fromOffset(560, 44), rot = -0.8, color = C.paperWhite, age = false })
	UI.text({ Text = "PIEKTDIENA, 15.00. 4. LABORATORIJA.", FontFace = F.type, TextSize = 20, Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -32, 1, 0),
		TextYAlignment = Enum.TextYAlignment.Center, Parent = hs })
	UI.tape(hh, UDim2.new(0, 14, 0, 4), -30, 40)

	local room = UI.frame({ BackgroundColor3 = Color3.fromRGB(30, 32, 36), Position = UDim2.fromOffset(30, 74), Size = UDim2.fromOffset(560, 104), Parent = root })
	UI.stroke(C.wood, 3).Parent = room
	local chairs = {}
	local maxSeats = 10
	for i = 1, maxSeats do
		local x = 22 + (i - 1) * 53
		local chair = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(x, 26), Size = UDim2.fromOffset(36, 56), Parent = room })
		local back = UI.frame({ BackgroundColor3 = C.inkSoft, Position = UDim2.fromOffset(4, 0), Size = UDim2.fromOffset(28, 24), Parent = chair })
		local seat = UI.frame({ BackgroundColor3 = C.inkSoft, Position = UDim2.fromOffset(0, 26), Size = UDim2.fromOffset(36, 8), Parent = chair })
		UI.frame({ BackgroundColor3 = C.inkSoft, Position = UDim2.fromOffset(3, 34), Size = UDim2.fromOffset(3, 20), Parent = chair })
		UI.frame({ BackgroundColor3 = C.inkSoft, Position = UDim2.fromOffset(30, 34), Size = UDim2.fromOffset(3, 20), Parent = chair })
		-- cilvēka siluets (parādās, kad atnāk)
		local person = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(4, -20), Size = UDim2.fromOffset(28, 52), Visible = false, Parent = chair })
		local head = UI.frame({ BackgroundColor3 = C.lamp, Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(6, 0), Parent = person })
		UI.corner(UDim.new(0.5, 0)).Parent = head
		local body = UI.frame({ BackgroundColor3 = C.lamp, Size = UDim2.fromOffset(26, 26), Position = UDim2.fromOffset(1, 18), Parent = person })
		UI.corner(UDim.new(0.4, 0)).Parent = body
		chairs[i] = { person = person, back = back, seat = seat }
	end
	
	local tx = 22 + Config.TEAM_NEEDED * 53 - 9
	UI.frame({ BackgroundColor3 = C.redBright, Position = UDim2.fromOffset(tx, 6), Size = UDim2.fromOffset(2, 92), Parent = room })
	UI.text({ Text = "komanda", FontFace = F.hand, TextSize = 14, TextColor3 = C.redBright, Position = UDim2.fromOffset(tx + 5, 2), Size = UDim2.fromOffset(80, 18), Parent = room })
	local counter = UI.text({ Text = "0", FontFace = F.type, TextSize = 40, TextColor3 = C.paper, Position = UDim2.fromOffset(606, 82), Size = UDim2.fromOffset(120, 50), Parent = root })
	UI.text({ Text = "ATNĀCA", FontFace = F.type, TextSize = 13, TextColor3 = C.paperShade, Position = UDim2.fromOffset(606, 130), Size = UDim2.fromOffset(120, 18), Parent = root })

	local filled = 0
	local function fill(n)
		for _ = 1, n do
			filled += 1
			local c = chairs[filled]
			if c then
				c.person.Visible = true
				c.person.Position = UDim2.fromOffset(4, -40)
				UI.tween(c.person, 0.3, { Position = UDim2.fromOffset(4, -20) }, Enum.EasingStyle.Back)
			end
			counter.Text = tostring(filled)
			task.wait(0.12)
		end
	end

	
	local cardsBox = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 192), Size = UDim2.fromOffset(560, 340), Parent = root })
	local grid = UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(274, 104), CellPadding = UDim2.fromOffset(12, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = cardsBox })

	local function reactionCard(i, card)
		local cell = UI.frame({ BackgroundTransparency = 1, LayoutOrder = i, Parent = cardsBox })
		local rot = ((i % 2) == 0 and 1 or -1) * 0.8
		local h, s = UI.paper(cell, { size = UDim2.fromScale(1, 1), rot = rot, color = C.card, age = false })
		local ch = case.characters[card.who]
		local look = ch and ch.look or { "longhair" }
		local name = ch and ch.name or "Vecāki"
		UI.polaroid(s, { pos = UDim2.fromOffset(8, 10), size = UDim2.fromOffset(58, 72), rot = -3, look = look, small = ch and ch.small, caption = name, captionSize = 10 })
		local tl = UI.text({ Text = card.text, FontFace = F.serif, TextSize = 13, Position = UDim2.fromOffset(76, 10), Size = UDim2.new(1, -116, 1, -20), TextScaled = true, Parent = s })
		UI.new("UITextSizeConstraint", { MaxTextSize = 13, MinTextSize = 9, Parent = tl })
		UI.text({ Text = card.count > 0 and ("+" .. card.count) or (card.who == "markuss" and "" or "—"), FontFace = F.handBold, TextSize = 24, TextColor3 = card.count > 0 and C.green or C.red,
			Position = UDim2.new(1, -40, 0, 4), Size = UDim2.fromOffset(34, 30), TextXAlignment = Enum.TextXAlignment.Right, Parent = s })
		local sc = UI.new("UIScale", { Scale = 0.6, Parent = h })
		h.Position = UDim2.fromOffset(0, 20)
		UI.tween(sc, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		UI.tween(h, 0.25, { Position = UDim2.fromOffset(0, 0) })
	end

	
	local right = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(616, 170), Size = UDim2.fromOffset(320, 360), Parent = root })

	local function scoreCard()
		local h, s = UI.indexCard(right, { pos = UDim2.fromOffset(0, 0), size = UDim2.fromOffset(318, 270), rot = 1, lineTop = 44, lineGap = 34 })
		UI.pin(h, UDim2.new(0.5, 0, 0, 8))
		UI.text({ Text = "VĒRTĒJUMS", FontFace = F.type, TextSize = 17, Position = UDim2.fromOffset(18, 14), Size = UDim2.fromOffset(200, 22), Parent = s })
		local rows = {
			{ "Izmeklēšana", res.stars.investigation },
			{ "Precizitāte", res.stars.accuracy },
			{ "Skaidrība", res.stars.clarity },
			{ "Piemērotība", res.stars.appropriateness },
		}
		for i, r in rows do
			local y = 44 + (i - 1) * 34
			UI.text({ Text = r[1], FontFace = F.hand, TextSize = 19, TextColor3 = C.blue, Position = UDim2.fromOffset(18, y + 2), Size = UDim2.fromOffset(150, 30), Parent = s })
			for k = 1, 3 do
				local on = k <= r[2]
				local dot = UI.frame({ BackgroundColor3 = on and C.red or C.card, Position = UDim2.fromOffset(200 + (k - 1) * 30, y + 8), Size = UDim2.fromOffset(18, 18), Rotation = 45, Parent = s })
				UI.stroke(C.red, 1.5).Parent = dot
			end
		end
		UI.text({ Text = "Rangs:", FontFace = F.type, TextSize = 13, TextColor3 = C.inkFaint, Position = UDim2.fromOffset(18, 186), Size = UDim2.fromOffset(100, 18), Parent = s })
		UI.text({ Text = res.rank, FontFace = F.typ or F.type, TextSize = 17, Position = UDim2.fromOffset(18, 204), Size = UDim2.new(1, -36, 0, 24), Parent = s })
		UI.text({ Text = ("Pavedieni: %d no %d · mājieni: %d · kļūdaini: %d"):format(res.found, res.totalClues, state.hintsUsed, state.decoyCount),
			FontFace = F.hand, TextSize = 14, TextColor3 = C.inkFaint, Position = UDim2.fromOffset(18, 236), Size = UDim2.new(1, -36, 0, 20), Parent = s })

		local row = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 290), Size = UDim2.fromOffset(318, 46), Parent = right })
		UI.button(row, "Komisāra piezīmes", { style = "paper", size = UDim2.fromOffset(160, 44), textSize = 13, onClick = function()
			app:openModal(function(md, close)
				local ph, ps = UI.paper(md, { pos = UDim2.fromOffset(110, 30), size = UDim2.fromOffset(740, 440), rot = 0, color = C.paper })
				UI.pin(ph, UDim2.new(0.5, 0, 0, 10))
				UI.text({ Text = "KOMISĀRA PIEZĪMES — KAS ZIŅĀS VĒL NEBIJA SKAIDRS", FontFace = F.type, TextSize = 16, Position = UDim2.fromOffset(28, 24), Size = UDim2.new(1, -56, 0, 22), Parent = ps })
				local sc = UI.new("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(28, 58), Size = UDim2.new(1, -44, 1, -76),
					CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5, Parent = ps })
				UI.list(nil, 8).Parent = sc
				local n = 0
				for _, m in case.messages do
					local r = res.messages[m.id]
					n += 1
					UI.text({ Text = UI.upper(m.tab), FontFace = F.type, TextSize = 14, TextColor3 = C.inkSoft, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = n, Parent = sc })
					if #r.issues == 0 then
						n += 1
						UI.text({ Text = "Viss skaidrs un piemēroti uzrakstīts. Nav ko piebilst.", FontFace = F.hand, TextSize = 18, TextColor3 = C.green, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = n, Parent = sc })
					end
					for _, iss in r.issues do
						n += 1
						local tag = ({ vague = "neskaidrs", wrong = "nepareizs fakts", register = "nepiemērots tonis" })[iss.q] or iss.q
						UI.text({ Text = ("%s: „%s” — %s. %s"):format(iss.label, iss.text, tag, iss.why), FontFace = F.serif, TextSize = 15,
							Size = UDim2.new(1, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = n, Parent = sc })
					end
				end
				UI.button(md, "Aizvērt", { pos = UDim2.fromOffset(700, 482), size = UDim2.fromOffset(150, 42), onClick = close })
			end, { closeOnDim = true })
		end })
		UI.button(row, "Spēlēt vēlreiz", { pos = UDim2.fromOffset(168, 0), size = UDim2.fromOffset(150, 44), textSize = 13, onClick = function()
			app:newCase()
			app:go("Title")
		end })
	end

	
	task.spawn(function()
		task.wait(0.8)
		for i, card in res.cards do
			if not alive then return end
			reactionCard(i, card)
			task.wait(0.35)
			fill(card.count)
			task.wait(0.7)
		end
		if not alive then return end
		local closing = UI.text({ Text = res.success and case.closing.success or case.closing.fail, FontFace = F.serifItalic, TextSize = 16, TextColor3 = C.paper,
			Position = UDim2.fromOffset(616, 16), Size = UDim2.fromOffset(320, 64), Parent = root })
		local tw = UI.typewrite(closing, 50)
		while not tw.done and alive do task.wait() end
		UI.stamp(root, res.success and "Lieta atrisināta" or "Nav atrisināta", { pos = UDim2.fromOffset(800, 120), rot = -10, size = 22, color = res.success and C.redBright or C.paperShade, z = 40 })
		task.wait(0.6)
		if alive then scoreCard() end
	end)

	return function()
		alive = false
	end
end

return Results
