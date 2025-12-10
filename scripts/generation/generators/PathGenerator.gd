class_name PathGenerator extends RefCounted

const TileConfigScript = preload("res://scripts/generation/TileConfig.gd")


var path_width: int
var path_smoothness: float
var path_edge_grass_ratio: float
var path_edge_dirt_ratio: float

func _init(width_val: int, smoothness: float, grass_ratio: float, dirt_ratio: float):
	path_width = width_val
	path_smoothness = smoothness
	path_edge_grass_ratio = grass_ratio
	path_edge_dirt_ratio = dirt_ratio

func generate(data: MapData):
	print("Connecting zones...")
	build_zone_graph(data)
	
	var mst_edges = build_minimum_spanning_tree(data)
	
	for edge in mst_edges:
		carve_path_between_zones(data, edge.from_zone, edge.to_zone)
	
	print("Connected %d zone pairs" % mst_edges.size())

func build_zone_graph(data: MapData):
	data.zone_graph.clear()
	for i in range(data.zones.size()):
		data.zone_graph[i] = []
		for j in range(i + 1, data.zones.size()):
			var dist = data.zones[i].center.distance_to(data.zones[j].center)
			if dist < 80:
				data.zone_graph[i].append({"to": j, "dist": dist})

func build_minimum_spanning_tree(data: MapData) -> Array:
	var edges = []
	for from_id in data.zone_graph:
		for edge in data.zone_graph[from_id]:
			edges.append({"from": from_id, "to": edge.to, "dist": edge.dist})
	
	edges.sort_custom(func(a, b): return a.dist < b.dist)
	
	var parent = {}
	for i in range(data.zones.size()):
		parent[i] = i
		
	var mst_edges = []
	for edge in edges:
		var root_from = _find_root(parent, edge.from)
		var root_to = _find_root(parent, edge.to)
		
		if root_from != root_to:
			parent[root_from] = root_to
			mst_edges.append({"from_zone": data.zones[edge.from], "to_zone": data.zones[edge.to]})
			
	# Add extra loops (20%)
	var extra_count = max(1, int(mst_edges.size() * 0.2))
	for i in range(extra_count):
		if i < edges.size():
			var edge = edges[i]
			# Check if not already added? Logic in original was raw index; we'll trust original logic roughly
			mst_edges.append({"from_zone": data.zones[edge.from], "to_zone": data.zones[edge.to]})
			
	return mst_edges

func _find_root(parent, i):
	while parent[i] != i:
		parent[i] = parent[parent[i]]
		i = parent[i]
	return i

func carve_path_between_zones(data: MapData, zone_a: Zone, zone_b: Zone):
	var start = zone_a.get_random_entrance()
	var end = zone_b.get_random_entrance()
	
	# Waypoints
	var waypoints: Array[Vector2i] = [start]
	var num_waypoints = randi_range(1, 3)
	
	for i in range(num_waypoints):
		var t = (i + 1.0) / (num_waypoints + 1.0)
		var lerp_pos = Vector2(start).lerp(Vector2(end), t)
		var direction = (Vector2(end) - Vector2(start)).normalized()
		var perpendicular = Vector2(-direction.y, direction.x)
		var deviation = data.noise.get_noise_2d(i * 100, zone_a.id * 50) * 5.0
		
		var waypoint = Vector2i(lerp_pos + perpendicular * deviation)
		waypoint.x = clamp(waypoint.x, 5, data.width - 5)
		waypoint.y = clamp(waypoint.y, 5, data.height - 5)
		waypoints.append(waypoint)
	waypoints.append(end)
	
	# A*
	var astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, data.width, data.height)
	astar.cell_size = Vector2(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	for x in range(data.width):
		for y in range(data.height):
			var cell = Vector2i(x, y)
			if TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(cell)):
				astar.set_point_weight_scale(cell, 10.0)
	
	var full_path: Array[Vector2i] = []
	for i in range(waypoints.size() - 1):
		var segment = astar.get_id_path(waypoints[i], waypoints[i+1])
		full_path.append_array(segment)
		
	# Process path
	var processed_edge_cells = {}
	for i in range(full_path.size()):
		var point = full_path[i]
		# Noise curve - Removed for cleaner paths
		var curved_point = point

			
		# Carve
		var local_width = path_width + int(data.noise.get_noise_2d(curved_point.x * 0.2, curved_point.y * 0.2) * 1.0)
		local_width = clamp(local_width, 1, path_width + 2)
		
		for dx in range(-local_width / 2, local_width / 2 + 1):
			for dy in range(-local_width / 2, local_width / 2 + 1):
				var cell = curved_point + Vector2i(dx, dy)
				if data.is_in_bounds(cell.x, cell.y):
					if TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(cell)):
						data.wall_layer.set_cell(cell, -1)
						data.ground_layer.set_cell(cell, TileConfigScript.SOURCE_ID, TileConfigScript.BRIDGE)
					else:
						var biome = data.get_biome_at(cell.x, cell.y)
						data.wall_layer.set_cell(cell, -1)
						data.ground_layer.set_cell(cell, TileConfigScript.SOURCE_ID, biome.path_tile)

		# Edge Transitions - Simplified
		for dx in range(-local_width / 2 - 1, local_width / 2 + 2):
			for dy in range(-local_width / 2 - 1, local_width / 2 + 2):
				if abs(dx) <= local_width/2 and abs(dy) <= local_width/2: continue
				
				var side_cell = curved_point + Vector2i(dx, dy)
				if processed_edge_cells.has(side_cell): continue
				
				if data.is_in_bounds(side_cell.x, side_cell.y):
					if TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(side_cell)): continue
					
					var current_wall = data.wall_layer.get_cell_source_id(side_cell)
					var current_ground = data.ground_layer.get_cell_atlas_coords(side_cell)
					var biome = data.get_biome_at(side_cell.x, side_cell.y)
					
					if current_wall != -1 or current_ground == biome.ground_tile:
						var rand_val = randf()
						if rand_val < path_edge_grass_ratio:
							data.wall_layer.set_cell(side_cell, -1)
							data.ground_layer.set_cell(side_cell, TileConfigScript.SOURCE_ID, biome.ground_tile)
						elif rand_val < path_edge_grass_ratio + path_edge_dirt_ratio:
							data.wall_layer.set_cell(side_cell, -1)
							data.ground_layer.set_cell(side_cell, TileConfigScript.SOURCE_ID, biome.dirt_tile)
						else:
							data.wall_layer.set_cell(side_cell, TileConfigScript.SOURCE_ID, biome.wall_tile)
							data.ground_layer.set_cell(side_cell, TileConfigScript.SOURCE_ID, biome.ground_tile)
						processed_edge_cells[side_cell] = true
