## Génère la carte des biomes via algorithme Voronoi.
## Chaque zone reçoit un biome aléatoire, puis les cellules sont assignées au biome le plus proche.
class_name BiomeGenerator extends RefCounted

const BiomeResourceScript = preload("res://scripts/generation/BiomeResource.gd")

var available_biomes: Array[BiomeResource]


func _init(biomes: Array[BiomeResource]):
	if biomes.is_empty():
		# Biome par défaut si aucun fourni
		available_biomes = [BiomeResourceScript.new()]
	else:
		available_biomes = biomes


## Génère la grille de biomes pour toute la carte.
func generate(data: MapData, zone_seeds: Array[Vector2i]):
	print("Generating Biome Map...")
	
	# Initialise la grille 2D
	data.biome_grid = []
	data.biome_grid.resize(data.width)
	for x in range(data.width):
		data.biome_grid[x] = []
		data.biome_grid[x].resize(data.height)
	
	# Si aucune seed, remplit tout avec un biome aléatoire
	if zone_seeds.is_empty():
		var biome = available_biomes.pick_random()
		for x in range(data.width):
			for y in range(data.height):
				data.biome_grid[x][y] = biome
		return
	
	# Assigne un biome aléatoire à chaque seed
	var seed_biomes = {}
	for seed in zone_seeds:
		seed_biomes[seed] = available_biomes.pick_random()
	
	# Voronoi : chaque cellule reçoit le biome de la seed la plus proche
	for x in range(data.width):
		for y in range(data.height):
			var pos = Vector2i(x, y)
			var closest_seed = zone_seeds[0]
			var min_dist = 999999.0
			
			for seed in zone_seeds:
				# Distance + bruit pour des bordures organiques
				var dist = pos.distance_to(seed)
				var noise_offset = data.noise.get_noise_2d(x * 2.0, y * 2.0) * 25.0
				dist += noise_offset
				
				if dist < min_dist:
					min_dist = dist
					closest_seed = seed
			
			data.biome_grid[x][y] = seed_biomes[closest_seed]
