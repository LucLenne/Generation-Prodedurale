class_name TerrainGenerator extends RefCounted

const TileConfigScript = preload("res://scripts/generation/TileConfig.gd")

func generate(data: MapData):
	print("Filling Base Terrain...")
	# Fill entire map with forest (TREE) based on Biome
	for x in range(data.width):
		for y in range(data.height):
			var biome = data.get_biome_at(x, y)
			if biome:
				# Base Terrain Variation
				var noise_val = data.noise.get_noise_2d(x * 5.0, y * 5.0)
				var tile = biome.ground_tile
				
				# 30% chance for variation (e.g. patches of "dirt" or alternate grass)
				if noise_val > 0.4:
					tile = biome.dirt_tile
					
				data.ground_layer.set_cell(Vector2i(x, y), TileConfig.SOURCE_ID, tile)
				data.wall_layer.set_cell(Vector2i(x, y), TileConfig.SOURCE_ID, biome.wall_tile)
