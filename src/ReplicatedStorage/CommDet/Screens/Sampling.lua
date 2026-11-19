-- Water test, in four hands-on steps:
--   1. FILL  - hold to fill the jar and stop between the fill lines
--   2. DIP   - dip the test strip and pull it out after about 2 seconds
--   3. READ  - match the pad against a continuous colour chart (at night: switch on the torch first)
--   4. LABEL - write the time on the label, sign and seal it, so the sample counts as evidence
-- The result shows the reading and a profile of the whole river so far.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Audio = require(script.Parent.Parent.Systems.Audio)
local RiverScene = require(script.Parent.Parent.Art.RiverScene)

local Sampling = {}

local CLEAN = Color3.fromRGB(150, 190, 214)
local MOONLIGHT = Color3.fromRGB(70, 74, 84)
local MURKY = Color3.fromRGB(120, 112, 70)

local FILL_RATE = 0.42 -- jar fraction per second while holding
local FILL_MIN, FILL_MAX = 0.70, 0.90
local DIP_MIN, DIP_MAX, DIP_FAIL = 1.5, 2.5, 3.6 -- seconds
local DIP_SCALE = 4 -- the timer bar shows 0-4 s
local SEGMENTS = 40
local TOLERANCE = 2 -- segments either side of the right colour

-- The chart: swatches evenly spaced along a bar, colours blended in between.
local function chartAt(swatches, p)
	local n = #swatches
	local f = math.clamp(p, 0, 1) * (n - 1) + 1
	local i = math.clamp(math.floor(f), 1, n - 1)
	local t = f - i
	local a, b = swatches[i], swatches[i + 1]
	return a.color:Lerp(b.color, t), a.value + (b.value - a.value) * t
end

local function chartPos(swatches, v)
	local n = #swatches
	if v <= swatches[1].value then return 0 end
	for i = 1, n - 1 do
		local a, b = swatches[i].value, swatches[i + 1].value
		if v <= b then
			return ((i - 1) + (v - a) / (b - a)) / (n - 1)
		end
	end
	return 1
end

