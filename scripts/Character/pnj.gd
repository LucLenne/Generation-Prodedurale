class_name PNJ extends CharacterBase

@export var QuestGiverDialogueSystem : DialogueSystem

@onready var dialogue_system: DialogueSystem = $DialogueSystem
var current_quest : QuestBase


@onready var north: Marker2D = $Direction/North
@onready var east: Marker2D = $Direction/East
@onready var south: Marker2D = $Direction/South
@onready var west: Marker2D = $Direction/West

func _get_direction_position(direction : DialogueSystem.Directions) -> Vector2 :
	match direction:
		DialogueSystem.Directions.NORD: return north.position
		DialogueSystem.Directions.EST : return east.position
		DialogueSystem.Directions.SUD : return south.position
		DialogueSystem.Directions.OUEST : return west.position
	push_warning("No directions match with " + str(direction) + "Fallback on NORD")
	return north.position

func _update_state(_delta : float):
	pass


func create_dialogue():
	dialogue_system.generate_new_quest()
