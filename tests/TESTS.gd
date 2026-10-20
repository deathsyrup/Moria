extends Node

onready var tests_move = get_node("TESTS_MOVE")
onready var tests_inventory = get_node("TESTS_INVENTORY")

signal tested
signal done

var TEST_SPEED = 0.05

const TEST_NAME = 0
const TEST_POS = 1
const TEST_INIT = 2
const TEST_INPUTS = 3

var spawnedItems: Array = []
var rememberedThrowings: int = 0
var rememberedXp: int = 0
var rememberedGolds: int = 0
var layoutA: int = 0
var layoutB: int = 0
var layoutC: int = 0
var rememberedMusic: float = 0.0

func runAll():
	var collection = get_children()
	if Ref.game.tests != 0:
		collection = [get_child(Ref.game.tests-1)]
	for c in collection:
		if not c.toTest:
			continue
		prints("Testing collection", c.name)
		runCollection(c)
		yield(self, "done")
	get_tree().quit()

func runCollection(tester: Node):
	# Was Time.get_unix_time_from_system(), a Godot 4 API that does not exist in Godot 3
	var time_start = OS.get_ticks_msec() / 1000.0
	for testId in tester.tests.keys():
		runTest(tester, testId)
		yield(self, "tested")
	var time_elapsed = OS.get_ticks_msec() / 1000.0 - time_start
	prints("Tested", tester.tests.size(), "/", tester.tests.size(), "in", time_elapsed, "seconds")
	emit_signal("done")

func runTest(tester: Node, testId: int):
	Settings.difficulty = 1
	Identify.reset()
	Settings.tips = false
	Ref.game.testFloor()
	# Was GLOBAL.items.empty(), a query that clears nothing. The item ids restart at 0 for every
	# test, so items left by earlier tests collided with the new ones
	GLOBAL.items.clear()
	Ref.ui.lastPrinted = ""
	Ref.game.inventoryMenu.currentTab = 0
	Ref.game.itemGenerator.id = -1
	spawnedItems = []
	var test = tester.tests[testId]
	prints('\t', "Testing", test[TEST_NAME], "...")
	GeneralEngine.isFaking = true
	yield(get_tree(), "idle_frame")
	Ref.character.init(-1)
	Ref.currentLevel.placeCharacter(test[TEST_POS])
	yield(get_tree(), "idle_frame")
	for step in test[TEST_INIT]:
		if step.size() == 2:
			call(step[0], step[1])
		if step.size() == 3:
			call(step[0], step[1], step[2])
	yield(get_tree(), "idle_frame")
	for input in test[TEST_INPUTS]:
		yield(get_tree().create_timer(TEST_SPEED), "timeout")
		if input is Array:
			tester.call(input[0], testId, input[1])
		elif input.begins_with("assert"):
			tester.call(input, testId)
		elif input.begins_with("fake"):
			call(input, testId)
		else:
			var a = InputEventAction.new()
			a.action = input
			a.pressed = true
			Input.parse_input_event(a)
			yield(get_tree(), "idle_frame")
			a.pressed = false
			Input.parse_input_event(a)
			yield(get_tree(), "idle_frame")
	emit_signal("tested")

func fake_dice(value: int):
	GeneralEngine.fakedValue = value

func fake_low_dice(_testId: int):
	GeneralEngine.fakedValue = 1

func fake_high_dice(_testId: int):
	GeneralEngine.fakedValue = 6

func fake_remember_throwings(_testId: int):
	rememberedThrowings = Ref.character.inventory.throwings.size()

func fake_remember_xp(_testId: int):
	rememberedXp = Ref.character.stats.xp

func fake_remember_music(_testId: int):
	rememberedMusic = Settings.musicVolume

func fake_restore_music(_testId: int):
	Settings.setMusicVolume(rememberedMusic)

func fake_travel(_testId: int):
	Ref.game.travelTo(Vector2(10, 8))

func fake_low_hp(_testId: int):
	Settings.effects = true
	Ref.character.stats.hp = 2

