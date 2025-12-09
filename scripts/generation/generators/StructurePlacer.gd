class_name StructurePlacer extends RefCounted

const HouseGenScript = preload("res://scripts/generation/HouseGenerator.gd")
const TileConfigScript = preload("res://scripts/generation/TileConfig.gd")


var building_count_range: Vector2i

func _init(count_range: Vector2i):
	building_count_range = count_range

func generate(data: MapData, parent_node: Node2D):
	print("Populating zones...")
	for zone in data.zones:
		var biome = data.get_biome_at(zone.center.x, zone.center.y)
		var current_house_scenes: Array[PackedScene] = []
		if biome and not biome.house_scenes.is_empty():
			current_house_scenes = biome.house_scenes
			
		var building_count = randi_range(building_count_range.x, building_count_range.y)
		var placed_buildings: Array[Rect2i] = []
		var building_doors: Array[Vector2i] = []
		var occupied_cells = data.reserved_cells # Use global reference
		
		# Place Buildings
		for i in range(building_count):
			if zone.cells.is_empty(): continue
			
			var attempts = 0
			while attempts < 100:
				attempts += 1
				var cell = zone.cells.pick_random()
				
				# Skip if existing path
				if data.ground_layer.get_cell_atlas_coords(cell) == TileConfigScript.PATH:
					continue
					
				var use_procedural = false
				if biome: use_procedural = biome.use_procedural_buildings
				
				var result = try_place_building_at(data, zone, cell, placed_buildings, occupied_cells, parent_node, current_house_scenes, use_procedural)
				if result.success:
					placed_buildings.append(result.rect)
					building_doors.append(result.door)
					if result.has("actual_cells"):
						for ac in result.actual_cells: occupied_cells[ac] = true
					else:
						for x in range(result.rect.position.x, result.rect.end.x):
							for y in range(result.rect.position.y, result.rect.end.y):
								occupied_cells[Vector2i(x,y)] = true
					break
		
		# Connect Doors to Paths
		connect_doors_to_paths(data, zone, building_doors, occupied_cells)
		
		# Spawn NPCs near doors (Requires Spawner, let's just return locations or do it here?)
		# To keep it cohesive, StructurePlacer focuses on structures. Spawning NPCS is EntitySpawner.
		# However, we know where doors are here.
		# I will emit a signal or return list of door positions?
		# For now, let's assume EntitySpawner will handle random NPC spawning or we do it here if closely tied.
		# The original code spawned NPCs immediately after placing buildings.
		# Let's delegate NPC spawning to EntitySpawner, but we need to store door locations.
		zone.set_meta("building_doors", building_doors) # Storing in metadata for EntitySpawner
		
		# Place Decorations
		place_decorations(data, zone, occupied_cells, parent_node)

func try_place_building_at(data: MapData, zone: Zone, pos: Vector2i, placed_buildings: Array[Rect2i], occupied_cells: Dictionary, parent: Node2D, available_scenes: Array[PackedScene], force_procedural: bool = false) -> Dictionary:
	var result = {"success": false, "rect": Rect2i(), "door": Vector2i()}
	
	var offset = Vector2i.ZERO
	var building_size = Vector2i(5, 5)
	var door_pos = pos
	var use_scene = false
	
	if force_procedural:
		# Explicitly forced procedural
		pass 
	elif available_scenes.size() > 0:
		use_scene = true
	else:
		# Scenes expected but none available -> Do nothing
		return result
	
	if use_scene:
		var scene = available_scenes.pick_random()
		if scene == null: return result
		
		# Instantiate temp to check size
		var temp = scene.instantiate()
		var local_door = Vector2i(2, 4)
		var actual_cells: Array[Vector2i] = []
		var tile_layer = temp.get_node_or_null("TileMapLayer")
		
		if tile_layer:
			var rect = tile_layer.get_used_rect()
			if rect.has_area():
				building_size = rect.size
				offset = rect.position
				for cell in tile_layer.get_used_cells():
					var world_cell = pos + (cell - offset)
					actual_cells.append(world_cell)
					if tile_layer.get_cell_atlas_coords(cell) == TileConfigScript.DOOR:
						local_door = cell
		temp.free()
		
		door_pos = pos + (local_door - offset)
		
		# Validation
		var building_rect = Rect2i(pos, building_size)
		for cell in actual_cells:
			if not zone.is_point_inside(cell): return result
			if occupied_cells.has(cell): return result
			if data.ground_layer.get_cell_atlas_coords(cell) == TileConfigScript.PATH: return result
			if TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(cell)): return result
			
		for other in placed_buildings:
			if building_rect.grow(3).intersects(other): return result
			
		# Place
		var instance = scene.instantiate()
		instance.position = Vector2(pos - offset) * TileConfigScript.TILE_SIZE
		parent.add_child(instance)
		if parent.has_method("register_generated_object"):
			parent.register_generated_object(instance)
		zone.buildings.append(instance)
		
		result.success = true
		result.rect = building_rect
		result.door = door_pos
		result.actual_cells = actual_cells
		return result
		
	else:
		# Procedural Logic (Only reached if force_procedural is true)
		var house_data = HouseGenScript.generate_random_house(pos)
		var building_rect = house_data.rect
		door_pos = house_data.door_position
		
		for x in range(building_rect.position.x, building_rect.end.x):
			for y in range(building_rect.position.y, building_rect.end.y):
				var cell = Vector2i(x,y)
				if not zone.is_point_inside(cell): return result
				if occupied_cells.has(cell): return result
				if data.ground_layer.get_cell_atlas_coords(cell) == TileConfigScript.PATH: return result
				if TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(cell)): return result
		
		for other in placed_buildings:
			if building_rect.grow(3).intersects(other): return result
			
		_build_house_procedural(data, house_data)
		zone.buildings.append(house_data)
		
		result.success = true
		result.rect = building_rect
		result.door = door_pos
		return result

