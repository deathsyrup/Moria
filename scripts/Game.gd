extends Node2D

class_name Game

export (int, "Normal, Fast, Tests, Dungeon, Menu, Debug, Generator report") var start = 0
export (int, "Fighter", "Thief", "Mage", "Cleric", "Paladin", "Bard", "Druid", "Ranger") var debugClass = 0
export (bool) var debugMode = false
export (int, "All", "Move", "Inventory") var tests = 0

onready var inventoryMenu = get_node("InventoryMenu")
onready var characterMenu = get_node("CharacterMenu")
onready var spellMenu = get_node("SpellMenu")
onready var chestMenu = get_node("ChestMenu")
onready var chooseClassMenu = get_node("ChooseClassMenu")
onready var chooseNameMenu = get_node("ChooseNameMenu")
onready var chooseSpellMenu = get_node("ChooseSpellMenu")
onready var chooseFeatMenu = get_node("ChooseFeatMenu")
onready var dungeonGenerator = get_node("Utils/DungeonGenerator_v2")
onready var pathfinder = get_node("Utils/Pathfinder")
onready var itemGenerator = get_node("Utils/ItemGenerator") as ItemGenerator
onready var pickupLootHandler = get_node("Utils/PickupLootHandler")
onready var spellHandler = get_node("Utils/SpellHandler")
onready var throwHandler = get_node("Utils/ThrowHandler")
onready var restHandler = get_node("Utils/RestHandler")
onready var saveSystem = get_node("Utils/SaveSystem")
onready var optionsMenu = preload("res://scripts/menu/OptionsMenu.gd").new()
onready var helpMenu = preload("res://scripts/menu/HelpMenu.gd").new()
onready var gameOver = preload("res://scripts/menu/GameOverScreen.gd").new()
onready var historyScreen = preload("res://scripts/menu/TextScreen.gd").new()
onready var mapOverview = preload("res://scripts/menu/MapOverview.gd").new()

var random_seed: int
var autoexplore = false setget setAutoExplore
var traveling = false
var holdTime = 0.0
var hoverCell = Vector2(-1, -1)
# The seed of this run. Every floor is generated from it (see floorSeed), so a seed gives the same dungeon
var runSeed = 0
const HISTORY_LINES = 300
# Where the map is drawn on the 1920 x 1080 screen, clicks outside it belong to the panels
const MAP_WINDOW = Rect2(Vector2(24, 24), Vector2(1332, 684))

# Hold an arrow key to keep walking: it starts after a short delay, then steps at a steady pace
const HOLD_DELAY = 0.3
const HOLD_INTERVAL = 0.1

func _ready():
	set_physics_process(true)
	add_child(optionsMenu)
	add_child(helpMenu)
	add_child(gameOver)
	add_child(historyScreen)
	add_child(mapOverview)
	if debugMode:
		Ref.currentLevel.fog.visible = false
		Ref.currentLevel.shadows.visible = false
		Ref.currentLevel.debugLayer.visible = true
	if GLOBAL.startingMode != null:
		start = GLOBAL.startingMode
	if start == 4:
		get_tree().change_scene("res://scenes/UI/TitleScreen.tscn")
	randomize()
	runSeed = seedFromArguments()
	if runSeed == 0:
		runSeed = randi()
	print("Seed: " + String(runSeed))
	seed(runSeed)
	Ref.game = self
	set_process_input(false)
	set_process(false)
	match start:
		0:
			chooseClassMenu.open()
		1:
			chooseClassMenu.close()
			Ref.character.init(Data.CL_FIGHTER)
			startGame()
		3:
			Ref.currentLevel.fog.visible = false
			Ref.currentLevel.shadows.visible = false
			Ref.character.init(debugClass)
			Ref.character.setPosition(dungeonGenerator.newFloor())
