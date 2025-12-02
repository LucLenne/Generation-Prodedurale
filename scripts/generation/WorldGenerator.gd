class_name WorldGenerator extends Node2D

@export var width : int = 120
@export var height : int = 120

@export_group("Zone Configuration")
@export var zone_count_range: Vector2i = Vector2i(5, 12)
@export var zone_size_range: Vector2i = Vector2i(15, 40)

@export_group("Zone Details")
@export var entrance_count_range: Vector2i = Vector2i(1, 4)
@export var building_count_range: Vector2i = Vector2i(2, 8)
@export_range(0.0, 1.0, 0.05) var zone_dirt_ratio: float = 0.4  # 0 = all grass, 1 = all dirt

@export_group("Path Generation")
@export var path_width: int = 2
@export var path_smoothness: float = 0.5
@export_range(0.0, 1.0, 0.05) var path_edge_grass_ratio: float = 0.3  # Grass on path edges
@export_range(0.0, 1.0, 0.05) var path_edge_dirt_ratio: float = 0.2   # Dirt on path edges (rest = trees)

@export_group("Resources")
@export var npc_scene : PackedScene
@export var house_scenes : Array[PackedScene]

@export_group("Layers")
@export var ground_layer : TileMapLayer
@export var wall_layer : TileMapLayer

const HouseGenScript = preload("res://scripts/generation/HouseGenerator.gd")
const HouseScript = preload("res://scripts/House.gd")
const TileConfigScript = preload("res://scripts/generation/TileConfig.gd")
const ZoneScript = preload("res://scripts/generation/Zone.gd")

var zones: Array = []  # Array of Zone objects
var zone_graph: Dictionary = {}  # Adjacency list
var npcs : Array[NPC] = []
var noise : FastNoiseLite

func _ready():
	print("WorldGenerator _ready called.")
	if npc_scene == null:
		npc_scene = preload("res://scenes/generation/NPC.tscn")
	
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.02
	noise.fractal_octaves = 4
	
	if ground_layer == null or wall_layer == null:
		printerr("Error: TileMapLayers are not assigned in WorldGenerator!")
		return
		
	print("Layers assigned. Starting generation...")
	generate_world()

func generate_world():
	print("Starting World Generation (Forest Network)...")
	ground_layer.clear()
	wall_layer.clear()
	zones.clear()
	zone_graph.clear()
	for npc in npcs:
		npc.queue_free()
	npcs.clear()
	
	fill_forest()
	generate_zones()
	connect_zones()
	populate_zones()
	print("World Generation Complete.")

func fill_forest():
	# Fill entire map with forest (TREE)
	for x in range(width):
		for y in range(height):
			ground_layer.set_cell(Vector2i(x, y), TileConfig.SOURCE_ID, TileConfig.GRASS)
			wall_layer.set_cell(Vector2i(x, y), TileConfig.SOURCE_ID, TileConfig.TREE)

func generate_zones():
	print("Generating zones...")
	var zone_seeds = generate_zone_seeds()
	var all_zone_cells = {}  # Track all cells occupied by zones
	
	var zone_id = 0
	for seed in zone_seeds:
		var target_size = randi_range(zone_size_range.x, zone_size_range.y)
		var zone = grow_zone_organically(zone_id, seed, target_size, all_zone_cells)
		
		if zone.get_size() > 10:  # Only keep zones with reasonable size
			zones.append(zone)
			
			# Add zone cells to tracking (with buffer)
			for cell in zone.cells:
				all_zone_cells[cell] = zone_id
				# Also mark buffer cells (1-tile around zone) as occupied
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						var buffer_cell = cell + Vector2i(dx, dy)
						if not all_zone_cells.has(buffer_cell):
							all_zone_cells[buffer_cell] = -1  # -1 = buffer zone
			
			# Carve out the zone from forest
			for cell in zone.cells:
				wall_layer.set_cell(cell, -1)  # Remove tree
				# Mix of grass and dirt for natural look
				if randf() < zone_dirt_ratio:
					ground_layer.set_cell(cell, TileConfig.SOURCE_ID, TileConfig.DIRT)
				else:
					ground_layer.set_cell(cell, TileConfig.SOURCE_ID, TileConfig.GRASS)
			
			zone_id += 1
	
	# Identify entrances (boundary cells)
	for zone in zones:
		var boundary = zone.get_boundary_cells()
		# Select random entrances based on range
		var entrance_count = randi_range(entrance_count_range.x, entrance_count_range.y)
		boundary.shuffle()
		for i in range(min(entrance_count, boundary.size())):
			zone.entrances.append(boundary[i])
	
	print("Generated %d zones" % zones.size())

