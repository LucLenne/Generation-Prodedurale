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

@export_group("Decorations")
@export var decoration_tiles: Array[Vector2i] = []
@export var decoration_scenes: Array[PackedScene] = []
@export_range(0.0, 1.0) var decoration_density: float = 0.05
@export var decoration_scene_count_range: Vector2i = Vector2i(0, 2)
