class_name DialogueSystemUI extends Control

signal dialogue_closed 
signal player_answered(mood: DialogueSystem.Mood)

@export_group("UI Bindings")
@export var dialogue_text: RichTextLabel
@export var response_container: HBoxContainer
@export var dialogue_container: PanelContainer
@export var click_button: Button


@export var btn_intimidate: Button
@export var btn_friendly: Button
@export var btn_persuade: Button


@export_group("UI Parameters")
@export var typing_speed: float = 0.02 # Secondes par caractère

var is_typing: bool = false
var is_interaction_mode: bool = false
var current_tween: Tween

func _ready():
	response_container.visible = false
	
	btn_intimidate.pressed.connect(_on_response_pressed.bind(DialogueSystem.Mood.INTIMIDATING))
	btn_friendly.pressed.connect(_on_response_pressed.bind(DialogueSystem.Mood.FRIENDLY))
	btn_persuade.pressed.connect(_on_response_pressed.bind(DialogueSystem.Mood.PERSUASIVE))

	click_button.pressed.connect(_on_bubble_clicked)


func _on_bubble_clicked():
	if is_typing:
		if current_tween:
			current_tween.kill()
		dialogue_text.visible_ratio = 1.0
		is_typing = false
		
	else:
		if is_interaction_mode:
			response_container.visible = true
		else:
			close_dialogue()

func _on_response_pressed(mood: DialogueSystem.Mood):
	player_answered.emit(mood)
	close_dialogue()

func close_dialogue():
	visible = false
	dialogue_closed.emit()

func show_intro_dialogue(text: String):
	is_interaction_mode = false
	_start_dialogue(text)

func show_interaction_dialogue(data: Dictionary):
	is_interaction_mode = true
	
	btn_intimidate.text = data["btn_intimidate"]
	btn_friendly.text = data["btn_friendly"]
	btn_persuade.text = data["btn_persuade"]
	
	_start_dialogue(data["text"])


func _start_dialogue(text: String):
	visible = true
	response_container.visible = false
	dialogue_text.text = text
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