func _build_house_procedural(data: MapData, house_data):
	for cell in house_data.floor_cells:
		data.ground_layer.set_cell(cell, TileConfigScript.SOURCE_ID, TileConfigScript.FLOOR)
		
	var wall_set = {}
	for cell in house_data.wall_cells: wall_set[cell] = true
	var floor_set = {}
	for cell in house_data.floor_cells: floor_set[cell] = true
	
	for cell in house_data.wall_cells:
		var border_mask = 0
		var top = cell + Vector2i(0, -1)
		var right = cell + Vector2i(1, 0)
		var bottom = cell + Vector2i(0, 1)
		var left = cell + Vector2i(-1, 0)
		
		if not wall_set.has(top) and not floor_set.has(top): border_mask += 1
		if not wall_set.has(right) and not floor_set.has(right): border_mask += 2
		if not wall_set.has(bottom) and not floor_set.has(bottom): border_mask += 4
		if not wall_set.has(left) and not floor_set.has(left): border_mask += 8
		
		var coords = TileConfigScript.get_wall_tile(border_mask)
		data.wall_layer.set_cell(cell, TileConfigScript.SOURCE_ID, coords)
		
	data.wall_layer.set_cell(house_data.door_position, TileConfigScript.SOURCE_ID, TileConfigScript.DOOR)
	# Trigger NPC spawn by storing in data? Or let EntitySpawner handle if we passed it info. 
	# Original code called spawn_npc immediately. 
	# We can store npc_position in data or meta.
	# Actually, HouseGenerator returns npc_position. We can append to a list in MapData if we added one, or just ignore for now as EntitySpawner handles main NPCs.
	# Wait, procedural houses imply NPCs inside/near? Original code: spawn_npc(data.npc_position). 
	# I'll create a simple helper in MapData to queue spawns? Or just expose a signal. 
	# For simplicity: Use meta on MapData?
	if not data.has_meta("pending_npc_spawns"):
		data.set_meta("pending_npc_spawns", [])
	data.get_meta("pending_npc_spawns").append(house_data.npc_position)

