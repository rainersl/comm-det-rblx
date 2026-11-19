-- Case 01: Murky Water
-- All case content lives here. A new case = a new file like this one.
--
-- Text parts: plain text = string; tappable phrase = { "text", clue = "id" }
-- or { "text", decoy = "id" } (looks suspicious, but is not a problem).
-- Every clue, decision and achievement is tagged with the UN SDG targets it supports.

local Case = {}

Case.id = "murky_water"
Case.number = "01"
Case.title = "Murky Water"
Case.town = "Vecupe"
Case.river = "Dzirnupe"
Case.question = "Why are the fish dying in the Dzirnupe?"

------------------------------------------------------------------------
-- UN Sustainable Development Goals used in this case (official target wording)
------------------------------------------------------------------------
Case.sdgs = {
	["3.9"] = { goal = "Good Health and Well-being", text = "Substantially reduce the number of deaths and illnesses from hazardous chemicals and air, water and soil pollution and contamination." },
	["6.3"] = { goal = "Clean Water and Sanitation", text = "Improve water quality by reducing pollution, eliminating dumping and minimizing release of hazardous chemicals and materials." },
	["6.6"] = { goal = "Clean Water and Sanitation", text = "Protect and restore water-related ecosystems, including rivers, wetlands, aquifers and lakes." },
	["12.6"] = { goal = "Responsible Consumption and Production", text = "Encourage companies to adopt sustainable practices and to integrate sustainability information into their reporting." },
	["12.8"] = { goal = "Responsible Consumption and Production", text = "Ensure that people everywhere have the relevant information and awareness for sustainable development." },
	["16.3"] = { goal = "Peace, Justice and Strong Institutions", text = "Promote the rule of law and ensure equal access to justice for all." },
	["16.5"] = { goal = "Peace, Justice and Strong Institutions", text = "Substantially reduce corruption and bribery in all their forms." },
	["16.6"] = { goal = "Peace, Justice and Strong Institutions", text = "Develop effective, accountable and transparent institutions at all levels." },
	["16.7"] = { goal = "Peace, Justice and Strong Institutions", text = "Ensure responsive, inclusive, participatory and representative decision-making at all levels." },
	["16.10"] = { goal = "Peace, Justice and Strong Institutions", text = "Ensure public access to information and protect fundamental freedoms." },
}
-- Four goals only: SDG 3, 6, 12 and 16 (see README). Shown nowhere in the game itself.
Case.sdgOrder = { "3.9", "6.3", "6.6", "12.6", "12.8", "16.3", "16.5", "16.6", "16.7", "16.10" }

------------------------------------------------------------------------
-- Characters (look = silhouette details on the polaroid)
------------------------------------------------------------------------
Case.characters = {
	chief = { name = "Chief Dūmiņš", full = "Chief Inspector Dūmiņš", role = "Head of the Bureau", look = { "fedora" } },
	janis = { name = "Jānis", full = "Jānis Ozols", role = "Fisherman, 40 years on the Dzirnupe", look = { "cap", "backpack" } },
	edgars = { name = "Edgars Kalniņš", full = "Edgars Kalniņš", role = "PR manager, AS Zaļā Druva", look = { "glasses", "tie" } },
	anna = { name = "Anna", full = "Anna Bērziņa", role = "Technician, Vecupe Water Lab", look = { "longhair", "glasses" } },
	arturs = { name = "Councillor Lapsa", full = "Councillor Artūrs Lapsa", role = "Town councillor, environment committee", look = { "tie" } },
	ieva = { name = "Ieva", full = "Ieva Liepa", role = "Mother of two, lives by the beach", look = { "longhair", "phone" } },
	rita = { name = "Rita", full = "Rita Vanaga", role = "Reporter, Vecupes Ziņas", look = { "bun", "phone" } },
	lawyer = { name = "Mr Krūmiņš", full = "Kārlis Krūmiņš", role = "Lawyer for the plant", look = { "glasses", "tie" } },
}

------------------------------------------------------------------------
-- Briefing
------------------------------------------------------------------------
Case.briefing = {
	{ who = "narr", text = "October. Third day of rain. The river below Vecupe had turned the colour of weak tea." },
	{ who = "narr", text = "On my desk: a newspaper, a printout of the town chat and a note from the chief." },
	{ who = "chief", text = "Cadet. Dead fish in the Dzirnupe — third time this week. The fertiliser plant says everything is within the limits." },
	{ who = "chief", text = "On Friday the council votes on extending the plant's permit. After that, nobody will look at this river for years." },
	{ who = "chief", text = "You have three days. Every visit, every water test and every conversation costs time. Choose well." },
	{ who = "chief", text = "And remember: an accusation without evidence is just another rumour. Bring me facts." },
}

------------------------------------------------------------------------
-- Town map (coordinates inside the 684 x 512 map)
-- open = time slots when the place is open (1 Morning, 2 Afternoon, 3 Evening, 4 Night)
------------------------------------------------------------------------
Case.riverPath = {
	Vector2.new(165, -10), Vector2.new(185, 70), Vector2.new(235, 145), Vector2.new(325, 200),
	Vector2.new(430, 218), Vector2.new(520, 262), Vector2.new(600, 300), Vector2.new(700, 318),
}

