-- Follow the money: connect people and companies, but only with links the documents prove.
-- (README: SDG 16.5 corruption and bribery, 16.6 transparent institutions, 16.3 no unproven accusations.)
local MoneyTrail = {}

function MoneyTrail.build(app, root)
	local UI = app.UI
	local C, F = UI.C, UI.F
	local case, state = app.case, app.state
	local data = case.money

	local _, hs = UI.paper(root, { pos = UDim2.fromOffset(24, 14), size = UDim2.fromOffset(600, 44), rot = -0.5, color = C.paperWhite, age = false })
	UI.text({ Text = "FOLLOW THE MONEY · PUBLIC RECORDS", FontFace = F.type, TextSize = 19, Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -32, 1, 0), TextYAlignment = Enum.TextYAlignment.Center, Parent = hs })

	--------------------------------------------------------------------
	-- Documents (left)
	--------------------------------------------------------------------
	local tabs = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 70), Size = UDim2.fromOffset(340, 30), Parent = root })
	local docH, doc = UI.paper(root, { pos = UDim2.fromOffset(24, 100), size = UDim2.fromOffset(340, 330), color = C.paperWhite, age = false })
	local docBody = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 1, -28), Parent = doc })
	UI.list(nil, 4).Parent = docBody
	local current = 1

	local function showDoc(i)
		current = i
		for _, c in docBody:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
		local d = data.docs[i]
		UI.text({ Text = UI.upper(d.title), FontFace = F.type, TextSize = 16, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 0, Parent = docBody })
		if d.requiresEvidence and not state.revealed[d.requiresEvidence] then
			UI.text({ Text = "You don't have this document yet. Request public records at the town hall.", FontFace = F.hand, TextSize = 17,
				TextColor3 = C.red, Size = UDim2.new(1, 0, 0, 60), LayoutOrder = 1, Parent = docBody })
		else
			for j, line in d.lines do
				local isNote = string.sub(line, 1, 1) == "("
				UI.text({ Text = line, FontFace = isNote and F.hand or F.mono, TextSize = isNote and 15 or 13, TextColor3 = isNote and C.blue or C.ink,
					Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = j, Parent = docBody })
			end
		end
		for j, t in tabs:GetChildren() do
			if t:IsA("TextButton") then
				t.BackgroundColor3 = t.LayoutOrder == i and C.manila or C.manilaDark
			end
		end
	end
	UI.list(Enum.FillDirection.Horizontal, 3).Parent = tabs
	for i, d in data.docs do
		local t = UI.new("TextButton", { Text = d.title, FontFace = F.type, TextSize = 11, TextWrapped = true, TextColor3 = C.ink,
			BackgroundColor3 = C.manilaDark, BorderSizePixel = 0, AutoButtonColor = false, Size = UDim2.fromOffset(82, 30), LayoutOrder = i, Parent = tabs })
		UI.corner(4).Parent = t
		t.Activated:Connect(function() showDoc(i) end)
	end

	UI.text({ Text = "Tap two cards on the board, then choose how they are connected. Only connect what a document proves — a wrong link is an unfair accusation.",
		FontFace = F.hand, TextSize = 15, TextColor3 = C.paperShade, Position = UDim2.fromOffset(24, 440), Size = UDim2.fromOffset(340, 80), Parent = root })

	--------------------------------------------------------------------
	-- Board (right)
	--------------------------------------------------------------------
	local _, woodSheet = UI.paper(root, { pos = UDim2.fromOffset(380, 70), size = UDim2.fromOffset(560, 410), color = C.wood, age = false })
	local board = UI.frame({ BackgroundColor3 = C.cork, Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -16), Parent = woodSheet })
	local threads = UI.frame({ BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = board })

	local nodes, centers = {}, {}
	local selected
	local required = 0
	for _, l in data.links do if not l.extra then required += 1 end end

	local progress = UI.text({ FontFace = F.type, TextSize = 15, TextColor3 = C.paper, Position = UDim2.fromOffset(380, 488), Size = UDim2.fromOffset(300, 20), Parent = root })

	local function linkKey(l) return l.a .. "|" .. l.b .. "|" .. l.rel end

	local function drawLink(l, animate)
		local a, b = centers[l.a], centers[l.b]
		UI.thread(threads, a, b, { animate = animate, z = 2, width = 3 })
		local mid = (a + b) / 2
		UI.text({ Text = l.rel, FontFace = F.handBold, TextSize = 13, TextColor3 = C.paperWhite, BackgroundColor3 = C.red, BackgroundTransparency = 0.1,
			TextWrapped = false, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(mid.X, mid.Y), ZIndex = 4, Parent = threads })
	end

	local function countLinks()
		local n = 0
		for _, l in data.links do
			if not l.extra and state.links[linkKey(l)] then n += 1 end
		end
		return n
	end

	local function updateProgress()
		local n = countLinks()
		progress.Text = ("Proven links: %d of %d · unfair links: %d"):format(n, required, state.falseLinks)
		if n >= required and not state:has("c_conflict") then
			state:find("c_conflict")
			UI.stamp(board, "Conflict of interest", { pos = UDim2.fromScale(0.5, 0.52), rot = -8, size = 26, z = 30 })
			app:toast("Councillor Lapsa voted for the permit while the plant paid his brother's company €18,000.", C.red)
		end
	end

	local function select(id, on)
		local n = nodes[id]
		local s = n:FindFirstChild("Sel")
		if s then s:Destroy() end
		if on then
			local st = UI.stroke(C.redBright, 3)
			st.Name = "Sel"
			st.Parent = n
		end
	end

	local function tryLink(a, b, rel)
		for _, l in data.links do
			local match = l.rel == rel and ((l.a == a and l.b == b) or (l.a == b and l.b == a))
			if match then
				if state.links[linkKey(l)] then
					app:toast("You already proved that link.")
					return
				end
				if l.source == "Council minutes" and not state.revealed.E4 then
					app:toast("You need the council minutes to prove that. Request them at the town hall.")
					return
				end
				state.links[linkKey(l)] = true
				drawLink(l, true)
				app:toast("Proven by: " .. l.source .. (l.extra and " (true, but not part of this case)" or ""), C.green)
				updateProgress()
				return
			end
		end
		state.falseLinks += 1
		app:toast("Unsupported claim — no document shows that. Fairness goes down.", C.red)
		UI.shake(nodes[a], 5)
		UI.shake(nodes[b], 5)
		updateProgress()
	end

	local function askRelation(a, b)
		local la, lb
		for _, n in data.nodes do
			if n.id == a then la = n.label end
			if n.id == b then lb = n.label end
		end
		app:openModal(function(m, close)
			local h, s = UI.indexCard(m, { pos = UDim2.fromOffset(480, 270), anchor = Vector2.new(0.5, 0.5), size = UDim2.fromOffset(480, 300), rot = -0.6, lineTop = 50, lineGap = 26 })
			UI.pin(h, UDim2.new(0.5, 0, 0, 8))
			UI.text({ Text = "HOW ARE THEY CONNECTED?", FontFace = F.type, TextSize = 18, Position = UDim2.fromOffset(20, 16), Size = UDim2.new(1, -40, 0, 24), Parent = s })
			UI.text({ Text = la .. "  …  " .. lb, FontFace = F.handBold, TextSize = 18, TextColor3 = C.blue, Position = UDim2.fromOffset(20, 52), Size = UDim2.new(1, -40, 0, 26), Parent = s })
			local col = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 92), Size = UDim2.new(1, -40, 0, 190), Parent = s })
			UI.list(nil, 6).Parent = col
			for i, rel in data.relations do
				UI.button(col, la .. "  " .. rel .. "  " .. lb, { style = "paper", font = F.serif, textSize = 14, order = i, size = UDim2.new(1, 0, 0, 34),
					alignX = Enum.TextXAlignment.Left, onClick = function()
						close()
						tryLink(a, b, rel)
					end }).FontFace = F.serif
			end
			UI.button(col, "Cancel", { style = "paper", textSize = 13, order = 9, size = UDim2.fromOffset(100, 30), onClick = close })
		end, { closeOnDim = true, dim = 0.2 })
	end

	for _, n in data.nodes do
		local x, y = 8 + n.x * 1.13, 14 + n.y * 0.86
		local isCompany = string.find(n.label, "Ltd") or string.find(n.label, "Fertilisers")
		local isPermit = n.id == "permit"
		local b = UI.new("TextButton", {
			Name = n.id, Text = n.label, FontFace = F.type, TextSize = 14, TextWrapped = true, TextColor3 = C.ink,
			BackgroundColor3 = isPermit and Color3.fromRGB(236, 214, 140) or (isCompany and C.manila or C.paperWhite),
			BorderSizePixel = 0, AutoButtonColor = false, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(150, 40),
			Rotation = ((#n.id % 3) - 1) * 1.5, ZIndex = 3, Parent = board,
		})
		UI.pad(2, 6).Parent = b
		nodes[n.id] = b
		centers[n.id] = Vector2.new(x + 75, y + 20)
		UI.pin(board, UDim2.fromOffset(x + 75, y + 2), C.red, 5)
		b.Activated:Connect(function()
			if selected == n.id then
				select(n.id, false)
				selected = nil
			elseif selected then
				local a = selected
				select(a, false)
				selected = nil
				askRelation(a, n.id)
			else
				selected = n.id
				select(n.id, true)
			end
		end)
	end

	for _, l in data.links do
		if state.links[linkKey(l)] then drawLink(l, false) end
	end
	showDoc(1)
	updateProgress()
	if state:has("c_conflict") then
		UI.stamp(board, "Conflict of interest", { pos = UDim2.fromScale(0.5, 0.52), rot = -8, size = 26, z = 30, animate = false })
	end

	UI.button(root, "Back to the map", { pos = UDim2.fromOffset(710, 488), size = UDim2.fromOffset(230, 40), textSize = 15, onClick = function() app:go("Map") end })
end

return MoneyTrail
