extends Control

# Draws the explored part of the floor, one square per cell. Used by MapOverview.

const CELL = 18

const WALL = Color(0.32, 0.32, 0.36)
const FLOOR = Color(0.11, 0.11, 0.14)
const DOOR = Color(0.65, 0.42, 0.2)
const STAIRS = Color(1.0, 0.85, 0.3)
const LOOT = Color(0.95, 0.9, 0.4)
const CHEST = Color(1.0, 0.6, 0.2)
const ENEMY = Color(1.0, 0.3, 0.3)
const TRAP = Color(0.9, 0.3, 0.9)
const PLAYER = Color(0.4, 1.0, 1.0)

func _ready():
	rect_min_size = Vector2(GLOBAL.FLOOR_SIZE_X, GLOBAL.FLOOR_SIZE_Y) * CELL

func exploredCells() -> Array:
	var cells = []
	for x in range(GLOBAL.FLOOR_SIZE_X):
		for y in range(GLOBAL.FLOOR_SIZE_Y):
			if Ref.currentLevel.shadows.get_cellv(Vector2(x, y)) == 1:
				cells.append(Vector2(x, y))
	return cells

func mark(cell: Vector2, color: Color, inset: int = 4):
	draw_rect(Rect2(cell * CELL + Vector2(inset, inset), Vector2(CELL - 2 * inset, CELL - 2 * inset)), color)

func _draw():
	draw_rect(Rect2(Vector2.ZERO, rect_min_size), Color(0, 0, 0))
	var explored = exploredCells()
	var dungeon = Ref.currentLevel.dungeon
	for cell in explored:
		var tile = dungeon.get_cellv(cell)
		var color = FLOOR
		if tile == GLOBAL.WALL_ID or tile == -1:
			color = WALL
		elif tile == GLOBAL.DOOR_ID:
			color = DOOR
		elif tile == GLOBAL.PASS_ID:
			color = STAIRS
		draw_rect(Rect2(cell * CELL, Vector2(CELL, CELL)), color)
	for cell in GLOBAL.itemsOnFloor.keys():
		if explored.has(cell):
			mark(cell, LOOT, 6)
	for chestId in GLOBAL.chests.keys():
		var cell = GLOBAL.chests[chestId][GLOBAL.CH_POS]
		if explored.has(cell):
			mark(cell, CHEST, 3)
	for cell in GLOBAL.trapsByPos.keys():
		var trap = GLOBAL.getTrapByPos(cell)
		if trap != null and not trap.hidden and explored.has(cell):
			mark(cell, TRAP, 5)
	for id in GLOBAL.targets.keys():
		var entity = instance_from_id(id)
		if entity != null:
			mark(entity.pos, ENEMY, 3)
	mark(Ref.character.pos, PLAYER, 2)
