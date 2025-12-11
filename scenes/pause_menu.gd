extends CanvasLayer

@export var menu_scene: PackedScene

func _on_resume_btn_pressed() -> void:
	visible = false
	
func _on_reload_btn_pressed() -> void:
	if DialogueSystemUI.instance :
		DialogueSystemUI.instance.reset_ui()
	DialogueSystemUI.instance = null
	Player.Instance = null
	PopupManager.reset_dialog()
	get_tree().reload_current_scene()


func _on_go_to_menu_btn_pressed() -> void:
	if menu_scene:
		get_tree().change_scene_to_packed(menu_scene)
	else:
		push_error("Attention : Aucune scène de jeu n'est assignée dans l'inspecteur du PauseMenu !")
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("OpenPauseMenu") :
		visible = true;
