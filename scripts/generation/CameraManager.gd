class_name CameraManager extends Camera2D

@export var player_zoom : Vector2 = Vector2(4, 4)
@export var map_zoom : Vector2 = Vector2(0.5, 0.5)
@export var zoom_speed : float = 5.0
@export var move_speed : float = 5.0
@export var limit_smoothing_speed : float = 2.5 # Faster to ensure visible switch
@export var free_move_speed : float = 600.0

var target_node : Node2D
var is_free_roam : bool = false

# Soft limits
var target_limits_rect : Rect2
var current_limits_rect : Rect2

func _ready():
	# Initialize limits to something huge or current view
	current_limits_rect = Rect2(0, 0, 100000, 100000)
	target_limits_rect = current_limits_rect
	zoom = map_zoom
	
	# Enable built-in smoothing for stable follow
	position_smoothing_enabled = true
	position_smoothing_speed = 3.0
	
	# Fix Jitter: Sync camera updates with physics engine
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	
	# Enable Drag Margins (Dead Zone)
	drag_horizontal_enabled = true
	drag_vertical_enabled = true
	drag_left_margin = 0.1
	drag_top_margin = 0.1
	drag_right_margin = 0.1
	drag_bottom_margin = 0.1

func _physics_process(delta):
	# 1. Zoom Transition
	var desired_zoom = map_zoom if is_free_roam else player_zoom
	zoom = zoom.lerp(desired_zoom, zoom_speed * delta)
	
	# 2. Limits Transition (Soft Limits)
	# We interpret limit_left/top/right/bottom as a Rect2 for interpolation
	current_limits_rect.position = current_limits_rect.position.lerp(target_limits_rect.position, limit_smoothing_speed * delta)
	current_limits_rect.size = current_limits_rect.size.lerp(target_limits_rect.size, limit_smoothing_speed * delta)
	
	# Apply limits
	limit_left = int(current_limits_rect.position.x)
	limit_top = int(current_limits_rect.position.y)
	limit_right = int(current_limits_rect.end.x)
	limit_bottom = int(current_limits_rect.end.y)
	
	# 3. Movement
	if is_free_roam:
		_process_free_roam(delta)
	else:
		_process_follow(delta)

func _process_free_roam(delta):
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): direction.x += 1
	if Input.is_action_pressed("ui_left"): direction.x -= 1
	if Input.is_action_pressed("ui_down"): direction.y += 1
	if Input.is_action_pressed("ui_up"): direction.y -= 1
	
	global_position += direction.normalized() * free_move_speed * delta

var forced_center = null

func _process_follow(delta):
	# If we have a forced center (Grid Mode), aim for it
	if forced_center != null:
		global_position = forced_center
	elif is_instance_valid(target_node):
		# Standard follow
		global_position = target_node.global_position

func set_target(node: Node2D):
	target_node = node
	if node:
		# Warp mostly to target to avoid long pans if far away, OR let it fly:
		# Let's let it fly to look cool ("worked transitions")
		pass

func set_limits(rect: Rect2):
	target_limits_rect = rect

func toggle_mode():
	is_free_roam = !is_free_roam
	
	if is_free_roam:
		position_smoothing_enabled = false
	else:
		position_smoothing_enabled = true
