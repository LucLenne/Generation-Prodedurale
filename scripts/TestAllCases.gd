extends Node

func _init():
	print("\n⚔️ --- DÉMARRAGE DU TEST UNITAIRE 'HARDCORE' (LOGIQUE UTILISATEUR) --- ⚔️")
	print("--------------------------------------------------------------------------------")
	
	# ==================================================================
	# 1. JEU DE DONNÉES
	# ==================================================================
	var rules = {
		# --- BASE ---
		"rat": ["Rat"],
		"souris": ["^Souris"],
		
		# --- AUTO-PLURIELS ---
		"eau": ["Château"],
		"al": ["Cheval"],
		"bijou": ["Bijou / Bijoux"],
		"pneu": ["Pneu / Pneus"],
		
		# --- AUTO-FÉMININS ---
		"actif": ["Actif"],
		"boucher": ["Boucher"],
		"heureux": ["Heureux"],
		
		# --- LOGIQUE VOYELLES & H ---
		"avion": ["Avion"],
		"image": ["Image"],
		"homme": ["*Homme"],       # H * -> Élision
		"histoire": ["*Histoire"], # H * -> Élision
		"hibou": ["Hibou"],        # H sans * -> Consonne
		"hache": ["Hache"],        # H sans * -> Consonne
		
		# --- PARSING ---
		"vieux": ["vieux / vieux | vieille / vieilles"],
		"foufou": ["fou / fous | folle / folles"],
		"grec": ["grec | grecque"]
	}
	
	var grammar = TraceryFR.GrammarFR.new(rules)
	
	var tests = [
		# A. PARSING
		{"tag": "#vieux#",     "expect": "vieux",    "desc": "Parsing: Masc Singulier"},
		{"tag": "#vieux.s#",   "expect": "vieux",    "desc": "Parsing: Masc Pluriel Invariant"},
		{"tag": "#vieux.f#",   "expect": "vieille",  "desc": "Parsing: Fem Singulier"},
		{"tag": "#vieux.f.s#", "expect": "vieilles", "desc": "Parsing: Fem Pluriel"},
		{"tag": "#foufou.s#",  "expect": "fous",     "desc": "Parsing: Irrégulier Masc Pluriel"},
		{"tag": "#foufou.f#",  "expect": "folle",    "desc": "Parsing: Irrégulier Fem Singulier"},

		# B. RÈGLES AUTO
		{"tag": "#eau.s#",       "expect": "Châteaux",   "desc": "Auto-Pluriel: eau -> x"},
		{"tag": "#al.s#",        "expect": "Chevaux",    "desc": "Auto-Pluriel: al -> aux"},
		{"tag": "#souris.s#",    "expect": "Souris",     "desc": "Auto-Pluriel: s -> invariant"},
		{"tag": "#pneu.s#",      "expect": "Pneus",      "desc": "Pluriel Exception: eu -> s"},
		{"tag": "#actif.f#",     "expect": "Active",     "desc": "Auto-Féminin: f -> ve"},
		{"tag": "#boucher.f#",   "expect": "Bouchère",   "desc": "Auto-Féminin: er -> ère"},
		{"tag": "#heureux.f#",   "expect": "Heureuse",   "desc": "Auto-Féminin: x -> se"},
		{"tag": "#grec.f#",      "expect": "grecque",    "desc": "Féminin Exception"},

		# C. ARTICLES DÉFINIS (.def)
		{"tag": "#rat.def#",     "expect": "le Rat",     "desc": "Def: Masc Consonne"},
		{"tag": "#avion.def#",   "expect": "l'Avion",    "desc": "Def: Masc Voyelle"},
		{"tag": "#souris.def#",  "expect": "la Souris",  "desc": "Def: Fem Consonne"},
		{"tag": "#image.def#",   "expect": "l'Image",    "desc": "Def: Fem Voyelle"},
		{"tag": "#homme.def#",   "expect": "l'Homme",    "desc": "Def: H marqué (*)"},
		{"tag": "#hibou.def#",   "expect": "le Hibou",   "desc": "Def: H non marqué"},
		{"tag": "#histoire.def#","expect": "l'Histoire", "desc": "Def: H Fem marqué (*)"},
		{"tag": "#hache.def#",   "expect": "la Hache",   "desc": "Def: H Fem non marqué"},
		{"tag": "#avion.s.def#", "expect": "les Avions", "desc": "Def: Pluriel bat Voyelle"},

		# D. ARTICLES INDÉFINIS (.indef)
		{"tag": "#rat.indef#",    "expect": "un Rat",    "desc": "Indef: Masc"},
		{"tag": "#souris.indef#", "expect": "une Souris","desc": "Indef: Fem"},
		{"tag": "#avion.indef#",  "expect": "un Avion",  "desc": "Indef: Pas d'élision sur Un"},
		{"tag": "#rat.s.indef#",  "expect": "des Rats",  "desc": "Indef: Pluriel"},

		# E. PARTITIFS DÉFINIS (.partDef)
		{"tag": "#rat.partDef#",    "expect": "du Rat",      "desc": "PartDef: Masc Consonne"},
		{"tag": "#souris.partDef#", "expect": "de la Souris","desc": "PartDef: Fem Consonne"},
		{"tag": "#avion.partDef#",  "expect": "de l'Avion",  "desc": "PartDef: Voyelle"},
		{"tag": "#homme.partDef#",  "expect": "de l'Homme",  "desc": "PartDef: H marqué (*)"},
		{"tag": "#hibou.partDef#",  "expect": "du Hibou",    "desc": "PartDef: H non marqué"},
		{"tag": "#hache.partDef#",  "expect": "de la Hache", "desc": "PartDef: H Fem non marqué"},
		{"tag": "#rat.s.partDef#",  "expect": "des Rats",    "desc": "PartDef: Pluriel"},

		# F. PARTITIFS INDÉFINIS (.partIndef)
		{"tag": "#rat.partIndef#",    "expect": "d'un Rat",     "desc": "PartIndef: Masc"},
		{"tag": "#souris.partIndef#", "expect": "d'une Souris", "desc": "PartIndef: Fem"},
		{"tag": "#hibou.partIndef#",  "expect": "d'un Hibou",   "desc": "PartIndef: H"},
		{"tag": "#rat.s.partIndef#",  "expect": "des Rats",     "desc": "PartIndef: Pluriel"},

		# G. PRÉPOSITION 'À' (.a)
		{"tag": "#rat.a#",     "expect": "au Rat",      "desc": "À: Masc Consonne -> Au"},
		{"tag": "#souris.a#",  "expect": "à la Souris", "desc": "À: Fem Consonne -> À la"},
		{"tag": "#avion.a#",   "expect": "à l'Avion",   "desc": "À: Voyelle -> À l'"},
		{"tag": "#homme.a#",   "expect": "à l'Homme",   "desc": "À: H marqué (*) -> À l'"},
		{"tag": "#hibou.a#",   "expect": "au Hibou",    "desc": "À: H non marqué -> Au"},
		{"tag": "#rat.s.a#",   "expect": "aux Rats",    "desc": "À: Pluriel -> Aux"},

		# H. DÉMONSTRATIFS (.dem)
		{"tag": "#rat.dem#",    "expect": "ce Rat",      "desc": "Dem: Masc Consonne -> Ce"},
		{"tag": "#avion.dem#",  "expect": "cet Avion",   "desc": "Dem: Masc Voyelle -> Cet"},
		{"tag": "#souris.dem#", "expect": "cette Souris","desc": "Dem: Fem -> Cette"},
		{"tag": "#homme.dem#",  "expect": "cet Homme",   "desc": "Dem: H marqué (*) -> Cet"},
		{"tag": "#hibou.dem#",  "expect": "ce Hibou",    "desc": "Dem: H non marqué -> Ce"},
		{"tag": "#rat.s.dem#",  "expect": "ces Rats",    "desc": "Dem: Pluriel -> Ces"},

		# I. POSSESSIFS (.poss) - Euphonie
		{"tag": "#rat.poss#",     "expect": "son Rat",      "desc": "Poss: Masc -> Son"},
		{"tag": "#souris.poss#",  "expect": "sa Souris",    "desc": "Poss: Fem Consonne -> Sa"},
		{"tag": "#image.poss#",   "expect": "son Image",    "desc": "Poss: Fem Voyelle -> Son (Euphonie)"},
		{"tag": "#histoire.poss#","expect": "son Histoire", "desc": "Poss: Fem H marqué (*) -> Son (Euphonie)"},
		{"tag": "#hache.poss#",   "expect": "sa Hache",     "desc": "Poss: Fem H non marqué -> Sa (Pas d'euphonie)"},
		{"tag": "#rat.s.poss#",   "expect": "ses Rats",     "desc": "Poss: Pluriel -> Ses"}
	]
	
	var passed = 0
	var failed = 0
	
	for t in tests:
		var result = grammar.flatten(t["tag"])
		
		# Affichage Formaté pour plus de lisibilité
		var padding = " ".repeat(40 - t["desc"].length()) if t["desc"].length() < 40 else " "
		
		if result != t["expect"]:
			print("❌ [FAIL] ", t["desc"], padding, "| Got: '", result, "' (Attendu: '", t["expect"], "')")
			failed += 1
		else:
			print("✅ [OK]   ", t["desc"], padding, "| '", result, "'")
			passed += 1
			
	print("--------------------------------------------------------------------------------")
	if failed == 0:
		print("🏆 SUCCÈS TOTAL : ", passed, "/", passed, " tests validés !")
	else:
		print("⚠️  ÉCHEC : ", failed, " erreurs détectées sur ", passed + failed, " tests.")
