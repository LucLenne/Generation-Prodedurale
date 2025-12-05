class_name WorldGenerator extends Node2D

# --- Exports ---

@export var width : int = 120
@export var height : int = 120

@export_group("Zone Configuration")
@export var zone_count_range: Vector2i = Vector2i(5, 12)
@export var zone_size_range: Vector2i = Vector2i(15, 40)
@export var min_zone_distance: int = 50

@export_group("Zone Details")
@export var entrance_count_range: Vector2i = Vector2i(1, 4)
@export var building_count_range: Vector2i = Vector2i(2, 8)
@export_range(0.0, 1.0, 0.05) var zone_dirt_ratio: float = 0.4

@export_group("Path Generation")
@export var path_width: int = 2
@export var path_smoothness: float = 0.5
@export_range(0.0, 1.0, 0.05) var path_edge_grass_ratio: float = 0.3
@export_range(0.0, 1.0, 0.05) var path_edge_dirt_ratio: float = 0.2

@export_group("Resources")
@export var npc_scene : PackedScene
@export var player_scene : PackedScene
@export var collision_scene : PackedScene
@export var house_scenes : Array[PackedScene]
@export var manager_quest_scene : PackedScene

@export_group("Layers")
@export var ground_layer : TileMapLayer
@export var wall_layer : TileMapLayer

@export var available_biomes: Array[BiomeResource] = []

# --- Internal Data ---

var map_data: MapData
var npcs : Array = [] # Kept for compatibility / tracking
var player_instance : Node2D = null

# --- Scripts ---
const MapDataScript = preload("res://scripts/generation/MapData.gd")
const BiomeGenScript = preload("res://scripts/generation/generators/BiomeGenerator.gd")
const TerrainGenScript = preload("res://scripts/generation/generators/TerrainGenerator.gd")
const RiverGenScript = preload("res://scripts/generation/generators/RiverGenerator.gd")
const ZoneGenScript = preload("res://scripts/generation/generators/ZoneGenerator.gd")
const PathGenScript = preload("res://scripts/generation/generators/PathGenerator.gd")
const StructureGenScript = preload("res://scripts/generation/generators/StructurePlacer.gd")
const SpawnerScript = preload("res://scripts/generation/generators/EntitySpawner.gd")

const TileConfigScript = preload("res://scripts/generation/TileConfig.gd")

func _ready():
	print("WorldGenerator _ready called.")
	if npc_scene == null:
		npc_scene = preload("res://scenes/generation/NPC.tscn")
	if player_scene == null:
		player_scene = preload("res://scenes/Player.tscn")
	
	if ground_layer == null or wall_layer == null:
		printerr("Error: TileMapLayers are not assigned in WorldGenerator!")
		return
		
	# Initialize MapData
	map_data = MapDataScript.new(width, height, ground_layer, wall_layer, randi())
	
	print("Layers assigned. Starting generation...")
	generate_world()

func generate_world():
	print("Starting World Generation (Modular)...")
	
	# Cleanup
	ground_layer.clear()
	wall_layer.clear()
	for npc in npcs:
		if is_instance_valid(npc): npc.queue_free()
	npcs.clear()
	if is_instance_valid(player_instance):
		player_instance.queue_free()
	
	# 1. Generators Instantiation
	var biome_gen = BiomeGenScript.new(available_biomes)
	var terrain_gen = TerrainGenScript.new()
	var river_gen = RiverGenScript.new()
	var zone_gen = ZoneGenScript.new(zone_count_range, zone_size_range, min_zone_distance, entrance_count_range, zone_dirt_ratio)
	var path_gen = PathGenScript.new(path_width, path_smoothness, path_edge_grass_ratio, path_edge_dirt_ratio)
	var structure_gen = StructureGenScript.new(building_count_range, house_scenes)
	var spawner_gen = SpawnerScript.new(player_scene, npc_scene, manager_quest_scene)
	
	# 2. Pipeline Execution
	# Biomes
	var zone_seeds = zone_gen.generate_seeds(map_data)
	biome_gen.generate(map_data, zone_seeds)
	
	# Terrain
	terrain_gen.generate(map_data)
	
	# River
	river_gen.generate(map_data)
	
	# Zones
	zone_gen.generate_zones(map_data, zone_seeds)
	path_gen.generate(map_data)
	
	# Structures & Decorations
	structure_gen.generate(map_data, self)

	# Quests (Manager Spawn) - Spawning after structures allow access to doors and collision avoidances
	spawner_gen.spawn_manager_quest(self, self)
	
	# Spawn Entities (Player & NPCs)
	spawner_gen.spawn_npcs(map_data, self)
	player_instance = spawner_gen.spawn_player(map_data, self)
	
	print("World Generation Complete.")