func fake_full_hp(_testId: int):
	Ref.character.stats.hp = Ref.character.stats.hpMax

func fake_hold_right(_testId: int):
	var a = InputEventAction.new()
	a.action = "ui_right"
	a.pressed = true
	Input.parse_input_event(a)

func fake_release_right(_testId: int):
	var a = InputEventAction.new()
	a.action = "ui_right"
	a.pressed = false
	Input.parse_input_event(a)

func fake_many_traps(_testId: int):
	for i in range(30):
		Ref.currentLevel.placeTrap(Vector2(5 + i, 6))
	Ref.game.capTraps()

func fake_next_floor(_testId: int):
	WorldHandler.setLocation(1, Data.BIOME_DUNGEON)
	Ref.game.nextFloor()

func fake_remember_golds(_testId: int):
	rememberedGolds = Ref.character.inventory.golds

func layout_signature() -> int:
	var total = 0
	for c in Ref.currentLevel.dungeon.get_used_cells_by_id(GLOBAL.FLOOR_ID):
		total += int(c.x) * 131 + int(c.y) * 7919 + int(c.x) * int(c.y)
	return total

# The same seed gives the same floor, another seed gives another one
func fake_seed_floors(_testId: int):
	WorldHandler.setLocation(2, Data.BIOME_DUNGEON)
	Ref.game.runSeed = 1234
	Ref.game.newFloor()
	layoutA = layout_signature()
	# Whatever the balance left behind by the floor before, the same seed gives the same floor
	WorldHandler.diffCR = 7.5
	Ref.game.newFloor()
	layoutB = layout_signature()
	WorldHandler.diffCR = -6.0
	Ref.game.runSeed = 98765
	Ref.game.newFloor()
	layoutC = layout_signature()

func fake_summary_stats(_testId: int):
	Ref.character.floorStatsFloor = 2
	Ref.character.kills = 5
	Ref.character.floorKillsStart = 1
	Ref.character.floorChests = 1
	Ref.character.floorItems = 3

var specialSeen = {"vault": 0, "lair": 0}
var specialProblems = 0

# Build floors until both a vault and a lair showed up (or give up after 60) and check each room
func fake_special_rooms(_testId: int):
	WorldHandler.setLocation(3, Data.BIOME_DUNGEON)
	for i in range(60):
		Ref.game.runSeed = 4000 + i * 11
		Ref.game.newFloor()
		var seen = flood(Ref.character.pos)
		for room in SpecialRooms.built():
			specialSeen[room["kind"]] += 1
			if not seen.has(room["outside"]) or not seen.has(room["door"]):
				specialProblems += 1
			if room["kind"] == "lair" and room["monsters"] < 3:
				specialProblems += 1
			if room["kind"] == "vault" and Ref.currentLevel.chests.get_child_count() == 0:
				specialProblems += 1
		if specialSeen["vault"] >= 3 and specialSeen["lair"] >= 2:
			break

# Cells reachable from a start, doors count as open and so do hidden doors
func flood(start: Vector2) -> Dictionary:
	var seen = {start: 0}
	var queue = [start]
	while not queue.empty():
		var c = queue.pop_front()
		for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			var n = c + d
			if seen.has(n):
				continue
			var id = Ref.currentLevel.dungeon.get_cellv(n)
			if id == -1 or (id == GLOBAL.WALL_ID and not GLOBAL.hiddenDoors.has(n)):
				continue
			seen[n] = seen[c] + 1
			queue.append(n)
	return seen

func fake_debug_key(_testId: int):
	WorldHandler.setLocation(1, Data.BIOME_DUNGEON)

func fake_clear_statuses(_testId: int):
	StatusEngine.clearStatuses(Ref.character)

