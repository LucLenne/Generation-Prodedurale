class_name Player extends CharacterBody2D
static var Instance : Player

@export var speed: float = 100.0
var _quest_book_ui = preload("res://scripts/UI/quest_book_ui.gd")

func _ready():
	$Camera2D.make_current()


func _physics_process(delta):
	var direction = Vector2.ZERO
	
	if direction == Vector2.ZERO:
		if Input.is_action_pressed("Up"): direction.y -= 1
		if Input.is_action_pressed("Down"): direction.y += 1
		if Input.is_action_pressed("Left"): direction.x -= 1
		if Input.is_action_pressed("Right"): direction.x += 1
		direction = direction.normalized()
	if(Input.is_action_pressed("open_inventory")):
		if _quest_book_ui is QuestBookUI:
			_quest_book_ui.visible = !_quest_book_ui.visible
	velocity = direction * speed
	move_and_slide()
	
	if velocity != Vector2.ZERO:
		pass
		
	detect_biome()

var current_biome_name: String = ""

func detect_biome():
	var world_gen = get_parent()
	if world_gen and world_gen.has_method("get_biome_at"):
		var biome = world_gen.get_biome_at(position)
		if biome:
			if biome.biome_name != current_biome_name:
				current_biome_name = biome.biome_name
				print("Entered Biome: ", current_biome_name)
