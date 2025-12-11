class_name QuestManager extends Node


@export_group("Génération")
@export var _numberQuest : int = 2
@export var list_collectibles : Array[CollectibleBase]
@export var list_biomes : Array[String]
@export var _type_ennemies : Array[PackedScene]
@export var _directions : Array[Node2D]

var _typeQuest : Array[Script] = [TalkQuest]
var _activeQuest : Array[QuestBase]
var _inactiveQuest : Array[QuestBase]
var _successQuest : Array[QuestBase]
var _failQuest : Array[QuestBase]
var _pnj : Array[PNJ]
var _pnj_in_quest : Array[PNJ]

func _ready() -> void:
	await get_tree().process_frame
	_init_list_npc()
	_generate_quests()

func _process(delta: float) -> void:
	for quest in _activeQuest:
		quest._process(delta)

func ActiveQuest(quest : QuestBase):
	if _inactiveQuest.has(quest):
		_inactiveQuest.erase(quest)
		_activeQuest.append(quest)
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
	
	
func GetPNJ() -> PNJ:
	#if _pnj.is_empty():
		#push_warning("No more PNJ available for quest generation")
		#return
		
	var pnj = _pnj.pick_random()
	_pnj.erase(pnj)
	_pnj_in_quest.append(pnj)
	return pnj
	
	
func SpawnPNJ(dir : DialogueSystem.Directions, Name : String) -> PNJ:
	var scene_pnj : PackedScene = _type_ennemies.pick_random() 
	var pnj = scene_pnj.instantiate()
	if pnj is PNJ:
		pnj.position = _pos_dir(dir)
		pnj.Name = Name
		return pnj
	return 

func _generate_quests() -> void :
	for i in range(_numberQuest):
		var quest_script = _typeQuest.pick_random()
		var quest = quest_script.new()
		quest.id = i
		quest.init()
		_inactiveQuest.append(quest)
		
		
func _create_quest_ui(quest : QuestBase):
	QuestBookUi.create_quest(quest.title,quest.id)
	
func _delete_quest_UI(id : int):
	QuestBookUi.delete_quest(id)
	
func _init_list_npc():
	var current_scene = get_tree().current_scene
	for child in current_scene.get_children():
		if child is PNJ:
			_pnj.append(child)

func _pos_dir(dir : DialogueSystem.Directions) -> Vector2:
	match dir:
		DialogueSystem.Directions.NORD:
			var north =  _directions[0]
			if north is Node2D:
				return north.position
		DialogueSystem.Directions.EST:
			var est =  _directions[1]
			if est is Node2D:
				return est.position
		DialogueSystem.Directions.SUD:
			var sud =  _directions[2]
			if sud is Node2D:
				return sud.position
		DialogueSystem.Directions.OUEST:
			var ouest =  _directions[3]
			if ouest is Node2D:
				return ouest.position
	return Vector2.ZERO
