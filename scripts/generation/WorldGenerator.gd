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
@export var manager_quest_scene : PackedScene

@export_group("Layers")
@export var ground_layer : TileMapLayer
@export var wall_layer : TileMapLayer

@export var available_biomes: Array[BiomeResource] = []

# --- Internal Data ---

var map_data: MapData
var npcs : Array = [] # Kept for compatibility / tracking
var generated_objects : Array = []
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

	# Auto-detect TileSet Source ID
	if ground_layer.tile_set:
		var source_count = ground_layer.tile_set.get_source_count()
		if source_count > 0:
			var found_id = ground_layer.tile_set.get_source_id(0)
			# Update the static variable
			TileConfigScript.SOURCE_ID = found_id
			print("Detected TileSet Source ID: ", found_id)
		else:
			printerr("Warning: TileSet assigned to Ground Layer has no sources.")
	else:
		printerr("Warning: No TileSet assigned to Ground Layer.")
		

	
	print("Layers assigned. Starting generation...")
	generate_world()

func generate_world():
	print("Starting World Generation (Modular)...")

	# Initialize MapData for a fresh generation
	map_data = MapDataScript.new(width, height, ground_layer, wall_layer, randi())
	
	# Cleanup
	ground_layer.clear()
	wall_layer.clear()
	
	for obj in generated_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	generated_objects.clear()
	
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
	var structure_gen = StructureGenScript.new(building_count_range)
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
	
	# Quests (Manager Spawn) - Spawning BEFORE structures to ensure priority (they reserve space first)
	spawner_gen.spawn_manager_quest(self, self)

	# Structures & Decorations
	structure_gen.generate(map_data, self)
	
	# Spawn Entities (Player & NPCs)
	spawner_gen.spawn_npcs(map_data, self)
	player_instance = spawner_gen.spawn_player(map_data, self)

	# --- Generate Quests for PNJs (After NPCs are placed) ---
	if ManagerQuest:
		for npc in npcs:
			if npc is PNJ and npc.QuestGiverDialogueSystem != null:
				ManagerQuest.spawn_quest_for_pnj(npc, self)
	
	setup_player_camera(player_instance)
	
	print("World Generation Complete.")

@onready var world_camera : CameraManager = $Camera2D

func setup_player_camera(player_node):
	if not is_instance_valid(player_node): return
	
	# Ensure world camera is active and targeted
	world_camera.enabled = true
	world_camera.make_current()
	world_camera.set_target(player_node)
	world_camera.is_free_roam = false # Force follow mode start
	
	# Disable player's internal camera just in case
	var p_cam = player_node.get_node_or_null("Camera2D")
	if p_cam: p_cam.enabled = false

	update_camera_limits(player_node.global_position)

func update_camera_limits(pos: Vector2):
	if not map_data: return
	
	var tile_pos = Vector2i(pos / TileConfigScript.TILE_SIZE)
	var found_zone = null
	
	for zone in map_data.zones:
		if zone.shape_bounds.has_point(tile_pos):
			found_zone = zone
			break
	
	if found_zone:
		var limits = found_zone.shape_bounds
		# Convert Rect2i (tiles) to Rect2 (pixels)
		var pixel_limits = Rect2(
			limits.position.x * TileConfigScript.TILE_SIZE,
			limits.position.y * TileConfigScript.TILE_SIZE,
			limits.size.x * TileConfigScript.TILE_SIZE,
			limits.size.y * TileConfigScript.TILE_SIZE
		)
		world_camera.set_limits(pixel_limits)
	else:
		# Fallback: Map Limits
		var map_rect = Rect2(0, 0, width * TileConfigScript.TILE_SIZE, height * TileConfigScript.TILE_SIZE)
		world_camera.set_limits(map_rect)

func toggle_camera():
	if world_camera:
		world_camera.toggle_mode()


func _on_regenerate_button_pressed():
	print("Regenerate button pressed. Regenerating world...")
	generate_world()

# --- Public API / Helpers (Preserved for Compatibility) ---

# Helper called by EntitySpawner
func register_npc(npc_node):
	npcs.append(npc_node)

func register_generated_object(node: Node):
	generated_objects.append(node)

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

