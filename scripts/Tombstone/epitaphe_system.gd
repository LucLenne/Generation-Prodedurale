class_name EpitaphSystem extends Control

@onready var timer: Timer = $Timer
@onready var label: Label = $MarginContainer/Label

var text = ""
var letter_index: int = 0


@export_group("UI Parameters")
@export var letter_time: float = 0.03
@export var space_time : float = 0.06
@export var punctuation_time : float = 0.2


signal finished_displaying()

const  MAX_WIDTH = 128
		

func display_text(text_to_display: String):
	text = text_to_display
	label.text = text_to_display
	
	await resized
	custom_minimum_size.x = min(size.x, MAX_WIDTH)
	
	if size.x > MAX_WIDTH :
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		await resized #wait for x resize
		await resized #wait for y resize
		custom_minimum_size.y = size.y
		
	global_position.x -= size.x / 2
	global_position.y -= size.y + 24
	
	label.text = ""
	_display_letter()
		
func _display_letter():
	label.text += text[letter_index]
	
	letter_index += 1
	if letter_index >= text.length() :
		finished_displaying.emit()
		timer.stop()
		return 
		
	match text[letter_index] :
		"!", ".", ",", "?" :
			timer.start(punctuation_time)
		" ":
			timer.start(space_time)
		_ :
			timer.start(letter_time)
	

func _on_timer_timeout() -> void:
	_display_letter()
