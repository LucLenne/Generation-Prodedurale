class_name House extends Node2D

@export var size : Vector2i = Vector2i(5, 5)
@export var door_position : Vector2i = Vector2i(2, 4) # Local grid pos
@export var npc_spawn_point : Marker2D

func _ready():
	# Auto-detect size and door if TileMapLayer exists
	var tile_layer = get_node_or_null("TileMapLayer")
	if tile_layer:
		var rect = tile_layer.get_used_rect()
		if rect.has_area():
			# Update size to match the drawn tiles
			# We assume the house starts at (0,0) locally, or we adjust
			size = rect.size
			
			# Optional: Find door if not set manually or if we want to be smart
			# Let's try to find a door tile (Atlas coords 4,2)
			var found_door = false
			for x in range(rect.position.x, rect.end.x):
				for y in range(rect.position.y, rect.end.y):
					var coords = tile_layer.get_cell_atlas_coords(Vector2i(x, y))
					if coords == Vector2i(4, 2): # Door
						door_position = Vector2i(x, y)
						found_door = true
						break
				if found_door: break

func get_rect() -> Rect2i:
	# Convert local size to a Rect2i based on current position
	# Assuming position is top-left of the house in world coords
	var grid_pos = Vector2i(position) / 8 # TILE_SIZE
	return Rect2i(grid_pos, size)
