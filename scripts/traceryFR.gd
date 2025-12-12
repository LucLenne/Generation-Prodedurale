# From "https://github.com/Althar93/GDTracery", adapted to Godot 4
class_name TraceryFR
extends RefCounted
		
		
class ModifiersFR extends RefCounted:

	const MARQUEURS = ["^", "*", "$", "!"] # ^pour le féminin, * pour le h muet, $ flag pour les articles pour dire que le mot est au pluriel, ! pour le masculin strict
	const VOYELLES_ACCENTS = "aeiouyàâäéèêëîïôöùûüÿ" # Liste complète pour éviter la normalisation coûteuse

	# On compile le Regex une seule fois au chargement du script (Static)
	static var _regex_symbol: RegEx = null

	static func _get_regex() -> RegEx:
		if _regex_symbol == null:
			_regex_symbol = RegEx.new()
			_regex_symbol.compile("[a-zA-ZÀ-ÿ]")
		return _regex_symbol

	static func _is_consonant(character: String) -> bool:
		if character.is_empty():
			push_error("_is_consonant : Character is empty")
		var lower_char = character.to_lower()
		return VOYELLES_ACCENTS.find(lower_char) == -1

	static func _is_symbol(character: String) -> bool:
		return _get_regex().search(character) == null


	static func _remove_accents(word: String) -> String:
		var ts = TextServerManager.get_primary_interface()
		return ts.strip_diacritics(word)
		
		
	static func _has_marker(word: String, marker: String) -> bool:
		var prefix = word.substr(0, 3) 
		return marker in prefix


	static func _get_word_without_marker(word: String) -> String:
		if word.is_empty(): return ""
		
		var clean_word = word
		var cleaning = true
		while cleaning and not clean_word.is_empty():
			var first_char = clean_word[0]
			if first_char in MARQUEURS:
				clean_word = clean_word.substr(1)
			else:
				cleaning = false
				
		return clean_word
		
	
	static func _get_word_without_gender_separator(word: String) -> String:
		if word.is_empty(): return ""
	
		# On garde uniquement la partie Masculin
		if "|" in word:
			return word.split("|")[0].strip_edges()
		return word
		
	static func _get_word_without_number_separator(word: String) -> String:
		if word.is_empty(): return ""
		
		if "/" in word:
			return word.split("/")[0].strip_edges()
		return word
		
	static func _get_word_without_separators(word: String) -> String:
		if word.is_empty(): return ""
		
		# On garde uniquement la partie Masculin Singulier pour l'analyse
		if "|" in word:
			word = _get_word_without_gender_separator(word)
		if "/" in word:
			word = _get_word_without_number_separator(word)	
		return word
	

	static func _has_GenderException_Seperator(word: String, emptyStrIfNot: bool = true) -> String:
		var parts = word.split("|")
		if parts.size() > 1:
			return parts[1].strip_edges()
		if emptyStrIfNot :
			return "" 
		else :
			return parts[0]

	static func _has_NumberException_Seperator(word: String, emptyStrIfNot: bool = true) -> String:
		var parts = word.split("/")
		if parts.size() > 1:
			return parts[1].split("|")[0].strip_edges()
		if emptyStrIfNot :
			return "" 
		else :
			return parts[0]

	static func _has_maleOnly_marker(word : String) -> bool :
		return _has_marker(word, "!")
		
	static func _has_female_marker(word : String) -> bool:
		return _has_marker(word, "^")

	static func _is_female(word: String) -> bool:
		if _has_maleOnly_marker(word) :
			return false
		if not _has_GenderException_Seperator(word).is_empty() :
			return false
		return _has_female_marker(word)
			
	static func _is_plural(word : String) -> bool:
		return _has_marker(word, "$")

	static func _need_elision(word: String) -> bool:
		if word.is_empty():
			push_error("_need_elision : Word is empty")
			return false
			
		# Si marqué par *, c'est un H aspiré (Homme, Héroine) -> élision
		if _has_marker(word, "*"): 
			return true
			
		var word_root = _get_word_without_marker(word)
		word_root = _get_word_without_separators(word_root)
		
		if word_root.is_empty(): 
			return false
		
		return not _is_consonant(word_root[0])
	
			
