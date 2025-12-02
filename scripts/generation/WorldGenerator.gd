class_name WorldGenerator extends Node2D

@export var width : int = 100
@export var height : int = 80
@export var house_count : int = 10
@export var npc_scene : PackedScene
@export var house_scenes : Array[PackedScene]

@export var ground_layer : TileMapLayer
@export var wall_layer : TileMapLayer

const HouseGenScript = preload("res://scripts/generation/HouseGenerator.gd")
const HouseScript = preload("res://scripts/House.gd")
const TileConfigScript = preload("res://scripts/generation/TileConfig.gd")

var houses : Array = [] # Array of Dictionaries: { "rect": Rect2i, "door": Vector2i }
var npcs : Array[NPC] = []
var noise : FastNoiseLite
var village_center : Vector2i
var village_square_rect : Rect2i
var river_cells : Array[Vector2i] = []

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
	print("Starting World Generation (Medieval Village)...")
	ground_layer.clear()
	wall_layer.clear()
	houses.clear()
	river_cells.clear()
	for npc in npcs:
		npc.queue_free()
	npcs.clear()
	
	village_center = Vector2i(width / 2, height / 2)
	
	fill_ground()
	generate_river()
	place_village_square()
	place_borders()
	place_houses_clustered()
	draw_paths_to_center()
	decorate_logical()
	setup_quests()
	print("World Generation Complete.")

func fill_ground():
	# 1. Infinite Grass Plain
	for x in range(width):
		for y in range(height):
			ground_layer.set_cell(Vector2i(x, y), TileConfig.SOURCE_ID, TileConfig.GRASS)

func place_borders():
	# 2. Irregular Organic Borders (Dense Forest at edges)
	for x in range(width):
		for y in range(height):
			# Calculate distance to the closest edge
			var dist_x = min(x, width - x)
			var dist_y = min(y, height - y)
			var dist_to_edge = min(dist_x, dist_y)
			
			# Noise factor for irregularity
			var noise_val = noise.get_noise_2d(x * 2.0, y * 2.0) * 10.0
			
			# Threshold: closer to edge = higher chance of tree
			# Base border thickness of ~8 tiles, plus noise variation
			if dist_to_edge < 5 + noise_val:
				wall_layer.set_cell(Vector2i(x, y), TileConfig.SOURCE_ID, TileConfig.TREE)
			
			# Ensure absolute map bounds are closed (safety)
			if x == 0 or x == width - 1 or y == 0 or y == height - 1:
				wall_layer.set_cell(Vector2i(x, y), TileConfig.SOURCE_ID, TileConfig.TREE)

func generate_river():
	# 3. Sinuous Vertical River
	# Offset X slightly to not cut exactly through the center if possible, or adapt center
	var start_x = width / 2 + randi_range(-5, 5)
	var amplitude = randf_range(3.0, 6.0)
	var frequency = randf_range(0.02, 0.05)
	
	for y in range(height):
		var x_offset = sin(y * frequency) * amplitude
		var noise_val = noise.get_noise_1d(y * 0.5) * 3.0 # Smoother noise
		var center_x = int(start_x + x_offset + noise_val)
		
		# River width of 3
		for w in range(-1, 2):
			var cell = Vector2i(center_x + w, y)
			if cell.x >= 1 and cell.x < width - 1:
				ground_layer.set_cell(cell, TileConfig.SOURCE_ID, TileConfig.WATER_BASE)
				# Note: We do NOT add to wall_layer, as it would hide the autotiled ground tiles.
				# Collision is handled by the tiles themselves or by logic.
				river_cells.append(cell)
	
	autotile_river()

func autotile_river():
	# 1. Création du Set pour une recherche rapide
	var river_set = {}
	for cell in river_cells:
		river_set[cell] = true
		
	# 2. Boucle sur les cellules
	for cell in river_cells:
		var neighbor_mask = 0
		
		# On regarde les VOISINS (Est-ce de l'eau ?)
		if river_set.has(cell + Vector2i(0, -1)): neighbor_mask += 1 # Haut (Eau)
		if river_set.has(cell + Vector2i(1, 0)):  neighbor_mask += 2 # Droite (Eau)
		if river_set.has(cell + Vector2i(0, 1)):  neighbor_mask += 4 # Bas (Eau)
		if river_set.has(cell + Vector2i(-1, 0)): neighbor_mask += 8 # Gauche (Eau)
		
		# 3. Inversion pour obtenir le Masque de BORDURE (Où est la terre ?)
		var border_mask = (~neighbor_mask) & 15
		
		# 4. Récupération de la tuile
		var coords = TileConfig.get_river_tile(border_mask)
		
		ground_layer.set_cell(cell, TileConfig.SOURCE_ID, coords)

