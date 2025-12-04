# From "https://github.com/Althar93/GDTracery", adapted to Godot 4
class_name TraceryEN
extends RefCounted
		
		
class ModifiersEN extends RefCounted:
	
	static func _is_consonant(character: String) -> bool:
		if character.is_empty():
			return false
		var lower_case_character := character.to_lower()
		match lower_case_character:
			"a", "e", "i", "o", "u":
				return false
			_:
				return true
			
			
	static func _ends_with_con_y(string: String) -> bool:
		if string.length() < 2:
			return false
		var last_character := string[string.length() - 1]
		var second_to_last_character := string[string.length() - 2]
		if last_character == "y":
			return _is_consonant(second_to_last_character)
		return false
			
			
class UniversalModifiersEN extends ModifiersEN:
	
	static func get_modifiers() -> Dictionary:
		return {
			"a": [UniversalModifiersEN, "_a"],
			"s": [UniversalModifiersEN, "_s"],
			"ed": [UniversalModifiersEN, "_ed"],
			"capitalize": [UniversalModifiersEN, "_capitalize"],
			"capitalizeAll": [UniversalModifiersEN, "_capitalize_all"],
			"comma": [UniversalModifiersEN, "_comma"],
			"inQuotes": [UniversalModifiersEN, "_in_quotes"]
		}
		
	static func _a(string: String) -> String:
		if string.is_empty():
			return string
		var first_character := string[0]
		if not _is_consonant(first_character):
			return "an " + string
		return "a " + string
	
	static func _s(string: String) -> String:
		if string.is_empty():
			return string
		var last := string[string.length() - 1]
		var last_two := ""
		if string.length() >= 2:
			last_two = string.substr(string.length() - 2)
		
		match last:
			"y":
				if _ends_with_con_y(string):
					return string.substr(0, string.length() - 1) + "ies"
				return string + "s"
			"x", "z", "s":
				return string + "es"
			"h":
				if last_two == "ch" or last_two == "sh":
					return string + "es"
		
		if last_two == "ss":
			return string + "es"
		
		return string + "s"
	
	static func _ed(string: String) -> String:
		if string.is_empty():
			return string
		
		var space_idx := string.find(" ")
		var word := string
		var rest := ""
		if space_idx > -1:
			word = string.substr(0, space_idx)
			rest = string.substr(space_idx)
			
		var conjugated := ""
		
		if word.ends_with("y") and _ends_with_con_y(word):
			conjugated = word.substr(0, word.length() - 1) + "ied"
		elif word.ends_with("e"):
			conjugated = word + "d"
		else:
			conjugated = word + "ed"
			
		return conjugated + rest
		
	static func _capitalize(string: String) -> String:
		if string.is_empty():
			return string
		return string[0].to_upper() + string.substr(1)
		
	static func _capitalize_all(string: String) -> String:
		return string.to_upper()
		
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
class GrammarEN extends RefCounted:
	
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
		add_modifiers(UniversalModifiersEN.get_modifiers())
	
	
	func add_modifier(key: String, object: Object, function_name: String) -> void:
		# J'enregistre un modificateur individuel sous une clé, au format [objet, nom_de_fonction]
		_modifier_lookup[key] = [object, function_name]
	
	
	func add_modifiers(modifiers: Dictionary) -> void:
		# J'ajoute en une fois plusieurs modificateurs depuis un dictionnaire déjà au bon format
		for k in modifiers.keys():
			_modifier_lookup[k] = modifiers[k]
	
	
	func flatten(rule: String) -> String:
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

			# Je choisis la règle à partir des données sauvegardées ou des règles de base
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
					# Je réapplique flatten sur le choix pour gérer les tags imbriqués
					resolved = flatten(choice)
			else:
				# Si c'est une simple chaîne je la passe à flatten pour gérer les tags éventuels
				resolved = flatten(str(selected_rule))

			# J'applique chaque modificateur dans l'ordre sur le texte résolu
			for m in modifiers:
				if _modifier_lookup.has(m):
					var obj = _modifier_lookup[m][0]
					var fn = _modifier_lookup[m][1]
					resolved = obj.call(fn, resolved)

			# J'ajoute le texte final au résultat
			result += resolved

			# Je continue la recherche après la fin du tag traité
			pos = end

		# J'ajoute le texte restant après le dernier tag
		result += rule.substr(pos)
		return result
	
	
	func _resolve_save_symbols(rule: String) -> String:
		# Je cherche toutes les actions de type [nom:valeur] ou [nom]
		var matches := _save_symbol_regex.search_all(rule)
		if matches.is_empty():
			return rule

		for m in matches:
			var full := m.get_string(0) # Exemple "[hero:#name#]"
			# Je retire les crochets pour ne garder que "hero:#name#"
			var content := full.substr(1, full.length() - 2)
			var parts := content.split(":")

			if parts.size() == 2:
				# Cas [nom:valeur]
				var name := parts[0].strip_edges()
				var rhs := parts[1].strip_edges()

				if rhs.find(",") != -1:
					# Si la valeur contient des virgules je considère que c'est une liste de règles
					var arr := []
					for p in rhs.split(","):
						arr.append(p.strip_edges())
					_save_data[name] = arr
				else:
					# Sinon je résous la valeur immédiatement et je la stocke comme texte
					_save_data[name] = flatten(rhs)
			else:
				# Cas [nom] que je résous comme #nom#
				var name2 := content.strip_edges()
				_save_data[name2] = flatten("#" + name2 + "#")

		# Je renvoie la règle nettoyée sans les actions de sauvegarde
		return _save_symbol_regex.sub(rule, "", true)

	
	
	func _get_modifiers(symbol: String) -> Array:
		# A partir d'un tag "#hero.capitalize.a#" je récupère ["capitalize", "a"]
		var modifiers := symbol.replace("#", "").split(".")
		if modifiers.size() > 0:
			# Je retire le premier élément qui est le nom du symbole
			modifiers.remove_at(0)
		return modifiers
	
	
	func _apply_modifiers(resolved: String, modifiers: Array) -> String:
		# Fonction utilitaire si je veux appliquer une liste de modificateurs à part
		for m in modifiers:
			if _modifier_lookup.has(m):
				var obj = _modifier_lookup[m][0]
				var func_name = _modifier_lookup[m][1]
				resolved = obj.call(func_name, resolved)
		return resolved
