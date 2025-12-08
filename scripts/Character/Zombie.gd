extends Enemy
class_name Zombie

func _ready() -> void:
	super._ready()
	# Zombie est toujours hostile et a beaucoup de vie
	is_hostile = true
	# On s'assure d'avoir des stats de "brute"
	life = 50 # Exemple de "Beaucoup de points de vie"
	attack_warm_up = 0.8
	if default_movement:
		default_movement = default_movement.duplicate()
		default_movement.speed_max = 80.0
	print("Zombie spawn: Life=50, Hostile=True")
