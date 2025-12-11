## Place les bâtiments et décorations dans les zones.
## Gère les maisons préfabriquées et procédurales, ainsi que les décos.
class_name StructurePlacer extends RefCounted

const HouseGenScript = preload("res://scripts/generation/HouseGenerator.gd")
const TileConfigScript = preload("res://scripts/generation/TileConfig.gd")
const TombstoneScene = preload("res://scenes/Tombstone/Tombstone.tscn")
const NPCWithoutDialogueScene = preload("res://scenes/Tombstone/NPCWithoutDialogue.tscn")

var building_count_range: Vector2i
var tombstone_count_range: Vector2i
var npc_without_dialogue_count_range: Vector2i


func _init(count_range: Vector2i, tombstone_range: Vector2i = Vector2i(5, 15), npc_wd_range: Vector2i = Vector2i(3, 10)):
	building_count_range = count_range
	tombstone_count_range = tombstone_range
	npc_without_dialogue_count_range = npc_wd_range


## Place tous les éléments (bâtiments puis décorations).
func generate(data: MapData, parent_node: Node2D):
	place_buildings(data, parent_node)
	place_decorations_global(data, parent_node)


## Place les bâtiments dans chaque zone.
func place_buildings(data: MapData, parent: Node2D):
	print("Populating zones (Buildings)...")
	
	for zone in data.zones:
		var biome = data.get_biome_at(zone.center.x, zone.center.y)
		var house_scenes: Array[PackedScene] = []
		if biome and not biome.house_scenes.is_empty():
			house_scenes = biome.house_scenes
		
		var count = randi_range(building_count_range.x, building_count_range.y)
		var placed: Array[Rect2i] = []
		var doors: Array[Vector2i] = []
		
		for i in range(count):
			if zone.cells.is_empty():
				continue
			
			# Essaie de placer un bâtiment
			for attempt in range(100):
				var cell = zone.cells.pick_random()
				if data.ground_layer.get_cell_atlas_coords(cell) == TileConfigScript.PATH:
					continue
				
				var use_procedural = biome.use_procedural_buildings if biome else false
				var result = _try_place_building(data, zone, cell, placed, parent, house_scenes, use_procedural)
				
				if result.success:
					placed.append(result.rect)
					doors.append(result.door)
					
					# Marque les cellules comme occupées
					if result.has("actual_cells"):
						for c in result.actual_cells:
							data.reserved_cells[c] = true
					else:
						for x in range(result.rect.position.x, result.rect.end.x):
							for y in range(result.rect.position.y, result.rect.end.y):
								data.reserved_cells[Vector2i(x, y)] = true
					break
		
		# Connecte les portes aux chemins
		_connect_doors_to_paths(data, zone, doors)
		zone.set_meta("building_doors", doors)


## Place les décorations dans toutes les zones.
func place_decorations_global(data: MapData, parent: Node2D):
	print("Populating zones (Decorations)...")
	for zone in data.zones:
		_place_decorations(data, zone, parent)


# =============================================================================
# PLACEMENT DE BÂTIMENTS
# =============================================================================

## Tente de placer un bâtiment à une position donnée.
func _try_place_building(data: MapData, zone: Zone, pos: Vector2i, placed: Array[Rect2i], parent: Node2D, scenes: Array[PackedScene], force_procedural: bool) -> Dictionary:
	var result = {"success": false, "rect": Rect2i(), "door": Vector2i()}
	
	# Détermine le type de placement
	var use_scene = not force_procedural and scenes.size() > 0
	if not use_scene and not force_procedural:
		return result
	
	if use_scene:
		return _place_scene_building(data, zone, pos, placed, parent, scenes)
	else:
		return _place_procedural_building(data, zone, pos, placed)


