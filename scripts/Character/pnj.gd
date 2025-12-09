class_name PNJ extends CharacterBase


@export var interact_prompt: String = "Appuyer sur [E] pour parler"

var current_quest: QuestBase
var has_active_quest: bool = false 

func _update_state(delta : float):
	pass

@onready var quest_indicator_label: Label = $QuestIndicatorLabel # Assurez-vous que le chemin du Node est correct, ici j'utilise @onready

func _ready():
	if not quest_indicator_label:
		pass


func assign_quest(new_quest: QuestBase):
	if new_quest:
		current_quest = new_quest
		has_active_quest = true
		print("PNJ: Quête assignée : ", new_quest.name)
	else:
		print("PNJ: Tentative d'assigner une quête nulle.")

func _physics_process(delta: float) -> void:
	pass

func _process(_delta: float) -> void:
	if quest_indicator_label:
		if (has_active_quest && current_quest.state == QuestBase.STATE.INACTIVE):
			quest_indicator_label.text = "?"
		elif (has_active_quest && current_quest.state == QuestBase.STATE.SUCCESS):
			quest_indicator_label.text = "!"
		else:
			quest_indicator_label.text = ""
