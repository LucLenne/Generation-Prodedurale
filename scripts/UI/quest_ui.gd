class_name quest_ui extends Control


@export var Text : String = ""
@export var img : Texture


func _init() -> void :
	while(Text == ""):
		_try_init_value()
	
	
func _try_init_value() -> void:
	var image = $image
	var text = $text
	if image is Texture:
		image.texture = img
	if text is Label:
		text.text = Text
