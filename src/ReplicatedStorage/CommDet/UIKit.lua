-- ui kit
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)
local C, F = Theme.C, Theme.F

local UI = {}
UI.C = C
UI.F = F

------------------------------------------------------------------------
-- basics
------------------------------------------------------------------------
function UI.new(className, props, children)
	local o = Instance.new(className)
	local parent
	if props then
		for k, v in props do
			if k == "Parent" then
				parent = v
			else
				o[k] = v
			end
		end
	end
	if children then
		for _, c in children do
			c.Parent = o
		end
	end
	if parent then
		o.Parent = parent
	end
	return o
end
local new = UI.new

local function merge(defaults, props)
	local t = table.clone(defaults)
	if props then
		for k, v in props do
			t[k] = v
		end
	end
	return t
end

function UI.corner(r)
	return new("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r or 2) })
end

function UI.stroke(color, thickness, transparency)
	return new("UIStroke", {
		Color = color or C.ink,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function UI.pad(t, r, b, l)
	return new("UIPadding", {
		PaddingTop = UDim.new(0, t or 0),
		PaddingRight = UDim.new(0, r or t or 0),
		PaddingBottom = UDim.new(0, b or t or 0),
		PaddingLeft = UDim.new(0, l or r or t or 0),
	})
end

function UI.list(dir, padding, hAlign, vAlign)
	return new("UIListLayout", {
		FillDirection = dir or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, padding or 0),
		HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

function UI.frame(props)
	return new("Frame", merge({
		BorderSizePixel = 0,
		BackgroundColor3 = C.paper,
	}, props))
end

function UI.text(props)
	return new("TextLabel", merge({
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = F.serif,
		TextColor3 = C.ink,
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, props))
end

function UI.hit(props)
	return new("TextButton", merge({
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
	}, props))
end

function UI.tween(obj, t, props, style, dir)
	local tw = TweenService:Create(
		obj,
		TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

function UI.shake(obj, amount)
	local base = obj.Position
	amount = amount or 4
	task.spawn(function()
		for i = 1, 6 do
			local dx = (i % 2 == 0 and 1 or -1) * amount * (1 - i / 7)
			obj.Position = base + UDim2.fromOffset(dx, 0)
			task.wait(0.03)
		end
		obj.Position = base
	end)
end

local upperMap = {
	["ā"] = "Ā", ["č"] = "Č", ["ē"] = "Ē", ["ģ"] = "Ģ", ["ī"] = "Ī", ["ķ"] = "Ķ",
	["ļ"] = "Ļ", ["ņ"] = "Ņ", ["š"] = "Š", ["ū"] = "Ū", ["ž"] = "Ž",
}
function UI.upper(s)
	local out = string.upper(s)
	for lo, up in upperMap do
		out = string.gsub(out, lo, up)
	end
	return out
end
function UI.capFirst(s)
	local first = utf8.offset(s, 2)
	if not first then
		return UI.upper(s)
	end
	return UI.upper(string.sub(s, 1, first - 1)) .. string.sub(s, first)
end

------------------------------------------------------------------------
-- paper sheet
------------------------------------------------------------------------
function UI.paper(parent, o)
	o = o or {}
	local holder = UI.frame({
		Name = o.name or "Paper",
		BackgroundTransparency = 1,
		Position = o.pos or UDim2.new(),
		Size = o.size or UDim2.fromOffset(200, 150),
		AnchorPoint = o.anchor or Vector2.zero,
		Rotation = o.rot or 0,
		ZIndex = o.z or 1,
		Parent = parent,
	})
	if o.shadow ~= false then
		UI.frame({
			Name = "Shadow",
			BackgroundColor3 = C.black,
			BackgroundTransparency = o.shadowT or 0.6,
			Position = UDim2.fromOffset(o.shadowX or 3, o.shadowY or 5),
			Size = UDim2.fromScale(1, 1),
			Parent = holder,
		})
	end
	local sheet = UI.frame({
		Name = "Sheet",
		BackgroundColor3 = o.color or C.paper,
		Size = UDim2.fromScale(1, 1),
		Parent = holder,
	})
	if o.age ~= false then
		-- viegls novecojums uz leju
		new("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(226, 220, 208)),
			Parent = sheet,
		})
	end
	return holder, sheet
end

------------------------------------------------------------------------
-- pin
------------------------------------------------------------------------
function UI.pin(parent, pos, color, z)
	local holder = UI.frame({
		Name = "Pin",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = pos,
		ZIndex = z or 20,
		Parent = parent,
	})
	UI.frame({
		BackgroundColor3 = C.black,
		BackgroundTransparency = 0.55,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(2, 3),
		ZIndex = holder.ZIndex,
		Parent = holder,
	}).Parent = holder
	local head = UI.frame({
		BackgroundColor3 = color or C.red,
		Size = UDim2.fromScale(1, 1),
		ZIndex = holder.ZIndex,
		Parent = holder,
	})
	UI.corner(UDim.new(0.5, 0)).Parent = head
	UI.corner(UDim.new(0.5, 0)).Parent = holder:GetChildren()[1]
	local shine = UI.frame({
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromOffset(4, 4),
		Position = UDim2.fromOffset(3, 3),
		ZIndex = holder.ZIndex,
		Parent = head,
	})
	UI.corner(UDim.new(0.5, 0)).Parent = shine
	return holder
end

------------------------------------------------------------------------
-- tape
------------------------------------------------------------------------
function UI.tape(parent, pos, rot, w, z)
	return UI.frame({
		Name = "Tape",
		BackgroundColor3 = C.tape,
		BackgroundTransparency = 0.25,
		Size = UDim2.fromOffset(w or 60, 18),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = pos,
		Rotation = rot or 0,
		ZIndex = z or 20,
		Parent = parent,
	})
end

------------------------------------------------------------------------
-- stamp
------------------------------------------------------------------------
function UI.stamp(parent, text, o)
	o = o or {}
	local color = o.color or C.red
	local lbl = UI.text({
		Name = "Stamp",
		Text = UI.upper(text),
		FontFace = F.type,
		TextSize = o.size or 22,
		TextColor3 = color,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		AnchorPoint = o.anchor or Vector2.new(0.5, 0.5),
		Position = o.pos or UDim2.fromScale(0.5, 0.5),
		Rotation = o.rot or -8,
		TextTransparency = 0.08,
		ZIndex = o.z or 30,
		Parent = parent,
	})
	UI.pad(4, 10).Parent = lbl
	local s = UI.stroke(color, o.thick or 2.5, 0.08)
	s.Parent = lbl
	if o.animate ~= false then
		local sc = new("UIScale", { Scale = 1.8, Parent = lbl })
		lbl.TextTransparency = 1
		s.Transparency = 1
		UI.tween(sc, 0.18, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		UI.tween(lbl, 0.12, { TextTransparency = 0.08 })
		UI.tween(s, 0.12, { Transparency = 0.08 })
	end
	return lbl
end

------------------------------------------------------------------------
-- buttons
-- style: "ink", "paper", "tag"
------------------------------------------------------------------------
function UI.button(parent, text, o)
	o = o or {}
	local style = o.style or "ink"
	local bg, fg, hoverBg, font, size
	if style == "ink" then
		bg, fg, hoverBg = C.ink, C.paper, C.red
		font, size = F.type, o.textSize or 17
	elseif style == "tag" then
		bg, fg, hoverBg = C.manila, C.ink, C.paperWhite
		font, size = F.type, o.textSize or 15
	else
		bg, fg, hoverBg = C.paper, C.ink, C.paperWhite
		font, size = o.font or F.type, o.textSize or 15
	end

	local auto = o.size == nil
	local btn = new("TextButton", {
		Name = o.name or "Button",
		Text = style == "ink" and UI.upper(text) or text,
		FontFace = font,
		TextSize = size,
		TextColor3 = fg,
		TextWrapped = not auto,
		BackgroundColor3 = bg,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Size = o.size or UDim2.fromOffset(0, 0),
		AutomaticSize = auto and Enum.AutomaticSize.XY or Enum.AutomaticSize.None,
		Position = o.pos or UDim2.new(),
		AnchorPoint = o.anchor or Vector2.zero,
		Rotation = o.rot or 0,
		LayoutOrder = o.order or 0,
		TextXAlignment = o.alignX or Enum.TextXAlignment.Center,
		ZIndex = o.z or 1,
		Parent = parent,
	})
	UI.pad(o.padY or 9, o.padX or 16).Parent = btn
	if style ~= "ink" then
		UI.stroke(C.ink, style == "tag" and 1 or 1.5, style == "tag" and 0.5 or 0).Parent = btn
	end
	if style == "tag" then
		-- caurums birškai
		local hole = UI.frame({
			BackgroundColor3 = C.paperWhite,
			Size = UDim2.fromOffset(7, 7),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, -8, 0.5, 0),
			ZIndex = btn.ZIndex,
			Parent = btn,
		})
		UI.corner(UDim.new(0.5, 0)).Parent = hole
		UI.stroke(C.manilaDark, 1).Parent = hole
	end

	local enabled = true
	local baseRot = btn.Rotation
	btn.MouseEnter:Connect(function()
		if not enabled then return end
		UI.tween(btn, 0.12, { BackgroundColor3 = hoverBg, Rotation = baseRot - 1 })
	end)
	btn.MouseLeave:Connect(function()
		UI.tween(btn, 0.12, { BackgroundColor3 = bg, Rotation = baseRot })
	end)
	if o.onClick then
		btn.Activated:Connect(function()
			if enabled then
				o.onClick(btn)
			end
		end)
	end

	local api = {}
	function api.setEnabled(v)
		enabled = v
		btn.BackgroundTransparency = v and 0 or 0.55
		btn.TextTransparency = v and 0 or 0.45
		btn.Active = v
	end
	function api.setText(t)
		btn.Text = style == "ink" and UI.upper(t) or t
	end
	api.instance = btn
	if o.disabled then
		api.setEnabled(false)
	end
	return btn, api
end

------------------------------------------------------------------------
-- foto siluete
------------------------------------------------------------------------
local function blob(parent, props, radius)
	local f = UI.frame(merge({ BackgroundColor3 = C.silhouette }, props))
	f.Parent = parent
	if radius then
		UI.corner(radius).Parent = f
	end
	return f
end

function UI.silhouette(photo, look, small)
	look = look or {}
	local has = {}
	for _, k in look do
		has[k] = true
	end
	local z = photo.ZIndex
	local sc = small and 0.86 or 1
	local root = UI.frame({
		Name = "Silhouette",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = z,
		Parent = photo,
	})
	local round = UDim.new(0.5, 0)
	local headY = small and 0.28 or 0.2
	local headS = 0.36 * sc

	if has.hood then
		blob(root, { Size = UDim2.fromScale(headS * 1.42, headS * 1.42), SizeConstraint = Enum.SizeConstraint.RelativeXX,
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, headY - 0.06), ZIndex = z }, UDim.new(0.42, 0))
	end
	if has.longhair then
		blob(root, { Size = UDim2.fromScale(headS * 1.3, 0.5), AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, headY - 0.02), ZIndex = z }, UDim.new(0.4, 0))
	end
	if has.backpack then
		blob(root, { Size = UDim2.fromScale(0.3, 0.34), AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0.62, 1), ZIndex = z }, UDim.new(0.25, 0))
	end

	local shoulderW = 0.8 * sc
	blob(root, { Size = UDim2.fromScale(shoulderW, 0.34), AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1), ZIndex = z }, UDim.new(0.45, 0))
	blob(root, { Size = UDim2.fromScale(shoulderW, 0.14), AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1), ZIndex = z })
	blob(root, { Size = UDim2.fromScale(0.14 * sc, 0.2), AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, headY + 0.28), ZIndex = z })
	local head = blob(root, { Name = "Head", Size = UDim2.fromScale(headS, headS), SizeConstraint = Enum.SizeConstraint.RelativeXX,
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, headY), ZIndex = z }, round)

	if has.bun then
		blob(root, { Size = UDim2.fromScale(0.15, 0.15), SizeConstraint = Enum.SizeConstraint.RelativeXX,
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, headY + 0.005), ZIndex = z }, round)
	end
	if has.cap then
		blob(root, { Size = UDim2.fromScale(headS * 1.02, 0.11), AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, headY - 0.01), ZIndex = z }, UDim.new(0.5, 0))
		blob(root, { Size = UDim2.fromScale(0.2, 0.035), AnchorPoint = Vector2.new(0, 0),
			Position = UDim2.fromScale(0.5, headY + 0.08), ZIndex = z }, UDim.new(0.5, 0))
	end
	if has.fedora then
		blob(root, { Size = UDim2.fromScale(0.3, 0.12), AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, headY + 0.07), ZIndex = z }, UDim.new(0.18, 0))
		blob(root, { Size = UDim2.fromScale(0.58, 0.04), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, headY + 0.075), ZIndex = z }, UDim.new(0.5, 0))
	end
	if has.headphones then
		for _, x in { 0.5 - headS / 2 - 0.01, 0.5 + headS / 2 + 0.01 } do
			blob(root, { Size = UDim2.fromScale(0.075, 0.15), AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(x, headY + 0.36), ZIndex = z }, UDim.new(0.4, 0))
		end
	end
	if has.glasses then
		for _, x in { 0.43, 0.57 } do
			local ring = UI.frame({ BackgroundTransparency = 1, Size = UDim2.fromScale(0.095, 0.095), SizeConstraint = Enum.SizeConstraint.RelativeXX,
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, headY + 0.17), ZIndex = z, Parent = root })
			UI.corner(round).Parent = ring
			UI.stroke(C.photoLight, 1.5, 0.15).Parent = ring
		end
		UI.frame({ BackgroundColor3 = C.photoLight, BackgroundTransparency = 0.15, Size = UDim2.fromScale(0.04, 0.012),
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, headY + 0.17), ZIndex = z, Parent = root })
	end
	if has.phone then
		local ph = UI.frame({ BackgroundColor3 = Color3.fromRGB(196, 214, 230), Size = UDim2.fromScale(0.1, 0.16),
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.68, 0.84), Rotation = 12, ZIndex = z, Parent = root })
		UI.corner(2).Parent = ph
		UI.stroke(Color3.fromRGB(230, 240, 250), 2, 0.6).Parent = ph
	end
	return root, head
