class_name ExploreQuest extends QuestBase

var _biomes : Array[String]

func _init(biomes : String) -> void :
	_type = TYPE.EXPLORE
	_biomes = biomes

func _process(delta: float) -> void:
	for biome in _biomes:
		if()
