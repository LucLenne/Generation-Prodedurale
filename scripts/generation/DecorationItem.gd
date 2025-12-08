class_name DecorationItem extends Resource

@export var atlas_coords: Vector2i = Vector2i(0, 0)
@export_range(0.0, 1.0) var density: float = 0.05 ## Probability of this specific decoration appearing (0.0 to 1.0)
