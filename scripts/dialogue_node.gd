extends Node2D

@export var PNJDialogueFile : JSON
@export var PlayerAnswerFile : JSON
var FirstQuote : String
var SecondQuote : String
#FirstQuote, #SecondQuote
#FriendlyAnswer, #IntimidatingAnswer, #PersuasiveAnswer
var FriendlyAnswer : String
var IntimidatingAnswer : String
var PersuasiveAnswer : String


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var PNJDialogueRule = PNJDialogueFile.data
	var PNJDialogueGrammar = TraceryFR.GrammarFR.new(PNJDialogueRule)
	PNJDialogueGrammar.add_modifiers(TraceryFR.UniversalModifiersFR.get_modifiers())
	
	FirstQuote = PNJDialogueGrammar.flatten("#origin#")
	SecondQuote = PNJDialogueGrammar.flatten("#replique2")
	
	var PlayerAnswerRule = PlayerAnswerFile.data
	var PlayerAnswerGrammar = TraceryFR.GrammarFR.new(PlayerAnswerRule)
	PlayerAnswerGrammar.add_modifiers(TraceryFR.UniversalModifiersFR.get_modifiers())
	
	FriendlyAnswer = PlayerAnswerGrammar.flatten("#origin")
	IntimidatingAnswer = PlayerAnswerGrammar.flatten("#reponseIntimidante")
	PersuasiveAnswer = PlayerAnswerGrammar.flatten("#reponsePersuasive")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	pass