var areasBuilt = {}
func fake_build_areas(_testId: int):
	for biome in [Data.BIOME_DUNGEON, Data.BIOME_CAVERN, Data.BIOME_CRYPT, Data.BIOME_MINE, Data.BIOME_VOLCANO]:
		WorldHandler.setLocation(2, biome)
		Ref.game.runSeed = 321
		Ref.game.newFloor()
		var types = {}
		for m in Ref.currentLevel.monsters.get_children():
			types[m.type] = true
		areasBuilt[biome] = {"monsters": Ref.currentLevel.monsters.get_child_count(), "types": types, "tint": Ref.currentLevel.dungeon.modulate}
		# only monsters of the area's pool (plus special-room draws from the same pool)
		var allowed = {}
		for encounter in Data.encounters[biome]:
			for group in encounter[Data.ENC_MONSTERS]:
				allowed[group[Data.ENC_MO_TYPE]] = true
		for type in types.keys():
			assert(allowed.has(type))

var championFound = false
var hoardDropped = false
var champOnFirstFloor = false
func fake_champion_floor(_testId: int):
	WorldHandler.setLocation(1, Data.BIOME_CRYPT)
	Ref.game.newFloor()
	for m in Ref.currentLevel.monsters.get_children():
		if Data.championTypes.has(m.type):
			champOnFirstFloor = true
	WorldHandler.setLocation(Data.biomes[Data.BIOME_CRYPT][Data.BI_FLOORS], Data.BIOME_CRYPT)
	Ref.game.newFloor()
	for m in Ref.currentLevel.monsters.get_children():
		if m.type == Data.areaChampions[Data.BIOME_CRYPT]:
			championFound = true
			var cell = m.pos
			# 150 XP would level the character up and open a press-Enter prompt that takes the input
			m.stats.xp = 0
			m.die()
			hoardDropped = GLOBAL.itemsOnFloor.has(cell)

func fake_drink_first_potion(_testId: int):
	Ref.character.quaffPotion(Ref.character.inventory.potions[0])

func fake_learn_scroll(_testId: int):
	Identify.learn("scroll", 1)

func fake_drink_each_potion(_testId: int):
	for p in [Data.PO_MIGHT, Data.PO_BRILLANCE_1, Data.PO_REGENERATION, Data.PO_INVISIBILITY]:
		Ref.character.pickItem(Ref.game.itemGenerator.getPotion(p))
		Ref.character.quaffPotion(Ref.character.inventory.potions[0])

# hp is kept in rememberedXp, the test helper that already stores one number
func fake_regeneration(_testId: int):
	Ref.character.stats.updateHp(Ref.character.stats.hpMax - 10)
	rememberedXp = Ref.character.stats.hp
	Ref.character.pickItem(Ref.game.itemGenerator.getPotion(Data.PO_REGENERATION))
	Ref.character.quaffPotion(Ref.character.inventory.potions[0])
	for _i in range(3):
		StatusEngine.decreaseStatusesTime(Ref.character)

func fake_hunger(_testId: int):
	Ref.character.inventory.food = Supplies.HUNGRY + 1
	Supplies.burnFood(2)

func fake_burn_out_torches(_testId: int):
	Ref.character.inventory.light = 1
	Ref.character.inventory.torches = 1
	Supplies.tick()
	Ref.character.inventory.light = 1
	Supplies.tick()

func spawn_supply(kind: int, pos: Vector2):
	var items = Ref.game.itemGenerator.generateSupply(kind, 1)
	GLOBAL.dropItemOnFloor(items[0], pos)

func fake_pick_supplies(_testId: int):
	rememberedXp = Ref.character.inventory.lockpicks
	for id in GLOBAL.itemsOnFloor[Vector2(11, 10)][GLOBAL.FLOOR_IDS].duplicate():
		Ref.character.pickItem([id])

func fake_wield_sling(_testId: int):
	Ref.character.inventory.equipWeapon(Ref.character.inventory.weapons[0])
	Ref.character.inventory.stones = 5

# Fires without the targeting UI: the shot itself
func fake_fire_sling(_testId: int):
	var weapon = Ref.character.inventory.getWeapon()
	spawn_monster(Data.MO_DUMMY, Vector2(14, 10))
	var target = instance_from_id(GLOBAL.monstersByPosition[Vector2(14, 10)])
	Ref.game.throwHandler.fireResolve(weapon, Data.W_SLING, target, false)