## Place un bâtiment préfabriqué (scène).
func _place_scene_building(data: MapData, zone: Zone, pos: Vector2i, placed: Array[Rect2i], parent: Node2D, scenes: Array[PackedScene]) -> Dictionary:
	var result = {"success": false, "rect": Rect2i(), "door": Vector2i()}
	
	var scene = scenes.pick_random()
	if scene == null:
		return result
	
	# Analyse la scène pour obtenir sa taille
	var temp = scene.instantiate()
	var building_size = Vector2i(5, 5)
	var offset = Vector2i.ZERO
	var local_door = Vector2i(2, 4)
	var actual_cells: Array[Vector2i] = []
	
	# 1. Essaie TileMapLayer d'abord
	var tile_layer = _find_tile_layer(temp)
	if tile_layer:
		var rect = tile_layer.get_used_rect()
		if rect.has_area():
			building_size = rect.size
			offset = rect.position
			for cell in tile_layer.get_used_cells():
				var world_cell = pos + (cell - offset)
				actual_cells.append(world_cell)
				# Détecte toutes les variantes de portes
				var atlas = tile_layer.get_cell_atlas_coords(cell)
				if TileConfigScript.is_door(atlas):
					local_door = cell
	
	# 2. Sinon, essaie de détecter via Sprite2D
	if actual_cells.is_empty():
		var sprite = _find_sprite(temp)
		if sprite and sprite.texture:
			# Convertit la taille du sprite en tuiles
			var tex_size = sprite.texture.get_size()
			building_size = Vector2i(
				ceil(tex_size.x / TileConfigScript.TILE_SIZE),
				ceil(tex_size.y / TileConfigScript.TILE_SIZE)
			)
			# Centre le sprite
			offset = Vector2i(-building_size.x / 2, -building_size.y / 2)
	
	# 3. Fallback : génère les cellules à partir de la taille calculée
	if actual_cells.is_empty():
		for x in range(building_size.x):
			for y in range(building_size.y):
				actual_cells.append(pos + Vector2i(x, y) + offset)
	
	temp.free()
	
	# Validation avec buffer autour de la map
	var building_rect = Rect2i(pos + offset, building_size)
	if not _validate_placement(data, zone, actual_cells, placed, building_rect):
		return result
	
	# Place la scène
	var instance = scene.instantiate()
	instance.position = Vector2(pos + offset) * TileConfigScript.TILE_SIZE
	parent.add_child(instance)
	if parent.has_method("register_generated_object"):
		parent.register_generated_object(instance)
	zone.buildings.append(instance)
	
	# Génère les collisions pour le bâtiment instancié
	_add_collision_to_building(instance)
	
	result.success = true
	result.rect = building_rect
	result.door = pos + (local_door - offset)
	result.actual_cells = actual_cells
	return result


## Place un bâtiment procédural.
func _place_procedural_building(data: MapData, zone: Zone, pos: Vector2i, placed: Array[Rect2i]) -> Dictionary:
	var result = {"success": false, "rect": Rect2i(), "door": Vector2i()}
	
	var house_data = HouseGenScript.generate_random_house(pos)
	var building_rect = house_data.rect
	
	# Valide toutes les cellules
	for x in range(building_rect.position.x, building_rect.end.x):
		for y in range(building_rect.position.y, building_rect.end.y):
			var cell = Vector2i(x, y)
			if not _is_cell_valid(data, zone, cell):
				return result
	
	for other in placed:
		if building_rect.grow(5).intersects(other):
			return result
	
	# Construit la maison
	_build_procedural_house(data, house_data)
	zone.buildings.append(house_data)
	
	result.success = true
	result.rect = building_rect
	result.door = house_data.door_position
	return result


## Valide le placement d'un bâtiment.
func _validate_placement(data: MapData, zone: Zone, cells: Array[Vector2i], placed: Array[Rect2i], rect: Rect2i) -> bool:
	# 1. Verification stricte des limites du rectangle entier
	const EDGE_BUFFER = 15
	if rect.position.x < EDGE_BUFFER or rect.end.x >= data.width - EDGE_BUFFER:
		return false
	if rect.position.y < EDGE_BUFFER or rect.end.y >= data.height - EDGE_BUFFER:
		return false
	
	# Vérifie collision avec autres bâtiments
	for other in placed:
		if rect.grow(3).intersects(other):
			return false
			
	# Vérifie CHAQUE cellule du rectangle (Rect Validation)
	# On s'assure que tout l'espace du bâtiment (y compris trous/jardins) est valide et sans obstacles
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var cell = Vector2i(x, y)
			if not _is_cell_valid(data, zone, cell):
				return false
	
	return true


