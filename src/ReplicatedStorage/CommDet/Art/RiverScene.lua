-- River scene for the water test. Built only from GUI frames: layered gradients,
-- concentric glows and CanvasGroups for soft, painted-looking light and water.
local TweenService = game:GetService("TweenService")

local RiverScene = {}

local W, H = 400, 430
local HORIZON = 238

function RiverScene.build(UI, parent, o)
	local C, F = UI.C, UI.F
	local night = o.night == true
	local evening = o.slot == "Evening"
	local pid = o.point.id
	local rng = Random.new(#pid * 31 + (night and 3 or 0) + 7)
	local WHITE = Color3.new(1, 1, 1)

	local function fr(p) return UI.frame(p) end
	local function round(obj, r) UI.corner(r or UDim.new(0.5, 0)).Parent = obj; return obj end
	local function grad(obj, cols, rot, transp)
		local seq
		if typeof(cols[1]) == "Color3" then
			seq = ColorSequence.new(cols[1], cols[2])
		else
			local kps = {}
			for _, k in cols do table.insert(kps, ColorSequenceKeypoint.new(k[1], k[2])) end
			seq = ColorSequence.new(kps)
		end
		local g = UI.new("UIGradient", { Color = seq, Rotation = rot or 90, Parent = obj })
		if transp then
			local kps = {}
			for _, k in transp do table.insert(kps, NumberSequenceKeypoint.new(k[1], k[2])) end
			g.Transparency = NumberSequence.new(kps)
		end
		return g
	end
	local FADE_X = { { 0, 1 }, { 0.25, 0 }, { 0.75, 0 }, { 1, 1 } } -- soft ends left/right
	local function loop(obj, t, props, delay)
		TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, delay or 0), props):Play()
	end
	local function drift(obj, t, props, delay)
		TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false, delay or 0), props):Play()
	end
	local NIGHT, DUSK = Color3.fromRGB(10, 14, 30), Color3.fromRGB(96, 54, 72)
	local function lit(c, k)
		k = k or 0.78
		if night then return c:Lerp(NIGHT, k) end
		if evening then return c:Lerp(DUSK, k * 0.38) end
		return c
	end

	local scene = fr({ BackgroundColor3 = Color3.new(0, 0, 0), Position = UDim2.fromOffset(30, 76), Size = UDim2.fromOffset(W, H), ClipsDescendants = true, Parent = parent })
	UI.stroke(C.wood, 6).Parent = scene

	------------------------------------------------------------------ sky
	local skyTop, skyMid, skyLow
	if night then
		skyTop, skyMid, skyLow = Color3.fromRGB(4, 6, 16), Color3.fromRGB(14, 20, 44), Color3.fromRGB(46, 54, 88)
	elseif evening then
		skyTop, skyMid, skyLow = Color3.fromRGB(38, 46, 96), Color3.fromRGB(156, 106, 132), Color3.fromRGB(252, 180, 112)
	else
		skyTop, skyMid, skyLow = Color3.fromRGB(80, 134, 190), Color3.fromRGB(142, 182, 216), Color3.fromRGB(224, 234, 234)
	end
	local function haze(c, a) return c:Lerp(skyLow, a) end
	local sky = fr({ BackgroundColor3 = WHITE, Size = UDim2.new(1, 0, 0, HORIZON + 4), Parent = scene })
	grad(sky, { { 0, skyTop }, { 0.62, skyMid }, { 1, skyLow } })

	if night then
		for i = 1, 70 do
			local big = i % 9 == 0
			local sz = big and 3 or rng:NextInteger(1, 2)
			local st = round(fr({ BackgroundColor3 = Color3.fromRGB(232, 234, 255), BackgroundTransparency = rng:NextNumber(0.05, 0.65),
				Position = UDim2.fromOffset(rng:NextInteger(2, W - 2), rng:NextInteger(2, 190)), Size = UDim2.fromOffset(sz, sz), Parent = scene }))
			if big then
				round(fr({ BackgroundColor3 = Color3.fromRGB(200, 210, 255), BackgroundTransparency = 0.93, AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(9, 9), Parent = st }))
			end
			if i % 4 == 0 then loop(st, rng:NextNumber(1.2, 2.8), { BackgroundTransparency = 0.92 }) end
		end
	end

	-- sun or moon with a soft glow
	local lx, ly, lightCol = 84, 64, Color3.fromRGB(255, 246, 222)
	if night then lightCol = Color3.fromRGB(226, 230, 214)
	elseif evening then lx, ly, lightCol = 92, 200, Color3.fromRGB(255, 188, 118) end
	for i = 16, 1, -1 do
		local r = 22 + i * (night and 6 or 9)
		round(fr({ BackgroundColor3 = lightCol, BackgroundTransparency = night and 0.982 or 0.975, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(lx, ly), Size = UDim2.fromOffset(r * 2, r * 2), Parent = scene }))
	end
	local disc = round(fr({ BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(lx, ly),
		Size = UDim2.fromOffset(night and 34 or 42, night and 34 or 42), Parent = scene }))
	if night then
		grad(disc, { Color3.fromRGB(248, 246, 232), Color3.fromRGB(198, 196, 182) }, 45)
		for _, c in { { 8, 9, 8 }, { 19, 17, 6 }, { 12, 22, 4 }, { 22, 7, 3 } } do
			round(fr({ BackgroundColor3 = Color3.fromRGB(176, 174, 160), BackgroundTransparency = 0.55, Position = UDim2.fromOffset(c[1], c[2]), Size = UDim2.fromOffset(c[3], c[3]), Parent = disc }))
		end
	else
		grad(disc, { lightCol:Lerp(WHITE, 0.4), lightCol }, 45)
	end

	-- clouds: opaque puffs inside a CanvasGroup so the whole cloud fades softly
	local function cloud(x, y, s, alpha)
		local top, bottom
		if night then top, bottom = Color3.fromRGB(52, 58, 86), Color3.fromRGB(24, 28, 48)
		elseif evening then top, bottom = Color3.fromRGB(255, 226, 206), Color3.fromRGB(178, 120, 140)
		else top, bottom = WHITE, Color3.fromRGB(198, 208, 226) end
		local cg = UI.new("CanvasGroup", { BackgroundTransparency = 1, GroupTransparency = alpha, Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(150 * s, 56 * s), Parent = scene })
		for _, b in { { 0, 24, 54, 28 }, { 20, 10, 52, 40 }, { 50, 0, 60, 50 }, { 92, 12, 50, 38 }, { 10, 30, 124, 24 } } do
			local p = round(fr({ BackgroundColor3 = WHITE, Position = UDim2.fromOffset(b[1] * s, b[2] * s), Size = UDim2.fromOffset(b[3] * s, b[4] * s), Parent = cg }))
			grad(p, { top, bottom })
		end
		drift(cg, 90 + rng:NextInteger(0, 60), { Position = cg.Position + UDim2.fromOffset(120, 0) })
		return cg
	end
	if night then
		cloud(150, 60, 1.1, 0.55); cloud(-40, 140, 0.9, 0.6)
	else
		cloud(150, 40, 1.0, 0.08); cloud(-30, 110, 0.75, 0.15); cloud(250, 120, 0.6, 0.2)
	end

	------------------------------------------------------------------ distance
	-- hills, hazier the further they are
	for layer = 1, 2 do
		local col = haze(lit(Color3.fromRGB(70, 98, 86), 0.7), layer == 1 and 0.62 or 0.38)
		local x = -80
		while x < W + 40 do
			local w = rng:NextInteger(170, 260)
			local h = rng:NextInteger(60, 90) - layer * 14
			local hill = round(fr({ BackgroundColor3 = WHITE, Position = UDim2.fromOffset(x, HORIZON - 14 - h * 0.5 + layer * 8), Size = UDim2.fromOffset(w, h), Parent = scene }))
			grad(hill, { col:Lerp(WHITE, 0.06), col })
			x += math.floor(w * 0.62)
		end
	end

	local function house(x, baseY, w, h, roofCol, wallCol)
		local roofS = w * 0.72
		local roof = fr({ BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45,
			Position = UDim2.fromOffset(x + w / 2, baseY - h), Size = UDim2.fromOffset(roofS, roofS), Parent = scene })
		grad(roof, { roofCol:Lerp(WHITE, 0.12), roofCol:Lerp(Color3.new(0, 0, 0), 0.25) }, 45)
		local wall = fr({ BackgroundColor3 = WHITE, Position = UDim2.fromOffset(x, baseY - h), Size = UDim2.fromOffset(w, h), Parent = scene })
		grad(wall, { wallCol, wallCol:Lerp(Color3.new(0, 0, 0), 0.22) }, 0)
		local win = fr({ BackgroundColor3 = night and Color3.fromRGB(255, 210, 130) or lit(Color3.fromRGB(70, 80, 96)), Position = UDim2.fromOffset(x + w * 0.35, baseY - h * 0.7),
			Size = UDim2.fromOffset(math.max(4, w * 0.25), math.max(4, h * 0.3)), Parent = scene })
		if night and rng:NextNumber() < 0.4 then win.BackgroundColor3 = lit(Color3.fromRGB(70, 80, 96)) end
	end

	if pid == "pipe" then
		-- fertiliser plant behind the trees
		local wallA, wallB = lit(Color3.fromRGB(132, 136, 142), 0.66), lit(Color3.fromRGB(84, 88, 96), 0.66)
		local side = fr({ BackgroundColor3 = WHITE, Position = UDim2.fromOffset(150, 176), Size = UDim2.fromOffset(60, 54), Parent = scene })
		grad(side, { wallA:Lerp(wallB, 0.3), wallB }, 0)
		local hall = fr({ BackgroundColor3 = WHITE, Position = UDim2.fromOffset(200, 150), Size = UDim2.fromOffset(140, 80), Parent = scene })
		grad(hall, { wallA, wallB }, 0)
		fr({ BackgroundColor3 = lit(Color3.fromRGB(164, 166, 170), 0.66), Position = UDim2.fromOffset(196, 146), Size = UDim2.fromOffset(148, 5), Parent = scene })
		-- silo
		local silo = round(fr({ BackgroundColor3 = WHITE, Position = UDim2.fromOffset(344, 124), Size = UDim2.fromOffset(34, 106), Parent = scene }), UDim.new(0, 10))
		grad(silo, { { 0, wallB }, { 0.35, wallA:Lerp(WHITE, 0.08) }, { 1, wallB:Lerp(Color3.new(0, 0, 0), 0.2) } }, 0)
		-- chimneys with warning bands
		for _, ch in { { 296, 64, 14 }, { 318, 92, 10 } } do
			local c = fr({ BackgroundColor3 = WHITE, Position = UDim2.fromOffset(ch[1], ch[2]), Size = UDim2.fromOffset(ch[3], 152 - ch[2]), Parent = scene })
			grad(c, { { 0, wallB }, { 0.4, wallA }, { 1, wallB } }, 0)
			for k = 0, 1 do
				fr({ BackgroundColor3 = lit(Color3.fromRGB(176, 60, 50), 0.6), Position = UDim2.fromOffset(0, 6 + k * 12), Size = UDim2.new(1, 0, 0, 5), Parent = c })
			end
			if night then
				local beacon = round(fr({ BackgroundColor3 = Color3.fromRGB(255, 60, 50), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(4, 4), Parent = c }))
				local bglow = round(fr({ BackgroundColor3 = Color3.fromRGB(255, 70, 60), BackgroundTransparency = 0.82, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 10), Parent = beacon }))
				loop(bglow, 0.9, { BackgroundTransparency = 1 })
			end
			-- smoke plume
			local smoke = UI.new("CanvasGroup", { BackgroundTransparency = 1, GroupTransparency = night and 0.55 or 0.3,
				Position = UDim2.fromOffset(ch[1] - 20, ch[2] - 80), Size = UDim2.fromOffset(120, 84), Parent = scene })
			local sc = night and Color3.fromRGB(78, 80, 96) or Color3.fromRGB(226, 226, 222)
			for k = 1, 6 do
				local p = round(fr({ BackgroundColor3 = WHITE, Position = UDim2.fromOffset(14 + k * 12, 66 - k * 11), Size = UDim2.fromOffset(16 + k * 7, 13 + k * 5), Parent = smoke }))
				grad(p, { sc, sc:Lerp(Color3.new(0, 0, 0), 0.15) })
				loop(p, 2.4 + k * 0.5, { Position = p.Position + UDim2.fromOffset(6, -4), Size = p.Size + UDim2.fromOffset(6, 3) })
			end
		end
		-- windows
		for r = 0, 1 do
			for c = 0, 7 do
				local on = night and ((r * 3 + c) % 4 ~= 0)
				local wcol = on and Color3.fromRGB(255, 208, 120) or lit(Color3.fromRGB(64, 72, 84), 0.66)
				local wx, wy = 210 + c * 16, 166 + r * 22
				if on then
					for g = 1, 3 do
						round(fr({ BackgroundColor3 = Color3.fromRGB(255, 196, 110), BackgroundTransparency = 0.955, AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromOffset(wx + 4, wy + 4), Size = UDim2.fromOffset(8 + g * 6, 8 + g * 5), Parent = scene }))
					end
				end
				fr({ BackgroundColor3 = wcol, Position = UDim2.fromOffset(wx, wy), Size = UDim2.fromOffset(8, 9), Parent = scene })
			end
		end
	elseif pid == "beach" or pid == "farm" then
		for i = 0, 5 do
			local x = 24 + i * 62 + rng:NextInteger(-8, 8)
			local w, h = rng:NextInteger(26, 36), rng:NextInteger(16, 24)
			house(x, HORIZON - 14, w, h, lit(Color3.fromRGB(150, 72, 60), 0.7), lit(Color3.fromRGB(214, 204, 186), 0.7))
		end
	end

	-- tree line: far (hazy) then near (darker), each tree three clumps lit from the upper left
	local function tree(x, baseY, size, col)
		local hi = col:Lerp(WHITE, night and 0.05 or 0.22)
		local lo = col:Lerp(Color3.new(0, 0, 0), 0.3)
		for _, b in { { 0, 0.4, 1, 0.7 }, { 0.12, 0.08, 0.76, 0.68 }, { 0.42, 0.24, 0.62, 0.6 } } do
			local blob = round(fr({ BackgroundColor3 = WHITE, Position = UDim2.fromOffset(x + size * b[1], baseY - size + size * b[2]),
				Size = UDim2.fromOffset(size * b[3], size * b[4]), Parent = scene }))
			grad(blob, { hi, lo }, 60)
		end
	end
	local greens = { Color3.fromRGB(56, 88, 58), Color3.fromRGB(66, 100, 62), Color3.fromRGB(48, 76, 52) }
	local x = -20
	while x < W + 10 do
		local size = rng:NextInteger(26, 40)
		tree(x, HORIZON - 6, size, haze(lit(greens[rng:NextInteger(1, 3)], 0.8), 0.35))
		x += rng:NextInteger(14, 24)
	end
	x = -24
	while x < W + 10 do
		local size = rng:NextInteger(38, 62)
		local blocked = pid == "pipe" and x > 150 and x < 380
		if not blocked then tree(x, HORIZON - 2, size, lit(greens[rng:NextInteger(1, 3)], 0.82)) end
		x += rng:NextInteger(22, 40)
	end

	------------------------------------------------------------------ far bank
	local bankTop = pid == "farm" and HORIZON - 26 or HORIZON - 12
	local bank = fr({ BackgroundColor3 = WHITE, Position = UDim2.fromOffset(0, bankTop), Size = UDim2.new(1, 0, 0, HORIZON - bankTop + 2), Parent = scene })
	if pid == "beach" then
		grad(bank, { { 0, lit(Color3.fromRGB(230, 214, 170)) }, { 0.7, lit(Color3.fromRGB(206, 188, 144)) }, { 1, lit(Color3.fromRGB(162, 146, 110)) } })
		-- sign and lifebuoy
		local post = fr({ BackgroundColor3 = lit(Color3.fromRGB(110, 80, 52)), Position = UDim2.fromOffset(348, bankTop - 36), Size = UDim2.fromOffset(3, 40), Parent = scene })
		local sign = fr({ BackgroundColor3 = lit(Color3.fromRGB(240, 240, 232)), Position = UDim2.fromOffset(328, bankTop - 44), Size = UDim2.fromOffset(44, 16), Parent = scene })
		UI.stroke(lit(Color3.fromRGB(40, 90, 170)), 1).Parent = sign
		UI.text({ Text = "BEACH", FontFace = F.mono, TextSize = 8, TextColor3 = lit(Color3.fromRGB(40, 90, 170)), TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = sign })
		local buoy = round(fr({ BackgroundTransparency = 1, Position = UDim2.fromOffset(26, bankTop - 6), Size = UDim2.fromOffset(16, 16), Parent = scene }))
		UI.stroke(lit(Color3.fromRGB(232, 92, 52)), 4).Parent = buoy
	elseif pid == "farm" then
		grad(bank, { lit(Color3.fromRGB(142, 156, 86)), lit(Color3.fromRGB(104, 116, 62)) })
		for i = 0, 20 do
			local row = fr({ BackgroundColor3 = lit(Color3.fromRGB(92, 76, 50)), BackgroundTransparency = 0.45, Position = UDim2.fromOffset(i * 22 - 30, bankTop + 2),
				Size = UDim2.fromOffset(2, 30), Rotation = 52, Parent = scene })
			grad(row, { WHITE, WHITE }, 90, { { 0, 0.6 }, { 1, 0 } })
		end
	else
		grad(bank, { lit(Color3.fromRGB(98, 128, 74)), lit(Color3.fromRGB(62, 84, 52)) })
	end
	-- shoreline glint
	local glint = fr({ BackgroundColor3 = skyLow:Lerp(WHITE, 0.3), BackgroundTransparency = night and 0.6 or 0.35, Position = UDim2.fromOffset(0, HORIZON), Size = UDim2.new(1, 0, 0, 1), Parent = scene })
	grad(glint, { WHITE, WHITE }, 0, { { 0, 0.6 }, { 0.3, 0 }, { 0.7, 0.2 }, { 1, 0.7 } })

	------------------------------------------------------------------ water
	local waterColor = o.clean:Lerp(o.murky, math.clamp((o.value - 0.1) / 4.9, 0, 1))
	local surf = skyLow:Lerp(waterColor, 0.5)
	local deep = waterColor:Lerp(Color3.new(0, 0, 0), night and 0.72 or 0.4)
	if night then surf = surf:Lerp(Color3.new(0, 0, 0), 0.4) end
	local water = fr({ BackgroundColor3 = WHITE, Position = UDim2.fromOffset(0, HORIZON + 1), Size = UDim2.new(1, 0, 1, -HORIZON - 1), Parent = scene })
	grad(water, { { 0, surf }, { 0.35, surf:Lerp(deep, 0.55) }, { 1, deep } })
	-- reflection of the far shore, breaking up as it fades
	local refl = fr({ BackgroundColor3 = lit(Color3.fromRGB(38, 60, 44), 0.8), Position = UDim2.fromOffset(0, HORIZON + 1), Size = UDim2.new(1, 0, 0, 46), Parent = scene })
	grad(refl, { WHITE, WHITE }, 90, { { 0, 0.25 }, { 1, 1 } })
	if pid == "pipe" then
		local prefl = fr({ BackgroundColor3 = lit(Color3.fromRGB(90, 94, 102), 0.66), Position = UDim2.fromOffset(200, HORIZON + 1), Size = UDim2.fromOffset(140, 30), Parent = scene })
		grad(prefl, { WHITE, WHITE }, 90, { { 0, 0.45 }, { 1, 1 } })
		if night then
			for c = 0, 7 do
				if c % 4 ~= 0 then
					local s = fr({ BackgroundColor3 = Color3.fromRGB(255, 200, 120), Position = UDim2.fromOffset(211 + c * 16, HORIZON + 3), Size = UDim2.fromOffset(5, 30), Parent = scene })
					grad(s, { WHITE, WHITE }, 90, { { 0, 0.7 }, { 1, 1 } })
					loop(s, rng:NextNumber(0.8, 1.4), { Size = UDim2.fromOffset(3, 24) })
				end
			end
		end
	end
	-- sun / moon path on the water
	for i = 0, 13 do
		local y = HORIZON + 4 + math.floor((i / 13) ^ 1.4 * 150)
		local w = math.floor((i < 3 and 34 or 52 - i * 2) * rng:NextNumber(0.6, 1.1))
		local d = fr({ BackgroundColor3 = lightCol, BackgroundTransparency = 0.2 + i * 0.045, AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromOffset(lx + rng:NextInteger(-6, 6), y), Size = UDim2.fromOffset(w, i > 8 and 2 or 1), Parent = scene })
		grad(d, { WHITE, WHITE }, 0, FADE_X)
		loop(d, rng:NextNumber(0.7, 1.5), { Size = UDim2.fromOffset(math.floor(w * 0.55), d.Size.Y.Offset) })
	end
	-- ripples: denser and thinner far away, longer near
	for i = 1, 30 do
		local t = i / 30
		local y = HORIZON + 6 + math.floor(t ^ 1.5 * 186)
		local len = math.floor(18 + t * 70 * rng:NextNumber(0.6, 1.2))
		local rp = fr({ BackgroundColor3 = night and Color3.fromRGB(140, 150, 196) or skyLow:Lerp(WHITE, 0.4),
			BackgroundTransparency = 0.45 + rng:NextNumber(0, 0.3), Position = UDim2.fromOffset(rng:NextInteger(-30, W), y),
			Size = UDim2.fromOffset(len, t > 0.7 and 2 or 1), Parent = scene })
		grad(rp, { WHITE, WHITE }, 0, FADE_X)
		loop(rp, rng:NextNumber(2.2, 4.5), { Position = rp.Position + UDim2.fromOffset(rng:NextInteger(10, 26), 0) })
	end
	if night then
		local mist = fr({ BackgroundColor3 = Color3.fromRGB(130, 140, 176), Position = UDim2.fromOffset(-60, HORIZON - 14), Size = UDim2.new(1, 120, 0, 30), Parent = scene })
		grad(mist, { WHITE, WHITE }, 90, { { 0, 1 }, { 0.5, 0.82 }, { 1, 1 } })
		loop(mist, 9, { Position = mist.Position + UDim2.fromOffset(40, 0) })
	end

	------------------------------------------------------------------ outfall
	-- concrete headwall with a round pipe seen from the front, water pouring into the river
	local function outfall(cx, s, dirty, label)
		local hwH = math.floor(60 * s)
		local topY = HORIZON + 4 - hwH
		local stoneA, stoneB = lit(Color3.fromRGB(150, 146, 136), 0.6), lit(Color3.fromRGB(80, 76, 70), 0.6)
		for k = 1, math.floor(9 * s) + 5 do
			local sw = math.floor(rng:NextInteger(10, 20) * s)
			local st = round(fr({ BackgroundColor3 = WHITE, Position = UDim2.fromOffset(cx - 74 * s + rng:NextInteger(0, math.floor(148 * s)), topY + hwH - 18 * s + rng:NextInteger(0, math.floor(12 * s))),
				Size = UDim2.fromOffset(sw, math.floor(sw * 0.7)), Parent = scene }))
			grad(st, { stoneA, stoneB }, 70)
		end
		local hw = fr({ BackgroundColor3 = WHITE, Position = UDim2.fromOffset(cx - 52 * s, topY), Size = UDim2.fromOffset(104 * s, hwH), Parent = scene })
		grad(hw, { { 0, lit(Color3.fromRGB(184, 180, 170), 0.58) }, { 1, lit(Color3.fromRGB(110, 106, 98), 0.58) } })
		local capping = fr({ BackgroundColor3 = WHITE, Position = UDim2.fromOffset(cx - 56 * s, topY - 6 * s), Size = UDim2.fromOffset(112 * s, 7 * s), Parent = scene })
		grad(capping, { lit(Color3.fromRGB(210, 206, 196), 0.58), lit(Color3.fromRGB(150, 146, 138), 0.58) })
		for k = 1, 2 do
			fr({ BackgroundColor3 = lit(Color3.fromRGB(86, 82, 76), 0.58), BackgroundTransparency = 0.55, Position = UDim2.fromOffset(cx - 52 * s + k * 35 * s, topY), Size = UDim2.fromOffset(1, hwH), Parent = scene })
		end
		local R = math.floor(18 * s)
		local cy = topY + math.floor(26 * s)
		if dirty then
			for k = -1, 1 do
				local stain = fr({ BackgroundColor3 = Color3.fromRGB(118, 82, 42), Position = UDim2.fromOffset(cx + k * 10 * s - 3 * s, cy + R - 2), Size = UDim2.fromOffset(6 * s, hwH - 26 * s - R + 4), Parent = scene })
				grad(stain, { WHITE, WHITE }, 90, { { 0, 0.35 }, { 1, 1 } })
			end
		end
		local moss = fr({ BackgroundColor3 = lit(Color3.fromRGB(64, 92, 50), 0.6), Position = UDim2.fromOffset(cx - 52 * s, topY + hwH - 10 * s), Size = UDim2.fromOffset(104 * s, 10 * s), Parent = scene })
		grad(moss, { WHITE, WHITE }, 90, { { 0, 0.9 }, { 1, 0.15 } })
		if label then
			local plate = fr({ BackgroundColor3 = lit(Color3.fromRGB(226, 222, 206), 0.5), Position = UDim2.fromOffset(cx + 26 * s, topY + 8 * s), Size = UDim2.fromOffset(20 * s, 11 * s), Parent = scene })
			UI.text({ Text = label, FontFace = F.mono, TextSize = math.max(6, math.floor(7 * s)), TextColor3 = lit(Color3.fromRGB(40, 40, 40), 0.5),
				TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = plate })
		end
		-- the pipe mouth: outer rim, dark bore, a crescent of water along the bottom
		local rim = round(fr({ BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(R * 2 + 8 * s, R * 2 + 8 * s), Parent = scene }))
		grad(rim, { lit(Color3.fromRGB(214, 210, 200), 0.55), lit(Color3.fromRGB(108, 104, 96), 0.55) }, 115)
		local bore = round(fr({ BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(R * 2, R * 2), Parent = scene }))
		grad(bore, { Color3.fromRGB(6, 6, 6), Color3.fromRGB(46, 42, 36) })
		local inner = round(fr({ BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(R * 2 - 6, R * 2 - 6), Parent = scene }))
		UI.stroke(Color3.fromRGB(70, 66, 58), 1, 0.5).Parent = inner
		local flowCol = dirty and Color3.fromRGB(156, 142, 98) or Color3.fromRGB(176, 206, 216)
		local foamCol = dirty and Color3.fromRGB(236, 228, 196) or Color3.fromRGB(236, 246, 250)
		local crescent = round(fr({ BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromOffset(cx, cy + R - 1),
			Size = UDim2.fromOffset(math.floor(R * 1.5), math.floor((dirty and 9 or 5) * s)), Parent = scene }))
		grad(crescent, { flowCol:Lerp(WHITE, 0.15), flowCol })
		-- falling water
		local fallTop = cy + R - 3
		local streamW = math.floor((dirty and 18 or 8) * s)
		local stream = fr({ BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0), ClipsDescendants = true, Position = UDim2.fromOffset(cx, fallTop),
			Size = UDim2.fromOffset(streamW, HORIZON + 6 - fallTop), Parent = scene })
		UI.corner(UDim.new(0, 3)).Parent = stream
		grad(stream, { flowCol, flowCol:Lerp(foamCol, 0.5) }, 90, { { 0, 0.05 }, { 1, 0.3 } })
		for k = 0, 2 do
			local streak = fr({ BackgroundColor3 = foamCol, BackgroundTransparency = 0.35, Position = UDim2.new(0, 2 + k * math.max(2, streamW / 3 - 1), 0, -10),
				Size = UDim2.fromOffset(2, 8), Parent = stream })
			drift(streak, 0.5 + k * 0.12, { Position = UDim2.new(0, streak.Position.X.Offset, 1, 4) }, k * 0.15)
		end
		-- splash and foam
		for k = 1, dirty and 9 or 4 do
			local fw = math.floor(rng:NextInteger(5, 12) * s)
			local foam = round(fr({ BackgroundColor3 = foamCol, BackgroundTransparency = rng:NextNumber(0.15, 0.45), AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(cx + rng:NextInteger(-14, 14) * s, HORIZON + 5 + rng:NextInteger(-2, 4)), Size = UDim2.fromOffset(fw, math.floor(fw * 0.55)), Parent = scene }))
			loop(foam, rng:NextNumber(0.5, 1.1), { Size = UDim2.fromOffset(math.floor(fw * 1.3), math.floor(fw * 0.7)), BackgroundTransparency = 0.7 })
		end
		if dirty then
			-- a murky plume spreading downstream (towards the left and towards you)
			local plume = UI.new("CanvasGroup", { BackgroundTransparency = 1, GroupTransparency = night and 0.45 or 0.4,
				Position = UDim2.fromOffset(0, HORIZON + 2), Size = UDim2.fromOffset(W, 120), Parent = scene })
			local pc = lit(Color3.fromRGB(170, 156, 108), 0.5)
			for k = 1, 8 do
				local w = 50 + k * 18
				local p = round(fr({ BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset(cx - 6 - k * 17, 8 + k * 9), Size = UDim2.fromOffset(w, 10 + k * 4), Parent = plume }))
				grad(p, { pc, pc:Lerp(waterColor, 0.4) }, 0, { { 0, 1 }, { 0.3, 0.2 + k * 0.06 }, { 0.7, 0.25 + k * 0.06 }, { 1, 1 } })
				loop(p, 2.6 + k * 0.35, { Position = p.Position + UDim2.fromOffset(-12, 3) })
			end
			for k = 1, 12 do
				local f = round(fr({ BackgroundColor3 = foamCol, BackgroundTransparency = 0.2, Position = UDim2.fromOffset(cx - rng:NextInteger(10, 120), rng:NextInteger(4, 70)),
					Size = UDim2.fromOffset(rng:NextInteger(2, 5), 2), Parent = plume }))
				drift(f, rng:NextNumber(4, 7), { Position = f.Position + UDim2.fromOffset(-40, 12), BackgroundTransparency = 1 }, rng:NextNumber(0, 3))
			end
		end
		return topY
	end

	if pid == "pipe" then
		local topY = outfall(338, 0.95, night, "ZD-03")
		if night then
			-- security lamp above the outfall, lighting the concrete
			local pole = fr({ BackgroundColor3 = lit(Color3.fromRGB(70, 70, 74), 0.5), Position = UDim2.fromOffset(384, topY - 58), Size = UDim2.fromOffset(3, 58), Parent = scene })
			local head = fr({ BackgroundColor3 = Color3.fromRGB(60, 60, 64), Position = UDim2.fromOffset(370, topY - 60), Size = UDim2.fromOffset(18, 4), Parent = scene })
			round(fr({ BackgroundColor3 = Color3.fromRGB(255, 236, 190), Position = UDim2.fromOffset(372, topY - 56), Size = UDim2.fromOffset(10, 3), Parent = scene }))
			local cone = fr({ BackgroundColor3 = Color3.fromRGB(255, 232, 170), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(372, topY - 54), Size = UDim2.fromOffset(90, 80), Parent = scene })
			grad(cone, { WHITE, WHITE }, 90, { { 0, 0.72 }, { 1, 1 } })
			for i = 8, 1, -1 do
				round(fr({ BackgroundColor3 = Color3.fromRGB(255, 230, 170), BackgroundTransparency = 0.97, AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset(377, topY - 55), Size = UDim2.fromOffset(6 + i * 6, 6 + i * 6), Parent = scene }))
			end
		end
		-- a dead fish drifting near the outfall
		local fish = fr({ BackgroundTransparency = 1, Position = UDim2.fromOffset(238, HORIZON + 34), Size = UDim2.fromOffset(30, 12), Rotation = -6, Parent = scene })
		local body = round(fr({ BackgroundColor3 = WHITE, Size = UDim2.fromOffset(24, 9), Position = UDim2.fromOffset(6, 1), Parent = fish }))
		grad(body, { lit(Color3.fromRGB(226, 228, 220), 0.55), lit(Color3.fromRGB(150, 156, 150), 0.55) })
		fr({ BackgroundColor3 = lit(Color3.fromRGB(170, 174, 166), 0.55), Rotation = 45, Position = UDim2.fromOffset(0, 2), Size = UDim2.fromOffset(7, 7), Parent = fish })
		round(fr({ BackgroundColor3 = Color3.fromRGB(30, 30, 30), Position = UDim2.fromOffset(25, 3), Size = UDim2.fromOffset(2, 2), Parent = fish }))
		loop(fish, 2.2, { Position = fish.Position + UDim2.fromOffset(-4, 2), Rotation = -2 })
	elseif pid == "farm" then
		outfall(66, 0.45, false, nil)
	elseif pid == "up" then
		-- a few rocks breaking the current
		for k = 1, 3 do
			local rx, ry = 250 + k * 34, HORIZON + 22 + k * 12
			local rock = round(fr({ BackgroundColor3 = WHITE, Position = UDim2.fromOffset(rx, ry), Size = UDim2.fromOffset(22 + k * 6, 10 + k * 3), Parent = scene }))
			grad(rock, { lit(Color3.fromRGB(160, 156, 146), 0.6), lit(Color3.fromRGB(76, 72, 66), 0.6) }, 70)
			local wake = fr({ BackgroundColor3 = WHITE, BackgroundTransparency = 0.4, Position = UDim2.fromOffset(rx - 16, ry + 8 + k), Size = UDim2.fromOffset(20, 1), Parent = scene })
			grad(wake, { WHITE, WHITE }, 0, FADE_X)
			loop(wake, 1.2, { Position = wake.Position + UDim2.fromOffset(-8, 0), BackgroundTransparency = 0.8 })
		end
	end

	------------------------------------------------------------------ torch (night)
	local torch = UI.new("CanvasGroup", { BackgroundTransparency = 1, GroupTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = scene })
	for i = 14, 1, -1 do
		round(fr({ BackgroundColor3 = Color3.fromRGB(255, 232, 176), BackgroundTransparency = 0.97, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(160, 300), Size = UDim2.fromOffset(40 + i * 18, 34 + i * 15), Parent = torch }))
	end

	------------------------------------------------------------------ sample bottle
	local jar = fr({ BackgroundColor3 = Color3.fromRGB(226, 240, 246), BackgroundTransparency = 0.45, AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, -40, 1, -40), Size = UDim2.fromOffset(130, 170), ZIndex = 3, Parent = scene })
	UI.corner(18).Parent = jar
	grad(jar, { WHITE, WHITE }, 0, { { 0, 0.15 }, { 0.12, 0.7 }, { 0.5, 0.93 }, { 0.88, 0.7 }, { 1, 0.2 } })
	UI.stroke(Color3.fromRGB(240, 248, 252), 1.5, 0.3).Parent = jar
	local neck = fr({ BackgroundColor3 = Color3.fromRGB(226, 240, 246), BackgroundTransparency = 0.45, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, 3),
		Size = UDim2.fromOffset(62, 18), ZIndex = 3, Parent = jar })
	UI.corner(4).Parent = neck
	grad(neck, { WHITE, WHITE }, 0, { { 0, 0.2 }, { 0.2, 0.75 }, { 0.8, 0.75 }, { 1, 0.25 } })
	UI.stroke(Color3.fromRGB(240, 248, 252), 1.5, 0.3).Parent = neck
	for k = 0, 1 do
		fr({ BackgroundColor3 = WHITE, BackgroundTransparency = 0.55, Position = UDim2.fromOffset(4, 4 + k * 5), Size = UDim2.new(1, -8, 0, 1), ZIndex = 3, Parent = neck })
	end
	local cap = fr({ BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -60), Size = UDim2.fromOffset(70, 20), Visible = false, ZIndex = 6, Parent = jar })
	UI.corner(4).Parent = cap
	grad(cap, { Color3.fromRGB(60, 96, 160), Color3.fromRGB(24, 46, 96) })
	for k = 0, 6 do
		fr({ BackgroundColor3 = Color3.fromRGB(16, 32, 70), BackgroundTransparency = 0.3, Position = UDim2.fromOffset(6 + k * 10, 3), Size = UDim2.fromOffset(2, 14), ZIndex = 6, Parent = cap })
	end
	local JAR_INNER = 158
	local jarWater = fr({ BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 6, 1, -6), BackgroundTransparency = 0.12,
		Size = UDim2.new(1, -12, 0, 0), ZIndex = 3, ClipsDescendants = true, Parent = jar })
	UI.corner(12).Parent = jarWater
	grad(jarWater, { waterColor:Lerp(WHITE, 0.2), waterColor:Lerp(Color3.new(0, 0, 0), 0.25) })
	local meniscus = fr({ BackgroundColor3 = WHITE, BackgroundTransparency = 0.35, Size = UDim2.new(1, 0, 0, 2), ZIndex = 4, Parent = jarWater })
	grad(meniscus, { WHITE, WHITE }, 0, { { 0, 0 }, { 0.5, 0.6 }, { 1, 0 } })
	if o.value > 1.5 then
		for k = 1, 10 do
			round(fr({ BackgroundColor3 = Color3.fromRGB(120, 104, 60), BackgroundTransparency = 0.4, Position = UDim2.new(rng:NextNumber(0.1, 0.9), 0, 1, -rng:NextInteger(6, 100)),
				Size = UDim2.fromOffset(3, 3), ZIndex = 4, Parent = jarWater }))
		end
	end
	for _, lv in { o.fillMin, o.fillMax } do
		fr({ BackgroundColor3 = C.redBright, BackgroundTransparency = 0.25, Position = UDim2.new(0, 8, 1, -6 - math.floor(JAR_INNER * lv)),
			Size = UDim2.new(1, -16, 0, 2), ZIndex = 5, Parent = jar })
	end
	for ml = 100, 400, 100 do
		local y = -6 - math.floor(JAR_INNER * ml / 450)
		fr({ BackgroundColor3 = WHITE, BackgroundTransparency = 0.3, Position = UDim2.new(1, -20, 1, y), Size = UDim2.fromOffset(12, 1), ZIndex = 5, Parent = jar })
		UI.text({ Text = tostring(ml), FontFace = F.mono, TextSize = 9, TextColor3 = WHITE, TextTransparency = 0.25, TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.new(1, -52, 1, y - 6), Size = UDim2.fromOffset(30, 12), ZIndex = 5, Parent = jar })
	end
	local hl = fr({ BackgroundColor3 = WHITE, BackgroundTransparency = 0.35, Position = UDim2.fromOffset(11, 16), Size = UDim2.new(0, 7, 1, -34), ZIndex = 5, Parent = jar })
	grad(hl, { WHITE, WHITE }, 90, { { 0, 1 }, { 0.15, 0.1 }, { 0.8, 0.3 }, { 1, 1 } })
	local hl2 = fr({ BackgroundColor3 = WHITE, BackgroundTransparency = 0.6, Position = UDim2.fromOffset(22, 22), Size = UDim2.new(0, 3, 1, -60), ZIndex = 5, Parent = jar })
	grad(hl2, { WHITE, WHITE }, 90, { { 0, 1 }, { 0.3, 0 }, { 1, 1 } })
	local seal = fr({ BackgroundColor3 = C.red, Visible = false, Position = UDim2.new(0, -6, 0, -4), Size = UDim2.new(1, 12, 0, 10), Rotation = -4, ZIndex = 7, Parent = neck })
	local jarLabel = fr({ BackgroundColor3 = C.manila, Visible = false, Position = UDim2.fromOffset(28, 40), Size = UDim2.fromOffset(76, 44), Rotation = -2, ZIndex = 6, Parent = jar })
	local jarLabelText = UI.text({ Text = "", FontFace = F.handBold, TextSize = 13, TextColor3 = C.blue, TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = jarLabel })

	------------------------------------------------------------------ near water + foreground
	local NEAR = 336
	local front = fr({ BackgroundColor3 = WHITE, BackgroundTransparency = 0.32, Position = UDim2.fromOffset(0, NEAR), Size = UDim2.new(1, 0, 1, -NEAR), ZIndex = 4, Parent = scene })
	grad(front, { surf:Lerp(deep, 0.5), deep })
	local frontEdge = fr({ BackgroundColor3 = WHITE, BackgroundTransparency = 0.5, Position = UDim2.fromOffset(0, NEAR), Size = UDim2.new(1, 0, 0, 1), ZIndex = 4, Parent = scene })
	grad(frontEdge, { WHITE, WHITE }, 0, { { 0, 1 }, { 0.2, 0.6 }, { 0.42, 0 }, { 0.6, 0 }, { 0.8, 0.6 }, { 1, 1 } })
	for side = -1, 1, 2 do
		for k = 0, 2 do
			local r = fr({ BackgroundColor3 = WHITE, BackgroundTransparency = 0.45 + k * 0.15, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(160 + side * (70 + k * 12), NEAR + 2 + k * 5), Size = UDim2.fromOffset(22 - k * 5, 2), ZIndex = 4, Parent = scene })
			grad(r, { WHITE, WHITE }, 0, FADE_X)
			loop(r, 1.1 + k * 0.4, { Position = r.Position + UDim2.fromOffset(side * 9, 0), BackgroundTransparency = 0.92 })
		end
	end

	-- muddy bank corners with reeds and cattails
	for side = 0, 1 do
		local bx = side == 0 and -30 or 330
		local mud = round(fr({ BackgroundColor3 = WHITE, Position = UDim2.fromOffset(bx - 20, 404), Size = UDim2.fromOffset(150, 52), ZIndex = 7, Parent = scene }))
		grad(mud, { lit(Color3.fromRGB(58, 62, 40), 0.8), lit(Color3.fromRGB(28, 26, 18), 0.8) }, 90, { { 0, 0.55 }, { 0.35, 0.05 }, { 1, 0 } })
		for k = 1, 14 do
			local px = side == 0 and rng:NextInteger(-8, 66) or rng:NextInteger(334, 408)
			local h = rng:NextInteger(60, 160)
			local base = lit(Color3.fromRGB(rng:NextInteger(54, 82), rng:NextInteger(84, 112), 46), 0.8)
			local blade = fr({ BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromOffset(px, 420),
				Size = UDim2.fromOffset(rng:NextInteger(3, 6), h), Rotation = rng:NextNumber(-14, 14), ZIndex = 8, Parent = scene })
			UI.corner(UDim.new(0.5, 0)).Parent = blade
			grad(blade, { base:Lerp(WHITE, 0.12), base:Lerp(Color3.new(0, 0, 0), 0.35) }, 90, { { 0, 0.6 }, { 0.12, 0 }, { 1, 0 } })
			if k % 4 == 0 then
				local head = fr({ BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(8, 24), ZIndex = 8, Parent = blade })
				UI.corner(UDim.new(0.5, 0)).Parent = head
				grad(head, { lit(Color3.fromRGB(140, 92, 54), 0.8), lit(Color3.fromRGB(80, 50, 30), 0.8) }, 0)
			end
			loop(blade, rng:NextNumber(2.4, 4.2), { Rotation = blade.Rotation + rng:NextNumber(3, 7) }, rng:NextNumber(0, 1))
		end
	end

	------------------------------------------------------------------ test strip
	local strip = fr({ BackgroundColor3 = WHITE, Position = UDim2.new(0.5, 74, 0, 40), Size = UDim2.fromOffset(18, 200), ZIndex = 5, Parent = scene })
	UI.corner(3).Parent = strip
	grad(strip, { Color3.fromRGB(255, 255, 255), Color3.fromRGB(222, 224, 226) }, 0)
	UI.stroke(Color3.fromRGB(130, 130, 130), 1, 0.45).Parent = strip
	fr({ BackgroundColor3 = Color3.fromRGB(40, 90, 170), Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 6), ZIndex = 5, Parent = strip })
	UI.text({ Text = "PO4", FontFace = F.mono, TextSize = 8, TextColor3 = Color3.fromRGB(40, 90, 170), TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 10), ZIndex = 5, Parent = strip })
	local pad = fr({ BackgroundColor3 = WHITE, Position = UDim2.new(0, 2, 1, -28), Size = UDim2.new(1, -4, 0, 22), ZIndex = 6, Parent = strip })
	UI.stroke(C.inkFaint, 1, 0.3).Parent = pad
	local patch = fr({ BackgroundColor3 = WHITE, Visible = false, Position = UDim2.fromScale(0.45, 0), Size = UDim2.fromScale(0.55, 0.6), ZIndex = 7, Parent = pad })

	------------------------------------------------------------------ vignette
	for _, v in { { UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 70), 90, false }, { UDim2.new(0, 0, 1, -90), UDim2.new(1, 0, 0, 90), 270, false },
		{ UDim2.new(0, 0, 0, 0), UDim2.new(0, 60, 1, 0), 0, true }, { UDim2.new(1, -60, 0, 0), UDim2.new(0, 60, 1, 0), 180, true } } do
		local vg = fr({ BackgroundColor3 = Color3.new(0, 0, 0), Position = v[1], Size = v[2], ZIndex = 9, Parent = scene })
		grad(vg, { WHITE, WHITE }, v[3], { { 0, night and 0.35 or 0.55 }, { 1, 1 } })
	end

	local api = {
		scene = scene, jar = jar, strip = strip, stripHome = strip.Position, pad = pad, patch = patch, waterColor = waterColor,
	}
	function api.setFill(f)
		jarWater.Size = UDim2.new(1, -12, 0, math.floor(JAR_INNER * math.clamp(f, 0, 1)))
	end
	function api.torchOn()
		TweenService:Create(torch, TweenInfo.new(0.4), { GroupTransparency = 0 }):Play()
	end
	function api.sealJar(labelText)
		cap.Visible = true
		UI.tween(cap, 0.35, { Position = UDim2.new(0.5, 0, 0, -12) }, Enum.EasingStyle.Back)
		task.delay(0.3, function() seal.Visible = true end)
		jarLabelText.Text = labelText
		jarLabel.Visible = true
	end
	return api
end

return RiverScene
