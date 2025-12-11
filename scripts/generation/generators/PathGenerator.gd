## Génère les chemins entre les zones.
## Utilise un arbre couvrant minimum (MST) pour connecter toutes les zones.
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


## Génère tous les chemins entre les zones.
func generate(data: MapData):
	print("Connecting zones...")
	
	_build_zone_graph(data)
	var mst_edges = _build_mst(data)
	
	for edge in mst_edges:
		_carve_path(data, edge.from_zone, edge.to_zone)
	
	print("Connected %d zone pairs" % mst_edges.size())


## Construit le graphe de proximité entre zones.
func _build_zone_graph(data: MapData):
	data.zone_graph.clear()
	for i in range(data.zones.size()):
		data.zone_graph[i] = []
		for j in range(i + 1, data.zones.size()):
			var dist = data.zones[i].center.distance_to(data.zones[j].center)
			if dist < 80:
				data.zone_graph[i].append({"to": j, "dist": dist})


## Construit l'arbre couvrant minimum + quelques boucles.
func _build_mst(data: MapData) -> Array:
	# Collecte et trie les arêtes
	var edges = []
	for from_id in data.zone_graph:
		for edge in data.zone_graph[from_id]:
			edges.append({"from": from_id, "to": edge.to, "dist": edge.dist})
	edges.sort_custom(func(a, b): return a.dist < b.dist)
	
	# Union-Find pour le MST
	var parent = {}
	for i in range(data.zones.size()):
		parent[i] = i
	
	var mst_edges = []
	for edge in edges:
		var root_from = _find_root(parent, edge.from)
		var root_to = _find_root(parent, edge.to)
		
		if root_from != root_to:
			parent[root_from] = root_to
			mst_edges.append({
				"from_zone": data.zones[edge.from],
				"to_zone": data.zones[edge.to]
			})
	
	# Ajoute ~20% de boucles pour plus de variété
	var extra_count = max(1, int(mst_edges.size() * 0.2))
	for i in range(min(extra_count, edges.size())):
		var edge = edges[i]
		mst_edges.append({
			"from_zone": data.zones[edge.from],
			"to_zone": data.zones[edge.to]
		})
	
	return mst_edges


func _find_root(parent: Dictionary, i: int) -> int:
	while parent[i] != i:
		parent[i] = parent[parent[i]]
		i = parent[i]
	return i


## Trace un chemin entre deux zones via A*.
func _carve_path(data: MapData, zone_a: Zone, zone_b: Zone):
	var start = zone_a.get_random_entrance()
	var end = zone_b.get_random_entrance()
	
	# Crée des waypoints intermédiaires pour un tracé plus naturel
	var waypoints: Array[Vector2i] = [start]
	var num_waypoints = randi_range(1, 3)
	
	for i in range(num_waypoints):
		var t = (i + 1.0) / (num_waypoints + 1.0)
		var lerp_pos = Vector2(start).lerp(Vector2(end), t)
		
		# Déviation perpendiculaire
		var direction = (Vector2(end) - Vector2(start)).normalized()
		var perp = Vector2(-direction.y, direction.x)
		var deviation = data.noise.get_noise_2d(i * 100, zone_a.id * 50) * 5.0
		
		var waypoint = Vector2i(lerp_pos + perp * deviation)
		waypoint.x = clamp(waypoint.x, 5, data.width - 5)
		waypoint.y = clamp(waypoint.y, 5, data.height - 5)
		waypoints.append(waypoint)
	
	waypoints.append(end)
	
	# Configure A*
	var astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, data.width, data.height)
	astar.cell_size = Vector2(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	# Pénalise l'eau
	for x in range(data.width):
		for y in range(data.height):
			var cell = Vector2i(x, y)
			if TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(cell)):
				astar.set_point_weight_scale(cell, 10.0)
	
	# Trace le chemin segment par segment
	var full_path: Array[Vector2i] = []
	for i in range(waypoints.size() - 1):
		var segment = astar.get_id_path(waypoints[i], waypoints[i + 1])
		full_path.append_array(segment)
	
	# Creuse le chemin
	var processed_edges = {}
	for point in full_path:
		_carve_path_segment(data, point, processed_edges)


## Creuse un segment de chemin avec ses bords.
func _carve_path_segment(data: MapData, center: Vector2i, processed_edges: Dictionary):
	# Largeur variable via bruit
	var noise = data.noise.get_noise_2d(center.x * 0.2, center.y * 0.2)
	var local_width = clamp(path_width + int(noise), 1, path_width + 2)
	var half = local_width / 2
	
	# Creuse le chemin principal
	for dx in range(-half, half + 1):
		for dy in range(-half, half + 1):
			var cell = center + Vector2i(dx, dy)
			if not data.is_in_bounds(cell.x, cell.y):
				continue
			
			if TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(cell)):
				# Pont sur l'eau
				data.wall_layer.set_cell(cell, -1)
				data.ground_layer.set_cell(cell, TileConfigScript.SOURCE_ID, TileConfigScript.BRIDGE)
			else:
				var biome = data.get_biome_at(cell.x, cell.y)
				data.wall_layer.set_cell(cell, -1)
				data.ground_layer.set_cell(cell, TileConfigScript.SOURCE_ID, biome.path_tile)
	
	# Traite les bords
	for dx in range(-half - 1, half + 2):
		for dy in range(-half - 1, half + 2):
			if abs(dx) <= half and abs(dy) <= half:
				continue
			
			var cell = center + Vector2i(dx, dy)
			if processed_edges.has(cell) or not data.is_in_bounds(cell.x, cell.y):
				continue
			if TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(cell)):
				continue
			
			var wall_id = data.wall_layer.get_cell_source_id(cell)
			var ground = data.ground_layer.get_cell_atlas_coords(cell)
			var biome = data.get_biome_at(cell.x, cell.y)
			
			if wall_id != -1 or ground == biome.ground_tile:
				var rand = randf()
				if rand < path_edge_grass_ratio:
					data.wall_layer.set_cell(cell, -1)
					data.ground_layer.set_cell(cell, TileConfigScript.SOURCE_ID, biome.ground_tile)
				elif rand < path_edge_grass_ratio + path_edge_dirt_ratio:
					data.wall_layer.set_cell(cell, -1)
					data.ground_layer.set_cell(cell, TileConfigScript.SOURCE_ID, biome.dirt_tile)
				else:
					data.wall_layer.set_cell(cell, TileConfigScript.SOURCE_ID, biome.wall_tile)
					data.ground_layer.set_cell(cell, TileConfigScript.SOURCE_ID, biome.ground_tile)
				processed_edges[cell] = true
