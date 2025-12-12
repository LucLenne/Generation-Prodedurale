class_name DialogueSystem extends Node


@onready var pnj: PNJ = $".."
var targetInterractable : Interractable


@export_group("Dialogue Files")
var dialogue_ui : DialogueSystemUI
var npc_json_file : JSON
var monster_json_file : JSON

const NPC_FOLDER_PATH = "res://Assets/NPCJson/"
const MONSTER_FOLDER_PATH = "res://Assets/MonsterJSON/"

@export_group("Dialogue Difficulty")
var player_controller : PlayerController
@export var DC_EASY = 5
@export var DC_MEDIUM = 10 
@export var DC_HARD = 15 

enum QuestType {TALK, KILL, DELIVERY, EXPLORE, COLLECT}
@export var QuestTypeEnabeling : Dictionary[QuestType, bool]
enum Mood { INTIMIDATING, FRIENDLY, PERSUASIVE }
enum Directions { NORD, SUD, EST, OUEST }
@onready var interractable: Interractable  = $"../Interractable"


@export var InitializeOnReady : bool

@export var current_quest_data = {
	"quest_type" : QuestType.TALK,
	"target_type": "",
	"target_direction": "",
	"target_mood": Mood.INTIMIDATING,
	"giver_mood": Mood.FRIENDLY,
	"owner_name": "",
	"target_name" : ""
}

func is_current_quest_data_null() -> bool:
	var temp_quest_data = {
	"quest_type" : QuestType.TALK,
	"target_type": "",
	"target_direction": "",
	"target_mood": Mood.INTIMIDATING,
	"giver_mood": Mood.FRIENDLY,
	"owner_name": "",
	"target_name" : ""
	}
	return current_quest_data == temp_quest_data
	
func  is_current_quest_data_valid() -> bool:
	return !is_current_quest_data_null()


var has_quest = false
var is_intro: bool = true
var is_fighting_monster: bool = false
var is_second_chance : bool = false
var is_reaction: bool = false
var quest_ended = false

var grammar_npc : TraceryFR.GrammarFR
var grammar_monster : TraceryFR.GrammarFR

func _ready():
	if InitializeOnReady :
		generate_new_quest()

func generate_new_quest():
	player_controller = Player.Instance
	if !player_controller:
		push_error("Aucun Player présent dans la scène")
	
	if !dialogue_ui:
		dialogue_ui = DialogueSystemUI.instance
		
	load_random_json_files()
	if !npc_json_file :
		push_error("No Npc json file loaded")
	if !monster_json_file :
		push_error("No Monster json file loaded")
		
	if dialogue_ui:
		dialogue_ui.dialogue_closed.connect(_on_dialogue_closed)
		dialogue_ui.player_answered.connect(_on_player_answered)
	else:
		push_error("Aucun Dialogue System UI présent dans la scène")
		
	is_intro = true
	is_fighting_monster = false
	is_second_chance = false
	is_reaction = false
	
	grammar_npc = TraceryFR.GrammarFR.new(npc_json_file.data)
	grammar_npc.add_modifiers(TraceryFR.UniversalModifiersFR.get_modifiers())
	
	grammar_monster = TraceryFR.GrammarFR.new(monster_json_file.data)
	grammar_monster.add_modifiers(TraceryFR.UniversalModifiersFR.get_modifiers())
	
	current_quest_data.giver_mood = Mood.values()[randi() % Mood.size()]
	
	grammar_npc.flatten("#setup_variables#")
	grammar_monster.flatten("#setup_variables#")
	
	current_quest_data.target_mood = _string_to_mood_enum(grammar_npc._save_data.get("mood_monstre", ["FRIENDLY"]))

	current_quest_data.target_type = grammar_npc._save_data.get("type_monstre", ["MonstreInconnu"])

	current_quest_data.target_direction = grammar_npc._save_data.get("direction", ["Nulle part"])
	
	current_quest_data.owner_name = grammar_npc._save_data.get("proprietaire", ["Inconnu"])
	
	current_quest_data.target_name = grammar_npc._save_data.get("cible_nom", ["Karim"])

	grammar_monster._save_data["proprietaire"] = [current_quest_data.owner_name]
	grammar_monster._save_data["type_monstre"] = [current_quest_data.target_type]
	grammar_monster._save_data["cible_nom"] = [current_quest_data.target_name]
	
	has_quest = true
	interractable.showLabel = true
	
	

func get_quest_intro_text() -> String:
	var mood_key = _get_mood_key(current_quest_data.target_mood)
	return grammar_npc.flatten("#intro_quete_" + mood_key + "#")

func get_monster_dialogue() -> Dictionary:
	var mood_key = _get_mood_key(current_quest_data.target_mood)
	return {
		"text": grammar_monster.flatten("#replique_" + mood_key + "#"),
		"btn_intimidate": grammar_monster.flatten("#btn_intimidation#"),
		"btn_friendly": grammar_monster.flatten("#btn_amical#"),
		"btn_persuade": grammar_monster.flatten("#btn_persuasion#")
	}

