class_name DeliveryQuest extends QuestBase

var _pnj : PNJ
var _item : CollectibleBase

func _init(pnj : PNJ, item : CollectibleBase) -> void :
	_type = TYPE.DELIVERY
	_pnj = pnj
	_item = item

func _process(delta: float) -> void:
	if(_pnj.is_dead):
		_fail_quest()
	if(_pnj.item_in_inventory(_item)):
		_valid_quest()
