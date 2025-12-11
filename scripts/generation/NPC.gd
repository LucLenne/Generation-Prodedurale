class_name NPC extends CharacterBody2D

@export var dialogue_text : String = "Hello traveler!"

func interact():
	print("NPC says: " + dialogue_text)
	# TODO: Connect to a UI system for displaying dialogue
