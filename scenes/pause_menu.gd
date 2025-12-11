extends CanvasLayer



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
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("OpenPauseMenu") :
		visible = true;