func generate_zone_seeds() -> Array[Vector2i]:
	# Poisson Disk Sampling for natural spacing
	var seeds: Array[Vector2i] = []
	var zone_count = randi_range(zone_count_range.x, zone_count_range.y)
	var min_distance = 25  # Minimum distance between zone centers
	
	var attempts = 0
	var max_attempts = zone_count * 100
	
	while seeds.size() < zone_count and attempts < max_attempts:
		attempts += 1
		var candidate = Vector2i(
			randi_range(10, width - 10),
			randi_range(10, height - 10)
		)
		
		var valid = true
		for existing in seeds:
			if candidate.distance_to(existing) < min_distance:
				valid = false
				break
		
		if valid:
			seeds.append(candidate)
	
	return seeds

func grow_zone_organically(zone_id: int, seed: Vector2i, target_size: int, existing_zones: Dictionary) -> Zone:
	var zone = Zone.new(zone_id, seed)
	var open_set: Array[Vector2i] = [seed]
	var visited = {}
	
	# Check if seed is already in another zone
	if existing_zones.has(seed):
		return zone  # Return empty zone
	
	# Calculate effective radius from target size (area = pi*r^2)
	var effective_radius = sqrt(target_size / PI) * 1.5  # Multiply by 1.5 for better growth
	
	while zone.get_size() < target_size and open_set.size() > 0:
		var current = open_set.pop_front()
		if visited.has(current):
			continue
		
		# Bounds check
		if current.x < 1 or current.x >= width - 1 or current.y < 1 or current.y >= height - 1:
			continue
		
		# Check if this cell is already in another zone or buffer
		if existing_zones.has(current):
			continue
		
		# Multi-octave organic noise for natural shapes
		var dist = current.distance_to(Vector2(seed))
		var noise_val1 = noise.get_noise_2d(current.x * 0.15, current.y * 0.15)  # Large features
		var noise_val2 = noise.get_noise_2d(current.x * 0.4, current.y * 0.4) * 0.5  # Medium details
		var noise_val3 = noise.get_noise_2d(current.x * 0.8, current.y * 0.8) * 0.25  # Fine details
		var combined_noise = noise_val1 + noise_val2 + noise_val3
		
		# Improved probability formula for better size scaling
		var dist_factor = 1.0 - (dist / effective_radius)
		var prob = clamp(dist_factor + combined_noise * 0.6, 0.0, 1.0)
		
		if randf() < prob:
			zone.add_cell(current)
			visited[current] = true
			
			# Add neighbors (sometimes diagonal for more organic growth)
			var neighbors = [
				current + Vector2i(0, -1),
				current + Vector2i(1, 0),
				current + Vector2i(0, 1),
				current + Vector2i(-1, 0)
			]
			# Occasionally add diagonal neighbors for rounder shapes
			if randf() < 0.3:
				neighbors.append_array([
					current + Vector2i(1, -1),
					current + Vector2i(1, 1),
					current + Vector2i(-1, 1),
					current + Vector2i(-1, -1)
				])
			
			for neighbor in neighbors:
				if not visited.has(neighbor) and not existing_zones.has(neighbor):
					open_set.append(neighbor)
	
	return zone

	
	while zone.get_size() < target_size and open_set.size() > 0:
		var current = open_set.pop_front()
		if visited.has(current):
			continue
		
		# Bounds check
		if current.x < 1 or current.x >= width - 1 or current.y < 1 or current.y >= height - 1:
			continue
		
		# Multi-octave organic noise for natural shapes
		var dist = current.distance_to(Vector2(seed))
		var noise_val1 = noise.get_noise_2d(current.x * 0.15, current.y * 0.15)  # Large features
		var noise_val2 = noise.get_noise_2d(current.x * 0.4, current.y * 0.4) * 0.5  # Medium details
		var noise_val3 = noise.get_noise_2d(current.x * 0.8, current.y * 0.8) * 0.25  # Fine details
		var combined_noise = noise_val1 + noise_val2 + noise_val3
		
		# Improved probability formula for better size scaling
		var dist_factor = 1.0 - (dist / effective_radius)
		var prob = clamp(dist_factor + combined_noise * 0.6, 0.0, 1.0)
		
		if randf() < prob:
			zone.add_cell(current)
			visited[current] = true
			
			# Add neighbors (sometimes diagonal for more organic growth)
			var neighbors = [
				current + Vector2i(0, -1),
				current + Vector2i(1, 0),
				current + Vector2i(0, 1),
				current + Vector2i(-1, 0)
			]
			# Occasionally add diagonal neighbors for rounder shapes
			if randf() < 0.3:
				neighbors.append_array([
					current + Vector2i(1, -1),
					current + Vector2i(1, 1),
					current + Vector2i(-1, 1),
					current + Vector2i(-1, -1)
				])
			
			for neighbor in neighbors:
				if not visited.has(neighbor):
					open_set.append(neighbor)
	
	return zone

