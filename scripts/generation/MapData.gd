class_name MapData extends RefCounted

var width: int
var height: int
var ground_layer: TileMapLayer
var wall_layer: TileMapLayer

var biome_grid: Array = [] # 2D Array [x][y] -> BiomeResource
var zones: Array = [] # Array of Zone objects
var reserved_cells: Dictionary = {} # Global reservation system
var zone_graph: Dictionary = {} # Adjacency list for connectivity

# Random number generator shared instance checking
var rng_seed: int
var noise: FastNoiseLite

func _init(w: int, h: int, g_layer: TileMapLayer, w_layer: TileMapLayer, seed_val: int):
	width = w
	height = h
	ground_layer = g_layer
	wall_layer = w_layer
	rng_seed = seed_val
	
	noise = FastNoiseLite.new()
	noise.seed = rng_seed
	noise.frequency = 0.02
	noise.fractal_octaves = 4

func get_biome_at(x: int, y: int) -> BiomeResource:
	if x < 0 or x >= width or y < 0 or y >= height:
		return null
	if biome_grid.is_empty():
		return null
	return biome_grid[x][y]

func is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height
