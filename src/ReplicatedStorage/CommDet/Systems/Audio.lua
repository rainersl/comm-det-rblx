-- Sound: one-shot effects and looping ambience. All sounds are free Creator Store audio
-- (mostly Pro Sound Effects, licensed by Roblox for every experience). Client-side only.
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Audio = {}

-- Master levels: change these two numbers to make everything louder or quieter.
Audio.SFX_VOLUME = 0.5
Audio.MUSIC_VOLUME = 0.16

-- name = { id, volume, extra }  (volume is before the master level above)
Audio.SOUNDS = {
	-- effects
	click   = { 9120300066, 0.12 },            -- Typewriter Key 1 (Pro Sound Effects)
	type    = { 9120300134, 0.06 },            -- Typewriter Key 2 (Pro Sound Effects)
	paper   = { 9118835414, 0.25 },            -- Scrapbook Open And Turn Pages (Pro Sound Effects)
	stamp   = { 9114348888, 0.35 },            -- Envelope Slam Down (Pro Sound Effects)
	gavel   = { 9125573400, 0.4 },             -- Gavel Hit, Light Impacts (Pro Sound Effects)
	verdict = { 9125574353, 0.45 },            -- Gavel Hit, Triple Impact (Pro Sound Effects)
	phone   = { 121031853982816, 0.4 },        -- Phone Vibrating On Table (Creator Store)
	pour    = { 9117865991, 0.3, loop = true }, -- Pour Water In Glass (Pro Sound Effects)
	torch   = { 9114481274, 0.35 },            -- Flashlight Switch (Pro Sound Effects)
	-- ambience (looped)
	rain    = { 9112856768, 0.12, loop = true }, -- Rain On Window (Pro Sound Effects)
	river   = { 9119647236, 0.2, loop = true },  -- Stream, Small River (Pro Sound Effects)
	crickets= { 9112764546, 0.14, loop = true }, -- Crickets Night (Pro Sound Effects)
	crowd   = { 9119996106, 0.14, loop = true }, -- Theatre Crowd, subdued walla (Pro Sound Effects)
}

-- Background music: free DistroKid tracks from the Creator Store, played in a shuffled loop.
Audio.MUSIC = {
	{ 136687089974030, 0.35 }, -- Rainy Day Work Piano
	{ 133914369779227, 0.35 }, -- Quiet Morning Drizzle
	{ 102696255971003, 0.35 }, -- Piano Dreams
}

-- Which ambience plays on which screen. Screens not listed keep what's playing.
Audio.AMBIENCE = {
	Title = { "rain" }, Briefing = { "rain" }, Map = { "rain" }, Board = { "rain" }, Viewer = { "rain" },
	Interview = { "rain" }, MoneyTrail = { "rain" }, Report = { "rain" },
	Sampling = { "river" }, SamplingNight = { "river", "crickets" },
	Hearing = { "crowd" }, Ending = { "river" },
}

local enabled = RunService:IsRunning() -- stay silent in Edit-mode previews
local muted = false
local folder
local loops = {} -- name -> Sound
local lastPlayed = {}

local sfxGroup, musicGroup
local function getFolder()
	if not folder or not folder.Parent then
		folder = SoundService:FindFirstChild("CommDetAudio") or Instance.new("Folder")
		folder.Name = "CommDetAudio"
		folder.Parent = SoundService
		sfxGroup = Instance.new("SoundGroup")
		sfxGroup.Name = "SFX"
		sfxGroup.Volume = Audio.SFX_VOLUME
		sfxGroup.Parent = folder
		musicGroup = Instance.new("SoundGroup")
		musicGroup.Name = "Music"
		musicGroup.Volume = Audio.MUSIC_VOLUME
		musicGroup.Parent = folder
	end
	return folder
end

local function make(name)
	local def = Audio.SOUNDS[name]
	if not def then return nil end
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = "rbxassetid://" .. tostring(def[1])
	s.Volume = def[2]
	s.Looped = def.loop == true
	s.Parent = getFolder()
	s.SoundGroup = sfxGroup
	return s, def
end

