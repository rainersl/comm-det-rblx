-- case nr1

local Case = {}

Case.id = "empty_workshop"
Case.number = "01"
Case.title = "Tukšā darbnīca"
Case.question = "Kāpēc ceturtdien atnāca tikai trīs?"

------------------------------------------------------------------------
-- characters
------------------------------------------------------------------------
Case.characters = {
	chief = { name = "Kom. Dūmiņš", full = "Komisārs Dūmiņš", role = "Biroja priekšnieks", look = { "fedora" } },
	ilze = { name = "Ilze Kalniņa", full = "Ilze Kalniņa", role = "Robotikas skolotāja", look = { "bun", "glasses" } },
	markuss = { name = "Markuss", full = "Markuss", role = "11. klase, pulčiņa čata administrators", look = { "hood", "headphones" } },
	emils = { name = "Emīls", full = "Emīls", role = "8. klase", look = { "cap", "backpack" }, small = true },
	daniela = { name = "Daniela", full = "Daniela", role = "10. klase, latviešu valodu mācās otro gadu", look = { "longhair", "phone" } },
}

Case.witnessOrder = { "ilze", "markuss", "emils", "daniela" }

------------------------------------------------------------------------
-- briefing
------------------------------------------------------------------------
Case.briefing = {
	{ who = "narr", text = "Oktobris. Lietus lī jau trešo dienu." },
	{ who = "narr", text = "Uz galda gulēja plāna mape. Plānas mapes parasti nozīmē lielas nepatikšanas." },
	{ who = "chief", text = "Kadet, ir darbs. Skolas robotikas pulčiņš. Ceturtdien uz darbnīcu gaidīja divdesmit skolēnu, atnāca trīs." },
	{ who = "chief", text = "Piektdien pulksten trīs ir pēdējā darbnīca. Ja nesanāks vismaz seši, skola šogad paliks bez komandas valsts sacensībās." },
	{ who = "chief", text = "Neviens nemelo, un neviens negribēja neko sabojāt. Kad vainīga nav neviena, parasti vainīga ir ziņa." },
	{ who = "chief", text = "Laika tev pietiks trim sarunām, ne vairāk. Izvēlies gudri. Un neaizmirsti lupu." },
}