Case.locations = {
	{ id = "office", name = "Bureau office", x = 628, y = 462, open = { 1, 2, 3, 4 },
		desc = "Your desk, the case board and a laptop with the public company register." },
	{ id = "hut", name = "Fisherman's hut", x = 96, y = 236, open = { 1, 2, 3, 4 }, witness = "janis",
		desc = "Jānis has fished this river for forty years. He is awake at all hours." },
	{ id = "plant", name = "Zaļā Druva plant", x = 312, y = 92, open = { 1, 2 }, witness = "edgars", brochure = "E3",
		desc = "The new fertiliser plant. The gate is open during office hours." },
	{ id = "lab", name = "Vecupe Water Lab", x = 560, y = 400, open = { 1, 2, 3 }, witness = "anna",
		desc = "The small lab that tests the plant's water samples." },
	{ id = "hall", name = "Town hall", x = 410, y = 418, open = { 1, 2 }, witness = "arturs", records = { "E4", "E5" },
		desc = "Public records can be requested here. Councillor Lapsa has an office upstairs." },
	{ id = "beach", name = "Town beach", x = 612, y = 352, open = { 1, 2, 3 }, witness = "ieva",
		desc = "Families swim here. Ieva lives in the house next to it." },
}

------------------------------------------------------------------------
-- Water sampling. Values in mg/L of phosphorus. The permit limit is 1.0.
------------------------------------------------------------------------
Case.sampleLimit = 1.0
Case.swatches = {
	{ value = 0.1, color = Color3.fromRGB(236, 238, 214) },
	{ value = 0.5, color = Color3.fromRGB(196, 222, 214) },
	{ value = 1.0, color = Color3.fromRGB(146, 196, 212) },
	{ value = 2.0, color = Color3.fromRGB(84, 146, 196) },
	{ value = 5.0, color = Color3.fromRGB(34, 72, 142) },
}
Case.samplePoints = {
	{ id = "up", name = "Upstream", x = 186, y = 66, day = 0.1, night = 0.1,
		desc = "Above the plant. If the water is clean here, the problem starts lower down." },
	{ id = "pipe", name = "Outflow pipe", x = 300, y = 188, day = 0.5, night = 5.0,
		desc = "Right where the plant's pipe enters the river." },
	{ id = "farm", name = "Farm drain", x = 468, y = 230, day = 0.5, night = 0.5,
		desc = "A ditch from the fields. Farms can pollute rivers too." },
	{ id = "beach", name = "Beach", x = 548, y = 280, day = 1.0, night = 2.0,
		desc = "Where the children swim." },
}