end

------------------------------------------------------------------------
-- polaroid
------------------------------------------------------------------------
function UI.polaroid(parent, o)
	local size = o.size or UDim2.fromOffset(100, 122)
	local holder, sheet = UI.paper(parent, {
		name = o.name or "Polaroid",
		pos = o.pos, size = size, rot = o.rot, anchor = o.anchor,
		color = C.paperWhite, z = o.z, age = false,
	})
	local z = holder.ZIndex
	sheet.ZIndex = z
	for _, ch in holder:GetChildren() do
		if ch:IsA("GuiObject") then ch.ZIndex = z end
	end
	local m = math.max(5, math.floor(size.X.Offset * 0.07))
	local photo = UI.frame({
		Name = "Photo",
		BackgroundColor3 = Color3.new(1, 1, 1),
		Position = UDim2.fromOffset(m, m),
		Size = UDim2.new(1, -2 * m, 0.76, -m),
		ZIndex = z,
		Parent = sheet,
	})
	new("UIGradient", {
		Rotation = 55,
		Color = ColorSequence.new(C.photoLight, C.photo),
		Parent = photo,
	})
	UI.silhouette(photo, o.look, o.small)
	if o.caption then
		UI.text({
			Name = "Caption",
			Text = o.caption,
			FontFace = F.hand,
			TextSize = o.captionSize or 16,
			TextColor3 = C.blue,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Position = UDim2.new(0, 2, 0.76, 0),
			Size = UDim2.new(1, -4, 0.24, 0),
			ZIndex = z,
			Parent = sheet,
		})
	end
	return holder, sheet, photo
