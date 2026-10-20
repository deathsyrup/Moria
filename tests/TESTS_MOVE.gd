extends Node

export var toTest = true

const tests = {
	0: [
		"Move",
		Vector2(10, 10),
		[],
		["ui_left", "ui_down", "ui_right", "ui_up", "assert_no_move"]
	],
	1: [
		"Move against wall",
		Vector2(3, 3),
		[],
		["ui_left", "assert_no_move", 
		"ui_down", "assert_no_move", 
		"ui_right", "assert_no_move",
		"ui_up", "assert_no_move"]
	],
	2: [
		"Open a door",
		Vector2(3, 5),
		[],
		["ui_right", "assert_no_move",
		"ui_right", "assert_move_right"]
	],
	3: [
		"Move against a locked door",
		Vector2(10, 10),
		[
			["spawn_locked_door", Vector2(11,10)],
			["set_lockpicks", 0]
		],
		["ui_right", "assert_no_move"]
	],
	4: [
		"Fail unlocking a door",
		Vector2(10, 10),
		[
			["spawn_locked_door", Vector2(11,10)],
			["set_lockpicks", 1],
			["fake_dice", 1],
		],
		["ui_right", "yes", "assert_no_move", "assert_no_lockpicks",
		"ui_right", "assert_no_move"]
	],
	5: [
		"Unlock a locked door",
		Vector2(10, 10),
		[
			["spawn_locked_door", Vector2(11,10)],
			["set_lockpicks", 1],
			["fake_dice", 6],
		],
		["ui_right", "yes", "assert_no_move", "assert_one_lockpicks",
		"ui_right", "assert_move_right", "assert_no_locked_door"]
	],
	6: [
		"Automatically discover a hidden door",
		Vector2(10, 12),
		[
			["spawn_hidden_door", Vector2(10,3)],
			["fake_dice", 6],
		],
		["ui_up", "ui_up", "ui_up", "ui_up", "assert_one_hidden_door",
		"ui_up", "assert_no_hidden_door"]
	],
	7: [
		"Manually discover a hidden door",
		Vector2(10, 12),
		[
			["spawn_hidden_door", Vector2(10,3)],
			["fake_dice", 1],
		],
		["ui_up", "ui_up", "ui_up", "ui_up",
		"ui_up", "assert_one_hidden_door", "search",
		"fake_high_dice", "search", "assert_no_hidden_door"]
	],
	8: [
		"Move against a hidden door",
		Vector2(10, 12),
		[
			["spawn_hidden_door", Vector2(10,11)],
			["fake_dice", 1],
		],
		["search", "assert_one_hidden_door", "ui_up", "assert_no_move"]
	],
	9: [
		"Move against a hidden locked door",
		Vector2(10, 12),
		[
			["spawn_hidden_door", Vector2(10,11)],
			["set_lockpicks", 1],
			["fake_dice", 1],
		],
		["search", "assert_one_hidden_door", "ui_up", "assert_no_move"]
	],
	10: [
		"Automatically discover trap",
		Vector2(10, 12),
		[
			["spawn_trap", 0, Vector2(10, 3)],
			["fake_dice", 6],
		],
		[["assert_trap_hidden", Vector2(10, 3)], "ui_up",
		"ui_up", "ui_up", "ui_up", "ui_up", "ui_up", "ui_up", "ui_up",
		["assert_trap_revealed", Vector2(10, 3)],
		"fake_last_printed", "ui_up", ["assert_last_printed", ""]]
	],
	11: [
		"Manually discover trap",
		Vector2(10, 12),
		[
			["spawn_trap", 0, Vector2(10, 3)],
			["fake_dice", 1],
		],
		["ui_up", "ui_up", "ui_up", "ui_up", "ui_up", "ui_up", "ui_up", "ui_up",
		["assert_trap_hidden", Vector2(10, 3)], "search",
		["assert_trap_hidden", Vector2(10, 3)], "fake_high_dice",
		"search", ["assert_last_printed", "writeHiddenTrapDetected"],
		["assert_trap_revealed", Vector2(10, 3)],
		"fake_last_printed", "ui_up", ["assert_last_printed", ""],
		["assert_trap_revealed", Vector2(10, 3)]]
	],
	12: [
		"Trigger trap",
		Vector2(10, 12),
		[
			["spawn_trap", 0, Vector2(10, 3)],
			["fake_dice", 1],
		],
		["ui_up", "ui_up", "ui_up", "ui_up", "ui_up", "ui_up", "ui_up", "ui_up",
		["assert_trap_hidden", Vector2(10, 3)], "ui_up",
		["assert_last_printed", "writeCharacterTakeHit"],
		["assert_no_trap", Vector2(10, 3)]]
	],
	13: [
		"Attack contact creature",
		Vector2(10, 12),
		[
			["spawn_monster", Data.MO_DUMMY, Vector2(10, 9)],
			["fake_dice", 6],
		],
		["ui_up", "ui_up",
		["assert_last_printed", "writeCharacterTakeHit"],
		"fake_last_printed", "search",
		["assert_last_printed", "writeCharacterTakeHit"],
		"ui_up"]
	],
	14: [
		"Awake creature",
		Vector2(10, 12),
		[
			["spawn_monster", Data.MO_DUMMY, Vector2(10, 3)],
			["fake_dice", 6],
		],
		[["assert_creature_sleep", Vector2(10, 3)],
		"ui_up", "ui_up", "ui_up", "ui_up",
		["assert_creature_awake", Vector2(10, 3)]]
	],
	15: [
		"Allied aura hurts an enemy",
		Vector2(10, 12),
		[
			["spawn_monster", Data.MO_DUMMY, Vector2(10, 3)],
			["spawn_allied_fire_aura", Vector2(10, 3)],
			["fake_dice", 1],
		],
		["search", "assert_enemy_hurt"]
	],
	16: [
		"Allied aura spares the character and allies",
		Vector2(10, 12),
		[
			["spawn_ally", Data.MO_DUMMY, Vector2(10, 11)],
			["spawn_allied_fire_aura", Vector2(10, 12)],
			["fake_dice", 1],
		],
		["search", "assert_ally_unhurt", "assert_character_unhurt"]
	],
	17: [
		"Hostile aura hurts the character and allies",
		Vector2(10, 12),
		[
			["spawn_ally", Data.MO_DUMMY, Vector2(10, 11)],
			["spawn_hostile_fire_aura", Vector2(10, 12)],
			["fake_dice", 1],
		],
		["search", "assert_ally_hurt", "assert_character_hurt"]
	],
	18: [
		"Hostile aura spares an enemy",
		Vector2(10, 12),
		[
			["spawn_monster", Data.MO_DUMMY, Vector2(10, 3)],
			["spawn_hostile_fire_aura", Vector2(10, 3)],
			["fake_dice", 1],
		],
		["search", "assert_enemy_unhurt"]
	],
	19: [
		"Map auras are cleared with the floor",
		Vector2(10, 12),
		[
			["spawn_allied_fire_aura", Vector2(10, 3)],
		],
		["fake_clean_floor", "assert_no_map_auras"]
	],
	20: [
		"Enemy attacks a summon",
		Vector2(10, 12),
		[
			["spawn_monster", Data.MO_DUMMY, Vector2(10, 5)],
			["spawn_ally", Data.MO_DUMMY, Vector2(10, 6)],
			["fake_dice", 6],
		],
		["fake_remember_xp", "search", "search", "search", "search",
		"assert_ally_hurt", "assert_xp_unchanged"]
	],
	21: [
		"Group members spawn on free cells they can see",
		Vector2(10, 12),
		[
			["spawn_monster", Data.MO_DUMMY, Vector2(26, 10)],
		],
		["assert_near_cells_valid"]
	],
	22: [
		"Every sound effect and music track has a file",
		Vector2(10, 12),
		[],
		["assert_sounds_exist"]
	],
	23: [
		"Options menu changes the music volume",
		Vector2(10, 12),
		[],
		["fake_remember_music", "ui_cancel", "assert_options_mode", "ui_down", "ui_down",
		"ui_left", "assert_music_lowered", "fake_restore_music", "ui_cancel", "assert_normal_mode_move"]
	],
	24: [
		"Help screen opens and closes",
		Vector2(10, 12),
		[],
		["help", "assert_help_mode", "ui_cancel", "assert_normal_mode_move"]
	],
	25: [
		"Game over summary",
		Vector2(10, 12),
		[],
		["assert_summary_lines"]
	],
	26: [
		"Low health warning",
		Vector2(10, 12),
		[],
		["fake_low_hp", "assert_low_health", "fake_full_hp", "assert_not_low_health"]
	],
	27: [
		"Click to travel",
		Vector2(10, 12),
		[],
		["fake_travel", "fake_wait", "fake_wait", "fake_wait", "fake_wait", "fake_wait", "fake_wait",
		"fake_wait", "fake_wait", "fake_wait", "fake_wait", "assert_traveled"]
	],
	28: [
		"Holding an arrow key keeps walking",
		Vector2(6, 8),
		[],
		["fake_hold_right", "fake_wait", "fake_wait", "fake_wait", "fake_wait", "fake_wait", "fake_wait",
		"fake_wait", "fake_wait", "fake_wait", "fake_wait", "fake_wait", "fake_wait", "fake_wait", "fake_wait",
		"fake_wait", "fake_wait", "fake_wait", "fake_wait", "fake_release_right", "assert_walked_far"]
	],
	29: [
		"Title screen helpers",
		Vector2(10, 12),
		[],
		["assert_manual_conversion", "assert_morgue_line", "assert_save_date", "assert_killer_in_summary"]
	],
	30: [
		"Traps are capped per floor",
		Vector2(10, 12),
		[],
		["fake_many_traps", "assert_traps_capped"]
	],
	31: [
		"Taking the stairs moves to the next floor",
		Vector2(10, 12),
		[],
		["fake_next_floor", "assert_next_floor"]
	],
	32: [
		"Floor card texts",
		Vector2(10, 12),
		[],
		["assert_card_texts"]
	],
	33: [
		"Camera stays inside the map",
		Vector2(10, 12),
		[],
		["assert_camera_limits"]
	],
	34: [
		"Saves know the map size they were made with",
		Vector2(10, 12),
		[],
		["assert_save_size"]
	],
	35: [
		"Gold is picked up by walking over it",
		Vector2(10, 10),
		[
			["spawn_golds", Vector2(11, 10), 40],
		],
		["fake_remember_golds", "ui_right", "assert_golds_gained"]
	],
	36: [
		"Screenshot path and quit saving",
		Vector2(10, 12),
		[],
		["assert_screenshot_path", "assert_no_quit_save_in_tests"]
	],
	37: [
		"Gamepad bindings exist",
		Vector2(10, 12),
		[],
		["assert_gamepad_bindings"]
	],
	38: [
		"Message history opens and closes",
		Vector2(10, 12),
		[],
		["history", "assert_log_mode", "ui_cancel", "assert_normal_mode_move"]
	],
	39: [
		"Floor summary text",
		Vector2(10, 12),
		[],
		["fake_summary_stats", "assert_floor_summary"]
	],
	40: [
		"The same seed gives the same floor",
		Vector2(10, 12),
		[],
		["fake_seed_floors", "assert_seed_floors"]
	],
	41: [
		"Map overview opens, closes and knows the explored cells",
		Vector2(10, 12),
		[],
		["overview", "assert_map_mode", "ui_cancel", "assert_normal_mode_move", "assert_explored_cells"]
	],
	42: [
		"Hover tooltip describes a monster and loot",
		Vector2(10, 12),
		[
			["spawn_monster", Data.MO_DUMMY, Vector2(10, 9)],
			["spawn_golds", Vector2(11, 12), 7],
		],
		["assert_cell_info"]
	],
	43: [
		"Vaults and lairs are built, reachable and filled",
		Vector2(10, 12),
		[],
		["fake_special_rooms", "assert_special_rooms"]
	],
	44: [
		"The slash key no longer skips floors, ? opens the controls",
		Vector2(10, 12),
		[],
		["fake_debug_key", "debug_new_floor", "fake_wait", "fake_wait", "assert_floor_unchanged", "assert_question_mark_is_help"]
	],
	45: [
		"Difficulty scales monster health",
		Vector2(10, 12),
		[],
		["assert_difficulty_scaling"]
	],
	46: [
		"Unlocks, tips and starting bonuses",
		Vector2(10, 12),
		[],
		["assert_progress"]
	],
	47: [
		"A trap is named as the killer",
		Vector2(10, 12),
		[
			["spawn_trap", 0, Vector2(10, 12)],
		],
		["assert_trap_killer"]
	],
	48: [
		"Every trap kind does what it says",
		Vector2(10, 12),
		[
			["spawn_monster", Data.MO_DUMMY, Vector2(10, 5)],
		],
		["assert_trap_kinds", "fake_clear_statuses"]
	],
	49: [
		"Areas have their own mix of traps",
		Vector2(10, 12),
		[],
		["assert_trap_mix"]
	],
	50: [
		"Monster, encounter and area data are consistent",
		Vector2(10, 12),
		[],
		["assert_world_data"]
	],
	51: [
		"Every area builds floors with its own monsters",
		Vector2(10, 12),
		[],
		["fake_build_areas", "assert_areas_built"]
	],
	52: [
		"A champion waits on the last floor and drops a hoard",
		Vector2(10, 12),
		[],
		["fake_champion_floor", "assert_champion_hoard"]
	],
}

