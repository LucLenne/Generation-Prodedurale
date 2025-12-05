class_name DeliveryQuest extends QuestBase

var _pnj : PNJ
var _item : CollectibleBase

func _init() -> void :
	_type = TYPE.DELIVERY
	var rd = randi_range(0, ManagerQuest.Instance.list_collectibles.size()) 
	_item = ManagerQuest.Instance.list_collectibles[rd]
	rd = randi_range(0, ManagerQuest.Instance.list_pnj.size()) 
	_pnj = ManagerQuest.Instance.list_pnj[rd]

func _process(_delta: float) -> void:
	if(_pnj.is_dead):
		_fail_quest()
	if(_pnj.item_in_inventory(_item)):
		_valid_quest()