end

------------------------------------------------------------------------
-- thread
------------------------------------------------------------------------
function UI.thread(parent, a, b, o)
	o = o or {}
	local d = b - a
	local len = d.Magnitude
	local mid = (a + b) / 2
	local line = UI.frame({
		Name = "Thread",
		BackgroundColor3 = o.color or C.redBright,
		Size = UDim2.fromOffset(o.animate and 0 or len, o.width or 2),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(mid.X, mid.Y),
		Rotation = math.deg(math.atan2(d.Y, d.X)),
		ZIndex = o.z or 18,
		Parent = parent,
	})
	if o.animate then
		UI.tween(line, 0.45, { Size = UDim2.fromOffset(len, o.width or 2) })
	end
	return line
end

------------------------------------------------------------------------
-- typewriter effect
------------------------------------------------------------------------
function UI.typewrite(label, cps, onDone)
	local ctrl = { done = false }
	label.MaxVisibleGraphemes = 0
	local total = utf8.len(label.ContentText) or #label.ContentText
	local thread
	function ctrl.skip()
		if ctrl.done then return end
		ctrl.done = true
		if thread and coroutine.status(thread) ~= "dead" and thread ~= coroutine.running() then
			pcall(task.cancel, thread)
		end
		label.MaxVisibleGraphemes = -1
		if onDone then onDone() end
	end
	thread = task.spawn(function()
		local shown = 0
		local step = 1 / (cps or 45)
		while shown < total do
			task.wait(step)
			if ctrl.done or not label.Parent then return end
			shown += 1
			label.MaxVisibleGraphemes = shown
		end
		if not ctrl.done then
			ctrl.done = true
			label.MaxVisibleGraphemes = -1
			if onDone then onDone() end
		end
	end)
	return ctrl
