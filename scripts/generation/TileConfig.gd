## Configuration des tuiles pour la génération de carte.
class_name TileConfig extends Node

# --- Paramètres globaux ---
static var SOURCE_ID = 1
const TILE_SIZE = 8

# --- Tuiles de base ---
const GRASS = Vector2i(5, 4)        # Herbe
const DIRT = Vector2i(1, 1)         # Terre
const WALL = Vector2i(1, 0)         # Mur
const DOOR = Vector2i(2, 2)         # Porte principale
const TREE = Vector2i(5, 5)         # Arbre
const PATH = Vector2i(4, 4)         # Chemin
const FLOOR = Vector2i(1, 1)        # Sol intérieur
const BRIDGE = Vector2i(11, 5)      # Pont
const SQUARE = Vector2i(4, 4)       # Place pavée
const WATER_BASE = Vector2i(12, 8)  # Eau (centre)

# --- Variantes de portes ---
const DOOR_VARIANTS = [
	Vector2i(2, 2),
	Vector2i(2, 10),
	Vector2i(2, 11),
	Vector2i(6, 10),
	Vector2i(6, 11),
	Vector2i(8, 9),
	Vector2i(10, 10),
	Vector2i(10, 11),
]

# --- Variantes de sol (Pour la validation) ---
const GRASS_VARIANTS = [
	GRASS,
	Vector2i(23, 4),
	Vector2i(13, 10),
	Vector2i(15, 10)
] # Ajoutez ici d'autres variantes d'herbe si nécessaire
const DIRT_VARIANTS = [DIRT]   # Ajoutez ici d'autres variantes de terre si nécessaire

# --- Variantes à exclure explicitement (Safety Check) ---
const TREE_VARIANTS = [
	TREE,
	Vector2i(14, 11),
	Vector2i(15, 11),
	Vector2i(12, 11),
	Vector2i(13, 11),
	Vector2i(23, 5),
	Vector2i(22, 5),
	]
const PATH_VARIANTS = [
	PATH,
	Vector2i(12, 10),
	Vector2i(14, 10),
	Vector2i(22, 4),
	]
const WATER_VARIANTS = [WATER_BASE]


## Vérifie si les coordonnées correspondent à une porte.
static func is_door(coords: Vector2i) -> bool:
	return DOOR_VARIANTS.has(coords)

# --- Autotiling eau ---
# Masque: Haut=1, Droite=2, Bas=4, Gauche=8
const RIVER_BITMASK_MAP = {
	0: Vector2i(12, 8),   # Centre
	1: Vector2i(12, 7),   # Bord haut
	2: Vector2i(13, 8),   # Bord droite
	4: Vector2i(12, 9),   # Bord bas
	8: Vector2i(11, 8),   # Bord gauche
	3: Vector2i(13, 7),   # Coin haut-droite
	6: Vector2i(13, 9),   # Coin bas-droite
	12: Vector2i(11, 9),  # Coin bas-gauche
	9: Vector2i(11, 7),   # Coin haut-gauche
	5: Vector2i(12, 6),   # Canal vertical
	10: Vector2i(13, 6),  # Canal horizontal
	7: Vector2i(13, 8),   # Cul-de-sac (terre H+B+D)
	11: Vector2i(11, 8),  # Cul-de-sac (terre H+B+G)
	13: Vector2i(12, 7),  # Cul-de-sac (terre H+G+D)
	14: Vector2i(12, 9),  # Cul-de-sac (terre B+G+D)
	15: Vector2i(12, 8)   # Isolé
}

const RIVER_MASK_NAMES = {
	0: "center", 1: "border_top", 2: "border_right", 4: "border_bottom",
	8: "border_left", 3: "corner_top_right", 6: "corner_bottom_right",
	12: "corner_bottom_left", 9: "corner_top_left", 5: "canal_vertical",
	10: "canal_horizontal", 7: "dead_end_left_open", 11: "dead_end_right_open",
	13: "dead_end_bottom_open", 14: "dead_end_top_open", 15: "isolated"
}


## Retourne la tuile d'eau correspondant au masque de bordure.
static func get_river_tile(border_mask: int) -> Vector2i:
	if RIVER_BITMASK_MAP.has(border_mask):
		return RIVER_BITMASK_MAP[border_mask]
	return WATER_BASE


# --- Autotiling murs ---
const WALL_BITMASK_MAP = {
	1: Vector2i(1, 0),   # Mur haut
	4: Vector2i(1, 2),   # Mur bas
	8: Vector2i(0, 1),   # Mur gauche
	2: Vector2i(3, 1),   # Mur droite
	9: Vector2i(0, 0),   # Coin haut-gauche
	3: Vector2i(3, 0),   # Coin haut-droite
	12: Vector2i(0, 2),  # Coin bas-gauche
	6: Vector2i(3, 2),   # Coin bas-droite
	0: Vector2i(2, 0)    # Pilier isolé
}


## Retourne la tuile de mur correspondant au masque de voisinage.
static func get_wall_tile(neighbor_mask: int) -> Vector2i:
	if WALL_BITMASK_MAP.has(neighbor_mask):
		return WALL_BITMASK_MAP[neighbor_mask]
	return WALL


## Vérifie si les coordonnées correspondent à une tuile d'eau.
static func is_water(coords: Vector2i) -> bool:
	if coords == WATER_BASE:
		return true
	return RIVER_BITMASK_MAP.values().has(coords)