func place_village_square():
	# 4. Central Village Square
	var size = 10
	var top_left = village_center - Vector2i(size / 2, size / 2)
	village_square_rect = Rect2i(top_left, Vector2i(size, size))
	
	for x in range(village_square_rect.position.x, village_square_rect.end.x):
		for y in range(village_square_rect.position.y, village_square_rect.end.y):
			# Don't overwrite river
			if not river_cells.has(Vector2i(x, y)):
				ground_layer.set_cell(Vector2i(x, y), TileConfig.SOURCE_ID, TileConfig.SQUARE)
				# Clear any walls/trees that might be there
				wall_layer.set_cell(Vector2i(x, y), -1)

func place_houses_clustered():
	# 5. Clustered Houses (Hybrid: Scenes + Presets + Procedural)
	var attempts = 0
	var max_radius = 25
	var min_radius = 8
	
	while houses.size() < house_count and attempts < 200:
		attempts += 1
		
		# Random position
		var angle = randf() * TAU
		var dist = randf_range(min_radius, max_radius)
		var pos = village_center + Vector2i(Vector2(cos(angle), sin(angle)) * dist)
		
		var new_rect : Rect2i
		var door_pos : Vector2i
		var house_scene_instance : House = null
		var house_data = null
		
		# Decide Type: 50% Scene (if available), 50% Data (Preset/Procedural)
		var use_scene = false
		if house_scenes.size() > 0 and randf() > 0.5:
			use_scene = true
		
		var offset = Vector2i.ZERO
		
		if use_scene:
			var scene = house_scenes.pick_random()
			var temp = scene.instantiate()
			
			# Manual Measurement (since _ready hasn't run)
			var size = Vector2i(5, 5) # Default
			var local_door = Vector2i(2, 4) # Default
			
			# Try to find TileMapLayer to measure real size
			var tile_layer = temp.get_node_or_null("TileMapLayer")
			if tile_layer:
				var rect = tile_layer.get_used_rect()
				if rect.has_area():
					size = rect.size
					offset = rect.position # Capture the offset (e.g. if drawn centered)
					
					# Find door in the scene (TileConfig.DOOR is 2,2)
					for cell in tile_layer.get_used_cells():
						if tile_layer.get_cell_atlas_coords(cell) == TileConfig.DOOR:
							local_door = cell
							break
			
			temp.free()
			new_rect = Rect2i(pos.x, pos.y, size.x, size.y)
			
			# Door Global Pos = Grid Top-Left + (Door Local Pos - Top-Left Local Pos)
			door_pos = pos + (local_door - offset)
			
		else:
			# Generate Data (Preset or Procedural)
			house_data = HouseGenScript.generate_random_house(pos)
			new_rect = house_data.rect
			door_pos = house_data.door_position
		
		# Check bounds
		if new_rect.position.x < 2 or new_rect.end.x > width - 2: continue
		if new_rect.position.y < 2 or new_rect.end.y > height - 2: continue
		
		# Check overlaps
		var overlap = false
		for h in houses:
			if new_rect.grow(2).intersects(h.rect):
				overlap = true; break
		if overlap: continue
		
		if new_rect.grow(1).intersects(village_square_rect): continue
		
		for x in range(new_rect.position.x - 1, new_rect.end.x + 1):
			for y in range(new_rect.position.y - 1, new_rect.end.y + 1):
				if river_cells.has(Vector2i(x, y)):
					overlap = true; break
			if overlap: break
		if overlap: continue
		
		# Place House
		houses.append({ "rect": new_rect, "door": door_pos })
		
		if use_scene:
			var scene = house_scenes.pick_random() # Ideally same one
			var instance = scene.instantiate()
			
			# Adjust position: We want the Top-Left Tile (at 'offset') to be at 'pos'
			# Instance Pos + Offset = Pos
			# Instance Pos = Pos - Offset
			instance.position = Vector2(pos - offset) * TileConfig.TILE_SIZE
			add_child(instance)
			
			# Spawn NPC at door + 1 down
			spawn_npc(Vector2(door_pos.x, door_pos.y + 1))
			
		else:
			# Build from Data
			build_house_from_data(house_data)

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
	# We place the door tile on the Wall Layer (so it stands up)
	wall_layer.set_cell(data.door_position, TileConfig.SOURCE_ID, TileConfig.DOOR)
	
	# NPC
	spawn_npc(data.npc_position)
	
	# Interior
	for deco in data.interior_decorations:
		# Note: For Scene Collections, use alternative_tile for the scene ID
		ground_layer.set_cell(deco.pos, 0, Vector2i.ZERO, deco.id)