end

------------------------------------------------------------------------
-- text flow
------------------------------------------------------------------------
function UI.flow(parent, parts, o)
	o = o or {}
	local size = o.size or 16
	local lineH = o.lineHeight or math.floor(size * 1.45)
	local spaceW = o.spaceWidth or math.floor(size * 0.3)
	local z = o.z or 1
	local box = UI.frame({
		Name = "Flow",
		BackgroundTransparency = 1,
		Size = o.boxSize or UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = o.order or 0,
		ZIndex = z,
		Parent = parent,
	})
	local layout = UI.list(Enum.FillDirection.Horizontal, 0)
	layout.Wraps = true
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	if o.alignRight then
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	end
	layout.Parent = box

	local order = 0
	local pendingSpace = false
	local buttons = {}

	local function spacer()
		order += 1
		UI.frame({ BackgroundTransparency = 1, Size = UDim2.fromOffset(spaceW, lineH), LayoutOrder = order, ZIndex = z, Parent = box })
	end

	local function item(text, part)
		if pendingSpace and order > 0 then
			spacer()
		end
		pendingSpace = false
		order += 1
		local b = new("TextButton", {
			Name = part and (part.clue or part.decoy or "Phrase") or "Word",
			Text = text,
			FontFace = (part and part.font) or o.font or F.serif,
			TextSize = size,
			TextColor3 = (part and part.color) or o.color or C.ink,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			TextWrapped = false,
			Size = UDim2.fromOffset(0, lineH),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = order,
			ZIndex = z,
			Parent = box,
		})
		if o.onPart then
			b.Activated:Connect(function()
				o.onPart(part, b)
			end)
		end
		if part then
			table.insert(buttons, { part = part, button = b })
		end
		return b
	end

	for _, p in parts do
		if type(p) == "string" then
			if o.wordsTappable == false then
			end
			local pos = 1
			for ws, word in string.gmatch(p, "(%s*)(%S+)") do
				if #ws > 0 then pendingSpace = true end
				item(word, nil)
				pos += #ws + #word
			end
			if string.match(p, "%s$") then
				pendingSpace = true
			end
			if string.match(p, "^%s+$") then
				pendingSpace = true
			end
		else
			item(p[1], p)
		end
	end
	return box, buttons
