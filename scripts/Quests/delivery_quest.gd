class_name DeliveryQuest extends QuestBase

var _pnj : PNJ
var _item : CollectibleBase

func _init() -> void :
	type = TYPE.DELIVERY

func setup(world_gen: Node2D) -> void:
	var rd = randi_range(0, QuestManager.Instance.list_collectibles.size()) 
	_item = QuestManager.Instance.list_collectibles[rd]
	# Defer spawning of PNJ

func try_spawn_target(direction: String, distance: float, dialogue_ref: Object) -> bool:
	if QuestManager.Instance.list_pnj.is_empty(): return false
	
	var pnj_scene = QuestManager.Instance.list_pnj.pick_random()
	
	var origin_pos = Vector2.ZERO
	if dialogue_ref and "pnj" in dialogue_ref and dialogue_ref.pnj:
		origin_pos = dialogue_ref.pnj.global_position
	elif Player.Instance:
		origin_pos = Player.Instance.global_position
		
	var spawn_pos = QuestManager.Instance.get_spawn_position_from_direction(direction, distance, origin_pos)
	
	_pnj = QuestManager.Instance.spawn_entity_in_world(pnj_scene, 0, 0, spawn_pos) as PNJ
	if _pnj: _pnj.dialogue_ref = dialogue_ref
	return _pnj != null

func _spawn_fallback(dialogue_ref: Object) -> bool:
	if QuestManager.Instance.list_pnj.is_empty(): return false
	var scene = QuestManager.Instance.list_pnj.pick_random()
	
	_pnj = QuestManager.Instance.spawn_entity_in_world(scene) as PNJ
	if _pnj: _pnj.dialogue_ref = dialogue_ref
	return _pnj != null

func _process(_delta: float) -> void:
	if(_pnj.is_dead):
		_fail_quest()
	if(_pnj.item_in_inventory(_item)):
		_valid_quest()
