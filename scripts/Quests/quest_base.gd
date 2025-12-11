class_name QuestBase

enum TYPE {COLLECT, KILL, EXPLORE, DELIVERY, TALK, NONE}
enum STATE { INACTIVE ,ACTIVE,SUCCESS,FAIL}

var _state : STATE = STATE.ACTIVE
var type : TYPE = TYPE.NONE
var id : int
var title : String = "No title attribute to the quest"

func _valid_quest() -> void:
	ManagerQuest.SuccessQuest(self)
	_state = STATE.SUCCESS
	_give_reward()
func _fail_quest()-> void:
	ManagerQuest.FailQuest(self)
	_state = STATE.FAIL
func _give_reward()-> void:
	Player.Instance.life += Player.Instance.life_to_add
func init() -> void:
	pass
func _process(_delta: float):
	pass

func setup(_world_gen: Node2D) -> void:
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