------------------------------------------------------------------------
-- clues
------------------------------------------------------------------------
Case.clues = {
	-- facts
	f_friday = { kind = "fact", source = "E1", title = "Piektdien, 23. oktobrī", note = "Pēdējā darbnīca. Konkrēts datums, nevis „rīt”." },
	f_time = { kind = "fact", source = "E1", title = "Plkst. 15.00", note = "Precīzs laiks. Nekādu „varbūt” un „ish”." },
	f_room = { kind = "fact", source = "E1", title = "4. laboratorija, 2. stāvā", note = "Tas ir IT kabinets — ne ķīmijas, ne fizikas laboratorija." },
	f_items = { kind = "fact", source = "E1", title = "Klēpjdators un lādētājs", note = "Lūk, kas bija domāts ar „stuff”." },
	f_six = { kind = "fact", source = "E1", title = "Vajag vismaz sešus", note = "Ja būs mazāk par sešiem, komandas nebūs." },

	-- problems e1
	c_midnight = { kind = "problem", source = "E2", title = "Nosūtīts 00.07", note = "Markuss rakstīja pēc pusnakts. Viņam „rīt” nozīmēja ceturtdienu, bet tiem, kas lasīja no rīta, — piektdienu.", link = { "E2", "E3" } },
	c_tmrw = { kind = "problem", source = "E2", title = "„tmrw” — kura diena?", note = "„Rīt” ir atkarīgs no tā, kad ziņu izlasa. Datums nemainās." },
	c_after = { kind = "problem", source = "E2", title = "„after lessons” — kad tieši?", note = "Katrai klasei stundas beidzas citā laikā.", link = { "E2", "E5" } },
	c_lab = { kind = "problem", source = "E2", title = "„@ lab” — kura laboratorija?", note = "Tikai viens vārds. Bet cik skolā ir laboratoriju?", link = { "E2", "E4" } },
	c_stuff = { kind = "problem", source = "E2", title = "„bring ur stuff” — ko tieši?", note = "Kādas mantas? Skolotājas e-pastā tas bija uzrakstīts.", link = { "E2", "E1" } },
	c_time = { kind = "problem", source = "E2", title = "„maybe 15:00ish”", note = "„Varbūt” un „apmēram” vienā teikumā. Tā raksta tad, kad pats nezini.", link = { "E2", "E1" } },
	c_workshop = { kind = "problem", source = "E2", title = "„Workshop” — vai visiem saprotams?", note = "Pulčiņā visi saprata. Bet ziņa nonāca arī pie vecākiem.", link = { "E2", "E3" } },
	
	-- e2
	c_parents = { kind = "problem", source = "E3", title = "Vecāki nesaprot ziņu", note = "„Kas ir workshop? Kurā lab?” Un neviens neatbildēja." },
	c_guess = { kind = "problem", source = "E3", title = "„Laikam piektdien?”", note = "Vecāki minēja. Minējums nav informācija." },

	-- e4 & e5
	c_three_labs = { kind = "problem", source = "E4", title = "Skolā ir trīs laboratorijas", note = "Ķīmijas, fizikas un 4. (IT). „Lab” var būt jebkura no tām." },
	c_grades = { kind = "problem", source = "E5", title = "„Pēc stundām” — 14.10 vai 15.00?", note = "Astotajām klasēm stundas beidzas 14.10, vienpadsmitajām — 15.00." },

	-- hidden clue e6
	c_motive = { kind = "problem", source = "E6", title = "„Neviens tik garu nelasīs”", note = "Markuss zināja visu. Viņš ziņu saīsināja tīšām.", link = { "E6", "markuss" } },

	-- conversation problems
	c_only11 = { kind = "problem", source = "ilze", title = "Atnāca tikai 11. klase", note = "Tie, kuriem stundas beidzas 15.00 un kuriem „lab” ir viņu pašu kabinets.", link = { "ilze", "E5" } },
	c_ourlab = { kind = "problem", source = "markuss", title = "Markusam „lab” ir IT kabinets", note = "Viņa klasē visi tā saka. Pārējiem tas nav skaidrs.", link = { "markuss", "E4" } },
	c_emils = { kind = "problem", source = "emils", title = "Emīls gaidīja ķīmijas laboratorijā", note = "Atnāca 14.15 — laikus, bet ne tur un ne tad.", link = { "emils", "E4" } },
	c_daniela = { kind = "problem", source = "daniela", title = "Tulkotājs nesaprata „ur stuff”", note = "Daniela angliski saprot labi. Nesaprotams bija saturs, nevis valoda.", link = { "daniela", "E2" } },
}

-- decoys or fake clues
Case.decoys = {
	d_robot = { note = "Robota emocijzīme saprast netraucē. Ne viss dīvainais ir kļūda." },
	d_thanks = { note = "Pieklājīga pateicība. Te viss ir kārtībā." },
	d_morning = { note = "Parasts sveiciens. Tas nav pierādījums." },
	d_wardrobe = { note = "Garderobei ar šo lietu nav nekāda sakara." },
	d_lunch = { note = "Pusdienas ir svarīgas, bet ne šajā lietā." },
	d_ok = { note = "„Ok” — īsi un skaidri. Šajā čatā tas ir skaidrākais vārds." },
}

