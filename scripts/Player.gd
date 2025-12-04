extends CharacterBody2D

@export var speed: float = 100.0
# @export var zoom_level: Vector2 = Vector2(4.0, 4.0) # Removed in favor of dynamic zoom

func _ready():
	# Detach camera to control it manually
	$Camera2D.top_level = true
	# $Camera2D.zoom = zoom_level # Set dynamically now
	$Camera2D.make_current()
	
	# Force initial update
	update_zoom()
	update_camera_position()
	$Camera2D.position = target_camera_pos # Snap immediately on start
	
	# Connect to viewport resize to update zoom dynamically
	get_tree().root.size_changed.connect(on_viewport_resize)

func on_viewport_resize():
	update_zoom()
	update_camera_position()

var target_camera_pos: Vector2

func _physics_process(delta):
	var direction = Vector2.ZERO
	
	if direction == Vector2.ZERO:
		if Input.is_action_pressed("Up"): direction.y -= 1
		if Input.is_action_pressed("Down"): direction.y += 1
		if Input.is_action_pressed("Left"): direction.x -= 1
		if Input.is_action_pressed("Right"): direction.x += 1
		direction = direction.normalized()
		
	velocity = direction * speed
	move_and_slide()
	
	update_camera_position()
	# Smooth transition
	$Camera2D.position = $Camera2D.position.lerp(target_camera_pos, 10 * delta)
	
	if velocity != Vector2.ZERO:
		pass
		
	detect_biome()

func update_zoom():
	var world_gen = get_parent()
	if world_gen and "tiles_per_screen" in world_gen:
		var zone_size_pixels = Vector2(world_gen.tiles_per_screen) * TileConfig.TILE_SIZE
		var viewport_size = get_viewport_rect().size
		
		# Calculate zoom to fit the zone in the viewport
		# We use the minimum scale to ensure the entire zone fits (might have black bars)
		# Or maximum to fill (might cut off).
		# Usually for this style, we want to FIT.
		var zoom_x = viewport_size.x / zone_size_pixels.x
		var zoom_y = viewport_size.y / zone_size_pixels.y
		var new_zoom = min(zoom_x, zoom_y)
		
		$Camera2D.zoom = Vector2(new_zoom, new_zoom)
	else:
		$Camera2D.zoom = Vector2(4, 4) # Fallback

func update_camera_position():
	var screen_size = Vector2.ZERO
	
	# Try to get screen size from WorldGenerator
	var world_gen = get_parent()
	if world_gen and "tiles_per_screen" in world_gen:
		screen_size = Vector2(world_gen.tiles_per_screen) * TileConfig.TILE_SIZE
	else:
		# Fallback to viewport
		var viewport_size = get_viewport_rect().size
		screen_size = viewport_size / $Camera2D.zoom
	
	# Calculate which "screen" the player is in
	# Use global_position to be safe
	var grid_x = floor(global_position.x / screen_size.x)
	var grid_y = floor(global_position.y / screen_size.y)
	
	target_camera_pos = Vector2(
		grid_x * screen_size.x + screen_size.x / 2,
		grid_y * screen_size.y + screen_size.y / 2
	)

var current_biome_name: String = ""

func detect_biome():
	var world_gen = get_parent()
	if world_gen and world_gen.has_method("get_biome_at"):
		var biome = world_gen.get_biome_at(position)
		if biome:
			if biome.biome_name != current_biome_name:
				current_biome_name = biome.biome_name
				print("Entered Biome: ", current_biome_name)
