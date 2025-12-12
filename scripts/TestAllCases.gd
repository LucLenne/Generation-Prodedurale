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
		"frère" : ["Frère | Soeur"],
		"mari" : ["Mari | Femme"],
		
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
		"hache": ["^Hache"],        # H sans * -> Consonne
		
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
		
		# 7. Possessifs et pièges
		"amie": ["Amie"],
		# Mots MASCULINS finissant par 'e' (Masculin Exclusif)
		"monde": ["Monde"],      
		"probleme": ["Problème"],
		"musee": ["Musée"],
		"arbre": ["Arbre"],

		# 8. Mots MASCULINS finissant par 'e' MAIS avec Exception FÉMININE
		"prince": ["Prince / Princes | Princesse / Princesses"],
		"tigre": ["Tigre / Tigres | Tigresse / Tigresses"],
		"ane": ["Âne / Ânes | Ânesse / Ânesses"] # Le boss final (Voyelle + E + Exception)
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

		# B. RÈGLES AUTO
		{"tag": "#eau.s#",       "expect": "Châteaux",   "desc": "Auto-Pluriel: eau -> x"},
		{"tag": "#al.s#",        "expect": "Chevaux",    "desc": "Auto-Pluriel: al -> aux"},
		{"tag": "#souris.s#",    "expect": "Souris",     "desc": "Auto-Pluriel: s -> invariant"},
		{"tag": "#pneu.s#",      "expect": "Pneus",      "desc": "Pluriel Exception: eu -> s"},
		{"tag": "#actif.f#",     "expect": "Active",     "desc": "Auto-Féminin: f -> ve"},
		{"tag": "#boucher.f#",   "expect": "Bouchère",   "desc": "Auto-Féminin: er -> ère"},
		{"tag": "#heureux.f#",   "expect": "Heureuse",   "desc": "Auto-Féminin: x -> se"},
		{"tag": "#grec.f#",      "expect": "grecque",    "desc": "Féminin Exception"},

		# C. ARTICLES DÉFINIS
		{"tag": "#rat.def#",     "expect": "le Rat",     "desc": "Def: Masc Consonne"},
		{"tag": "#avion.def#",   "expect": "l'Avion",    "desc": "Def: Masc Voyelle"},
		{"tag": "#souris.def#",  "expect": "la Souris",  "desc": "Def: Fem Consonne"},
		{"tag": "#image.def#",   "expect": "l'Image",    "desc": "Def: Fem Voyelle"},
		{"tag": "#homme.def#",   "expect": "l'Homme",    "desc": "Def: H marqué (*)"},
		{"tag": "#hibou.def#",   "expect": "le Hibou",   "desc": "Def: H non marqué"},
		{"tag": "#histoire.def#","expect": "l'Histoire", "desc": "Def: H Fem marqué (*)"},
		{"tag": "#hache.def#",   "expect": "la Hache",   "desc": "Def: H Fem non marqué"},
		{"tag": "#avion.s.def#", "expect": "les Avions", "desc": "Def: Pluriel bat Voyelle"},

		# D. ARTICLES INDÉFINIS
		{"tag": "#rat.indef#",    "expect": "un Rat",    "desc": "Indef: Masc"},
		{"tag": "#souris.indef#", "expect": "une Souris","desc": "Indef: Fem"},
		{"tag": "#avion.indef#",  "expect": "un Avion",  "desc": "Indef: Pas d'élision sur Un"},
		{"tag": "#rat.s.indef#",  "expect": "des Rats",  "desc": "Indef: Pluriel"},

		{"tag": "#frère.f.indef#",  "expect": "une Soeur",  "desc": "Indef: Fem"},
		{"tag": "#frère.f.s.indef#",  "expect": "des Soeurs",  "desc": "Indef: Fem Pluriel"},
		{"tag": "#mari.f.indef#",  "expect": "une Femme",  "desc": "Indef: Fem"},
		{"tag": "#mari.f.s.indef#",  "expect": "des Femmes",  "desc": "Indef: Fem Pluriel"},
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
		{"tag": "#rat.poss_s#",      "expect": "son Rat",      "desc": "Poss: Masc -> Son"},
		{"tag": "#souris.poss_s#",   "expect": "sa Souris",    "desc": "Poss: Fem Consonne -> Sa"},
		{"tag": "#image.poss_s#",    "expect": "son Image",    "desc": "Poss: Fem Voyelle -> Son (Euphonie)"},
		{"tag": "#histoire.poss_m#", "expect": "mon Histoire", "desc": "Poss: Fem H marqué (*) -> Son (Euphonie)"},
		{"tag": "#hache.poss_s#",    "expect": "sa Hache",     "desc": "Poss: Fem H non marqué -> Sa (Pas d'euphonie)"},
		{"tag": "#rat.s.poss_s#",    "expect": "ses Rats",     "desc": "Poss: Pluriel -> Ses"}
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
		{"tag": "#oeil.def#",      "expect": "l'Oeil",   "desc": "Def: Masc Voyelle"},
		{"tag": "#oeil.s.def#",    "expect": "les Yeux", "desc": "Def: Plural Irregular overrides elision"},
		{"tag": "#hopital.def#",   "expect": "l'Hôpital","desc": "Def: Masc H Marqué"},
		{"tag": "#hopital.s.def#", "expect": "les Hôpitaux", "desc": "Def: Plural Irregular + H Marqué"},
		{"tag": "#heros.def#",     "expect": "le Héros", "desc": "Def: H Non Marqué (Consonne)"},
		{"tag": "#heros.s.def#",   "expect": "les Héros","desc": "Def: H Non Marqué Plural"}, 
		
		# --- N. FORMATTING COMBOS ---
		{"tag": "#rat.def.capitalize#", "expect": "Le Rat", "desc": "Format: Def(3) then Cap(4) -> Le Rat"},
		{"tag": "#rat.capitalize.def#", "expect": "Le Rat", "desc": "Format: Sorted to Def then Cap -> Le Rat"},
		{"tag": "#rat.capitalizeAll.def#", "expect": "LE RAT", "desc": "Format: Sorted to Def then CapAll -> LE RAT"},
		{"tag": "#rat.def.capitalizeAll#", "expect": "LE RAT", "desc": "Format: Def then CapAll -> LE RAT"},
		{"tag": "#rat.inQuotes#",       "expect": "\"Rat\"", "desc": "Format: Quotes"},
		{"tag": "#rat.def.inQuotes#",   "expect": "\"le Rat\"", "desc": "Format: Def(3) then Quotes(>3)"},
		
		# --- O. POSSESSIVE EDGE CASES ---
		{"tag": "#amie.poss_s#",     "expect": "son Amie", "desc": "Poss: Fem starting with Vowel (Euphonie)"},
		{"tag": "#heroine.poss_m#",  "expect": "mon Héroïne", "desc": "Poss: Fem H marqué (Euphonie)"},
		{"tag": "#heroine.s.poss_m#", "expect": "mes Héroïnes", "desc": "Poss: Fem Plural H Marqué"},

		# --- P. MASCULIN EXCLUSIF FINISSANT PAR 'E' (Les Pièges) ---
		{"tag": "#monde.poss_m#",    "expect": "mon Monde",    "desc": "Poss_m: Masc 'e' -> Mon"},
		{"tag": "#monde.poss_s#",    "expect": "son Monde",    "desc": "Poss_s: Masc 'e' -> Son"},
		{"tag": "#arbre.poss_m#",    "expect": "mon Arbre",    "desc": "Poss_m: Masc Voyelle -> Mon"},

		# --- Q. MASCULIN FINISSANT PAR 'E' + EXCEPTION FÉMININE ---
		
		# 1. Prince -> Princesse
		{"tag": "#prince#",          "expect": "Prince",       "desc": "Base 'e': Masc reste Masc"},
		{"tag": "#prince.f#",        "expect": "Princesse",    "desc": "Fem Excep: Utilise la règle, n'ajoute pas 'e'"},
		{"tag": "#prince.poss_m#",   "expect": "mon Prince",   "desc": "Poss Masc 'e': Mon (pas ma)"},
		{"tag": "#prince.f.poss_m#", "expect": "ma Princesse", "desc": "Poss Fem Excep: Ma (Consonne)"},
		
		# 2. Tigre -> Tigresse
		{"tag": "#tigre#",           "expect": "Tigre",        "desc": "Base 'e' (Animal)"},
		{"tag": "#tigre.f#",         "expect": "Tigresse",     "desc": "Fem Excep (Animal)"},
		{"tag": "#tigre.poss_s#",    "expect": "son Tigre",    "desc": "Poss Masc 'e' (Animal) -> Son"},
		{"tag": "#tigre.f.poss_s#",  "expect": "sa Tigresse",  "desc": "Poss Fem Excep (Animal) -> Sa"},

		# 3. Âne -> Ânesse (Le Boss Final : Voyelle + E + Exception)
		{"tag": "#ane#",             "expect": "Âne",          "desc": "Base 'e' Voyelle"},
		{"tag": "#ane.f#",           "expect": "Ânesse",       "desc": "Fem Excep Voyelle"},
		{"tag": "#ane.poss_m#",      "expect": "mon Âne",      "desc": "Poss Masc Voyelle -> Mon"},
		{"tag": "#ane.f.poss_m#",    "expect": "mon Ânesse",   "desc": "Poss Fem Excep Voyelle -> Mon (Euphonie!)"},
	]
	
	tests.append_array(stress_tests)
	
	var passed = 0
	var failed = 0
	
	for t in tests:
		var result = grammar.flatten(t["tag"])
		
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
