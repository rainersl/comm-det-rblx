-- future mi integration
local Config = require(script.Parent.Parent.Config)

local AIBridge = {}

function AIBridge.isEnabled()
	return Config.AI_ENABLED == true
end

function AIBridge.askWitness(caseData, witnessId, question)
	if not AIBridge.isEnabled() then
		return nil
	end
	-- TODO: call server TextGenerator
	return nil
end

function AIBridge.evaluateFreeText(caseData, msgId, text)
	if not AIBridge.isEnabled() then
		return nil
	end
	-- TODO: TextGenerator with JsonSchema: { hasDate, hasTime, hasPlace, hasItems, register, unclearPhrases[] }
	return nil
end

return AIBridge
