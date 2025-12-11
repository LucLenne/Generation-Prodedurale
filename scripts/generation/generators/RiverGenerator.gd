## Génère une rivière sinueuse traversant la carte.
## Utilise des courbes sinusoïdales + bruit pour un aspect naturel.
class_name RiverGenerator extends RefCounted

const TileConfigScript = preload("res://scripts/generation/TileConfig.gd")


## Génère la rivière et applique l'autotiling.
func generate(data: MapData):
	print("Generating river...")
	
	# Points de départ et d'arrivée aléatoires (gauche -> droite)
	var start_y = randi_range(data.height / 4, data.height * 3 / 4)
	var end_y = randi_range(data.height / 4, data.height * 3 / 4)
	
	# Paramètres de courbe
	var curve_frequency = randf_range(0.05, 0.1)
	var curve_amplitude = randf_range(10.0, 20.0)
	
	var river_cells = {}
	
	# Trace la rivière de gauche à droite
	for x in range(data.width):
		# Interpole Y avec courbe sinusoïdale + bruit
		var t = float(x) / data.width
		var base_y = lerp(float(start_y), float(end_y), t)
		var sine_offset = sin(x * curve_frequency) * curve_amplitude
		var noise_offset = data.noise.get_noise_1d(x * 0.5) * 10.0
		
		var center_y = int(base_y + sine_offset + noise_offset)
		var river_width = randi_range(3, 5)
		
		# Remplit la largeur de la rivière
		for y in range(center_y - river_width / 2, center_y + river_width / 2 + 1):
			if y < 0 or y >= data.height:
				continue
				
			var pos = Vector2i(x, y)
			var biome = data.get_biome_at(x, y)
			
			# Place l'eau et la terre en dessous
			var dirt = biome.dirt_tile if biome else TileConfig.DIRT
			var water = TileConfig.WATER_BASE
			if biome and biome.river_tiles.has("center"):
				water = biome.river_tiles["center"]
			
			data.wall_layer.set_cell(pos, TileConfig.SOURCE_ID, water)
			data.ground_layer.set_cell(pos, TileConfig.SOURCE_ID, dirt)
			river_cells[pos] = true
			data.reserved_cells[pos] = true

	# Applique l'autotiling
	_apply_autotiling(data, river_cells)


## Applique l'autotiling aux cellules de la rivière.
func _apply_autotiling(data: MapData, river_cells: Dictionary):
	for cell in river_cells.keys():
		# Calcule le masque de bordure
		var mask = 0
		if not river_cells.has(cell + Vector2i(0, -1)): mask += 1  # Haut
		if not river_cells.has(cell + Vector2i(1, 0)): mask += 2   # Droite
		if not river_cells.has(cell + Vector2i(0, 1)): mask += 4   # Bas
		if not river_cells.has(cell + Vector2i(-1, 0)): mask += 8  # Gauche
		
		# Tuile par défaut
		var tile = TileConfig.get_river_tile(mask)
		
		# Override par biome si disponible
		var biome = data.get_biome_at(cell.x, cell.y)
		if biome and not biome.river_tiles.is_empty():
			if TileConfig.RIVER_MASK_NAMES.has(mask):
				var key = TileConfig.RIVER_MASK_NAMES[mask]
				if biome.river_tiles.has(key):
					tile = biome.river_tiles[key]
		
		data.wall_layer.set_cell(cell, TileConfig.SOURCE_ID, tile)