func connect_zones():
	print("Connecting zones...")
	build_zone_graph()
	
	# Create MST for minimum connectivity
	var mst_edges = build_minimum_spanning_tree()
	
	# Carve paths for each edge
	for edge in mst_edges:
		carve_path_between_zones(edge.from_zone, edge.to_zone)
	
	print("Connected %d zone pairs" % mst_edges.size())

func build_zone_graph():
	# Build adjacency list of nearby zones
	for i in range(zones.size()):
		zone_graph[i] = []
		for j in range(i + 1, zones.size()):
			var dist = zones[i].center.distance_to(zones[j].center)
			# Only connect if reasonably close
			if dist < 80:
				zone_graph[i].append({"to": j, "dist": dist})

func build_minimum_spanning_tree() -> Array:
	# Kruskal's algorithm for MST
	var edges = []
	
	# Collect all edges
	for from_id in zone_graph:
		for edge in zone_graph[from_id]:
			edges.append({"from": from_id, "to": edge.to, "dist": edge.dist})
	
	# Sort by distance
	edges.sort_custom(func(a, b): return a.dist < b.dist)
	
	# Union-Find for MST
	var parent = {}
	for i in range(zones.size()):
		parent[i] = i
	
	# Build MST using Kruskal's algorithm
	var mst_edges = []
	for edge in edges:
		# Find root of 'from' node
		var root_from = edge.from
		while parent[root_from] != root_from:
			parent[root_from] = parent[parent[root_from]]  # Path compression
			root_from = parent[root_from]
		
		# Find root of 'to' node
		var root_to = edge.to
		while parent[root_to] != root_to:
			parent[root_to] = parent[parent[root_to]]  # Path compression
			root_to = parent[root_to]
		
		# If different roots, union them
		if root_from != root_to:
			parent[root_from] = root_to
			mst_edges.append({"from_zone": zones[edge.from], "to_zone": zones[edge.to]})
	
	# Add some extra edges for loops (20% of MST size)
	var extra_count = max(1, int(mst_edges.size() * 0.2))
	for i in range(extra_count):
		if i < edges.size():
			var edge = edges[i]
			mst_edges.append({"from_zone": zones[edge.from], "to_zone": zones[edge.to]})
	
	return mst_edges

