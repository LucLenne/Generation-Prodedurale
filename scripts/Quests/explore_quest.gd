class_name ExploreQuest extends QuestBase

var _biome : String

func _init() -> void :
	type = TYPE.EXPLORE
	var rd = randi_range(0, ManagerQuest.list_biomes.size())
	_biome = ManagerQuest.list_biomes[rd]



func _process(_delta: float) -> void:
	if(Player.Instance.current_biome_name == _biome):
		_valid_quest()
		
