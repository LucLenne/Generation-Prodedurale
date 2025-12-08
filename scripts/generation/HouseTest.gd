class_name HouseTest extends Node2D

@export var house_count = 5
@export var map_size = Vector2i(50, 40)
@export var ground_layer : TileMapLayer
@export var wall_layer : TileMapLayer
@export var npc_scene : PackedScene

const HouseGenScript = preload("res://scripts/generation/HouseGenerator.gd")

# Tile Constants (Same as WorldGenerator)
const TILE_SOURCE_ID = 1
const ATLAS_COORDS_GRASS = Vector2i(5, 4)
const ATLAS_COORDS_WALL = Vector2i(2, 4)
const ATLAS_COORDS_FLOOR = Vector2i(0, 6)
const ATLAS_COORDS_DOOR = Vector2i(4, 2)

func _ready():
	if npc_scene == null:
		npc_scene = preload("res://scenes/generation/NPC.tscn")
		
	generate_test_houses()

func _input(event):
	if event.is_action_pressed("ui_accept"): # Space to regenerate
		generate_test_houses()

func generate_test_houses():
	print("Generating Test Houses...")
	ground_layer.clear()
	wall_layer.clear()
	
	# Clear existing NPCs
	for child in get_children():
		if child is NPC:
			child.queue_free()
	
	# Background loop removed as requested

	
	var center = map_size / 2
	
	var houses_data = HouseGenScript.generate_clustered_houses(
		house_count,
		center,
		map_size.x,
		map_size.y
	)
	
	for data in houses_data:
		build_house(data)

func build_house(data):
	# Floor
	for cell in data.floor_cells:
		ground_layer.set_cell(cell, TILE_SOURCE_ID, ATLAS_COORDS_FLOOR)
		
	# Walls
	for cell in data.wall_cells:
		wall_layer.set_cell(cell, TILE_SOURCE_ID, ATLAS_COORDS_WALL)
	
	# Door
	wall_layer.set_cell(data.door_position, -1)
	
	# NPC
	var npc = npc_scene.instantiate()
	npc.position = data.npc_position * 8 # TILE_SIZE
	add_child(npc)
	
	# Interior
	for deco in data.interior_decorations:
		ground_layer.set_cell(deco.pos, 0, Vector2i.ZERO, deco.id)
