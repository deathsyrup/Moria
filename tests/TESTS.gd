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
	Ref.game.testFloor()
	GLOBAL.items.empty()
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
