## Orchestrateur principal de la génération procédurale du monde.
## Coordonne tous les générateurs et gère le pipeline de création.
class_name WorldGenerator extends Node2D

# =============================================================================
# EXPORTS
# =============================================================================

@export var width: int = 120
@export var height: int = 120

@export_group("Configuration des Zones")
@export var zone_count_range: Vector2i = Vector2i(5, 12)
@export var zone_size_range: Vector2i = Vector2i(15, 40)
@export var min_zone_distance: int = 50

@export_group("Détails des Zones")
@export var entrance_count_range: Vector2i = Vector2i(1, 4)
@export var building_count_range: Vector2i = Vector2i(2, 8)
@export_range(0.0, 1.0, 0.05) var zone_dirt_ratio: float = 0.4

@export_group("Chemins")
@export var path_width: int = 2
@export var path_smoothness: float = 0.5
@export_range(0.0, 1.0, 0.05) var path_edge_grass_ratio: float = 0.3
@export_range(0.0, 1.0, 0.05) var path_edge_dirt_ratio: float = 0.2

@export_group("Ressources")
@export var npc_scene: PackedScene
@export var player_scene: PackedScene
@export var collision_scene: PackedScene
@export var manager_quest_scene: PackedScene

@export_group("Layers")
@export var ground_layer: TileMapLayer
@export var wall_layer: TileMapLayer

@export var available_biomes: Array[BiomeResource] = []

# =============================================================================
# DONNÉES INTERNES
# =============================================================================

var map_data: MapData
var npcs: Array = []
var generated_objects: Array = []
var player_instance: Node2D = null

@onready var world_camera: CameraManager = $Camera2D

# Scripts des générateurs
const MapDataScript = preload("res://scripts/generation/MapData.gd")
const BiomeGenScript = preload("res://scripts/generation/generators/BiomeGenerator.gd")
const TerrainGenScript = preload("res://scripts/generation/generators/TerrainGenerator.gd")
const RiverGenScript = preload("res://scripts/generation/generators/RiverGenerator.gd")
const ZoneGenScript = preload("res://scripts/generation/generators/ZoneGenerator.gd")
const PathGenScript = preload("res://scripts/generation/generators/PathGenerator.gd")
const StructureGenScript = preload("res://scripts/generation/generators/StructurePlacer.gd")
const SpawnerScript = preload("res://scripts/generation/generators/EntitySpawner.gd")
const TileConfigScript = preload("res://scripts/generation/TileConfig.gd")


# =============================================================================
# INITIALISATION
# =============================================================================

func _ready():
	print("WorldGenerator _ready called.")
	
	# Scènes par défaut
	if npc_scene == null:
		npc_scene = preload("res://scenes/generation/NPC.tscn")
	if player_scene == null:
		player_scene = preload("res://scenes/Player.tscn")
	
	# Vérifie les layers
	if ground_layer == null or wall_layer == null:
		printerr("Error: TileMapLayers are not assigned!")
		return
	
	# Détecte l'ID du TileSet
	if ground_layer.tile_set and ground_layer.tile_set.get_source_count() > 0:
		TileConfigScript.SOURCE_ID = ground_layer.tile_set.get_source_id(0)
		print("Detected TileSet Source ID: ", TileConfigScript.SOURCE_ID)
	
	print("Layers assigned. Starting generation...")
	generate_world()


# =============================================================================
# GÉNÉRATION DU MONDE
# =============================================================================

