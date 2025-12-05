class_name ManagerQuest extends Node
static var Instance : ManagerQuest


@export_group("Génération")
@export var _numberQuest : int = 5
@export var list_collectibles : Array[CollectibleBase]
@export var list_biomes : Array[String]
@export var list_character_to_kill : Array[PackedScene]
@export var list_pnj : Array[PackedScene]
var _pnj_in_quest : Array[PNJ]

func _enter_tree() -> void:
	if Instance == null:
		Instance = self
	else:
		queue_free()

@export_group("Talk")
@export var max_dist_pnj : float = 50
@export var entity_scale : Vector2 = Vector2.ONE


var _typeQuest : Array[Script] = [CollectQuest,DeliveryQuest,ExploreQuest,KillQuest,TalkQuest]
var _listQuest : Array[QuestBase]
var _successQuest : Array[QuestBase]
var _failQuest : Array[QuestBase]

# Helper to spawn entity from scene
# If specific_pos is provided (not INF), spawns there. Otherwise spawns around player.
func spawn_entity_in_world(scene: PackedScene, min_dist: float = 100, max_dist: float = 300, specific_pos: Vector2 = Vector2.INF) -> Node2D:
	if scene == null: return null
	
	var instance = scene.instantiate() as Node2D
	if instance == null: return null
	
	instance.scale = entity_scale
	
	if specific_pos != Vector2.INF:
		instance.global_position = specific_pos
	else:
		# Spawn around player if possible, otherwise 0,0
		var center = Vector2.ZERO
		if Player.Instance:
			center = Player.Instance.global_position
			
		var offset = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(min_dist, max_dist)
		instance.global_position = center + offset
	
	# Add to main scene (root of generator or window)
	# Assuming ManagerQuest is Autoload or in Main scene. 
	# Safest is to add to the parent of Player, or GetTree.current_scene
	if Player.Instance and Player.Instance.get_parent():
		Player.Instance.get_parent().call_deferred("add_child", instance)
	else:
		get_tree().root.call_deferred("add_child", instance)
		
	return instance

func GetPNJ(world_gen: Node2D = null) -> PNJ:
	if list_pnj.is_empty():
		print("ManagerQuest: No PNJ scenes in list!")
		return null
		
	var scene = list_pnj.pick_random()
	
	# Try to spawn at a building door (village) if WorldGenerator is available
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

func spawn_quests_in_world(world_gen: WorldGenerator) -> void:
	if quest_scenes.is_empty():
		print("ManagerQuest: No quest scenes assigned.")
		return
		
	print("ManagerQuest: Spawning %d quests using Zones..." % _numberQuest)
	print("Debug - list_character_to_kill size: ", list_character_to_kill.size())
	print("Debug - list_pnj size: ", list_pnj.size())
	
	for i in range(_numberQuest):
		var scene = quest_scenes.pick_random()
		if scene == null: continue
		
		# Prefer spawning quest givers/items near buildings (Villages)
		var spawn_pos = Vector2.ZERO
		if world_gen.has_method("get_random_building_door"):
			spawn_pos = world_gen.get_random_building_door()
		else:
			# Fallback to random zone center if method missing
			var zone = world_gen.get_random_zone()
			if zone: spawn_pos = Vector2(zone.center) * 32 # TILE_SIZE hardcoded fallback
			
		var instance = scene.instantiate()
		instance.position = spawn_pos
		instance.scale = entity_scale
		world_gen.add_child(instance)
		
		# Register space as occupied to prevent buildings from spawning on top
		if world_gen.has_method("register_reserved_area"):
			world_gen.register_reserved_area(spawn_pos, 2) # Reserve 2 tiles radius (5x5 area)
			
		print("ManagerQuest: Spawned quest at ", spawn_pos)
		
		# Also register in internal list if it's a QuestBase
		if instance is QuestBase:
			_listQuest.append(instance)
			instance.setup(world_gen)



func _process(_delta: float) -> void:
	for quest in _listQuest:
		if(quest._state == QuestBase.STATE.SUCCESS):
			_successQuest.append(quest)
			_listQuest.erase(quest)
		if(quest._state == QuestBase.STATE.FAIL):
			_failQuest.append(quest)
			_listQuest.erase(quest)