#			Ref.currentLevel.spawnMonster(Data.MO_BO_TROLL)
			set_process_input(true)
		5:
			chooseClassMenu.close()
			dungeonGenerator.biome = 4
			Ref.character.init(debugClass)
			Ref.character.skills.masteries = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
			Ref.character.skills.skp = 50
			Ref.character.skills.ftp = 10
			startGame()
		6:
			dungeonGenerator.analyzer.generateReport()
		7:
			# Was after the catch-all branch below, so Load game on the title screen never ran
			# and started a new fighter instead
			chooseClassMenu.close()
			Ref.character.init(Data.CL_FIGHTER)
			if not saveSystem.loadGame(GLOBAL.loadName):
				GLOBAL.titleMessage = "That save cannot be loaded (made with smaller maps)."
				get_tree().change_scene("res://scenes/UI/TitleScreen.tscn")
				return
			Ref.currentLevel.centerOn(Ref.character.pos, true)
			Ref.currentLevel.refresh_view()
			MasterInput.setMaster(self)
			GLOBAL.currentMode = GLOBAL.MODE_NORMAL
			Sfx.playMusicForBiome(WorldHandler.currentBiome)
		_:
			Ref.character.init(Data.CL_FIGHTER)
			startGame()

func _process(delta):
	if autoexplore:
		# Health check
		if Ref.character.stats.hpPercent() < 0.05:
			Ref.ui.write("Health too low for auto-explore!")
			setAutoExplore(false)
			return
		
		var dir = null
		
		# First priority: attack nearby enemies
		if !GLOBAL.targets.empty():
			# Get all monster positions
			var monster_positions = []
			for target_id in GLOBAL.targets.keys():
				var entity = instance_from_id(target_id)
				if entity != null:
					monster_positions.append(entity.pos)
			
			# Find nearest monster using pathfinder
			if !monster_positions.empty():
				var monsterMap = pathfinder.dijkstraComputeToMonsters(monster_positions)
				if monsterMap != null:
					dir = pathfinder.findNextStep(monsterMap, Ref.character.pos)
		
		# Second priority: collect items on the ground
		if dir == null and !GLOBAL.itemsOnFloor.empty():
			# Check if we're standing on an item
			if GLOBAL.itemsOnFloor.has(Ref.character.pos):
				pickupLootHandler.pickupLootAsync()
				return
			
			# Find nearest item using pathfinder
			var itemMap = pathfinder.dijkstraComputeToItems()
			if itemMap != null:
				dir = pathfinder.findNextStep(itemMap, Ref.character.pos)
		
		# NEW  priority - navigate to chests
		if dir == null and !GLOBAL.chests.empty():
			var chestMap = pathfinder.dijkstraComputeToChests()
			if chestMap != null:
				dir = pathfinder.findNextStep(chestMap, Ref.character.pos)
		
		# Third priority: explore unexplored tiles
		if dir == null:
			dir = pathfinder.findNextStep(pathfinder.exploreMap, Ref.character.pos)
			if dir == null:
				pathfinder.dijkstraCompute()
				dir = pathfinder.findNextStep(pathfinder.exploreMap, Ref.character.pos)
		
		# Fourth priority: go to exit (pass entrance position to exclude it)
		if dir == null:
			var exitMap = pathfinder.dijkstraComputeToExit(Ref.character.spawnPos)
			if exitMap != null:
				dir = pathfinder.findNextStep(exitMap, Ref.character.pos)
				if dir == null:
					Ref.ui.write("Reached the exit!")
					setAutoExplore(false)
					return
			else:
				Ref.ui.write("Nothing left to do.")
				setAutoExplore(false)
				return
		
		if dir != null:
			Ref.character.moveAsync(dir)
	else:
		GeneralEngine.newTurn()

func setAutoExplore(value: bool):
	autoexplore = value
	set_process(autoexplore)
	if autoexplore:
		pathfinder.dijkstraCompute()

func startGame():
	match start:
		1:
			newFloor()
			WorldHandler.currentCR = 2
		2:
			testFloor()
		5:
			testFloor()
			Ref.currentLevel.placeCharacter(Vector2(30, 10))
			Ref.currentLevel.spawnMonster(Data.MO_DUMMY_SUPER, Vector2(20, 4))
			Ref.currentLevel.spawnMonster(Data.MO_DUMMY_WEAK, Vector2(24, 4))
			dungeonGenerator.loadAllItems()
		_:
			WorldHandler.setLocation(1, Data.BIOME_DUNGEON)
#			WorldHandler.setLocation(1, Data.BIOME_TROLL_BOSS)
			WorldHandler.currentCR = 2
			Progress.applyToNewCharacter()
			newFloor()
	Ref.currentLevel.refresh_view()
	MasterInput.setMaster(self)
	GLOBAL.currentMode = GLOBAL.MODE_NORMAL
	if start == 2:
		Tests.runAll()