------------------------------------------------------------------------
-- evidence
------------------------------------------------------------------------
Case.evidence = {
	{
		id = "E1",
		kind = "email",
		label = "E-pasts",
		short = "E-pasts",
		caption = "Skolotājas e-pasts",
		board = { x = 22, y = 76, w = 150, h = 112, rot = -3 },
		header = {
			{ "No:", "Ilze Kalniņa" },
			{ "Kam:", "Markuss" },
			{ "Datums:", "trešdiena, 21.10., 16.40" },
			{ "Temats:", "Robotikas darbnīcas — lūdzu, pārsūti pulčiņam" },
		},
		paragraphs = {
			{ "Sveiks, Markus!" },
			{
				"Lūdzu, ieliec pulčiņa čatā ziņu par robotikas darbnīcām. Tās notiks ceturtdien, 22. oktobrī, un ",
				{ "piektdien, 23. oktobrī", clue = "f_friday" },
				", abas dienas ",
				{ "plkst. 15.00", clue = "f_time" },
				" ",
				{ "4. laboratorijā (IT kabinetā, 2. stāvā)", clue = "f_room" },
				".",
			},
			{
				"Līdzi jāņem ",
				{ "klēpjdators un lādētājs", clue = "f_items" },
				". Ja kādam nav klēpjdatora, lūdzu, lai pasaka man laikus.",
			},
			{
				"Piektdien veidosim komandu valsts robotikas sacensībām, tāpēc vajadzīgi ",
				{ "vismaz seši dalībnieki", clue = "f_six" },
				".",
			},
			{ { "Paldies!", decoy = "d_thanks" } },
			{ "Ilze Kalniņa" },
		},
	},
	{
		id = "E2",
		kind = "chat",
		label = "Pulčiņa čats",
		short = "Čats",
		caption = "Ekrānuzņēmums",
		board = { x = 196, y = 40, w = 138, h = 160, rot = 2 },
		chatTitle = "Robotikas pulčiņš",
		chatSub = "24 dalībnieki · 8.–11. klase",
		dayLabel = "Ceturtdiena, 22. oktobris",
		messages = {
			{
				from = "Markuss (administrators)",
				time = { "00.07", clue = "c_midnight" },
				parts = {
					{ "Workshop", clue = "c_workshop" },
					" ",
					{ "tmrw", clue = "c_tmrw" },
					" ",
					{ "after lessons", clue = "c_after" },
					" ",
					{ "@ lab", clue = "c_lab" },
					", ",
					{ "bring ur stuff", clue = "c_stuff" },
					", ",
					{ "maybe 15:00ish", clue = "c_time" },
					" ",
					{ "🤖", decoy = "d_robot" },
				},
			},
			{ from = "Rihards", time = { "07.31" }, parts = { { "ok", decoy = "d_ok" } } },
			{ from = "Emīls", time = { "07.44" }, parts = { "šodien vai rīt??" } },
		},
	},
	{
		id = "E3",
		kind = "chat",
		label = "Vecāku čats",
		short = "Vecāki",
		caption = "Ekrānuzņēmums",
		board = { x = 362, y = 72, w = 138, h = 118, rot = -2 },
		chatTitle = "8.A vecāki",
		chatSub = "31 dalībnieks",
		dayLabel = "Ceturtdiena, 22. oktobris",
		messages = {
			{
				from = "Emīla mamma",
				time = { "07.52" },
				parts = {
					{ "Labrīt!", decoy = "d_morning" },
					" Emīls saka, ka būšot kāds workshop. ",
					{ "Kas ir workshop? Kurā lab?", clue = "c_parents" },
				},
			},
			{
				from = "Laura (Kristera mamma)",
				time = { "08.15" },
				parts = { "Kristers arī neko nezina. ", { "Laikam piektdien?", clue = "c_guess" } },
			},
		},
		footer = "Izlasīja: 14",
	},
	{
		id = "E4",
		kind = "plan",
		label = "Skolas plāns",
		short = "Plāns",
		caption = "Evakuācijas plāns",
		board = { x = 526, y = 40, w = 118, h = 100, rot = 3 },
		title = "Skolas plāns — 1. un 2. stāvs",
		floors = {
			{
				name = "1. STĀVS",
				rooms = {
					{ "Ķīmijas laboratorija", 0.04, 0.06, 0.55, 0.4, clue = "c_three_labs" },
					{ "Garderobe", 0.63, 0.06, 0.33, 0.4, decoy = "d_wardrobe" },
					{ "Ēdnīca", 0.04, 0.54, 0.92, 0.4 },
				},
			},
			{
				name = "2. STĀVS",
				rooms = {
					{ "Fizikas laboratorija", 0.04, 0.06, 0.55, 0.4, clue = "c_three_labs" },
					{ "Bibliotēka", 0.63, 0.06, 0.33, 0.4 },
					{ "4. laboratorija (IT)", 0.04, 0.54, 0.92, 0.4, clue = "c_three_labs" },
				},
			},
		},
	},
	{
		id = "E5",
		kind = "table",
		label = "Stundu saraksts",
		short = "Saraksts",
		caption = "Stundu beigas",
		board = { x = 28, y = 214, w = 140, h = 96, rot = 2 },
		title = "Kad beidzas stundas — ceturtdiena",
		columns = { "Klase", "Pēdējā stunda beidzas" },
		rows = {
			{ "8. klases", { "14.10", clue = "c_grades" } },
			{ "9. klases", { "14.10", clue = "c_grades" } },
			{ "10. klases", { "14.55", clue = "c_grades" } },
			{ "11. klases", { "15.00", clue = "c_grades" } },
			{ "Pusdienas", { "12.20–12.50", decoy = "d_lunch" } },
		},
	},
	{
		id = "E6",
		kind = "note",
		hidden = true,
		label = "Saburzīta lapa",
		short = "Lapa",
		caption = "Markusa melnraksts",
		board = { x = 36, y = 336, w = 124, h = 96, rot = -4 },
		lines = {
			{ "Robotikas darbnīca rīt, ceturtdien, 22.10.," },
			{ { "plkst. 15.00", clue = "f_time" }, " ", { "4. laboratorijā (2. stāvā)", clue = "f_room" }, "." },
			{ "Ņemiet līdzi ", { "klēpjdatoru un lādētāju", clue = "f_items" }, "!" },
		},
		scribble = { "neviens tik garu nelasīs", clue = "c_motive" },
	},
}

