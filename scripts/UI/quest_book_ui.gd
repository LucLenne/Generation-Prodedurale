class_name QuestBookUI extends CanvasLayer

var _quest_ui = preload("res://scenes/ui/quest_ui.tscn")
@onready var left = $LeftPage
@onready var friendly = $RightPage/Friendly
@onready var intimidating = $RightPage/Intimidating
@onready var Persuasive = $RightPage/Persuasive
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

func _show_stat():
	if Player.Instance:
		friendly.text = "Amical : " + str(Player.Instance._friendly)
		intimidating.text = "Intimidating : " + str(Player.Instance._intimidating)
		Persuasive.text = "Persuasif : " + str(Player.Instance._persuasive)

func _process(delta: float) -> void:
	_show_stat()