func nextFloor():
	if !WorldHandler.getNextLocation():
		# Was an empty #TODO that went on to generate the same floor again
		victory()
		return
	Sfx.play("descend")
	# Fade to black, build the next floor while it is black, then fade in (see Fx.arrive)
	var fading = Fx.fadeOut()
	if fading is GDScriptFunctionState:
		yield(fading, "completed")
	newFloor()
	autosave()

# Saved after every new floor, so closing the game never costs more than the current floor
# Was uncapped: a cavern floor could get 31 traps on about 300 cells. Now 5 on the first floors, one more
# every three floors, the surplus is removed at random.
# The last floor of an area has a guardian, asleep and far from where you arrive
func spawnChampion(spawnPos: Vector2):
	var biome = WorldHandler.currentBiome
	if not Data.areaChampions.has(biome) or WorldHandler.currentFloor != Data.biomes[biome][Data.BI_FLOORS]:
		return
	var cell = Ref.currentLevel.getRandomFreeCell()
	for _i in range(120):
		cell = Ref.currentLevel.getRandomFreeCell()
		if Utils.dist(cell, spawnPos) >= 18:
			break
	Ref.currentLevel.spawnMonster(Data.areaChampions[biome], cell)
	Tips.show("champion", "A guardian waits on the last floor of every area. It is much tougher than anything before it, and it leaves a hoard.")

func trapCap() -> int:
	return int((5 + int(WorldHandler.currentFloor / 3)) * GLOBAL.CONTENT_SCALE)

func capTraps():
	var cap = trapCap()
	var traps = Ref.currentLevel.traps.get_children()
	traps.shuffle()
	while traps.size() > cap:
		var trap = traps.pop_back()
		GLOBAL.trapsByPos.erase(trap.pos)
		Ref.currentLevel.get_node("Debug/Traps").set_cellv(trap.pos, -1)
		trap.free()

func autosave():
	# Was announcing "Game saved." even when nothing was written (tests, bots)
	if not Settings.canWrite():
		return
	saveSystem.saveGame()
	Ref.ui.write("Game saved.")

# Walk to a clicked cell that is in view. It stops when an enemy comes into view, when
# something blocks the way or when any key is pressed.
func travelTo(cell: Vector2):
	if traveling or Ref.currentLevel.fog.get_cellv(cell) != 0:
		return
	if not GLOBAL.targets.empty():
		Ref.ui.write("You cannot walk there with enemies in sight.")
		return
	var path = pathfinder.a_star(Ref.character.pos, [cell], 60, true)
	if path == null or path.size() < 2:
		return
	traveling = true
	for i in range(1, path.size()):
		if not traveling or GLOBAL.currentMode != GLOBAL.MODE_NORMAL or not GLOBAL.targets.empty():
			break
		var step = path[i]
		var direction = step - Ref.character.pos
		if abs(direction.x) + abs(direction.y) != 1:
			break
		var hp = Ref.character.stats.hp
		Ref.character.moveAsync(direction)
		yield(get_tree().create_timer(0.07), "timeout")
		if Ref.character.pos != step and Ref.currentLevel.isCellFree(step)[0]:
			# A door was opened by the first try, walk through it
			Ref.character.moveAsync(direction)
			yield(get_tree().create_timer(0.07), "timeout")
		if Ref.character.pos != step or Ref.character.stats.hp < hp:
			break
	traveling = false

func victory():
	Ref.ui.write(Ref.ui.color("You have reached the end of the dungeon. You win!", "yellow"))
	set_process_input(false)
	Ref.ui.askForContinue(self)
	yield(Ref.ui, "coroutine_signal")
	get_tree().change_scene("res://scenes/UI/TitleScreen.tscn")