func assert_last_printed(testId: int, msg: String):
	assert(Ref.ui.lastPrinted == msg)

func assert_no_move(testId: int):
	assert(Ref.character.pos == tests[testId][get_parent().TEST_POS])

func assert_move_right(testId: int):
	assert(Ref.character.pos.x == tests[testId][get_parent().TEST_POS].x+1)
	assert(Ref.character.pos.y == tests[testId][get_parent().TEST_POS].y)

func assert_no_lockpicks(testId: int):
	assert(Ref.character.inventory.lockpicks == 0)

func assert_one_lockpicks(testId: int):
	assert(Ref.character.inventory.lockpicks == 1)

func assert_no_locked_door(testId: int):
	assert(GLOBAL.lockedDoors.empty())

func assert_no_hidden_door(testId: int):
	assert(GLOBAL.hiddenDoors.empty())

func assert_one_hidden_door(testId: int):
	assert(GLOBAL.hiddenDoors.size() == 1)

func assert_trap_hidden(testId: int, pos: Vector2):
	assert(GLOBAL.getTrapByPos(pos).hidden)

func assert_no_trap(testId: int, pos: Vector2):
	assert(!GLOBAL.trapsByPos.has(pos))

func assert_trap_revealed(testId: int, pos: Vector2):
	assert(!GLOBAL.getTrapByPos(pos).hidden)

