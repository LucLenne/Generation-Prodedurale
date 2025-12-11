extends Node2D
@onready var donneur_de_quête: PNJ = $DonneurDeQuête
@onready var monstre: PNJ = $Monstre

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var dialogueSystem : DialogueSystem = donneur_de_quête.get_node("DialogueSystem")
	dialogueSystem.generate_new_quest()
	dialogueSystem.targetInterractable = monstre.get_node("Interractable")
	monstre.QuestGiverDialogueSystem = dialogueSystem
	
