class_name ExploreQuest extends QuestBase

var _biome : String

func _init(biome : String) -> void :
	_type = TYPE.EXPLORE
	_biome = biome

func _process(delta: float) -> void:
	
