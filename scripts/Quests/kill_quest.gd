class_name KillQuest extends QuestBase

var _target : CharacterBase

func _init() -> void :
	_type = TYPE.KILL
	var rd = randi_range(0, ManagerQuest.Instance.list_character_to_kill.size())
	_target = ManagerQuest.Instance.list_character_to_kill[rd]

func _process(_delta: float) -> void:
	if(_target.is_dead):
		_valid_quest()