## Lance la génération complète du monde.
func generate_world():
	print("Starting World Generation (Modular)...")
	
	# Initialise les données
	map_data = MapDataScript.new(width, height, ground_layer, wall_layer, randi())
	
	# Nettoie l'ancien monde
	_cleanup_world()
	
	# Crée les générateurs
	var biome_gen = BiomeGenScript.new(available_biomes)
	var terrain_gen = TerrainGenScript.new()
	var river_gen = RiverGenScript.new()
	var zone_gen = ZoneGenScript.new(zone_count_range, zone_size_range, min_zone_distance, entrance_count_range, zone_dirt_ratio)
	var path_gen = PathGenScript.new(path_width, path_smoothness, path_edge_grass_ratio, path_edge_dirt_ratio)
	var structure_gen = StructureGenScript.new(building_count_range)
	var spawner_gen = SpawnerScript.new(player_scene, npc_scene, manager_quest_scene)
	
	# Pipeline de génération
	var zone_seeds = zone_gen.generate_seeds(map_data)
	biome_gen.generate(map_data, zone_seeds)
	terrain_gen.generate(map_data)
	river_gen.generate(map_data)
	zone_gen.generate_zones(map_data, zone_seeds)
	path_gen.generate(map_data)
	
	# Spawn du manager de quêtes
	spawner_gen.spawn_manager_quest(self, self)
	
	# Structures et entités
	structure_gen.place_buildings(map_data, self)
	spawner_gen.spawn_npcs(map_data, self)
	player_instance = spawner_gen.spawn_player(map_data, self)
	
	# Génération des quêtes
	if ManagerQuest:
		ManagerQuest.generate_quests_for_world(npcs, self)
	
	# Décorations
	structure_gen.place_decorations_global(map_data, self)
	
	# Configure la caméra
	_setup_player_camera(player_instance)
	
	print("World Generation Complete.")


## Nettoie le monde actuel.
func _cleanup_world():
	ground_layer.clear()
	wall_layer.clear()
	
	for obj in generated_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	generated_objects.clear()
	
	for npc in npcs:
		if is_instance_valid(npc):
			npc.queue_free()
	npcs.clear()
	
	if is_instance_valid(player_instance):
		player_instance.queue_free()


# =============================================================================
# CAMÉRA
# =============================================================================

## Configure la caméra pour suivre le joueur.
func _setup_player_camera(player: Node2D):
	if not is_instance_valid(player):
		return
	
	world_camera.enabled = true
	world_camera.make_current()
	world_camera.set_target(player)
	world_camera.is_free_roam = false
	
	# Désactive la caméra du joueur
	var p_cam = player.get_node_or_null("Camera2D")
	if p_cam:
		p_cam.enabled = false
	
	update_camera_limits(player.global_position)


## Met à jour les limites de la caméra selon la zone actuelle.
func update_camera_limits(pos: Vector2):
	if not map_data:
		return
	
	var tile_pos = Vector2i(pos / TileConfigScript.TILE_SIZE)
	var found_zone = null
	
	for zone in map_data.zones:
		if zone.shape_bounds.has_point(tile_pos):
			found_zone = zone
			break
	
	if found_zone:
		var limits = found_zone.shape_bounds
		var pixel_limits = Rect2(
			limits.position.x * TileConfigScript.TILE_SIZE,
			limits.position.y * TileConfigScript.TILE_SIZE,
			limits.size.x * TileConfigScript.TILE_SIZE,
			limits.size.y * TileConfigScript.TILE_SIZE
		)
		world_camera.set_limits(pixel_limits)
	else:
		var map_rect = Rect2(0, 0, width * TileConfigScript.TILE_SIZE, height * TileConfigScript.TILE_SIZE)
		world_camera.set_limits(map_rect)


## Bascule le mode de la caméra.
func toggle_camera():
	if world_camera:
		world_camera.toggle_mode()


# =============================================================================
# API PUBLIQUE
# =============================================================================

## Régénère le monde.
func _on_regenerate_button_pressed():
	print("Regenerate button pressed. Regenerating world...")
	generate_world()


## Enregistre un PNJ pour le tracking.
func register_npc(npc_node: Node):
	npcs.append(npc_node)


## Enregistre un objet généré pour le nettoyage.
func register_generated_object(node: Node):
	generated_objects.append(node)


## Réserve une zone autour d'une position.
func register_reserved_area(world_pos: Vector2, radius: int = 2):
	var center = Vector2i(world_pos / TileConfigScript.TILE_SIZE)
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			if map_data:
				map_data.reserved_cells[Vector2i(x, y)] = true