func fake_wait(_testId: int):
	pass

func fake_clean_floor(_testId: int):
	Ref.game.cleanFloor()

func fake_last_printed(_testId: int):
	Ref.ui.lastPrinted = ""

func spawn_locked_door(pos: Vector2):
	Ref.currentLevel.dungeon.set_cellv(pos, GLOBAL.DOOR_ID, false, false, false, Vector2(0,1))
	GLOBAL.lockedDoors.append(pos)

func spawn_hidden_door(pos: Vector2):
	Ref.currentLevel.dungeon.set_cellv(pos, GLOBAL.WALL_ID)
	GLOBAL.hiddenDoors.append(pos)

func set_lockpicks(value: int):
	Ref.character.inventory.updateLockpicks(value)

func spawn_weapon(id: int, pos):
	var items = Ref.game.itemGenerator.getWeapon(id)
	if pos != null:
		for item in items:
			GLOBAL.dropItemOnFloor(item, pos)
	else:
		Ref.character.pickItem(items)
	spawnedItems.append_array(items)

func spawn_shield(id: int, pos):
	var items = Ref.game.itemGenerator.getShield(id)
	if pos != null:
		for item in items:
			GLOBAL.dropItemOnFloor(item, pos)
	else:
		Ref.character.pickItem(items)
	spawnedItems.append_array(items)

func spawn_armor(id: int, pos):
	var items = Ref.game.itemGenerator.getArmor(id)
	if pos != null:
		for item in items:
			GLOBAL.dropItemOnFloor(item, pos)
	else:
		Ref.character.pickItem(items)
	spawnedItems.append_array(items)

func spawn_talisman(id: int, pos):
	var items = Ref.game.itemGenerator.getTalisman(id)
	if pos != null:
		for item in items:
			GLOBAL.dropItemOnFloor(item, pos)
	else:
		Ref.character.pickItem(items)
	spawnedItems.append_array(items)

func spawn_potion(id: int, pos):
	var items = Ref.game.itemGenerator.getPotion(id)
	if pos != null:
		for item in items:
			GLOBAL.dropItemOnFloor(item, pos)
	else:
		Ref.character.pickItem(items)
	spawnedItems.append_array(items)

func spawn_scroll(id: int, pos):
	var items = Ref.game.itemGenerator.getScroll(id)
	if pos != null:
		for item in items:
			GLOBAL.dropItemOnFloor(item, pos)
	else:
		Ref.character.pickItem(items)
	spawnedItems.append_array(items)

func spawn_throwable(id: int, pos):
	var items = Ref.game.itemGenerator.getThrowable(id)
	if pos != null:
		for item in items:
			GLOBAL.dropItemOnFloor(item, pos)
	else:
		Ref.character.pickItem(items)
	spawnedItems.append_array(items)

func spawn_lockpicks(pos: Vector2, count: int):
	var items = Ref.game.itemGenerator.generateLockpicks(count)
	for item in items:
		GLOBAL.dropItemOnFloor(item, pos)

func spawn_golds(pos: Vector2, count: int):
	var items = Ref.game.itemGenerator.generateGolds(0, count)
	for item in items:
		GLOBAL.dropItemOnFloor(item, pos)

func spawn_monster(idx: int, pos: Vector2):
	Ref.currentLevel.spawnMonster(idx, pos)

func spawn_ally(idx: int, pos: Vector2):
	Ref.currentLevel.spawnMonster(idx, pos, true)

func aura_cells(center: Vector2) -> Array:
	var cells = []
	for i in range(-2, 3):
		for j in range(-2, 3):
			cells.append(center + Vector2(i, j))
	return cells

func spawn_allied_fire_aura(pos: Vector2):
	Aura.create(aura_cells(pos), Aura.FIRE_AURA, 5, true)

func spawn_hostile_fire_aura(pos: Vector2):
	Aura.create(aura_cells(pos), Aura.FIRE_AURA, 5, false)

func spawn_trap(idx: int, pos: Vector2):
	Ref.currentLevel.placeTrap(pos, idx)