## Vérifie si une cellule est valide pour un bâtiment.
func _is_cell_valid(data: MapData, zone: Zone, cell: Vector2i) -> bool:
	if not data.is_in_bounds(cell.x, cell.y):
		return false
	if not zone.is_point_inside(cell):
		return false
	if data.reserved_cells.has(cell):
		return false
	
	var biome = data.get_biome_at(cell.x, cell.y)
	if not biome:
		return false
	
	# 0. Safety Check: Vérification explicite des tuiles interdites
	# (Au cas où l'allowlist serait trop permissive ou incomplète)
	var wall_safety = data.wall_layer.get_cell_atlas_coords(cell)
	if TileConfigScript.TREE_VARIANTS.has(wall_safety): return false
	if TileConfigScript.WATER_VARIANTS.has(wall_safety): return false
	
	var ground_safety = data.ground_layer.get_cell_atlas_coords(cell)
	if TileConfigScript.PATH_VARIANTS.has(ground_safety): return false
	
	# 1. Vérifie WALL LAYER (Doit être vide: ni arbre, ni eau, ni mur)
	if data.wall_layer.get_cell_source_id(cell) != -1:
		return false
		
	# 2. Vérifie GROUND LAYER (Doit être sol naturel: herbe ou terre)
	var ground = data.ground_layer.get_cell_atlas_coords(cell)
	if not _is_valid_ground(ground, biome):
		return false
		
	return true


## Vérifie si une tuile de sol est valide (base ou variante).
func _is_valid_ground(tile: Vector2i, biome: BiomeResource) -> bool:
	# Vérifie les bases du biome
	if tile == biome.ground_tile: return true
	if tile == biome.dirt_tile: return true
	
	# Vérifie les variantes globales si elles correspondent au type du biome
	# (Si l'herbe du biome est l'herbe standard, alors on accepte toutes les variantes d'herbe standard)
	if biome.ground_tile == TileConfigScript.GRASS:
		if TileConfigScript.GRASS_VARIANTS.has(tile): return true
		
	if biome.dirt_tile == TileConfigScript.DIRT:
		if TileConfigScript.DIRT_VARIANTS.has(tile): return true
		
	return false

## Place des bordures d'arbres tout autour de la map.
func place_map_borders(data: MapData):
	print("StructurePlacer: Placing Map Borders...")
	var w = data.width
	var h = data.height
	
	var border_cells = []
	
	# Haut et Bas
	for x in range(w):
		border_cells.append(Vector2i(x, 0))
		border_cells.append(Vector2i(x, h - 1))
		
	# Gauche et Droite
	for y in range(1, h - 1): # On évite les coins déjà faits
		border_cells.append(Vector2i(0, y))
		border_cells.append(Vector2i(w - 1, y))
		
	for cell in border_cells:
		# Force Grass underneath
		data.ground_layer.set_cell(cell, TileConfigScript.SOURCE_ID, TileConfigScript.GRASS)
		# Place Tree Wall
		data.wall_layer.set_cell(cell, TileConfigScript.SOURCE_ID, TileConfigScript.TREE)
		# Mark reserved to ensure nothing else spawns here (though it's post-gen usually)
		data.reserved_cells[cell] = true


## Trouve le TileMapLayer dans une scène.
func _find_tile_layer(node: Node) -> Node:
	var layer = node.get_node_or_null("TileMapLayer")
	if layer:
		return layer
	
	for child in node.get_children():
		if child is TileMapLayer or child is TileMap:
			return child
	
	return null


## Trouve le Sprite2D principal dans une scène.
func _find_sprite(node: Node) -> Sprite2D:
	for child in node.get_children():
		if child is Sprite2D:
			return child
	
	# Cherche récursivement
	for child in node.get_children():
		var found = _find_sprite(child)
		if found:
			return found
	
	return null


## Construit une maison procédurale.
func _build_procedural_house(data: MapData, house_data):
	# Sol
	for cell in house_data.floor_cells:
		data.ground_layer.set_cell(cell, TileConfigScript.SOURCE_ID, TileConfigScript.FLOOR)
	
	# Murs avec autotiling
	var wall_set = {}
	var floor_set = {}
	for cell in house_data.wall_cells:
		wall_set[cell] = true
	for cell in house_data.floor_cells:
		floor_set[cell] = true
	
	for cell in house_data.wall_cells:
		var mask = 0
		var top = cell + Vector2i(0, -1)
		var right = cell + Vector2i(1, 0)
		var bottom = cell + Vector2i(0, 1)
		var left = cell + Vector2i(-1, 0)
		
		if not wall_set.has(top) and not floor_set.has(top): mask += 1
		if not wall_set.has(right) and not floor_set.has(right): mask += 2
		if not wall_set.has(bottom) and not floor_set.has(bottom): mask += 4
		if not wall_set.has(left) and not floor_set.has(left): mask += 8
		
		var tile = TileConfigScript.get_wall_tile(mask)
		data.wall_layer.set_cell(cell, TileConfigScript.SOURCE_ID, tile)
	
	# Porte
	data.wall_layer.set_cell(house_data.door_position, TileConfigScript.SOURCE_ID, TileConfigScript.DOOR)
	
	# Queue pour spawn PNJ
	if not data.has_meta("pending_npc_spawns"):
		data.set_meta("pending_npc_spawns", [])
	data.get_meta("pending_npc_spawns").append(house_data.npc_position)


