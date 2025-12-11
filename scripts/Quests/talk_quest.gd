class_name TalkQuest extends QuestBase

var pnj : PNJ
var enemy : PNJ

func init() -> void :
	type = TYPE.TALK
	pnj = ManagerQuest.GetPNJ()
	if !pnj :
		push_warning("PNJ is null, Quest can't be created")
		ManagerQuest._delete_quest_UI(id)
		return
	pnj.create_dialogue()
	pnj.current_quest = self
	

	var quest_data = pnj.dialogue_system.current_quest_data
	var Direction = pnj.dialogue_system._string_to_direction_enum(quest_data["target_direction"])
	
	pnj.name = quest_data["owner_name"]
	enemy = ManagerQuest.SpawnPNJ(Direction, quest_data["target_name"], pnj)
	pnj.dialogue_system.targetInterractable = enemy.get_node("Interractable")
	
	var QuestGiverDialogueSystem: DialogueSystem = pnj.dialogue_system
	enemy.QuestGiverDialogueSystem = QuestGiverDialogueSystem
	
	title = "Tu dois réconcilier " + pnj.Name + " et " + enemy.Name + "."
	print(title)
#func setup(world_gen: Node2D) -> void:
	#pnj = ManagerQuest.GetPNJ(world_gen)
	#enemy = ManagerQuest.GetPNJ(world_gen)
	#if pnj: pnj.emotion = CharacterBase.EMOTION.ANGRY
	#if enemy: enemy.emotion = CharacterBase.EMOTION.ANGRY

func _process(_delta: float):
	if(pnj.is_dead || enemy.is_dead):
		_fail_quest()
