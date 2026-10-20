extends Node

const bossNeighbors = {
	Vector2(-1, 0): [Vector2(-1, 0), Vector2(-1, 1)],
	Vector2(1, 0): [Vector2(2, 0), Vector2(2, 1)],
	Vector2(0, -1): [Vector2(0, -1), Vector2(1, -1)],
	Vector2(0, 1): [Vector2(0, 2), Vector2(1, 2)],
}

var exploreMap: Array = []

func dijkstraCompute():
	exploreMap.clear()
	for i in range(GLOBAL.FLOOR_SIZE_X+1):
		exploreMap.append([])
		for _j in range(GLOBAL.FLOOR_SIZE_Y+1):
			exploreMap[i].append(9999)
	for cell in Ref.currentLevel.shadows.get_used_cells_by_id(0):
		if cell.x < 0 or cell.y < 0:
			continue
		var value = Ref.currentLevel.dungeon.get_cellv(cell)
		if value != GLOBAL.FLOOR_ID and value != GLOBAL.DOOR_ID:
			continue
		exploreMap[cell.x][cell.y] = 0
	for itemCell in GLOBAL.itemsOnFloor.keys():
		if !GLOBAL.itemsOnFloor[itemCell][GLOBAL.FLOOR_EXP]:
			exploreMap[itemCell.x][itemCell.y] = 0
	var cells = Ref.currentLevel.dungeon.get_used_cells_by_id(GLOBAL.FLOOR_ID)
	cells.append_array(Ref.currentLevel.dungeon.get_used_cells_by_id(GLOBAL.DOOR_ID))
	for chest in GLOBAL.chests.values():
		cells.erase(chest[GLOBAL.CH_POS])
	for door in GLOBAL.testedDoors:
		cells.erase(door)
	var stop = false
	while !stop:
		stop = true
		for cell in cells:
			if (exploreMap[cell.x][cell.y] - exploreMap[cell.x-1][cell.y]) > 1:
				exploreMap[cell.x][cell.y] = exploreMap[cell.x-1][cell.y] + 1
				stop = false
			if (exploreMap[cell.x][cell.y] - exploreMap[cell.x+1][cell.y]) > 1:
				exploreMap[cell.x][cell.y] = exploreMap[cell.x+1][cell.y] + 1
				stop = false
			if (exploreMap[cell.x][cell.y] - exploreMap[cell.x][cell.y-1]) > 1:
				exploreMap[cell.x][cell.y] = exploreMap[cell.x][cell.y-1] + 1
				stop = false
			if (exploreMap[cell.x][cell.y] - exploreMap[cell.x][cell.y+1]) > 1:
				exploreMap[cell.x][cell.y] = exploreMap[cell.x][cell.y+1] + 1
				stop = false

func findNextStep(map: Array, pos: Vector2):
	var dist = map[pos.x][pos.y] 
	var result = null
	for d in Utils.directons:
		if map[pos.x+d.x][pos.y+d.y] < dist:
			dist = map[pos.x+d.x][pos.y+d.y]
			result = d
	return result

func checkRange(start: Vector2, end: Vector2):
	return abs(start.x - end.x) + abs(start.y - end.y)

func check_line_of_sight(start, end): 
	var result = []
	var e1 = 10000.0
	var current = start
	if (start.x != end.x):
		e1 = float(end.y - start.y) / float(end.x - start.x)
	var e = e1
	result.append(current)
	check_cell_vision(current)
	while (current != end):
		if (abs(e) < 0.999):
			check_cell_vision(current + Vector2(0,sign(end.y-start.y)))
			current = current + Vector2(sign(end.x-start.x),0)
			e += e1
		else:
			check_cell_vision(current + Vector2(sign(end.x-start.x),0))
			current = current + Vector2(0,sign(end.y-start.y))
			e -= sign(e)
		result.append(current)
		if(!check_cell_vision(current)):
			return [false, result]
	return [true, result]

func check_cell_vision(position):
	var cellState = Ref.currentLevel.isCellFree(position)
	if (!cellState[0]):
		return false
	return true

