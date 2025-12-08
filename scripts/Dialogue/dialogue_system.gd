class_name DialogueSystem extends Node

@export var dialogue_ui : DialogueSystemUI
@export var npc_json_file : JSON
@export var monster_json_file : JSON

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
	match opponent_mood:
		Mood.INTIMIDATING: return player_choice == Mood.FRIENDLY
		Mood.FRIENDLY: return player_choice == Mood.PERSUASIVE
		Mood.PERSUASIVE: return player_choice == Mood.INTIMIDATING
	return false

func _on_dialogue_closed():
	if is_intro:
		is_intro = false
		
		
		await get_tree().create_timer(2.0).timeout
		
		is_fighting_monster = true
		
		var monster_data = get_monster_dialogue()
		if dialogue_ui:
			dialogue_ui.show_interaction_dialogue(monster_data)

func _on_player_answered(mood: Mood):
	var success = check_success(mood, is_fighting_monster)
	
	if success:
		print("Quest Won!")
	else:
		if is_fighting_monster:
			print("Failed! Returning to NPC...")
			is_fighting_monster = false
			
			# Wait a short delay
			await get_tree().create_timer(1.0).timeout
			
			var npc_data = get_second_chance_dialogue()
			if dialogue_ui:
				dialogue_ui.show_interaction_dialogue(npc_data)
		else:
			print("Game Over! Quest Failed.")