------------------------------------------------------------------------
-- Liecinieki. topics = jautājumi; claim = apgalvojums, ko var atspēkot ar pierādījumu
------------------------------------------------------------------------
Case.witnesses = {
	ilze = {
		intro = "Skolotāja sēž tukšajā laboratorijā starp divdesmit krēsliem. Ceturtdien aizņemti bija tikai trīs.",
		opening = "Jūs esat no biroja? Labi, ka atnācāt. Es vairs nezinu, ko darīt.",
		topics = {
			{
				ask = "Kas notika ceturtdien?",
				lines = {
					"Gaidīju divdesmit skolēnu. Atnāca trīs.",
					"Un visi trīs no vienpadsmitās klases. No jaunākajiem — neviena.",
				},
				gives = "c_only11",
			},
			{
				ask = "Ko jūs nosūtījāt?",
				lines = {
					"Visu: datumu, laiku, telpu un to, kas jāņem līdzi. Uzrakstīju garu, kārtīgu e-pastu.",
					"Nosūtīju to Markusam, lai viņš ieliek pulčiņa čatā. Es pati tajā čatā neesmu.",
				},
			},
			{
				ask = "Kāpēc piektdiena ir tik svarīga?",
				lines = {
					"Piektdien jāsastāda komanda. Vajag sešus cilvēkus.",
					"Ja nebūs sešu, šogad sacensībās nepiedalīsimies.",
				},
				gives = "f_six",
			},
		},
	},
	markuss = {
		intro = "Austiņas ap kaklu. Viņš izskatās pēc cilvēka, kurš jau zina, ka vainos viņu.",
		opening = "Es tikai pārsūtīju ziņu. Es neesmu skolotājs.",
		topics = {
			{
				ask = "Vai ziņa bija skaidra?",
				claim = {
					text = "Protams. Viss bija skaidri uzrakstīts — gan laiks, gan vieta.",
					accepts = { "c_time", "c_lab", "c_three_labs" },
					success = {
						{ who = "narr", text = "Es noliku pierādījumu viņam priekšā. Viņš ilgi uz to skatījās." },
						"…Labi. To „ish” es pierakstīju, jo nebiju īsti drošs.",
						"Un „lab”… Mūsu klasē visi tā saka IT kabinetam. Man pat prātā neienāca, ka ir arī citas laboratorijas.",
					},
					gives = "c_ourlab",
					fail = "Nu un? Tas neko nepierāda.",
				},
			},
			{
				ask = "Kad tu nosūtīji ziņu?",
				lines = {
					"Vakarā. Nu… īstenībā jau naktī, kaut kad pēc divpadsmitiem.",
					"Es vēl nebiju gājis gulēt, tāpēc man tā vēl bija trešdiena. Tātad „rīt” bija ceturtdiena.",
				},
				gives = "c_midnight",
			},
			{
				ask = "Kāpēc tik īsi?",
				lines = {
					"Garus tekstus neviens nelasa. Nu, kurš tad lasa garus tekstus?",
				},
			},
			{
				ask = "Es atradu tavu pilno versiju.",
				requires = "c_motive",
				lines = {
					{ who = "narr", text = "Viņš ieraudzīja saburzīto lapu un brīdi klussēja." },
					"…Jā. Es to izdzēsu. Likās, ka izklausos pēc skolotājas.",
					"Garā versija tomēr bija labāka, vai ne?",
				},
			},
		},
	},
	emils = {
		intro = "Mugursoma lielāka par viņu pašu. Viņš izskatās pēc cilvēka, kurš atnāca laikus, tikai ne tur.",
		opening = "Es neko nesabojāju! Es taču atnācu!",
		topics = {
			{
				ask = "Kur tu biji ceturtdien?",
				claim = {
					text = "Laboratorijā! Tūlīt pēc stundām, kā bija rakstīts.",
					accepts = { "c_three_labs", "c_lab", "c_grades", "c_after" },
					success = {
						{ who = "narr", text = "Es parādīju viņam pierādījumu. Viņš savieblās." },
						"…Ķīmijas laboratorijā. Citu es nemaz nezinu.",
						"Biju tur 14.15. Gaidīju desmit minūtes, bet neviens neatnāca.",
					},
					gives = "c_emils",
					fail = "Ko tu man rādi? Es tur biju, saku taču!",
				},
			},
			{
				ask = "Ko saprata tava mamma?",
				lines = {
					"Viņa prasīja, kas ir „workshop”. Es teicu, ka darbnīca.",
					"Tad viņa prasīja, kāpēc tā arī neuzraksta. Nezināju, ko atbildēt.",
				},
				gives = "c_parents",
			},
			{
				ask = "Vai piektdien nāksi?",
				lines = {
					"Nākšu, ja kāds beidzot pateiks, KUR un KAD. Un vai „rīt” nozīmē šodien.",
				},
			},
		},
	},
	daniela = {
		intro = "Viņa runā lēnām un rūpīgi izvēlas katru vārdu.",
		opening = "Labdien. Jūs gribat zināt, kāpēc es neatnācu?",
		topics = {
			{
				ask = "Kāpēc tu neatnāci?",
				lines = {
					"Es iekopēju ziņu tulkotājā. Tas iztulkoja: „Atnes savu mantu.” Kādu mantu?",
					"Es nezināju, ko ņemt līdzi un kur jāiet. Tāpēc arī negāju.",
				},
				gives = "c_daniela",
			},
			{
				ask = "Vai vainīga bija angļu valoda?",
				lines = {
					"Nē. Angliski es saprotu labi — pagaidām pat labāk nekā latviski.",
					"Problēma ir „stuff”. Arī angliski tas neko konkrētu nenozīmē.",
				},
			},
			{
				ask = "Kas tev būtu palīdzējis?",
				lines = {
					"Datums, laiks, telpa un tas, kas jāņem līdzi. Ar pilnīgiem vārdiem.",
					"Īsa ziņa var būt skaidra. Un gara var būt neskaidra.",
				},
			},
		},
	},
}