# --- Public API / Helpers (Preserved for Compatibility) ---

# Helper called by EntitySpawner
func register_npc(npc_node):
	npcs.append(npc_node)

func register_reserved_area(world_pos: Vector2, radius: int = 2) -> void:
	var center_cell = Vector2i(world_pos / TileConfigScript.TILE_SIZE)
	for x in range(center_cell.x - radius, center_cell.x + radius + 1):
		for y in range(center_cell.y - radius, center_cell.y + radius + 1):
			if map_data:
				map_data.reserved_cells[Vector2i(x, y)] = true

# Used by Quest System
func get_random_zone() -> Zone: # Returns Zone object
	if not map_data or map_data.zones.is_empty(): return null
	return map_data.zones.pick_random()

func get_random_zone_position(specific_zone = null) -> Vector2:
	var target_zone = specific_zone
	if target_zone == null:
		target_zone = get_random_zone()
		
	if target_zone == null: return Vector2.ZERO
	if target_zone.cells.is_empty(): return Vector2(target_zone.center) * TileConfigScript.TILE_SIZE
	
	# Attempt to find a valid spot (Not water, Not occupied, Area check)
	for i in range(20):
		var cell = target_zone.cells.pick_random()
		if _is_area_safe(cell, 4): # Check 4 tile radius (9x9) for large quests
			return Vector2(cell) * TileConfigScript.TILE_SIZE
	
	# Fallback
	return Vector2(target_zone.cells.pick_random()) * TileConfigScript.TILE_SIZE

func get_random_building_door() -> Vector2:
	if not map_data: return Vector2.ZERO
	
	var valid_zones = map_data.zones.filter(func(z): return z.has_meta("building_doors") and not z.get_meta("building_doors").is_empty())
	if valid_zones.is_empty(): 
		return get_random_zone_position()
		
	var zone = valid_zones.pick_random()
	var doors = zone.get_meta("building_doors")
	if doors.is_empty(): return Vector2(zone.center) * TileConfigScript.TILE_SIZE
	
	var door = doors.pick_random()
	
	# Find free spot near door (Spiral out)
	for r in range(2, 8): # Start slightly further away
		for x in range(door.x - r, door.x + r + 1):
			for y in range(door.y - r, door.y + r + 1):
				var cell = Vector2i(x,y)
				if map_data.reserved_cells.has(cell): continue
				
				# Check safety (no water, no trees) - Radius 3 allows for decent sized decorations
				if _is_area_safe(cell, 3): 
					return Vector2(cell) * TileConfigScript.TILE_SIZE

	return Vector2(door) * TileConfigScript.TILE_SIZE

func _is_area_safe(center: Vector2i, radius: int) -> bool:
	if not map_data: return false
	
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var c = Vector2i(x,y)
			if not map_data.is_in_bounds(c.x, c.y): return false
			
			# Check Global Reservation
			if map_data.reserved_cells.has(c): return false
			
			# Check Water
			if TileConfigScript.is_water(wall_layer.get_cell_atlas_coords(c)): return false
			
			# Check Wall/Tree (We want open ground)
			if wall_layer.get_cell_source_id(c) != -1: return false
			
	return true

# Accessor for MapData properties if needed externally (e.g. zones)
var zones: Array:
	get: return map_data.zones if map_data else []