class UniversalModifiersFR extends ModifiersFR:
	
	static func get_modifiers() -> Dictionary:
		return {
			"def": [UniversalModifiersFR, "_def"],
			"indef" : [UniversalModifiersFR, "_indef"],
			"partDef" : [UniversalModifiersFR, "_partDef"],
			"partIndef" : [UniversalModifiersFR, "_partIndef"],
			"a" : [UniversalModifiersFR, "_a"],
			"poss_s" : [UniversalModifiersFR, "_poss_s"],
			"poss_m" : [UniversalModifiersFR, "_poss_m"],
			"dem" : [UniversalModifiersFR, "_dem"],
			"f" : [UniversalModifiersFR, "_f"],
			"s": [UniversalModifiersFR, "_s"],
			"capitalize": [UniversalModifiersFR, "_capitalize"],
			"capitalizeAll": [UniversalModifiersFR, "_capitalize_all"],
			"comma": [UniversalModifiersFR, "_comma"],
			"inQuotes": [UniversalModifiersFR, "_in_quotes"]
		}
		
	static func _def(string : String) -> String :
		if string.is_empty() :
			push_error("_def : string is empty")
		if _is_plural(string) :
			return "les " + _get_word_without_marker(string)
		if _need_elision(string) :
			return "l'" + _get_word_without_marker(string)
		if _is_female(string):
			return "la " + _get_word_without_marker(string)
		return "le " + _get_word_without_marker(string)
	
		
	static func _indef(string : String) -> String :
		if string.is_empty() :
			push_error("_indef : string is empty")
		if _is_plural(string) :
			return "des " + _get_word_without_marker(string)
		if _is_female(string):
			return "une " + _get_word_without_marker(string)
		return "un " + _get_word_without_marker(string)
	
	static func _partDef(string : String) -> String :
		if string.is_empty() :
			push_error("_partDef : string is empty")
		if _is_plural(string) :
			return "des " + _get_word_without_marker(string)
		if _need_elision(string) :
			return "de l'" + _get_word_without_marker(string)
		if _is_female(string):
			return "de la " + _get_word_without_marker(string)
		return "du " + _get_word_without_marker(string)
		
	static func _partIndef(string : String) -> String :
		if string.is_empty() :
			push_error("_partIndef : string is empty")
		if _is_plural(string) :
			return "des " + _get_word_without_marker(string)
		if _is_female(string):
			return "d'une " + _get_word_without_marker(string)
		return "d'un " + _get_word_without_marker(string)
		
	static func _a(string : String) -> String :
		if string.is_empty() :
			push_error("_a : string is empty")
		if _is_plural(string) :
			return "aux " + _get_word_without_marker(string)
		if _need_elision(string):
			return "à l'" + _get_word_without_marker(string)
		if _is_female(string) :
			return "à la " + _get_word_without_marker(string)
		return "au " + _get_word_without_marker(string)
	
	static func _poss_s(string : String) -> String :
		if string.is_empty() :
			push_error("_poss_s : string is empty")
		if _is_plural(string) :
			return "ses " + _get_word_without_marker(string)
		if _need_elision(string):
			return "son " + _get_word_without_marker(string)
		if _is_female(string):
			return "sa " + _get_word_without_marker(string)
		return "son " + _get_word_without_marker(string)
		
	static func _poss_m(string : String) -> String :
		if string.is_empty() :
			push_error("_poss_m : string is empty")
		if _is_plural(string) :
			return "mes " + _get_word_without_marker(string)
		if _need_elision(string):
			return "mon " + _get_word_without_marker(string)
		if _is_female(string):
			return "ma " + _get_word_without_marker(string)
		return "mon " + _get_word_without_marker(string)
	
	static func _dem(string : String) -> String :
		if string.is_empty() :
			push_error("_dem : string is empty")
		
		if _is_plural(string) :
			return "ces " + _get_word_without_marker(string)
		if _need_elision(string):
			return "cet " + _get_word_without_marker(string)
		if _is_female(string):
			return "cette " + _get_word_without_marker(string)
		return "ce " + _get_word_without_marker(string)
		
	static func _f (string : String) -> String :
		
		if string.is_empty() :
			push_error("_f : string is empty")
		
		if _has_maleOnly_marker(string) :
			return string
		
		if _has_female_marker(string):
			return string
			
		var marker = ""
		if _has_marker(string, "*") :
			marker += "*"
			
		var clean_word = _get_word_without_marker(string)
		
		var exceptionString = _has_GenderException_Seperator(clean_word);
		if not exceptionString.is_empty() : 
			var result = exceptionString.strip_edges() # si il a aussi un séparateur pluriel on renvoie feminin singulier / féminin pluriel
			# On force le marqueur féminin sur le résultat
			if "*" in marker:
				result = "*" + result
			return "^" + result # c'est féminin dans tous les cas
		
			
		# Nettoyer le mot des marqueurs et séparateurs pour les vérifications suivantes
		var singular = _get_word_without_separators(clean_word) # on enlève le séparator de pluriel, on récupère la version singulière
		
		var res = ""
		if singular.ends_with("e") :
			res = clean_word
		elif singular.ends_with("f") :
			res = clean_word.left(-1) + "ve"
		elif singular.ends_with("x") :
			res = clean_word.left(-1) + "se"
		elif singular.ends_with("er") :
			res = clean_word.left(-2) + "ère"
		elif singular.ends_with("eur") :
			res = clean_word.left(-3) + "euse"
		elif _is_consonant(singular.right(1)) and not _is_consonant(singular.substr(singular.length() - 2, 1)) : # si le mot se finit par une consonne et que l'avant dernière lettre est une voyelle
			res = clean_word + clean_word.right(1) + "e" #on double la consonne
		else:
			res = clean_word + "e"
			
		# On ajoute le marqueur féminin si pas présent
		if "^" in marker:
			res =  "^" + res
		if "*" in marker:
			return "*" + res
		return res
		
		
	static func _s (string : String) -> String :
		if string.is_empty() :
			push_error("_s : string is empty")
		
		var markers = ""
		if _has_female_marker(string):
			markers += "^"
		if  _has_marker(string, "*"):
			markers += "*"
			
		var clean_word = _get_word_without_marker(string)
		
		var exceptionString = _has_NumberException_Seperator(clean_word);
		if not exceptionString.is_empty() :
			var result = exceptionString.strip_edges()
			if "^" in markers: 
				result = "^" + result
			if "*" in markers :
				return "$*" + result
			return "$" + result
		
		# Nettoyer le mot des marqueurs et séparateurs pour les vérifications suivantes
		
		clean_word = _get_word_without_separators(clean_word)
		
		var res = clean_word
		if clean_word.ends_with("s") or clean_word.ends_with("x") or clean_word.ends_with("z"):
			res = clean_word
		elif clean_word.ends_with("au") or clean_word.ends_with("eau") or clean_word.ends_with("eu") :
			res = clean_word + "x"
		elif clean_word.ends_with("al") :
			res = clean_word.left(clean_word.length() - 2) + "aux"
		else:
			res = clean_word + "s"
			
		return "$" + markers + res
		
	static func _capitalize(string: String) -> String:
		if string.is_empty():
			return string
			
		var marker_length = 0
		while marker_length < string.length() and string[marker_length] in MARQUEURS:
			marker_length += 1
			
		if marker_length >= string.length():
			return string
			
		var prefix = string.substr(0, marker_length)
		var word = string.substr(marker_length)
		
		return prefix + word[0].to_upper() + word.substr(1)
		
	static func _capitalize_all(string: String) -> String:
		return string.to_upper() # to_upper n'affecte pas les symboles ^ et * donc c'est ok
		
	static func _comma(string: String) -> String:
		if string.is_empty():
			return ","
		var last_character := string[string.length() - 1]
		match last_character:
			",", ".", "?", "!":
				return string
			_:
				return string + ","
			
	static func _in_quotes(string: String) -> String:
		return "\"" + string + "\""
				
				
