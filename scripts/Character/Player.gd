class_name Player extends PlayerController
static var Instance : Player

var _quest_book_ui = preload("res://scripts/UI/quest_book_ui.gd")
@export var life_to_add : int = 1
@export var life_to_loose : int = 1
@export var timer_damage : int = 15

var time_left : float = timer_damage

func _enter_tree():
	if Instance != null:
		push_warning("Attention : Deux Player existent en même temps !")
		queue_free()
		return
	Instance = self

func _exit_tree():
	if Instance == self:
		Instance = null
		
func _ready():
	super._ready()
	life = 20
	# Assign main sprite for rotation logic in base class
	main_sprite = $Sprite2D
	
	# Set Fixed orientation to prevent rotation
	orientation = ORIENTATION.FIXED
	
	# Setup default movement if not assigned in Inspector
	if default_movement == null:
		default_movement = MovementParameters.new()
		default_movement.speed_max = 400.0 # Much faster
		default_movement.acceleration = 2500.0 # Very snappy
		default_movement.friction = 2000.0
	
	_current_movement = default_movement
	
	# Camera setup is handled by WorldGenerator now, but we can ensure internal cam is off
	#$Camera2D.enabled = false

func _process(delta: float) -> void:
	super._process(delta) # Handles state updates
	_loose_life(delta)
	if(Input.is_action_just_pressed("open_inventory")):
		QuestBookUi.visible = !QuestBookUi.visible

func _physics_process(delta):
	# Map Input to _direction for CharacterBase
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("Up"): input_dir.y -= 1
	if Input.is_action_pressed("Down"): input_dir.y += 1
	if Input.is_action_pressed("Left"): input_dir.x -= 1
	if Input.is_action_pressed("Right"): input_dir.x += 1
	
	_direction = input_dir.normalized()
	
	# Call base physics (velocity calc + move_and_slide)
	super._physics_process(delta)
	
	# Camera updates
	if velocity != Vector2.ZERO:
		var world_gen = get_parent()
		if world_gen and world_gen.has_method("update_camera_limits"):
			world_gen.update_camera_limits(global_position)
		
	detect_biome()
	
	if Input.is_key_pressed(KEY_C):
		if not _c_pressed:
			_c_pressed = true
			var world_gen = get_parent()
			if world_gen and world_gen.has_method("toggle_camera"):
				world_gen.toggle_camera()
	else:
		_c_pressed = false

func _update_state(_delta : float):
	# Logic specific to player state?
	# For now, just keep it simple or delegate to base
	pass

var _c_pressed : bool = false
var current_biome_name: String = ""

func detect_biome():
	var world_gen = get_parent()
	if world_gen and world_gen.has_method("get_biome_at"):
		var biome = world_gen.get_biome_at(position)
		if biome:
			if biome.biome_name != current_biome_name:
				current_biome_name = biome.biome_name
				print("Entered Biome: ", current_biome_name)


func _loose_life(delta : float):
	time_left -= delta
	if time_left <= 0:
		time_left = timer_damage
		life -= life_to_loose
