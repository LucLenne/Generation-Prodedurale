extends Node2D
@onready var donneur_de_quête: PNJ = $DonneurDeQuête
@onready var monstre: PNJ = $Monstre


func _ready() -> void:
	var dialogueSystem : DialogueSystem = donneur_de_quête.get_node("DialogueSystem")
	dialogueSystem.generate_new_quest()
	monstre.QuestGiverDialogueSystem = dialogueSystem
	pass # Replace with function body.
