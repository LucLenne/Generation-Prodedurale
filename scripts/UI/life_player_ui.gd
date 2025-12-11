extends CanvasLayer

@onready var label_life = $background/number_life

var current_player = null

func _process(delta: float) -> void:
	# Détecte si la référence du joueur a changé (ex: respawn)
	if Player.Instance != current_player:
		current_player = Player.Instance
		
		if current_player:
			# Connecte le signal si pas déjà fait
			if not current_player.life_changed.is_connected(_on_life_changed):
				current_player.life_changed.connect(_on_life_changed)
			
			# Met à jour l'affichage immédiatement
			_on_life_changed(current_player.life)
		else:
			# Si pas de joueur (pendant la regen), on peut afficher 0 ou ?
			label_life.text = "?"

func _on_life_changed(new_life: int) -> void:
	label_life.text = str(new_life)