func assert_creature_sleep(testId: int, pos: Vector2):
	assert(GLOBAL.getMonsterByPos(pos).status == "sleep")

func assert_creature_awake(testId: int, pos: Vector2):
	assert(GLOBAL.getMonsterByPos(pos).status == "awake")

func assert_enemy_hurt(testId: int):
	# The dummy has 1 HP, it is gone when the aura hurts it
	var monsters = Ref.currentLevel.monsters
	assert(monsters.get_child_count() == 0 or monsters.get_child(0).stats.currentHp < monsters.get_child(0).stats.hpMax)

func assert_enemy_unhurt(testId: int):
	var m = Ref.currentLevel.monsters.get_child(0)
	assert(m.stats.currentHp == m.stats.hpMax)

func assert_ally_hurt(testId: int):
	var allies = Ref.currentLevel.allies
	assert(allies.get_child_count() == 0 or allies.get_child(0).stats.currentHp < allies.get_child(0).stats.hpMax)

func assert_ally_unhurt(testId: int):
	var m = Ref.currentLevel.allies.get_child(0)
	assert(m.stats.currentHp == m.stats.hpMax)

func assert_character_hurt(testId: int):
	assert(Ref.character.stats.hp < Ref.character.stats.hpMax)

func assert_character_unhurt(testId: int):
	assert(Ref.character.stats.hp == Ref.character.stats.hpMax)

