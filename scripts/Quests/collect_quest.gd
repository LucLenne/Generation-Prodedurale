class_name CollectQuest extends QuestBase

var _items : Array[CollectibleBase]

func _init(items : Array[CollectibleBase]) -> void :
	_type = TYPE.COLLECT
	_items = items

func _process(delta: float) -> void:
	for item in _items:
		if(Player.Instance.item_in_inventory(item)):
			_items.erase(item)
	if(_items.is_empty()):
		_valid_quest()
