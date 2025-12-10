class_name QuestBase extends Node2D


enum TYPE {COLLECT, KILL, EXPLORE, DELIVERY, TALK, NONE}
enum STATE { INACTIVE ,ACTIVE,SUCCESS,FAIL}

var _state : STATE = STATE.ACTIVE
var type : TYPE = TYPE.NONE
var id : int
@export var title : String

func _valid_quest() -> void:
	_state = STATE.SUCCESS
	_give_reward()
	
func _fail_quest()-> void:
	_state = STATE.FAIL


func _give_reward()-> void:
	Player.Instance.life += Player.Instance.life_to_add
	

func setup(world_gen: Node2D) -> void:
	pass