func assert_no_map_auras(testId: int):
	assert(Ref.currentLevel.auras.get_child_count() == 0)

func assert_xp_unchanged(testId: int):
	assert(Ref.character.stats.xp == get_parent().rememberedXp)

# Around (26, 10) the test floor has walls on both sides and a monster on the center cell.
# Run a few times: the cells are picked at random
func assert_near_cells_valid(testId: int):
	var handler = Ref.game.dungeonGenerator.encounterHandler
	for _i in range(100):
		var cell = handler.getNearFreeCell(Vector2(26, 10))
		if cell == null:
			continue
		assert(cell != Vector2(26, 10))
		# Rows 9 to 11 are walled on both sides of the corridor, nothing beside it is visible
		assert(cell.x == 26 or cell.y < 9 or cell.y > 11)

func assert_sounds_exist(testId: int):
	for sound in Sfx.EVENTS.values() + Sfx.DIRECT:
		assert(Sfx.getStream(Sfx.SFX_FOLDER, sound) != null)
		# A looping effect plays forever once it is triggered
		assert(not Sfx.getStream(Sfx.SFX_FOLDER, sound).loop)
	for track in Sfx.MUSIC:
		assert(Sfx.getMusicStream(track) != null)

func assert_options_mode(testId: int):
	assert(GLOBAL.currentMode == GLOBAL.MODE_OPTIONS)

