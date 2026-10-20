extends Node

onready var monsterScene = preload("res://scenes/Monster.tscn")
onready var lootScene = preload("res://scenes/Loot.tscn")
onready var chestScene = preload("res://scenes/Chest.tscn")
onready var trapScene = preload("res://scenes/Trap.tscn")
onready var npcScene = preload("res://scenes/Npc.tscn")

# Was "res://usr/": the res:// folder is read-only in an exported game, so saving only worked
# when running from the editor. Saves now go to the user data folder.
var filePath = "user://saves/"
var oldFilePath = "res://usr/"

func createFolder():
	var directory = Directory.new()
	if not directory.dir_exists(filePath):
		directory.make_dir_recursive(filePath)

func saveGame():
	if not Settings.canWrite():
		return
	createFolder()
	var file = File.new()
	file.open(filePath + Ref.character.stats.charName + ".sav", File.WRITE)
	#todo if file already exists copy it before erasing content
	file.store_var(saveItemGenerator(), true)
	file.store_var(saveStatusEngine(), true)
	file.store_var(saveItems(), true)
	file.store_var(saveStatuses(), true)
	file.store_var(saveGlobals(), true)
	file.store_var(saveMap(), true)
	file.store_var(saveMonsters(), true)
	file.store_var(saveAllies(), true)
	file.store_var(saveNpcs(), true)
	file.store_var(saveCharacter(), true)
	file.store_var(saveLevelBuffer(), true)
	file.store_var(saveTraps(), true)
	file.store_var(saveEngine(), true)
	file.store_var(saveUI(), true)
	file.close()

# Maps were 37 x 19 before the floors got bigger, saves without a size are from then
const LEGACY_SIZE = Vector2(37, 19)

func isCompatible(path: String) -> bool:
	var file = File.new()
	if file.open(path, File.READ) != OK:
		return false
	for _i in range(5):
		file.get_var(true)
	var map = file.get_var(true)
	file.close()
	return sizeOf(map) == Vector2(GLOBAL.FLOOR_SIZE_X, GLOBAL.FLOOR_SIZE_Y)

func sizeOf(map) -> Vector2:
	if map is Dictionary and map.has("size"):
		return map["size"]
	return LEGACY_SIZE

# Returns false when there is nothing to load or the save is from a version with smaller maps
func loadGame(charName: String) -> bool:
	var checkFile = File.new()
	var checkPath = filePath + charName + ".sav"
	if not checkFile.file_exists(checkPath):
		checkPath = oldFilePath + charName + ".sav"
	if checkFile.file_exists(checkPath) and not isCompatible(checkPath):
		Ref.ui.write("This save was made with smaller maps and cannot be loaded.")
		return false
	Ref.game.cleanFloor()
	for a in Ref.currentLevel.allies.get_children():
		GLOBAL.monstersByPosition.erase(a.pos)
		a.free()
	var file = File.new()
	var path = filePath + charName + ".sav"
	if not file.file_exists(path):
		# Saves made by older versions were written next to the project
		path = oldFilePath + charName + ".sav"
		if not file.file_exists(path):
			return false
	# Was reading Ref.character.stats.charName and ignoring the charName argument
	file.open(path, File.READ)
	loadItemGenerator(file.get_var(true))
	loadStatusEngine(file.get_var(true))
	loadItems(file.get_var(true))
	loadStatuses(file.get_var(true))
	loadGlobals(file.get_var(true))
	loadMap(file.get_var(true))
	loadMonsters(file.get_var(true))
	loadAllies(file.get_var(true))
	loadNpcs(file.get_var(true))
	loadCharacter(file.get_var(true))
	loadLevelBuffer(file.get_var(true))
	loadTraps(file.get_var(true))
	loadEngine(file.get_var(true))
	loadUI(file.get_var(true))
	file.close()
	return true

func saveItemGenerator() -> Dictionary:
	return {
		"id": Ref.game.itemGenerator.id
	}

func loadItemGenerator(dict: Dictionary):
	Ref.game.itemGenerator.id = dict["id"]

func saveStatusEngine() -> Dictionary:
	return {
		"id": StatusEngine.id
	}

func loadStatusEngine(dict: Dictionary):
	StatusEngine.id = dict["id"]