func get_second_chance_dialogue() -> Dictionary:
	var mood_key = _get_mood_key(current_quest_data.giver_mood)
	return {
		"text": grammar_npc.flatten("#seconde_chance_" + mood_key + "#"),
		"btn_intimidate": grammar_npc.flatten("#btn_intimidation#"),
		"btn_friendly": grammar_npc.flatten("#btn_amical#"),
		"btn_persuade": grammar_npc.flatten("#btn_persuasion#")
	}
func get_retour_dialogue(mood : Mood, is_succes : bool) -> String:
	#var mood_key = _get_mood_key(current_quest_data.giver_mood) # si on veut que la reaction soit celon le mood de l'interlocuteur
	var mood_key = _get_mood_key(mood) #si on veut que la reaction se fasse en fonction de la réponse du joueur.
	var echec_or_victory_str = "echec" if not is_succes else "victoire"
	var active_grammar : TraceryFR.GrammarFR = grammar_monster if is_fighting_monster else grammar_npc
	print("#retour_" + echec_or_victory_str + "_" + mood_key + "#")
	return active_grammar.flatten("#retour_" + echec_or_victory_str + "_" + mood_key + "#")

func StartIntroDialogue():
	var intro = get_quest_intro_text()
	if dialogue_ui:
		dialogue_ui._initNewDialog(pnj)
		dialogue_ui.show_non_interractive_dialogue(intro)
		
func StartMonsterDialogue():
	is_fighting_monster = true
	var monster_data = get_monster_dialogue()
	if dialogue_ui:
		dialogue_ui.show_interaction_dialogue(monster_data)
		
func StartSecondChanceDialogue():
	is_second_chance = true
	var second_chance = get_second_chance_dialogue()
	if dialogue_ui :
		dialogue_ui.show_interaction_dialogue(second_chance)
		

func StartReactionDialogue(mood : Mood, is_success : bool):
	is_reaction = true
	var retourDialogue = get_retour_dialogue(mood, is_success)
	if dialogue_ui:
		dialogue_ui.show_non_interractive_dialogue(retourDialogue)
			
	
func check_success(player_choice : Mood, target_is_monster : bool) -> bool:
	var opponent_mood = current_quest_data.target_mood if target_is_monster else current_quest_data.giver_mood
	
	var difficulty = DC_MEDIUM # Par défaut (Neutre)
	
	match opponent_mood:
		Mood.INTIMIDATING:
			if player_choice == Mood.FRIENDLY: difficulty = DC_EASY      
			elif player_choice == Mood.PERSUASIVE: difficulty = DC_HARD   
			
		Mood.FRIENDLY:
			if player_choice == Mood.PERSUASIVE: difficulty = DC_EASY     
			elif player_choice == Mood.INTIMIDATING: difficulty = DC_HARD 
			
		Mood.PERSUASIVE:
			if player_choice == Mood.INTIMIDATING: difficulty = DC_EASY   
			elif player_choice == Mood.FRIENDLY: difficulty = DC_HARD   
	
	var player_stat_value = 0.0
	match player_choice:
		Mood.INTIMIDATING: 
			player_stat_value = player_controller._intimidating
		Mood.FRIENDLY: 
			player_stat_value = player_controller._friendly
		Mood.PERSUASIVE: 
			player_stat_value = player_controller._persuasive
	

	var d20_roll = randi_range(1, 20)
	var stat_modifier = player_stat_value - 10
	var final_score = d20_roll + stat_modifier
	
	# 5. Donner l'XP (Même en cas d'échec, on apprend !)
	player_controller.gain_xp(player_choice)
	
	print("--- TEST DE COMPÉTENCE ---")
	print("Adversaire: %s | Joueur: %s" % [Mood.keys()[opponent_mood], Mood.keys()[player_choice]])
	print("Difficulté (DC): %d" % difficulty)
	print("Stat Joueur: %.1f (Mod: %.1f)" % [player_stat_value, stat_modifier])
	print("Jet de dé: %d" % d20_roll)
	print("SCORE FINAL: %d (Objectif: > %d)" % [final_score, difficulty])
	

	return final_score >= difficulty

func _on_dialogue_closed(questGiver : PNJ):
	if questGiver != pnj :
		return
	if is_reaction:
		is_reaction = false
		if is_fighting_monster:
			is_fighting_monster = false
			targetInterractable.showLabel = false
			if _last_success:
				if pnj and pnj.current_quest:
					pnj.current_quest._valid_quest()
					quest_ended = true
			else:
				is_second_chance = true
				interractable.showLabel = true
			
				
		elif is_second_chance:
			if _last_success:
				if pnj and pnj.current_quest:
					pnj.current_quest._valid_quest()
					quest_ended = true
				is_second_chance = false
			else:
				if pnj and pnj.current_quest:
					pnj.current_quest._fail_quest()
					quest_ended = true
				is_second_chance = false 
			interractable.showLabel = false
				
	elif is_intro:
		is_intro = false
		interractable.showLabel = false
		targetInterractable.showLabel = true
		ManagerQuest.ActiveQuest(pnj.current_quest)


