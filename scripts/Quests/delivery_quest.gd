class_name DeliveryQuest extends QuestBase

var _pnj : PNJ
var _items : Array[CollectibleBase]

func _init(pnj : PNJ, items : Array[CollectibleBase]) -> void :
	_type = TYPE.DELIVERY
	_pnj = pnj
	_items = items

func _process(delta: float) -> void:
	if(_pnj.is_dead):
		_fail_quest()
	for item in _items:
		if(Player.Instance.item_in_inventory(item)):
			_items.erase(item)
	if(_items.is_empty()):
		_valid_quest()
