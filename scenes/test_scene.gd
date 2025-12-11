extends Node2D
@onready var donneur_de_quête: PNJ = $DonneurDeQuête
@onready var monstre: PNJ = $Monstre

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var dialogueSystem : DialogueSystem = donneur_de_quête.get_node("DialogueSystem")
	dialogueSystem.generate_new_quest()
	monstre.QuestGiverDialogueSystem = dialogueSystem
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
