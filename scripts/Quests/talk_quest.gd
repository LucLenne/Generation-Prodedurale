class_name TalkQuest extends QuestBase

var pnj : PNJ
var enemy : PNJ

func init() -> void :
	type = TYPE.TALK
	title = "Tu dois réconcilier " + pnj.Name + " et " + enemy.Name + "."
	pnj.create_dialogue()
	pnj = ManagerQuest.Getpnj()
	enemy = ManagerQuest.Getpnj()
	var quest_data = pnj._dialogue_system.current_quest_data
	enemy.QuestGiverDialogueSystem = pnj._dialogue_system
	ManagerQuest.Spawn_PNJ(quest_data["target_direction"])
	
#func setup(world_gen: Node2D) -> void:
	#pnj = ManagerQuest.GetPNJ(world_gen)
	#enemy = ManagerQuest.GetPNJ(world_gen)
	#if pnj: pnj.emotion = CharacterBase.EMOTION.ANGRY
	#if enemy: enemy.emotion = CharacterBase.EMOTION.ANGRY

func _process(_delta: float):
	if(pnj.is_dead || enemy.is_dead):
		_fail_quest()

	
	