------------------------------------------------------------------------
-- deduction
------------------------------------------------------------------------
Case.deduction = {
	prompt = "Atzīmē visus patiesos iemeslus.",
	options = {
		{ text = "„Rīt” bija divdomīgs, jo ziņa tika nosūtīta pēc pusnakts.", correct = true,
			why = "Markusam „rīt” nozīmēja ceturtdienu, bet tiem, kas lasīja no rīta, — piektdienu." },
		{ text = "Nebija norādīts, kura laboratorija. Skolā tās ir trīs.", correct = true,
			why = "Emīls gaidīja ķīmijas laboratorijā." },
		{ text = "„Pēc stundām” katrai klasei nozīmē citu laiku.", correct = true,
			why = "Astotajām klasēm tas ir 14.10, vienpadsmitajām — 15.00. Tāpēc atnāca tikai 11. klase." },
		{ text = "Nebija skaidrs, kas jāņem līdzi.", correct = true,
			why = "„Stuff” nav saraksts. Daniela palika mājās." },
		{ text = "Skolēnus robotika vienkārši neinteresē.", correct = false,
			why = "Pierādījumi liecina par pretējo: Emīls atnāca, tikai ne tur." },
		{ text = "Ziņā bija angļu vārdi — tie ir visa problēma.", correct = false,
			why = "Daniela angliski saprot labi. Vainīga bija neskaidrība, nevis valoda." },
	},
}

