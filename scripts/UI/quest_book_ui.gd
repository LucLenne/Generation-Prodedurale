class_name QuestBookUI extends Control
static var Instance : QuestBookUI

var _quest_ui = preload("res://scripts/UI/quest_ui.gd")
@onready var left = $LeftPage
@onready var right = $RightPage
@export var _img_quest : Array[Texture]
@export var _page_max_quest : int = 8

func _init() -> void:
	visible = false

func _create_quest(text : String, id : int) -> void:
	var new_quest = _quest_ui.instantiate()
	if new_quest is quest_ui:
		new_quest.id = id
		new_quest.Text = text
	if(!_is_left_container_full()):
		left.add_child(new_quest)
	else:
		right.add_child(new_quest)

func delete_quest(id : int):
	var childs_left = left.get_children()
	var childs_right = right.get_children()
	for quest in childs_left:
		if quest is quest_ui:
			if id == quest.id:
				quest.queue_free()
				return
	for quest in childs_right:
		if quest is quest_ui:
			if id == quest.id:
				quest.queue_free()
				return
	print("no quest with this id found in the ui")

func _is_left_container_full() -> bool : 
	return left.get_child_count() > _page_max_quest
