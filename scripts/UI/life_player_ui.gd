class_name DisplayLifePlayer extends CanvasLayer


@onready var ref_text = $number_life

func _process(_delta: float) -> void:
	if ref_text:
		if ref_text is Label:
			ref_text.text = str(Player.Instance.life)
