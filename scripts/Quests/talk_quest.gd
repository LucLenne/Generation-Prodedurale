class_name TalkQuest extends QuestBase

var _pnj1 : CharacterBase
var _pnj2 : CharacterBase

func _init() -> void :
	_type = TYPE.TALK
	_pnj1 = ManagerQuest.Instance.GetPNJ()
	_pnj2 = ManagerQuest.Instance.GetPNJ()
	_pnj1.emotion = CharacterBase.EMOTION.ANGRY
	_pnj2.emotion = CharacterBase.EMOTION.ANGRY

func _process(_delta: float) -> void:
	if(_pnj1.emotion != CharacterBase.EMOTION.ANGRY && _pnj2.emotion != CharacterBase.EMOTION.ANGRY):
		_valid_quest()
	if(_pnj1.is_dead || _pnj2.is_dead):
		_fail_quest()
