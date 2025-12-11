class_name QuestManager extends Node

const TileConfigScript = preload("res://scripts/generation/TileConfig.gd")


@export_group("Génération")
@export var _numberQuest : int = 5
@export var list_collectibles : Array[CollectibleBase]
@export var list_biomes : Array[String]
@export var list_character_to_kill : Array[PackedScene]
@export var list_pnj : Array[PackedScene]
var _pnj_in_quest : Array[PNJ]


@export_group("Talk")
@export var max_dist_pnj : float = 50
@export var entity_scale : Vector2 = Vector2.ONE


var _typeQuest : Array[Script] = [CollectQuest,DeliveryQuest,ExploreQuest,TalkQuest]
var _activeQuest : Array[QuestBase]
var _inactiveQuest : Array[QuestBase]
var _successQuest : Array[QuestBase]
var _failQuest : Array[QuestBase]

func spawn_entity_in_world(scene: PackedScene, min_dist: float = 100, max_dist: float = 300, specific_pos: Vector2 = Vector2.INF) -> Node2D:
	if scene == null: return null
	
	var instance = scene.instantiate() as Node2D
	if instance == null: return null
	
	instance.scale = entity_scale
	
	if specific_pos != Vector2.INF:
		instance.global_position = specific_pos
	else:
		var center = Vector2.ZERO
		if Player.Instance:
			center = Player.Instance.global_position
			
		var offset = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(min_dist, max_dist)
		instance.global_position = center + offset

	if Player.Instance and Player.Instance.get_parent():
		var parent = Player.Instance.get_parent()
		parent.call_deferred("add_child", instance)
		if parent.has_method("register_generated_object"):
			parent.call_deferred("register_generated_object", instance)
	else:
		get_tree().root.call_deferred("add_child", instance)
		
	return instance

func GetPNJ(world_gen: Node2D = null) -> PNJ:
	if list_pnj.is_empty():
		print("ManagerQuest: No PNJ scenes in list!")
		return null
		
	var scene = list_pnj.pick_random()
	var spawn_pos = Vector2.INF
	
	if world_gen and world_gen.has_method("get_random_building_door"):
		spawn_pos = world_gen.get_random_building_door()
	elif Player.Instance and Player.Instance.get_parent().has_method("get_random_building_door"):
		spawn_pos = Player.Instance.get_parent().get_random_building_door()
		
	var pnj = spawn_entity_in_world(scene, 50, max_dist_pnj, spawn_pos) as PNJ
	
	if pnj:
		_pnj_in_quest.append(pnj)
		return pnj
		
	return null

@export var quest_scenes : Array[PackedScene]

var _quest_scenes_by_type: Dictionary = {}

func _ready() -> void:
	# Populate quest scenes by type for easy lookup
	print("ManagerQuest: _ready called. Total quest_scenes assigned: ", quest_scenes.size())
	for scene in quest_scenes:
		var temp_instance = scene.instantiate()
		if temp_instance is QuestBase:
			var type = temp_instance.type
			if not _quest_scenes_by_type.has(type):
				_quest_scenes_by_type[type] = []
			_quest_scenes_by_type[type].append(scene)
			print("ManagerQuest: Registered quest scene for type ", type)
		temp_instance.free()
		
func generate_quests_for_world(npcs: Array, world_gen: WorldGenerator) -> void:
	print("ManagerQuest: Generating quests for world...")
	var valid_pnjs: Array[PNJ] = []
	for npc in npcs:
		if npc is PNJ:
			if npc.QuestGiverDialogueSystem != null:
				valid_pnjs.append(npc)
			else:
				print("ManagerQuest Debug: NPC %s is PNJ but has NO DialogueSystem" % npc.name)
			
	if valid_pnjs.is_empty():
		print("ManagerQuest: No valid PNJs found for quest generation. (Total NPCs checked: %d)" % npcs.size())
		return
		
	if _quest_scenes_by_type.is_empty() and quest_scenes.is_empty():
		printerr("ManagerQuest ERROR: No quest scenes loaded! Check inspector assignments on ManagerQuest.")
		return
		
	valid_pnjs.shuffle()
	var selected_pnjs = valid_pnjs.slice(0, min(_numberQuest, valid_pnjs.size()))
	
	print("ManagerQuest: Selected %d PNJs for quests." % selected_pnjs.size())
	
	for pnj in selected_pnjs:
		# Trigger dialogue generation to define the quest
		pnj.QuestGiverDialogueSystem.generate_new_quest()
		
		# Spawn the physical quest object based on the new data
		spawn_quest_for_pnj(pnj, world_gen)

func map_dialogue_type_to_quest_type(dialogue_type_enum) -> QuestBase.TYPE:
	# DialogueSystem.QuestType {TALK, KILL, DELIVERY, EXPLORE, COLLECT}
	# QuestBase.TYPE {COLLECT, KILL, EXPLORE, DELIVERY, TALK, NONE}
	
	# Assuming enums might not match int values exactly, we map by string name logic or strict switch if we knew values.
	# Let's rely on string representation if possible, or manual mapping.
	# Since DialogueSystem script is available, we can try to match logic.
	
	# DialogueSystem.QuestType keys:
	# TALK=0, KILL=1, DELIVERY=2, EXPLORE=3, COLLECT=4 (Based on view)
	
	match dialogue_type_enum:
		0: return QuestBase.TYPE.TALK
		1: return QuestBase.TYPE.KILL
		2: return QuestBase.TYPE.DELIVERY
		3: return QuestBase.TYPE.EXPLORE
		4: return QuestBase.TYPE.COLLECT
	
	return QuestBase.TYPE.NONE