func dist(a, b):
	return sqrt(pow(b.x-a.x, 2) + pow(b.y-a.y, 2))

func path_to(cell):
	var result = [cell[0]]
	while not cell[2] == null:
		cell = cell[2]
		result.append(cell[0])
	result.invert()
	return result

func shorter_in(cell, list):
	for i in list:
		if (cell[0].x == i[0].x and cell[0].y == i[0].y):
			if (cell[1] >= i[1]):
				return true
	return false

func add_sorted(cell, list):
	var k = 0
	for i in list:
		if (cell[1] < i[1]):
			list.insert(k, cell)
			return
		k += 1
	list.insert(k, cell)

func get_neighbors(cell, ends, length, ignoreDoors: bool, isBoss: bool):
	var result = []
	var pos = cell[0]
	var cost = cell[1] + 1
	if !isBoss:
		for i in [Vector2(-1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(1, 0)]:
			for end in ends:
				if (pos + i) == end:
					result.append([pos + Vector2(i.x, i.y), cost, cell])
			var cellState = Ref.currentLevel.isCellFree(pos+i)
			if (pos + i) == Ref.character.pos:
				continue
			if !cellState[0] and (cellState[1] != "door" or !ignoreDoors) and cellState[1] != "pass":
				continue
			if (cost + dist(pos + Vector2(i.x, i.y), ends[0]) <= length):
				result.append([pos + Vector2(i.x, i.y), cost, cell])
	else:
		for n in bossNeighbors.keys():
			var toAdd = true
			var obj = []
			for i in bossNeighbors[n]:
				for end in ends:
					if (pos + i) == end:
						obj.append([pos + Vector2(i.x, i.y), cost, cell])
				var cellState = Ref.currentLevel.isCellFree(pos+i)
				if (pos + i) == Ref.character.pos:
					toAdd = false
				if !cellState[0] and (cellState[1] != "door" or !ignoreDoors) and cellState[1] != "pass":
					toAdd = false
			if toAdd and (cost + dist(pos + Vector2(n.x, n.y), ends[0]) <= length):
				result.append([pos + Vector2(n.x, n.y), cost, cell])
	return result

# Takes an array of ends so a boss can path to any of its contact cells
func a_star(start, ends, length, ignoreDoors: bool = false, isBoss: bool = false):
	for end in ends:
		if (end == null):
			return null
		if (dist(start, end) > length) or (dist(start, end) == 0):
			return null
	var closedList = []
	var openList = [[start, 0, null]]
	while (openList.size() > 0):
		var u = openList.pop_front()
		for end in ends:
			if (u[0].x == end.x and u[0].y == end.y):
				return path_to(u)
		for v in get_neighbors(u, ends, length, ignoreDoors, isBoss):
			if (shorter_in(v, openList) or shorter_in(v, closedList)):
				continue
			add_sorted(v, openList)
		closedList.append(u)
	return null

func get_neighbors_entites(cell, start, end, length):
	var result = []
	var pos = cell[0]
	var cost = cell[1] + 1
	if !start.isBoss:
		for i in [Vector2(-1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(1, 0)]:
			if (pos + i) == end.pos:
#				result.append([pos + Vector2(i.x, i.y), cost, cell])
				return [[pos + Vector2(i.x, i.y), cost, cell]]
			var cellState = Ref.currentLevel.isCellFree(pos+i, false)
			if !cellState[0]:
				if cellState[1] == "monster":
					if cellState[2] != start and cellState[2] != end:
						continue
				if cellState[1] != "door" and cellState[1] != "pass":
					continue
			if (cost + dist(pos + Vector2(i.x, i.y), end.pos) <= length):
				result.append([pos + Vector2(i.x, i.y), cost, cell])
	else:
		for n in bossNeighbors.keys():
			var toAdd = true
			for i in bossNeighbors[n]:
				if (pos + i) == end.pos:
#					result.append([pos + Vector2(n.x, n.y), cost, cell])
					return [[pos + Vector2(n.x, n.y), cost, cell]]
				var cellState = Ref.currentLevel.isCellFree(pos+i, false)
				if (pos + i) == Ref.character.pos:
					toAdd = false
				if !cellState[0]:
					if cellState[1] == "monster":
						if cellState[2] != start and cellState[2] != end:
							toAdd = false
					if cellState[1] != "door" and cellState[1] != "pass":
						toAdd = false
			if toAdd and (cost + dist(pos + Vector2(n.x, n.y), end.pos) <= length):
				result.append([pos + Vector2(n.x, n.y), cost, cell])
	return result

func a_star_entities(start, end, length: int):
	Ref.currentLevel.get_node("Debug").refresh()
	if (dist(start.pos, end.pos) > length) or (dist(start.pos, end.pos) == 0):
		return null
	var closedList = []
	var openList = [[start.pos, 0, null]]
	while (openList.size() > 0):
		var u = openList.pop_front()
		Ref.currentLevel.get_node("Debug").addLine(path_to(u))
		if start.isContact(end, u[0]):
			return path_to(u)
		for v in get_neighbors_entites(u, start, end, length):
			if (shorter_in(v, openList) or shorter_in(v, closedList)):
				continue
			add_sorted(v, openList)
		closedList.append(u)
	return null

# Bresenham's Line Algorithm
func get_line(start:Vector2, end:Vector2):
	# Setup initial conditions
	var x1: float = start.x
	var y1: float = start.y
	var x2: float = end.x
	var y2: float = end.y
	var dx: float = x2 - x1
	var dy: float = y2 - y1

	# Determine how steep the line is
	var is_steep = abs(dy) > abs(dx)
	var swap_var = 0.0
	
	# Rotate line
	if is_steep:
		swap_var = x1
		x1 = y1
		y1 = swap_var
		
		swap_var = x2
		x2 = y2
		y2 = swap_var

	# Swap start and end points if necessary and store swap state
	var swapped := false
	if x1 > x2:
		swap_var = x1
		x1 = x2
		x2 = swap_var
		swap_var = y1
		y1 = y2
		y2 = swap_var
		swapped = true

	# Recalculate differentials
	dx = x2 - x1
	dy = y2 - y1

	# Calculate error
	var error: float = floor(dx / 2.0)  # Try int
	var ystep = 1 if y1 < y2 else -1

	# Iterate over bounding box generating points between start and end
	var y = y1
	var points: Array = []
	for x in range(x1, x2 + 1):
		var coord = Vector2(y, x) if is_steep else Vector2(x, y)
		points.append(coord)
		error -= abs(dy)
		if error < 0:
			y += ystep
			error += dx

	# Reverse the list if the coordinates were swapped
	if swapped:
		points.invert()
	return points

# Add these to your Pathfinder script

func dijkstraComputeToItems():
	if GLOBAL.itemsOnFloor.empty():
		return null
	
	var itemMap: Array = []
	for i in range(GLOBAL.FLOOR_SIZE_X+1):
		itemMap.append([])
		for _j in range(GLOBAL.FLOOR_SIZE_Y+1):
			itemMap[i].append(9999)
	
	# Set all item positions as goals
	for itemCell in GLOBAL.itemsOnFloor.keys():
		itemMap[itemCell.x][itemCell.y] = 0
	
	# Get walkable cells
	var cells = Ref.currentLevel.dungeon.get_used_cells_by_id(GLOBAL.FLOOR_ID)
	cells.append_array(Ref.currentLevel.dungeon.get_used_cells_by_id(GLOBAL.DOOR_ID))
	
	# Remove obstacles
	for chest in GLOBAL.chests.values():
		cells.erase(chest[GLOBAL.CH_POS])
	for door in GLOBAL.testedDoors:
		cells.erase(door)
	
	# Run Dijkstra
	var stop = false
	while !stop:
		stop = true
		for cell in cells:
			if (itemMap[cell.x][cell.y] - itemMap[cell.x-1][cell.y]) > 1:
				itemMap[cell.x][cell.y] = itemMap[cell.x-1][cell.y] + 1
				stop = false
			if (itemMap[cell.x][cell.y] - itemMap[cell.x+1][cell.y]) > 1:
				itemMap[cell.x][cell.y] = itemMap[cell.x+1][cell.y] + 1
				stop = false
			if (itemMap[cell.x][cell.y] - itemMap[cell.x][cell.y-1]) > 1:
				itemMap[cell.x][cell.y] = itemMap[cell.x][cell.y-1] + 1
				stop = false
			if (itemMap[cell.x][cell.y] - itemMap[cell.x][cell.y+1]) > 1:
				itemMap[cell.x][cell.y] = itemMap[cell.x][cell.y+1] + 1
				stop = false
	
	return itemMap

func dijkstraComputeToMonsters(monster_positions: Array):
	if monster_positions.empty():
		return null
	
	var monsterMap: Array = []
	for i in range(GLOBAL.FLOOR_SIZE_X+1):
		monsterMap.append([])
		for _j in range(GLOBAL.FLOOR_SIZE_Y+1):
			monsterMap[i].append(9999)
	
	# Set all monster positions as goals
	for pos in monster_positions:
		if pos.x >= 0 and pos.x < GLOBAL.FLOOR_SIZE_X and pos.y >= 0 and pos.y < GLOBAL.FLOOR_SIZE_Y:
			monsterMap[pos.x][pos.y] = 0
	
	# Get walkable cells
	var cells = Ref.currentLevel.dungeon.get_used_cells_by_id(GLOBAL.FLOOR_ID)
	cells.append_array(Ref.currentLevel.dungeon.get_used_cells_by_id(GLOBAL.DOOR_ID))
	
	# Remove obstacles
	for chest in GLOBAL.chests.values():
		cells.erase(chest[GLOBAL.CH_POS])
	for door in GLOBAL.testedDoors:
		cells.erase(door)
	
	# Run Dijkstra
	var stop = false
	while !stop:
		stop = true
		for cell in cells:
			if cell.x <= 0 or cell.x >= GLOBAL.FLOOR_SIZE_X or cell.y <= 0 or cell.y >= GLOBAL.FLOOR_SIZE_Y:
				continue
				
			if (monsterMap[cell.x][cell.y] - monsterMap[cell.x-1][cell.y]) > 1:
				monsterMap[cell.x][cell.y] = monsterMap[cell.x-1][cell.y] + 1
				stop = false
			if (monsterMap[cell.x][cell.y] - monsterMap[cell.x+1][cell.y]) > 1:
				monsterMap[cell.x][cell.y] = monsterMap[cell.x+1][cell.y] + 1
				stop = false
			if (monsterMap[cell.x][cell.y] - monsterMap[cell.x][cell.y-1]) > 1:
				monsterMap[cell.x][cell.y] = monsterMap[cell.x][cell.y-1] + 1
				stop = false
			if (monsterMap[cell.x][cell.y] - monsterMap[cell.x][cell.y+1]) > 1:
				monsterMap[cell.x][cell.y] = monsterMap[cell.x][cell.y+1] + 1
				stop = false
	
	return monsterMap

func dijkstraComputeToChests():
	if GLOBAL.chests.empty():
		return null
	
	var chestMap: Array = []
	for i in range(GLOBAL.FLOOR_SIZE_X+1):
		chestMap.append([])
		for _j in range(GLOBAL.FLOOR_SIZE_Y+1):
			chestMap[i].append(9999)
	
	# Set ONLY unlocked chest positions as goals
	var hasTargets = false
	for chest_data in GLOBAL.chests.values():
		var chest_pos = chest_data[GLOBAL.CH_POS]
		var lock_level = chest_data[GLOBAL.CH_LOCKED]
		
		# Only target if completely unlocked
		if lock_level == 0:
			chestMap[chest_pos.x][chest_pos.y] = 0
			hasTargets = true
	
	# No valid chests to target
	if !hasTargets:
		return null
	
	# Get walkable cells
	var cells = Ref.currentLevel.dungeon.get_used_cells_by_id(GLOBAL.FLOOR_ID)
	cells.append_array(Ref.currentLevel.dungeon.get_used_cells_by_id(GLOBAL.DOOR_ID))
	
	# Remove obstacles
	for door in GLOBAL.testedDoors:
		cells.erase(door)
	
	# Run Dijkstra
	var stop = false
	while !stop:
		stop = true
		for cell in cells:
			if cell.x <= 0 or cell.x >= GLOBAL.FLOOR_SIZE_X or cell.y <= 0 or cell.y >= GLOBAL.FLOOR_SIZE_Y:
				continue
			
			if (chestMap[cell.x][cell.y] - chestMap[cell.x-1][cell.y]) > 1:
				chestMap[cell.x][cell.y] = chestMap[cell.x-1][cell.y] + 1
				stop = false
			if (chestMap[cell.x][cell.y] - chestMap[cell.x+1][cell.y]) > 1:
				chestMap[cell.x][cell.y] = chestMap[cell.x+1][cell.y] + 1
				stop = false
			if (chestMap[cell.x][cell.y] - chestMap[cell.x][cell.y-1]) > 1:
				chestMap[cell.x][cell.y] = chestMap[cell.x][cell.y-1] + 1
				stop = false
			if (chestMap[cell.x][cell.y] - chestMap[cell.x][cell.y+1]) > 1:
				chestMap[cell.x][cell.y] = chestMap[cell.x][cell.y+1] + 1
				stop = false
	
	return chestMap

func dijkstraComputeToExit(entryPos: Vector2):
	# Find only PASS_ID cells (exits), not MERCHANT_ID
	var exitCells = Ref.currentLevel.dungeon.get_used_cells_by_id(GLOBAL.PASS_ID)
	if exitCells.empty():
		return null
	
	# Find the entrance door (it should be adjacent to the spawn position)
	var entranceDoor = null
	for dir in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		var checkPos = entryPos + dir
		if exitCells.has(checkPos):
			entranceDoor = checkPos
			break
	
	# Remove the entrance door if found
	if entranceDoor != null:
		exitCells.erase(entranceDoor)
	
	if exitCells.empty():
		return null
	
	var exitMap: Array = []
	for i in range(GLOBAL.FLOOR_SIZE_X+1):
		exitMap.append([])
		for _j in range(GLOBAL.FLOOR_SIZE_Y+1):
			exitMap[i].append(9999)
	
	# Set exit positions as goals
	for exitCell in exitCells:
		exitMap[exitCell.x][exitCell.y] = 0
	
	# Get walkable cells
	var cells = Ref.currentLevel.dungeon.get_used_cells_by_id(GLOBAL.FLOOR_ID)
	cells.append_array(Ref.currentLevel.dungeon.get_used_cells_by_id(GLOBAL.DOOR_ID))
	cells.append_array(exitCells)
	
	# Remove obstacles
	for chest in GLOBAL.chests.values():
		cells.erase(chest[GLOBAL.CH_POS])
	for door in GLOBAL.testedDoors:
		cells.erase(door)
	
	# Run Dijkstra
	var stop = false
	while !stop:
		stop = true
		for cell in cells:
			if (exitMap[cell.x][cell.y] - exitMap[cell.x-1][cell.y]) > 1:
				exitMap[cell.x][cell.y] = exitMap[cell.x-1][cell.y] + 1
				stop = false
			if (exitMap[cell.x][cell.y] - exitMap[cell.x+1][cell.y]) > 1:
				exitMap[cell.x][cell.y] = exitMap[cell.x+1][cell.y] + 1
				stop = false
			if (exitMap[cell.x][cell.y] - exitMap[cell.x][cell.y-1]) > 1:
				exitMap[cell.x][cell.y] = exitMap[cell.x][cell.y-1] + 1
				stop = false
			if (exitMap[cell.x][cell.y] - exitMap[cell.x][cell.y+1]) > 1:
				exitMap[cell.x][cell.y] = exitMap[cell.x][cell.y+1] + 1
				stop = false
	
	return exitMap
