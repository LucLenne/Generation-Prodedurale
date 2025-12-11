class_name CollectQuest extends QuestBase

var _item : CollectibleBase

func init() -> void :
	type = TYPE.COLLECT
	title = "Collect this object " + _item.Name
	var rd = randi_range(0, ManagerQuest.list_collectibles.size())
	if  ManagerQuest.list_collectibles[rd] != null:
		_item = ManagerQuest.list_collectibles[rd]
	

func _process(_delta: float) -> void:
	if(Player.Instance.item_in_inventory(_item)):
		_valid_quest()