end

------------------------------------------------------------------------
-- red marker
------------------------------------------------------------------------
function UI.marker(button, color, animate)
	if button:FindFirstChild("Marker") then return end
	local ring = UI.frame({
		Name = "Marker",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 12, 1, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Rotation = -2,
		ZIndex = button.ZIndex + 1,
		Parent = button,
	})
	UI.corner(UDim.new(0.5, 0)).Parent = ring
	local s = UI.stroke(color or C.redBright, 2.2, animate == false and 0.05 or 1)
	s.Parent = ring
	if animate ~= false then
		local sc = new("UIScale", { Scale = 1.25, Parent = ring })
		UI.tween(sc, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
		UI.tween(s, 0.15, { Transparency = 0.05 })
	end
	return ring
end

function UI.pencilMark(button)
	if button:FindFirstChild("Pencil") then return end
	UI.frame({
		Name = "Pencil",
		BackgroundColor3 = C.blue,
		BackgroundTransparency = 0.35,
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -5),
		Rotation = 1,
		ZIndex = button.ZIndex + 1,
		Parent = button,
	})
end

------------------------------------------------------------------------
-- index card
------------------------------------------------------------------------
function UI.indexCard(parent, o)
	local holder, sheet = UI.paper(parent, {
		name = o.name or "IndexCard",
		pos = o.pos, size = o.size, rot = o.rot, anchor = o.anchor,
		color = C.card, z = o.z, age = false,
	})
	local z = holder.ZIndex
	for _, ch in holder:GetChildren() do
		if ch:IsA("GuiObject") then ch.ZIndex = z end
	end
	local h = o.size.Y.Offset
	local top = o.lineTop or 30
	local y = top
	while y < h - 6 do
		UI.frame({ BackgroundColor3 = C.cardLine, BackgroundTransparency = 0.45, Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.fromOffset(0, y), ZIndex = z, Parent = sheet })
		y += o.lineGap or 22
	end
	UI.frame({ BackgroundColor3 = C.cardMargin, BackgroundTransparency = 0.3, Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.fromOffset(0, top - 6), ZIndex = z, Parent = sheet })
	return holder, sheet