------------------------------------------------------------------------
-- Clues. kind: "fact", "problem" or "rumour". sdg = targets the clue relates to.
-- link = draws a red thread on the case board between two items.
------------------------------------------------------------------------
Case.clues = {
	-- E1 newspaper
	c_third = { kind = "problem", sdg = { "6.6" }, title = "Third fish kill this week",
		note = "Not an accident. Something keeps happening to this river." },
	c_vote = { kind = "fact", sdg = { "16.7" }, title = "Council votes on Friday",
		note = "The permit extension will be decided in public. Residents can attend and speak." },
	c_claim = { kind = "problem", sdg = { "12.6" }, title = "\"All within the limits\"",
		note = "A claim, not a proof. Who measured it, where, and when?" },

	-- E2 town chat
	c_kids = { kind = "problem", sdg = { "3.9" }, title = "Children swim at the beach daily",
		note = "If the water is polluted, children are the first to get hurt.", link = { "E2", "ieva" } },
	c_smell = { kind = "problem", sdg = { "6.3" }, title = "Sharp smell at night",
		note = "Several neighbours mention the night. Why the night?", link = { "E2", "janis" } },
	c_rumour = { kind = "rumour", sdg = { "16.3" }, title = "Rumour: \"Lapsa is a thief\"",
		note = "Unproven. Repeating it could hurt an innocent person. Find evidence or drop it.",
		learn = "An accusation without evidence is not a fact. Fair justice means checking before blaming." },

	-- E3 plant's Green Report
	c_zero = { kind = "problem", sdg = { "12.6" }, title = "\"Zero impact on the river\"",
		note = "A big promise with no numbers behind it. Classic greenwashing.",
		learn = "Greenwashing: making a company look more environmentally friendly than it really is, using vague or unproven claims." },
	c_eco = { kind = "problem", sdg = { "12.6", "12.8" }, title = "\"100% eco-friendly\"",
		note = "Eco-friendly compared to what? Measured how? Vague words hide facts." },
	c_treated = { kind = "problem", sdg = { "6.3" }, title = "\"All wastewater is treated\"",
		note = "Treated when? The report never mentions the night shift.", link = { "E3", "E6" } },

	-- E4 permit + minutes
	c_fast = { kind = "problem", sdg = { "16.6" }, title = "Permit approved in 7 days",
		note = "The usual review takes 60 days. Who rushed it, and why?" },
	c_lapsa_vote = { kind = "fact", sdg = { "16.5" }, title = "Councillor Lapsa voted in favour",
		note = "The vote was 5–4. One vote made the difference.", link = { "E4", "arturs" } },
	c_no_declare = { kind = "problem", sdg = { "16.5", "16.6" }, title = "No conflict of interest declared",
		note = "Councillors must declare personal interests before a vote. Nobody did.",
		learn = "Conflict of interest: when a decision-maker could personally gain from a decision. They must declare it and step aside." },

	-- E5 official lab summary
	c_daytime = { kind = "problem", sdg = { "6.3" }, title = "Samples taken 10:00–14:00 only",
		note = "Every official test was taken in daylight. Nobody tested at night.", link = { "E5", "E6" } },
	c_signed = { kind = "problem", sdg = { "16.6" }, title = "Signed by the plant, not the lab",
		note = "The summary was signed by the plant director. Who checks the checker?", link = { "E5", "anna" } },

	-- E6 photos
	c_night_photo = { kind = "problem", sdg = { "6.3" }, title = "Cloudy discharge at 02:14",
		note = "A plume of grey water from the pipe in the middle of the night.", link = { "E6", "edgars" } },

	-- E7 Anna's original lab sheet
	c_hidden = { kind = "problem", sdg = { "6.3", "16.10" }, title = "Night samples: 4.6 mg/L — hidden",
		note = "Four times the limit, crossed out with 'do not include'.", link = { "E7", "E5" },
		learn = "Whistleblower: a person who reveals wrongdoing inside an organisation. The law protects them, and so should you." },

	-- Sampling
	c_upstream = { kind = "fact", sdg = { "6.6" }, title = "Upstream water is clean (0.1)",
		note = "The river is healthy above the plant. Not a natural bloom." },
	c_source = { kind = "problem", sdg = { "6.3" }, title = "Pipe at night: 5.0 mg/L",
		note = "Five times the permit limit, right at the plant's pipe, at night.",
		learn = "Eutrophication: too many nutrients (like phosphorus from fertiliser) make algae explode. When they rot, oxygen disappears and fish suffocate. The Dzirnupe flows into the Baltic Sea." },
	c_farm_ok = { kind = "fact", sdg = { "16.3" }, title = "The farm is not the cause",
		note = "Slightly raised, but under the limit, day and night. Blame stays where the evidence is." },
	c_beach = { kind = "problem", sdg = { "3.9" }, title = "Beach water over the limit",
		note = "The water where children swim is polluted too.", link = { "E2", "ieva" } },

	-- Money trail
	c_conflict = { kind = "problem", sdg = { "16.5", "16.6" }, title = "Lapsa's brother was paid €18,000",
		note = "The plant paid the councillor's brother's company three days before the vote.", link = { "arturs", "E4" } },

	-- Interviews
	c_cloudy = { kind = "problem", sdg = { "6.3" }, title = "Water goes cloudy at night",
		note = "Jānis: the fish die after nights when the water turns grey and sharp.", link = { "janis", "E6" } },
	c_admitted = { kind = "problem", sdg = { "6.3" }, title = "Plant admits night discharges",
		note = "Edgars: \"only during maintenance\". So it does happen at night.", link = { "edgars", "E5" } },
	c_rash = { kind = "problem", sdg = { "3.9" }, title = "A child got a rash after swimming",
		note = "Ieva's son. Health is already being affected.", link = { "ieva", "E2" } },
	c_urgent = { kind = "problem", sdg = { "16.6" }, title = "\"Urgent\" — but who asked?",
		note = "Lapsa says the plant asked for speed. The rules don't allow skipping the review.", link = { "arturs", "E4" } },
	c_bribe = { kind = "problem", sdg = { "16.5" }, title = "Bribe offered to the Bureau",
		note = "€2,000 'consulting' if we slow down. Saved as evidence.", link = { "E8", "edgars" } },
}

Case.decoys = {
	d_weather = { note = "Small talk. Not every message is a clue." },
	d_jobs = { note = "True — the plant does employ local people. Jobs are not the problem; pollution is." },
	d_start = { note = "A normal meeting time. Nothing suspicious here." },
	d_units = { note = "mg/L is the normal unit for this test." },
	d_festival = { note = "A town festival is not a crime." },
	d_coffee = { note = "Just coffee. Investigators need it too." },
}

