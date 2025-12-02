class_name TileConfig extends Node

# Global Settings
const TILE_SIZE = 8
const SOURCE_ID = 1

# --- Basic Tiles ---
const GRASS = Vector2i(5, 4)       # Herbe verte
const WALL = Vector2i(1, 0)        # Mur générique
const DOOR = Vector2i(2, 2)        # Porte
const TREE = Vector2i(5, 5)        # Arbre
const PATH = Vector2i(4, 4)        # Chemin terre
const FLOOR = Vector2i(1, 1)       # Plancher bois
const SQUARE = Vector2i(4, 4)      # Pavé pierre pour la place
const WATER_BASE = Vector2i(12, 8) # Eau pleine (fallback)

# --- Masque de Bordure (Où est la TERRE ?) ---
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

static func get_river_tile(border_mask: int) -> Vector2i:
	if RIVER_BITMASK_MAP.has(border_mask):
		return RIVER_BITMASK_MAP[border_mask]
	return WATER_BASE

# --- Configuration Murs (Bitmask des BORDURES EXTERIEURES) ---
# Masque : Haut=1, Droite=2, Bas=4, Gauche=8
# Ce masque indique où se trouve l'EXTERIEUR (le vide/herbe), pas les voisins murs.
const WALL_BITMASK_MAP = {
	# --- Murs Droits (1 côté extérieur) ---
	1: Vector2i(1, 0),  # Mur du HAUT (Exterieur en Haut) -> Horizontal
	4: Vector2i(1, 2),  # Mur du BAS (Exterieur en Bas) -> Horizontal
	8: Vector2i(0, 1),  # Mur de GAUCHE (Exterieur à Gauche) -> Vertical
	2: Vector2i(3, 1),  # Mur de DROITE (Exterieur à Droite) -> Vertical
	
	# --- Coins (2 côtés extérieurs) ---
	9: Vector2i(0, 0),  # Coin Haut-Gauche (Exterieur Haut+Gauche)
	3: Vector2i(3, 0),  # Coin Haut-Droite (Exterieur Haut+Droite)
	12: Vector2i(0, 2), # Coin Bas-Gauche (Exterieur Bas+Gauche)
	6: Vector2i(3, 2),  # Coin Bas-Droite (Exterieur Bas+Droite)
	
	# --- Cas Spéciaux (Optionnel) ---
	# Si un mur est entouré de sol (pilier intérieur), masque = 0.
	0: Vector2i(2, 0)
}

static func get_wall_tile(neighbor_mask: int) -> Vector2i:
	if WALL_BITMASK_MAP.has(neighbor_mask):
		return WALL_BITMASK_MAP[neighbor_mask]
	return WALL
