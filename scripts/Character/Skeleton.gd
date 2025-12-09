extends Enemy
class_name Skeleton

@export var linked_grave : Node2D
var _is_resurrecting : bool = false

func _ready() -> void:
	super._ready()
	life = 10 # Faibles HP
	print("Skeleton spawn: Life=10, Grave=" + str(linked_grave))

func apply_hit(attack : Attack) -> void:
	# Si on est déjà un tas d'os, on ignore les coups (ou on pourrait détruire le tas d'os ?)
	if _is_resurrecting:
		return
		
	super.apply_hit(attack)

func _set_state(state : STATE) -> void:
	# Interception de la mort
	if state == STATE.DEAD:
		if is_instance_valid(linked_grave):
			_start_resurrection()
			return
		else:
			# Vraie mort si pas de tombe
			super._set_state(STATE.DEAD)
			return

	super._set_state(state)

func _start_resurrection() -> void:
	if _is_resurrecting:
		return
		
	print("Skeleton: Collapsing to bones... Resurrecting in 15s.")
	_is_resurrecting = true
	# On simule l'état "Tas d'os" via STUNNED pour empêcher le mouvement
	super._set_state(STATE.STUNNED)
	# Feedback visuel (si possible)
	_set_color(Color.WEB_GRAY)
	
	await get_tree().create_timer(15.0).timeout
	
	if is_instance_valid(linked_grave):
		_resurrect()
	else:
		# Si la tombe a été détruite pendant l'attente
		super._set_state(STATE.DEAD)

func _resurrect() -> void:
	print("Skeleton: Arise!")
	_is_resurrecting = false
	life = 10 # Restauration des PV
	_set_color(Color.WHITE)
	_set_state(STATE.IDLE)