func saveMap() -> Dictionary:
	var dungeonInfo = []
	var cells = Ref.currentLevel.dungeon.get_used_cells()
	for c in cells:
		dungeonInfo.append([c, Ref.currentLevel.dungeon.get_cellv(c), Ref.currentLevel.dungeon.get_cell_autotile_coord(c.x, c.y)])
	return {
		"dungeon": tileMapToArray(Ref.currentLevel.dungeon),
		"shadows": tileMapToArray(Ref.currentLevel.shadows),
		"under": tileMapToArray(Ref.currentLevel.underShadows),
		"searched": Ref.currentLevel.searched,
		# Saves hold the map as arrays of the floor size, so they can only be loaded at the same size
		"size": Vector2(GLOBAL.FLOOR_SIZE_X, GLOBAL.FLOOR_SIZE_Y),
		"seed": Ref.game.runSeed,
		"currentBiome": WorldHandler.currentBiome,
		"currentFloor": WorldHandler.currentFloor,
	}

func loadMap(dict: Dictionary):
	Ref.currentLevel.initShadows()
	Ref.currentLevel.initSecrets()
	arrayToTilemap(dict["dungeon"], Ref.currentLevel.dungeon)
	arrayToTilemap(dict["shadows"], Ref.currentLevel.shadows, false)
	arrayToTilemap(dict["under"], Ref.currentLevel.underShadows, false)
	Ref.currentLevel.searched = dict["searched"]
	Ref.game.runSeed = dict.get("seed", Ref.game.runSeed)
	WorldHandler.currentBiome = dict["currentBiome"]
	WorldHandler.currentFloor = dict["currentFloor"]

func saveCharacter() -> Dictionary:
	return {
		"pos": Ref.character.pos,
		"class": Ref.character.charClass,
		"enchants": Ref.character.enchants,
		"statuses": Ref.character.statuses,
		"inventory": {
			"rests": Ref.character.inventory.rests,
			"currentWeapon": Ref.character.inventory.currentWeapon,
			"currentArmor": Ref.character.inventory.currentArmor,
			"currentTalismans": Ref.character.inventory.currentTalismans,
			"weapons": Ref.character.inventory.weapons,
			# Was saving the rests count here, so the armor in the bag was lost on every save
			"armors": Ref.character.inventory.armors,
			"potions": Ref.character.inventory.potions,
			"scrolls": Ref.character.inventory.scrolls,
			"throwings": Ref.character.inventory.throwings,
			"talismans": Ref.character.inventory.talismans,
			"lockpicks": Ref.character.inventory.lockpicks,
			"golds": Ref.character.inventory.golds,
			"food": Ref.character.inventory.food,
			"light": Ref.character.inventory.light,
			"rations": Ref.character.inventory.rations,
			"torches": Ref.character.inventory.torches,
			"arrows": Ref.character.inventory.arrows,
			"stones": Ref.character.inventory.stones,
		},
		"stats": {
			"name": Ref.character.stats.charName,
			"xp": Ref.character.stats.xp,
			"level": Ref.character.stats.level,
		},
		"spells": {
			"spells": Ref.character.spells.spells,
			"spellsUses": Ref.character.spells.spellsUses,
		},
		"skills": {
			"feats": Ref.character.skills.feats,
			"ftp": Ref.character.skills.ftp,
			"skills": Ref.character.skills.skills,
			"masteries": Ref.character.skills.masteries,
			"skp": Ref.character.skills.skp,
		},
		"shortcuts": {
			"shortcuts": Ref.character.shortcuts.shortcuts,
			"shortcutsType": Ref.character.shortcuts.shortcutsType,
		},
		"fatigue": {
			"actual": Ref.character.fatigue.actual,
			"total": Ref.character.fatigue.total,
		}
	}

