extends Sprite2D
@onready var label: Label = $Label

signal OnPlayerInterract

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if label.is_visible_in_tree() :
		if Input.is_action_just_pressed("Interract") :
			OnPlayerInterract.emit()
	

func _on_area_2d_body_entered(_body: Node2D) -> void:
	label.visible = true


func _on_area_2d_body_exited(_body: Node2D) -> void:
	label.visible = false


func _on_on_player_interract() -> void:
	print("Player is interracting in area of Node")
	pass # Replace with function body.
