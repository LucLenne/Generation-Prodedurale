## Remplit le terrain de base avec le sol et les arbres.
## Utilise le bruit Perlin pour créer des variations naturelles.
class_name TerrainGenerator extends RefCounted

const TileConfigScript = preload("res://scripts/generation/TileConfig.gd")


## Génère le terrain de base pour toute la carte.
func generate(data: MapData):
	print("Filling Base Terrain...")
	
	for x in range(data.width):
		for y in range(data.height):
			var biome = data.get_biome_at(x, y)
			if not biome:
				continue
			
			# Variation naturelle via bruit Perlin
			var noise_val = data.noise.get_noise_2d(x * 5.0, y * 5.0)
			var ground_tile = biome.ground_tile
			
			# 40% de chance pour de la terre au lieu d'herbe
			if noise_val > 0.4:
				ground_tile = biome.dirt_tile
			
			data.ground_layer.set_cell(Vector2i(x, y), TileConfig.SOURCE_ID, ground_tile)
			data.wall_layer.set_cell(Vector2i(x, y), TileConfig.SOURCE_ID, biome.wall_tile)
