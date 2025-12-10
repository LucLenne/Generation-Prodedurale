class_name ZoneGenerator extends RefCounted

const ZoneScript = preload("res://scripts/generation/Zone.gd")
const TileConfigScript = preload("res://scripts/generation/TileConfig.gd")
const BiomeResourceScript = preload("res://scripts/generation/BiomeResource.gd")

var zone_count_range: Vector2i
var zone_size_range: Vector2i
var min_zone_distance: int
var entrance_count_range: Vector2i
var zone_dirt_ratio: float

func _init(count_range: Vector2i, size_range: Vector2i, min_dist: int, entrance_range: Vector2i, dirt_ratio: float):
	zone_count_range = count_range
	zone_size_range = size_range
	min_zone_distance = min_dist
	entrance_count_range = entrance_range
	zone_dirt_ratio = dirt_ratio

func generate_seeds(data: MapData) -> Array[Vector2i]:
	# Poisson Disk Sampling
	var seeds: Array[Vector2i] = []
	var zone_count = randi_range(zone_count_range.x, zone_count_range.y)
	
	var attempts = 0
	var max_attempts = zone_count * 100
	
	while seeds.size() < zone_count and attempts < max_attempts:
		attempts += 1
		var candidate = Vector2i(
			randi_range(10, data.width - 10),
			randi_range(10, data.height - 10)
		)
		
		var valid = true
		for existing in seeds:
			if candidate.distance_to(existing) < min_zone_distance:
				valid = false
				break
		
		if valid:
			seeds.append(candidate)
	
	return seeds

func generate_zones(data: MapData, seeds: Array[Vector2i]):
	print("Generating zones...")
	data.zones.clear()
	var all_zone_cells = {}
	
	var zone_id = 0
	for seed in seeds:
		var target_size = randi_range(zone_size_range.x, zone_size_range.y)
		var biome = data.get_biome_at(seed.x, seed.y)
		
		var zone = grow_zone(data, zone_id, seed, target_size, all_zone_cells, biome)
		
		if zone.get_size() > 10:
			data.zones.append(zone)
			
			# Add zone cells to tracking (with buffer)
			for cell in zone.cells:
				all_zone_cells[cell] = zone_id
				# Buffer
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						var buffer_cell = cell + Vector2i(dx, dy)
						if not all_zone_cells.has(buffer_cell):
							all_zone_cells[buffer_cell] = -1 # -1 = buffer
			
			# Carve zone
			carve_zone(data, zone, biome)
			zone_id += 1
	
	# Identify entrances
	identify_entrances(data.zones)
	print("Generated %d zones" % data.zones.size())

func grow_zone(data: MapData, zone_id: int, seed: Vector2i, target_size: int, existing_zones: Dictionary, biome: BiomeResource) -> Zone:
	match biome.zone_shape:
		BiomeResource.ZoneShape.RECTANGULAR:
			return grow_zone_rectangular(data, zone_id, seed, target_size, existing_zones)
		BiomeResource.ZoneShape.CIRCULAR:
			return grow_zone_circular(data, zone_id, seed, target_size, existing_zones)
		_:
			return grow_zone_organic(data, zone_id, seed, target_size, existing_zones)

func carve_zone(data: MapData, zone: Zone, biome: BiomeResource):
	var boundary_cells = zone.get_boundary_cells()
	var boundary_set = {}
	for b_cell in boundary_cells:
		boundary_set[b_cell] = true
		
	for cell in zone.cells:
		# Preserve Water
		if TileConfig.is_water(data.wall_layer.get_cell_atlas_coords(cell)):
			continue
			
		# Check border density
		if boundary_set.has(cell):
			if randf() < biome.border_tree_density:
				continue # Keep tree
				
		var biome_at_cell = data.get_biome_at(cell.x, cell.y)
		data.wall_layer.set_cell(cell, -1) # Remove tree
		
		if biome_at_cell:
			if randf() < zone_dirt_ratio:
				data.ground_layer.set_cell(cell, TileConfig.SOURCE_ID, biome_at_cell.dirt_tile)
			else:
				data.ground_layer.set_cell(cell, TileConfig.SOURCE_ID, biome_at_cell.ground_tile)
		else:
			printerr("Warning: No biome found at zone cell ", cell)

	# Outer Border Gaps
	process_outer_border(data, zone, boundary_set, biome)

func process_outer_border(data: MapData, zone: Zone, boundary_set: Dictionary, biome: BiomeResource):
	var outer_boundary_set = {}
	for b_cell in boundary_set:
		var neighbors = [
			b_cell + Vector2i(0, -1), b_cell + Vector2i(1, 0),
			b_cell + Vector2i(0, 1), b_cell + Vector2i(-1, 0)
		]
		for neighbor in neighbors:
			if not boundary_set.has(neighbor) and not zone.is_point_inside(neighbor):
				if data.is_in_bounds(neighbor.x, neighbor.y):
					outer_boundary_set[neighbor] = true

	for outer_cell in outer_boundary_set:
		if randf() > biome.border_tree_density:
			data.wall_layer.set_cell(outer_cell, -1)
			var biome_at_cell = data.get_biome_at(outer_cell.x, outer_cell.y)
			if biome_at_cell:
				data.ground_layer.set_cell(outer_cell, TileConfig.SOURCE_ID, biome_at_cell.dirt_tile)

