class_name ManagerQuest extends Node
static var Instance : ManagerQuest


@export_group("Génération")
@export var _numberQuest : int = 5
@export var list_collectibles : Array[CollectibleBase]
@export var list_biomes : Array[String]
@export var list_character_to_kill : Array[CharacterBase]
@export var list_pnj : Array[PNJ]


var _typeQuest : Array[Script] = [CollectQuest,DeliveryQuest,ExploreQuest,KillQuest,TalkQuest]
var _listQuest : Array[QuestBase]


func GeneratesQuest()-> void:
	for i in range(_numberQuest):
		var quest = _typeQuest.pick_random()
		var new_quest = quest.new()
		_listQuest.append(new_quest)