------------------------------------------------------------------------
-- final message. q = "clear" | "ok" | "vague" | "wrong" | "register"
------------------------------------------------------------------------
Case.messages = {
	{
		id = "chat",
		tab = "Pulčiņa čats",
		chatTitle = "Robotikas pulčiņš",
		audience = "Skolēni no 8. līdz 11. klasei. Var rakstīt brīvāk, bet skaidri.",
		sender = "Markuss (administrators)",
		template = "{what} būs {when} {where}. {bring}",
		slots = {
			{ id = "what", label = "Kas", options = {
				{ text = "Robotikas darbnīca", q = "clear" },
				{ text = "Workshop", q = "ok", why = "Skolēni saprot. Draugu čatā tas ir normāli." },
				{ text = "Pasākums", q = "vague", why = "Kāds pasākums? Diskotēka? Talka?" },
			} },
			{ id = "when", label = "Kad", fact = true, options = {
				{ text = "piektdien, 23.10., plkst. 15.00,", q = "clear", requires = { "f_friday", "f_time" } },
				{ text = "rīt pēc stundām", q = "vague", why = "Tieši „rīt” un „pēc stundām” sajauca pirmo ziņu." },
				{ text = "piektdien ap 15:00ish", q = "vague", why = "„Ap” un „ish” — kurš tad atnāks laikus?" },
				{ text = "ceturtdien plkst. 15.00", q = "wrong", why = "Ceturtdiena jau ir pagājusi." },
			} },
			{ id = "where", label = "Kur", fact = true, options = {
				{ text = "4. laboratorijā (IT kabinetā, 2. stāvā)", q = "clear", requires = { "f_room" } },
				{ text = "@ lab", q = "vague", why = "Skolā ir trīs laboratorijas." },
				{ text = "ķīmijas laboratorijā", q = "wrong", why = "Tur Emīls jau gaidīja — viens pats." },
			} },
			{ id = "bring", label = "Ko ņemt", fact = true, options = {
				{ text = "Ņemiet līdzi klēpjdatoru un lādētāju.", q = "clear", requires = { "f_items" } },
				{ text = "Bring ur stuff.", q = "vague", why = "Danielas tulkotājs joprojām nesaprot, kas ir „stuff”." },
				{ text = "Ņemiet savas mantas.", q = "vague", why = "Latviski, bet tikpat neskaidri. Problēma bija saturs, nevis valoda." },
			} },
		},
	},
	{
		id = "parents",
		tab = "Vecāku grupa",
		chatTitle = "8.A vecāki",
		audience = "Vecāki. Pieklājīgi, pilnīgi un bez slenga.",
		sender = "Ilze Kalniņa",
		template = "{greet} {when^} {where} notiks {what}. {ask} {sign}",
		slots = {
			{ id = "greet", label = "Sveiciens", options = {
				{ text = "Labdien!", q = "clear" },
				{ text = "Čau visiem!", q = "register", why = "Vecāku grupā tas izklausās nevietā." },
				{ text = "Yo", q = "register", why = "Nē. Vienkārši nē." },
			} },
			{ id = "what", label = "Kas", options = {
				{ text = "robotikas darbnīca", q = "clear" },
				{ text = "workshop", q = "register", why = "Tieši šo vārdu Emīla mamma nesaprata." },
				{ text = "pasākums", q = "vague", why = "Vecāki nesapratīs, par ko ir runa." },
			} },
			{ id = "when", label = "Kad", fact = true, options = {
				{ text = "piektdien, 23. oktobrī, plkst. 15.00", q = "clear", requires = { "f_friday", "f_time" } },
				{ text = "rīt pēc stundām", q = "vague", why = "Vecāki nezina, kad bērniem beidzas stundas. Un „rīt” atkal ir atkarīgs no tā, kad lasa." },
				{ text = "piektdien ap trijiem", q = "vague", why = "„Ap trijiem” — tas ir 14.50 vai 15.20?" },
			} },
			{ id = "where", label = "Kur", fact = true, options = {
				{ text = "4. laboratorijā (IT kabinetā, 2. stāvā)", q = "clear", requires = { "f_room" } },
				{ text = "skolā", q = "vague", why = "Skola ir liela, un laboratorijas ir trīs." },
				{ text = "@ lab", q = "register", why = "Vecāku grupā „@ lab” ir mīkla, nevis adrese." },
			} },
			{ id = "ask", label = "Lūgums", fact = true, options = {
				{ text = "Lūdzu, atgādiniet bērniem paņemt līdzi klēpjdatoru un lādētāju.", q = "clear", requires = { "f_items" } },
				{ text = "Lai paņem savas lietas.", q = "vague", why = "Kādas lietas? Vecāki to nezina." },
				{ text = "Pls atgādiniet par laptop.", q = "register", why = "„Pls” vecāku grupā neiederas. Un par lādētāju aizmirsts." },
			} },
			{ id = "sign", label = "Paraksts", options = {
				{ text = "Paldies! Ilze Kalniņa, robotikas skolotāja", q = "clear" },
				{ text = "Paldies!", q = "vague", why = "Vecāki nezina, kas raksta." },
				{ text = "xx", q = "register", why = "Skolotāja vecākiem „xx” neraksta." },
			} },
		},
	},
}