------------------------------------------------------------------------
-- Evidence documents
------------------------------------------------------------------------
Case.evidence = {
	{
		id = "E1", kind = "news", label = "Vecupes Ziņas", short = "News",
		board = { x = 22, y = 74, w = 150, h = 112, rot = -3 },
		masthead = "VECUPE NEWS · Tuesday, 20 October",
		headline = "Dead fish in the Dzirnupe again",
		paragraphs = {
			{ "Residents found hundreds of dead roach and perch below the town on Monday morning — ", { "the third time this week", clue = "c_third" }, "." },
			{ "A spokesperson for the Zaļā Druva fertiliser plant said the plant's discharge is ", { "\"all within the limits\"", clue = "c_claim" }, " and blamed the warm autumn." },
			{ "The ", { "council will vote on Friday", clue = "c_vote" }, " on extending the plant's discharge permit for ten years. The meeting is open to the public." },
		},
	},
	{
		id = "E2", kind = "chat", label = "Town chat", short = "Chat",
		board = { x = 196, y = 40, w = 138, h = 160, rot = 2 },
		chatTitle = "Vecupe Neighbours", chatSub = "412 members", dayLabel = "Monday, 19 October",
		messages = {
			{ from = "Maris", time = { "07.12" }, parts = { { "Lovely sunrise today.", decoy = "d_weather" }, " But the river stinks again." } },
			{ from = "Ieva", time = { "07.40" }, parts = { "My kids ", { "swim at the beach every day", clue = "c_kids" }, ". Is it safe??" } },
			{ from = "Dace", time = { "08.02" }, parts = { "It always gets a ", { "sharp smell at night", clue = "c_smell" }, ". Smells like a chemistry lab." } },
			{ from = "Guntis", time = { "08.30" }, parts = { "Everybody knows ", { "Lapsa is a thief", clue = "c_rumour" }, ". He sold the river!!" } },
		},
	},
	{
		id = "E3", kind = "doc", label = "Green Report", short = "Brochure", hidden = true,
		board = { x = 362, y = 70, w = 138, h = 118, rot = -2 },
		paperColor = Color3.fromRGB(222, 236, 214),
		docTitle = "ZAĻĀ DRUVA — GREEN REPORT 2026",
		paragraphs = {
			{ "At Zaļā Druva we care for nature. Our modern plant has ", { "zero impact on the river", clue = "c_zero" }, "." },
			{ "Our products are ", { "100% eco-friendly", clue = "c_eco" }, " and made with love for Latvian soil." },
			{ "Thanks to our filters, ", { "all wastewater is treated", clue = "c_treated" }, " before it leaves the site." },
			{ "We are proud to ", { "employ 140 people from Vecupe", decoy = "d_jobs" }, " and to sponsor the ", { "Autumn Festival", decoy = "d_festival" }, "." },
		},
	},
	{
		id = "E4", kind = "doc", label = "Permit & minutes", short = "Minutes", hidden = true,
		board = { x = 526, y = 40, w = 118, h = 100, rot = 3 },
		docTitle = "VECUPE TOWN COUNCIL — MINUTES, 6 OCTOBER 2026",
		header = { { "Item:", "Discharge permit #114, AS Zaļā Druva" }, { "Opened:", "17:00" } },
		paragraphs = {
			{ { "The meeting opened at 17:00.", decoy = "d_start" }, " The application was received on 29 September and ", { "approved in 7 days", clue = "c_fast" }, " (standard review: 60 days)." },
			{ "Vote: 5 for, 4 against. ", { "Councillor A. Lapsa voted in favour", clue = "c_lapsa_vote" }, "." },
			{ "Declarations of personal interest: ", { "none recorded", clue = "c_no_declare" }, "." },
		},
	},
	{
		id = "E5", kind = "table", label = "Official lab summary", short = "Lab summary", hidden = true,
		board = { x = 28, y = 214, w = 140, h = 96, rot = 2 },
		title = "Water test summary — Zaļā Druva outflow",
		columns = { "Date", "Phosphorus" },
		rows = {
			{ "12 October", "0.6 mg/L" },
			{ "14 October", "0.5 mg/L" },
			{ "16 October", "0.7 mg/L" },
		},
		footnote = {
			"Permit limit 1.0 ", { "mg/L", decoy = "d_units" }, ". ", { "All samples taken 10:00–14:00", clue = "c_daytime" }, ". ",
			{ "Signed: V. Saule, plant director", clue = "c_signed" }, ".",
		},
	},
	{
		id = "E6", kind = "photo", label = "Jānis's photos", short = "Photos", hidden = true,
		board = { x = 380, y = 214, w = 128, h = 92, rot = -3 },
		photos = {
			{ caption = { "02:14 — cloudy water from the pipe", clue = "c_night_photo" }, plume = true },
			{ caption = { "07:30 — dead fish at the beach" }, fish = true },
		},
	},
	{
		id = "E7", kind = "note", label = "Anna's lab sheet", short = "Lab sheet", hidden = true,
		board = { x = 36, y = 336, w = 124, h = 96, rot = -4 },
		heading = "Original lab sheet — A. Bērziņa",
		lines = {
			{ "12 Oct, 11:00 — 0.6 mg/L" },
			{ { "14 Oct, 02:30 — 4.6 mg/L", clue = "c_hidden" } },
			{ "16 Oct, 12:00 — 0.7 mg/L" },
		},
		strike = { 2 },
		scribble = { "\"do not include\" — V.S.", clue = "c_hidden" },
	},
	{
		id = "E8", kind = "chat", label = "Bribe message", short = "Bribe", hidden = true,
		board = { x = 530, y = 160, w = 118, h = 96, rot = 3 },
		chatTitle = "Edgars Kalniņš", chatSub = "AS Zaļā Druva", dayLabel = "Saved as evidence",
		messages = {
			{ from = "Edgars Kalniņš", time = { "19.40", clue = "c_bribe" }, parts = { "Our plant would love to sponsor the Autumn Festival — and pay your Bureau €2,000 for 'consulting'. Maybe no need to rush before Friday?" } },
		},
	},
}

------------------------------------------------------------------------
-- Witnesses. topics: questions. claim: a statement you can disprove with evidence.
-- gives = clue; reveal = evidence id; requires = clue that must be found first
------------------------------------------------------------------------
Case.witnessOrder = { "janis", "edgars", "anna", "arturs", "ieva" }

