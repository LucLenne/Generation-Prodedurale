class_name RiverGenerator extends RefCounted

const TileConfigScript = preload("res://scripts/generation/TileConfig.gd")

func generate(data: MapData):
	print("Generating river...")
	var height = data.height
	var width = data.width
	var noise = data.noise
	
	var start_y = randi_range(height / 4, height * 3 / 4)
	var end_y = randi_range(height / 4, height * 3 / 4)
	
	var curve_frequency = randf_range(0.05, 0.1)
	var curve_amplitude = randf_range(10.0, 20.0)
	
	var river_cells = {} # Track river cells for autotiling
	
	for x in range(width):
		# Sinusoidal base + noise
		var t = float(x) / width
		var base_y = lerp(float(start_y), float(end_y), t)
		var sine_offset = sin(x * curve_frequency) * curve_amplitude
		var noise_offset = noise.get_noise_1d(x * 0.5) * 10.0
		
		var center_y = int(base_y + sine_offset + noise_offset)
		var river_width = randi_range(3, 5)
		
		for y in range(center_y - river_width / 2, center_y + river_width / 2 + 1):
			if y >= 0 and y < height:
				var pos = Vector2i(x, y)
				var biome = data.get_biome_at(x, y)
				
				# Get biome-specific dirt or default
				var dirt = TileConfig.DIRT
				if biome: dirt = biome.dirt_tile
					
				# Get centered water tile (default or biome specific)
				# This acts as initialization before autotiling
				var water = TileConfig.WATER_BASE
				if biome and biome.river_tiles.has("center"): 
					water = biome.river_tiles["center"]

				data.wall_layer.set_cell(pos, TileConfig.SOURCE_ID, water)
				data.ground_layer.set_cell(pos, TileConfig.SOURCE_ID, dirt) # Dirt under water
				river_cells[pos] = true

	# Autotiling
	for cell in river_cells.keys():
		var mask = 0
		# Check neighbors: If NOT in river_cells, it's LAND (Border)
		var top = cell + Vector2i(0, -1)
		var right = cell + Vector2i(1, 0)
		var bottom = cell + Vector2i(0, 1)
		var left = cell + Vector2i(-1, 0)
		
		if not river_cells.has(top): mask += 1
		if not river_cells.has(right): mask += 2
		if not river_cells.has(bottom): mask += 4
		if not river_cells.has(left): mask += 8
		
		# Default tile
		var tile = TileConfig.get_river_tile(mask)
		
		# Biome override
		var biome = data.get_biome_at(cell.x, cell.y)
		if biome and not biome.river_tiles.is_empty():
			if TileConfig.RIVER_MASK_NAMES.has(mask):
				var key = TileConfig.RIVER_MASK_NAMES[mask]
				if biome.river_tiles.has(key):
					tile = biome.river_tiles[key]

		data.wall_layer.set_cell(cell, TileConfig.SOURCE_ID, tile)
