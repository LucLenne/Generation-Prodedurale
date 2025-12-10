class_name TalkQuest extends QuestBase

var _pnj1 : CharacterBase
var _pnj2 : CharacterBase

func _init() -> void :
	type = TYPE.TALK
	title = "Tu dois réconcilier " + _pnj1.Name + " et " + _pnj2.Name + "."

	

#func setup(world_gen: Node2D) -> void:
	#_pnj1 = ManagerQuest.GetPNJ(world_gen)
	#_pnj2 = ManagerQuest.GetPNJ(world_gen)
	#if _pnj1: _pnj1.emotion = CharacterBase.EMOTION.ANGRY
	#if _pnj2: _pnj2.emotion = CharacterBase.EMOTION.ANGRY

func _process(_delta: float):
	if(_pnj1.is_dead || _pnj2.is_dead):
		_fail_quest()

func _init_talk_quest():
	_pnj1 = ManagerQuest.GetNPC()
	_pnj2 = ManagerQuest.GetNPC()
