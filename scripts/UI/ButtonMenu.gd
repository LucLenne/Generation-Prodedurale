extends Button

@export var active_color: Color = Color("#7cc534")
@export var inactive_color: Color = Color("#6a6a6a")

func _ready() -> void:
	_update_styles()

func _update_styles() -> void:
	var corner_radius = 10
	var border_width_bottom = 6
	
	# Normal State
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = inactive_color
	style_normal.border_color = inactive_color.darkened(0.2)
	style_normal.border_width_bottom = border_width_bottom
	style_normal.border_width_left = 0
	style_normal.border_width_top = 0
	style_normal.border_width_right = 0
	style_normal.set_corner_radius_all(corner_radius)
	

	var style_active = StyleBoxFlat.new()
	style_active.bg_color = active_color
	style_active.border_color = active_color.darkened(0.2)
	style_active.border_width_bottom = border_width_bottom
	style_active.border_width_left = 0
	style_active.border_width_top = 0
	style_active.border_width_right = 0
	style_active.set_corner_radius_all(corner_radius)
	
	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_active)
	add_theme_stylebox_override("pressed", style_active)
	add_theme_stylebox_override("focus", style_active)