-- Music: plays the tracks one after another (shuffled), cross-fading between them.
local musicOn = false
local musicMuted = false
local track, trackIndex, order = nil, 0, {}
local function nextTrack()
	if not musicOn then return end
	if #order == 0 then
		for i = 1, #Audio.MUSIC do table.insert(order, math.random(1, #order + 1), i) end
	end
	trackIndex = table.remove(order, 1)
	local def = Audio.MUSIC[trackIndex]
	getFolder()
	local s = Instance.new("Sound")
	s.Name = "Music"
	s.SoundId = "rbxassetid://" .. tostring(def[1])
	s.SoundGroup = musicGroup
	s.Volume = 0
	s.Parent = folder
	local old = track
	track = s
	if old then
		TweenService:Create(old, TweenInfo.new(2), { Volume = 0 }):Play()
		task.delay(2.1, function() old:Destroy() end)
	end
	s:Play()
	TweenService:Create(s, TweenInfo.new(3), { Volume = (muted or musicMuted) and 0 or def[2] }):Play()
	s.Ended:Connect(function()
		if track == s then nextTrack() end
	end)
end

function Audio.music(on)
	if not enabled then return end
	if on == musicOn then return end
	musicOn = on
	if on then
		nextTrack()
	elseif track then
		local old = track
		track = nil
		TweenService:Create(old, TweenInfo.new(1.5), { Volume = 0 }):Play()
		task.delay(1.6, function() old:Destroy() end)
	end
end

-- One-shot effect. opts: volume (multiplier), pitch, minGap (seconds between repeats)
function Audio.play(name, opts)
	if not enabled or muted then return end
	opts = opts or {}
	local now = os.clock()
	if lastPlayed[name] and now - lastPlayed[name] < (opts.minGap or 0.05) then return end
	lastPlayed[name] = now
	local s, def = make(name)
	if not s then return end
	s.Looped = false
	s.Volume = def[2] * (opts.volume or 1)
	s.PlaybackSpeed = opts.pitch or 1
	s:Play()
	s.Ended:Connect(function() s:Destroy() end)
	task.delay(8, function() if s.Parent then s:Destroy() end end)
end

-- A held sound (e.g. pouring while a button is held). Returns a stop() function.
function Audio.hold(name)
	if not enabled or muted then return function() end end
	local s = make(name)
	if not s then return function() end end
	s.Looped = true
	s:Play()
	return function()
		if s.Parent then
			TweenService:Create(s, TweenInfo.new(0.15), { Volume = 0 }):Play()
			task.delay(0.2, function() s:Destroy() end)
		end
	end
end

-- Cross-fade the background loops to the given list of names.
function Audio.ambience(names)
	if not enabled then return end
	local want = {}
	for _, n in names do want[n] = true end
	for n, s in loops do
		if not want[n] then
			loops[n] = nil
			TweenService:Create(s, TweenInfo.new(1.2), { Volume = 0 }):Play()
			task.delay(1.3, function() s:Destroy() end)
		end
	end
	for n in want do
		if not loops[n] then
			local s, def = make(n)
			if s then
				loops[n] = s
				s.Looped = true
				s.Volume = 0
				s:Play()
				if not muted then
					TweenService:Create(s, TweenInfo.new(1.5), { Volume = def[2] }):Play()
				end
			end
		end
	end
end

function Audio.forScreen(screenName, args)
	Audio.music(true)
	local key = screenName
	if screenName == "Sampling" and args and args.night then key = "SamplingNight" end
	local list = Audio.AMBIENCE[key]
	if list then Audio.ambience(list) end
end

function Audio.isMuted() return muted end
function Audio.isMusicMuted() return musicMuted end

function Audio.setMusicMuted(m)
	musicMuted = m
	if track and trackIndex > 0 then
		TweenService:Create(track, TweenInfo.new(0.4), { Volume = (m or muted) and 0 or Audio.MUSIC[trackIndex][2] }):Play()
	end
end

function Audio.setMuted(m)
	muted = m
	for n, s in loops do
		TweenService:Create(s, TweenInfo.new(0.3), { Volume = m and 0 or Audio.SOUNDS[n][2] }):Play()
	end
	if track and trackIndex > 0 then
		TweenService:Create(track, TweenInfo.new(0.3), { Volume = (m or musicMuted) and 0 or Audio.MUSIC[trackIndex][2] }):Play()
	end
end

return Audio
