-- deduction
local Deduction = {}

function Deduction.build(app, root)
	local UI = app.UI
	local C, F = UI.C, UI.F
	local case, state = app.case, app.state
	local ded = state.deduction

	local h, sheet = UI.paper(root, { pos = UDim2.fromOffset(60, 10), size = UDim2.fromOffset(840, 466), rot = 0, color = C.paper })
	UI.pin(h, UDim2.new(0.5, 0, 0, 10))
	UI.text({ Text = "SECINĀJUMI — LIETA Nr. " .. case.number, FontFace = F.type, TextSize = 18, Position = UDim2.fromOffset(36, 26), Size = UDim2.new(1, -72, 0, 24), Parent = sheet })
	UI.frame({ BackgroundColor3 = C.ink, Position = UDim2.fromOffset(36, 54), Size = UDim2.new(1, -72, 0, 1), Parent = sheet })
	UI.text({ Text = case.question, FontFace = F.handBold, TextSize = 28, TextColor3 = C.red, Position = UDim2.fromOffset(36, 62), Size = UDim2.new(1, -72, 0, 40), Rotation = -0.6, Parent = sheet })
	local sub = UI.text({ Text = case.deduction.prompt, FontFace = F.serifItalic, TextSize = 15, TextColor3 = C.inkSoft, Position = UDim2.fromOffset(36, 104), Size = UDim2.new(1, -72, 0, 22), Parent = sheet })

	local list = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(36, 132), Size = UDim2.new(1, -72, 0, 320), Parent = sheet })
	UI.list(nil, 2).Parent = list

	local rows = {}
	local function drawMark(box, on)
		local m = box:FindFirstChild("Mark")
		if m then m:Destroy() end
		if on then
			UI.text({ Name = "Mark", Text = "X", FontFace = F.handBold, TextSize = 30, TextColor3 = C.redBright, Size = UDim2.new(1, 8, 1, 8), Position = UDim2.fromOffset(-4, -8),
				TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, Rotation = -6, Parent = box })
		end
	end

	for i, opt in case.deduction.options do
		local row = UI.frame({ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = i, Parent = list })
		local box = UI.frame({ BackgroundColor3 = C.paperWhite, Position = UDim2.fromOffset(0, 10), Size = UDim2.fromOffset(24, 24), Parent = row })
		UI.stroke(C.ink, 1.5).Parent = box
		local label = UI.text({ Text = opt.text, FontFace = F.serif, TextSize = 17, Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -190, 1, 0), TextYAlignment = Enum.TextYAlignment.Center, Parent = row })
		local why = UI.text({ Text = "", FontFace = F.hand, TextSize = 15, TextColor3 = C.blue, Position = UDim2.fromOffset(40, 28), Size = UDim2.new(1, -190, 0, 20), Visible = false, TextScaled = true, Parent = row })
		UI.new("UITextSizeConstraint", { MaxTextSize = 15, MinTextSize = 11, Parent = why })
		local verdictSlot = UI.frame({ BackgroundTransparency = 1, Position = UDim2.new(1, -150, 0, 0), Size = UDim2.fromOffset(150, 44), Parent = row })
		local hit = UI.hit({ ZIndex = 5, Parent = row })
		hit.Activated:Connect(function()
			if ded.done then return end
			ded.picks[i] = not ded.picks[i]
			drawMark(box, ded.picks[i])
		end)
		drawMark(box, ded.picks[i])
		rows[i] = { row = row, why = why, slot = verdictSlot, label = label }
	end

	local nextBtn
	local function showVerdicts(animate)
		sub.Text = "Spriedums:"
		for i, opt in case.deduction.options do
			local r = rows[i]
			local picked = ded.picks[i] == true
			local text, color
			if opt.correct and picked then
				text, color = "Pareizi", C.ink
			elseif opt.correct and not picked then
				text, color = "Palaists garām", C.red
			elseif not opt.correct and picked then
				text, color = "Nepareizi", C.red
			end
			if text then
				r.row.Size = UDim2.new(1, 0, 0, 50)
				r.label.Size = UDim2.new(1, -190, 0, 28)
				r.why.Text = opt.why
				r.why.Visible = true
				local function put()
					UI.stamp(r.slot, text, { size = 13, color = color, rot = -6 + (i % 3) * 3, animate = animate })
				end
				if animate then task.delay(i * 0.18, put) else put() end
			else
				r.label.TextTransparency = 0.5
			end
		end
		local _, api = UI.button(root, "Rakstīt jaunu ziņu →", {
			pos = UDim2.fromOffset(900, 530), anchor = Vector2.new(1, 1), size = UDim2.fromOffset(280, 44),
			onClick = function() app:go("Message") end,
		})
		nextBtn = api
	end

	local submit
	local _, submitApi = UI.button(root, "Iesniegt secinājumus", {
		pos = UDim2.fromOffset(900, 530), anchor = Vector2.new(1, 1), size = UDim2.fromOffset(280, 44),
		onClick = function(btn)
			local any = false
			for _, v in ded.picks do if v then any = true end end
			if not any then
				app:toast("Atzīmē vismaz vienu iemeslu.")
				return
			end
			ded.done = true
			local correctTotal, hit, wrong = 0, 0, 0
			for i, opt in case.deduction.options do
				if opt.correct then correctTotal += 1 end
				if ded.picks[i] then
					if opt.correct then hit += 1 else wrong += 1 end
				end
			end
			ded.score = math.max(0, (hit - wrong) / correctTotal)
			btn:Destroy()
			showVerdicts(true)
		end,
	})

	UI.button(root, "← Dēlis", {
		style = "paper", pos = UDim2.fromOffset(60, 490), textSize = 14, padY = 8, padX = 14,
		onClick = function() app:go("Board") end,
	})

	if ded.done then
		submitApi.instance:Destroy()
		showVerdicts(false)
	end
end

return Deduction
