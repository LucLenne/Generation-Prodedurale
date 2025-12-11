class_name TalkQuest extends QuestBase

var pnj : PNJ
var enemy : PNJ

func init() -> void :
	type = TYPE.TALK
	pnj.create_dialogue()
	pnj = ManagerQuest.GetPNJ()
	enemy = ManagerQuest.GetPNJ()
	enemy.QuestGiverDialogueSystem = pnj.QuestGiverDialogueSystem
	var quest_data = pnj._dialogue_system.current_quest_data
	ManagerQuest.Spawn_PNJ(quest_data["target_direction"],quest_data["owner_name"])
	title = "Tu dois réconcilier " + pnj.Name + " et " + enemy.Name + "."
#func setup(world_gen: Node2D) -> void:
	#pnj = ManagerQuest.GetPNJ(world_gen)
	#enemy = ManagerQuest.GetPNJ(world_gen)
	#if pnj: pnj.emotion = CharacterBase.EMOTION.ANGRY
	#if enemy: enemy.emotion = CharacterBase.EMOTION.ANGRY

func _process(_delta: float):
	if(pnj.is_dead || enemy.is_dead):
		_fail_quest()
