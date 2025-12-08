class_name TileConfig extends Node

# Global Settings
static var SOURCE_ID = 1
const TILE_SIZE = 8

# Basic tiles
const GRASS = Vector2i(5, 4)       # Herbe verte
const DIRT = Vector2i(1, 1)        # Terre
const WALL = Vector2i(1, 0)        # Mur générique
const DOOR = Vector2i(2, 2)        # Porte
const TREE = Vector2i(5, 5)        # Arbre
const PATH = Vector2i(4, 4)        # Chemin terre
const FLOOR = Vector2i(1, 1)       # Plancher bois
const BRIDGE = Vector2i(11, 5)      # Pont (par défaut même que le sol)
const SQUARE = Vector2i(4, 4)      # Pavé pierre pour la place
const WATER_BASE = Vector2i(12, 8) # Eau pleine (fallback)

# --- Configuration Eau ---
const RIVER_BITMASK_MAP = {
	# --- Centre ---
	0: Vector2i(12, 8),  # Centre

	# --- BORDURES SIMPLES ---
	1: Vector2i(12, 7),  # Terre HAUT
	2: Vector2i(13, 8),  # Terre DROITE
	4: Vector2i(12, 9),  # Terre BAS
	8: Vector2i(11, 8),  # Terre GAUCHE

	# --- ANGLES ---
	3: Vector2i(13, 7),  # Terre Haut + Droite
	6: Vector2i(13, 9),  # Terre Bas + Droite
	12: Vector2i(11, 9), # Terre Bas + Gauche
	9: Vector2i(11, 7),  # Terre Haut + Gauche

	# --- CANAUX ---
	5: Vector2i(12, 6),  # Terre Haut + Bas 
	10: Vector2i(13, 6), # Terre Gauche + Droite

	# --- PRESQU'ÎLES / CULS-DE-SAC (3 côtés terre) ---
	7: Vector2i(13, 8),  # Terre H+B+D -> On affiche Bordure DROITE
	11: Vector2i(11, 8), # Terre H+B+G -> On affiche Bordure GAUCHE
	13: Vector2i(12, 7), # Terre H+G+D -> On affiche Bordure HAUT
	14: Vector2i(12, 9), # Terre B+G+D -> On affiche Bordure BAS

	# --- LAC ISOLÉ (4 côtés terre) ---
	15: Vector2i(12, 8)  # Petit trou d'eau -> Centre
}

const RIVER_MASK_NAMES = {
	0: "center",
	1: "border_top",
	2: "border_right",
	4: "border_bottom",
	8: "border_left",
	3: "corner_top_right",
	6: "corner_bottom_right",
	12: "corner_bottom_left",
	9: "corner_top_left",
	5: "canal_vertical",
	10: "canal_horizontal",
	7: "dead_end_left_open", # Land on T, R, B
	11: "dead_end_right_open", # Land on T, B, L
	13: "dead_end_bottom_open", # Land on T, L, R
	14: "dead_end_top_open", # Land on B, L, R
	15: "isolated"
}

static func get_river_tile(border_mask: int) -> Vector2i:
	if RIVER_BITMASK_MAP.has(border_mask):
		return RIVER_BITMASK_MAP[border_mask]
	return WATER_BASE

# --- Configuration Murs ---
# Masque : Haut=1, Droite=2, Bas=4, Gauche=8
const WALL_BITMASK_MAP = {
	# --- Murs Droits ---
	1: Vector2i(1, 0),  # Mur du HAUT
	4: Vector2i(1, 2),  # Mur du BAS
	8: Vector2i(0, 1),  # Mur de GAUCHE
	2: Vector2i(3, 1),  # Mur de DROITE
	
	# --- Coins ---
	9: Vector2i(0, 0),  # Coin Haut-Gauche
	3: Vector2i(3, 0),  # Coin Haut-Droite
	12: Vector2i(0, 2), # Coin Bas-Gauche
	6: Vector2i(3, 2),  # Coin Bas-Droite
	
	# --- Cas Spéciaux ---
	# Pilier intérieur, masque = 0.
	0: Vector2i(2, 0)
}

static func get_wall_tile(neighbor_mask: int) -> Vector2i:
	if WALL_BITMASK_MAP.has(neighbor_mask):
		return WALL_BITMASK_MAP[neighbor_mask]
	return WALL

static func is_water(coords: Vector2i) -> bool:
	if coords == WATER_BASE: return true
	return RIVER_BITMASK_MAP.values().has(coords)