func cleanFloor():
	#DEBUG
	Ref.currentLevel.get_node("Debug/Traps").clear()
	Ref.currentLevel.get_node("Debug/Secrets").clear()
	Ref.currentLevel.get_node("Debug/Enemies").clear()
	for s in Ref.currentLevel.secrets.get_children():
		s.free()
	GLOBAL.hiddenDoors.clear()
	GLOBAL.lockedDoors.clear()
	GLOBAL.testedDoors.clear()
	#GLOBAL.testedChests.clear()
	Ref.currentLevel.searched.clear()
	for i in range(GLOBAL.FLOOR_SIZE_X):
		Ref.currentLevel.searched.append([])
		for _j in range(GLOBAL.FLOOR_SIZE_Y):
			Ref.currentLevel.searched[i].append(false)
	for m in Ref.currentLevel.monsters.get_children():
		GLOBAL.monstersByPosition.erase(m.pos)
		m.free()
	# Was: never cleared, so a poison cloud kept hurting on the next floor.
	# Auras tied to a caster (relativeTo) follow the character and stay.
	for a in Ref.currentLevel.auras.get_children():
		if a.relativeTo == null:
			a.free()
	for n in Ref.currentLevel.npcs.get_children():
		n.free()
	for c in Ref.currentLevel.chests.get_children():
		c.free()
	GLOBAL.chests.clear()
	for t in Ref.currentLevel.traps.get_children():
		t.free()
	GLOBAL.trapsByPos.clear()
	for l in Ref.currentLevel.loots.get_children():
		l.free()
	for i in GLOBAL.itemsOnFloor.keys():
		GLOBAL.items.erase(i)
	GLOBAL.itemsOnFloor.clear()

func testFloor():
	Ref.currentLevel.levelBuffer.flush()
	cleanFloor()
	# Was: allies survived testFloor() (they follow the character between floors),
	# so a test inherited the allies of the previous one
	for a in Ref.currentLevel.allies.get_children():
		GLOBAL.monstersByPosition.erase(a.pos)
		a.free()
	dungeonGenerator.simpleFloor()
	Ref.currentLevel.initShadows()
	Ref.currentLevel.initSecrets()

func merchantFloor():
	Ref.currentLevel.levelBuffer.saveLevel()
	if Ref.currentLevel.levelBuffer.savedLevels.has("merchant"):
		Ref.currentLevel.levelBuffer.loadLevel("merchant")
	else:
		cleanFloor()
		var spawnPos = dungeonGenerator.newFloor(3)
		Ref.currentLevel.initShadows()
		Ref.currentLevel.initSecrets()
		Ref.currentLevel.placeCharacter(spawnPos)
		Ref.currentLevel.levelBuffer.currentLevel = "merchant"

# Every floor holds some food and torches, and now and then ammo. Without them the dungeon starves you.
func placeSupplies():
	var wanted = [[Data.SUP_RATION, 1], [Data.SUP_TORCH, 1]]
	if randf() < 0.5:
		wanted.append([Data.SUP_RATION, 1])
	if randf() < 0.5:
		wanted.append([Data.SUP_ARROWS, 4 + randi() % 8])
	if randf() < 0.5:
		wanted.append([Data.SUP_STONES, 5 + randi() % 8])
	for w in wanted:
		var cell = Ref.currentLevel.getRandomFreeCell()
		for id in itemGenerator.generateSupply(w[0], w[1]):
			GLOBAL.dropItemOnFloor(id, cell)

func newFloor():
	seed(floorSeed())
	# The encounter balance (diffCR) used to carry over from the floor before, which changed how many random
	# numbers a floor used and so the floor itself. A floor now depends on its seed alone.
	WorldHandler.diffCR = 0.0
	Ref.currentLevel.levelBuffer.flush()
	cleanFloor()
	Ref.currentLevel.initShadows()
	var spawnPos: Vector2
	match WorldHandler.currentBiome:
		Data.BIOME_DUNGEON, Data.BIOME_CRYPT:
			spawnPos = dungeonGenerator.dungeonFloor()
		Data.BIOME_CAVERN, Data.BIOME_MINE, Data.BIOME_VOLCANO:
			spawnPos = dungeonGenerator.cavernFloor()
		_:
			spawnPos = dungeonGenerator.newFloor()
	var tint = Data.areaTints.get(WorldHandler.currentBiome, Vector3(1, 1, 1))
	Ref.currentLevel.dungeon.modulate = Color(tint.x, tint.y, tint.z)
	SpecialRooms.generate()
	spawnChampion(spawnPos)
	capTraps()
	Ref.currentLevel.initSecrets()
	Ref.character.spawnPos = spawnPos
	Ref.currentLevel.placeCharacter(spawnPos)
	Ref.currentLevel.centerOn(spawnPos, true)
	for a in Ref.currentLevel.allies.get_children():
		var cell = Ref.character.getRandomCloseCell()
		if cell == null:
			a.die()
			# Was missing: the dead ally went on to setPosition(null)
			continue
		a.setPosition(cell)
