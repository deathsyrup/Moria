extends Reference
class_name SpecialRooms

# Rooms that make a floor worth exploring instead of just crossing it. They are carved into solid rock
# next to an existing corridor or room, so they never cut a way through the floor.
#
# Vault: a sealed 3 x 3 room behind a hidden or a locked door, a locked chest and better loot, and
#        sometimes a trap waiting outside a locked door.
# Lair:  a 4 x 4 room behind an ordinary door, a sleeping group of monsters guarding a chest and loot,
#        and a trap at the door.

const VAULT_SIZE = 3
const LAIR_SIZE = 4
const DIRECTIONS = [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]

# What was built on this floor: dictionaries with kind, door, outside and cells
static func built() -> Array:
	return GLOBAL.specialRooms

static func generate():
	GLOBAL.specialRooms = []
	if WorldHandler.currentBiome == Data.BIOME_TROLL_BOSS:
		return
	if randf() < 0.7:
		addVault()
	if randf() < min(0.6, 0.35 + 0.03 * WorldHandler.currentFloor):
		addLair()

static func tile(cell: Vector2) -> int:
	return Ref.currentLevel.dungeon.get_cellv(cell)

# A spot in solid rock for a room of this size, next to a floor cell: {interior, door, outside} or null
static func findSpot(size: int):
	var dungeon = Ref.currentLevel.dungeon
	var floors = dungeon.get_used_cells_by_id(GLOBAL.FLOOR_ID)
	floors.shuffle()
	for outside in floors:
		var directions = DIRECTIONS.duplicate()
		directions.shuffle()
		for d in directions:
			var door = outside + d
			if tile(door) != GLOBAL.WALL_ID:
				continue
			var interior = interiorRect(door, d, size)
			if rockAround(interior, outside, d):
				return {"interior": interior, "door": door, "outside": outside}
	return null

# The size x size cells that lie beyond the door, centered on the line through it
static func interiorRect(door: Vector2, d: Vector2, size: int) -> Rect2:
	var half = int(size / 2)
	if d.y != 0:
		var y = door.y + 1 if d.y > 0 else door.y - size
		return Rect2(Vector2(door.x - half, y), Vector2(size, size))
	var x = door.x + 1 if d.x > 0 else door.x - size
	return Rect2(Vector2(x, door.y - half), Vector2(size, size))

# The room and the wall around it (one cell thick, like the walls of any other room) must all be rock
static func rockAround(interior: Rect2, outside: Vector2, d: Vector2) -> bool:
	var margin = interior.grow(1)
	for x in range(int(margin.position.x), int(margin.end.x)):
		for y in range(int(margin.position.y), int(margin.end.y)):
			var cell = Vector2(x, y)
			if cell.x < 1 or cell.y < 1 or cell.x > GLOBAL.FLOOR_SIZE_X - 2 or cell.y > GLOBAL.FLOOR_SIZE_Y - 2:
				return false
			if (cell - outside).dot(d) == 0:
				continue
			if tile(cell) != GLOBAL.WALL_ID:
				return false
	return true

static func carve(spot: Dictionary, doorKind: String):
	var dungeon = Ref.currentLevel.dungeon
	var cells = []
	for x in range(int(spot["interior"].position.x), int(spot["interior"].end.x)):
		for y in range(int(spot["interior"].position.y), int(spot["interior"].end.y)):
			dungeon.set_cell(x, y, GLOBAL.FLOOR_ID)
			cells.append(Vector2(x, y))
	match doorKind:
		"hidden":
			GLOBAL.hiddenDoors.append(spot["door"])
		"locked":
			dungeon.set_cellv(spot["door"], GLOBAL.DOOR_ID)
			GLOBAL.lockedDoors.append(spot["door"])
		_:
			dungeon.set_cellv(spot["door"], GLOBAL.DOOR_ID)
	dungeon.update_bitmask_region()
	if doorKind != "hidden":
		dungeon.set_cellv(spot["door"], GLOBAL.DOOR_ID, false, false, false, Vector2(0, 1))
	return cells

static func lockLastChest(level: int):
	var chests = Ref.currentLevel.chests
	var chest = chests.get_child(chests.get_child_count() - 1)
	GLOBAL.chests[chest.get_instance_id()][GLOBAL.CH_LOCKED] = level

static func addVault():
	var spot = findSpot(VAULT_SIZE)
	if spot == null:
		return false
	var doorKind = "hidden" if randf() < 0.6 else "locked"
	var cells = carve(spot, doorKind)
	cells.shuffle()
	Ref.currentLevel.addChest(cells.pop_back(), 2)
	lockLastChest(3)
	for _i in range(3):
		Ref.currentLevel.addLoot(cells.pop_back(), true)
	if doorKind == "locked" and randf() < 0.5:
		Ref.currentLevel.placeTrap(spot["outside"])
	GLOBAL.specialRooms.append({"kind": "vault", "door": spot["door"], "outside": spot["outside"], "cells": cells, "doorKind": doorKind})
	return true

static func addLair():
	var spot = findSpot(LAIR_SIZE)
	if spot == null:
		return false
	var cells = carve(spot, "plain")
	cells.shuffle()
	# Monsters of two encounters, so it is a crowd and not a pair
	var monsters = 0
	var firstType = -1
	for _round in range(2):
		var encounter = Ref.game.dungeonGenerator.encounterHandler.chooseEncounter(Data.encounters[WorldHandler.currentBiome])
		for group in encounter[Data.ENC_MONSTERS]:
			if firstType < 0:
				firstType = group[Data.ENC_MO_TYPE]
			var count = group[Data.ENC_MO_MIN]
			if group[Data.ENC_MO_MAX] > group[Data.ENC_MO_MIN]:
				count += randi() % (group[Data.ENC_MO_MAX] - group[Data.ENC_MO_MIN] + 1)
			for _i in range(count):
				if monsters >= 5 or cells.size() < 4:
					break
				Ref.currentLevel.spawnMonster(group[Data.ENC_MO_TYPE], cells.pop_back())
				monsters += 1
	# A thin draw still makes a lair: at least three of the first kind
	while monsters < 3 and cells.size() > 3:
		Ref.currentLevel.spawnMonster(firstType, cells.pop_back())
		monsters += 1
	Ref.currentLevel.addChest(cells.pop_back(), 1)
	for _i in range(2):
		Ref.currentLevel.addLoot(cells.pop_back(), true)
	Ref.currentLevel.placeTrap(spot["outside"])
	GLOBAL.specialRooms.append({"kind": "lair", "door": spot["door"], "outside": spot["outside"], "cells": cells, "monsters": monsters})
	return true