# =============================================================================
# CONNEXION DES PORTES
# =============================================================================

## Connecte les portes aux chemins via A*.
func _connect_doors_to_paths(data: MapData, zone: Zone, doors: Array[Vector2i]):
	# Trouve les cellules de chemin dans la zone
	var path_cells: Array[Vector2i] = []
	for cell in zone.cells:
		if data.ground_layer.get_cell_atlas_coords(cell) == TileConfigScript.PATH:
			path_cells.append(cell)
	
	if path_cells.is_empty():
		path_cells = zone.entrances.duplicate()
	
	# Configure A*
	var astar = AStarGrid2D.new()
	astar.region = zone.shape_bounds.grow(10)
	astar.cell_size = Vector2(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	# Pénalise l'eau mais ne bloque pas
	for x in range(astar.region.position.x, astar.region.end.x):
		for y in range(astar.region.position.y, astar.region.end.y):
			var cell = Vector2i(x, y)
			if data.is_in_bounds(x, y) and TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(cell)):
				astar.set_point_weight_scale(cell, 10.0)
	
	# Connecte chaque porte
	for door in doors:
		# 1. Dégage la zone devant la porte (3x3)
		_clear_door_area(data, door, zone)
		
		# 2. Trouve le chemin vers la porte
		astar.set_point_solid(door, false)
		var nearest = _find_nearest_path_cell(door, path_cells, zone.center)
		
		# Débloque les points sur le chemin potentiel
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				var p = door + Vector2i(dx, dy)
				if astar.is_in_boundsv(p):
					astar.set_point_solid(p, false)
		
		var path = astar.get_id_path(nearest, door)
		
		# 3. Creuse le chemin
		_carve_door_path(data, path, path_cells)
	
	zone.set_meta("path_cells", path_cells)


## Dégage la zone devant une porte.
func _clear_door_area(data: MapData, door: Vector2i, _zone: Zone):
	var biome = data.get_biome_at(door.x, door.y)
	
	# Dégage une zone 5x5 autour de la porte (toutes directions)
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			# Ignore la porte elle-même
			if dx == 0 and dy == 0:
				continue
			
			var pos = door + Vector2i(dx, dy)
			
			if not data.is_in_bounds(pos.x, pos.y):
				continue
			
			# Ne dégage pas les cellules de bâtiments
			if data.reserved_cells.has(pos):
				continue
			
			# Ne touche pas à l'eau
			if TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(pos)):
				continue
			
			# Supprime les arbres/obstacles
			data.wall_layer.set_cell(pos, -1)
			
			# Place du chemin devant (2 cases), sinon de la terre
			if biome:
				if abs(dx) <= 1 and dy >= 0 and dy <= 2:
					data.ground_layer.set_cell(pos, TileConfigScript.SOURCE_ID, biome.path_tile)
				else:
					data.ground_layer.set_cell(pos, TileConfigScript.SOURCE_ID, biome.dirt_tile)


## Trouve la cellule de chemin la plus proche.
func _find_nearest_path_cell(door: Vector2i, path_cells: Array[Vector2i], fallback: Vector2i) -> Vector2i:
	if path_cells.is_empty():
		return fallback
	
	var nearest = path_cells[0]
	var min_dist = 999999.0
	for cell in path_cells:
		var dist = cell.distance_to(door)
		if dist < min_dist:
			min_dist = dist
			nearest = cell
	return nearest


