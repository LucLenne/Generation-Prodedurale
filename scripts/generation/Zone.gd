class_name Zone extends RefCounted

var id: int
var center: Vector2i
var cells: Array[Vector2i] = []
var entrances: Array[Vector2i] = []
var buildings: Array = []
var shape_bounds: Rect2i

func _init(_id: int, _center: Vector2i):
	id = _id
	center = _center

func add_cell(cell: Vector2i):
	cells.append(cell)
	_update_bounds(cell)

func _update_bounds(cell: Vector2i):
	if cells.size() == 1:
		shape_bounds = Rect2i(cell, Vector2i(1, 1))
	else:
		var min_x = min(shape_bounds.position.x, cell.x)
		var min_y = min(shape_bounds.position.y, cell.y)
		var max_x = max(shape_bounds.end.x, cell.x + 1)
		var max_y = max(shape_bounds.end.y, cell.y + 1)
		shape_bounds = Rect2i(min_x, min_y, max_x - min_x, max_y - min_y)

func get_random_entrance() -> Vector2i:
	if entrances.is_empty():
		return center
	return entrances.pick_random()

func get_boundary_cells() -> Array[Vector2i]:
	var boundary: Array[Vector2i] = []
	var cell_set = {}
	for cell in cells:
		cell_set[cell] = true
	
	for cell in cells:
		# Check if any neighbor is not in the zone
		var neighbors = [
			cell + Vector2i(0, -1),
			cell + Vector2i(1, 0),
			cell + Vector2i(0, 1),
			cell + Vector2i(-1, 0)
		]
		for neighbor in neighbors:
			if not cell_set.has(neighbor):
				boundary.append(cell)
				break
	
	return boundary

func is_point_inside(point: Vector2i) -> bool:
	return cells.has(point)

func get_size() -> int:
	return cells.size()