Case.witnesses = {
	janis = {
		intro = "A wooden hut, nets drying by the stove. Jānis doesn't get up.",
		opening = "Forty years I've fished here. I've never seen the river like this.",
		topics = {
			{ ask = "When do the fish die?", lines = {
				"Always after the same kind of night. The water turns grey, it smells sharp, like a swimming pool.",
				"By morning the fish are floating.",
			}, gives = "c_cloudy" },
			{ ask = "Do you have any proof?", lines = {
				"I took photos. Two nights ago, from my boat, right by the plant's pipe.",
				{ who = "narr", text = "He handed me two prints. The timestamps were in the middle of the night." },
			}, reveal = "E6" },
			{ ask = "Could it be the warm weather?", lines = {
				"Warm weather? Above the plant the water is fine. Go and test it yourself.",
			} },
		},
	},
	edgars = {
		intro = "A bright office, a bowl of green apples, a smile that has been practised.",
		opening = "Welcome! We have nothing to hide. Here, take our Green Report.",
		topics = {
			{ ask = "Does the plant discharge at night?", claim = {
				text = "Never. All discharge happens during office hours, under supervision.",
				accepts = { "c_night_photo", "c_cloudy", "c_source", "c_smell" },
				success = {
					{ who = "narr", text = "I put the evidence on his desk. The smile stayed. The eyes didn't." },
					"…Well. Sometimes, during maintenance, we release some water at night. It's all treated.",
				},
				gives = "c_admitted",
				fail = "That proves nothing. Anything else?",
			} },
			{ ask = "Who tests your water?", lines = {
				"The town lab. The results are public — ask at the town hall.",
			} },
			{ ask = "What about the dead fish?", lines = {
				"A natural algae bloom. It has been a warm autumn. Nature is unpredictable.",
			} },
		},
	},
	anna = {
		intro = "Rows of glass jars. Anna keeps glancing at the door.",
		opening = "I just run the tests. I don't decide what goes in the reports.",
		topics = {
			{ ask = "Who takes the samples?", lines = {
				"The plant brings them to us. We test what we get.",
			} },
			{ ask = "Why are all the samples from daytime?", lines = {
				"That's… when they bring them.",
				{ who = "narr", text = "She looked at the door again." },
			} },
			{ ask = "Did anyone ever test at night?", requires = { "c_daytime", "c_cloudy", "c_night_photo", "c_smell" }, lines = {
				{ who = "narr", text = "She was quiet for a long time. Then she opened a drawer." },
				"Once. On the 14th, at half past two in the morning. It was terrible.",
				"The director crossed it out. Here. Please — be careful with this.",
			}, reveal = "E7", trigger = "whistle" },
		},
	},
	arturs = {
		intro = "A heavy desk, a framed photo with the mayor, a calendar from a consulting firm.",
		opening = "I have ten minutes. The council follows every procedure.",
		topics = {
			{ ask = "Why was the permit approved so fast?", claim = {
				text = "It went through the normal procedure, like every other permit.",
				accepts = { "c_fast" },
				success = {
					{ who = "narr", text = "I showed him the dates. Seven days." },
					"…The plant said it was urgent. Jobs were at stake. We were trying to help the town.",
				},
				gives = "c_urgent",
				fail = "I don't see your point.",
			} },
			{ ask = "Do you know NL Konsultācijas?", claim = {
				text = "Never heard of it. I have no personal interest in this plant.",
				accepts = { "c_conflict" },
				success = {
					{ who = "narr", text = "I laid out the register entry, the declaration and the payment." },
					"…My brother's business is his business. I didn't ask him to do anything.",
					{ who = "narr", text = "He didn't deny the money. He just stopped looking at me." },
				},
				fail = "I told you, I don't know it.",
			} },
		},
	},
	ieva = {
		intro = "A small house by the beach. Two bikes, two pairs of wet shoes by the door.",
		opening = "Are you here about the river? Finally someone is.",
		topics = {
			{ ask = "Have your children been affected?", lines = {
				"My youngest got a red rash after swimming on Sunday. The doctor said 'probably an allergy'.",
				"Probably. Nobody tells us anything.",
			}, gives = "c_rash" },
			{ ask = "What would help the neighbours?", lines = {
				"Clear information. Is it safe to swim or not? Can we use the well? Who is checking?",
				"And not only on the internet. Half of this street is pensioners.",
			} },
		},
	},
}

