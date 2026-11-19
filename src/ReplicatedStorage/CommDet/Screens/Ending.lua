-- Three months later: the river, four meters, what happened to the people
-- and a checklist of what changed in town because of your decisions.
local Ending = {}

local MURKY = Color3.fromRGB(122, 112, 74)
local CLEAR = Color3.fromRGB(78, 140, 186)

-- outcome label, how to reach it, SDG target it represents (internal only)
local OUTCOMES = {
	{ sdg = "6.3", label = "Night discharges stopped", how = "Find where the pollution comes from and send it to the State Environmental Service — and win the vote." },
	{ sdg = "6.3b", label = "Less pollution reaching the sea", how = "Prove the pollution starts at the plant's pipe and stop the permit." },
	{ sdg = "6.6", label = "The river is recovering", how = "Show the river is healthy above the plant, and stop the permit." },
	{ sdg = "3.9", label = "Families kept safe", how = "Warn people clearly not to swim, and send the case to the Health Inspectorate." },
	{ sdg = "12.8", label = "Residents got clear information", how = "Tell residents what you found and what to do — calmly and precisely." },
	{ sdg = "12.6", label = "Greenwashing exposed", how = "Find the empty 'green' promises in the plant's brochure." },
	{ sdg = "16.5", label = "Corruption reported, bribe refused", how = "Follow the money, refuse the bribe and send the conflict of interest to KNAB." },
	{ sdg = "16.6", label = "Rushed permit exposed", how = "Show how fast the permit was approved and who signed the lab summary." },
	{ sdg = "16.3", label = "Nobody accused without evidence", how = "Don't draw links the documents don't prove, and don't leak rumours to the press." },
	{ sdg = "16.10", label = "Whistleblower kept safe", how = "Use Anna's hidden lab sheet — and keep her name out of it." },
	{ sdg = "16.7", label = "The town decided together", how = "Win the room's trust at the hearing and make updates reach everyone." },
}

