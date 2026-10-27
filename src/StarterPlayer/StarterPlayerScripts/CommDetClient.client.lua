local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

task.spawn(function()
	for _ = 1, 10 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		end)
		if ok then break end
		task.wait(0.2)
	end
end)

local root = ReplicatedStorage:WaitForChild("CommDet")
local Config = require(root:WaitForChild("Config"))
local App = require(root:WaitForChild("App"))

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local app = App.new(playerGui, root.Cases.EmptyWorkshop)
app:go(Config.DEBUG_START or "Title")