## Creuse le chemin vers une porte.
func _carve_door_path(data: MapData, path: Array, path_cells: Array[Vector2i]):
	for i in range(path.size()):
		var point = path[i]
		
		# Ignore les cellules réservées sauf pour les dernières cellules (près de la porte)
		if data.reserved_cells.has(point) and i < path.size() - 3:
			continue
		
		var biome = data.get_biome_at(point.x, point.y)
		
		if TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(point)):
			# Pont sur l'eau
			data.wall_layer.set_cell(point, -1)
			data.ground_layer.set_cell(point, TileConfigScript.SOURCE_ID, TileConfigScript.BRIDGE)
		else:
			# Supprime les obstacles (arbres, etc.)
			data.wall_layer.set_cell(point, -1)
			
			# Place du chemin
			if biome:
				data.ground_layer.set_cell(point, TileConfigScript.SOURCE_ID, biome.path_tile)
		
		path_cells.append(point)


# =============================================================================
# DÉCORATIONS
# =============================================================================

## Place les décorations dans une zone.
func _place_decorations(data: MapData, zone: Zone, parent: Node2D):
	var biome = data.get_biome_at(zone.center.x, zone.center.y)
	if not biome:
		return
	
	var path_cells = zone.get_meta("path_cells", [])
	
	# Décorations scènes
	_place_decoration_scenes(data, zone, parent, biome, path_cells)
	
	# Décorations tuiles
	_place_decoration_tiles(data, zone, biome, path_cells)


## Place les scènes de décoration.
func _place_decoration_scenes(data: MapData, zone: Zone, parent: Node2D, biome: BiomeResource, path_cells: Array):
	if biome.decoration_scenes.is_empty():
		return
	
	var count = randi_range(biome.decoration_scene_count_range.x, biome.decoration_scene_count_range.y)
	
	for i in range(count):
		for attempt in range(20):
			var cell = zone.cells.pick_random()
			
			if data.reserved_cells.has(cell) or cell in path_cells:
				continue
			if TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(cell)):
				continue
			
			var scene = biome.decoration_scenes.pick_random()
			if scene == null:
				continue
			
			# Analyse la scène
			var temp = scene.instantiate()
			var offset = Vector2i.ZERO
			var actual_cells = []
			
			var tile_layer = _find_tile_layer(temp)
			if tile_layer:
				var rect = tile_layer.get_used_rect()
				if rect.has_area():
					offset = rect.position
					for u in tile_layer.get_used_cells():
						actual_cells.append(cell + (u - offset))
			temp.free()
			
			# Valide le placement
			var valid = true
			for c in actual_cells:
				if not zone.is_point_inside(c) or data.reserved_cells.has(c):
					valid = false
					break
				if c in path_cells or TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(c)):
					valid = false
					break
			
			if valid:
				var instance = scene.instantiate()
				instance.position = Vector2(cell - offset) * TileConfigScript.TILE_SIZE
				parent.add_child(instance)
				if parent.has_method("register_generated_object"):
					parent.register_generated_object(instance)
				zone.buildings.append(instance)
				for c in actual_cells:
					data.reserved_cells[c] = true
				break


## Place les tuiles de décoration.
func _place_decoration_tiles(data: MapData, zone: Zone, biome: BiomeResource, path_cells: Array):
	if biome.decorations.is_empty():
		return
	
	for cell in zone.cells:
		if data.reserved_cells.has(cell) or cell in path_cells:
			continue
		if TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(cell)):
			continue
		
		var ground = data.ground_layer.get_cell_atlas_coords(cell)
		if ground != biome.ground_tile and ground != biome.dirt_tile:
			continue
		if data.wall_layer.get_cell_source_id(cell) != -1:
			continue
		
		# Sélectionne une décoration selon sa densité
		var roll = randf()
		var acc = 0.0
		for deco in biome.decorations:
			acc += deco.density
			if roll < acc:
				data.wall_layer.set_cell(cell, TileConfigScript.SOURCE_ID, deco.atlas_coords)
				break


# =============================================================================
# TOMBES / TOMBSTONES
# =============================================================================

