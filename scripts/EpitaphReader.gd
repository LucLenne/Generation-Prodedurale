extends Node


@export var EpitaphJson : JSON
@export var epitaphSystem : EpitaphSystem
var EpitaphText : String

func _ready():
	var rulesFR = EpitaphJson.data
	var grammarFR = TraceryFR.GrammarFR.new(rulesFR)

	grammarFR.add_modifiers(TraceryFR.UniversalModifiersFR.get_modifiers())
	
	print("--- Tests Tracery FR ---")
	
	EpitaphText = grammarFR.flatten("#origin#")
	print("Phrase 1 : " + EpitaphText)
	
	

	


func _on_interractable_on_player_interract() -> void:
	if !epitaphSystem :
		push_error("EpitaphSystem is null")
		return
	epitaphSystem.show_epitaph_text(EpitaphText)
	