#	for i in range(9):
#		Ref.currentLevel.spawnMonster(i)
	for _i in range(int(round(max(0, randi() % 6 - 2) * GLOBAL.CONTENT_SCALE))):
		Ref.currentLevel.createChest()
	for _i in range(int(round((3 + (randi() % 4)) * GLOBAL.CONTENT_SCALE))):
		Ref.currentLevel.dropItem()
	placeSupplies()
	Sfx.playMusicForBiome(WorldHandler.currentBiome)
	# The floor is built from the seed, everything after it (fights, loot rolls) is random again
	randomize()
	Progress.best("best_floor", WorldHandler.currentFloor)
	if WorldHandler.currentFloor == 1 and WorldHandler.currentBiome == Data.BIOME_DUNGEON:
		Tips.show("start", "Press H for the controls and Tab for the map. S searches for secret doors, O explores for you.")
	Fx.arrive(WorldHandler.currentBiome, WorldHandler.currentFloor, Ref.character.floorSummary())
	Ref.character.startFloorStats()

# Was: key repeat was ignored (is_action_pressed skips echo events), so holding an arrow key moved
# exactly one step and a corridor meant tapping once per cell
# Closing the window keeps the run. Was losing everything since the last stairs.
func _notification(what):
	if what == NOTIFICATION_WM_QUIT_REQUEST and canSaveOnQuit():
		saveSystem.saveGame()