var _last_success : bool = false

func _on_player_answered(mood: Mood, questGiver : PNJ):
	if questGiver != pnj :
		return
	print("_on_player_answered")
	_last_success = check_success(mood, is_fighting_monster)
	StartReactionDialogue(mood, _last_success)


func _on_interractable_on_player_interract() -> void:
	if !pnj:
		print("MonsterDialogue")
		push_error("No PNJ assigned to DialogueSystem")
		return
	if !pnj.QuestGiverDialogueSystem : # c'est le donneur de quête
		if not has_quest :
			return
		if is_intro and not quest_ended :
			print("intro")
			StartIntroDialogue()
		elif is_second_chance :
			print("seconde chance")
			StartSecondChanceDialogue()
	else: # c'est le monstre.
		if ( not pnj.QuestGiverDialogueSystem.quest_ended 
		and not pnj.QuestGiverDialogueSystem.is_intro
		and not pnj.QuestGiverDialogueSystem.is_second_chance): 
			print("MonsterDialogue")
			pnj.QuestGiverDialogueSystem.StartMonsterDialogue()

func _string_to_direction_enum(direction_string : String) -> Directions:
	match direction_string.to_upper():
		"NORD": return Directions.NORD
		"SUD": return Directions.SUD
		"EST": return Directions.EST
		"OUEST": return Directions.OUEST
	
	push_warning("Direction inconnu reçu de Tracery : " + direction_string + ". Fallback sur OUEST.")
	return Directions.OUEST
		
func _string_to_mood_enum(mood_string : String) -> Mood:
	match mood_string.to_upper():
		"INTIMIDATING": return Mood.INTIMIDATING
		"FRIENDLY": return Mood.FRIENDLY
		"PERSUASIVE": return Mood.PERSUASIVE
	
	push_warning("Mood inconnu reçu de Tracery : " + mood_string + ". Fallback sur FRIENDLY.")
	return Mood.FRIENDLY
	
	
func _get_mood_key(mood : Mood) -> String:
	match mood:
		Mood.INTIMIDATING: return "intimidant"
		Mood.FRIENDLY: return "amical"
		Mood.PERSUASIVE: return "persuasif"
	return "amical"


func _string_to_questType_enum(questType_string : String) -> QuestType :
	match questType_string.to_upper():
		"TALK": 
			return QuestType.TALK
		"KILL": 
			return QuestType.KILL
		"EXPLORE": 
			return QuestType.EXPLORE
		"DELIVERY" :
			return QuestType.DELIVERY
		"COLLECT" :
			return QuestType.COLLECT
	push_warning("Mood inconnu reçu de Tracery : " + questType_string + ". Fallback sur TALK.")
	return QuestType.TALK
	
func _get_questType_key(questType : QuestType) -> String:
	match questType:
		QuestType.TALK: return "TALK"
		QuestType.KILL: return "KILL"
		QuestType.DELIVERY: return "DELIVERY"
		QuestType.EXPLORE: return "EXPLORE"
		QuestType.COLLECT : return "COLLECT"
	return "TALK"
		
func get_random_npcJsonFolder() -> String:
	var enabled_types: Array[QuestType] = []
	
	for type in QuestType.values():
		if QuestTypeEnabeling.get(type, false):
			enabled_types.append(type)

	if enabled_types.is_empty():
		push_error("Aucun QuestType n'est activé dans le dictionnaire !")
		return ""
	
	var random_quest_type = enabled_types.pick_random()
	
	return _get_questType_key(random_quest_type)

func load_random_json_files():
	var randomNpcJsonFolder = get_random_npcJsonFolder()
	if randomNpcJsonFolder.is_empty() :
		return
	current_quest_data.target_type = randomNpcJsonFolder
	var npc_folder_path = NPC_FOLDER_PATH
	npc_folder_path += randomNpcJsonFolder + "/"
	var npc_files = _get_json_files_in_folder(npc_folder_path)
	if npc_files.size() > 0:
		var random_npc_path = npc_files.pick_random()
		npc_json_file = load(random_npc_path)
		print("Fichier PNJ chargé : " + random_npc_path)
	else:
		push_error("Aucun fichier JSON trouvé dans : " + npc_folder_path)

	var monster_files = _get_json_files_in_folder(MONSTER_FOLDER_PATH)
	if monster_files.size() > 0:
		var random_monster_path = monster_files.pick_random()
		monster_json_file = load(random_monster_path)
		print("Fichier Monstre chargé : " + random_monster_path)
	else:
		push_error("Aucun fichier JSON trouvé dans : " + MONSTER_FOLDER_PATH)


func _get_json_files_in_folder(path: String) -> Array[String]:
	var files: Array[String] = []
	var dir = DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				files.append(path + "/" + file_name)
			
			file_name = dir.get_next()
	else:
		push_error("Impossible d'ouvrir le dossier : " + path)
	
	return files
