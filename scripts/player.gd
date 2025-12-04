extends CharacterBody2D

@export var speed: float = 100.0

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
		
	
	if direction != Vector2.ZERO:
		print("Input detected: ", direction)
		
	velocity = direction * speed
	move_and_slide()
	
	if velocity != Vector2.ZERO:
		print("Player moving, velocity: ", velocity, " Position: ", position)
