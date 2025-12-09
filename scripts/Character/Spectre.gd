extends Enemy
class_name Spectre

@export var linked_anchor : Node2D
@export var zone_radius : float = 150.0

var _start_position : Vector2

func _ready() -> void:
	super._ready()
	_start_position = global_position
	speed_max = 60.0 # Plus lent, fantomatique
	
	if is_instance_valid(linked_anchor):
		# On surveille la destruction de l'ancre
		linked_anchor.tree_exited.connect(_on_anchor_destroyed)
	else:
		push_warning("Spectre: Pas d'ancre liée (linked_anchor) !")

func apply_hit(attack : Attack) -> void:
	# Invulnérabilité aux dégâts physiques (tous les dégâts pour l'instant)
	# On ne fait rien.
	pass

func _update_state(delta : float) -> void:
	# Logique standard d'abord (Chasse, etc)
	super._update_state(delta)
	
	# Contrainte de zone
	if _state == STATE.CHASE:
		# Si le spectre s'éloigne trop de son ancre/point de départ
		if global_position.distance_to(_start_position) > zone_radius:
			print("Spectre: Trop loin de la zone, retour...")
			target = null
			_set_state(STATE.IDLE)
			# Optionnel : Ajouter une logique de retour au point de départ (ReturnToHome)
			# Pour l'instant, IDLE arrêtera le mouvement ou errera.

	# Si la cible est hors de la zone, on lâche l'aggro rapidement
	if target and target.global_position.distance_to(_start_position) > zone_radius:
		target = null
		_set_state(STATE.IDLE)

func _on_anchor_destroyed() -> void:
	print("Spectre: Ancre détruite ! Mort instantanée.")
	# On force la mort en contournant apply_hit
	life = 0
	# On appelle directement CharacterBase._set_state(DEAD) via super (mais ici Enemy._set_state appelle CharacterBase)
	# Comme on hérite de Enemy, on peut appeler _set_state
	_set_state(STATE.DEAD)
