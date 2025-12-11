class_name quest_ui extends Control


var id : int 

func _ready() -> void:
	_update_ui()

var Text : String = "" :
	set(value):
		if not value.begins_with("- "):
			value = "- " + value
		Text = value
		_update_ui()

var img : Texture :
	set(value):
		img = value
		_update_ui()

func _update_ui() -> void:
	if not is_inside_tree(): return
	
	var image_node = $image
	var text_node = $text
	
	if image_node and img:
		image_node.texture = img
		
	if text_node is Label:
		text_node.text = Text
