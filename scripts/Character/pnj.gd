class_name PNJ extends CharacterBase

@export var QuestGiverDialogueSystem : DialogueSystem

@onready var dialogue_system: DialogueSystem = $DialogueSystem
var current_quest : QuestBase


@onready var north: Marker2D = $Direction/North
@onready var east: Marker2D = $Direction/East
@onready var south: Marker2D = $Direction/South
@onready var west: Marker2D = $Direction/West

var quest_icon : Sprite2D
@export var quest_icon_texture : Texture2D
@export var quest_icon_offset : Vector2 = Vector2(0, -20)

func _ready() -> void:
	super._ready()
	
	# Gestion de la texture par défaut
	if quest_icon_texture == null:
		var loaded_tex = load("res://scenes/sprites/quest_icon.png")
		if loaded_tex:
			quest_icon_texture = loaded_tex

	# Recherche du noeud dans la scène (Priorité Manuelle)
	if has_node("QuestIcon"):
		quest_icon = get_node("QuestIcon")
		# On applique la texture si le noeud n'en a pas
		if quest_icon.texture == null and quest_icon_texture:
			quest_icon.texture = quest_icon_texture
	else:
		# Création dynamique (Fallback Automatique pour Zombies/Squelettes qui n'ont pas la scène PNJ mise à jour)
		quest_icon = Sprite2D.new()
		quest_icon.name = "QuestIcon"
		add_child(quest_icon)
		
		quest_icon.position = quest_icon_offset
		quest_icon.visible = false
		quest_icon.scale = Vector2(0.3, 0.3)
		quest_icon.z_index = 10
		
		if quest_icon_texture:
			quest_icon.texture = quest_icon_texture
		else:
			# Création d'une texture Placeholder (Carré Rouge) si l'image n'est pas trouvée
			var placeholder = PlaceholderTexture2D.new()
			placeholder.size = Vector2(32, 64)
			quest_icon.texture = placeholder
			quest_icon.modulate = Color.RED
			# On ne spam pas d'erreur, juste un warning unique si possible, mais ici c'est par instance
			# printerr("PNJ: Quest Icon texture missing, using placeholder.")

func _process(delta: float) -> void:
	super._process(delta)
	_update_quest_icon()

func _update_quest_icon():
	if not quest_icon or not dialogue_system:
		return
		
	# Vérifie si le PNJ a une quête non finie
	var has_active_quest = dialogue_system.has_quest and not dialogue_system.quest_ended
	
	if has_active_quest:
		# Si le joueur est proche (UI d'interaction visible), on cache l'icône
		# On accède au label via le composant interractable lié au système de dialogue
		if dialogue_system.interractable and dialogue_system.interractable.label and dialogue_system.interractable.label.visible:
			quest_icon.visible = false
		else:
			quest_icon.visible = true
	else:
		quest_icon.visible = false

func _get_direction_position(direction : DialogueSystem.Directions) -> Vector2 :
	match direction:
		DialogueSystem.Directions.NORD: return north.global_position
		DialogueSystem.Directions.EST : return east.global_position
		DialogueSystem.Directions.SUD : return south.global_position
		DialogueSystem.Directions.OUEST : return west.global_position
	push_warning("No directions match with " + str(direction) + "Fallback on NORD")
	return north.global_position

func _update_state(_delta : float):
	pass


func create_dialogue():
	dialogue_system.generate_new_quest()
