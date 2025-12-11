extends CharacterBase
class_name PlayerController

func _ready() -> void:
	randomize()
	_friendly = randi_range(5, 10)
	_intimidating = randi_range(5, 10)
	_persuasive = randi_range(5, 10)
	print("PlayerController Stats: Friendly=%d, Intimidating=%d, Persuasive=%d" % [_friendly, _intimidating, _persuasive])
	
	if default_movement:
		_current_movement = default_movement
	else:
		push_warning("PlayerController: 'Default Movement' n'est pas assigné dans l'inspecteur !")



func _update_state(delta: float) -> void:
	if !_can_move():
		_direction = Vector2.ZERO
		return
	
	# 1. Gestion des Mouvements (ZQSD)
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("Left", "Right")
	input_vector.y = Input.get_axis("Up", "Down")
	_direction = input_vector.normalized()
	
	# 2. Gestion du Combat
	if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("Attack"):
		_attack()
	
	## 3. Gestion de l'Interaction
	#if Input.is_action_just_pressed("interact"):
		#_interact()

func _attack() -> void:
	super._attack()
	
	if _state == STATE.ATTACKING:
		_spawn_attack_scene()
		
		await get_tree().create_timer(attack_cooldown).timeout
		
		if _state == STATE.ATTACKING:
			_set_state(STATE.IDLE)

#func _unhandled_input(event: InputEvent) -> void:
	#if !_can_move():
		#return
		#
	#if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		#_interact()

#func _interact() -> void:
	#var space_state = get_world_2d().direct_space_state
	#
	#if main_sprite == null:
		#push_error("Main Sprite non assigné dans CharacterBase (BodySprite introuvable ?)")
		#return
#
	#var look_direction = Vector2.RIGHT.rotated(main_sprite.rotation)
	#if look_direction.length_squared() < 0.1:
		#look_direction = Vector2.DOWN
		#
	#var query = PhysicsRayQueryParameters2D.create(global_position, global_position + look_direction * 50)
	#query.collide_with_areas = true
	#query.collide_with_bodies = true
	#query.exclude = [self.get_rid()]
	#
	#var result = space_state.intersect_ray(query)
	#if result:
		#var collider = result.collider
		#
		#if collider.has_method("interact"):
			#collider.interact(self)
		#elif collider.get_parent() and collider.get_parent().has_method("interact"):
			#collider.get_parent().interact(self)
