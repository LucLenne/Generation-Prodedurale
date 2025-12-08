class_name HouseGenerator extends Node

class HouseData:
	var rect : Rect2i
	var floor_cells : Array[Vector2i] = []
	var wall_cells : Array[Vector2i] = []
	var door_position : Vector2i
	var npc_position : Vector2
	var interior_decorations : Array[Dictionary] = []

# Define Presets using a simple string grid
# Legend:
# W = Wall
# . = Floor
# D = Door
# [space] = Empty/Void (use this to make non-rectangular shapes)
const PRESETS = [
	{
		"name": "Peni",
		"layout": [
			"....W....",
			"...WWW...",
			"....W....",
			"....W....",
			"....W....",
			"....W....",
			"....W....",
			".WWW.WWW.",
			".WWW.WWW.",
			".WWW.WWW."
		]
	}
]

static func generate_random_house(pos: Vector2i) -> HouseData:
	# 50% Chance: Preset vs Procedural
	if randf() > 0.5:
		var preset = PRESETS.pick_random()
		return create_preset_house(pos, preset)
	else:
		var w = randi_range(5, 7)
		var h = randi_range(4, 6)
		var rect = Rect2i(pos.x, pos.y, w, h)
		return create_procedural_house(rect)

static func generate_clustered_houses(
	count: int, 
	center: Vector2i, 
	map_width: int, 
	map_height: int, 
	obstacles: Array[Rect2i] = [], 
	forbidden_cells: Array[Vector2i] = []
) -> Array[HouseData]:
	
	var houses_data : Array[HouseData] = []
	var attempts = 0
	var max_radius = 25
	var min_radius = 8
	
	while houses_data.size() < count and attempts < 200:
		attempts += 1
		
		# Random point in ring
		var angle = randf() * TAU
		var dist = randf_range(min_radius, max_radius)
		var pos = center + Vector2i(Vector2(cos(angle), sin(angle)) * dist)
		
		var house_data = generate_random_house(pos)
		var new_rect = house_data.rect
		
		# Check bounds
		if new_rect.position.x < 2 or new_rect.end.x > map_width - 2: continue
		if new_rect.position.y < 2 or new_rect.end.y > map_height - 2: continue
		
		# Check overlaps
		var overlap = false
		
		# Overlap with other houses
		for house in houses_data:
			if new_rect.grow(2).intersects(house.rect):
				overlap = true; break
		if overlap: continue
		
		# Overlap with Obstacles (Square)
		for obs in obstacles:
			if new_rect.grow(1).intersects(obs):
				overlap = true; break
		if overlap: continue
			
		# Overlap with Forbidden Cells (River)
		# We check the bounding box for simplicity, which is safe
		for x in range(new_rect.position.x - 1, new_rect.end.x + 1):
			for y in range(new_rect.position.y - 1, new_rect.end.y + 1):
				if forbidden_cells.has(Vector2i(x, y)):
					overlap = true; break
			if overlap: break
		if overlap: continue
		
		houses_data.append(house_data)
		
	return houses_data

static func create_procedural_house(rect: Rect2i) -> HouseData:
	var data = HouseData.new()
	data.rect = rect
	
	# Floor & Walls
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			# Determine if wall or floor
			var is_wall = x == rect.position.x or x == rect.end.x - 1 or y == rect.position.y or y == rect.end.y - 1
			if is_wall:
				data.wall_cells.append(Vector2i(x, y))
			else:
				data.floor_cells.append(Vector2i(x, y))
	
	# Door (Bottom center)
	data.door_position = Vector2i(rect.position.x + int(rect.size.x / 2), rect.end.y - 1)
	# Remove door from walls and add to floor
	if data.wall_cells.has(data.door_position):
		data.wall_cells.erase(data.door_position)
		data.floor_cells.append(data.door_position)
		
	# NPC Position (Outside door)
	data.npc_position = Vector2(data.door_position.x, data.door_position.y + 1)
	
	# Interior
	generate_interior(data)
	return data

static func create_preset_house(pos: Vector2i, preset: Dictionary) -> HouseData:
	var data = HouseData.new()
	var layout = preset["layout"]
	var h = layout.size()
	var w = layout[0].length()
	
	data.rect = Rect2i(pos.x, pos.y, w, h)
	
	for y in range(h):
		for x in range(w):
			var char = layout[y][x]
			var global_pos = pos + Vector2i(x, y)
			
			match char:
				"W":
					data.wall_cells.append(global_pos)
				".":
					data.floor_cells.append(global_pos)
				"D":
					data.door_position = global_pos
					data.floor_cells.append(global_pos) # Door is also floor
				" ":
					pass # Void/Empty
	
	data.npc_position = Vector2(data.door_position.x, data.door_position.y + 1)
	
	generate_interior(data)
	return data

static func generate_interior(data: HouseData):
	for cell in data.floor_cells:
		if cell == data.door_position: continue
		
		if randf() > 0.8: # 20% chance per tile
			var item_id = randi_range(1, 2)
			data.interior_decorations.append({"pos": cell, "id": item_id})
