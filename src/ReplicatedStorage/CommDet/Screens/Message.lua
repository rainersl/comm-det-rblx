-- final message creation
local Evaluator = require(script.Parent.Parent.Systems.MessageEvaluator)

local Message = {}

function Message.build(app, root, args)
	local UI = app.UI
	local C, F = UI.C, UI.F
	local case, state = app.case, app.state
	local activeIndex = (args and args.tab) or 1

	local fh, folder = UI.paper(root, { pos = UDim2.fromOffset(24, 46), size = UDim2.fromOffset(500, 470), rot = 0, color = C.manila })
	local tabsRow = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 14), Size = UDim2.fromOffset(500, 34), Parent = root })

	local content = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(22, 18), Size = UDim2.new(1, -44, 1, -36), Parent = folder })

	local phoneH, phone = UI.paper(root, { pos = UDim2.fromOffset(552, 24), size = UDim2.fromOffset(384, 420), rot = 0.8, color = Color3.fromRGB(22, 24, 28), age = false })
	UI.corner(18).Parent = phone
	local shadow = phoneH:FindFirstChild("Shadow")
	if shadow then UI.corner(18).Parent = shadow end
	local screen = UI.frame({ BackgroundColor3 = C.screen, Position = UDim2.fromOffset(12, 14), Size = UDim2.new(1, -24, 1, -28), ClipsDescendants = true, Parent = phone })
	UI.corner(10).Parent = screen
	local bar = UI.frame({ BackgroundColor3 = Color3.fromRGB(32, 35, 41), Size = UDim2.new(1, 0, 0, 50), Parent = screen })
	local chatTitle = UI.text({ FontFace = F.sansBold, TextSize = 18, TextColor3 = Color3.new(1, 1, 1), Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -32, 0, 22), Parent = bar })
	UI.text({ Text = "melnraksts · vēl nav nosūtīts", FontFace = F.sans, TextSize = 12, TextColor3 = Color3.fromRGB(160, 166, 176), Position = UDim2.fromOffset(16, 29), Size = UDim2.new(1, -32, 0, 16), Parent = bar })
	local bubble = UI.frame({ BackgroundColor3 = C.bubbleOwn, Position = UDim2.fromOffset(16, 70), Size = UDim2.new(1, -32, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = screen })
	UI.corner(12).Parent = bubble
	UI.pad(10, 14, 12, 14).Parent = bubble
	UI.list(nil, 4).Parent = bubble
	local sender = UI.text({ FontFace = F.sansBold, TextSize = 13, TextColor3 = C.blue, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1, Parent = bubble })
	local body = UI.text({ FontFace = F.sans, TextSize = 18, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, LineHeight = 1.1, RichText = true, Parent = bubble })

	local sendBtn, sendApi

	local function msgComplete(m)
		for _, s in m.slots do
			if not state.choices[m.id][s.id] then return false end
		end
		return true
	end

	local render

	local function openPicker(m, slot)
		app:openModal(function(md, close)
			UI.text({ Text = UI.upper(m.tab) .. " — " .. UI.upper(slot.label), FontFace = F.type, TextSize = 22, TextColor3 = C.paper, Position = UDim2.fromOffset(120, 40), Size = UDim2.fromOffset(720, 30), Parent = md })
			UI.text({ Text = m.audience, FontFace = F.hand, TextSize = 18, TextColor3 = C.paperShade, Position = UDim2.fromOffset(120, 74), Size = UDim2.fromOffset(720, 26), Parent = md })
			local col = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(120, 116), Size = UDim2.fromOffset(720, 360), Parent = md })
			UI.list(nil, 12).Parent = col
			for oi, opt in slot.options do
				local unlocked = state:isOptionUnlocked(opt)
				local selected = state.choices[m.id][slot.id] == oi
				local cell = UI.frame({ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 56), LayoutOrder = oi, Parent = col })
				local rot = ((oi % 2) == 0 and 0.6 or -0.6)
				local h, s = UI.paper(cell, { size = UDim2.fromScale(1, 1), rot = rot, color = unlocked and (selected and C.paperWhite or C.paper) or C.paperShade, age = false })
				if selected then UI.stroke(C.redBright, 2.5).Parent = s end
				UI.text({
					Text = unlocked and opt.text or "████████  Šim variantam vajag faktu, ko vēl neesi atradis.",
					FontFace = unlocked and F.sans or F.type,
					TextSize = unlocked and 19 or 15,
					TextColor3 = unlocked and C.ink or C.inkFaint,
					Position = UDim2.fromOffset(18, 0), Size = UDim2.new(1, -36, 1, 0),
					TextYAlignment = Enum.TextYAlignment.Center, Parent = s,
				})
				if unlocked then
					local hit = UI.hit({ ZIndex = 10, Parent = h })
					hit.MouseEnter:Connect(function() UI.tween(h, 0.1, { Rotation = 0, Position = UDim2.fromOffset(6, 0) }) end)
					hit.MouseLeave:Connect(function() UI.tween(h, 0.1, { Rotation = rot, Position = UDim2.fromOffset(0, 0) }) end)
					hit.Activated:Connect(function()
						state:choose(m.id, slot.id, oi)
						close()
						render()
					end)
				end
			end
			UI.button(md, "Atcelt", { style = "paper", pos = UDim2.fromOffset(120, 480), size = UDim2.fromOffset(140, 40), onClick = close })
		end, { closeOnDim = true, dim = 0.2 })
	end

	render = function()
		local m = case.messages[activeIndex]

		tabsRow:ClearAllChildren()
		for i, mm in case.messages do
			local done = msgComplete(mm)
			local active = i == activeIndex
			local t = UI.new("TextButton", {
				Text = mm.tab .. (done and "  ✓" or ""),
				FontFace = F.type, TextSize = 15, TextColor3 = C.ink,
				BackgroundColor3 = active and C.manila or C.manilaDark,
				BorderSizePixel = 0, AutoButtonColor = false,
				Position = UDim2.fromOffset(16 + (i - 1) * 196, active and 0 or 6),
				Size = UDim2.fromOffset(186, active and 36 or 30),
				Parent = tabsRow,
			})
			UI.corner(5).Parent = t
			t.Activated:Connect(function()
				activeIndex = i
				render()
			end)
		end

		content:ClearAllChildren()
		UI.text({ Text = "KAM:", FontFace = F.type, TextSize = 13, TextColor3 = C.inkSoft, Position = UDim2.fromOffset(0, 4), Size = UDim2.fromOffset(60, 18), Parent = content })
		UI.text({ Text = m.audience, FontFace = F.handBold, TextSize = 18, TextColor3 = C.red, Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 48), Parent = content })
		local slotsBox = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 76), Size = UDim2.new(1, 0, 1, -76), Parent = content })
		UI.list(nil, 8).Parent = slotsBox
		for si, slot in m.slots do
			local row = UI.frame({ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 52), LayoutOrder = si, Parent = slotsBox })
			UI.text({ Text = UI.upper(slot.label), FontFace = F.type, TextSize = 13, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(96, 52),
				TextYAlignment = Enum.TextYAlignment.Center, Parent = row })
			local opt = Evaluator.selectedOption(case, state, m.id, slot.id)
			local strip = UI.new("TextButton", {
				Text = opt and opt.text or "izvēlies…",
				FontFace = opt and F.sans or F.hand,
				TextSize = opt and 16 or 17,
				TextColor3 = opt and C.ink or C.inkFaint,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundColor3 = opt and C.paperWhite or C.paper,
				BorderSizePixel = 0, AutoButtonColor = false,
				Position = UDim2.fromOffset(98, 2), Size = UDim2.new(1, -98, 1, -4),
				Rotation = (si % 2 == 0) and 0.4 or -0.4,
				Parent = row,
			})
			UI.pad(4, 12).Parent = strip
			strip.TextScaled = true
			UI.new("UITextSizeConstraint", { MaxTextSize = opt and 16 or 17, MinTextSize = 11, Parent = strip })
			UI.stroke(C.ink, 1, opt and 0.6 or 0.2).Parent = strip
			if not opt then
				local st = strip:FindFirstChildOfClass("UIStroke")
				st.LineJoinMode = Enum.LineJoinMode.Miter
			end
			strip.MouseEnter:Connect(function() UI.tween(strip, 0.1, { BackgroundColor3 = C.paperWhite }) end)
			strip.MouseLeave:Connect(function() UI.tween(strip, 0.1, { BackgroundColor3 = opt and C.paperWhite or C.paper }) end)
			strip.Activated:Connect(function() openPicker(m, slot) end)
		end

		chatTitle.Text = m.chatTitle
		sender.Text = m.sender
		local text = Evaluator.compose(case, state, m)
		text = string.gsub(text, "____", '<font color="#A42428">____</font>')
		body.Text = text

		local all = Evaluator.isComplete(case, state)
		if sendApi then sendApi.setEnabled(all) end
	end

	sendBtn, sendApi = UI.button(root, "Nosūtīt abas ziņas", {
		pos = UDim2.fromOffset(552, 464),
		size = UDim2.fromOffset(384, 52),
		textSize = 18,
		onClick = function()
			app:openModal(function(md, close)
				local h, s = UI.indexCard(md, { pos = UDim2.fromOffset(480, 270), anchor = Vector2.new(0.5, 0.5), size = UDim2.fromOffset(460, 210), rot = 1, lineTop = 50, lineGap = 26 })
				UI.pin(h, UDim2.new(0.5, 0, 0, 8))
				UI.text({ Text = "SŪTĪT?", FontFace = F.type, TextSize = 20, Position = UDim2.fromOffset(20, 16), Size = UDim2.new(1, -40, 0, 26), Parent = s })
				UI.text({ Text = "Kad ziņas būs nosūtītas, neko vairs nevarēs labot. Piektdien redzēsim, cik krēslu būs aizņemti.",
					FontFace = F.hand, TextSize = 18, TextColor3 = C.blue, Position = UDim2.fromOffset(20, 50), Size = UDim2.new(1, -40, 0, 80), Parent = s })
				UI.button(s, "Sūtīt", { pos = UDim2.new(1, -20, 1, -16), anchor = Vector2.new(1, 1), size = UDim2.fromOffset(150, 40), onClick = function() app:go("Results") end })
				UI.button(s, "Vēl labot", { style = "paper", pos = UDim2.new(0, 20, 1, -16), anchor = Vector2.new(0, 1), size = UDim2.fromOffset(140, 40), onClick = close })
			end, { closeOnDim = true })
		end,
	})

	UI.button(root, "← Dēlis", {
		style = "paper", pos = UDim2.fromOffset(446, 12), textSize = 13, padY = 6, padX = 12,
		onClick = function() app:go("Board") end,
	})

	render()
end

return Message
