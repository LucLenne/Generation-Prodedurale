class_name DialogueSystem extends Node

@export_group("Dialogue Files")
@export var dialogue_ui : DialogueSystemUI
@export var npc_json_file : JSON
@export var monster_json_file : JSON

@export_group("Dialogue Difficulty")
@export var player_controller : PlayerController
@export var DC_EASY = 5
@export var DC_MEDIUM = 10 
@export var DC_HARD = 15 


enum Mood { INTIMIDATING, FRIENDLY, PERSUASIVE }
enum Directions { NORD, SUD, EST, OUEST }

var current_quest_data = {
	"target_type": "",
	"target_direction": "",
	"target_mood": Mood.INTIMIDATING,
	"giver_mood": Mood.FRIENDLY,
	"owner_name": ""
}

var is_fighting_monster: bool = false
var is_intro: bool = true

var is_reaction: bool = false

var grammar_npc : TraceryFR.GrammarFR
var grammar_monster : TraceryFR.GrammarFR

func _ready():
	if dialogue_ui:
		dialogue_ui.dialogue_closed.connect(_on_dialogue_closed)
		dialogue_ui.player_answered.connect(_on_player_answered)
	
	generate_new_quest()
	
	var intro = get_quest_intro_text()
	if dialogue_ui:
		dialogue_ui.show_intro_dialogue(intro)

func generate_new_quest():
	is_intro = true
	is_fighting_monster = false
	is_reaction = false
	
	grammar_npc = TraceryFR.GrammarFR.new(npc_json_file.data)
	grammar_npc.add_modifiers(TraceryFR.UniversalModifiersFR.get_modifiers())
	
	grammar_monster = TraceryFR.GrammarFR.new(monster_json_file.data)
	grammar_monster.add_modifiers(TraceryFR.UniversalModifiersFR.get_modifiers())
	
	current_quest_data.giver_mood = Mood.values()[randi() % Mood.size()]
	
	grammar_npc.flatten("#setup_variables#")
	
	
	current_quest_data.target_mood = _string_to_mood_enum(grammar_npc._save_data.get("mood_monstre", ["FRIENDLY"])[0])
	current_quest_data.target_type = grammar_npc._save_data.get("type_monstre", ["MonstreInconnu"])[0]
	current_quest_data.target_direction = grammar_npc._save_data.get("direction", ["Nulle part"])[0]
	
	current_quest_data.owner_name = grammar_npc._save_data.get("proprietaire", ["Inconnu"])

	grammar_monster._save_data["proprietaire"] = [current_quest_data.owner_name]

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
		"text": grammar_npc.flatten("#retour_echec_" + mood_key + "#"),
		"btn_intimidate": grammar_npc.flatten("#btn_intimidation#"),
		"btn_friendly": grammar_npc.flatten("#btn_amical#"),
		"btn_persuade": grammar_npc.flatten("#btn_persuasion#")
	}

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

func _on_dialogue_closed():
	if is_intro:
		is_intro = false
		await get_tree().create_timer(2.0).timeout
		
		is_fighting_monster = true
		var monster_data = get_monster_dialogue()
		if dialogue_ui:
			dialogue_ui.show_interaction_dialogue(monster_data)
			
			
	elif is_reaction:
		is_reaction = false
		pass 
		
		_handle_post_reaction()

var _last_success : bool = false

func _on_player_answered(mood: Mood):
	_last_success = check_success(mood, is_fighting_monster)
	
	var reaction_text = ""
	
	
	var active_grammar = grammar_monster if is_fighting_monster else grammar_npc
	
	if _last_success:
		reaction_text = active_grammar.flatten("#reaction_victoire#")
	else:
		reaction_text = active_grammar.flatten("#reaction_echec#")

	is_reaction = true
	if dialogue_ui:
		dialogue_ui.start_dialogue_sequence(reaction_text, false) # False = Just reading, then close


func _handle_post_reaction():
	if _last_success:
		print("Quest Won!")
		
	else:
		if is_fighting_monster:
			print("Failed! Returning to NPC...")
			is_fighting_monster = false 
			
			await get_tree().create_timer(1.0).timeout
			
			var npc_data = get_second_chance_dialogue()
			if dialogue_ui:
				dialogue_ui.show_interaction_dialogue(npc_data)
		else:
			print("Game Over! Quest Failed.")
