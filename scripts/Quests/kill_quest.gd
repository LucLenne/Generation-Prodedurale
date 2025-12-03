class_name KillQuest extends QuestBase

var _target : PNJ

func _init(target : PNJ) -> void :
	_type = TYPE.KILL
	_target = target

func _process(delta: float) -> void:
	if(_target.is_dead):
		_valid_quest()
