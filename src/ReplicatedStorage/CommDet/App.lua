-- Comm-Det: app core. Creates the screen layers, scales the stage, switches screens,
-- opens modals, shows short notices (toasts) and phone messages.
local Config = require(script.Parent.Config)
local UI = require(script.Parent.UIKit)
local CaseState = require(script.Parent.Systems.CaseState)
local Audio = require(script.Parent.Systems.Audio)
local C, F = UI.C, UI.F

local App = {}
App.__index = App

local STAGE = Config.STAGE

local function screenGui(parent, name, order, safe)
	return UI.new("ScreenGui", {
		Name = name,
		DisplayOrder = order,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = safe and Enum.ScreenInsets.DeviceSafeInsets or Enum.ScreenInsets.None,
		Parent = parent,
	})
end

-- 960x540 stage that scales to fit any screen
local function makeStage(gui, name)
	local stage = UI.frame({
		Name = name or "Stage",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(STAGE.X, STAGE.Y),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = gui,
	})
	local scale = UI.new("UIScale", { Parent = stage })
	local function update()
		local abs = gui.AbsoluteSize
		if abs.X > 0 and abs.Y > 0 then
			scale.Scale = math.min(abs.X / STAGE.X, abs.Y / STAGE.Y)
		end
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
	update()
	return stage
end

function App.new(playerGui, caseModule)
	local self = setmetatable({}, App)
	self.UI = UI
	self.caseModule = caseModule
	self.screens = script.Parent.Screens

	self.backdropGui = screenGui(playerGui, "CommDet_Backdrop", 0, false)
	UI.desk(self.backdropGui)

	self.mainGui = screenGui(playerGui, "CommDet_Main", 1, true)
	self.stage = makeStage(self.mainGui)

	self.overlayGui = screenGui(playerGui, "CommDet_Overlay", 5, true)
	self.overlayGui.Enabled = false
	self.dimGui = screenGui(playerGui, "CommDet_Dim", 4, false)
	self.dimGui.Enabled = false
	self.dim = UI.new("TextButton", {
		Name = "Dim",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = C.black,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = self.dimGui,
	})
	self.overlayStage = makeStage(self.overlayGui, "OverlayStage")

	self.toastGui = screenGui(playerGui, "CommDet_Toast", 10, true)
	self.toastStage = makeStage(self.toastGui, "ToastStage")

	-- sound on/off switch, top-right corner
	local soundBtn = UI.new("TextButton", {
		Name = "SoundToggle", Text = "SOUND: ON", FontFace = F.mono, TextSize = 9, TextColor3 = C.paper,
		BackgroundColor3 = C.ink, BackgroundTransparency = 0.35, BorderSizePixel = 0, AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 0), Size = UDim2.fromOffset(72, 13), ZIndex = 60,
		Parent = self.toastStage,
	})
	UI.corner(4).Parent = soundBtn
	soundBtn.Activated:Connect(function()
		Audio.setMuted(not Audio.isMuted())
		soundBtn.Text = Audio.isMuted() and "SOUND: OFF" or "SOUND: ON"
		Audio.play("click")
	end)
	local musicBtn = soundBtn:Clone()
	musicBtn.Name = "MusicToggle"
	musicBtn.Text = "MUSIC: ON"
	musicBtn.Position = UDim2.new(1, -80, 0, 0)
	musicBtn.Parent = self.toastStage
	musicBtn.Activated:Connect(function()
		Audio.setMusicMuted(not Audio.isMusicMuted())
		musicBtn.Text = Audio.isMusicMuted() and "MUSIC: OFF" or "MUSIC: ON"
		Audio.play("click")
	end)

	self:newCase()
	return self
end

function App:newCase()
	self.case = require(self.caseModule)
	self.state = CaseState.new(self.case)
	self.phoneOpen = false
end

