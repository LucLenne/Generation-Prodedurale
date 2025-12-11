class_name Enemy extends PNJ

@export_group("AI")
@export var is_hostile : bool = false
@export var detection_radius : float = 200.0
@export var attack_distance : float = 40.0
@export var attack_warm_up : float = 0.5
@export var chase_limit_distance : float = 300.0

var start_position : Vector2
var target : Node2D
var _state_timer : float = 0.0

func _ready() -> void:
	super._ready()
	start_position = global_position
	_set_state(STATE.IDLE)

func _process(delta: float) -> void:
	super(delta)

# Surcharge de apply_hit pour réagir aux attaques (Neutral -> Hostile)
func apply_hit(attack : Attack) -> void:
	super.apply_hit(attack)
	if _state != STATE.DEAD and attack != null and attack.attack_owner is Player:
		if !is_hostile:
			is_hostile = true
		target = attack.attack_owner
		_set_state(STATE.CHASE)

func _update_state(delta : float) -> void:
	if _state != STATE.ATTACKING:
		_state_timer = 0.0
	else:
		_state_timer += delta

	match _state:
		STATE.IDLE:
			_direction = Vector2.ZERO
			if is_hostile:
				_detect_target()
			
		STATE.CHASE:
			if is_instance_valid(target):
				var dist = global_position.distance_to(target.global_position)
				if global_position.distance_to(start_position) > chase_limit_distance:
					target = null
					_set_state(STATE.RETURN)
				elif dist <= attack_distance:
					_start_attack()
				elif dist > detection_radius * 2.0: # Abandon chase if too far
					target = null
					_set_state(STATE.IDLE)
				else:
					_direction = (target.global_position - global_position).normalized()
			else:
				# Target lost or dead
				_set_state(STATE.IDLE)
		
		STATE.RETURN:
			var dist = global_position.distance_to(start_position)
			if dist < 5.0:
				_set_state(STATE.IDLE)
				_direction = Vector2.ZERO
			else:
				_direction = (start_position - global_position).normalized()

		STATE.ATTACKING:
			# Attente du warm_up avant de spawn la hitbox
			_direction = Vector2.ZERO
			if _state_timer >= attack_warm_up:
				_spawn_attack_scene()
				# Après l'attaque, on retourne en chasse ou idle
				if is_instance_valid(target) and global_position.distance_to(start_position) <= chase_limit_distance:
					_set_state(STATE.CHASE)
				else:
					_set_state(STATE.RETURN)
		
		STATE.DEAD:
			_direction = Vector2.ZERO
			# La mort est gérée par CharacterBase, mais on peut ajouter des effets ici
			pass

func _detect_target() -> void:
	if Player.Instance:
		var dist = global_position.distance_to(Player.Instance.global_position)
		if dist <= detection_radius:
			target = Player.Instance
			_set_state(STATE.CHASE)

func _start_attack() -> void:
	# On passe en ATTACKING seulement si le cooldown de base est respecté
	# _attack() de CharacterBase gère le cooldown et set STATE.ATTACKING
	if Time.get_unix_time_from_system() - _last_attack_time >= attack_cooldown:
		_last_attack_time = Time.get_unix_time_from_system()
		_set_state(STATE.ATTACKING)

func _set_state(state : STATE) -> void:
	super._set_state(state)
	if state == STATE.ATTACKING:
		_state_timer = 0.0
