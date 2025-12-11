class_name NPC extends CharacterBody2D

@export var dialogue_text : String = "Hello traveler!"
@onready var _dialogue_system = $DialogueSystem

func interact():
	print("NPC says: " + dialogue_text)
	# TODO: Connect to a UI system for displaying dialogue

func create_dialogue():
	if _dialogue_system is DialogueSystem:
		_dialogue_system.generate_new_quest()