------------------------------------------------------------------------
-- q(msgId, slotId) returns variant quality of response for slot
------------------------------------------------------------------------
function Case.replay(q)
	local function good(m, s)
		local v = q(m, s)
		return v == "clear" or v == "ok"
	end
	local cards = {}
	local function add(who, text, n)
		table.insert(cards, { who = who, text = text, count = n })
	end

	add("ilze", "Atnāca tie paši trīs vienpadsmitklasnieki, kas ceturtdien. Uz viņiem var paļauties.", 3)

	if good("chat", "where") and good("chat", "when") then
		add("emils", "Emīls atrada 4. laboratoriju un atveda līdzi divus klasesbiedrus.", 3)
	elseif not good("chat", "where") then
		add("emils", "Emīls atkal gaidīja ķīmijas laboratorijā. Šoreiz piecpadsmit minūtes.", 0)
	else
		add("emils", "Emīls nezināja, vai „rīt” nozīmē šodien, un palika mājās.", 0)
	end

	if good("chat", "bring") and good("chat", "where") then
		add("daniela", "Daniela atnāca ar klēpjdatoru, lādētāju un draudzeni.", 2)
	else
		add("daniela", "Daniela izlasīja ziņu divreiz, tulkotājā — trīsreiz. Un tomēr neatnāca.", 0)
	end

	local parentsOk = good("parents", "when") and good("parents", "where") and good("parents", "ask")
		and q("parents", "what") ~= "register" and q("parents", "greet") ~= "register"
	if parentsOk then
		add("parents", "Emīla mamma atrakstīja: „Paldies, sapratu!” Viņa pateica vēl divām mammām, un atnāca vēl divi astotklasnieki.", 2)
	else
		add("parents", "Vecāku grupā atkal klusums. Tikai „Izlasīja: 14”.", 0)
	end

	local allChat = good("chat", "when") and good("chat", "where") and good("chat", "bring") and good("chat", "what")
	if allChat then
		add("markuss", "Markuss ielika tavu ziņu čatā bez saīsinājumiem. Pirmo reizi.", 0)
	end
	return cards
end

Case.closing = {
	success = "Skolotāja pierakstīja komandu. Šoreiz krēsli tukši nestāvēja.",
	fail = "Piektdiena beidzās, un pārāk daudz krēslu palika tukši. Lieta vēl nav atrisināta.",
}

------------------------------------------------------------------------
-- hints
------------------------------------------------------------------------
Case.hints = {
	{ need = "c_midnight", text = "Paskaties, KAD Markuss sūtīja ziņu. Ne ko, bet kad." },
	{ need = "c_lab", text = "„@ lab” pulčiņa čatā. Izlasi to vēlreiz — lēnām." },
	{ need = "c_three_labs", text = "Cik skolā ir laboratoriju? Paskaties plānā." },
	{ need = "c_grades", text = "„Pēc stundām” — pēc kurām? Ieskaties stundu sarakstā." },
	{ need = "f_items", text = "Skolotājas e-pasts ir garš, bet tajā ir visi fakti." },
	{ need = "f_friday", text = "Kurā datumā ir pēdējā darbnīca? Meklē e-pastā." },
	{ need = "c_motive", text = "Ne viss uz dēļa ir piesprausts. Kaut kas ir saburzīts." },
	{ need = "c_ourlab", text = "Markuss apgalvo, ka viss bija skaidri. Parādi viņam to „ish”." },
	{ need = "c_emils", text = "Emīls saka, ka bija laboratorijā. Kurā tieši? Parādi viņam plānu." },
}
Case.hintFallback = "Tev ir gandrīz viss. Laiks izdarīt secinājumus."

return Case