func assert_music_lowered(testId: int):
	assert(Settings.musicVolume < get_parent().rememberedMusic or Settings.musicVolume == 0.0)

func assert_normal_mode_move(testId: int):
	assert(GLOBAL.currentMode == GLOBAL.MODE_NORMAL)

func assert_help_mode(testId: int):
	assert(GLOBAL.currentMode == GLOBAL.MODE_HELP)

func assert_summary_lines(testId: int):
	var lines = Ref.character.summaryLines()
	assert(lines.size() >= 5)
	assert("floor" in "\n".join(lines))

func assert_low_health(testId: int):
	assert(Fx.lowHealth)

func assert_not_low_health(testId: int):
	assert(not Fx.lowHealth)

func assert_traveled(testId: int):
	assert(Ref.character.pos == Vector2(10, 8))

# One tap is one step, holding the key walks on
func assert_walked_far(testId: int):
	assert(Ref.character.pos.x >= 10)
	assert(Ref.character.pos.y == 8)

func assert_manual_conversion(testId: int):
	var out = TextScreen.markdownToBbcode("# Title\n- one **bold** item\n| Key | Does |\n|---|---|\n| S | Search |")
	assert("[b]Title[/b]" in out)
	assert("\u2022 one [b]bold[/b] item" in out)
	assert("Search" in out)
	assert(not "|" in out)

func assert_morgue_line(testId: int):
	var line = Morgue.line({"name": "Ana", "class": "Mage", "floor": 3, "level": 2, "kills": 5, "killer": "Goblin", "date": "2026-01-02 03:04"})
	assert("Ana the Mage" in line and "floor 3" in line and "killed by Goblin" in line)

func assert_save_date(testId: int):
	assert(SaveFiles.dateText(0).begins_with("1970-01-01"))

func assert_killer_in_summary(testId: int):
	Ref.character.killedBy = "Goblin"
	assert("Killed by Goblin" in Ref.character.summaryLines())
	Ref.character.killedBy = ""

func assert_traps_capped(testId: int):
	var cap = Ref.game.trapCap()
	assert(Ref.currentLevel.traps.get_child_count() == cap)
	assert(GLOBAL.trapsByPos.size() == cap)

func assert_next_floor(testId: int):
	assert(WorldHandler.currentFloor == 2)
	assert(not Fx.transitioning)

func assert_card_texts(testId: int):
	assert(Fx.cardTexts(Data.BIOME_CAVERN, 3)[0] == "FLOOR 3")
	assert(Fx.cardTexts(Data.BIOME_CAVERN, 3)[1] == "The Caverns")
	assert(Fx.cardTexts(Data.BIOME_DUNGEON, 7)[1] == "The Dungeon")
	assert(Fx.cardTexts(Data.BIOME_TROLL_BOSS, 1)[0] == "THE TROLL")

func assert_camera_limits(testId: int):
	var level = Ref.currentLevel
	level.centerOn(Vector2(1, 1), true)
	assert(level.cameraOffset == Vector2(0, 0))
	level.centerOn(Vector2(GLOBAL.FLOOR_SIZE_X - 2, GLOBAL.FLOOR_SIZE_Y - 2), true)
	assert(level.cameraOffset == Vector2((GLOBAL.FLOOR_SIZE_X - GLOBAL.MAP_VIEW_COLS) * 9, (GLOBAL.FLOOR_SIZE_Y - GLOBAL.MAP_VIEW_ROWS) * 9))
	# The middle of the map: the character is in the middle of the window
	level.centerOn(Vector2(GLOBAL.FLOOR_SIZE_X / 2, GLOBAL.FLOOR_SIZE_Y / 2), true)
	assert(level.cameraOffset.x > 0 and level.cameraOffset.y > 0)
	level.centerOn(Ref.character.pos, true)

func assert_save_size(testId: int):
	var saves = Ref.game.saveSystem
	assert(saves.sizeOf({}) == Vector2(37, 19))
	assert(saves.sizeOf({"size": Vector2(55, 27)}) == Vector2(55, 27))

func assert_golds_gained(testId: int):
	assert(Ref.character.inventory.golds >= get_parent().rememberedGolds + 40)
	assert(not GLOBAL.itemsOnFloor.has(Vector2(11, 10)))