func get_random_zone_position(specific_zone = null, size: Vector2i = Vector2i(1, 1)) -> Vector2:
	var target_zone = specific_zone
	if target_zone == null:
		target_zone = get_random_zone()
		
	if target_zone == null: return Vector2.ZERO
	if target_zone.cells.is_empty(): return Vector2(target_zone.center) * TileConfigScript.TILE_SIZE
	
	# Attempt to find a valid spot (Not water, Not occupied, Area check)
	for i in range(20):
		var cell = target_zone.cells.pick_random()
		if _is_rect_safe(cell, size):
			var world_pos = Vector2(cell) * TileConfigScript.TILE_SIZE
			register_reserved_area(world_pos, max(size.x, size.y) / 2 + 1)
			return world_pos
	
	# Fallback
	var fallback_cell = target_zone.cells.pick_random()
	var fallback_pos = Vector2(fallback_cell) * TileConfigScript.TILE_SIZE
	register_reserved_area(fallback_pos, max(size.x, size.y) / 2 + 1)
	return fallback_pos

func get_position_in_direction(origin: Vector2, direction_str: String, distance: float, check_size: Vector2i = Vector2i(1,1)) -> Vector2:
	if not map_data: return Vector2.INF

	var dir_vec = Vector2.RIGHT
	match direction_str.to_upper():
		"NORD": dir_vec = Vector2.UP
		"SUD": dir_vec = Vector2.DOWN
		"EST": dir_vec = Vector2.RIGHT
		"OUEST": dir_vec = Vector2.LEFT
		_:
			# Fallback or random if needed, but for now specific
			printerr("WorldGenerator: Unknown direction '%s', defaulting to RIGHT" % direction_str)

	# Calculate theoretical target
	var target_pos = origin + (dir_vec * distance)
	var target_cell = Vector2i(target_pos / TileConfigScript.TILE_SIZE)
	
	# Spiral search for valid spot near target
	var search_radius = 5
	for r in range(0, search_radius + 1):
		for x in range(target_cell.x - r, target_cell.x + r + 1):
			for y in range(target_cell.y - r, target_cell.y + r + 1):
				var cell = Vector2i(x,y)
				# Only check outer ring if r>0 to avoid re-checking
				# (Optional optimization, but simple loop is fine for small radius)
				
				if _is_rect_safe(cell, check_size):
					var world_pos = Vector2(cell) * TileConfigScript.TILE_SIZE
					
					# We should probably reserve this spot if found? 
					# The user asked for a function that *finds* an appropriate place.
					# Usually we want to reserve it to avoid double spawn.
					register_reserved_area(world_pos, max(check_size.x, check_size.y) / 2 + 1)
					return world_pos
					
	return Vector2.INF

func get_random_building_door(size: Vector2i = Vector2i(1, 1)) -> Vector2:
	if not map_data: return Vector2.ZERO
	
	var valid_zones = map_data.zones.filter(func(z): return z.has_meta("building_doors") and not z.get_meta("building_doors").is_empty())
	if valid_zones.is_empty(): 
		return get_random_zone_position(null, size)
		
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
				
				# Check safety (no water, no trees)
				if _is_rect_safe(cell, size):
					var world_pos = Vector2(cell) * TileConfigScript.TILE_SIZE
					register_reserved_area(world_pos, max(size.x, size.y) / 2 + 1) 
					return world_pos

	var fallback_pos = Vector2(door) * TileConfigScript.TILE_SIZE
	register_reserved_area(fallback_pos, max(size.x, size.y) / 2 + 1)
	return fallback_pos

func _is_area_safe(center: Vector2i, radius: int) -> bool:
	return _is_rect_safe(center - Vector2i(radius, radius), Vector2i(radius * 2, radius * 2))

func _is_rect_safe(top_left: Vector2i, size: Vector2i) -> bool:
	if not map_data: return false
	
	# Safety buffer around the rect
	var buffer = 1
	var start = top_left - Vector2i(buffer, buffer)
	var end = top_left + size + Vector2i(buffer, buffer)
	
	for x in range(start.x, end.x):
		for y in range(start.y, end.y):
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
