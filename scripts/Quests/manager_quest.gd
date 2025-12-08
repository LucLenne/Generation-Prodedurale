class_name ManagerQuest extends Node
static var Instance : ManagerQuest


@export_group("Génération")
@export var _numberQuest : int = 5
@export var list_collectibles : Array[CollectibleBase]
@export var list_biomes : Array[String]
@export var list_character_to_kill : Array[CharacterBase]
@export var list_pnj : Array[PNJ]
var _pnj_in_quest : Array[PNJ]

@export_group("Talk")
@export var max_dist_pnj : float = 1000


var _typeQuest : Array[Script] = [CollectQuest,DeliveryQuest,ExploreQuest,KillQuest,TalkQuest]
var _activeQuest : Array[QuestBase]
var _inactiveQuest : Array[QuestBase]
var _successQuest : Array[QuestBase]
var _failQuest : Array[QuestBase]

func GetPNJ() -> PNJ:
	for pnj in list_pnj:
		if(Player.Instance.position.distance_to(pnj.position) < max_dist_pnj):
			_pnj_in_quest.append(pnj)
			list_pnj.erase(pnj)
			return pnj
	print("No pnj available at this distance")
	return

func GeneratesQuest()-> void:
	for i in range(_numberQuest):
		var quest = _typeQuest.pick_random()
		var new_quest = quest.new()
		if new_quest is QuestBase:
			new_quest.id = i
		_inactiveQuest.append(new_quest)

func DeleteQuestUI(id : int):
	QuestBookUI.Instance.delete_quest(id)

func ActivateQuest(id : int):
	for quest in _inactiveQuest:
		if quest.id == id:
			_inactiveQuest.erase(quest)
			_activeQuest.append(quest)
			QuestBookUI.Instance._create_quest(str(quest.type),quest.id)
			return
	print("quest not inactive")

func _process(_delta: float) -> void:
	for quest in _activeQuest:
		if(quest._state == QuestBase.STATE.SUCCESS):
			DeleteQuestUI(quest.id)
			_successQuest.append(quest)
			_activeQuest.erase(quest)
		if(quest._state == QuestBase.STATE.FAIL):
			DeleteQuestUI(quest.id)
			_failQuest.append(quest)
			_activeQuest.erase(quest)
