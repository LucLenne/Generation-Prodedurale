class_name BiomeGenerator extends RefCounted

const BiomeResourceScript = preload("res://scripts/generation/BiomeResource.gd")

var available_biomes: Array[BiomeResource]

func _init(biomes: Array[BiomeResource]):
	if biomes.is_empty():
		# Create default biome if none provided (Fallback)
		var default_biome = BiomeResourceScript.new()
		available_biomes = [default_biome]
	else:
		available_biomes = biomes

func generate(data: MapData, zone_seeds: Array[Vector2i]):
	print("Generating Biome Map...")
	data.biome_grid = []
	data.biome_grid.resize(data.width)
	for x in range(data.width):
		data.biome_grid[x] = []
		data.biome_grid[x].resize(data.height)
	
	# Assign random biome to each seed (Zone seeds are used as Biome centers effectively)
	var seed_biomes = {}
	
	# If no seeds provided (fallback), just pick one biome for whole map
	if zone_seeds.is_empty():
		var b = available_biomes.pick_random()
		for x in range(data.width):
			for y in range(data.height):
				data.biome_grid[x][y] = b
		return

	for seed in zone_seeds:
		seed_biomes[seed] = available_biomes.pick_random()
		
	# Voronoi: Assign closest seed's biome to each cell
	for x in range(data.width):
		for y in range(data.height):
			var current_pos = Vector2i(x, y)
			var closest_seed = zone_seeds[0]
			var min_dist = 999999.0
			
			for seed in zone_seeds:
				var dist = current_pos.distance_to(seed)
				if dist < min_dist:
					min_dist = dist
					closest_seed = seed
			
			data.biome_grid[x][y] = seed_biomes[closest_seed]
