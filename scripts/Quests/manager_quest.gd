class_name QuestManager extends Node
static var Instance : QuestManager

const TileConfigScript = preload("res://scripts/generation/TileConfig.gd")


@export_group("Génération")
@export var _numberQuest : int = 5
@export var list_collectibles : Array[CollectibleBase]
@export var list_biomes : Array[String]
@export var list_character_to_kill : Array[PackedScene]
@export var list_pnj : Array[PackedScene]
var _pnj_in_quest : Array[PNJ]

func _enter_tree() -> void:
	if Instance == null:
		Instance = self
	else:
		queue_free()

@export_group("Talk")
@export var max_dist_pnj : float = 50
@export var entity_scale : Vector2 = Vector2.ONE


var _typeQuest : Array[Script] = [CollectQuest,DeliveryQuest,ExploreQuest,KillQuest,TalkQuest]
var _activeQuest : Array[QuestBase]
var _inactiveQuest : Array[QuestBase]
var _successQuest : Array[QuestBase]
var _failQuest : Array[QuestBase]

func spawn_entity_in_world(scene: PackedScene, min_dist: float = 100, max_dist: float = 300, specific_pos: Vector2 = Vector2.INF) -> Node2D:
	if scene == null: return null
	
	var instance = scene.instantiate() as Node2D
	if instance == null: return null
	
	instance.scale = entity_scale
	
	if specific_pos != Vector2.INF:
		instance.global_position = specific_pos
	else:
		var center = Vector2.ZERO
		if Player.Instance:
			center = Player.Instance.global_position
			
		var offset = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(min_dist, max_dist)
		instance.global_position = center + offset

	if Player.Instance and Player.Instance.get_parent():
		var parent = Player.Instance.get_parent()
		parent.call_deferred("add_child", instance)
		if parent.has_method("register_generated_object"):
			parent.call_deferred("register_generated_object", instance)
	else:
		get_tree().root.call_deferred("add_child", instance)
		
	return instance

func GetPNJ(world_gen: Node2D = null) -> PNJ:
	if list_pnj.is_empty():
		print("ManagerQuest: No PNJ scenes in list!")
		return null
		
	var scene = list_pnj.pick_random()
	var spawn_pos = Vector2.INF
	
	if world_gen and world_gen.has_method("get_random_building_door"):
		spawn_pos = world_gen.get_random_building_door()
	elif Player.Instance and Player.Instance.get_parent().has_method("get_random_building_door"):
		spawn_pos = Player.Instance.get_parent().get_random_building_door()
		
	var pnj = spawn_entity_in_world(scene, 50, max_dist_pnj, spawn_pos) as PNJ
	
	if pnj:
		_pnj_in_quest.append(pnj)
		return pnj
		
	return null

@export var quest_scenes : Array[PackedScene]

