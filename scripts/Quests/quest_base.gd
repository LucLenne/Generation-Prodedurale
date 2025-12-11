class_name QuestBase extends Node2D

enum TYPE {COLLECT, KILL, EXPLORE, DELIVERY, TALK, NONE}
enum STATE { INACTIVE ,ACTIVE,SUCCESS,FAIL}

var _state : STATE = STATE.ACTIVE
var type : TYPE = TYPE.NONE
var id : int
@export var title : String

@export var _amount_life_reward : int = 5

func _valid_quest() -> void:
	_state = STATE.SUCCESS
	_give_reward()
	
func _fail_quest()-> void:
	_state = STATE.FAIL


func _give_reward()-> void:
	pass

func setup(world_gen: Node2D) -> void:
	pass

func try_spawn_target(direction: String, distance: float, dialogue_ref: Object) -> bool:
	return false

func force_spawn_target(direction: String, distance: float, dialogue_ref: Object) -> bool:
	if try_spawn_target(direction, distance, dialogue_ref):
		return true
	print("QuestBase: Specific spawn failed, attempting fallback spawn...")
	return _spawn_fallback(dialogue_ref)

func _spawn_fallback(dialogue_ref: Object) -> bool:
	return false
