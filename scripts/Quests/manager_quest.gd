class_name QuestManager extends Node


@export_group("Génération")
@export var _numberQuest : int = 5
@export var list_collectibles : Array[CollectibleBase]
@export var list_biomes : Array[String]

var _typeQuest : Array[Script] = [CollectQuest,DeliveryQuest,ExploreQuest,KillQuest,TalkQuest]
var _activeQuest : Array[QuestBase]
var _inactiveQuest : Array[QuestBase]
var _successQuest : Array[QuestBase]
var _failQuest : Array[QuestBase]
var _pnj : Array[NPC]
var _pnj_in_quest : Array[NPC]

func _ready() -> void:
	_generate_quests()
	_init_list_npc()
func _process(delta: float) -> void:
	for quest in _activeQuest:
		quest._process(delta)

func ActiveQuest(quest : QuestBase):
	if _inactiveQuest.has(quest):
		_inactiveQuest.erase(quest)
		_activeQuest.append(quest)
		quest.init()
		_create_quest_ui(quest)
func SuccessQuest(quest : QuestBase):
	if _activeQuest.has(quest):
		_activeQuest.erase(quest)
		_successQuest.append(quest)
		_delete_quest_UI(quest.id)
func FailQuest(quest : QuestBase):
	if _activeQuest.has(quest):
		_activeQuest.erase(quest)
		_failQuest.append(quest)
		_delete_quest_UI(quest.id)
func GetQuest(type : QuestBase.TYPE) -> QuestBase:
	for quest in _inactiveQuest:
		if(quest.type == type):
			return quest
	print("no quest " + str(type) + " exist.")
	return
func GetPNJ() -> NPC:
	var pnj = _pnj.pick_random()
	_pnj.erase(pnj)
	_pnj_in_quest.append(pnj)
	return pnj

func _generate_quests() -> void :
	for i in range(_numberQuest):
		var quest_script = _typeQuest.pick_random()
		var quest = quest_script.new()
		quest.id = i
		_inactiveQuest.append(quest)
func _create_quest_ui(quest : QuestBase):
	QuestBookUi.create_quest(quest.title,quest.id)
func _delete_quest_UI(id : int):
	QuestBookUi.delete_quest(id)
func _init_list_npc():
	var current_scene = get_tree().current_scene
	for child in current_scene.get_children():
		if child is NPC:
			_pnj.append(child)