func identify_entrances(zones: Array):
	for zone in zones:
		var boundary = zone.get_boundary_cells()
		var count = randi_range(entrance_count_range.x, entrance_count_range.y)
		boundary.shuffle()
		for i in range(min(count, boundary.size())):
			zone.entrances.append(boundary[i])

# --- Growth Implementations ---

func grow_zone_rectangular(data: MapData, zone_id: int, seed: Vector2i, target_size: int, existing_zones: Dictionary) -> Zone:
	var zone = ZoneScript.new(zone_id, seed)
	if existing_zones.has(seed): return zone
	
	var aspect_ratio = randf_range(0.5, 2.0)
	var height = int(sqrt(target_size / aspect_ratio))
	var width = int(height * aspect_ratio)
	var half_width = width / 2
	var half_height = height / 2
	
	for x in range(seed.x - half_width, seed.x + half_width + 1):
		for y in range(seed.y - half_height, seed.y + half_height + 1):
			var cell = Vector2i(x, y)
			if not data.is_in_bounds(cell.x, cell.y): continue
			if existing_zones.has(cell): continue
			zone.add_cell(cell)
	return zone

func grow_zone_circular(data: MapData, zone_id: int, seed: Vector2i, target_size: int, existing_zones: Dictionary) -> Zone:
	var zone = ZoneScript.new(zone_id, seed)
	if existing_zones.has(seed): return zone
	
	var radius = sqrt(target_size / PI)
	var ellipse_ratio = randf_range(0.7, 1.3)
	var radius_x = radius * ellipse_ratio
	var radius_y = radius / ellipse_ratio
	
	for x in range(int(seed.x - radius_x - 1), int(seed.x + radius_x + 2)):
		for y in range(int(seed.y - radius_y - 1), int(seed.y + radius_y + 2)):
			var cell = Vector2i(x,y)
			if not data.is_in_bounds(cell.x, cell.y): continue
			if existing_zones.has(cell): continue
			
			var dx = float(cell.x - seed.x) / radius_x
			var dy = float(cell.y - seed.y) / radius_y
			if dx*dx + dy*dy <= 1.0:
				zone.add_cell(cell)
	return zone

func grow_zone_organic(data: MapData, zone_id: int, seed: Vector2i, target_size: int, existing_zones: Dictionary) -> Zone:
	var zone = ZoneScript.new(zone_id, seed)
	if existing_zones.has(seed): return zone
	
	var candidates = {}
	var visited = {}
	var aspect_ratio = randf_range(0.5, 2.0)
	candidates[seed] = 1000.0
	
	while zone.get_size() < target_size and candidates.size() > 0:
		var best_cell = Vector2i.ZERO
		var best_score = -999999.0
		for cell in candidates:
			if candidates[cell] > best_score:
				best_score = candidates[cell]
				best_cell = cell
		
		candidates.erase(best_cell)
		zone.add_cell(best_cell)
		visited[best_cell] = true
		
		var neighbors = [
			best_cell + Vector2i(0, -1), best_cell + Vector2i(1, 0),
			best_cell + Vector2i(0, 1), best_cell + Vector2i(-1, 0)
		]
		if randf() < 0.4:
			neighbors.append_array([
				best_cell + Vector2i(1,-1), best_cell + Vector2i(1,1),
				best_cell + Vector2i(-1,1), best_cell + Vector2i(-1,-1)
			])
			
		for neighbor in neighbors:
			if visited.has(neighbor) or candidates.has(neighbor): continue
			if not data.is_in_bounds(neighbor.x, neighbor.y): continue
			if existing_zones.has(neighbor): continue
			
			var dx = abs(neighbor.x - seed.x)
			var dy = abs(neighbor.y - seed.y)
			var dist = max(dx, dy * aspect_ratio)
			var noise_val = data.noise.get_noise_2d(neighbor.x * 0.1, neighbor.y * 0.1)
			var score = -dist + (noise_val * 5.0)
			candidates[neighbor] = score
			
			candidates[neighbor] = score
			
	# Smoothing Pass (Cellular Automata - simple)
	return _smooth_zone(zone)

func _smooth_zone(zone: Zone) -> Zone:
	var cells_set = {}
	for c in zone.cells: cells_set[c] = true
	
	var new_cells = []
	
	# Erosion / Smoothing
	for c in zone.cells:
		var neighbors = 0
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0: continue
				if cells_set.has(c + Vector2i(dx, dy)):
					neighbors += 1
		
		# Keep if enough neighbors (solid)
		if neighbors >= 3:
			new_cells.append(c)
			
	zone.cells = new_cells
	return zone