------------------------------------------------------------------------
-- Phone messages: arrive when you return to the map. Each choice has consequences.
-- when(state) decides when the message arrives.
------------------------------------------------------------------------
Case.phone = {
	{
		id = "mother", from = "ieva", sdg = { "3.9" },
		when = function(s) return s:timeIndex() >= 2 end,
		text = "Hi, it's Ieva from the beach. It's warm today and the kids are begging to swim. Is it safe?",
		choices = {
			{ text = "Please keep them out of the water until we have test results.", effect = { decision = "warned", safety = 25 } },
			{ text = "Should be fine, it's just a few fish.", effect = { decision = "reassured", safety = -25 } },
			{ text = "Ask the council, not me.", effect = { decision = "deflected", safety = -5 } },
		},
		timeout = { decision = "ignored", safety = -10 },
	},
	{
		id = "bribe", from = "edgars", sdg = { "16.5" },
		when = function(s) return s.visited.edgars == true end,
		text = "Good meeting today. Our plant would love to sponsor the Autumn Festival — and pay your Bureau €2,000 for 'consulting'. Maybe no need to rush before Friday?",
		choices = {
			{ text = "Accept the offer.", effect = { decision = "accepted" } },
			{ text = "No, thank you.", effect = { decision = "declined", justice = 5 } },
			{ text = "No. And I'm saving this message as evidence.", effect = { decision = "saved", justice = 15, reveal = "E8", clue = "c_bribe" } },
		},
		timeout = { decision = "ignored" },
	},
	{
		id = "whistle", from = "anna", sdg = { "16.10" },
		when = function(s) return s.revealed.E7 == true end,
		text = "If the director finds out I gave you that sheet, I'll lose my job. What are you going to do with it?",
		choices = {
			{ text = "You'll stay anonymous. I'll send it through the official whistleblower channel.", effect = { decision = "protected", trust = 10 } },
			{ text = "People should know your name — you're a hero!", effect = { decision = "exposed", trust = -10 } },
			{ text = "Sorry, without your name nobody will believe it.", effect = { decision = "exposed", trust = -10 } },
		},
		timeout = { decision = "ignored" },
	},
	{
		id = "journalist", from = "rita", sdg = { "16.3", "12.8" },
		when = function(s) return s:timeIndex() >= 6 end,
		text = "Rita from Vecupes Ziņas. I hear you're digging into the plant. Can I publish tonight: 'Councillor Lapsa bribed by the plant'?",
		choices = {
			{ text = "Not yet. I'll share only what's proven, after Friday.", effect = { decision = "wait", justice = 5 } },
			{ text = "Sure, go ahead.", effect = { decision = "published", justice = -25 } },
			{ text = "Write about the water tests and the swimming advice instead.", effect = { decision = "water", safety = 10, justice = 5 } },
		},
		timeout = { decision = "ignored" },
	},
}

------------------------------------------------------------------------
-- Money trail (company register puzzle)
------------------------------------------------------------------------
Case.money = {
	nodes = {
		{ id = "arturs", label = "Councillor Artūrs Lapsa", x = 70, y = 70 },
		{ id = "normunds", label = "Normunds Lapsa", x = 70, y = 250 },
		{ id = "inga", label = "Inga Lapsa", x = 330, y = 380 },
		{ id = "nl", label = "SIA NL Konsultācijas", x = 320, y = 250 },
		{ id = "bakery", label = "SIA Lapsas Maiznīca", x = 70, y = 380 },
		{ id = "plant", label = "AS Zaļā Druva", x = 330, y = 120 },
		{ id = "permit", label = "Permit #114", x = 210, y = 20 },
	},
	relations = { "owns", "is a relative of", "paid money to", "voted for" },
	links = {
		{ a = "normunds", b = "nl", rel = "owns", source = "Company register" },
		{ a = "arturs", b = "normunds", rel = "is a relative of", source = "Declaration of interests" },
		{ a = "plant", b = "nl", rel = "paid money to", source = "Plant payments" },
		{ a = "arturs", b = "permit", rel = "voted for", source = "Council minutes" },
		{ a = "inga", b = "bakery", rel = "owns", source = "Company register", extra = true },
	},
	docs = {
		{ title = "Company register", lines = {
			"SIA NL Konsultācijas — registered 12 Aug 2026",
			"Owner: Normunds Lapsa (100%)",
			"Activity: management consulting",
			"",
			"SIA Lapsas Maiznīca — registered 2009",
			"Owner: Inga Lapsa (100%)",
			"Activity: bakery",
		} },
		{ title = "Declaration of interests", lines = {
			"Public official: Artūrs Lapsa, councillor",
			"Close relatives: brother — Normunds Lapsa",
			"Business interests: none",
			"",
			"(Inga Lapsa is not listed. Same surname, no relation.)",
		} },
		{ title = "Plant payments", lines = {
			"AS Zaļā Druva — annual report, annex 3",
			"3 Oct 2026 — SIA NL Konsultācijas — €18,000",
			"Purpose: 'environmental consulting'",
			"",
			"(Three days before the council vote.)",
		} },
		{ title = "Council minutes", requiresEvidence = "E4", lines = {
			"6 Oct 2026 — Permit #114, AS Zaļā Druva",
			"For: A. Lapsa and 4 others. Against: 4.",
			"Declarations of interest: none recorded.",
		} },
	},
}

------------------------------------------------------------------------
-- Report: which institutions receive your evidence
------------------------------------------------------------------------
Case.institutions = {
	{ id = "vvd", name = "State Environmental Service (VVD)", does = "Investigates pollution and can stop illegal discharges.", good = true, sdg = { "6.3" } },
	{ id = "knab", name = "Corruption Prevention and Combating Bureau (KNAB)", does = "Investigates bribery and conflicts of interest.", good = true, needs = "c_conflict", sdg = { "16.5" } },
	{ id = "health", name = "Health Inspectorate", does = "Checks bathing water and can warn the public.", good = true, sdg = { "3.9" } },
	{ id = "plantpr", name = "The plant's PR department", does = "Will read it first and prepare a denial.", good = false },
	{ id = "social", name = "Social media only", does = "Fast and loud, but nobody is obliged to investigate.", good = false },
}

