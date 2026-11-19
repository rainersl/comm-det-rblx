-- Before the hearing: review your key evidence and choose who receives your report.
-- Sending evidence to the right institution is what makes change happen (README: SDG 16.6).
local Report = {}

local KEY = {
	{ id = "c_source", label = "Where the pollution comes from" },
	{ id = "c_upstream", label = "Proof it isn't natural" },
	{ id = "c_daytime", label = "Why official tests looked fine" },
	{ id = "c_hidden", label = "The hidden lab result" },
	{ id = "c_conflict", label = "Who profited from the permit" },
	{ id = "c_fast", label = "How the permit was rushed" },
	{ id = "c_rash", label = "Harm to people" },
	{ id = "c_zero", label = "The plant's green claims" },
}

function Report.build(app, root)
	local UI = app.UI
	local C, F = UI.C, UI.F
	local case, state = app.case, app.state

	local _, hs = UI.paper(root, { pos = UDim2.fromOffset(24, 14), size = UDim2.fromOffset(600, 44), rot = -0.5, color = C.paperWhite, age = false })
	UI.text({ Text = "FRIDAY, 9:00 · SEND YOUR REPORT", FontFace = F.type, TextSize = 19, Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -32, 1, 0), TextYAlignment = Enum.TextYAlignment.Center, Parent = hs })

	-- Evidence checklist
	local _, ev = UI.paper(root, { pos = UDim2.fromOffset(24, 72), size = UDim2.fromOffset(400, 452), color = C.paper })
	UI.text({ Text = "KEY EVIDENCE", FontFace = F.type, TextSize = 16, Position = UDim2.fromOffset(18, 14), Size = UDim2.new(1, -36, 0, 22), Parent = ev })
	local col = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 44), Size = UDim2.new(1, -36, 1, -110), Parent = ev })
	UI.list(nil, 4).Parent = col
	local have = 0
	for i, k in KEY do
		local ok = state:has(k.id)
		if k.id == "c_rash" then ok = state:hasAny({ "c_rash", "c_beach" }) end
		if ok then have += 1 end
		local row = UI.frame({ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = i, Parent = col })
		UI.text({ Text = ok and "✓" or "x", FontFace = F.handBold, TextSize = 22, TextColor3 = ok and C.green or C.red, Size = UDim2.fromOffset(24, 40),
			TextYAlignment = Enum.TextYAlignment.Center, Parent = row })
		UI.text({ Text = k.label, FontFace = F.serif, TextSize = 15, TextColor3 = ok and C.ink or C.inkFaint, Position = UDim2.fromOffset(30, 2), Size = UDim2.new(1, -30, 0, 18), Parent = row })
		UI.text({ Text = ok and case.clues[k.id].title or "not found", FontFace = F.hand, TextSize = 13, TextColor3 = ok and C.blue or C.inkFaint,
			Position = UDim2.fromOffset(30, 20), Size = UDim2.new(1, -30, 0, 18), TextTruncate = Enum.TextTruncate.AtEnd, Parent = row })
	end
	UI.text({ Text = ("%d of %d. Missing evidence will make the hearing harder."):format(have, #KEY), FontFace = F.hand, TextSize = 16,
		TextColor3 = have >= 6 and C.green or C.red, Position = UDim2.new(0, 18, 1, -56), Size = UDim2.new(1, -36, 0, 40), Parent = ev })

	-- Institutions
	UI.text({ Text = "WHO RECEIVES YOUR EVIDENCE?", FontFace = F.type, TextSize = 16, TextColor3 = C.paper, Position = UDim2.fromOffset(448, 72), Size = UDim2.fromOffset(480, 22), Parent = root })
	UI.text({ Text = "Choose every place that should act on it. Choose carefully — the wrong address means nobody investigates.",
		FontFace = F.hand, TextSize = 15, TextColor3 = C.paperShade, Position = UDim2.fromOffset(448, 96), Size = UDim2.fromOffset(480, 40), Parent = root })
	local list = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(448, 140), Size = UDim2.fromOffset(484, 320), Parent = root })
	UI.list(nil, 8).Parent = list
	local picks = {}
	for i, inst in case.institutions do
		local cell = UI.frame({ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 56), LayoutOrder = i, Parent = list })
		local h, s = UI.paper(cell, { size = UDim2.fromScale(1, 1), rot = (i % 2 == 0) and 0.5 or -0.5, color = C.paperWhite, age = false })
		local box = UI.frame({ BackgroundColor3 = C.paper, Position = UDim2.fromOffset(12, 16), Size = UDim2.fromOffset(24, 24), Parent = s })
		UI.stroke(C.ink, 1.5).Parent = box
		UI.text({ Text = inst.name, FontFace = F.type, TextSize = 14, Position = UDim2.fromOffset(48, 6), Size = UDim2.new(1, -60, 0, 20), TextTruncate = Enum.TextTruncate.AtEnd, Parent = s })
		UI.text({ Text = inst.does, FontFace = F.serif, TextSize = 13, TextColor3 = C.inkSoft, Position = UDim2.fromOffset(48, 28), Size = UDim2.new(1, -60, 0, 22), Parent = s })
		local hit = UI.hit({ ZIndex = 10, Parent = h })
		hit.Activated:Connect(function()
			picks[inst.id] = not picks[inst.id]
			local mk = box:FindFirstChild("Mark")
			if mk then mk:Destroy() end
			if picks[inst.id] then
				UI.text({ Name = "Mark", Text = "X", FontFace = F.handBold, TextSize = 28, TextColor3 = C.redBright, Size = UDim2.new(1, 8, 1, 8), Position = UDim2.fromOffset(-4, -8),
					TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, Parent = box })
			end
		end)
	end

	UI.button(root, "Send the report and go to the hearing →", { pos = UDim2.fromOffset(448, 474), size = UDim2.fromOffset(484, 50), textSize = 15,
		onClick = function()
			local any = false
			for _, v in picks do if v then any = true end end
			if not any then
				app:toast("Your evidence needs to reach someone. Choose at least one.", C.red)
				return
			end
			state.institutions = {}
			for id, v in picks do if v then state.institutions[id] = true end end
			app:go("Hearing")
		end })
end

return Report