func spawn_npc(pos: Vector2):
	var npc = npc_scene.instantiate()
	npc.position = pos * TileConfig.TILE_SIZE
	add_child(npc)
	npcs.append(npc)

func draw_paths_to_center():
	# 6. Paths: House -> Village Square Center
	var astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, width, height)
	astar.cell_size = Vector2(1, 1)
	astar.update()
	
	# Solid obstacles
	for x in range(width):
		for y in range(height):
			if river_cells.has(Vector2i(x, y)):
				# Check if it's water (river)
				# Allow movement but with higher cost to prefer land if possible
				astar.set_point_weight_scale(Vector2i(x, y), 5.0)
			elif wall_layer.get_cell_source_id(Vector2i(x, y)) != -1:
				# Real walls/trees are solid
				astar.set_point_solid(Vector2i(x, y))
				
	var center_target = village_center
	
	for house in houses:
		var start = house.door
		# Ensure start is not solid (it shouldn't be, we cleared the door)
		
		var path = astar.get_id_path(start, center_target)
		for point in path:
			# Don't overwrite square floor or house floor
			var current_atlas = ground_layer.get_cell_atlas_coords(point)
			if current_atlas != TileConfig.SQUARE and current_atlas != TileConfig.FLOOR:
				
				# Check if we are crossing the river
				if river_cells.has(point):
					# Build Bridge
					ground_layer.set_cell(point, TileConfig.SOURCE_ID, TileConfig.FLOOR) # Wood floor as bridge
					wall_layer.set_cell(point, -1) # Remove water collision
				else:
					# Normal Path
					ground_layer.set_cell(point, TileConfig.SOURCE_ID, TileConfig.PATH)

func decorate_logical():
	# 7. Vegetation: Dense edges, clear center
	for x in range(width):
		for y in range(height):
			# Skip occupied
			if wall_layer.get_cell_source_id(Vector2i(x, y)) != -1: continue
			if ground_layer.get_cell_atlas_coords(Vector2i(x, y)) != TileConfig.GRASS: continue
			
			var dist_to_center = Vector2(x, y).distance_to(Vector2(village_center))
			var max_dist = width / 2.0
			
			# Probability increases with distance
			var prob = remap(dist_to_center, 10.0, max_dist, 0.0, 0.8)
			prob = clamp(prob, 0.0, 0.8)
			
			# Add noise variation
			var noise_val = (noise.get_noise_2d(x, y) + 1.0) / 2.0
			
			if randf() < prob * noise_val:
				wall_layer.set_cell(Vector2i(x, y), TileConfig.SOURCE_ID, TileConfig.TREE)

func setup_quests():
	if npcs.size() == 0: return
	for i in range(npcs.size()):
		var npc = npcs[i]
		if i < npcs.size() - 1:
			if i + 1 >= houses.size(): break
			var direction = "East"
			if houses[i+1].rect.position.x < houses[i].rect.position.x: direction = "West"
			if houses[i+1].rect.position.y < houses[i].rect.position.y: direction = "North"
			if houses[i+1].rect.position.y > houses[i].rect.position.y: direction = "South"
			npc.dialogue_text = "Go find the neighbor to the " + direction + "!"
		else:
			npc.dialogue_text = "Welcome to our village!"
