-- Phone message with a timer and reply choices. Every reply is a decision with consequences.
local Config = require(script.Parent.Parent.Config)
local Audio = require(script.Parent.Parent.Systems.Audio)

local Phone = {}

function Phone.open(app, msg, onDone)
	local UI = app.UI
	local C, F = UI.C, UI.F
	local case, state = app.case, app.state
	local sender = case.characters[msg.from]

	Audio.play("phone")
	app:openModal(function(m, close)
		local answered = false

		-- phone body
		local body = UI.frame({ BackgroundColor3 = Color3.fromRGB(20, 22, 26), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(480, 290),
			Size = UDim2.fromOffset(380, 500), Rotation = -1, Parent = m })
		UI.corner(26).Parent = body
		local screen = UI.frame({ BackgroundColor3 = C.screen, Position = UDim2.fromOffset(12, 14), Size = UDim2.new(1, -24, 1, -28), ClipsDescendants = true, Parent = body })
		UI.corner(16).Parent = screen
		local sc = UI.new("UIScale", { Scale = 0.85, Parent = body })
		UI.tween(sc, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)

		local bar = UI.frame({ BackgroundColor3 = Color3.fromRGB(32, 35, 41), Size = UDim2.new(1, 0, 0, 64), Parent = screen })
		UI.polaroid(bar, { pos = UDim2.fromOffset(10, 6), size = UDim2.fromOffset(44, 52), look = sender.look, small = sender.small })
		UI.text({ Text = sender.full, FontFace = F.sansBold, TextSize = 17, TextColor3 = Color3.new(1, 1, 1), Position = UDim2.fromOffset(64, 10), Size = UDim2.new(1, -74, 0, 22), Parent = bar })
		UI.text({ Text = sender.role, FontFace = F.sans, TextSize = 12, TextColor3 = Color3.fromRGB(160, 166, 176), Position = UDim2.fromOffset(64, 33), Size = UDim2.new(1, -74, 0, 18),
			TextTruncate = Enum.TextTruncate.AtEnd, Parent = bar })

		local thread = UI.frame({ BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 78), Size = UDim2.new(1, -28, 0, 160), Parent = screen })
		UI.list(nil, 8).Parent = thread
		local row1 = UI.frame({ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = thread })
		local bubble = UI.frame({ BackgroundColor3 = C.bubble, Size = UDim2.new(1, -36, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = row1 })
		UI.corner(12).Parent = bubble
		UI.stroke(Color3.fromRGB(205, 208, 214), 1).Parent = bubble
		UI.pad(10, 12).Parent = bubble
		local msgText = UI.text({ Text = msg.text, FontFace = F.sans, TextSize = 16, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LineHeight = 1.05, Parent = bubble })
		UI.typewrite(msgText, 120)

		-- decision label
		local tag = UI.frame({ BackgroundTransparency = 1, Position = UDim2.new(0, 14, 1, -246), Size = UDim2.new(1, -28, 0, 20), Parent = screen })
		UI.list(Enum.FillDirection.Horizontal, 6).Parent = tag
		UI.text({ Text = "YOUR REPLY WILL HAVE CONSEQUENCES", FontFace = F.type, TextSize = 12, TextColor3 = C.red, TextWrapped = false, AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 18), TextYAlignment = Enum.TextYAlignment.Center, LayoutOrder = 0, Parent = tag })

		-- timer
		local timerBack = UI.frame({ BackgroundColor3 = Color3.fromRGB(210, 212, 218), Position = UDim2.new(0, 14, 1, -220), Size = UDim2.new(1, -28, 0, 6), Parent = screen })
		local timerFill = UI.frame({ BackgroundColor3 = C.red, Size = UDim2.fromScale(1, 1), Parent = timerBack })

		-- replies
		local replies = UI.frame({ BackgroundTransparency = 1, Position = UDim2.new(0, 14, 1, -206), Size = UDim2.new(1, -28, 0, 196), Parent = screen })
		UI.list(nil, 6).Parent = replies

		local function finish(effect, replyText)
			if answered then return end
			answered = true
			state:applyEffect(msg.id, effect)
			replies.Visible = false
			timerBack.Visible = false
			if replyText then
				local row2 = UI.frame({ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = thread })
				local mine = UI.frame({ BackgroundColor3 = C.bubbleOwn, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0),
					Size = UDim2.new(1, -36, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = row2 })
				UI.corner(12).Parent = mine
				UI.pad(10, 12).Parent = mine
				UI.text({ Text = replyText, FontFace = F.sans, TextSize = 15, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = mine })
			else
				app:toast("No reply sent. Silence is a decision too.", C.red)
			end
			task.delay(replyText and 1.6 or 0.6, function()
				close()
				if onDone then onDone() end
			end)
		end

		for i, ch in msg.choices do
			local b = UI.new("TextButton", {
				Text = ch.text, FontFace = F.sans, TextSize = 15, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = C.blue, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, AutoButtonColor = false,
				Size = UDim2.new(1, 0, 0, 58), LayoutOrder = i, Parent = replies,
			})
			UI.corner(10).Parent = b
			UI.stroke(C.blue, 1.5, 0.3).Parent = b
			UI.pad(4, 10).Parent = b
			b.TextScaled = true
			UI.new("UITextSizeConstraint", { MaxTextSize = 15, MinTextSize = 11, Parent = b })
			b.MouseEnter:Connect(function() UI.tween(b, 0.1, { BackgroundColor3 = C.bubbleOwn }) end)
			b.MouseLeave:Connect(function() UI.tween(b, 0.1, { BackgroundColor3 = Color3.new(1, 1, 1) }) end)
			b.Activated:Connect(function() finish(ch.effect, ch.text) end)
		end

		task.spawn(function()
			local total = Config.PHONE_TIMER
			local t0 = os.clock()
			while not answered and m.Parent do
				local left = 1 - (os.clock() - t0) / total
				timerFill.Size = UDim2.fromScale(math.max(0, left), 1)
				if left <= 0 then
					finish(msg.timeout, nil)
					break
				end
				task.wait(0.05)
			end
		end)
	end, { dim = 0.25, silent = true })
end

return Phone
