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
	var distance = 100.0 # Default fixed distance for now
	
	if dialogue_data.has("target_direction"):
		directory = dialogue_data["target_direction"]
		print("ManagerQuest: Using direction '%s' from DialogueSystem" % directory)
	else:
		print("ManagerQuest: No target_direction in DialogueSystem, using default EST")
		
	# Fallback if direction comes back as "Nulle part" or empty from random gen
	if directory == "Nulle part" or directory == "":
		var fallback_dirs = ["NORD", "SUD", "EST", "OUEST"]
		directory = fallback_dirs.pick_random()
		print("ManagerQuest: Direction was invalid, picked random: ", directory)

	var scene = quest_scenes.pick_random()
	if scene == null: return
	
	# Determine Quest Size (for safe spawning)
	var temp = scene.instantiate()
	var quest_size = Vector2i(3,3)
	var offset = Vector2i.ZERO # To center it or handle tilemap offset
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
	temp.free()

	# Find Position
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
		
	# Assign to PNJ
	if instance is QuestBase:
		_inactiveQuest.append(instance)
		instance.setup(world_gen)
		pnj.assign_quest(instance)
		print("ManagerQuest: Spawned quest for PNJ at ", instance.position)

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