func spawn_quest_for_pnj(pnj: PNJ, world_gen: WorldGenerator) -> void:
	if quest_scenes.is_empty():
		print("ManagerQuest: No quest scenes assigned.")
		return
	if pnj == null: return
	
	# Check if PNJ has a Dialogue System attached
	if pnj.QuestGiverDialogueSystem == null:
		print("ManagerQuest: PNJ %s has no DialogueSystem, skipping quest spawn." % pnj.name)
		return
	
	# Determine spawn parameters from Dialogue System
	var dialogue_data = pnj.QuestGiverDialogueSystem.current_quest_data
	var directory = "EST" # Default fallback
	var distance = 200.0 # Distance in pixels for quest spawn
	var quest_type_enum = 0 # Default TALK
	
	if dialogue_data.has("target_direction") and dialogue_data["target_direction"] != "":
		directory = dialogue_data["target_direction"].to_upper()
	
	if dialogue_data.has("quest_type"):
		quest_type_enum = dialogue_data["quest_type"]
		
	var target_quest_type = map_dialogue_type_to_quest_type(quest_type_enum)

	if directory == "Nulle part" or directory == "" or directory == "EST":
		pass
		
	if directory == "Nulle part" or directory == "":
		var fallback_dirs = ["NORD", "SUD", "EST", "OUEST"]
		directory = fallback_dirs.pick_random()
		print("ManagerQuest: Direction was invalid/empty, picked random: ", directory)

	var scene = null
	if _quest_scenes_by_type.has(target_quest_type) and not _quest_scenes_by_type[target_quest_type].is_empty():
		scene = _quest_scenes_by_type[target_quest_type].pick_random()
	else:
		print("ManagerQuest: No scene found for type ", target_quest_type, ". Picking random fallback.")
		scene = quest_scenes.pick_random()
		
	if scene == null: return
	
	# Analyse la scène pour obtenir sa taille et ses cellules
	var temp = scene.instantiate()
	var quest_size = Vector2i(3, 3)
	var offset = Vector2i.ZERO
	var actual_cells: Array[Vector2i] = []
	
	var tile_layer_node = temp.get_node_or_null("TileMapLayer")
	if not tile_layer_node:
		for child in temp.get_children():
			if child is TileMapLayer or child is TileMap:
				tile_layer_node = child
				break
	
	if tile_layer_node:
		var rect = tile_layer_node.get_used_rect()
		if rect.has_area():
			quest_size = rect.size
			offset = rect.position
			# Récupère TOUTES les cellules utilisées
			for cell in tile_layer_node.get_used_cells():
				actual_cells.append(cell)
	
	# Si pas de cellules trouvées, génère un rectangle basé sur la taille
	if actual_cells.is_empty():
		for x in range(quest_size.x):
			for y in range(quest_size.y):
				actual_cells.append(Vector2i(x, y) + offset)
	
	temp.free()

	# Find Position avec la vraie taille
	var valid_pos = world_gen.get_position_in_direction(pnj.global_position, directory, distance, quest_size)
	
	if valid_pos == Vector2.INF:
		print("ManagerQuest: Failed to find spot for PNJ quest.")
		return
		
	# Instantiate
	var instance = scene.instantiate()
	instance.position = valid_pos - (Vector2(offset) * TileConfigScript.TILE_SIZE)
	
	world_gen.add_child(instance)
	if world_gen.has_method("register_generated_object"):
		world_gen.register_generated_object(instance)
	
	# Enregistre les cellules occupées pour éviter les superpositions
	if world_gen.has_method("register_quest_cells"):
		world_gen.register_quest_cells(instance.position, actual_cells, offset)
		
	# Assign to PNJ
	if instance is QuestBase:
		_inactiveQuest.append(instance)
		instance.setup(world_gen)
		
		instance.quest_data = dialogue_data
		
		if instance.has_method("force_spawn_target"):
			instance.force_spawn_target(directory, distance, pnj.QuestGiverDialogueSystem)
			
		# Update Title (safely after targets exist)
		if instance.has_method("_update_title"):
			instance._update_title()
		elif instance.has_method("_init_name"): # Support old KillQuest style
			instance._init_name()
		
		pnj.assign_quest(instance)
		print("ManagerQuest: Spawned quest for PNJ at ", instance.position, " with ", actual_cells.size(), " cells reserved")

func DeleteQuestUI(id : int):
	QuestBookUi.delete_quest(id)

func ActivateQuest(pnj : PNJ):
	var quest = pnj.current_quest
	if quest._state == QuestBase.STATE.INACTIVE:
		_inactiveQuest.erase(quest)
		_activeQuest.append(quest)
		QuestBookUi._create_quest(quest.title,quest.id)
		return
	print("quest not inactive")

func _process(_delta: float) -> void:
	for quest in _activeQuest:
		if(quest._state == QuestBase.STATE.SUCCESS):
			DeleteQuestUI(quest.id)
			_successQuest.append(quest)
			_activeQuest.erase(quest)
			_failQuest.append(quest)
			_activeQuest.erase(quest)

func GetQuest(type : QuestBase.TYPE) -> QuestBase:
	for quest in _inactiveQuest:
		if(quest.type == type):
			return quest
	print("no quest " + str(type) + " exist.")
	return


func get_spawn_position_from_direction(direction: String, distance: float, origin_pos: Vector2) -> Vector2:
	var dir_vec = Vector2.RIGHT # Default
	match direction.to_upper():
		"NORD": dir_vec = Vector2.UP
		"SUD": dir_vec = Vector2.DOWN
		"EST": dir_vec = Vector2.RIGHT
		"OUEST": dir_vec = Vector2.LEFT
		_:
			printerr("QuestManager: Unknown direction '%s', defaulting to EST" % direction)
	
	return origin_pos + (dir_vec * distance)
