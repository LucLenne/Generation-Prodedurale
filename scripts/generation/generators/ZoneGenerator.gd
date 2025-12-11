## Génère les zones/villages sur la carte.
## Supporte 3 formes : rectangulaire, circulaire, et organique.
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


## Génère les points de départ des zones via Poisson Disk Sampling.
func generate_seeds(data: MapData) -> Array[Vector2i]:
	var seeds: Array[Vector2i] = []
	var zone_count = randi_range(zone_count_range.x, zone_count_range.y)
	var max_attempts = zone_count * 100
	
	for i in range(max_attempts):
		if seeds.size() >= zone_count:
			break
			
		var candidate = Vector2i(
			randi_range(10, data.width - 10),
			randi_range(10, data.height - 10)
		)
		
		# Vérifie la distance minimale avec les seeds existantes
		var valid = true
		for existing in seeds:
			if candidate.distance_to(existing) < min_zone_distance:
				valid = false
				break
		
		if valid:
			seeds.append(candidate)
	
	return seeds


## Génère toutes les zones à partir des seeds.
func generate_zones(data: MapData, seeds: Array[Vector2i]):
	print("Generating zones...")
	data.zones.clear()
	var all_zone_cells = {}
	
	var zone_id = 0
	for seed in seeds:
		var target_size = randi_range(zone_size_range.x, zone_size_range.y)
		var biome = data.get_biome_at(seed.x, seed.y)
		
		var zone = _grow_zone(data, zone_id, seed, target_size, all_zone_cells, biome)
		
		if zone.get_size() > 10:
			data.zones.append(zone)
			
			# Marque les cellules + buffer
			for cell in zone.cells:
				all_zone_cells[cell] = zone_id
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						var buffer_cell = cell + Vector2i(dx, dy)
						if not all_zone_cells.has(buffer_cell):
							all_zone_cells[buffer_cell] = -1
			
			_carve_zone(data, zone, biome)
			zone_id += 1
	
	_identify_entrances(data.zones)
	print("Generated %d zones" % data.zones.size())


## Fait grandir une zone selon la forme définie par le biome.
func _grow_zone(data: MapData, zone_id: int, seed: Vector2i, target_size: int, existing: Dictionary, biome: BiomeResource) -> Zone:
	match biome.zone_shape:
		BiomeResource.ZoneShape.RECTANGULAR:
			return _grow_rectangular(data, zone_id, seed, target_size, existing)
		BiomeResource.ZoneShape.CIRCULAR:
			return _grow_circular(data, zone_id, seed, target_size, existing)
		_:
			return _grow_organic(data, zone_id, seed, target_size, existing)


## Creuse la zone (retire les arbres, place le sol).
func _carve_zone(data: MapData, zone: Zone, biome: BiomeResource):
	var boundary = zone.get_boundary_cells()
	var boundary_set = {}
	for cell in boundary:
		boundary_set[cell] = true
	
	for cell in zone.cells:
		# Préserve l'eau
		if TileConfig.is_water(data.wall_layer.get_cell_atlas_coords(cell)):
			continue
		
		# Garde certains arbres en bordure
		if boundary_set.has(cell) and randf() < biome.border_tree_density:
			continue
		
		var biome_at = data.get_biome_at(cell.x, cell.y)
		data.wall_layer.set_cell(cell, -1)
		
		if biome_at:
			var tile = biome_at.dirt_tile if randf() < zone_dirt_ratio else biome_at.ground_tile
			data.ground_layer.set_cell(cell, TileConfig.SOURCE_ID, tile)
	
	_process_outer_border(data, zone, boundary_set, biome)


## Traite la bordure extérieure de la zone.
func _process_outer_border(data: MapData, zone: Zone, boundary_set: Dictionary, biome: BiomeResource):
	var outer_cells = {}
	
	for cell in boundary_set:
		var neighbors = [
			cell + Vector2i(0, -1), cell + Vector2i(1, 0),
			cell + Vector2i(0, 1), cell + Vector2i(-1, 0)
		]
		for neighbor in neighbors:
			if not boundary_set.has(neighbor) and not zone.is_point_inside(neighbor):
				if data.is_in_bounds(neighbor.x, neighbor.y):
					outer_cells[neighbor] = true
	
	for cell in outer_cells:
		if randf() > biome.border_tree_density:
			data.wall_layer.set_cell(cell, -1)
			var biome_at = data.get_biome_at(cell.x, cell.y)
			if biome_at:
				data.ground_layer.set_cell(cell, TileConfig.SOURCE_ID, biome_at.dirt_tile)