func loadCharacter(dict: Dictionary):
	Ref.character.init(dict["class"], false)
	Ref.character.enchants = dict["enchants"]
	Ref.character.statuses = dict["statuses"]
	Ref.character.inventory.rests = dict["inventory"]["rests"]
	Ref.character.inventory.currentWeapon = dict["inventory"]["currentWeapon"]
	Ref.character.inventory.currentArmor = dict["inventory"]["currentArmor"]
	Ref.character.inventory.currentTalismans = dict["inventory"]["currentTalismans"]
	Ref.character.inventory.weapons = dict["inventory"]["weapons"]
	# Was assigning the armors entry to rests, the armor list itself was never loaded
	# Saves made before the fix above hold the rest count (a number) here, keep the bag empty then
	var savedArmors = dict["inventory"]["armors"]
	Ref.character.inventory.armors = savedArmors if savedArmors is Array else []
	Ref.character.inventory.potions = dict["inventory"]["potions"]
	Ref.character.inventory.scrolls = dict["inventory"]["scrolls"]
	Ref.character.inventory.throwings = dict["inventory"]["throwings"]
	Ref.character.inventory.talismans = dict["inventory"]["talismans"]
	Ref.character.inventory.lockpicks = dict["inventory"]["lockpicks"]
	Ref.character.inventory.golds = dict["inventory"]["golds"]
	# Saves from before food and light start fed and lit
	var inv = dict["inventory"]
	Ref.character.inventory.food = inv.get("food", Supplies.FOOD_START)
	Ref.character.inventory.light = inv.get("light", Supplies.LIGHT_MAX)
	Ref.character.inventory.rations = inv.get("rations", 2)
	Ref.character.inventory.torches = inv.get("torches", 2)
	Ref.character.inventory.arrows = inv.get("arrows", 0)
	Ref.character.inventory.stones = inv.get("stones", 0)
	Ref.character.stats.charName = dict["stats"]["name"]
	Ref.character.stats.xp = dict["stats"]["xp"]
	Ref.character.stats.level = dict["stats"]["level"]
	Ref.character.spells.spells = dict["spells"]["spells"]
	Ref.character.spells.spellsUses = dict["spells"]["spellsUses"]
	Ref.character.skills.feats = dict["skills"]["feats"]
	Ref.character.skills.ftp = dict["skills"]["ftp"]
	Ref.character.skills.skills = dict["skills"]["skills"]
	Ref.character.skills.masteries = dict["skills"]["masteries"]
	Ref.character.skills.skp = dict["skills"]["skp"]
	Ref.character.shortcuts.shortcuts = dict["shortcuts"]["shortcuts"]
	Ref.character.shortcuts.shortcutsType = dict["shortcuts"]["shortcutsType"]
	Ref.character.stats.computeStats()
	Ref.character.setPosition(dict["pos"])

func saveMonsters() -> Dictionary:
	var result = []
	for m in Ref.currentLevel.monsters.get_children():
		var allies = []
		for a in m.allies:
			allies.append(a.get_instance_id())
		result.append({
			"id": m.get_instance_id(),
			"type": m.type,
			"status": m.status,
			"statuses": m.statuses,
			"pos": m.pos,
			"skipNextTurn": m.skipNextTurn,
			"allies": allies,
			"buffCD": m.buffCD,
			"actions": {
				"throwings": m.actions.throwings,
				"spells": m.actions.spells,
				"buffs": m.actions.buffs,
				"debuffs": m.actions.debuffs,
				"heals": m.actions.heals,
				"selfBuffs": m.actions.selfBuffs,
				"selfHeals": m.actions.selfHeals,
			}
		})
	return {
		"monsters": result
	}

func loadMonsters(dict: Dictionary):
	var alliesOldIds: Dictionary = {}
	var reverseIds: Dictionary = {}
	for m in dict["monsters"]:
		var monster = monsterScene.instance()
		Ref.currentLevel.monsters.add_child(monster)
		monster.spawn(m["type"], m["pos"], true)
		monster.stats.type = m["type"]
		monster.allies = []
		monster.status = m["status"]
		monster.statuses = m["statuses"]
		monster.skipNextTurn = m["skipNextTurn"]
		monster.buffCD = m["buffCD"]
		monster.actions.throwings = m["actions"]["throwings"]
		monster.actions.spells = m["actions"]["spells"]
		monster.actions.buffs = m["actions"]["buffs"]
		monster.actions.debuffs = m["actions"]["debuffs"]
		monster.actions.heals = m["actions"]["heals"]
		monster.actions.selfBuffs = m["actions"]["selfBuffs"]
		monster.actions.selfHeals = m["actions"]["selfHeals"]
		monster.stats.computeStats()
		alliesOldIds[monster.get_instance_id()] = m["allies"]
		reverseIds[m["id"]] = monster
	for monster in Ref.currentLevel.monsters.get_children():
		for allyId in alliesOldIds[monster.get_instance_id()]:
			monster.allies.append(reverseIds[allyId])