func connect_doors_to_paths(data: MapData, zone: Zone, doors: Array[Vector2i], occupied_cells: Dictionary):
	var path_cells_in_zone: Array[Vector2i] = []
	for cell in zone.cells:
		if data.ground_layer.get_cell_atlas_coords(cell) == TileConfigScript.PATH:
			path_cells_in_zone.append(cell)
			
	if path_cells_in_zone.is_empty():
		path_cells_in_zone = zone.entrances.duplicate()
		
	for door in doors:
		var nearest = path_cells_in_zone[0] if path_cells_in_zone else zone.center
		var min_dist = 999999.0
		for pc in path_cells_in_zone:
			var d = pc.distance_to(door)
			if d < min_dist: min_dist = d; nearest = pc
			
		var astar = AStarGrid2D.new()
		astar.region = zone.shape_bounds.grow(5)
		astar.cell_size = Vector2(1,1)
		astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
		astar.update()
		
		for occ in occupied_cells:
			if occ != door and astar.is_in_bounds(occ.x, occ.y):
				astar.set_point_solid(occ)
				
		for x in range(astar.region.position.x, astar.region.end.x):
			for y in range(astar.region.position.y, astar.region.end.y):
				var c = Vector2i(x,y)
				if data.is_in_bounds(x,y) and TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(c)):
					astar.set_point_weight_scale(c, 5.0)

		var path = astar.get_id_path(nearest, door)
		for i in range(path.size() - 1):
			var point = path[i]
			if occupied_cells.has(point): continue
			
			if TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(point)):
				data.wall_layer.set_cell(point, -1)
				data.ground_layer.set_cell(point, TileConfigScript.SOURCE_ID, TileConfigScript.BRIDGE)
				path_cells_in_zone.append(point)
			else:
				var ct = data.ground_layer.get_cell_atlas_coords(point)
				var biome = data.get_biome_at(point.x, point.y)
				# Check biome existence
				if biome:
					if ct == biome.ground_tile or ct == biome.dirt_tile or ct == TileConfigScript.PATH:
						data.wall_layer.set_cell(point, -1)
						data.ground_layer.set_cell(point, TileConfigScript.SOURCE_ID, biome.path_tile)
						path_cells_in_zone.append(point)
				else:
					# Fallback or skip if biome not found
					if ct == TileConfigScript.PATH:
						path_cells_in_zone.append(point)
					
	# Pass path_cells to place_decorations via meta or argument
	zone.set_meta("path_cells", path_cells_in_zone)

func place_decorations(data: MapData, zone: Zone, occupied_cells: Dictionary, parent: Node2D):
	var biome = data.get_biome_at(zone.center.x, zone.center.y)
	if not biome: 
		printerr("Warning: No biome found at zone center ", zone.center)
		return
		
	var path_cells = zone.get_meta("path_cells", [])
	
	# Scenes
	var scene_count = randi_range(biome.decoration_scene_count_range.x, biome.decoration_scene_count_range.y)
	for i in range(scene_count):
		if biome.decoration_scenes.is_empty(): break
		
		var attempts = 0
		while attempts < 20:
			attempts += 1
			var cell = zone.cells.pick_random()
			if occupied_cells.has(cell) or TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(cell)): continue
			if cell in path_cells: continue
			
			var scene = biome.decoration_scenes.pick_random()
			if scene == null: continue
			var temp = scene.instantiate()
			var deco_size = Vector2i(3,3)
			var offset = Vector2i.ZERO
			var actual_cells = []
			
			var tile_layer = temp.get_node_or_null("TileMapLayer")
			if tile_layer:
				var rect = tile_layer.get_used_rect()
				if rect.has_area():
					deco_size = rect.size
					offset = rect.position
					for u in tile_layer.get_used_cells(): actual_cells.append(cell + (u - offset))
			temp.free()
			
			var valid = true
			for ac in actual_cells:
				if not zone.is_point_inside(ac): valid = false; break
				if occupied_cells.has(ac): valid = false; break
				if TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(ac)): valid = false; break
				if ac in path_cells: valid = false; break
				
			if valid:
				var instance = scene.instantiate()
				instance.position = Vector2(cell - offset) * TileConfigScript.TILE_SIZE
				parent.add_child(instance)
				if parent.has_method("register_generated_object"):
					parent.register_generated_object(instance)
				zone.buildings.append(instance)
				for ac in actual_cells: occupied_cells[ac] = true
				break

	# Tiles
	if biome.decorations.size() > 0:
		for cell in zone.cells:
			if occupied_cells.has(cell): continue
			if TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(cell)): continue
			if cell in path_cells: continue
			
			var ground_tile = data.ground_layer.get_cell_atlas_coords(cell)
			if ground_tile != biome.ground_tile and ground_tile != biome.dirt_tile: continue
			if data.wall_layer.get_cell_source_id(cell) != -1: continue
			
			var r = randf()
			var acc = 0.0
			for d in biome.decorations:
				acc += d.density
				if r < acc:
					data.wall_layer.set_cell(cell, TileConfigScript.SOURCE_ID, d.atlas_coords)
					break
