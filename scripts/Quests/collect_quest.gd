class_name CollectQuest extends QuestBase

var _object : CollectibleBase

func _init(object : CollectibleBase) -> void :
	_type = TYPE.COLLECT
	_object = object

func _process(delta: float) -> void:
	if(Player.Instance.item_in_inventory(_object)):
		_valid_quest()