func saveAllies() -> Dictionary:
	var result = []
	for m in Ref.currentLevel.allies.get_children():
		result.append({
			"id": m.get_instance_id(),
			"type": m.type,
			"status": m.status,
			"statuses": m.statuses,
			"pos": m.pos,
			"skipNextTurn": m.skipNextTurn,
			"buffCD": m.buffCD,
			"actions": {
				"throwings": m.actions.throwings,
				"spells": m.actions.spells,
				"buffs": m.actions.buffs,
				"debuffs": m.actions.debuffs,
				"heals": m.actions.heals,
				"selfBuffs": m.actions.selfBuffs,
				"selfHeals": m.actions.selfHeals,
			}
		})
	return {
		"allies": result
	}

func loadAllies(dict: Dictionary):
	for m in dict["allies"]:
		var monster = monsterScene.instance()
		Ref.currentLevel.allies.add_child(monster)
		monster.spawn(m["type"], m["pos"], true)
		monster.stats.type = m["type"]
		monster.allies = [Ref.character.get_instance_id()]
		monster.status = m["status"]
		monster.statuses = m["statuses"]
		monster.skipNextTurn = m["skipNextTurn"]
		monster.buffCD = m["buffCD"]
		monster.actions.throwings = m["actions"]["throwings"]
		monster.actions.spells = m["actions"]["spells"]
		monster.actions.buffs = m["actions"]["buffs"]
		monster.actions.debuffs = m["actions"]["debuffs"]
		monster.actions.heals = m["actions"]["heals"]
		monster.actions.selfBuffs = m["actions"]["selfBuffs"]
		monster.actions.selfHeals = m["actions"]["selfHeals"]
		monster.stats.computeStats()

func saveNpcs() -> Dictionary:
	var result = []
	for n in Ref.currentLevel.npcs.get_children():
		result.append({
			"type": n.type,
			"pos": n.pos,
			"spokeWelcome": n.spokeWelcome,
			"spokeIntro": n.spokeIntro
		})
	return {
		"npcs": result
	}

func loadNpcs(dict: Dictionary):
	for n in dict["npcs"]:
		var npc = npcScene.instance()
		Ref.currentLevel.npcs.add_child(npc)
		npc.setPosition(n["pos"])
		npc.type = n["type"]
		npc.spokeIntro = n["spokeIntro"]
		npc.spokeWelcome = n["spokeWelcome"]

func saveTraps() -> Dictionary:
	var result = []
	for t in Ref.currentLevel.traps.get_children():
		result.append([t.type, t.pos, t.hidden, t.disabled])
	return {
		"traps": result
	}

func loadTraps(dict: Dictionary):
	GLOBAL.trapsByPos.clear()
	for t in dict["traps"]:
		var trap = trapScene.instance()
		Ref.currentLevel.traps.add_child(trap)
		trap.init(t[0], t[1])
		if not t[2]:
			trap.reveal(false)
		elif t[3]:
			trap.disable()
			GLOBAL.trapsByPos.erase(trap.pos)

func saveItems() -> Dictionary:
	var items: Dictionary = {}
	for i in GLOBAL.items.keys():
		items[i] = itemToVar(GLOBAL.items[i])
	return {
		"items": items
	}

func loadItems(dict: Dictionary):
	for i in dict["items"].keys():
		GLOBAL.items[i] = varToItem(dict["items"][i])

func saveStatuses() -> Dictionary:
	return {
		"statuses": GLOBAL.statuses
	}

func loadStatuses(dict: Dictionary):
	GLOBAL.statuses = dict["statuses"]

func saveGlobals() -> Dictionary:
	return {
		"itemsOnFloor": GLOBAL.itemsOnFloor,
		"chests": GLOBAL.chests,
		"hiddenDoors": GLOBAL.hiddenDoors,
		"lockedDoors": GLOBAL.lockedDoors,
		"testedDoors": GLOBAL.testedDoors,
		"known": GLOBAL.known,
	}