func assert_screenshot_path(testId: int):
	var path = Settings.screenshotPath()
	assert(path.begins_with("user://screenshots/moria_") and path.ends_with(".png"))

func assert_no_quit_save_in_tests(testId: int):
	assert(not Ref.game.canSaveOnQuit())

func assert_gamepad_bindings(testId: int):
	for action in ["ui_up", "ui_down", "ui_left", "ui_right", "ui_accept", "ui_cancel", "inventory", "pickLoot", "search"]:
		var found = false
		for e in InputMap.get_action_list(action):
			if e is InputEventJoypadButton or e is InputEventJoypadMotion:
				found = true
		assert(found)

func assert_log_mode(testId: int):
	assert(GLOBAL.currentMode == GLOBAL.MODE_LOG)

func assert_floor_summary(testId: int):
	assert(Ref.character.floorSummary() == "Floor 2: 4 slain, 1 chests, 3 items")
	Ref.character.floorStatsFloor = 0
	assert(Ref.character.floorSummary() == "")

func assert_seed_floors(testId: int):
	var t = get_parent()
	assert(t.layoutA == t.layoutB)
	assert(t.layoutA != t.layoutC)

func assert_map_mode(testId: int):
	assert(GLOBAL.currentMode == GLOBAL.MODE_MAP)

func assert_explored_cells(testId: int):
	Ref.currentLevel.refresh_view()
	assert(Ref.game.mapOverview.canvas.exploredCells().size() > 10)

func assert_cell_info(testId: int):
	var monster = CellInfo.describe(Vector2(10, 9), false)
	assert("Dummy" in monster and "HP" in monster)
	assert(CellInfo.describe(Vector2(11, 12), false) != "")
	assert(CellInfo.describe(Vector2(-3, 4), false) == "")

func assert_special_rooms(testId: int):
	var t = get_parent()
	assert(t.specialSeen["vault"] >= 1)
	assert(t.specialSeen["lair"] >= 1)
	assert(t.specialProblems == 0)

func assert_floor_unchanged(testId: int):
	assert(WorldHandler.currentFloor == 1)

func assert_question_mark_is_help(testId: int):
	var found = false
	for e in InputMap.get_action_list("help"):
		if e is InputEventKey and e.scancode == KEY_SLASH and e.shift:
			found = true
	assert(found)

func assert_difficulty_scaling(testId: int):
	Settings.difficulty = 1
	var normal = Ref.currentLevel.spawnMonster(Data.MO_GOBLIN, Vector2(12, 5))
	assert(normal.stats.hpMax == 4)
	Settings.difficulty = 0
	var easy = Ref.currentLevel.spawnMonster(Data.MO_GOBLIN, Vector2(13, 5))
	assert(easy.stats.hpMax == 3)
	Settings.difficulty = 2
	var hard = Ref.currentLevel.spawnMonster(Data.MO_GOBLIN, Vector2(14, 5))
	assert(hard.stats.hpMax == 5 and hard.stats.currentHp == 5)
	assert(Settings.startRests() == 1)
	Settings.setDifficulty(3)
	assert(Settings.difficulty == 0)
	Settings.difficulty = 1

func assert_progress(testId: int):
	Progress.data = {"tips": [], "stats": {}, "unlocked": []}
	assert(not Progress.isUnlocked("potion"))
	Progress.add("kills", 50)
	assert(Progress.isUnlocked("potion"))
	Progress.best("best_floor", 3)
	assert(Progress.isUnlocked("coin"))
	Progress.best("best_floor", 2)
	assert(Progress.stat("best_floor") == 3)
	Settings.tips = true
	assert(Tips.shouldShow("t1"))
	Progress.markSeen("t1")
	assert(not Tips.shouldShow("t1"))
	Settings.tips = false
	assert(not Tips.shouldShow("t2"))
	# Starting bonuses
	Progress.data["unlocked"] = ["coin", "picks", "rest"]
	var golds = Ref.character.inventory.golds
	var picks = Ref.character.inventory.lockpicks
	var rests = Ref.character.inventory.rests
	Progress.applyToNewCharacter()
	assert(Ref.character.inventory.golds == golds + 40)
	assert(Ref.character.inventory.lockpicks == picks + 3)
	assert(Ref.character.inventory.rests == rests + 1)
	Progress.data = {"tips": [], "stats": {}, "unlocked": []}

