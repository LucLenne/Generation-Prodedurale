class_name BiomeResource extends Resource

enum ZoneShape {
	RECTANGULAR,   # Forme rectangulaire nette
	CIRCULAR,      # Forme circulaire/elliptique
	ORGANIC        # Forme organique avec bruit
}

@export var biome_name: String = "Forest"

@export_group("Zone Generation")
@export var zone_shape: ZoneShape = ZoneShape.ORGANIC
@export_range(0.0, 1.0) var border_tree_density: float = 0.0


@export_group("Tiles")
@export var ground_tile: Vector2i = Vector2i(5, 4) # Default Grass
@export var dirt_tile: Vector2i = Vector2i(1, 1)   # Default Dirt
@export var wall_tile: Vector2i = Vector2i(5, 5)   # Default Tree
@export var path_tile: Vector2i = Vector2i(4, 4)   # Default Path
@export var river_tiles: Dictionary = {
	"center": Vector2i(12, 8),
	"border_top": Vector2i(12, 7),
	"border_right": Vector2i(13, 8),
	"border_bottom": Vector2i(12, 9),
	"border_left": Vector2i(11, 8),
	"corner_top_right": Vector2i(13, 7),
	"corner_bottom_right": Vector2i(13, 9),
	"corner_bottom_left": Vector2i(11, 9),
	"corner_top_left": Vector2i(11, 7),
	"canal_vertical": Vector2i(12, 6),
	"canal_horizontal": Vector2i(13, 6),
	"dead_end_left_open": Vector2i(13, 8),
	"dead_end_right_open": Vector2i(11, 8),
	"dead_end_bottom_open": Vector2i(12, 7),
	"dead_end_top_open": Vector2i(12, 9),
	"isolated": Vector2i(12, 8)
}

@export_group("Decorations")
# @export var decoration_tiles: Array[Vector2i] = [] # Deprecated
@export var decorations: Array[DecorationItem] = []
@export var decoration_scenes: Array[PackedScene] = []
@export var house_scenes: Array[PackedScene] = [] # Buildings specific to this biome
# @export_range(0.0, 1.0) var decoration_density: float = 0.05 # Deprecated
@export var decoration_scene_count_range: Vector2i = Vector2i(0, 2)
