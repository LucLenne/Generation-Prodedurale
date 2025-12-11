class_name PNJ extends CharacterBase

@export var QuestGiverDialogueSystem : DialogueSystem

var current_quest: QuestBase
var has_active_quest: bool = false 
@onready var dialogue_system : DialogueSystem = $DialogueSystem
@onready var quest_indicator_label: Label = $QuestIndicatorLabel # Assurez-vous que le chemin du Node est correct, ici j'utilise @onready

func _update_state(_delta : float):
	pass
func interact():
	pass
	
func _ready():
	if not quest_indicator_label:
		pass

func create_dialogue():
	dialogue_system.generate_new_quest()

func active_quest():
	QuestGiverDialogueSystem.active
