class_name KillQuest extends QuestBase

var _target : CharacterBase

func _init() -> void :
	_type = TYPE.KILL

func setup(world_gen: Node2D) -> void:
	var target_scene = null
	if not ManagerQuest.Instance.list_character_to_kill.is_empty():
		target_scene = ManagerQuest.Instance.list_character_to_kill.pick_random()
	else:
		print("KillQuest Debug: list_character_to_kill is EMPTY!")
	
	if target_scene == null:
		print("KillQuest Debug: picked target_scene is NULL")
	
	var spawn_pos = Vector2.INF
	if world_gen.has_method("get_random_zone_position"):
		spawn_pos = world_gen.get_random_zone_position()
		
	var spawned_obj = ManagerQuest.Instance.spawn_entity_in_world(target_scene, 200, 500, spawn_pos)
	_target = spawned_obj as CharacterBase
	
	if spawned_obj != null and _target == null:
		print("KillQuest Debug: Spawned object is NOT a CharacterBase. It is: ", spawned_obj.get_class())
	
	if _target == null:
		printerr("KillQuest: Failed to spawn target! Check list_character_to_kill in ManagerQuest.")

func _process(_delta: float) -> void:
	if _target == null: return
	
	if(_target.is_dead):
		_valid_quest()
