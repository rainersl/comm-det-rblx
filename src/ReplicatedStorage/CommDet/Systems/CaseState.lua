-- Comm-Det: the state of one investigation (time, evidence, decisions, results)
local Config = require(script.Parent.Parent.Config)

local CaseState = {}
CaseState.__index = CaseState

function CaseState.new(case)
	local self = setmetatable({}, CaseState)
	self.case = case

	-- evidence & clues
	self.found = {}
	self.foundOrder = {}
	self.decoys = {}
	self.decoyCount = 0
	self.revealed = {}
	self.hintsLeft = Config.HINTS
	self.hintsUsed = 0
	self.tutorial = {}

	-- time
	self.day = 1
	self.slot = 1
	self.timeUp = false

	-- field work
	self.kits = Config.TEST_KITS
	self.samples = {}        -- [pointId] = { value = n, night = bool }
	self.recordsRequested = false
	self.moneyOpened = false
	self.links = {}          -- ["a|b|rel"] = true
	self.falseLinks = 0

	-- interviews
	self.visited = {}
	self.asked = {}
	self.resolved = {}
	self.transcripts = {}
	self.claimFails = 0

	-- decisions & consequences
	self.decisions = {}      -- [phoneId] = choice
	self.phoneDone = {}
	self.meterBonus = { safety = 0, justice = 0, trust = 0 }
	self.institutions = {}
	self.notice = {}         -- [slotId] = option index
	self.noticeQuality = {}
	self.hearingTrust = nil

	self.changed = Instance.new("BindableEvent")
	return self
end

function CaseState:fire(what, id)
	self.changed:Fire(what, id)
end

------------------------------------------------------------------------
-- Clues & evidence
------------------------------------------------------------------------
function CaseState:has(id)
	return self.found[id] == true
end

function CaseState:hasAny(list)
	if type(list) == "string" then return self:has(list) end
	for _, id in list do
		if self:has(id) then return true end
	end
	return false
end

function CaseState:find(id)
	if self.found[id] or not self.case.clues[id] then
		return false
	end
	self.found[id] = true
	table.insert(self.foundOrder, id)
	self:fire("clue", id)
	return true
end

function CaseState:markDecoy(id)
	if self.decoys[id] then return false end
	self.decoys[id] = true
	self.decoyCount += 1
	self:fire("decoy", id)
	return true
end

function CaseState:isVisible(ev)
	return not ev.hidden or self.revealed[ev.id] == true
end

function CaseState:reveal(evId)
	if self.revealed[evId] then return false end
	self.revealed[evId] = true
	self:fire("reveal", evId)
	return true
end

function CaseState:countFound()
	local n, total = 0, 0
	for id in self.case.clues do
		total += 1
		if self.found[id] then n += 1 end
	end
	return n, total
end

function CaseState:useHint()
	if self.hintsLeft <= 0 then return nil end
	local text = self.case.hintFallback
	for _, h in self.case.hints do
		if not self:has(h.need) then
			text = h.text
			break
		end
	end
	self.hintsLeft -= 1
	self.hintsUsed += 1
	self:fire("hint")
	return text
end

function CaseState:isOptionUnlocked(opt)
	if not opt.requires then return true end
	for _, id in opt.requires do
		if not self:has(id) then return false end
	end
	return true
end

------------------------------------------------------------------------
-- Time
------------------------------------------------------------------------
function CaseState:timeIndex()
	return (self.day - 1) * #Config.SLOTS + self.slot
end

function CaseState:totalSlots()
	return Config.DAYS * #Config.SLOTS
end

function CaseState:slotName()
	return Config.SLOTS[self.slot]
end

function CaseState:dayName()
	return Config.DAY_NAMES[self.day] or ("Day " .. self.day)
end

function CaseState:isNight()
	return self.slot == #Config.SLOTS
end

function CaseState:isOpen(loc)
	return table.find(loc.open, self.slot) ~= nil
end

-- Spend time. Returns true when the investigation time is over.
function CaseState:spend(n)
	for _ = 1, n or 1 do
		if self.slot < #Config.SLOTS then
			self.slot += 1
		elseif self.day < Config.DAYS then
			self.day += 1
			self.slot = 1
		else
			self.timeUp = true
		end
	end
	self:fire("time")
	return self.timeUp
end

------------------------------------------------------------------------
-- Decisions
------------------------------------------------------------------------
function CaseState:applyEffect(phoneId, effect)
	self.phoneDone[phoneId] = true
	if not effect then return end
	self.decisions[phoneId] = effect.decision
	for _, k in { "safety", "justice", "trust" } do
		if effect[k] then
			self.meterBonus[k] += effect[k]
		end
	end
	if effect.reveal then self:reveal(effect.reveal) end
	if effect.clue then self:find(effect.clue) end
	self:fire("decision", phoneId)
end

function CaseState:pendingPhone()
	for _, msg in self.case.phone do
		if not self.phoneDone[msg.id] and msg.when(self) then
			return msg
		end
	end
end

return CaseState