func assert_trap_killer(testId: int):
	Ref.character.stats.hp = 1
	TrapEngine.trigger(GLOBAL.getTrapByPos(Vector2(10, 12)), Ref.character)
	assert(Ref.character.killedBy == "Spike trap")
	Ref.character.stats.hp = Ref.character.stats.hpMax
	Ref.character.killedBy = ""

func trigger_trap(type: int, cell: Vector2):
	Ref.currentLevel.placeTrap(cell, type)
	TrapEngine.trigger(GLOBAL.getTrapByPos(cell), Ref.character)

func assert_trap_kinds(testId: int):
	var hp = Ref.character.stats.hpMax
	for type in [Data.TR_DART, Data.TR_PIT, Data.TR_FIRE]:
		Ref.character.stats.hp = hp
		trigger_trap(type, Vector2(12 + type, 14))
		assert(Ref.character.stats.hp < hp)
	trigger_trap(Data.TR_GAS, Vector2(20, 14))
	assert(Ref.character.statuses.has(Data.STATUS_POISON))
	trigger_trap(Data.TR_SNARE, Vector2(21, 14))
	assert(Ref.character.statuses.has(Data.STATUS_IMMOBILE))
	var monster = GLOBAL.getMonsterByPos(Vector2(10, 5))
	assert(monster.status == "sleep")
	trigger_trap(Data.TR_ALARM, Vector2(22, 14))
	assert(monster.status == "awake")
	Ref.character.stats.hp = hp

func assert_trap_mix(testId: int):
	var seen = {}
	for _i in range(200):
		seen[Data.randomTrapType(Data.BIOME_DUNGEON)] = true
		assert(Data.randomTrapType(Data.BIOME_CAVERN) != Data.TR_ALARM)
		assert(Data.randomTrapType(Data.BIOME_VOLCANO) != Data.TR_ALARM)
	assert(seen.size() >= 4)
	var fire = 0
	for _i in range(200):
		if Data.randomTrapType(Data.BIOME_VOLCANO) == Data.TR_FIRE:
			fire += 1
	assert(fire > 40)

func assert_world_data(testId: int):
	# every monster in every encounter exists and has all of its fields
	for biome in Data.encounters.keys():
		assert(Data.biomes.has(biome))
		for encounter in Data.encounters[biome]:
			for group in encounter[Data.ENC_MONSTERS]:
				assert(Data.monsters.has(group[Data.ENC_MO_TYPE]))
				assert(group[Data.ENC_MO_MIN] >= 1 and group[Data.ENC_MO_MAX] >= group[Data.ENC_MO_MIN])
	for type in Data.monsters.keys():
		assert(Data.monsters[type].size() == 14)
		assert(Data.monsters[type][Data.MO_HP] > 0)
	for type in Data.monsterTints.keys():
		assert(Data.monsters.has(type))
	for type in Data.championTypes:
		assert(Data.monsters.has(type) and Data.monsters[type][Data.MO_HP] >= 28)
	# every area of the chain has monsters (except the troll's) and a champion (except the troll's)
	for biome in Data.biomes.keys():
		if biome != Data.BIOME_TROLL_BOSS:
			assert(Data.encounters.has(biome) and Data.areaChampions.has(biome))
		for next in Data.biomes[biome][Data.BI_CONNECT]:
			assert(Data.biomes.has(next))
	# the chain goes round: six areas and back to the dungeon
	var biome = Data.BIOME_DUNGEON
	var seen = []
	for _i in range(6):
		seen.append(biome)
		biome = Data.biomes[biome][Data.BI_CONNECT][0]
	assert(biome == Data.BIOME_DUNGEON and seen.size() == 6)
	for a in range(seen.size()):
		for b in range(a + 1, seen.size()):
			assert(seen[a] != seen[b])

func assert_areas_built(testId: int):
	var built = get_parent().areasBuilt
	for biome in built.keys():
		assert(built[biome]["monsters"] > 0)
	assert(built[Data.BIOME_DUNGEON]["tint"] == Color(1, 1, 1))
	assert(built[Data.BIOME_VOLCANO]["tint"] != Color(1, 1, 1))
	Ref.currentLevel.dungeon.modulate = Color(1, 1, 1)

func assert_champion_hoard(testId: int):
	var t = get_parent()
	assert(t.championFound and t.hoardDropped and not t.champOnFirstFloor)
