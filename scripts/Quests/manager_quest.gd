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
var _successQuest : Array[QuestBase]
var _failQuest : Array[QuestBase]

func GeneratesQuest()-> void:
	for i in range(_numberQuest):
		var quest = _typeQuest.pick_random()
		var new_quest = quest.new()
		_listQuest.append(new_quest)


func _process(_delta: float) -> void:
	for quest in _listQuest:
		if(quest._state == QuestBase.STATE.SUCCESS):
			_successQuest.append(quest)
			_listQuest.erase(quest)
		if(quest._state == QuestBase.STATE.FAIL):
			_failQuest.append(quest)
			_listQuest.erase(quest)
