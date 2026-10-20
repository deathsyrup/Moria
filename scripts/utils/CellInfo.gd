extends Reference
class_name CellInfo

# What the mouse is pointing at: a short description of a cell for the hover tooltip.
# Monsters only when the cell is in view, the rest also when it was explored before.

static func describe(cell: Vector2, requireSeen: bool = true) -> String:
	var level = Ref.currentLevel
	if cell.x < 0 or cell.y < 0 or cell.x >= GLOBAL.FLOOR_SIZE_X or cell.y >= GLOBAL.FLOOR_SIZE_Y:
		return ""
	var visible = level.fog.get_cellv(cell) == 0
	var explored = level.shadows.get_cellv(cell) == 1
	if requireSeen and not visible and not explored:
		return ""
	var lines = []
	if (visible or not requireSeen) and GLOBAL.monstersByPosition.has(cell):
		var monster = GLOBAL.getMonsterByPos(cell)
		if monster != null and monster.status != "dead":
			var mood = "asleep" if monster.status == "sleep" else ("ally" if monster.status == "help" else "hostile")
			lines.append(monster.stats.entityName + "  HP " + str(monster.stats.currentHp) + "/" + str(monster.stats.hpMax) + "  (" + mood + ")")
	if (visible or not requireSeen) and Ref.character.pos == cell:
		lines.append("You")
	var loots = GLOBAL.getItemList(cell)
	for key in loots.keys():
		var ids = loots[key]
		var count = "" if ids.size() == 1 else " x" + str(ids.size())
		lines.append(str(GLOBAL.items[ids[0]][GLOBAL.IT_NAME]) + count)
	for chestId in GLOBAL.chests.keys():
		if GLOBAL.chests[chestId][GLOBAL.CH_POS] == cell:
			lines.append("Chest" + (" (locked)" if GLOBAL.chests[chestId][GLOBAL.CH_LOCKED] > 0 else ""))
	if GLOBAL.trapsByPos.has(cell):
		var trap = GLOBAL.getTrapByPos(cell)
		if trap != null and not trap.hidden:
			lines.append(trap.trapName)
	var tile = level.dungeon.get_cellv(cell)
	if tile == GLOBAL.DOOR_ID:
		lines.append("Locked door" if GLOBAL.lockedDoors.has(cell) else "Door")
	elif tile == GLOBAL.PASS_ID:
		lines.append("Stairs")
	return "\n".join(PoolStringArray(lines))
