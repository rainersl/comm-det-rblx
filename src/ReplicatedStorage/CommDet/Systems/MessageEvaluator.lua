-- final message evaluation, aibridge placeholder
local Config = require(script.Parent.Parent.Config)
local AIBridge = require(script.Parent.AIBridge)

local Evaluator = {}

local function findMessage(case, msgId)
	for _, m in case.messages do
		if m.id == msgId then return m end
	end
end

local function findSlot(msg, slotId)
	for _, s in msg.slots do
		if s.id == slotId then return s end
	end
end

function Evaluator.selectedOption(case, state, msgId, slotId)
	local msg = findMessage(case, msgId)
	local slot = msg and findSlot(msg, slotId)
	local idx = state.choices[msgId][slotId]
	if slot and idx then
		return slot.options[idx], slot
	end
	return nil, slot
end

function Evaluator.quality(case, state, msgId, slotId)
	local opt = Evaluator.selectedOption(case, state, msgId, slotId)
	return opt and opt.q or nil
end

local function capFirst(s)
	local first = utf8.offset(s, 2)
	if not first then return s end
	local head = string.sub(s, 1, first - 1)
	local map = { ["ā"] = "Ā", ["č"] = "Č", ["ē"] = "Ē", ["ģ"] = "Ģ", ["ī"] = "Ī", ["ķ"] = "Ķ",
		["ļ"] = "Ļ", ["ņ"] = "Ņ", ["š"] = "Š", ["ū"] = "Ū", ["ž"] = "Ž" }
	head = map[head] or string.upper(head)
	return head .. string.sub(s, first)
end

function Evaluator.compose(case, state, msg)
	local out = string.gsub(msg.template, "{(%w+)(%^?)}", function(slotId, cap)
		local opt = Evaluator.selectedOption(case, state, msg.id, slotId)
		local t = opt and opt.text or "____"
		if cap == "^" then t = capFirst(t) end
		return t
	end)
	out = string.gsub(out, ",%.", ".")
	out = string.gsub(out, "%.%.", ".")
	out = string.gsub(out, "!%.", "!")
	return out
end

function Evaluator.isComplete(case, state)
	for _, m in case.messages do
		for _, s in m.slots do
			if not state.choices[m.id][s.id] then return false end
		end
	end
	return true
end

function Evaluator.evaluateMessage(case, state, msg)
	local r = { issues = {}, clear = 0, ok = 0, vague = 0, wrong = 0, register = 0, factClear = 0, factTotal = 0 }
	for _, s in msg.slots do
		local opt = Evaluator.selectedOption(case, state, msg.id, s.id)
		local q = opt and opt.q or "vague"
		r[q] += 1
		if s.fact then
			r.factTotal += 1
			if q == "clear" then r.factClear += 1 end
		end
		if q ~= "clear" and q ~= "ok" then
			table.insert(r.issues, { label = s.label, text = opt and opt.text or "—", q = q, why = opt and opt.why or "" })
		end
	end
	return r
end

local function stars3(v, hi, mid)
	if v >= hi then return 3 elseif v >= mid then return 2 else return 1 end
end

function Evaluator.evaluateCase(case, state)
	local res = { messages = {}, stars = {} }
	local tot = { vague = 0, wrong = 0, register = 0, factClear = 0, factTotal = 0 }
	for _, m in case.messages do
		local r = Evaluator.evaluateMessage(case, state, m)
		res.messages[m.id] = r
		for k in tot do tot[k] += r[k] end
	end

	local found, total = state:countFound()
	local inv = (found / total) * 0.7 + (state.deduction.score or 0) * 0.3
	inv -= 0.06 * state.decoyCount + 0.05 * state.hintsUsed + 0.03 * state.claimFails
	res.stars.investigation = stars3(inv, 0.78, 0.5)

	local acc = tot.factClear / math.max(1, tot.factTotal)
	local a = stars3(acc, 0.99, 0.6)
	if tot.wrong > 0 then a = math.min(a, 2) end
	if tot.wrong > 1 then a = 1 end
	res.stars.accuracy = a

	res.stars.clarity = tot.vague == 0 and 3 or (tot.vague <= 2 and 2 or 1)

	res.stars.appropriateness = tot.register == 0 and 3 or (tot.register == 1 and 2 or 1)

	local sum = 0
	for _, v in res.stars do sum += v end
	res.total = sum
	if sum >= 12 then
		res.rank = "Vecākais komunikācijas detektīvs"
	elseif sum >= 10 then
		res.rank = "Vecākais detektīvs"
	elseif sum >= 7 then
		res.rank = "Detektīvs"
	else
		res.rank = "Kadets"
	end

	res.cards = case.replay(function(msgId, slotId)
		return Evaluator.quality(case, state, msgId, slotId)
	end)
	local arrived = 0
	for _, c in res.cards do arrived += c.count end
	res.arrived = arrived
	res.success = arrived >= Config.TEAM_NEEDED
	res.found, res.totalClues = found, total
	return res
end

function Evaluator.evaluateFreeText(case, msgId, text)
	return AIBridge.evaluateFreeText(case, msgId, text)
end

return Evaluator
