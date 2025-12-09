extends Node

func _init():
	print("\n⚔️ --- DÉMARRAGE DU TEST UNITAIRE 'HARDCORE' (AVEC PRIORITÉS) --- ⚔️")
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
		
		# --- LOGIQUE VOYELLES & H (Selon ta logique: * = Élision, Sans * = Consonne) ---
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
	
	rules.merge({
		# 1. Pairs Complexes
		"politesse": ["Monsieur / Messieurs | Madame / Mesdames"],
		"humain": ["homme / hommes | femme / femmes"],
		"animal_bizarre": ["cheval / chevaux | jument / juments"],
		
		# 2. Exceptions Genre seul
		"titre": ["Duc | Duchesse"],
		"metier": ["Acteur | Actrice"],
		
		# 3. Exceptions Pluriel seul
		"oeil": ["Oeil / Yeux"],
		"ciel": ["Ciel / Cieux"],
		
		# 4. Invariants
		"nez": ["Nez"], 
		"virus": ["Virus / Virus"],
		
		# 5. Adjectifs bizarres
		"beau": ["beau / beaux | belle / belles"],
		"frais": ["frais / frais | fraîche / fraîches"],
		
		# 6. H et Conflits
		"heros": ["Héros"],        # Pas d'étoile -> Consonne (Le Héros)
		"heroine": ["*Héroïne"],   # Étoile -> Voyelle/Élision (Son Héroïne)
		"hopital": ["*Hôpital / *Hôpitaux"], # Étoile -> L'Hôpital
		
		# 7. Ajout pour test Possessif
		"amie": ["Amie"]
	})
	
	var grammar = TraceryFR.GrammarFR.new(rules)
	
	var tests = [
		# A. PARSING
		{"tag": "#vieux#",     "expect": "vieux",    "desc": "Parsing: Masc Singulier"},
		{"tag": "#vieux.s#",   "expect": "vieux",    "desc": "Parsing: Masc Pluriel Invariant"},
		{"tag": "#vieux.f#",   "expect": "vieille",  "desc": "Parsing: Fem Singulier"},
		{"tag": "#vieux.f.s#", "expect": "vieilles", "desc": "Parsing: Fem Pluriel"},
		{"tag": "#foufou.s#",  "expect": "fous",     "desc": "Parsing: Irrégulier Masc Pluriel"},
		{"tag": "#foufou.f#",  "expect": "folle",    "desc": "Parsing: Irrégulier Fem Singulier"},

		# B. RÈGLES AUTO (Priorité 'f'(1) et 's'(2) testée implicitement)
		{"tag": "#eau.s#",       "expect": "Châteaux",   "desc": "Auto-Pluriel: eau -> x"},
		{"tag": "#al.s#",        "expect": "Chevaux",    "desc": "Auto-Pluriel: al -> aux"},
		{"tag": "#souris.s#",    "expect": "Souris",     "desc": "Auto-Pluriel: s -> invariant"},
		{"tag": "#pneu.s#",      "expect": "Pneus",      "desc": "Pluriel Exception: eu -> s"},
		{"tag": "#actif.f#",     "expect": "Active",     "desc": "Auto-Féminin: f -> ve"},
		{"tag": "#boucher.f#",   "expect": "Bouchère",   "desc": "Auto-Féminin: er -> ère"},
		{"tag": "#heureux.f#",   "expect": "Heureuse",   "desc": "Auto-Féminin: x -> se"},
		{"tag": "#grec.f#",      "expect": "grecque",    "desc": "Féminin Exception"},

		# C. ARTICLES DÉFINIS (Priorité 3)
		{"tag": "#rat.def#",     "expect": "le Rat",     "desc": "Def: Masc Consonne"},
		{"tag": "#avion.def#",   "expect": "l'Avion",    "desc": "Def: Masc Voyelle"},
		{"tag": "#souris.def#",  "expect": "la Souris",  "desc": "Def: Fem Consonne"},
		{"tag": "#image.def#",   "expect": "l'Image",    "desc": "Def: Fem Voyelle"},
		{"tag": "#homme.def#",   "expect": "l'Homme",    "desc": "Def: H marqué (*)"},
		{"tag": "#hibou.def#",   "expect": "le Hibou",   "desc": "Def: H non marqué"},
		{"tag": "#histoire.def#","expect": "l'Histoire", "desc": "Def: H Fem marqué (*)"},
		{"tag": "#hache.def#",   "expect": "la Hache",   "desc": "Def: H Fem non marqué"},
		
		# Test critique de priorité : .s (2) s'exécute avant .def (3)
		# Donc "Avion" devient "Avions" (s), puis "les Avions" (def)
		{"tag": "#avion.s.def#", "expect": "les Avions", "desc": "Def: Pluriel bat Voyelle (Grâce à Priority Map)"},

		# D. ARTICLES INDÉFINIS
		{"tag": "#rat.indef#",    "expect": "un Rat",    "desc": "Indef: Masc"},
		{"tag": "#souris.indef#", "expect": "une Souris","desc": "Indef: Fem"},
		{"tag": "#avion.indef#",  "expect": "un Avion",  "desc": "Indef: Pas d'élision sur Un"},
		{"tag": "#rat.s.indef#",  "expect": "des Rats",  "desc": "Indef: Pluriel"},

		# E. PARTITIFS DÉFINIS
		{"tag": "#rat.partDef#",    "expect": "du Rat",       "desc": "PartDef: Masc Consonne"},
		{"tag": "#souris.partDef#", "expect": "de la Souris","desc": "PartDef: Fem Consonne"},
		{"tag": "#avion.partDef#",  "expect": "de l'Avion",  "desc": "PartDef: Voyelle"},
		{"tag": "#homme.partDef#",  "expect": "de l'Homme",  "desc": "PartDef: H marqué (*)"},
		{"tag": "#hibou.partDef#",  "expect": "du Hibou",    "desc": "PartDef: H non marqué"},
		{"tag": "#hache.partDef#",  "expect": "de la Hache", "desc": "PartDef: H Fem non marqué"},
		{"tag": "#rat.s.partDef#",  "expect": "des Rats",    "desc": "PartDef: Pluriel"},

		# F. PARTITIFS INDÉFINIS
		{"tag": "#rat.partIndef#",    "expect": "d'un Rat",     "desc": "PartIndef: Masc"},
		{"tag": "#souris.partIndef#", "expect": "d'une Souris", "desc": "PartIndef: Fem"},
		{"tag": "#hibou.partIndef#",  "expect": "d'un Hibou",   "desc": "PartIndef: H"},
		{"tag": "#rat.s.partIndef#",  "expect": "des Rats",     "desc": "PartIndef: Pluriel"},

		# G. PRÉPOSITION 'À'
		{"tag": "#rat.a#",     "expect": "au Rat",      "desc": "À: Masc Consonne -> Au"},
		{"tag": "#souris.a#",  "expect": "à la Souris", "desc": "À: Fem Consonne -> À la"},
		{"tag": "#avion.a#",   "expect": "à l'Avion",   "desc": "À: Voyelle -> À l'"},
		{"tag": "#homme.a#",   "expect": "à l'Homme",   "desc": "À: H marqué (*) -> À l'"},
		{"tag": "#hibou.a#",   "expect": "au Hibou",    "desc": "À: H non marqué -> Au"},
		{"tag": "#rat.s.a#",   "expect": "aux Rats",    "desc": "À: Pluriel -> Aux"},

		# H. DÉMONSTRATIFS
		{"tag": "#rat.dem#",    "expect": "ce Rat",      "desc": "Dem: Masc Consonne -> Ce"},
		{"tag": "#avion.dem#",  "expect": "cet Avion",   "desc": "Dem: Masc Voyelle -> Cet"},
		{"tag": "#souris.dem#", "expect": "cette Souris","desc": "Dem: Fem -> Cette"},
		{"tag": "#homme.dem#",  "expect": "cet Homme",   "desc": "Dem: H marqué (*) -> Cet"},
		{"tag": "#hibou.dem#",  "expect": "ce Hibou",    "desc": "Dem: H non marqué -> Ce"},
		{"tag": "#rat.s.dem#",  "expect": "ces Rats",    "desc": "Dem: Pluriel -> Ces"},

		# I. POSSESSIFS
		{"tag": "#rat.poss_s#",     "expect": "son Rat",      "desc": "Poss: Masc -> Son"},
		{"tag": "#souris.poss_s#",  "expect": "sa Souris",    "desc": "Poss: Fem Consonne -> Sa"},
		{"tag": "#image.poss_s#",   "expect": "son Image",    "desc": "Poss: Fem Voyelle -> Son (Euphonie)"},
		{"tag": "#histoire.poss_m#","expect": "mon Histoire", "desc": "Poss: Fem H marqué (*) -> Son (Euphonie)"},
		{"tag": "#hache.poss_s#",   "expect": "sa Hache",     "desc": "Poss: Fem H non marqué -> Sa (Pas d'euphonie)"},
		{"tag": "#rat.s.poss_s#",   "expect": "ses Rats",     "desc": "Poss: Pluriel -> Ses"}
	]
	
	var stress_tests = [
		# --- J. REVERSION TO BASE ---
		{"tag": "#politesse#",     "expect": "Monsieur", "desc": "Base: Return Masc Sing from complex set"},
		{"tag": "#politesse.s#",   "expect": "Messieurs", "desc": "Plural: Irregular Masc Plural"},
		{"tag": "#politesse.f#",   "expect": "Madame",   "desc": "Fem: Irregular Fem Sing"},
		{"tag": "#politesse.f.s#", "expect": "Mesdames", "desc": "Fem Plural: Irregular Fem Plural"},
		
		{"tag": "#humain#",        "expect": "homme",    "desc": "Base: Return Masc Sing"},
		{"tag": "#humain.s#",      "expect": "hommes",   "desc": "Plural: Standard Masc Plural from pair"},
		
		# --- K. MISSING DEFINITIONS ---
		{"tag": "#titre.s#",       "expect": "Ducs",     "desc": "Implicit Plural: Masc (Auto-S)"},
		{"tag": "#titre.f.s#",     "expect": "Duchesses","desc": "Implicit Plural: Fem (Auto-S)"},
		
		{"tag": "#oeil.f#",        "expect": "Oeil",     "desc": "Invalid Gender: Force Fem on Masc -> No Change"}, 
		
		# --- L. ADJECTIVE AGREEMENTS ---
		{"tag": "#beau#",          "expect": "beau",     "desc": "Adj: Masc Sing"},
		{"tag": "#beau.s#",        "expect": "beaux",    "desc": "Adj: Masc Plural (x)"},
		{"tag": "#beau.f#",        "expect": "belle",    "desc": "Adj: Fem Sing (Irregular)"},
		{"tag": "#beau.f.s#",      "expect": "belles",   "desc": "Adj: Fem Plural"},
		
		{"tag": "#frais.s#",       "expect": "frais",    "desc": "Adj: Masc Plural Invariant"},
		{"tag": "#frais.f#",       "expect": "fraîche",  "desc": "Adj: Fem Sing Irregular"},
		
		# --- M. ARTICLE CONFLICTS & PRIORITY ---
		# Grâce à la priorité: .s (2) s'exécute avant .def (3).
		# Donc "Oeil" -> "Yeux" -> "les Yeux".
		{"tag": "#oeil.def#",      "expect": "l'Oeil",   "desc": "Def: Masc Voyelle"},
		{"tag": "#oeil.s.def#",    "expect": "les Yeux", "desc": "Def: Plural Irregular overrides elision"},
		
		{"tag": "#hopital.def#",   "expect": "l'Hôpital","desc": "Def: Masc H Marqué"}, # L'étoile reste souvent dans la string interne, à vérifier selon ton implémentation de clean
		{"tag": "#hopital.s.def#", "expect": "les Hôpitaux", "desc": "Def: Plural Irregular + H Marqué"},
		
		{"tag": "#heros.def#",     "expect": "le Héros", "desc": "Def: H Non Marqué (Consonne)"},
		{"tag": "#heros.s.def#",   "expect": "les Héros","desc": "Def: H Non Marqué Plural"}, 
		
		# --- N. FORMATTING COMBOS (LE PLUS GROS CHANGEMENT DÛ À LA PRIORITY MAP) ---
		# Puisque 'def'(3) est prioritaire sur 'capitalize'(>3), 'def' s'exécute TOUJOURS avant 'capitalize'.
		# Donc on aura toujours "Le Rat" (L'article est capitalisé), jamais "le Rat".
		
		{"tag": "#rat.def.capitalize#", "expect": "Le Rat", "desc": "Format: Def(3) then Cap(4) -> Le Rat"},
		{"tag": "#rat.capitalize.def#", "expect": "Le Rat", "desc": "Format: Sorted to Def then Cap -> Le Rat"},
		
		{"tag": "#rat.capitalizeAll.def#", "expect": "LE RAT", "desc": "Format: Sorted to Def then CapAll -> LE RAT"},
		{"tag": "#rat.def.capitalizeAll#", "expect": "LE RAT", "desc": "Format: Def then CapAll -> LE RAT"},
		
		# Ici, 'inQuotes' est >3, donc 'def'(3) passe avant.
		{"tag": "#rat.inQuotes#",       "expect": "\"Rat\"", "desc": "Format: Quotes"},
		{"tag": "#rat.def.inQuotes#",   "expect": "\"le Rat\"", "desc": "Format: Def(3) then Quotes(>3)"},
		
		# --- O. POSSESSIVE EDGE CASES ---
		{"tag": "#amie.poss_s#",     "expect": "son Amie", "desc": "Poss: Fem starting with Vowel (Euphonie)"},
		
		# Héroïne est marqué * -> Donc Élision/Liaison autorisée (User Logic) -> Donc Euphonie
		{"tag": "#heroine.poss_m#",  "expect": "mon Héroïne", "desc": "Poss: Fem H marqué (Euphonie)"},
		{"tag": "#heroine.s.poss_m#", "expect": "mes Héroïnes", "desc": "Poss: Fem Plural H Marqué"},
	]
	
	tests.append_array(stress_tests)
	
	var passed = 0
	var failed = 0
	
	for t in tests:
		var result = grammar.flatten(t["tag"])
		
		# Nettoyage des étoiles pour la comparaison finale si ton code ne le fait pas à la toute fin
		# Mais je teste avec les étoiles si ton système les garde jusqu'au bout.
		# Si ton système clean à la fin, retire les * dans les "expect".
		
		# Affichage Formaté
		var padding = " ".repeat(45 - t["desc"].length()) if t["desc"].length() < 45 else " "
		
		if result != t["expect"]:
			print("❌ [FAIL] ", t["desc"], padding, "| Got: '", result, "' (Attendu: '", t["expect"], "')")
			failed += 1
		else:
			print("✅ [OK]    ", t["desc"], padding, "| '", result, "'")
			passed += 1
			
	print("--------------------------------------------------------------------------------")
	if failed == 0:
		print("🏆 SUCCÈS TOTAL : ", passed, "/", passed, " tests validés !")
	else:
		print("⚠️  ÉCHEC : ", failed, " erreurs détectées sur ", passed + failed, " tests.")
