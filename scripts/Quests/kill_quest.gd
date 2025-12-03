class_name KillQuest extends QuestBase

var _targets : Array[PNJ]

func _init(targets : Array[PNJ]) -> void :
	_type = TYPE.KILL
	_targets = targets

func _process(delta: float) -> void:
	for target in _targets:
		if(target.is_dead):
			_targets.erase(target)
	if(_targets.is_empty()):
		_valid_quest()
