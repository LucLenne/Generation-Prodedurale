class_name KillQuest extends QuestBase

var _target : CharacterBase

func _init() -> void :
	type = TYPE.KILL

func setup(world_gen: Node2D) -> void:
	# No longer spawning automatically
	pass

func try_spawn_target(direction: String, distance: float, dialogue_ref: Object) -> bool:
	if QuestManager.Instance.list_character_to_kill.is_empty():
		printerr("KillQuest: No enemies to spawn!")
		return false
		
	var target_scene = QuestManager.Instance.list_character_to_kill.pick_random()
	
	var origin_pos = Vector2.ZERO
	if dialogue_ref and "pnj" in dialogue_ref and dialogue_ref.pnj:
		origin_pos = dialogue_ref.pnj.global_position
	elif Player.Instance:
		origin_pos = Player.Instance.global_position
		
	var spawn_pos = QuestManager.Instance.get_spawn_position_from_direction(direction, distance, origin_pos)
	
	var spawned_obj = QuestManager.Instance.spawn_entity_in_world(target_scene, 0, 0, spawn_pos)
	_target = spawned_obj as CharacterBase
	
	if _target:
		_target.dialogue_ref = dialogue_ref
		print("KillQuest: Spawned target at ", spawn_pos, " (", direction, " ", distance, ")")
		return true
	else:
		printerr("KillQuest: Failed to spawn target.")
		return false

func _spawn_fallback(dialogue_ref: Object) -> bool:
	if QuestManager.Instance.list_character_to_kill.is_empty(): return false
	var scene = QuestManager.Instance.list_character_to_kill.pick_random()
	
	# Random spawn via ManagerQuest default behavior (around player/origin)
	var spawned_obj = QuestManager.Instance.spawn_entity_in_world(scene)
	_target = spawned_obj as CharacterBase
	if _target:
		_target.dialogue_ref = dialogue_ref
	return _target != null

func _process(_delta: float) -> void:
	if _target == null: return
	
	if(_target.is_dead):
		_valid_quest()