-- Statement to residents at the hearing (text blocks)
Case.notice = {
	tab = "Statement to residents",
	template = "{found} {action} {who} {where}",
	slots = {
		{ id = "found", label = "What we found", fact = true, options = {
			{ text = "Tests show phosphorus five times over the limit at the plant's pipe at night.", q = "clear", requires = { "c_source" } },
			{ text = "The plant is poisoning all of us!", q = "panic", why = "Loud, but not precise. Panic makes people stop listening." },
			{ text = "Something might be wrong with the river.", q = "vague", why = "Residents already know that. What did you find?" },
		} },
		{ id = "action", label = "What to do now", fact = true, options = {
			{ text = "Until new tests, please don't swim in the river or water gardens with it.", q = "clear", requires = { "c_kids" } },
			{ text = "Stay safe, everyone.", q = "vague", why = "Safe how? People need a concrete action." },
			{ text = "There is no need to worry.", q = "wrong", why = "There is. A child already has a rash." },
		} },
		{ id = "who", label = "Who is acting", fact = true, options = {
			{ text = "Our evidence has been sent to the institutions responsible.", q = "clear" },
			{ text = "Councillor Lapsa will go to prison.", q = "accusation", why = "Only a court can decide that. Unproven claims hurt your case." },
			{ text = "We'll see what happens.", q = "vague", why = "Nobody trusts a plan with no owner." },
		} },
		{ id = "where", label = "Where to get updates", options = {
			{ text = "Updates every Friday on the council website and on the library notice board.", q = "clear" },
			{ text = "Follow me on TikTok for updates.", q = "exclusive", why = "Half of the beach street is pensioners. Information must reach everyone." },
			{ text = "Check the town chat.", q = "vague", why = "The town chat is where the rumours started." },
		} },
	},
}

------------------------------------------------------------------------
-- Town hall hearing. counters = clue ids that disprove the statement.
-- truthful = true: objecting is a mistake (the statement is correct).
------------------------------------------------------------------------
Case.hearing = {
	start = 30,
	needed = 60,
	statements = {
		{ who = "lawyer", text = "Every official test shows our discharge is within the permitted limit.",
			counters = { "c_daytime", "c_hidden", "c_source", "c_night_photo", "c_admitted" }, sdg = { "6.3" },
			win = "Official tests were only taken in daylight. At night the numbers tell a different story." },
		{ who = "lawyer", text = "The fish died because of a natural algae bloom after a warm autumn.",
			counters = { "c_upstream", "c_source", "c_cloudy" }, sdg = { "6.6" },
			win = "Above the plant the water is clean. A natural bloom doesn't stop at a factory fence." },
		{ who = "lawyer", text = "Zaļā Druva employs 140 people from Vecupe.", truthful = true,
			lose = "That is true — and everyone in the room knows it. Objecting to facts makes you look unfair." },
		{ who = "arturs", text = "I had no personal interest when I voted for this permit.",
			counters = { "c_conflict" }, sdg = { "16.5" },
			win = "His brother's company was paid €18,000 by the plant three days before the vote." },
		{ who = "lawyer", text = "Nobody has been harmed. This is about a few fish.",
			counters = { "c_rash", "c_beach", "c_kids" }, sdg = { "3.9" },
			win = "Children swim in this water every day, and one already has a rash." },
		{ who = "lawyer", text = "Our Green Report proves we have zero impact on the river.",
			counters = { "c_source", "c_hidden", "c_night_photo", "c_zero" }, sdg = { "12.6" },
			win = "'Zero impact' is a slogan, not a measurement. The measurements say otherwise." },
	},
	-- Extra events depending on your phone decisions
	events = {
		published = { who = "lawyer", text = "The Bureau leaked unproven accusations to the press. 'Councillor bribed' — where is the court ruling?", trust = -15 },
		accepted = { who = "lawyer", text = "Before we continue — the Bureau accepted €2,000 from our plant this week. Here is the receipt.", trust = -45 },
		saved = { who = "you", text = "The plant offered our Bureau €2,000 to slow down. Here is the message.", trust = 10 },
	},
}

------------------------------------------------------------------------
-- Outcome after three months: meters (0–100), stakeholder cards, SDG targets reached
------------------------------------------------------------------------
local function clamp(v) return math.clamp(math.floor(v + 0.5), 0, 100) end