# Main grammar
class GrammarFR extends RefCounted:
	
	var rng: RandomNumberGenerator:
		set(value):
			rng = value
		get:
			return rng
	
	var _modifier_lookup: Dictionary = {} 
	var _rules: Dictionary = {} 
	var _save_data: Dictionary = {} 
	
	var _expansion_regex: RegEx = null 
	var _save_symbol_regex: RegEx = null 
	
	
	func _init(rules: Dictionary) -> void:
		_expansion_regex = RegEx.new()
		
		var err := _expansion_regex.compile("#([^#]+)#")
		if err != OK:
			push_error("Tracery: failed to compile expansion regex")

		_save_symbol_regex = RegEx.new()
		err = _save_symbol_regex.compile("\\[([^\\]]+)\\]")
		
		if err != OK:
			push_error("Tracery: failed to compile save symbol regex")
		
		rng = RandomNumberGenerator.new()
		rng.randomize()
		
		_rules = rules.duplicate(true)
		
		_modifier_lookup.clear()
		add_modifiers(UniversalModifiersFR.get_modifiers())
	
	
	func add_modifier(key: String, object: Object, function_name: String) -> void:
		# J'enregistre un modificateur individuel sous une clé, au format [objet, nom_de_fonction]
		_modifier_lookup[key] = [object, function_name]
	
	
	func add_modifiers(modifiers: Dictionary) -> void:
		# J'ajoute en une fois plusieurs modificateurs depuis un dictionnaire déjà au bon format
		for k in modifiers.keys():
			_modifier_lookup[k] = modifiers[k]
	
	
	func flatten(rule: String, strip_markers: bool = true) -> String:
		# Si la règle est vide je renvoie directement une chaîne vide
		if rule.is_empty():
			return rule

		# D'abord je traite toutes les actions [nom:valeur] et je les retire du texte
		rule = _resolve_save_symbols(rule)

		var result := ""
		var pos := 0

		while true:
			# Je cherche le prochain tag de type #...#
			var match := _expansion_regex.search(rule, pos)
			if match == null:
				break

			var start := match.get_start(0)
			var end := match.get_end(0)
			var tag := match.get_string(0) # Exemple "#hero.capitalize#"

			# J'ajoute au résultat tout le texte avant le tag courant
			result += rule.substr(pos, start - pos)

			# Je récupère le contenu interne du tag sans les #
			var inner := tag.substr(1, tag.length() - 2)
			# Je sépare le symbole des éventuels modificateurs avec "."
			var parts := inner.split(".")
			var symbol := parts[0]
			var modifiers := parts.slice(1, parts.size())

			var selected_rule: Variant
			if _save_data.has(symbol):
				selected_rule = _save_data[symbol]
			elif _rules.has(symbol):
				selected_rule = _rules[symbol]
			else:
				# Si je ne trouve rien je prends le nom du symbole tel quel comme texte brut
				selected_rule = symbol

			var resolved := ""

			# Si la règle est un tableau je pioche une entrée aléatoire dedans
			if typeof(selected_rule) == TYPE_ARRAY:
				var arr: Array = selected_rule
				if arr.size() == 0:
					resolved = ""
				else:
					var choice : String = arr[rng.randi() % arr.size()]
					resolved = flatten(choice, false)
			else:
				resolved = flatten(str(selected_rule), false)

			if resolved.length() > 1 :
				resolved = _apply_modifiers(resolved, modifiers)

			# J'ajoute le texte final au résultat
			result += resolved

			# Je continue la recherche après la fin du tag traité
			pos = end

		result += rule.substr(pos)
		
	
		if strip_markers:
			return ModifiersFR._get_word_without_marker(result)
		return result
	
	
	func _resolve_save_symbols(rule: String) -> String:
		
		var matches := _save_symbol_regex.search_all(rule)
		if matches.is_empty():
			return rule

		for m in matches:
			var full := m.get_string(0)
			
			var content := full.substr(1, full.length() - 2)
			var parts := content.split(":")

			if parts.size() == 2:
				# Cas [nom:valeur]
				var name := parts[0].strip_edges()
				var rhs := parts[1].strip_edges()

				if rhs.find(",") != -1:
					
					var arr := []
					for p in rhs.split(","):
						arr.append(p.strip_edges())
					_save_data[name] = arr
				else:
					
					_save_data[name] = flatten(rhs, false)
			else:
				# Cas [nom] que je résous comme #nom#
				var name2 := content.strip_edges()
				# IMPORTANT: On ne strip pas les marqueurs
				_save_data[name2] = flatten("#" + name2 + "#", false)

		
		return _save_symbol_regex.sub(rule, "", true)

	
	
	func _get_modifiers(symbol: String) -> Array:
	
		var modifiers := symbol.replace("#", "").split(".")
		if modifiers.size() > 0:
	
			modifiers.remove_at(0)
		return modifiers
	
	
	func _apply_modifiers(resolved: String, modifiers: Array) -> String:
		# je définis les priorités
		var priority_map = {
			"f": 1,         
			"s": 2,          
			"def": 3,        
			"indef": 3,
			"partDef": 3,
			"partIndef":3,
			"poss_m":3,
			"poss_s":3,
			"dem" : 3,
			"a" : 3,
			
		}
	
		# je fais une pré-résolution des modificateurs dynamiques Ex heroGender : f <- c'est ça le modifier dynamique
		var expanded_modifiers = []
		for m in modifiers:
			if _save_data.has(m):
				# C'est une variable, on récupère sa valeur
				var val = _save_data[m]
				
				# Gestion des chaînes vides : si la valeur est vide, on l'ignore
				if typeof(val) == TYPE_STRING and val.is_empty():
					continue
					
				if typeof(val) == TYPE_ARRAY:
					expanded_modifiers.append_array(val)
				else:
					expanded_modifiers.append(str(val))
			else:
				# Ce n'est pas une variable connue, on garde le modificateur tel quel
				expanded_modifiers.append(m)
		
		# Trier les modificateurs selon leur priorité
		var sorted_modifiers = expanded_modifiers
		sorted_modifiers.sort_custom(func(a, b):
			var priority_a = priority_map.get(a, 999)  
			var priority_b = priority_map.get(b, 999)
			return priority_a < priority_b
		)
		

		if "f" not in sorted_modifiers:
			resolved = ModifiersFR._get_word_without_gender_separator(resolved)
		
		# Application des modificateurs
		for m in sorted_modifiers:
			
			if m != "f" and m != "s" and "s" not in sorted_modifiers:
				resolved = ModifiersFR._get_word_without_number_separator(resolved)
			
			if _modifier_lookup.has(m):
				var obj = _modifier_lookup[m][0]
				var func_name = _modifier_lookup[m][1]
				resolved = obj.call(func_name, resolved)
			
					

		if "s" not in sorted_modifiers:
			resolved = ModifiersFR._get_word_without_number_separator(resolved)
			
		return ModifiersFR._get_word_without_marker(resolved) 
