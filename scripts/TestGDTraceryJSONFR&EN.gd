extends Node


@export var jsonEN : JSON
@export var jsonFR : JSON


func _ready():
	var rules = jsonEN.data
	var grammar = TraceryEN.GrammarEN.new(rules)
	
	var rulesFR = jsonFR.data
	var grammarFR = TraceryFR.GrammarFR.new(rulesFR)
	
	
	grammar.add_modifiers(TraceryEN.UniversalModifiersEN.get_modifiers())
	
	print("--- Tests Tracery EN ---")
	
	print("Phrase 1 : " + grammar.flatten("#origin#"))
	
	grammarFR.add_modifiers(TraceryFR.UniversalModifiersFR.get_modifiers())
	
	print("--- Tests Tracery FR ---")
		
	print("Phrase 1 : " + grammarFR.flatten("#origin#"))
	