## Place des tombes aléatoirement sur la carte.
func place_tombstones(data: MapData, parent: Node2D):
	print("Populating world (Tombstones)...")
	
	var count = randi_range(tombstone_count_range.x, tombstone_count_range.y)
	var placed_count = 0
	
	# Essaie de placer le nombre désiré de tombes
	for i in range(count):
		for attempt in range(50):  # 50 tentatives par tombe
			# Sélectionne une position aléatoire sur la carte
			var x = randi_range(15, data.width - 15)
			var y = randi_range(15, data.height - 15)
			var cell = Vector2i(x, y)
			
			# Vérifie si la cellule est valide
			if not _is_tombstone_cell_valid(data, cell):
				continue
			
			# Place la tombe
			var tombstone = TombstoneScene.instantiate()
			tombstone.position = Vector2(cell) * TileConfigScript.TILE_SIZE
			parent.add_child(tombstone)
			
			if parent.has_method("register_generated_object"):
				parent.register_generated_object(tombstone)
			
			# Marque la cellule comme réservée
			data.reserved_cells[cell] = true
			placed_count += 1
			break
	
	print("Placed %d tombstones on the map." % placed_count)


## Vérifie si une cellule est valide pour placer une tombe.
func _is_tombstone_cell_valid(data: MapData, cell: Vector2i) -> bool:
	if not data.is_in_bounds(cell.x, cell.y):
		return false
	
	# Cellule déjà réservée
	if data.reserved_cells.has(cell):
		return false
	
	# Vérifie le mur layer (doit être vide)
	if data.wall_layer.get_cell_source_id(cell) != -1:
		return false
	
	# Vérifie si c'est une tuile de chemin (évite de bloquer les routes)
	var ground = data.ground_layer.get_cell_atlas_coords(cell)
	if TileConfigScript.PATH_VARIANTS.has(ground):
		return false
	if ground == TileConfigScript.PATH:
		return false
	
	# Vérifie que c'est bien de l'herbe ou de la terre
	var biome = data.get_biome_at(cell.x, cell.y)
	if biome:
		if ground != biome.ground_tile and ground != biome.dirt_tile:
			# Vérifie les variantes de grass/dirt
			if not TileConfigScript.GRASS_VARIANTS.has(ground) and not TileConfigScript.DIRT_VARIANTS.has(ground):
				return false
	
	return true


# =============================================================================
# NPC SANS DIALOGUE
# =============================================================================

## Place des NPC sans dialogue aléatoirement sur la carte.
func place_npcs_without_dialogue(data: MapData, parent: Node2D):
	print("Populating world (NPCs Without Dialogue)...")
	
	var count = randi_range(npc_without_dialogue_count_range.x, npc_without_dialogue_count_range.y)
	var placed_count = 0
	
	for i in range(count):
		for attempt in range(50):
			var x = randi_range(15, data.width - 15)
			var y = randi_range(15, data.height - 15)
			var cell = Vector2i(x, y)
			
			# Réutilise la même validation que pour les tombes
			if not _is_tombstone_cell_valid(data, cell):
				continue
			
			var npc = NPCWithoutDialogueScene.instantiate()
			npc.position = Vector2(cell) * TileConfigScript.TILE_SIZE
			parent.add_child(npc)
			
			if parent.has_method("register_generated_object"):
				parent.register_generated_object(npc)
			
			data.reserved_cells[cell] = true
			placed_count += 1
			break
	

	print("Placed %d NPCs without dialogue on the map." % placed_count)


## Ajoute des collisions physiques aux tuiles de murs d'un bâtiment
func _add_collision_to_building(building_node: Node2D):
	var tile_layer = _find_tile_layer(building_node)
	if not tile_layer:
		return

	# Crée un conteneur pour les collisions
	var static_body = StaticBody2D.new()
	static_body.name = "GeneratedCollision"
	building_node.add_child(static_body)
	
	var shape = RectangleShape2D.new()
	shape.size = Vector2(TileConfigScript.TILE_SIZE, TileConfigScript.TILE_SIZE)
	
	for cell in tile_layer.get_used_cells():
		var atlas_coords = tile_layer.get_cell_atlas_coords(cell)
		
		# On ne met pas de collision sur le SOL ni sur la porte (gérée par ailleurs)
		if atlas_coords == TileConfigScript.FLOOR: continue
		if atlas_coords == TileConfigScript.GRASS: continue
		if atlas_coords == TileConfigScript.DIRT: continue
		if TileConfigScript.is_door(atlas_coords): continue
		
		# Sinon (Mur, Meuble, Toit...), on ajoute une collision
		var col = CollisionShape2D.new()
		col.shape = shape
		# Centrer la collision sur la tuile (coordonnées locales au TileMapLayer)
		col.position = tile_layer.map_to_local(cell)
		static_body.add_child(col)
