class_name QuestManager extends Node


@export_group("Génération")
@export var _numberQuest : int = 2
@export var list_collectibles : Array[CollectibleBase]
@export var list_biomes : Array[String]
@export var _type_ennemies : Array[PackedScene]

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
	
	
var _world_gen_ref: Node2D = null

func generate_quests_for_world(npcs_list: Array, world_gen: Node2D) -> void:
	print("Generating quests for procedural world...")
	_world_gen_ref = world_gen
	
	# Reset state
	_activeQuest.clear()
	_inactiveQuest.clear()
	_successQuest.clear()
	_failQuest.clear()
	_pnj.clear()
	_pnj_in_quest.clear()
	
	# Register NPCs
	for npc in npcs_list:
		if npc is PNJ:
			_pnj.append(npc)
			
	print("Registered %d NPCs for quests." % _pnj.size())
	
	_generate_quests()
	print("Generated %d quests." % _inactiveQuest.size())


func SpawnPNJ(dir : DialogueSystem.Directions, Name : String, questGiver : PNJ) -> PNJ:
	var scene_pnj : PackedScene = _type_ennemies.pick_random() 
	var pnj = scene_pnj.instantiate()
	
	# Utilise le parent du questGiver (devrait être WorldGenerator ou StructurePlacer root)
	if questGiver.get_parent():
		questGiver.get_parent().add_child(pnj)
	else:
		get_tree().root.add_child(pnj)
		
	if pnj is PNJ:
		var target_pos = Vector2.ZERO
		
		# Utilise WorldGenerator si disponible pour trouver une position valide
		if _world_gen_ref and _world_gen_ref.has_method("get_position_in_direction"):
			var dir_str = "SUD" # Default
			match dir:
				DialogueSystem.Directions.NORD: dir_str = "NORD"
				DialogueSystem.Directions.EST: dir_str = "EST"
				DialogueSystem.Directions.SUD: dir_str = "SUD"
				DialogueSystem.Directions.OUEST: dir_str = "OUEST"
			
			# Distance arbitraire (ex: 200 pixels)
			target_pos = _world_gen_ref.get_position_in_direction(questGiver.position, dir_str, 200.0)
		else:
			# Fallback sur la méthode interne du PNJ
			target_pos = questGiver._get_direction_position(dir)
			
		pnj.position = target_pos
		pnj.Name = Name
		
		# Enregistre le PNJ généré dans le WorldGenerator si possible
		if _world_gen_ref and _world_gen_ref.has_method("register_generated_object"):
			_world_gen_ref.register_generated_object(pnj)
			
		# Réserve la zone si possible
		if _world_gen_ref and _world_gen_ref.has_method("register_reserved_area"):
			_world_gen_ref.register_reserved_area(pnj.position, 2)
			
		return pnj
	return null

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

#func _pos_dir(dir : DialogueSystem.Directions) -> Vector2:
	#match dir:
		#DialogueSystem.Directions.NORD:
			#var north =  _directions[0]
			#if north is Node2D:
				#return north.position
		#DialogueSystem.Directions.EST:
			#var est =  _directions[1]
			#if est is Node2D:
				#return est.position
		#DialogueSystem.Directions.SUD:
			#var sud =  _directions[2]
			#if sud is Node2D:
				#return sud.position
		#DialogueSystem.Directions.OUEST:
			#var ouest =  _directions[3]
			#if ouest is Node2D:
				#return ouest.position
	#return Vector2.ZERO
