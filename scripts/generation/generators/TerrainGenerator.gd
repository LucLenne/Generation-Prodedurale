class_name TerrainGenerator extends RefCounted

const TileConfigScript = preload("res://scripts/generation/TileConfig.gd")

func generate(data: MapData):
	print("Filling Base Terrain...")
	# Fill entire map with forest (TREE) based on Biome
	for x in range(data.width):
		for y in range(data.height):
			var biome = data.get_biome_at(x, y)
			if biome:
				data.ground_layer.set_cell(Vector2i(x, y), TileConfig.SOURCE_ID, biome.ground_tile)
				data.wall_layer.set_cell(Vector2i(x, y), TileConfig.SOURCE_ID, biome.wall_tile)