## Identifie les entrées de chaque zone.
func _identify_entrances(zones: Array):
	for zone in zones:
		var boundary = zone.get_boundary_cells()
		var count = randi_range(entrance_count_range.x, entrance_count_range.y)
		boundary.shuffle()
		for i in range(min(count, boundary.size())):
			zone.entrances.append(boundary[i])


# =============================================================================
# FORMES DE ZONES
# =============================================================================

## Zone rectangulaire.
func _grow_rectangular(data: MapData, zone_id: int, seed: Vector2i, target_size: int, existing: Dictionary) -> Zone:
	var zone = ZoneScript.new(zone_id, seed)
	if existing.has(seed):
		return zone
	
	var aspect = randf_range(0.5, 2.0)
	var h = int(sqrt(target_size / aspect))
	var w = int(h * aspect)
	
	for x in range(seed.x - w/2, seed.x + w/2 + 1):
		for y in range(seed.y - h/2, seed.y + h/2 + 1):
			var cell = Vector2i(x, y)
			if data.is_in_bounds(cell.x, cell.y) and not existing.has(cell):
				zone.add_cell(cell)
	
	return zone


## Zone circulaire/elliptique.
func _grow_circular(data: MapData, zone_id: int, seed: Vector2i, target_size: int, existing: Dictionary) -> Zone:
	var zone = ZoneScript.new(zone_id, seed)
	if existing.has(seed):
		return zone
	
	var radius = sqrt(target_size / PI)
	var ratio = randf_range(0.7, 1.3)
	var rx = radius * ratio
	var ry = radius / ratio
	
	for x in range(int(seed.x - rx - 1), int(seed.x + rx + 2)):
		for y in range(int(seed.y - ry - 1), int(seed.y + ry + 2)):
			var cell = Vector2i(x, y)
			if not data.is_in_bounds(cell.x, cell.y) or existing.has(cell):
				continue
			
			var dx = float(cell.x - seed.x) / rx
			var dy = float(cell.y - seed.y) / ry
			if dx*dx + dy*dy <= 1.0:
				zone.add_cell(cell)
	
	return zone


## Zone organique (croissance par flood-fill pondéré).
func _grow_organic(data: MapData, zone_id: int, seed: Vector2i, target_size: int, existing: Dictionary) -> Zone:
	var zone = ZoneScript.new(zone_id, seed)
	if existing.has(seed):
		return zone
	
	var candidates = {seed: 1000.0}
	var visited = {}
	var aspect = randf_range(0.5, 2.0)
	
	while zone.get_size() < target_size and candidates.size() > 0:
		# Trouve le meilleur candidat
		var best_cell = Vector2i.ZERO
		var best_score = -999999.0
		for cell in candidates:
			if candidates[cell] > best_score:
				best_score = candidates[cell]
				best_cell = cell
		
		candidates.erase(best_cell)
		zone.add_cell(best_cell)
		visited[best_cell] = true
		
		# Ajoute les voisins comme candidats
		var neighbors = [
			best_cell + Vector2i(0, -1), best_cell + Vector2i(1, 0),
			best_cell + Vector2i(0, 1), best_cell + Vector2i(-1, 0)
		]
		# Parfois ajoute les diagonales
		if randf() < 0.4:
			neighbors.append_array([
				best_cell + Vector2i(1, -1), best_cell + Vector2i(1, 1),
				best_cell + Vector2i(-1, 1), best_cell + Vector2i(-1, -1)
			])
		
		for neighbor in neighbors:
			if visited.has(neighbor) or candidates.has(neighbor):
				continue
			if not data.is_in_bounds(neighbor.x, neighbor.y) or existing.has(neighbor):
				continue
			
			# Score basé sur distance + bruit
			var dx = abs(neighbor.x - seed.x)
			var dy = abs(neighbor.y - seed.y)
			var dist = max(dx, dy * aspect)
			var noise = data.noise.get_noise_2d(neighbor.x * 0.1, neighbor.y * 0.1)
			candidates[neighbor] = -dist + noise * 5.0
	
	return _smooth_zone(zone)


## Lisse la zone via automate cellulaire simple.
func _smooth_zone(zone: Zone) -> Zone:
	var cell_set = {}
	for c in zone.cells:
		cell_set[c] = true
	
	var new_cells = []
	for c in zone.cells:
		var neighbors = 0
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				if cell_set.has(c + Vector2i(dx, dy)):
					neighbors += 1
		
		# Garde si au moins 3 voisins
		if neighbors >= 3:
			new_cells.append(c)
	
	zone.cells = new_cells
	return zone
