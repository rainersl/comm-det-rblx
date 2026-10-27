-- case status
local Config = require(script.Parent.Parent.Config)

local CaseState = {}
CaseState.__index = CaseState

function CaseState.new(case)
	local self = setmetatable({}, CaseState)
	self.case = case
	self.found = {}          -- [clueId] = true
	self.foundOrder = {}
	self.decoys = {}         -- [decoyId] = true
	self.decoyCount = 0
	self.tokens = Config.INTERVIEW_TOKENS
	self.interviewed = {}    -- [witnessId] = true
	self.asked = {}          -- [witnessId] = { [topicIndex] = true }
	self.resolved = {}       -- [witnessId..topicIndex] = true
	self.claimFails = 0
	self.hintsLeft = Config.HINTS
	self.hintsUsed = 0
	self.revealed = {}       -- [evidenceId] = true
	self.deduction = { picks = {}, done = false, score = 0 }
	self.choices = {}        -- [msgId] = { [slotId] = optionIndex }
	for _, m in case.messages do
		self.choices[m.id] = {}
	end
	self.tutorial = {}       -- [stepId] = true
	self.changed = Instance.new("BindableEvent")
	return self
end

function CaseState:fire(what, id)
	self.changed:Fire(what, id)
end

function CaseState:has(clueId)
	return self.found[clueId] == true
end

function CaseState:find(clueId)
	if self.found[clueId] or not self.case.clues[clueId] then
		return false
	end
	self.found[clueId] = true
	table.insert(self.foundOrder, clueId)
	self:fire("clue", clueId)
	return true
end

function CaseState:markDecoy(decoyId)
	if self.decoys[decoyId] then
		return false
	end
	self.decoys[decoyId] = true
	self.decoyCount += 1
	self:fire("decoy", decoyId)
	return true
end

function CaseState:isVisible(ev)
	return not ev.hidden or self.revealed[ev.id] == true
end

function CaseState:reveal(evId)
	if self.revealed[evId] then return false end
	self.revealed[evId] = true
	-- slēptā pierādījuma atrašana dod papildu sarunu
	self.tokens += 1
	self:fire("reveal", evId)
	return true
end

function CaseState:canInterview(w)
	return self.interviewed[w] or self.tokens > 0
end

function CaseState:startInterview(w)
	if self.interviewed[w] then return true end
	if self.tokens <= 0 then return false end
	self.tokens -= 1
	self.interviewed[w] = true
	self.asked[w] = self.asked[w] or {}
	self:fire("interview", w)
	return true
end

function CaseState:useHint()
	if self.hintsLeft <= 0 then
		return nil
	end
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

function CaseState:countFound()
	local n, total = 0, 0
	for id in self.case.clues do
		total += 1
		if self.found[id] then n += 1 end
	end
	return n, total
end

function CaseState:choose(msgId, slotId, index)
	self.choices[msgId][slotId] = index
	self:fire("choice", msgId)
end

function CaseState:isOptionUnlocked(opt)
	if not opt.requires then return true end
	for _, id in opt.requires do
		if not self:has(id) then return false end
	end
	return true
end

return CaseState