function Ending.build(app, root)
	local UI = app.UI
	local C, F = UI.C, UI.F
	local case, state = app.case, app.state
	local out = case.outcome(state)
	local m = out.meters

	local _, hs = UI.paper(root, { pos = UDim2.fromOffset(30, 14), size = UDim2.fromOffset(600, 40), rot = -0.5, color = C.paperWhite, age = false })
	UI.text({ Text = "THREE MONTHS LATER · " .. UI.upper(out.ending.title), FontFace = F.type, TextSize = 18, Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -28, 1, 0), TextYAlignment = Enum.TextYAlignment.Center, Parent = hs })

	-- River illustration
	local band = UI.frame({ BackgroundColor3 = Color3.fromRGB(196, 210, 214), Position = UDim2.fromOffset(30, 64), Size = UDim2.fromOffset(600, 110), ClipsDescendants = true, Parent = root })
	UI.stroke(C.wood, 4).Parent = band
	local t = m.river / 100
	UI.frame({ BackgroundColor3 = MURKY:Lerp(CLEAR, t), Position = UDim2.new(0, 0, 0, 52), Size = UDim2.new(1, 0, 1, -52), Parent = band })
	UI.frame({ BackgroundColor3 = Color3.fromRGB(110, 140, 90), Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 14), Parent = band })
	local rng = Random.new(2)
	for _ = 1, 10 do
		local tr = UI.frame({ BackgroundColor3 = Color3.fromRGB(80, 116, 76), Position = UDim2.fromOffset(rng:NextInteger(0, 580), rng:NextInteger(8, 26)), Size = UDim2.fromOffset(26, 26), Parent = band })
		UI.corner(UDim.new(0.5, 0)).Parent = tr
	end
	local fish = math.floor(m.river / 15)
	for i = 1, fish do
		local f = UI.frame({ BackgroundColor3 = Color3.fromRGB(220, 226, 230), Position = UDim2.fromOffset(20 + i * 80 + rng:NextInteger(-20, 20), rng:NextInteger(66, 92)),
			Size = UDim2.fromOffset(28, 10), Parent = band })
		UI.corner(UDim.new(0.5, 0)).Parent = f
		UI.frame({ BackgroundColor3 = Color3.fromRGB(220, 226, 230), Position = UDim2.fromOffset(-8, 1), Size = UDim2.fromOffset(10, 8), Rotation = 45, Parent = f })
		UI.tween(f, 2 + rng:NextNumber(), { Position = f.Position + UDim2.fromOffset(40, 0) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	end
	if fish == 0 then
		UI.text({ Text = "no fish", FontFace = F.hand, TextSize = 16, TextColor3 = C.paperWhite, Position = UDim2.fromOffset(260, 70), Size = UDim2.fromOffset(100, 20), Parent = band })
	end

	local et = UI.text({ Text = out.ending.text, FontFace = F.serifItalic, TextSize = 15, TextColor3 = C.paper, Position = UDim2.fromOffset(30, 180), Size = UDim2.fromOffset(600, 48), TextScaled = true, Parent = root })
	UI.new("UITextSizeConstraint", { MaxTextSize = 15, MinTextSize = 11, Parent = et })

	-- Meters
	local meters = { { "River", m.river }, { "Justice", m.justice }, { "Safety", m.safety }, { "Trust", m.trust } }
	for i, row in meters do
		local y = 236 + (i - 1) * 26
		UI.text({ Text = UI.upper(row[1]), FontFace = F.type, TextSize = 14, TextColor3 = C.paper, Position = UDim2.fromOffset(30, y), Size = UDim2.fromOffset(90, 20), Parent = root })
		local back = UI.frame({ BackgroundColor3 = C.desk, Position = UDim2.fromOffset(122, y + 3), Size = UDim2.fromOffset(440, 14), Parent = root })
		UI.stroke(C.paperShade, 1, 0.4).Parent = back
		local fillC = row[2] >= 60 and Color3.fromRGB(96, 170, 110) or (row[2] >= 35 and C.lamp or C.redBright)
		local fl = UI.frame({ BackgroundColor3 = fillC, Size = UDim2.fromScale(0, 1), Parent = back })
		UI.tween(fl, 0.8, { Size = UDim2.fromScale(row[2] / 100, 1) })
		UI.text({ Text = tostring(row[2]), FontFace = F.type, TextSize = 14, TextColor3 = C.paper, Position = UDim2.fromOffset(574, y), Size = UDim2.fromOffset(50, 20), Parent = root })
	end

	-- People
	local grid = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 346), Size = UDim2.fromOffset(600, 184), Parent = root })
	UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(294, 88), CellPadding = UDim2.fromOffset(12, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	for i, card in out.cards do
		local cell = UI.frame({ BackgroundTransparency = 1, LayoutOrder = i, Parent = grid })
		local _, s = UI.paper(cell, { size = UDim2.fromScale(1, 1), rot = (i % 2 == 0) and 0.8 or -0.8, color = C.card, age = false })
		local ch = case.characters[card.who]
		if ch then
			UI.polaroid(s, { pos = UDim2.fromOffset(6, 6), size = UDim2.fromOffset(54, 68), rot = -3, look = ch.look, small = ch.small, caption = ch.name, captionSize = 9 })
		else
			local r = UI.frame({ BackgroundColor3 = MURKY:Lerp(CLEAR, t), Position = UDim2.fromOffset(8, 10), Size = UDim2.fromOffset(50, 60), Parent = s })
			UI.text({ Text = "RIVER", FontFace = F.type, TextSize = 10, TextColor3 = C.paperWhite, TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = r })
		end
		local tl = UI.text({ Text = card.text, FontFace = F.serif, TextSize = 13, TextColor3 = card.good and C.ink or C.red, Position = UDim2.fromOffset(68, 8),
			Size = UDim2.new(1, -78, 1, -16), TextScaled = true, Parent = s })
		UI.new("UITextSizeConstraint", { MaxTextSize = 13, MinTextSize = 9, Parent = tl })
	end

	-- What changed in town
	local _, sp = UI.paper(root, { pos = UDim2.fromOffset(650, 14), size = UDim2.fromOffset(282, 456), color = C.paper })
	local reached = 0
	for _, o in OUTCOMES do if out.reached[o.sdg] then reached += 1 end end
	UI.text({ Text = "WHAT CHANGED IN " .. UI.upper(case.town), FontFace = F.type, TextSize = 15, Position = UDim2.fromOffset(14, 12), Size = UDim2.new(1, -28, 0, 20), Parent = sp })
	UI.text({ Text = ("%d of %d. Tap a line to see why."):format(reached, #OUTCOMES), FontFace = F.hand, TextSize = 15, TextColor3 = C.blue,
		Position = UDim2.fromOffset(14, 34), Size = UDim2.new(1, -28, 0, 24), Parent = sp })
	local list = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 64), Size = UDim2.new(1, -24, 1, -72), Parent = sp })
	UI.list(nil, 3).Parent = list
	for i, o in OUTCOMES do
		local ok = out.reached[o.sdg]
		local row = UI.new("TextButton", { Text = "", BackgroundColor3 = ok and Color3.fromRGB(226, 236, 214) or C.paperWhite, BorderSizePixel = 0, AutoButtonColor = false,
			Size = UDim2.new(1, 0, 0, 31), LayoutOrder = i, Parent = list })
		UI.text({ Text = ok and "✓" or "x", FontFace = F.handBold, TextSize = 18, TextColor3 = ok and C.green or C.red, Position = UDim2.fromOffset(6, 0),
			Size = UDim2.fromOffset(20, 31), TextYAlignment = Enum.TextYAlignment.Center, Parent = row })
		UI.text({ Text = o.label, FontFace = F.serif, TextSize = 13, TextColor3 = ok and C.ink or C.inkFaint, Position = UDim2.fromOffset(30, 0),
			Size = UDim2.new(1, -34, 1, 0), TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row })
		row.Activated:Connect(function()
			app:openModal(function(md, close)
				local h, s = UI.indexCard(md, { pos = UDim2.fromOffset(480, 270), anchor = Vector2.new(0.5, 0.5), size = UDim2.fromOffset(520, 220), rot = -0.6, lineTop = 50, lineGap = 26 })
				UI.pin(h, UDim2.new(0.5, 0, 0, 8))
				UI.text({ Text = UI.upper(o.label), FontFace = F.type, TextSize = 17, TextColor3 = ok and C.green or C.red, Position = UDim2.fromOffset(22, 16), Size = UDim2.new(1, -44, 0, 24), Parent = s })
				UI.text({ Text = (ok and "You did it: " or "Not this time. How: ") .. o.how, FontFace = F.hand, TextSize = 18, TextColor3 = C.blue,
					Position = UDim2.fromOffset(22, 54), Size = UDim2.new(1, -44, 0, 100), Parent = s })
				UI.button(s, "Close", { style = "paper", pos = UDim2.new(1, -20, 1, -14), anchor = Vector2.new(1, 1), size = UDim2.fromOffset(110, 34), textSize = 13, onClick = close })
			end, { closeOnDim = true })
		end)
	end

	-- the ending stamp sits on a paper slip so it reads over the river picture
	local good = out.ending.title == "Clear Water"
	local st = UI.stamp(root, out.ending.title, { pos = UDim2.fromOffset(470, 104), rot = -8, size = 26, z = 40, thick = 3,
		color = good and Color3.fromRGB(34, 110, 58) or Color3.fromRGB(170, 28, 32) })
	st.BackgroundColor3 = C.paperWhite
	st.BackgroundTransparency = 1
	local padding = st:FindFirstChildOfClass("UIPadding")
	if padding then
		padding.PaddingTop, padding.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
		padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 14), UDim.new(0, 14)
	end
	UI.tween(st, 0.18, { BackgroundTransparency = 0.08 })

	UI.button(root, "Play again", { pos = UDim2.fromOffset(650, 480), size = UDim2.fromOffset(282, 46), onClick = function()
		app:newCase()
		app:go("Title")
	end })
end

return Ending
