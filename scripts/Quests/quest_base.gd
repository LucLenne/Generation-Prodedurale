class_name QuestBase extends Node2D


enum TYPE {COLLECT, KILL, EXPLORE, DELIVERY, TALK, NONE}
enum STATE { TO_DO,SUCCESS,FAIL}

var _state : STATE = STATE.TO_DO
var type : TYPE = TYPE.NONE
var id : int

@export var _amount_life_reward : int = 5

func _valid_quest() -> void:
	_state = STATE.SUCCESS
	_give_reward()
	
func _fail_quest()-> void:
	_state = STATE.FAIL

func _give_reward()-> void:
	Player.Instance.give_life(_amount_life_reward)

func setup(world_gen: Node2D) -> void:
	pass
