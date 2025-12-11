class_name PNJ extends CharacterBase

@export var QuestGiverDialogueSystem : DialogueSystem

@onready var dialogue_system: DialogueSystem = $DialogueSystem




func _update_state(_delta : float):
	pass


func create_dialogue():
	dialogue_system.generate_new_quest()