-- Switch screen: Title, Briefing, Map, Board, Interview, Sampling, MoneyTrail, Report, Hearing, Ending
function App:go(screenName, args)
	self:closeModal()
	if self.cleanup then
		pcall(self.cleanup)
		self.cleanup = nil
	end
	if self.screen then
		self.screen:Destroy()
	end
	local container = UI.frame({
		Name = screenName,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = self.stage,
	})
	self.screen = container
	self.current = screenName
	Audio.forScreen(screenName, args)
	local mod = require(self.screens:WaitForChild(screenName))
	local ok, result = pcall(mod.build, self, container, args)
	if not ok then
		warn("[CommDet] Screen " .. screenName .. " failed: " .. tostring(result))
	elseif type(result) == "function" then
		self.cleanup = result
	end
	-- short fade-in
	local fade = UI.frame({ BackgroundColor3 = C.black, Size = UDim2.new(4, 0, 4, 0), Position = UDim2.fromScale(-1.5, -1.5), ZIndex = 999, Parent = container })
	UI.tween(fade, 0.35, { BackgroundTransparency = 1 }).Completed:Connect(function()
		fade:Destroy()
	end)
end

-- Modal window. builder(frame, close) builds content in 960x540 coordinates.
function App:openModal(builder, opts)
	self:closeModal()
	opts = opts or {}
	local frame = UI.frame({
		Name = "Modal",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = self.overlayStage,
	})
	self.modal = frame
	if not opts.silent then Audio.play("paper", { minGap = 0.3, pitch = 0.95 + math.random() * 0.1 }) end
	self.overlayGui.Enabled = true
	self.dimGui.Enabled = true
	self.dim.BackgroundTransparency = 1
	UI.tween(self.dim, 0.2, { BackgroundTransparency = opts.dim or 0.35 })
	local closed = false
	local function close()
		if closed then return end
		closed = true
		if self.modal == frame then
			self:closeModal()
		end
		if opts.onClose then opts.onClose() end
	end
	if self.dimConn then self.dimConn:Disconnect() end
	self.dimConn = self.dim.Activated:Connect(function()
		if opts.closeOnDim then close() end
	end)
	builder(frame, close)
	return close
end

function App:closeModal()
	if self.modal then
		self.modal:Destroy()
		self.modal = nil
	end
	self.overlayGui.Enabled = false
	self.dimGui.Enabled = false
end

-- Short notice: handwriting on a paper strip at the top of the screen
function App:toast(text, color)
	if self.toastFrame then
		self.toastFrame:Destroy()
	end
	local holder, sheet = UI.paper(self.toastStage, {
		name = "Toast",
		pos = UDim2.new(0.5, 0, 0, -70),
		size = UDim2.fromOffset(560, 58),
		anchor = Vector2.new(0.5, 0),
		rot = -1,
		color = C.card,
		z = 50,
	})
	for _, ch in holder:GetChildren() do
		if ch:IsA("GuiObject") then ch.ZIndex = 50 end
	end
	local tl = UI.text({
		Text = text,
		FontFace = F.hand,
		TextSize = 18,
		TextScaled = true,
		TextColor3 = color or C.blue,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size = UDim2.new(1, -24, 1, -8),
		Position = UDim2.fromOffset(12, 4),
		ZIndex = 51,
		Parent = sheet,
	})
	UI.new("UITextSizeConstraint", { MaxTextSize = 21, MinTextSize = 15, Parent = tl })
	UI.tape(holder, UDim2.new(0.5, 0, 0, 0), 2, 70, 52)
	self.toastFrame = holder
	UI.tween(holder, 0.25, { Position = UDim2.new(0.5, 0, 0, 10) }, Enum.EasingStyle.Back)
	task.delay(3.4, function()
		if holder.Parent then
			UI.tween(holder, 0.25, { Position = UDim2.new(0.5, 0, 0, -70) }).Completed:Connect(function()
				holder:Destroy()
			end)
		end
	end)
end

-- Spend investigation time (returns true when the three days are over)
function App:spend(n)
	return self.state:spend(n)
end

-- Show the next pending phone message, if any. Messages chain one after another.
function App:checkPhone(onDone)
	if self.phoneOpen then return end
	local msg = self.state:pendingPhone()
	if not msg then
		if onDone then onDone() end
		return
	end
	self.phoneOpen = true
	local Phone = require(self.screens:WaitForChild("Phone"))
	Phone.open(self, msg, function()
		self.phoneOpen = false
		task.delay(0.4, function()
			self:checkPhone(onDone)
		end)
	end)
end

return App
