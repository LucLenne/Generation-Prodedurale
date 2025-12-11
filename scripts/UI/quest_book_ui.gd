class_name QuestBookUI extends Control
static var Instance : QuestBookUI

var _quest_ui = preload("res://scripts/UI/quest_ui.gd")
@onready var left = $LeftPage
@onready var friendly : Label = $RightPage/Friendly
@onready var intimidating : Label = $RightPage/Initimidating
@onready var persuiasive : Label = $RightPage/Persuasive
@export var _img_quest : Array[Texture]
@export var _page_max_quest : int = 8

func _init() -> void:
	visible = false

func create_quest(text : String, id : int) -> void:
	var new_quest = _quest_ui.instantiate()
	if new_quest is quest_ui:
		new_quest.id = id
		new_quest.Text = text
		left.add_child(new_quest)

func delete_quest(id : int):
	var childs_left = left.get_children()
	for quest in childs_left:
		if quest is quest_ui:
			if id == quest.id:
				quest.queue_free()
				return
	print("no quest with this id found in the ui")
func _process(_delta: float) -> void:
	_display_stats()
func _display_stats():
	if Player.Instance:
		friendly.text = "Amical : " + str(Player.Instance._friendly)
		intimidating.text = "Intimidant : " + str(Player.Instance._intimidating)
		persuiasive.text = "Persuasif : " + str(Player.Instance._persuasive)