function Case.outcome(s)
	local d = s.decisions
	local inst = s.institutions
	local noticeQ = s.noticeQuality or {}
	local permitStopped = (s.hearingTrust or 0) >= Case.hearing.needed and d.bribe ~= "accepted"

	local river = 15
	if s:has("c_source") then river += 20 end
	if inst.vvd then river += 25 end
	if permitStopped then river += 35 end
	if s:has("c_hidden") then river += 5 end
	if not permitStopped then river = math.min(river, 35) end

	local justice = 10 + (s.meterBonus.justice or 0)
	if s:has("c_conflict") then justice += 25 end
	if inst.knab and s:has("c_conflict") then justice += 25 end
	if inst.knab and not s:has("c_conflict") then justice -= 5 end
	if s:has("c_farm_ok") then justice += 5 end
	justice -= 12 * (s.falseLinks or 0)
	if noticeQ.who == "accusation" then justice -= 15 end
	if d.bribe == "accepted" then justice = 0 end

	local safety = 25 + (s.meterBonus.safety or 0)
	if inst.health then safety += 15 end
	if noticeQ.action == "clear" then safety += 25 elseif noticeQ.action == "wrong" then safety -= 20 end
	if noticeQ.where == "clear" then safety += 10 end

	local trust = (s.hearingTrust or 0) + (s.meterBonus.trust or 0)
	if d.whistle == "exposed" then trust -= 10 end

	local m = { river = clamp(river), justice = clamp(justice), safety = clamp(safety), trust = clamp(trust) }

	-- Ending
	local ending
	if d.bribe == "accepted" then
		ending = { title = "The Bureau for Sale", text = "The receipt was read out at the hearing. The permit passed. The river stayed grey — and nobody believes the Bureau any more." }
	elseif permitStopped and m.river >= 70 and m.justice >= 60 and m.safety >= 60 then
		ending = { title = "Clear Water", text = "The permit was frozen, the plant was fined and built a real filter. In spring, Jānis caught his first perch in months." }
	elseif permitStopped then
		ending = { title = "Half the Truth", text = "The permit was frozen — but some questions were never answered. The river is recovering slowly." }
	else
		ending = { title = "Business as Usual", text = "The permit was extended for ten years. The night discharges continue. The case file goes back into the drawer." }
	end

	-- Stakeholders
	local cards = {}
	local function add(who, text, good) table.insert(cards, { who = who, text = text, good = good }) end
	if permitStopped and inst.vvd then
		add("river", "VVD inspectors sealed the night valve. Oxygen levels are back to normal; the perch are returning.", true)
	elseif permitStopped then
		add("river", "The permit is frozen, but nobody inspected the pipe. Some nights the water still turns grey.", false)
	else
		add("river", "Two more fish kills before winter. The pollution flows on, all the way to the Baltic Sea.", false)
	end
	if d.whistle == "protected" then
		add("anna", "Anna stayed anonymous and still works at the lab. She now tests at night, too.", true)
	elseif d.whistle == "exposed" then
		add("anna", "Anna's name was in every chat by Saturday. The lab let her go a week later.", false)
	else
		add("anna", "Anna's sheet was never used. She still wonders if she should have kept quiet.", false)
	end
	if m.safety >= 60 then
		add("ieva", "Ieva's kids stayed out of the water until it was safe. The rash healed; no new cases.", true)
	else
		add("ieva", "Nobody told the families clearly. Three more children got rashes before the beach was closed.", false)
	end
	if s:has("c_conflict") and inst.knab then
		add("arturs", "KNAB opened a case on the €18,000 payment. Lapsa stepped down from the environment committee.", true)
	elseif s:has("c_conflict") then
		add("arturs", "You found the payment but told no one who could act. Lapsa is still on the committee.", false)
	else
		add("arturs", "The money trail was never followed. Lapsa voted on two more permits this autumn.", false)
	end

	-- SDG targets reached
	local reached = {
		["6.3"] = s:has("c_source") and inst.vvd and permitStopped,
		["6.6"] = s:has("c_upstream") and permitStopped,
		["6.3b"] = s:has("c_source") and permitStopped, -- SDG 6: less of it reaches the Baltic Sea
		["3.9"] = m.safety >= 60,
		["12.6"] = s:has("c_zero") and s:has("c_eco"),
		["12.8"] = noticeQ.found == "clear" and noticeQ.action == "clear",
		["16.3"] = (s.falseLinks or 0) == 0 and noticeQ.who ~= "accusation" and d.journalist ~= "published",
		["16.5"] = s:has("c_conflict") and inst.knab and d.bribe ~= "accepted",
		["16.6"] = s:has("c_fast") and s:has("c_signed"),
		["16.7"] = (s.hearingTrust or 0) >= Case.hearing.needed and noticeQ.where == "clear",
		["16.10"] = s:has("c_hidden") and d.whistle == "protected",
	}
	return { meters = m, ending = ending, cards = cards, reached = reached, permitStopped = permitStopped }
end

------------------------------------------------------------------------
-- Hints (first one whose clue is still missing)
------------------------------------------------------------------------
Case.hints = {
	{ need = "c_cloudy", text = "Talk to someone who is by the river at night. The fisherman's hut is on the west bank." },
	{ need = "c_upstream", text = "Test the water above the plant. If it's clean there, it isn't the weather." },
	{ need = "c_source", text = "The official tests were all taken in daylight. Test the pipe when nobody expects it." },
	{ need = "c_daytime", text = "Public records are public. Ask at the town hall during office hours." },
	{ need = "c_hidden", text = "The lab technician knows more than the official summary. Show her you know about the nights." },
	{ need = "c_conflict", text = "Follow the money. The company register on your office laptop is open to anyone." },
	{ need = "c_zero", text = "Pick up the plant's Green Report. Look for big promises without numbers." },
}
Case.hintFallback = "You have the key evidence. Prepare your report before Friday."

return Case
