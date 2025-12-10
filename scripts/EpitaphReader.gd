extends Node2D


@onready var popup_position: Node2D = $PopupPosition

@export var EpitaphJson : JSON
var EpitaphText : String

func _ready():
	var rulesFR = EpitaphJson.data
	var grammarFR = TraceryFR.GrammarFR.new(rulesFR)

	grammarFR.add_modifiers(TraceryFR.UniversalModifiersFR.get_modifiers())
	
	print("--- Tests Tracery FR ---")
	
	EpitaphText = grammarFR.flatten("#origin#")
	print("Phrase 1 : " + EpitaphText)
	


func _on_interractable_on_player_interract() -> void:
	var lines = EpitaphText.split("&&")
	PopupManager.start_dialog(popup_position.global_position, lines)
	
	
