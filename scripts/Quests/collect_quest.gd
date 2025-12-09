class_name CollectQuest extends QuestBase

var _item : CollectibleBase

func _init() -> void :
	type = TYPE.COLLECT
	var rd = randi_range(0, ManagerQuest.list_collectibles.size()) 
	_item = ManagerQuest.list_collectibles[rd]
	title = "Tu devrais récupérer " + _item.Name + "."

func _process(_delta: float) -> void:
	if(Player.Instance.item_in_inventory(_item)):
		_valid_quest()
