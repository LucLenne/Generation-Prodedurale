extends CanvasLayer

@export var game_scene: PackedScene


@onready var menu_container: VBoxContainer = $MainMenu
@onready var credits_container: Control = $Credits

func _ready() -> void:
	menu_container.visible = true
	credits_container.visible = false

func _on_play_btn_pressed() -> void:
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)
	else:
		push_error("Attention : Aucune scène de jeu n'est assignée dans l'inspecteur du MainMenu !")

func _on_credit_btn_pressed() -> void:
	menu_container.visible = false
	credits_container.visible = true

func _on_quit_btn_pressed() -> void:
	get_tree().quit()

func _on_back_to_menu_btn_pressed() -> void:
	credits_container.visible = false
	menu_container.visible = true