func carve_path_between_zones(zone_a: Zone, zone_b: Zone):
	var start = zone_a.get_random_entrance()
	var end = zone_b.get_random_entrance()
	
	# Generate 1-3 intermediate waypoints for natural meandering
	var waypoints: Array[Vector2i] = [start]
	var num_waypoints = randi_range(1, 3)
	
	for i in range(num_waypoints):
		# Interpolate between start and end, then deviate with noise
		var t = (i + 1.0) / (num_waypoints + 1.0)
		var lerp_pos = Vector2(start).lerp(Vector2(end), t)
		
		# Add perpendicular deviation for natural curves
		var direction = (Vector2(end) - Vector2(start)).normalized()
		var perpendicular = Vector2(-direction.y, direction.x)
		var deviation = noise.get_noise_2d(i * 100, zone_a.id * 50) * 15.0  # Larger deviation
		
		var waypoint = Vector2i(lerp_pos + perpendicular * deviation)
		# Clamp to bounds
		waypoint.x = clamp(waypoint.x, 5, width - 5)
		waypoint.y = clamp(waypoint.y, 5, height - 5)
		waypoints.append(waypoint)
	
	waypoints.append(end)
	
	# A* pathfinding between consecutive waypoints
	var astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, width, height)
	astar.cell_size = Vector2(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	var full_path: Array[Vector2i] = []
	for i in range(waypoints.size() - 1):
		var segment = astar.get_id_path(waypoints[i], waypoints[i + 1])
		full_path.append_array(segment)
	
	# Apply noise-based micro-curves to the full path
	var curved_path: Array[Vector2i] = []
	for i in range(full_path.size()):
		var point = full_path[i]
		# Small local noise deviation
		var noise_offset_x = int(noise.get_noise_1d(i * 0.5) * 2.0)
		var noise_offset_y = int(noise.get_noise_1d(i * 0.5 + 1000) * 2.0)
		var curved_point = point + Vector2i(noise_offset_x, noise_offset_y)
		
		# Clamp to bounds
		if curved_point.x >= 0 and curved_point.x < width and curved_point.y >= 0 and curved_point.y < height:
			curved_path.append(curved_point)
		else:
			curved_path.append(point)
	
	# Carve path with variable width for naturalness
	var processed_edge_cells = {}  # Track cells already modified in transition zone
	
	for point in curved_path:
		# Vary width slightly along path
		var local_width = path_width + int(noise.get_noise_2d(point.x * 0.1, point.y * 0.1) * 1.5)
		local_width = clamp(local_width, 1, path_width + 2)
		
		for dx in range(-local_width / 2, local_width / 2 + 1):
			for dy in range(-local_width / 2, local_width / 2 + 1):
				var cell = point + Vector2i(dx, dy)
				if cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height:
					wall_layer.set_cell(cell, -1)  # Remove tree
					ground_layer.set_cell(cell, TileConfig.SOURCE_ID, TileConfig.PATH)
		
		# Add natural mix around the path (1-2 tiles on each side)
		for dx in range(-local_width / 2 - 2, local_width / 2 + 3):
			for dy in range(-local_width / 2 - 2, local_width / 2 + 3):
				# Skip the path itself
				if abs(dx) <= local_width / 2 and abs(dy) <= local_width / 2:
					continue
				
				var side_cell = point + Vector2i(dx, dy)
				
				# Skip if already processed
				if processed_edge_cells.has(side_cell):
					continue
					
				if side_cell.x >= 0 and side_cell.x < width and side_cell.y >= 0 and side_cell.y < height:
					var current_wall = wall_layer.get_cell_source_id(side_cell)
					var current_ground = ground_layer.get_cell_atlas_coords(side_cell)
					
					# Only modify forest (has tree) or plain grass (cleared but not yet filled)
					if current_wall != -1 or current_ground == TileConfig.GRASS:
						var rand_val = randf()
						if rand_val < path_edge_grass_ratio:  # Grass
							wall_layer.set_cell(side_cell, -1)
							ground_layer.set_cell(side_cell, TileConfig.SOURCE_ID, TileConfig.GRASS)
						elif rand_val < path_edge_grass_ratio + path_edge_dirt_ratio:  # Dirt
							wall_layer.set_cell(side_cell, -1)
							ground_layer.set_cell(side_cell, TileConfig.SOURCE_ID, TileConfig.DIRT)
						else:  # Keep/restore tree
							wall_layer.set_cell(side_cell, TileConfig.SOURCE_ID, TileConfig.TREE)
							ground_layer.set_cell(side_cell, TileConfig.SOURCE_ID, TileConfig.GRASS)
						
						# Mark as processed
						processed_edge_cells[side_cell] = true

func populate_zones():
	print("Populating zones...")
	for zone in zones:
		var building_count = randi_range(building_count_range.x, building_count_range.y)
		var placed_buildings: Array[Rect2i] = []  # Track placed building footprints
		var building_doors: Array[Vector2i] = []  # Track door positions
		var occupied_cells = {}  # Track all cells occupied by buildings
		
		for i in range(building_count):
			# Pick random cell in zone
			if zone.cells.is_empty():
				continue
			
			var attempts = 0
			while attempts < 100:  # Even more attempts
				attempts += 1
				var cell = zone.cells.pick_random()
				
				# Skip if on existing path
				var current_ground = ground_layer.get_cell_atlas_coords(cell)
				if current_ground == TileConfig.PATH:
					continue
				
				# Try to place building
				var result = try_place_building_at(zone, cell, placed_buildings, occupied_cells)
				if result.success:
					placed_buildings.append(result.rect)
					building_doors.append(result.door)
					# Mark all cells of this building as occupied
					if result.has("actual_cells"):
						# Scene building - use actual tile cells
						for actual_cell in result.actual_cells:
							occupied_cells[actual_cell] = true
					else:
						# Procedural building - use rect
						for x in range(result.rect.position.x, result.rect.end.x):
							for y in range(result.rect.position.y, result.rect.end.y):
								occupied_cells[Vector2i(x, y)] = true
					break
		
		# Generate paths from existing paths to building doors
		var path_cells_in_zone: Array[Vector2i] = []
		
		# Collect all path cells in this zone (including main inter-zone paths)
		for cell in zone.cells:
			var tile = ground_layer.get_cell_atlas_coords(cell)
			if tile == TileConfig.PATH:
				path_cells_in_zone.append(cell)
		
		# If no paths exist yet, use zone entrances as starting points
		if path_cells_in_zone.is_empty():
			path_cells_in_zone = zone.entrances.duplicate()
		
		for door in building_doors:
			# Find nearest path cell to this door
			var nearest_path_cell = path_cells_in_zone[0] if path_cells_in_zone.size() > 0 else zone.center
			var min_dist = 999999.0
			
			for path_cell in path_cells_in_zone:
				var dist = path_cell.distance_to(door)
				if dist < min_dist:
					min_dist = dist
					nearest_path_cell = path_cell
			
			# A* path from nearest path to door with building obstacles (excluding doors)
			var astar = AStarGrid2D.new()
			astar.region = zone.shape_bounds.grow(5)
			astar.cell_size = Vector2(1, 1)
			astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
			astar.update()
			
			# Mark occupied cells as solid obstacles (EXCEPT doors)
			for occupied_cell in occupied_cells.keys():
				# Don't block doors - they should be accessible
				if occupied_cell != door and astar.is_in_bounds(occupied_cell.x, occupied_cell.y):
					astar.set_point_solid(occupied_cell)
			
			var path = astar.get_id_path(nearest_path_cell, door)
			# Carve path up to (but not including) the door
			for i in range(path.size() - 1):  # -1 to not overwrite door
				var point = path[i]
				# Only carve path on grass or dirt (not on buildings)
				if zone.is_point_inside(point) and not occupied_cells.has(point):
					var current_tile = ground_layer.get_cell_atlas_coords(point)
					if current_tile == TileConfig.GRASS or current_tile == TileConfig.DIRT:
						ground_layer.set_cell(point, TileConfig.SOURCE_ID, TileConfig.PATH)
						# Add this new path cell to the list for future connections
						path_cells_in_zone.append(point)
		
		# Spawn NPCs near building doors
		for door in building_doors:
			# Spawn NPC 1 tile in front of door (outside the building)
			var npc_pos = Vector2(door.x, door.y + 1)  # Assuming door faces down
			spawn_npc(npc_pos)
	
	print("Populated %d zones" % zones.size())

func try_place_building_at(zone: Zone, pos: Vector2i, placed_buildings: Array[Rect2i], occupied_cells: Dictionary) -> Dictionary:
	var result = {"success": false, "rect": Rect2i(), "door": Vector2i()}
	
	var use_scene = house_scenes.size() > 0 and randf() > 0.5
	var offset = Vector2i.ZERO
	var building_size = Vector2i(5, 5)
	var door_pos = pos
	
	if use_scene:
		var scene = house_scenes.pick_random()
		var temp = scene.instantiate()
		
		var local_door = Vector2i(2, 4)
		var actual_cells: Array[Vector2i] = []  # Track all actual tiles
		var tile_layer = temp.get_node_or_null("TileMapLayer")
		if tile_layer:
			var rect = tile_layer.get_used_rect()
			if rect.has_area():
				building_size = rect.size
				offset = rect.position
				
				# Get ALL used cells from the scene
				for cell in tile_layer.get_used_cells():
					var world_cell = pos + (cell - offset)
					actual_cells.append(world_cell)
					
					if tile_layer.get_cell_atlas_coords(cell) == TileConfig.DOOR:
						local_door = cell
		
		temp.free()
		door_pos = pos + (local_door - offset)
		
		# Check if ALL actual cells fit in zone and aren't occupied
		var building_rect = Rect2i(pos, building_size)
		for cell in actual_cells:
			if not zone.is_point_inside(cell):
				return result
			# Check if cell is already occupied
			if occupied_cells.has(cell):
				return result
			# Check if on main path
			var ground_tile = ground_layer.get_cell_atlas_coords(cell)
			if ground_tile == TileConfig.PATH:
				return result
		
		# Check collision with other buildings (with larger spacing)
		for other in placed_buildings:
			if building_rect.grow(3).intersects(other):  # 3-tile spacing
				return result
		
		# Place building
		var instance = scene.instantiate()
		instance.position = Vector2(pos - offset) * TileConfig.TILE_SIZE
		add_child(instance)
		zone.buildings.append(instance)
		
		result.success = true
		result.rect = building_rect
		result.door = door_pos
		result.actual_cells = actual_cells  # Return actual cells for tracking
		return result
	else:
		# Procedural building
		var house_data = HouseGenScript.generate_random_house(pos)
		var building_rect = house_data.rect
		door_pos = house_data.door_position
		
		# Check if fits
		for x in range(building_rect.position.x, building_rect.end.x):
			for y in range(building_rect.position.y, building_rect.end.y):
				if not zone.is_point_inside(Vector2i(x, y)):
					return result
				# Check if cell is already occupied
				if occupied_cells.has(Vector2i(x, y)):
					return result
				# Check if on main path
				var ground_tile = ground_layer.get_cell_atlas_coords(Vector2i(x, y))
				if ground_tile == TileConfig.PATH:
					return result
		
		# Check collision with other buildings (with larger spacing)
		for other in placed_buildings:
			if building_rect.grow(3).intersects(other):
				return result
		
		build_house_from_data(house_data)
		zone.buildings.append(house_data)
		
		result.success = true
		result.rect = building_rect
		result.door = door_pos
		return result
		

func build_house_from_data(data):
	# Floor
	for cell in data.floor_cells:
		ground_layer.set_cell(cell, TileConfig.SOURCE_ID, TileConfig.FLOOR)
		
	# Walls (Autotiling based on Outside Borders)
	var wall_set = {}
	for cell in data.wall_cells: wall_set[cell] = true
	
	var floor_set = {}
	for cell in data.floor_cells: floor_set[cell] = true
		
	for cell in data.wall_cells:
		var border_mask = 0
		
		# Check neighbors: If NOT Wall and NOT Floor, it's Outside (Border)
		var top = cell + Vector2i(0, -1)
		var right = cell + Vector2i(1, 0)
		var bottom = cell + Vector2i(0, 1)
		var left = cell + Vector2i(-1, 0)
		
		if not wall_set.has(top) and not floor_set.has(top): border_mask += 1
		if not wall_set.has(right) and not floor_set.has(right): border_mask += 2
		if not wall_set.has(bottom) and not floor_set.has(bottom): border_mask += 4
		if not wall_set.has(left) and not floor_set.has(left): border_mask += 8
		
		var coords = TileConfig.get_wall_tile(border_mask)
		wall_layer.set_cell(cell, TileConfig.SOURCE_ID, coords)
	
	# Door
	wall_layer.set_cell(data.door_position, TileConfig.SOURCE_ID, TileConfig.DOOR)
	
	# NPC
	spawn_npc(data.npc_position)

func spawn_npc(pos: Vector2):
	var npc = npc_scene.instantiate()
	npc.position = pos * TileConfig.TILE_SIZE
	add_child(npc)
	npcs.append(npc)
