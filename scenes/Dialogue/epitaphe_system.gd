class_name EpitaphSystem extends Control

@export_group("UI Bindings")
@export var dialogue_text: RichTextLabel
@export var dialogue_container: PanelContainer
@export var click_button: Button


@export_group("UI Parameters")
@export var typing_speed: float = 0.02 # Secondes par caractère

var text_queue: Array[String] = []
var is_typing: bool = false
var current_tween: Tween

		
func _ready():
	click_button.pressed.connect(_on_bubble_clicked)


func _on_bubble_clicked():
	if is_typing:
		if current_tween:
			current_tween.kill()
		dialogue_text.visible_ratio = 1.0
		is_typing = false
		
	else:
		if not text_queue.is_empty():
			_display_next_line()
		else:
			close_dialogue()

func close_dialogue():
	visible = false

func show_epitaph_text(text: String):
	start_dialogue_sequence(text, false)
	
	

func start_dialogue_sequence(raw_text: String, is_interactive: bool):
	visible = true
	var parts = raw_text.split("&&")
	text_queue.clear()
	for part in parts:
		var p = part.strip_edges()
		if not p.is_empty():
			text_queue.append(p)
			
	if text_queue.is_empty():
		text_queue.append("...")
		
	_display_next_line()


func _display_next_line():
	if text_queue.is_empty():
		return
		
	var line = text_queue.pop_front()
	dialogue_text.text = line
	dialogue_text.visible_ratio = 0.0
	_start_typing_effect()


func _start_typing_effect():
	is_typing = true
	
	if current_tween:
		current_tween.kill() 
	
	current_tween = create_tween()
	
	var duration = dialogue_text.get_total_character_count() * typing_speed
	
	current_tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)
	
	current_tween.finished.connect(_on_typing_finished)

func _on_typing_finished():
	is_typing = false
	dialogue_text.visible_ratio = 1.0