func loadGlobals(dict: Dictionary):
	# Saves from before identification have no list, everything counts as known there
	if dict.has("known"):
		GLOBAL.known = dict["known"]
	else:
		Identify.reset()
		Identify.learnEverything()
	GLOBAL.itemsOnFloor.clear()
	for pilePos in dict["itemsOnFloor"].keys():
		var item = dict["itemsOnFloor"][pilePos]
		for itemId in item[GLOBAL.FLOOR_IDS]:
			GLOBAL.dropItemOnFloor(itemId, pilePos, item[GLOBAL.FLOOR_TO_SELL], item[GLOBAL.FLOOR_PRICE], item[GLOBAL.FLOOR_RENEWABLE])
		GLOBAL.itemsOnFloor[pilePos][GLOBAL.FLOOR_EXP] = item[GLOBAL.FLOOR_EXP]
	GLOBAL.chests.clear()
	for c in dict["chests"].values():
		var chest = chestScene.instance()
		Ref.currentLevel.chests.add_child(chest)
		chest.init(c[0])
		GLOBAL.chests[chest.get_instance_id()] = c
	GLOBAL.hiddenDoors = dict["hiddenDoors"]
	GLOBAL.lockedDoors = dict["lockedDoors"]
	GLOBAL.testedDoors = dict["testedDoors"]

func saveEngine() -> Dictionary:
	return {
		"turn": GeneralEngine.turn
	}

func loadEngine(dict: Dictionary):
	GeneralEngine.turn = dict["turn"]

func saveUI() -> Dictionary:
	return {
		"diary": Ref.ui.diaryContent
	}

func loadUI(dict: Dictionary):
	Ref.ui.diary.clear()
	Ref.ui.diary.append_bbcode(dict["diary"])
	Ref.ui.monsterPanelList.fillList()
	Ref.ui.statusBar.refreshStatuses(Ref.character)

func saveLevelBuffer() -> Dictionary:
	return {
		"currentLevel": Ref.currentLevel.levelBuffer.currentLevel,
		"savedLevels": Ref.currentLevel.levelBuffer.savedLevels
	}

func loadLevelBuffer(dict: Dictionary):
	Ref.currentLevel.levelBuffer.currentLevel = dict["currentLevel"]
	Ref.currentLevel.levelBuffer.savedLevels = dict["savedLevels"]

func tileMapToArray(tilemap: TileMap) -> Array:
	var result = []
	for i in range(GLOBAL.FLOOR_SIZE_X):
		result.append([])
		for _j in range(GLOBAL.FLOOR_SIZE_Y):
			result[i].append([-1, -1])
	var cells = tilemap.get_used_cells()
	for c in cells:
		if c.x < 0 or c.y < 0:
			continue
		if c.x >= GLOBAL.FLOOR_SIZE_X or c.y >= GLOBAL.FLOOR_SIZE_Y:
			continue
		result[c.x][c.y] = [tilemap.get_cellv(c), tilemap.get_cell_autotile_coord(c.x, c.y)]
	return result

func arrayToTilemap(array: Array, tilemap: TileMap, clear:bool = true):
	if clear:
		tilemap.clear()
	for i in range(GLOBAL.FLOOR_SIZE_X):
		for j in range(GLOBAL.FLOOR_SIZE_Y):
			tilemap.set_cellv(Vector2(i, j), array[i][j][0], false, false, false, array[i][j][1])

func vecToJson(v: Vector2) -> Array:
	return [v.x, v.y]

func jsonToVec(array: Array) -> Vector2:
	return Vector2(array[0], array[1])

func itemToVar(item: Array) -> Array:
	var result = item.duplicate(true)
	if result[GLOBAL.IT_DMG] != null:
		result[GLOBAL.IT_DMG] = result[GLOBAL.IT_DMG].toVec()
	return result

func varToItem(item: Array) -> Array:
	var result = item.duplicate(true)
	if result[GLOBAL.IT_DMG] != null:
		result[GLOBAL.IT_DMG] = GeneralEngine.DmgDice.fromVec(result[GLOBAL.IT_DMG])
	return result