## Enregistre les cellules occupées par une quête spawnée.
## cells_local: Array de Vector2i en coordonnées locales (relatives à la scène)
## world_position: Position monde de la quête (en pixels)
## offset: Offset du TileMapLayer (en tiles)
func register_quest_cells(world_position: Vector2, cells_local: Array, offset: Vector2i = Vector2i.ZERO):
	if not map_data:
		return
	var base_cell = Vector2i(world_position / TileConfigScript.TILE_SIZE)
	for cell in cells_local:
		var world_cell = base_cell + (cell as Vector2i) - offset
		map_data.reserved_cells[world_cell] = true
	print("WorldGenerator: Registered %d quest cells at base %s" % [cells_local.size(), base_cell])


## Retourne une zone aléatoire.
func get_random_zone() -> Zone:
	if not map_data or map_data.zones.is_empty():
		return null
	return map_data.zones.pick_random()


## Retourne une position valide dans une zone.
func get_random_zone_position(specific_zone = null, size: Vector2i = Vector2i(1, 1)) -> Vector2:
	var zone = specific_zone if specific_zone else get_random_zone()
	if zone == null:
		return Vector2.ZERO
	if zone.cells.is_empty():
		return Vector2(zone.center) * TileConfigScript.TILE_SIZE
	
	# Cherche une position valide
	for i in range(20):
		var cell = zone.cells.pick_random()
		if _is_rect_safe(cell, size):
			var world_pos = Vector2(cell) * TileConfigScript.TILE_SIZE
			register_reserved_area(world_pos, max(size.x, size.y) / 2 + 1)
			return world_pos
	
	# Fallback
	var fallback_cell = zone.cells.pick_random()
	var fallback_pos = Vector2(fallback_cell) * TileConfigScript.TILE_SIZE
	register_reserved_area(fallback_pos, max(size.x, size.y) / 2 + 1)
	return fallback_pos


## Trouve une position dans une direction donnée depuis une origine.
func get_position_in_direction(origin: Vector2, direction_str: String, distance: float, check_size: Vector2i = Vector2i(1, 1)) -> Vector2:
	if not map_data:
		return Vector2.INF
	
	# Convertit la direction en vecteur
	var dir_vec = Vector2.RIGHT
	match direction_str.to_upper():
		"NORD": dir_vec = Vector2.UP
		"SUD": dir_vec = Vector2.DOWN
		"EST": dir_vec = Vector2.RIGHT
		"OUEST": dir_vec = Vector2.LEFT
		_:
			var dirs = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
			dir_vec = dirs.pick_random()
	
	# Essaie plusieurs distances
	var distances = [distance, distance * 1.5, distance * 2, distance * 0.5]
	for dist in distances:
		var result = _search_position(origin + dir_vec * dist, check_size, 15)
		if result != Vector2.INF:
			return result
	
	# Fallback: direction opposée
	var result = _search_position(origin - dir_vec * distance, check_size, 10)
	if result != Vector2.INF:
		return result
	
	# Fallback final: position aléatoire
	return get_random_zone_position(null, check_size)


## Retourne une porte de bâtiment aléatoire.
func get_random_building_door(size: Vector2i = Vector2i(1, 1)) -> Vector2:
	if not map_data:
		return Vector2.ZERO
	
	var valid_zones = map_data.zones.filter(func(z): 
		return z.has_meta("building_doors") and not z.get_meta("building_doors").is_empty()
	)
	
	if valid_zones.is_empty():
		return get_random_zone_position(null, size)
	
	var zone = valid_zones.pick_random()
	var doors = zone.get_meta("building_doors")
	if doors.is_empty():
		return Vector2(zone.center) * TileConfigScript.TILE_SIZE
	
	var door = doors.pick_random()
	
	# Cherche un spot libre près de la porte
	for r in range(2, 8):
		for x in range(door.x - r, door.x + r + 1):
			for y in range(door.y - r, door.y + r + 1):
				var cell = Vector2i(x, y)
				if map_data.reserved_cells.has(cell):
					continue
				if _is_rect_safe(cell, size):
					var world_pos = Vector2(cell) * TileConfigScript.TILE_SIZE
					register_reserved_area(world_pos, max(size.x, size.y) / 2 + 1)
					return world_pos
	
	var fallback_pos = Vector2(door) * TileConfigScript.TILE_SIZE
	register_reserved_area(fallback_pos, max(size.x, size.y) / 2 + 1)
	return fallback_pos


