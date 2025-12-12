extends CanvasLayer

# =============================================================================
# QUEST FEEDBACK UI
# =============================================================================

var feedback_container: CenterContainer
var feedback_label: Label
var feedback_bg: ColorRect

func _setup_feedback_ui():
	# Create overlay container (Center of screen)
	feedback_container = CenterContainer.new()
	feedback_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	feedback_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(feedback_container)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	feedback_container.add_child(vbox)
	
	# Background for readability
	feedback_bg = ColorRect.new()
	feedback_bg.custom_minimum_size = Vector2(400, 100)
	feedback_bg.color = Color(0, 0, 0, 0.7)
	# vbox.add_child(feedback_bg) # Optionnel: fond
	
	feedback_label = Label.new()
	feedback_label.text = "QUEST COMPLETE"
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 32)
	feedback_label.add_theme_color_override("font_color", Color.GREEN)
	feedback_label.add_theme_constant_override("outline_size", 4)
	feedback_label.add_theme_color_override("font_outline_color", Color.BLACK)
	vbox.add_child(feedback_label)
	
	feedback_container.modulate.a = 0.0
	feedback_container.hide()

func _ready() -> void:
	print("HUD: _ready called")
		
	# Setup Quest Feedback
	_setup_feedback_ui()
	if ManagerQuest:
		print("HUD: Connecting to ManagerQuest signal")
		ManagerQuest.quest_finished.connect(_on_quest_finished)
	else:
		printerr("HUD: ManagerQuest Global NOT found!")

func _on_quest_finished(quest, success: bool):
	print("HUD: Quest Finished Signal Received! Success: ", success)
	if not feedback_container: return
	
	feedback_container.show()
	feedback_container.modulate.a = 0.0
	
	if success:
		feedback_label.text = "QUÊTE RÉUSSIE !\n" + quest.title
		feedback_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		feedback_label.text = "ÉCHEC DE LA QUÊTE\n" + quest.title
		feedback_label.add_theme_color_override("font_color", Color.RED)
		
	var tween = create_tween()
	tween.tween_property(feedback_container, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	tween.tween_interval(2.5)
	tween.tween_property(feedback_container, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(feedback_container.hide)