end

------------------------------------------------------------------------
-- background
------------------------------------------------------------------------
function UI.desk(parent)
	local bg = UI.frame({
		Name = "Desk",
		BackgroundColor3 = C.desk,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	local rng = Random.new(11)
	for i = 1, 26 do
		UI.frame({
			BackgroundColor3 = C.deskGrain,
			BackgroundTransparency = rng:NextNumber(0.35, 0.8),
			Size = UDim2.new(1, 0, 0, rng:NextInteger(1, 3)),
			Position = UDim2.fromScale(0, (i - 1) / 26 + rng:NextNumber(-0.01, 0.01)),
			Rotation = rng:NextNumber(-0.3, 0.3),
			Parent = bg,
		})
	end
	for i = 1, 16 do
		local s = 0.45 + i * 0.09
		local c = UI.frame({
			BackgroundColor3 = C.lamp,
			BackgroundTransparency = 0.983,
			Size = UDim2.fromScale(s, s),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.42, 0.3),
			Parent = bg,
		})
		UI.corner(UDim.new(0.5, 0)).Parent = c
	end
	local function edge(rot, size, pos, anchor)
		local e = UI.frame({
			BackgroundColor3 = C.black,
			Size = size,
			Position = pos,
			AnchorPoint = anchor,
			Parent = bg,
		})
		new("UIGradient", {
			Rotation = rot,
			Transparency = NumberSequence.new(0.25, 1),
			Parent = e,
		})
	end
	edge(0, UDim2.fromScale(0.18, 1), UDim2.fromScale(0, 0), Vector2.zero)
	edge(180, UDim2.fromScale(0.18, 1), UDim2.fromScale(1, 0), Vector2.new(1, 0))
	edge(90, UDim2.fromScale(1, 0.25), UDim2.fromScale(0, 0), Vector2.zero)
	edge(-90, UDim2.fromScale(1, 0.25), UDim2.fromScale(0, 1), Vector2.new(0, 1))
	return bg
end

return UI
