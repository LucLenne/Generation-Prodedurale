extends Node2D


@onready var popup_position: Node2D = $PopupPosition
@onready var interractable: Interractable = $Interractable

const QUOTE_FOLDER_PATH = "res://Assets/Quotes/"


@export var QuoteJson : JSON
var QuoteText : String

var GrammarQuote : TraceryFR.GrammarFR

func _ready():
	interractable.showLabel = true
	load_random_json_files()
	
	var rulesFR = QuoteJson.data
	GrammarQuote = TraceryFR.GrammarFR.new(rulesFR)
	GrammarQuote.add_modifiers(TraceryFR.UniversalModifiersFR.get_modifiers())
	

func _on_interractable_on_player_interract() -> void:
	QuoteText = GrammarQuote.flatten("#origin#")
	var lines = QuoteText.split("&&")
	PopupManager.start_dialog(popup_position.global_position, lines)
	

func load_random_json_files():
	var epitaph_files = _get_json_files_in_folder(QUOTE_FOLDER_PATH)
	if epitaph_files.size() > 0:
		var random_epitaph_file = epitaph_files.pick_random()
		QuoteJson = load(random_epitaph_file)
		print("Fichier Epitah chargé : " + random_epitaph_file)
	else:
		push_error("Aucun fichier JSON trouvé dans : " + QUOTE_FOLDER_PATH)


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

	
	
