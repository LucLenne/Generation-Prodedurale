class_name DeliveryQuest extends QuestBase

var _pnj : PNJ
var _item : CollectibleBase

func _init() -> void :
	type = TYPE.DELIVERY
	title = "Tu dois donner" + _item.Name + ", à " + _pnj._name + "."

func setup(world_gen: Node2D) -> void:
	var rd = randi_range(0, ManagerQuest.list_collectibles.size()) 
	_item = ManagerQuest.list_collectibles[rd]
	var pnj_scene = ManagerQuest.list_pnj.pick_random()
	
	var spawn_pos = Vector2.INF
	if world_gen.has_method("get_random_building_door"):
		spawn_pos = world_gen.get_random_building_door()
		
	_pnj = ManagerQuest.spawn_entity_in_world(pnj_scene, 200, 500, spawn_pos) as PNJ

func _process(_delta: float) -> void:
	if(_pnj.is_dead):
		_fail_quest()
	if(_pnj.item_in_inventory(_item)):
		_valid_quest()