# --seed=12345 starts a run from that seed, --seed=daily from one that is the same for everybody that day
func seedFromArguments() -> int:
	for argument in OS.get_cmdline_args():
		if argument.begins_with("--seed="):
			var value = argument.substr(7)
			if value == "daily":
				var d = OS.get_datetime()
				return ("%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]).hash()
			return int(value)
	return 0

# Each floor has its own seed, so the layout, monsters and loot of a floor do not depend on what the
# player did on the floors before. Fights and the rest of the game stay random.
func floorSeed() -> int:
	return runSeed + 7919 * (WorldHandler.currentBiome * 100 + WorldHandler.currentFloor)

# A tooltip for what the mouse points at (monster, loot, chest, door...)
func updateHover():
	var mouse = get_viewport().get_mouse_position()
	if GLOBAL.currentMode != GLOBAL.MODE_NORMAL or Fx.transitioning or not MAP_WINDOW.has_point(mouse):
		Fx.hideTip()
		hoverCell = Vector2(-1, -1)
		return
	var cell = Ref.currentLevel.dungeon.world_to_map(Ref.currentLevel.dungeon.get_local_mouse_position())
	hoverCell = cell
	Fx.showTip(CellInfo.describe(cell), mouse)

func openHistory():
	var lines = Array(Ref.ui.diaryContent.split("\n"))
	var tail = lines.slice(max(0, lines.size() - HISTORY_LINES), lines.size() - 1)
	var text = "\n".join(PoolStringArray(tail))
	GLOBAL.currentMode = GLOBAL.MODE_LOG
	historyScreen.connect("closed", self, "onHistoryClosed", [], CONNECT_ONESHOT)
	historyScreen.open(text, self, true)

func onHistoryClosed():
	GLOBAL.currentMode = GLOBAL.MODE_NORMAL

# Was always on: / (and so ? and Shift+/, the key matching ignores Shift) skipped to the next floor.
# The cheat is still there for development: the debugMode export, or MORIA_DEBUG=1 in the environment.
func debugKeys() -> bool:
	return debugMode or OS.has_environment("MORIA_DEBUG")

func canSaveOnQuit() -> bool:
	if start == 2 or Ref.character == null or not is_instance_valid(Ref.character):
		return false
	return Ref.character.stats.hp > 0 and Ref.character.charClass >= 0 and GLOBAL.currentMode != GLOBAL.MODE_GAMEOVER

func _physics_process(delta):
	if GLOBAL.currentMode != GLOBAL.MODE_NORMAL or traveling or autoexplore or Ref.character == null or Fx.transitioning:
		holdTime = 0.0
		return
	var direction = heldDirection()
	if direction == Vector2.ZERO:
		holdTime = 0.0
		return
	holdTime += delta
	if holdTime < HOLD_DELAY:
		return
	holdTime = HOLD_DELAY - HOLD_INTERVAL
	# Only walk on through empty cells with no enemy in view. A wall, a door, a monster or an item
	# you would walk onto stops it, tap the key for those.
	if not GLOBAL.targets.empty() or not Ref.currentLevel.isCellFree(Ref.character.pos + direction)[0]:
		return
	Ref.character.moveAsync(direction)

func heldDirection() -> Vector2:
	if Input.is_action_pressed("ui_up"):
		return Vector2(0, -1)
	if Input.is_action_pressed("ui_down"):
		return Vector2(0, 1)
	if Input.is_action_pressed("ui_left"):
		return Vector2(-1, 0)
	if Input.is_action_pressed("ui_right"):
		return Vector2(1, 0)
	return Vector2.ZERO

func _input(event):
	# No moves while the screen fades between floors
	if Fx.transitioning and event.is_pressed():
		get_tree().set_input_as_handled()
		return
	if event.is_pressed():
		traveling = false
	if event is InputEventMouseMotion:
		updateHover()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		if GLOBAL.currentMode == GLOBAL.MODE_NORMAL and MAP_WINDOW.has_point(get_viewport().get_mouse_position()):
			travelTo(Ref.currentLevel.dungeon.world_to_map(Ref.currentLevel.dungeon.get_local_mouse_position()))
		return
	if event.is_pressed() and autoexplore:
		setAutoExplore(false)
	elif (event.is_action_pressed("autoexplore")):
		setAutoExplore(not autoexplore)
	for i in range(1, 10):
		if (event.is_action_released("shortcut" + String(i))):
			var item = Ref.character.shortcuts.getItem(i)
			if item != null:
				match Ref.character.shortcuts.shortcutsType[i]:
					GLOBAL.WP_TYPE:
						Ref.character.equipItem(item)
					GLOBAL.PO_TYPE:
						Ref.character.quaffPotion(item)
					GLOBAL.SC_TYPE:
						Ref.character.readScroll(item)
					GLOBAL.TH_TYPE:
						Ref.character.throw(item)
					GLOBAL.SP_TYPE:
						Ref.character.castSpell(item)
				return
	if (event.is_action_pressed("ui_up")):
		Ref.character.moveAsync(Vector2(0,-1))
	elif (event.is_action_pressed("ui_down")):
		Ref.character.moveAsync(Vector2(0,1))
	elif (event.is_action_pressed("ui_left")):
		Ref.character.moveAsync(Vector2(-1,0))
	elif (event.is_action_pressed("ui_right")):
		Ref.character.moveAsync(Vector2(1,0))
	elif (event.is_action_released("inventory")):
		inventoryMenu.open()
	elif (event.is_action_released("characterMenu")):
		characterMenu.open()
	elif (event.is_action_released("spellMenu")):
		spellMenu.open()
	elif (event.is_action_released("pickLoot")):
		pickupLootHandler.pickupLootAsync()
	elif (event.is_action_released("search")):
		Ref.character.search()
	elif event.is_action_released("fire"):
		Ref.character.fire()
	elif event.is_action_released("rest"):
		restHandler.askrForRest()
	elif event.is_action_released("debug_new_floor") and debugKeys():
		print("====================")
#		Ref.character.setPosition(dungeonGenerator.newFloor())
		nextFloor()
	elif event.is_action_released("ui_cancel") and GLOBAL.currentMode == GLOBAL.MODE_NORMAL:
		optionsMenu.open()
	elif event.is_action_released("help"):
		helpMenu.open()
	elif event.is_action_released("history"):
		openHistory()
	elif event.is_action_released("overview"):
		mapOverview.open()
	elif (event.is_action_released("save")):
		saveSystem.saveGame()
	elif (event.is_action_released("load")):
		saveSystem.loadGame(Ref.character.stats.charName)
	elif (event.is_action_released("no")):
#		Ref.ui.bossBar.damage(1 + (randi() % 5))
		Ref.character.stats.xp += 7
#		Ref.character.takeHit(3)
#		Ref.ui.askForContinue(self)
#		var coroutineReturn = yield(Ref.ui, "coroutine_signal")
#		if coroutineReturn:
#			pass
	elif (event.is_action_released("yes")):
		Ref.ui.bossBar.damage(- 1 - (randi() % 5))
