-- Comm-Det: global settings
local Config = {}

-- Design "stage" size. All UI is laid out in these coordinates and scaled with
-- UIScale, so it fits both computers and phones.
Config.STAGE = Vector2.new(960, 540)

-- Time: 3 days, each split into 4 parts. Most actions cost one part.
Config.DAYS = 3
Config.SLOTS = { "Morning", "Afternoon", "Evening", "Night" }
Config.DAY_NAMES = { "Tuesday", "Wednesday", "Thursday" }

Config.TEST_KITS = 4      -- water test kits
Config.HINTS = 3          -- hints available
Config.PHONE_TIMER = 25   -- seconds to answer a phone message

-- AI (Roblox TextGenerator). Off for now; see Systems/AIBridge.
Config.AI_ENABLED = false

-- Development: start straight on a screen (nil = normal start)
Config.DEBUG_START = nil

return Config