## Accesseur pour les zones.
var zones: Array:
	get: return map_data.zones if map_data else []


# =============================================================================
# UTILITAIRES INTERNES
# =============================================================================

## Recherche en spirale une position valide.
func _search_position(center: Vector2, check_size: Vector2i, radius: int) -> Vector2:
	var cell = Vector2i(center / TileConfigScript.TILE_SIZE)
	
	for r in range(0, radius + 1):
		for x in range(cell.x - r, cell.x + r + 1):
			for y in range(cell.y - r, cell.y + r + 1):
				if r > 0 and abs(x - cell.x) < r and abs(y - cell.y) < r:
					continue
				
				var c = Vector2i(x, y)
				if _is_rect_safe(c, check_size):
					var world_pos = Vector2(c) * TileConfigScript.TILE_SIZE
					register_reserved_area(world_pos, max(check_size.x, check_size.y) / 2 + 1)
					return world_pos
	
	return Vector2.INF


## Vérifie si une zone est sûre (pas d'eau, pas d'obstacles, pas de bâtiments).
func _is_rect_safe(top_left: Vector2i, size: Vector2i) -> bool:
	if not map_data:
		return false
	
	# Buffer de 3 tuiles autour de la zone
	const BUFFER = 3
	var start = top_left - Vector2i(BUFFER, BUFFER)
	var end = top_left + size + Vector2i(BUFFER, BUFFER)
	
	# Buffer de 10 tuiles autour de la carte
	const EDGE_BUFFER = 10
	
	for x in range(start.x, end.x):
		for y in range(start.y, end.y):
			var c = Vector2i(x, y)
			
			# Vérifie les limites de la carte
			if c.x < EDGE_BUFFER or c.x >= map_data.width - EDGE_BUFFER:
				return false
			if c.y < EDGE_BUFFER or c.y >= map_data.height - EDGE_BUFFER:
				return false
			
			if not map_data.is_in_bounds(c.x, c.y):
				return false
			
			# Vérifie si la cellule est réservée (bâtiment, rivière)
			if map_data.reserved_cells.has(c):
				return false
			
			var biome = map_data.get_biome_at(c.x, c.y)
			if not biome:
				return false
			
			# 0. Safety Check: Vérification explicite des tuiles interdites
			var wall_safety = map_data.wall_layer.get_cell_atlas_coords(c)
			if TileConfigScript.TREE_VARIANTS.has(wall_safety): return false
			if TileConfigScript.WATER_VARIANTS.has(wall_safety): return false
			
			var ground_safety = map_data.ground_layer.get_cell_atlas_coords(c)
			if TileConfigScript.PATH_VARIANTS.has(ground_safety): return false
			
			# 1. Vérifie WALL LAYER (Doit être vide: ni arbre, ni eau, ni mur)
			if map_data.wall_layer.get_cell_source_id(c) != -1:
				return false
				
			# 2. Vérifie GROUND LAYER (Doit être sol naturel: herbe ou terre)
			var ground = map_data.ground_layer.get_cell_atlas_coords(c)
			if not _is_valid_ground(ground, biome):
				return false
			
	return true


## Vérifie si une tuile de sol est valide (base ou variante).
## Dupliqué de StructurePlacer pour indépendance (ou à déplacer dans un utilitaire statique)
func _is_valid_ground(tile: Vector2i, biome: BiomeResource) -> bool:
	if tile == biome.ground_tile: return true
	if tile == biome.dirt_tile: return true
	
	if biome.ground_tile == TileConfigScript.GRASS:
		if TileConfigScript.GRASS_VARIANTS.has(tile): return true
		
	if biome.dirt_tile == TileConfigScript.DIRT:
		if TileConfigScript.DIRT_VARIANTS.has(tile): return true
		
	return false
