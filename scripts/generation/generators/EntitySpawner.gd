## Spawn le joueur et les PNJs dans le monde.
## Place les entités près des portes des bâtiments.
class_name EntitySpawner extends RefCounted

const TileConfigScript = preload("res://scripts/generation/TileConfig.gd")

var player_scene: PackedScene
var npc_scene: PackedScene
var manager_quest_scene: PackedScene
var hud_scene: PackedScene


func _init(p_scene: PackedScene, n_scene: PackedScene, mq_scene: PackedScene, h_scene: PackedScene):
	player_scene = p_scene
	npc_scene = n_scene
	manager_quest_scene = mq_scene
	hud_scene = h_scene


## Instancie le ManagerQuest si nécessaire.
func spawn_manager_quest(parent: Node2D, _world_gen: Node2D):
	if ManagerQuest != null:
		return
	
	if manager_quest_scene:
		var instance = manager_quest_scene.instantiate()
		parent.add_child(instance)
		if parent.has_method("register_generated_object"):
			parent.register_generated_object(instance)


## Spawn les PNJs près des portes des bâtiments.
func spawn_npcs(data: MapData, parent: Node2D):
	if npc_scene == null:
		return
	
	# Spawn près des portes de chaque zone
	for zone in data.zones:
		var doors = zone.get_meta("building_doors", [])
		for door in doors:
			var pos = Vector2(door.x, door.y + 1)
			_spawn_single_npc(parent, pos)
	
	# Spawn les PNJs des maisons procédurales
	if data.has_meta("pending_npc_spawns"):
		var pending = data.get_meta("pending_npc_spawns")
		for pos in pending:
			_spawn_single_npc(parent, pos)


func _spawn_single_npc(parent: Node2D, pos: Vector2):
	var npc = npc_scene.instantiate()
	npc.position = pos * TileConfigScript.TILE_SIZE
	parent.add_child(npc)
	
	if parent.has_method("register_npc"):
		parent.register_npc(npc)


## Spawn le joueur dans la première zone.
func spawn_player(data: MapData, parent: Node2D) -> Node2D:
	if player_scene == null:
		printerr("Player scene not assigned!")
		return null
	
	if data.zones.is_empty():
		printerr("No zones generated, cannot spawn player.")
		return null
	
	print("Spawning player...")
	var player = player_scene.instantiate()
	
	# Ajout du HUD si disponible
	if hud_scene:
		print("Spawning HUD...")
		var hud = hud_scene.instantiate()
		player.add_child(hud)
	else:
		printerr("HUD scene not assigned in EntitySpawner!")
	
	# Cherche une position valide près du centre de la première zone
	var center = data.zones[0].center
	var spawn_pos = _find_valid_spawn(data, center)
	
	player.position = Vector2(spawn_pos) * TileConfigScript.TILE_SIZE
	parent.add_child(player)
	
	# Configure les limites de la caméra
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = data.width * TileConfigScript.TILE_SIZE
		camera.limit_bottom = data.height * TileConfigScript.TILE_SIZE
	
	return player


## Trouve une position de spawn valide près d'un centre.
func _find_valid_spawn(data: MapData, center: Vector2i) -> Vector2i:
	for radius in range(0, 10):
		for x in range(center.x - radius, center.x + radius + 1):
			for y in range(center.y - radius, center.y + radius + 1):
				var cell = Vector2i(x, y)
				if not data.is_in_bounds(cell.x, cell.y):
					continue
				
				# Évite les murs et l'eau
				if data.wall_layer.get_cell_source_id(cell) != -1:
					continue
				if TileConfigScript.is_water(data.wall_layer.get_cell_atlas_coords(cell)):
					continue
				
				return cell
	
	return center