local function isRelease(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

function Sampling.build(app, root, args)
	local UI = app.UI
	local C, F = UI.C, UI.F
	local case, state = app.case, app.state

	local point
	for _, sp in case.samplePoints do if sp.id == args.point then point = sp end end
	local night = args.night == true
	local value = night and point.night or point.day
	local key = point.id .. (night and "_night" or "_day")
	local slotName = args.slot or state:slotName()
	local dayName = args.day or state:dayName()
	state.sampleMistakes = state.sampleMistakes or 0
	local mistakes = 0

	local conns = {}
	local alive = true
	local function cleanup()
		alive = false
		for _, c in conns do c:Disconnect() end
		table.clear(conns)
	end
	local function oops(msg)
		mistakes += 1
		state.sampleMistakes += 1
		if msg then app:toast(msg) end
	end

	--------------------------------------------------------------------
	-- Header
	--------------------------------------------------------------------
	local _, hs = UI.paper(root, { pos = UDim2.fromOffset(30, 16), size = UDim2.fromOffset(560, 44), rot = -0.6, color = C.paperWhite, age = false })
	UI.text({ Text = ("WATER TEST · %s · %s %s"):format(UI.upper(point.name), UI.upper(dayName), UI.upper(slotName)), FontFace = F.type, TextSize = 18,
		TextScaled = true, Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -32, 1, 0), TextYAlignment = Enum.TextYAlignment.Center, Parent = hs })
	local hsz = hs:FindFirstChildWhichIsA("TextLabel")
	if hsz then UI.new("UITextSizeConstraint", { MaxTextSize = 18, MinTextSize = 12, Parent = hsz }) end

	--------------------------------------------------------------------
	-- Scene (left): painted river bank, see Art.RiverScene
	--------------------------------------------------------------------
	local art = RiverScene.build(UI, root, { point = point, night = night, slot = slotName, value = value,
		clean = CLEAN, murky = MURKY, fillMin = FILL_MIN, fillMax = FILL_MAX })
	local jar, setFill, strip, stripHome, pad, patch, sealJar, waterColor =
		art.jar, art.setFill, art.strip, art.stripHome, art.pad, art.patch, art.sealJar, art.waterColor

	--------------------------------------------------------------------
	-- Right side: step tracker, instructions, work area
	--------------------------------------------------------------------
	local STEPS = { "Fill", "Dip", "Read", "Label" }
	local stepTags = {}
	for i, name in STEPS do
		local tag = UI.text({ Text = ("%d  %s"):format(i, UI.upper(name)), FontFace = F.type, TextSize = 13, TextColor3 = C.paperShade,
			TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, BackgroundColor3 = C.ink, BackgroundTransparency = 1,
			Position = UDim2.fromOffset(462 + (i - 1) * 118, 76), Size = UDim2.fromOffset(110, 24), Parent = root })
		UI.stroke(C.paperShade, 1, 0.6).Parent = tag
		stepTags[i] = tag
	end
	local ih, info = UI.indexCard(root, { pos = UDim2.fromOffset(462, 110), size = UDim2.fromOffset(468, 100), rot = 0.6, lineTop = 36, lineGap = 22 })
	local infoTitle = UI.text({ Text = "", FontFace = F.type, TextSize = 15, Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -32, 0, 22), Parent = info })
	local infoText = UI.text({ Text = "", FontFace = F.hand, TextSize = 16, TextColor3 = C.blue, TextScaled = true,
		Position = UDim2.fromOffset(16, 34), Size = UDim2.new(1, -32, 1, -40), Parent = info })
	UI.new("UITextSizeConstraint", { MaxTextSize = 16, MinTextSize = 11, Parent = infoText })

	local work = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(462, 222), Size = UDim2.fromOffset(468, 262), Parent = root })

	local function setStep(i, title, text)
		for j, tag in stepTags do
			if j < i then
				tag.Text = "✓  " .. UI.upper(STEPS[j]); tag.TextColor3 = Color3.fromRGB(150, 206, 150); tag.BackgroundTransparency = 1
			elseif j == i then
				tag.Text = ("%d  %s"):format(j, UI.upper(STEPS[j])); tag.TextColor3 = C.paper; tag.BackgroundTransparency = 0
			else
				tag.Text = ("%d  %s"):format(j, UI.upper(STEPS[j])); tag.TextColor3 = C.paperShade; tag.BackgroundTransparency = 1
			end
		end
		infoTitle.Text = title
		infoText.Text = text
	end
	local function clearWork()
		for _, ch in work:GetChildren() do ch:Destroy() end
	end
	local function sheet(h, color)
		local _, s = UI.paper(work, { size = UDim2.fromOffset(468, h), rot = 0, color = color or C.paperWhite, age = false })
		return s
	end
	-- horizontal gauge: returns the bar, a function to place a zone, and a function to place the needle/fill
	local function gauge(parent, y)
		local bar = UI.frame({ BackgroundColor3 = Color3.fromRGB(222, 216, 200), Position = UDim2.fromOffset(14, y), Size = UDim2.fromOffset(440, 26), ClipsDescendants = true, Parent = parent })
		UI.stroke(C.ink, 1, 0.5).Parent = bar
		local function zone(a, b, color, transp)
			return UI.frame({ BackgroundColor3 = color, BackgroundTransparency = transp or 0.45, Position = UDim2.fromScale(a, 0), Size = UDim2.fromScale(b - a, 1), ZIndex = 2, Parent = bar })
		end
		return bar, zone
	end

	local stageFill, stageDip, stageRead, stageLabel, showResult

	--------------------------------------------------------------------
	-- 1. FILL
	--------------------------------------------------------------------
	stageFill = function()
		clearWork()
		setStep(1, "STEP 1 · FILL THE JAR", "Hold the button to fill the jar. Let go between the two red lines: enough water to cover the pad, but not so much that it spills when you dip.")
		local s = sheet(186)
		UI.text({ Text = "JAR", FontFace = F.type, TextSize = 14, Position = UDim2.fromOffset(14, 10), Size = UDim2.fromOffset(200, 20), Parent = s })
		local bar, zone = gauge(s, 40)
		zone(FILL_MIN, FILL_MAX, C.green, 0.55)
		zone(0.97, 1, C.redBright, 0.4)
		local level = UI.frame({ BackgroundColor3 = waterColor, Size = UDim2.fromScale(0, 1), ZIndex = 3, BackgroundTransparency = 0.15, Parent = bar })
		UI.text({ Text = "fill line", FontFace = F.handBold, TextSize = 14, TextColor3 = C.green, TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(14 + 440 * FILL_MIN, 68), Size = UDim2.fromOffset(440 * (FILL_MAX - FILL_MIN), 18), Parent = s })
		UI.text({ Text = "spills", FontFace = F.handBold, TextSize = 14, TextColor3 = C.redBright, TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.fromOffset(374, 68), Size = UDim2.fromOffset(80, 18), Parent = s })
		local status = UI.text({ Text = "", FontFace = F.serifItalic or F.serif, TextSize = 14, Position = UDim2.fromOffset(14, 92), Size = UDim2.fromOffset(440, 36), Parent = s })

		local fill, holding, locked = 0, false, false
		local stopPour = function() end
		local function show() level.Size = UDim2.fromScale(math.clamp(fill, 0, 1), 1); setFill(fill) end
		show()

		local btn, api = UI.button(s, "Hold to fill", { pos = UDim2.fromOffset(14, 132), size = UDim2.fromOffset(220, 44) })

		local function release()
			if not holding then return end
			holding = false
			stopPour()
			UI.tween(jar, 0.2, { Rotation = 0 })
			if locked then return end
			if fill < FILL_MIN then
				status.Text = "Not enough to cover the pad yet. Hold again to top it up."
			elseif fill <= FILL_MAX then
				locked = true
				api.setEnabled(false)
				status.TextColor3 = C.green
				status.Text = "Right on the fill line."
				task.delay(0.8, function() if alive then stageDip() end end)
			else
				status.Text = "Too full: it would spill when you dip the strip. You pour some out. Try again."
				task.delay(0.35, function()
					if not alive then return end
					fill = 0.5; show()
				end)
			end
		end
		local function spill()
			holding = false
			stopPour()
			UI.tween(jar, 0.2, { Rotation = 0 })
			UI.shake(jar, 6)
			status.Text = "It overflowed and mud from the bank got in. Empty the jar and start again."
			oops()
			fill = 0
			task.delay(0.3, function() if alive then show() end end)
		end
		btn.MouseButton1Down:Connect(function()
			if locked or not alive then return end
			holding = true
			stopPour = Audio.hold("pour")
			status.TextColor3 = C.ink
			status.Text = "Filling…"
			UI.tween(jar, 0.2, { Rotation = 14 })
		end)
		btn.MouseButton1Up:Connect(release)
		table.insert(conns, UserInputService.InputEnded:Connect(function(input) if isRelease(input) then release() end end))
		table.insert(conns, RunService.Heartbeat:Connect(function(dt)
			if not holding then return end
			fill += dt * FILL_RATE
			show()
			if fill >= 1 then spill() end
		end))
	end

	--------------------------------------------------------------------
	-- 2. DIP
	--------------------------------------------------------------------
	local target = chartAt(case.swatches, chartPos(case.swatches, value))

	stageDip = function()
		clearWork()
		setStep(2, "STEP 2 · DIP THE STRIP", "Dip the strip and count to two. Pull it out inside the green zone. Too short leaves the pad patchy; too long makes the colour bleed and read too dark.")
		local s = sheet(186)
		UI.text({ Text = "STRIP TIMER", FontFace = F.type, TextSize = 14, Position = UDim2.fromOffset(14, 10), Size = UDim2.fromOffset(200, 20), Parent = s })
		local bar, zone = gauge(s, 40)
		zone(DIP_MIN / DIP_SCALE, DIP_MAX / DIP_SCALE, C.green, 0.55)
		zone(DIP_FAIL / DIP_SCALE, 1, C.redBright, 0.4)
		local needle = UI.frame({ BackgroundColor3 = C.ink, Position = UDim2.fromScale(0, 0), Size = UDim2.new(0, 3, 1, 0), ZIndex = 4, Parent = bar })
		for sec = 0, DIP_SCALE do
			UI.text({ Text = sec .. "s", FontFace = F.mono, TextSize = 11, TextColor3 = C.inkFaint, TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.fromOffset(14 + 440 * sec / DIP_SCALE - 15, 68), Size = UDim2.fromOffset(30, 14), Parent = s })
		end
		local status = UI.text({ Text = "", FontFace = F.serifItalic or F.serif, TextSize = 14, Position = UDim2.fromOffset(14, 92), Size = UDim2.fromOffset(440, 36), Parent = s })

		local phase = "ready" -- ready, in, out, done
		local t0 = 0
		local btn, api
		local function resetStrip()
			pad.BackgroundColor3 = Color3.new(1, 1, 1)
			patch.Visible = false
			needle.Position = UDim2.fromScale(0, 0)
			phase = "ready"
			api.setText("Dip the strip")
			api.setEnabled(true)
		end
		local function pull()
			if phase ~= "in" then return end
			phase = "out"
			api.setEnabled(false)
			local t = os.clock() - t0
			UI.tween(strip, 0.35, { Position = stripHome })
			if t < DIP_MIN then
				pad.BackgroundColor3 = Color3.new(1, 1, 1):Lerp(target, 0.45)
				patch.Visible = true
				status.Text = ("%.1f s: too short. The pad is patchy, so you take a fresh strip."):format(t)
				oops()
				task.delay(1.6, function() if alive then resetStrip() end end)
			elseif t > DIP_MAX then
				pad.BackgroundColor3 = target:Lerp(Color3.fromRGB(20, 24, 50), 0.55)
				status.Text = ("%.1f s: too long. The colour bled and would read too dark. Fresh strip."):format(t)
				oops()
				task.delay(1.6, function() if alive then resetStrip() end end)
			else
				phase = "done"
				status.TextColor3 = C.green
				status.Text = ("%.1f s. Clean dip. Now wait for the colour to develop…"):format(t)
				UI.tween(pad, 1.6, { BackgroundColor3 = night and target:Lerp(MOONLIGHT, 0.75) or target })
				task.delay(1.9, function() if alive then stageRead() end end)
			end
		end
		btn, api = UI.button(s, "Dip the strip", { pos = UDim2.fromOffset(14, 132), size = UDim2.fromOffset(220, 44), onClick = function()
			if phase == "ready" then
				phase = "dipping"
				api.setEnabled(false)
				status.TextColor3 = C.ink
				status.Text = "In the water… one… two…"
				UI.tween(strip, 0.3, { Position = stripHome + UDim2.fromOffset(-110, 150) })
				task.delay(0.3, function()
					if not alive then return end
					phase = "in"
					t0 = os.clock()
					api.setText("Pull it out")
					api.setEnabled(true)
				end)
			elseif phase == "in" then
				pull()
			end
		end })
		table.insert(conns, RunService.Heartbeat:Connect(function()
			if phase ~= "in" then return end
			local t = os.clock() - t0
			needle.Position = UDim2.fromScale(math.clamp(t / DIP_SCALE, 0, 1), 0)
			if t >= DIP_FAIL then pull() end
		end))
	end

	--------------------------------------------------------------------
	-- 3. READ
	--------------------------------------------------------------------
	stageRead = function()
		clearWork()
		setStep(3, "STEP 3 · READ THE COLOUR", night
			and "It's dark. Switch on your torch, then tap the chart where it matches the pad. Darker blue means more phosphorus."
			or "Tap the chart where it matches the pad. Use the arrows to fine-tune. Darker blue means more phosphorus.")
		local s = sheet(250)
		UI.text({ Text = "COLOUR CHART · PHOSPHORUS (mg/L)", FontFace = F.type, TextSize = 14, Position = UDim2.fromOffset(14, 10), Size = UDim2.fromOffset(330, 20), Parent = s })

		local targetIdx = math.clamp(math.floor(chartPos(case.swatches, value) * (SEGMENTS - 1) + 0.5) + 1, 1, SEGMENTS)
		local selected = nil
		local holding = false
		local segW = 440 / SEGMENTS

		local barY = 52
		local bar = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(14, barY), Size = UDim2.fromOffset(440, 44), Parent = s })
		UI.stroke(C.ink, 1, 0.4).Parent = bar
		local arrow = UI.text({ Text = "▼", FontFace = F.sansBold, TextSize = 16, TextColor3 = C.ink, Visible = false, TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(0, barY - 18), Size = UDim2.fromOffset(20, 16), Parent = s })
		local selBox = UI.frame({ BackgroundTransparency = 1, Visible = false, Size = UDim2.fromOffset(segW + 4, 50), ZIndex = 3, Parent = s })
		UI.stroke(C.ink, 2).Parent = selBox

		-- ticks and limit
		for _, sw in case.swatches do
			local p = chartPos(case.swatches, sw.value)
			UI.text({ Text = ("%.1f"):format(sw.value), FontFace = F.mono, TextSize = 12, TextColor3 = C.inkFaint, TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.fromOffset(14 + 440 * p - 20, barY + 48), Size = UDim2.fromOffset(40, 14), Parent = s })
		end
		local lp = chartPos(case.swatches, case.sampleLimit)
		UI.frame({ BackgroundColor3 = C.redBright, Position = UDim2.fromOffset(14 + 440 * lp - 1, barY - 4), Size = UDim2.fromOffset(2, 52), ZIndex = 2, Parent = s })
		UI.text({ Text = "permit limit", FontFace = F.handBold, TextSize = 14, TextColor3 = C.redBright,
			Position = UDim2.fromOffset(14 + 440 * lp + 4, barY + 60), Size = UDim2.fromOffset(110, 16), Parent = s })

		-- compare boxes
		local compY = 140
		UI.text({ Text = "PAD", FontFace = F.mono, TextSize = 11, TextColor3 = C.inkFaint, Position = UDim2.fromOffset(14, compY), Size = UDim2.fromOffset(64, 14), Parent = s })
		UI.text({ Text = "CHART", FontFace = F.mono, TextSize = 11, TextColor3 = C.inkFaint, Position = UDim2.fromOffset(84, compY), Size = UDim2.fromOffset(64, 14), Parent = s })
		local padBox = UI.frame({ BackgroundColor3 = target, Position = UDim2.fromOffset(14, compY + 16), Size = UDim2.fromOffset(64, 64), Parent = s })
		UI.stroke(C.ink, 1, 0.3).Parent = padBox
		local chartBox = UI.frame({ BackgroundColor3 = Color3.new(1, 1, 1), Position = UDim2.fromOffset(84, compY + 16), Size = UDim2.fromOffset(64, 64), Parent = s })
		UI.stroke(C.ink, 1, 0.3).Parent = chartBox
		local qm = UI.text({ Text = "?", FontFace = F.type, TextSize = 26, TextColor3 = C.inkFaint, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = chartBox })

		UI.text({ Text = "YOUR READING", FontFace = F.mono, TextSize = 11, TextColor3 = C.inkFaint, Position = UDim2.fromOffset(170, compY), Size = UDim2.fromOffset(140, 14), Parent = s })
		local readout = UI.text({ Text = "—", FontFace = F.type, TextSize = 24, TextScaled = true, Position = UDim2.fromOffset(170, compY + 14), Size = UDim2.fromOffset(104, 30), Parent = s })
		UI.new("UITextSizeConstraint", { MaxTextSize = 24, MinTextSize = 12, Parent = readout })

		local recordApi
		local function select(i)
			selected = math.clamp(i, 1, SEGMENTS)
			local p = (selected - 1) / (SEGMENTS - 1)
			local col, v = chartAt(case.swatches, p)
			chartBox.BackgroundColor3 = col
			qm.Visible = false
			readout.Text = ("≈ %.1f mg/L"):format(v)
			arrow.Visible = true
			arrow.Position = UDim2.fromOffset(14 + (selected - 0.5) * segW - 10, barY - 18)
			selBox.Visible = true
			selBox.Position = UDim2.fromOffset(14 + (selected - 1) * segW - 2, barY - 3)
			recordApi.setEnabled(true)
		end
		for i = 1, SEGMENTS do
			local p = (i - 1) / (SEGMENTS - 1)
			local seg = UI.new("TextButton", { Name = "Seg" .. i, Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundColor3 = chartAt(case.swatches, p),
				Position = UDim2.fromOffset((i - 1) * segW, 0), Size = UDim2.fromOffset(math.ceil(segW), 44), Parent = bar })
			seg.MouseButton1Down:Connect(function() holding = true; select(i) end)
			seg.MouseEnter:Connect(function() if holding then select(i) end end)
		end
		table.insert(conns, UserInputService.InputEnded:Connect(function(input) if isRelease(input) then holding = false end end))

		UI.button(s, "◀", { style = "plain", pos = UDim2.fromOffset(170, compY + 50), size = UDim2.fromOffset(40, 30), textSize = 14, padX = 4, padY = 2,
			onClick = function() select(selected and selected - 1 or math.floor(SEGMENTS / 2)) end })
		UI.button(s, "▶", { style = "plain", pos = UDim2.fromOffset(216, compY + 50), size = UDim2.fromOffset(40, 30), textSize = 14, padX = 4, padY = 2,
			onClick = function() select(selected and selected + 1 or math.floor(SEGMENTS / 2)) end })

		local wrong = 0
		local _, rApi = UI.button(s, "Record reading", { pos = UDim2.fromOffset(278, compY + 36), size = UDim2.fromOffset(176, 44), textSize = 14, padX = 6, disabled = true, onClick = function(b)
			if not selected then return end
			if math.abs(selected - targetIdx) <= TOLERANCE then
				recordApi.setEnabled(false)
				readout.Text = ("%.1f mg/L"):format(value)
				readout.TextColor3 = value > case.sampleLimit and C.red or C.green
				UI.stamp(s, "Match", { pos = UDim2.new(1, -70, 0, 18), rot = -8, size = 16, z = 20 })
				task.delay(1.0, function() if alive then stageLabel() end end)
			else
				wrong += 1
				oops()
				UI.shake(chartBox, 4)
				if wrong >= 2 then
					app:toast(selected < targetIdx and "The pad is darker than that. Move right." or "The pad is lighter than that. Move left.")
				else
					app:toast("Not a match. Is the pad lighter or darker than the chart?")
				end
			end
		end })
		recordApi = rApi

		if night then
			local dark = UI.frame({ BackgroundColor3 = Color3.fromRGB(10, 12, 24), BackgroundTransparency = 0.08, Active = true,
				Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 1, -34), ZIndex = 30, Parent = s })
			local hitBlock = UI.hit({ ZIndex = 30, Parent = dark }) -- swallow taps while it's dark
			UI.text({ Text = "Too dark to compare colours.\nUnder moonlight every pad looks grey.", FontFace = F.hand, TextSize = 18, TextColor3 = Color3.fromRGB(200, 204, 220),
				TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(20, 40), Size = UDim2.new(1, -40, 0, 60), ZIndex = 31, Parent = dark })
			local tb
			tb = UI.button(dark, "Switch on the torch", { style = "tag", pos = UDim2.fromOffset(124, 116), size = UDim2.fromOffset(230, 40), textSize = 15, padX = 8, z = 32, onClick = function()
				Audio.play("torch")
				UI.tween(pad, 0.4, { BackgroundColor3 = target })
				hitBlock:Destroy()
				tb.Visible = false
				UI.tween(dark, 0.4, { BackgroundTransparency = 1 })
				for _, d in dark:GetDescendants() do if d:IsA("TextLabel") then UI.tween(d, 0.3, { TextTransparency = 1 }) end end
				task.delay(0.45, function() if dark.Parent then dark:Destroy() end end)
				art.torchOn()
			end })
		end
	end

	--------------------------------------------------------------------
	-- 4. LABEL
	--------------------------------------------------------------------
	stageLabel = function()
		clearWork()
		setStep(4, "STEP 4 · LABEL AND SEAL", "A sample only counts as evidence if anyone can check where and when it was taken. Write the time on the label, then sign and seal the jar.")
		local s = sheet(250, C.manila)
		local n = 0
		for _ in state.samples do n += 1 end
		UI.text({ Text = ("SAMPLE LABEL  ·  No. %02d"):format(n + 1), FontFace = F.type, TextSize = 16, Position = UDim2.fromOffset(16, 10), Size = UDim2.fromOffset(300, 22), Parent = s })
		local rows = { { "Place", point.name }, { "Day", dayName }, { "Reading", ("%.1f mg/L phosphorus"):format(value) } }
		for i, r in rows do
			local y = 40 + (i - 1) * 28
			UI.text({ Text = r[1] .. ":", FontFace = F.type, TextSize = 14, Position = UDim2.fromOffset(16, y + 4), Size = UDim2.fromOffset(110, 20), Parent = s })
			UI.text({ Text = r[2], FontFace = F.handBold, TextSize = 19, TextColor3 = C.blue, Position = UDim2.fromOffset(130, y), Size = UDim2.fromOffset(320, 24), Parent = s })
			UI.frame({ BackgroundColor3 = C.manilaDark or C.inkFaint, BackgroundTransparency = 0.3, Position = UDim2.fromOffset(126, y + 24), Size = UDim2.fromOffset(320, 1), Parent = s })
		end
		local ty = 40 + 3 * 28
		UI.text({ Text = "Time taken:", FontFace = F.type, TextSize = 14, Position = UDim2.fromOffset(16, ty + 8), Size = UDim2.fromOffset(110, 20), Parent = s })
		local chosen = false
		local sealApi
		local chips = {}
		for i, slot in app.Config and app.Config.SLOTS or { "Morning", "Afternoon", "Evening", "Night" } do
			local chip
			chip = UI.button(s, slot, { style = "plain", font = F.type, pos = UDim2.fromOffset(126 + (i - 1) * 82, ty + 2), size = UDim2.fromOffset(78, 32), textSize = 12, padX = 2, padY = 2,
				onClick = function()
					if chosen then return end
					if slot == slotName then
						chosen = true
						for _, c in chips do c.BackgroundTransparency = c == chip and 0 or 0.6 end
						UI.stroke(C.blue, 2).Parent = chip
						sealApi.setEnabled(true)
					else
						oops("That's not when you took it. A wrong time on the label makes the sample worthless as evidence.")
						UI.shake(chip, 4)
					end
				end })
			table.insert(chips, chip)
		end
		local sigY = ty + 48
		UI.text({ Text = "Signed:", FontFace = F.type, TextSize = 14, Position = UDim2.fromOffset(16, sigY + 8), Size = UDim2.fromOffset(110, 20), Parent = s })
		local lp = Players.LocalPlayer
		local sig = UI.text({ Text = lp and lp.DisplayName or "Detective", FontFace = F.handBold, TextSize = 24, TextColor3 = C.blue, TextTransparency = 1,
			Position = UDim2.fromOffset(130, sigY), Size = UDim2.fromOffset(150, 30), Parent = s })
		local _, sApi = UI.button(s, "Sign & seal", { pos = UDim2.fromOffset(300, sigY), size = UDim2.fromOffset(150, 40), textSize = 15, disabled = true, onClick = function()
			sealApi.setEnabled(false)
			UI.tween(sig, 0.5, { TextTransparency = 0 })
			sealJar(("No. %02d\n%s"):format(n + 1, slotName))
			UI.stamp(s, "Sealed", { pos = UDim2.new(1, -90, 0, 30), rot = 10, size = 22, z = 20 })
			task.delay(1.1, function() if alive then showResult() end end)
		end })
		sealApi = sApi
	end

	--------------------------------------------------------------------
	-- Result + river profile
	--------------------------------------------------------------------
	showResult = function()
		clearWork()
		for _, tag in stepTags do tag.Visible = false end
		state.samples[key] = { value = value, night = night, slot = slotName, sealed = true, mistakes = mistakes }

		local clueId
		if point.id == "up" then clueId = "c_upstream"
		elseif point.id == "pipe" and night then clueId = "c_source"
		elseif point.id == "farm" then clueId = "c_farm_ok"
		elseif point.id == "beach" and value > case.sampleLimit then clueId = "c_beach" end
		local isNew = clueId and state:find(clueId)

		local ratio = value / case.sampleLimit
		local verdict
		if value > case.sampleLimit then
			verdict = ("%.1f mg/L · %s the permit limit"):format(value, ratio >= 2 and (math.floor(ratio + 0.5) .. "×") or "over")
		elseif value == case.sampleLimit then
			verdict = ("%.1f mg/L · exactly at the limit"):format(value)
		else
			verdict = ("%.1f mg/L · under the limit"):format(value)
		end
		local comment
		if point.id == "pipe" and not night then
			comment = "In daylight the pipe looks fine. That's exactly what the official tests say. But what happens when nobody is watching?"
		elseif clueId then
			comment = case.clues[clueId].note
		else
			comment = "Raised, but this alone proves nothing. Compare it with other points."
		end
		setStep(5, "SAMPLE SEALED", mistakes == 0 and "Textbook technique: no wasted strips, no spills." or ("Done, with %d slip%s along the way. Real field work is fiddly too."):format(mistakes, mistakes == 1 and "" or "s"))

		local h, rs = UI.paper(work, { size = UDim2.fromOffset(468, 96), rot = -0.6, color = C.paperWhite, age = false })
		UI.text({ Text = verdict, FontFace = F.type, TextSize = 17, TextColor3 = value > case.sampleLimit and C.red or C.green,
			Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 22), Parent = rs })
		local cl = UI.text({ Text = comment, FontFace = F.serif, TextSize = 14, Position = UDim2.fromOffset(14, 34), Size = UDim2.new(1, -28, 0, 54), TextScaled = true, Parent = rs })
		UI.new("UITextSizeConstraint", { MaxTextSize = 14, MinTextSize = 10, Parent = cl })
		if isNew then
			UI.stamp(h, "New clue", { pos = UDim2.new(1, -60, 1, -10), rot = -8, size = 13, z = 40 })
		end

		-- river profile
		local ph, ps = UI.paper(work, { pos = UDim2.fromOffset(0, 106), size = UDim2.fromOffset(468, 150), rot = 0, color = C.paperWhite, age = false })
		UI.text({ Text = "THE RIVER SO FAR  ·  upstream → sea", FontFace = F.type, TextSize = 13, Position = UDim2.fromOffset(14, 8), Size = UDim2.fromOffset(300, 18), Parent = ps })
		local dayCol, nightCol = Color3.fromRGB(146, 196, 212), Color3.fromRGB(34, 52, 102)
		local lg = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(320, 9), Size = UDim2.fromOffset(140, 16), Parent = ps })
		UI.frame({ BackgroundColor3 = dayCol, Position = UDim2.fromOffset(0, 3), Size = UDim2.fromOffset(10, 10), Parent = lg })
		UI.text({ Text = "day", FontFace = F.mono, TextSize = 11, Position = UDim2.fromOffset(14, 1), Size = UDim2.fromOffset(40, 14), Parent = lg })
		UI.frame({ BackgroundColor3 = nightCol, Position = UDim2.fromOffset(58, 3), Size = UDim2.fromOffset(10, 10), Parent = lg })
		UI.text({ Text = "night", FontFace = F.mono, TextSize = 11, Position = UDim2.fromOffset(72, 1), Size = UDim2.fromOffset(50, 14), Parent = lg })

		local BASE, MAXH = 104, 66
		local function hOf(v) return math.max(3, math.floor(math.sqrt(math.min(v, 5) / 5) * MAXH)) end
		local limY = BASE - hOf(case.sampleLimit)
		for x = 14, 440, 12 do
			UI.frame({ BackgroundColor3 = C.redBright, Position = UDim2.fromOffset(x, limY), Size = UDim2.fromOffset(6, 1), ZIndex = 3, Parent = ps })
		end
		UI.text({ Text = "limit", FontFace = F.handBold, TextSize = 12, TextColor3 = C.redBright, TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.fromOffset(400, limY - 15), Size = UDim2.fromOffset(54, 14), Parent = ps })
		UI.frame({ BackgroundColor3 = C.ink, BackgroundTransparency = 0.5, Position = UDim2.fromOffset(14, BASE), Size = UDim2.fromOffset(440, 1), Parent = ps })
		local colW = 440 / #case.samplePoints
		for i, sp in case.samplePoints do
			local cx = 14 + (i - 1) * colW
			for j, nt in { false, true } do
				local r = state.samples[sp.id .. (nt and "_night" or "_day")]
				local bx = cx + colW / 2 - 26 + (j - 1) * 28
				if r then
					local hh = hOf(r.value)
					local b = UI.frame({ BackgroundColor3 = nt and nightCol or dayCol, Position = UDim2.fromOffset(bx, BASE - hh), Size = UDim2.fromOffset(24, hh), ZIndex = 2, Parent = ps })
					if sp.id == point.id and nt == night then UI.stroke(C.redBright, 2).Parent = b end
					UI.text({ Text = ("%.1f"):format(r.value), FontFace = F.mono, TextSize = 10, TextColor3 = C.ink, TextXAlignment = Enum.TextXAlignment.Center,
						Position = UDim2.fromOffset(bx - 6, BASE - hh - 13), Size = UDim2.fromOffset(36, 12), ZIndex = 4, Parent = ps })
				else
					UI.text({ Text = "?", FontFace = F.type, TextSize = 13, TextColor3 = C.inkFaint, TextXAlignment = Enum.TextXAlignment.Center,
						Position = UDim2.fromOffset(bx, BASE - 16), Size = UDim2.fromOffset(24, 14), Parent = ps })
				end
			end
			UI.text({ Text = sp.name, FontFace = F.mono, TextSize = 11, TextColor3 = C.inkFaint, TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.fromOffset(cx, BASE + 4), Size = UDim2.fromOffset(colW, 14), Parent = ps })
		end
		local S = state.samples
		local up = S.up_day or S.up_night
		local pn = S.pipe_night
		local insight
		if up and pn and pn.value > case.sampleLimit then
			insight = "Clean above the plant, far over the limit at its pipe at night: the pollution gets in at the pipe."
		elseif S.pipe_day and not pn then
			insight = "The pipe has only been tested by day. The town says the smell comes at night…"
		elseif not up then
			insight = "Test upstream too: without a clean reference point you can't tell where the pollution starts."
		else
			insight = "Look for the jump: where the numbers rise between two points is where pollution gets in."
		end
		local il = UI.text({ Text = insight, FontFace = F.hand, TextSize = 15, TextColor3 = C.blue, TextScaled = true,
			Position = UDim2.fromOffset(14, BASE + 20), Size = UDim2.fromOffset(440, 22), Parent = ps })
		UI.new("UITextSizeConstraint", { MaxTextSize = 15, MinTextSize = 10, Parent = il })

		UI.button(root, "Back to the map", { pos = UDim2.fromOffset(700, 492), size = UDim2.fromOffset(230, 40), textSize = 15, onClick = function() app:go("Map") end })
	end

	stageFill()
	return cleanup
end

return Sampling