func spawn_quests_in_world(world_gen: WorldGenerator) -> void:
	if quest_scenes.is_empty():
		print("ManagerQuest: No quest scenes assigned.")
		return
		
	print("ManagerQuest: Spawning %d quests using Zones..." % _numberQuest)
	print("Debug - list_character_to_kill size: ", list_character_to_kill.size())
	print("Debug - list_pnj size: ", list_pnj.size())
	
	for i in range(_numberQuest):
		var scene = quest_scenes.pick_random()
		if scene == null: continue
		
		# 1. Determine size & footprint
		var temp = scene.instantiate()
		var quest_size = Vector2i(3,3)
		var offset = Vector2i.ZERO
		var actual_cells = []
		
		var tile_layer_node = temp.get_node_or_null("TileMapLayer")
		if not tile_layer_node:
			for child in temp.get_children():
				if child is TileMapLayer or child is TileMap:
					tile_layer_node = child
					break
					
		if tile_layer_node:
			var rect = tile_layer_node.get_used_rect()
			if rect.has_area():
				quest_size = rect.size
				offset = rect.position
				for cell in tile_layer_node.get_used_cells():
					actual_cells.append(cell - offset)

		# Fallback footprint
		if actual_cells.is_empty():
			for x in range(quest_size.x):
				for y in range(quest_size.y):
					actual_cells.append(Vector2i(x,y))
		temp.free()

		# 2. Find valid position
		var valid_pos = Vector2.INF
		
		# Gather spawn candidates (zone centers since we spawn BEFORE structures)
		var spawn_origins: Array[Vector2i] = []
		if world_gen.map_data:
			for zone in world_gen.map_data.zones:
				spawn_origins.append(zone.center)
		
		print("ManagerQuest: Found ", spawn_origins.size(), " spawn origins (Zone centers).")
		
		if spawn_origins.is_empty(): 
			spawn_origins.append(Vector2i(world_gen.width/2, world_gen.height/2))
		
		var occupied_cells = world_gen.map_data.reserved_cells
		var candidate_cell = Vector2i.ZERO
		
		for attempt in range(100):
			var origin = spawn_origins.pick_random()
			# Random offset near origin
			var r = randi_range(1, 10)
			var angle = randf() * TAU
			candidate_cell = origin + Vector2i(cos(angle)*r, sin(angle)*r)
			
			if not world_gen.map_data.is_in_bounds(candidate_cell.x, candidate_cell.y): continue
			
			var is_safe = true
			for rel_cell in actual_cells:
				var check_cell = candidate_cell + rel_cell
				
				# Check Bounds
				if not world_gen.map_data.is_in_bounds(check_cell.x, check_cell.y):
					is_safe = false; break
				
				# Check Strict Reservation (Walls, Buildings, Rivers)
				if occupied_cells.has(check_cell):
					is_safe = false; break
					
				# Check Water (Explicitly for safety)
				if TileConfigScript.is_water(world_gen.map_data.wall_layer.get_cell_atlas_coords(check_cell)):
					is_safe = false; break
					
				# Check Path (Optional but good)
				if world_gen.map_data.ground_layer.get_cell_atlas_coords(check_cell) == TileConfigScript.PATH:
					is_safe = false; break
			
			if is_safe:
				valid_pos = Vector2(candidate_cell) * TileConfigScript.TILE_SIZE
				
				# Register reservation immediately to prevent self-overlap in next loop
				for rel_cell in actual_cells:
					var check_cell = candidate_cell + rel_cell
					if world_gen.map_data:
						world_gen.map_data.reserved_cells[check_cell] = true
				break
		
		if valid_pos == Vector2.INF:
			print("ManagerQuest: Failed to find valid spot for quest ", i)
			continue
			
		var spawn_pos = valid_pos
		var instance = scene.instantiate()
		instance.position = spawn_pos - (Vector2(offset) * TileConfigScript.TILE_SIZE) # Adjust for offset because we calculated valid_pos as top-left of footprint relative to origin
		# Wait, valid_pos is based on candidate_cell which we treated as the anchor for (cell - offset).
		# In logic above: check_cell = candidate_cell + (cell - offset)
		# So candidate_cell represents the 'position' of the node (usually (0,0) of scene).
		# yes. So instance.position = valid_pos is correct assuming offset logic matches instantiation.
		# The offset was calculated as rect.position. actual_cells took this into account (cell - offset).
		# So actual_cells serves as relative coordinates from (0,0).
		# So candidate_cell is the World Position meant for (0,0) of the instance.
		
		instance.position = valid_pos # This should be correct without extra offset sub if valid_pos IS the origin.
		# Let's verify: check_cell = candidate_cell + rel_cell. rel_cell = cell_in_tilemap - offset.
		# If we place instance at candidate_cell, its tilemap will draw at (cell_in_tilemap).
		# Wait: instance pos (global) + tilemap cell pos (local) = world cell pos?
		# TileMapLayer in scene is at (0,0)? Usually yes.
		# If TileMapLayer is at (0,0), then drawing a tile at (2,2) means it appears at (2,2) relative to instance.
		# If instance is at (10,10), visual is (12,12).
		# Our math: check_cell = (10,10) + (2,2) - offset.
		# If offset is (0,0), check_cell is (12,12). Correct.
		# If offset is (2,2), rel_cell is (0,0). check_cell is (10,10). Visual is (12,12)?
		# No, offset is just to shift the "anchor" of our collision shape check.
		# Ideally we want to center or align.
		# Let's keep it simple: We validated that if we place the ORIGIN at candidate_cell, the tiles (shifted by offset logic) fall in safe spots.
		# But wait, actual_cells = cell - offset.
		# So we assumed we SHIFT the visual so that 'offset' becomes (0,0)? NO.
		# If we don't shift the instance visual, the tile at 'cell' will be at 'cell'.
		# If we want the collision check to match the visual:
		# Visual world pos = instance_pos + cell.
		# We checked: candidate_cell + (cell - offset).
		# So instance_pos must be = candidate_cell - offset.
		# wait...
		# If cell is (2,2) and offset is (2,2). rel is (0,0).
		# candidates_cell is (10,10). check_cell is (10,10).
		# If we place instance at (10,10), tile (2,2) is at (12,12).
		# Gap!
		
		# Correction:
		# We want to place the bounding box TOP-LEFT at candidate_cell.
		# rect.position is 'offset'.
		# If we want rect.position to align with candidate_cell?
		# No, we essentially treat actual_cells as "relative to some anchor".
		# Let's say we want to verify placing the instance at `P`.
		# Tile `C` is at `P + C`.
		# We want `P + C` to be safe.
		# In loop, we did `check = candidate + (C - offset)`.
		# This implies `P + C = candidate + C - offset`.
		# `P = candidate - offset`.
		# So `instance.position = (candidate - offset) * TILE_SIZE`.
		
		instance.position = valid_pos - (Vector2(offset) * TileConfigScript.TILE_SIZE)
		instance.scale = entity_scale
		world_gen.add_child(instance)
		
		if world_gen.has_method("register_generated_object"):
			world_gen.register_generated_object(instance)
		
		print("ManagerQuest: Spawned quest at ", instance.position)
		
		if instance is QuestBase:
			_inactiveQuest.append(instance)
			instance.setup(world_gen)

func DeleteQuestUI(id : int):
	QuestBookUI.Instance.delete_quest(id)

func ActivateQuest(pnj : PNJ):
	var quest = pnj.current_quest
	if quest._state == QuestBase.STATE.INACTIVE:
		_inactiveQuest.erase(quest)
		_activeQuest.append(quest)
		QuestBookUI.Instance._create_quest(str(quest.type),quest.id)
		return
	print("quest not inactive")

func _process(_delta: float) -> void:
	for quest in _activeQuest:
		if(quest._state == QuestBase.STATE.SUCCESS):
			DeleteQuestUI(quest.id)
			_successQuest.append(quest)
			_activeQuest.erase(quest)
		if(quest._state == QuestBase.STATE.FAIL):
			DeleteQuestUI(quest.id)
			_failQuest.append(quest)
			_activeQuest.erase(quest)
