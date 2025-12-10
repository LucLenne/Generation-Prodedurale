## Stocke les données globales de la carte pendant la génération.
## Contient la grille de biomes, les zones, et les cellules réservées.
class_name MapData extends RefCounted

var width: int                          # Largeur de la carte en tuiles
var height: int                         # Hauteur de la carte en tuiles
var ground_layer: TileMapLayer          # Layer du sol
var wall_layer: TileMapLayer            # Layer des murs/obstacles

var biome_grid: Array = []              # Grille 2D [x][y] -> BiomeResource
var zones: Array = []                   # Liste des zones générées
var reserved_cells: Dictionary = {}     # Cellules occupées (maisons, eau, etc.)
var zone_graph: Dictionary = {}         # Graphe de connexion entre zones

var rng_seed: int                       # Seed pour la génération aléatoire
var noise: FastNoiseLite                # Bruit Perlin pour variation naturelle


func _init(w: int, h: int, g_layer: TileMapLayer, w_layer: TileMapLayer, seed_val: int):
	width = w
	height = h
	ground_layer = g_layer
	wall_layer = w_layer
	rng_seed = seed_val
	
	# Configuration du bruit Perlin
	noise = FastNoiseLite.new()
	noise.seed = rng_seed
	noise.frequency = 0.02
	noise.fractal_octaves = 4


## Retourne le biome à la position donnée, ou null si hors limites.
func get_biome_at(x: int, y: int) -> BiomeResource:
	if not is_in_bounds(x, y) or biome_grid.is_empty():
		return null
	return biome_grid[x][y]


## Vérifie si les coordonnées sont dans les limites de la carte.
func is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height
