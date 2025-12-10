class_name TalkQuest extends QuestBase

var _pnj1 : CharacterBase
var _pnj2 : CharacterBase

func _init() -> void :
	type = TYPE.TALK
	
func _update_title() -> void:
	if _pnj1 and _pnj2:
		title = "Tu dois réconcilier " + _pnj1.Name + " et " + _pnj2.Name + "."
	else:
		title = "Tu dois réconcilier deux personnes (Erreur de spawn)."

func setup(world_gen: Node2D) -> void:
	_pnj1 = ManagerQuest.GetPNJ(world_gen)
	_pnj2 = ManagerQuest.GetPNJ(world_gen)
	if _pnj1: _pnj1.emotion = CharacterBase.EMOTION.ANGRY
	if _pnj2: _pnj2.emotion = CharacterBase.EMOTION.ANGRY

func try_spawn_target(direction: String, distance: float, dialogue_ref: Object) -> bool:
	# Keep original logic if possible, or adapt.
	# TalkQuest originally got existing PNJs via GetPNJ(world_gen).
	# Since we want to control spawn, we likely want to spawn NEW ones or find existing relative.
	# For consistency with "Spawn the enemy", I'll spawn new ones.
	
	if ManagerQuest.list_pnj.is_empty(): return false
	
	var origin_pos = Vector2.ZERO
	if dialogue_ref and "pnj" in dialogue_ref and dialogue_ref.pnj:
		origin_pos = dialogue_ref.pnj.global_position
	elif Player.Instance:
		origin_pos = Player.Instance.global_position

	var spawn_pos = ManagerQuest.get_spawn_position_from_direction(direction, distance, origin_pos)
	
	# Spawn 2 PNJs slightly offset?
	var scene1 = ManagerQuest.list_pnj.pick_random()
	var scene2 = ManagerQuest.list_pnj.pick_random()
	
	_pnj1 = ManagerQuest.spawn_entity_in_world(scene1, 0, 0, spawn_pos + Vector2(-20, 0)) as CharacterBase
	_pnj2 = ManagerQuest.spawn_entity_in_world(scene2, 0, 0, spawn_pos + Vector2(20, 0)) as CharacterBase
	
	if _pnj1: 
		_pnj1.emotion = CharacterBase.EMOTION.ANGRY
		_pnj1.dialogue_ref = dialogue_ref
		_pnj1.quest_data = self.quest_data
	if _pnj2: 
		_pnj2.emotion = CharacterBase.EMOTION.ANGRY
		_pnj2.dialogue_ref = dialogue_ref
		_pnj2.quest_data = self.quest_data
	
	return _pnj1 != null and _pnj2 != null

func _spawn_fallback(dialogue_ref: Object) -> bool:
	if ManagerQuest.list_pnj.is_empty(): return false
	var scene1 = ManagerQuest.list_pnj.pick_random()
	var scene2 = ManagerQuest.list_pnj.pick_random()
	
	# Spawn randomly
	_pnj1 = ManagerQuest.spawn_entity_in_world(scene1) as CharacterBase
	_pnj2 = ManagerQuest.spawn_entity_in_world(scene2) as CharacterBase
	
	if _pnj1: 
		_pnj1.emotion = CharacterBase.EMOTION.ANGRY
		_pnj1.dialogue_ref = dialogue_ref
		_pnj1.quest_data = self.quest_data
	if _pnj2: 
		_pnj2.emotion = CharacterBase.EMOTION.ANGRY
		_pnj2.dialogue_ref = dialogue_ref
		_pnj2.quest_data = self.quest_data
	
	return _pnj1 != null and _pnj2 != null

func _process(_delta: float) -> void:
	if not _pnj1 or not _pnj2: return

	if(_pnj1.emotion != CharacterBase.EMOTION.ANGRY || _pnj2.emotion != CharacterBase.EMOTION.ANGRY):
		_valid_quest()
	if(_pnj1.is_dead || _pnj2.is_dead):
		_fail_quest()
