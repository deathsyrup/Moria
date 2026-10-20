extends Node

export var toTest = true

const tests = {
	0: [
		"Pickup single item",
		Vector2(10, 10),
		[
			["spawn_weapon", 0, Vector2(11, 10)],
		],
		[["assert_one_loot", Vector2(11, 10)], "ui_right", "pickLoot",
		"assert_last_printed_pickup", ["assert_no_loot", Vector2(11, 10)],
		["assert_weapon_in_bag", 0]]
	],
	1: [
		"Pickup pile of single item",
		Vector2(10, 10),
		[
			["spawn_weapon", 0, Vector2(11, 10)],
			["spawn_weapon", 0, Vector2(11, 10)],
		],
		["ui_right", "pickLoot", "assert_choice_mode", "shortcut0",
		"assert_choice_mode", "shortcut3", "assert_choice_mode", "ui_cancel",
		"assert_normal_mode", ["assert_two_loots", Vector2(11, 10)],
		"pickLoot", "shortcut2", "assert_normal_mode", ["assert_weapon_in_bag", 1],
		["assert_one_loot", Vector2(11, 10)], "pickLoot",
		"assert_last_printed_pickup", ["assert_no_loot", Vector2(11, 10)],
		"assert_normal_mode", ["assert_weapon_in_bag", 0]]
	],
	2: [
		"Pickup stack of items",
		Vector2(10, 10),
		[
			["spawn_potion", 0, Vector2(11, 10)],
			["spawn_potion", 0, Vector2(11, 10)],
			["spawn_potion", 0, Vector2(11, 10)],
			["spawn_potion", 0, Vector2(11, 10)],
			["spawn_potion", 0, Vector2(11, 10)],
		],
		["ui_right", "pickLoot", "assert_number_mode", "shortcut0", "ui_accept",
		["assert_potions_in_bag", 0], "pickLoot", "shortcut3", "ui_accept",
		["assert_potions_in_bag", 3], "pickLoot", "shortcut2", "ui_accept",
		["assert_potions_in_bag", 5], ["assert_no_loot", Vector2(11, 10)]]
	],
	3: [
		"Item categories",
		Vector2(10, 10),
		[
			["spawn_weapon", 0, null],
			["spawn_shield", 0, null],
			["spawn_armor", 0, null],
			["spawn_armor", 10, null],
			["spawn_talisman", 0, null],
			["spawn_potion", 0, null],
			["spawn_scroll", 0, null],
			["spawn_throwable", 0, null],
		],
		[
			"inventory", ["assert_item_in_item_list", 0], ["assert_item_in_item_list", 1],
			"ui_right", ["assert_item_in_item_list", 2], ["assert_item_in_item_list", 3],
			"ui_right", ["assert_stackable_in_item_list", 6],
			"ui_right", ["assert_stackable_in_item_list", 5],
			"ui_right", ["assert_stackable_in_item_list", 7],
			"ui_right", ["assert_item_in_item_list", 4], "ui_right", "ui_cancel"
		]
	],
	4: [
		"Inventory scrolling",
		Vector2(10, 10),
		[
			["spawn_weapon", 0, null],
			["spawn_weapon", 0, null],
			["spawn_weapon", 0, null],
			["spawn_weapon", 0, null],
			["spawn_weapon", 0, null],
			["spawn_weapon", 0, null],
			["spawn_weapon", 0, null],
		],
		["inventory", ["assert_inventory_tab_size", 7],
		["assert_selected_item_index", 0], "ui_up", 
		["assert_selected_item_index", 5], "ui_down",
		["assert_selected_item_index", 0], "ui_down",
		["assert_selected_item_index", 1], "ui_cancel"]
	],
	5: [
		"Pickup lockpicks",
		Vector2(10, 10),
		[
			["spawn_lockpicks", Vector2(11, 10), 2],
			["spawn_lockpicks", Vector2(11, 10), 3],
		],
		["ui_right", "pickLoot", "assert_five_lockpicks", ["assert_no_loot", Vector2(11, 10)]]
	],
	6: [
		"Pickup golds",
		Vector2(10, 10),
		[
			["spawn_golds", Vector2(11, 10), 2],
			["spawn_golds", Vector2(11, 10), 3],
		],
		["ui_right", "pickLoot", "assert_five_golds", ["assert_no_loot", Vector2(11, 10)]]
	],
	7: [
		"Drop single item",
		Vector2(10, 10),
		[

		],
		[]
	],
	8: [
		"Drop stackable items",
		Vector2(10, 10),
		[

		],
		[]
	],
	9: [
		"Wear weapon",
		Vector2(10, 10),
		[

		],
		[]
	],
	10: [
		"Wear armor",
		Vector2(10, 10),
		[

		],
		[]
	],
	11: [
		"Wear talisman",
		Vector2(10, 10),
		[

		],
		[]
	],
	12: [
		"Quaff potion",
		Vector2(10, 10),
		[
			["spawn_potion", 0, Vector2(11, 10)],
		],
		[
			"inventory", "ui_right", "ui_right", "ui_right", "quaffPotion",
			"assert_last_printed_null", "assert_inventory_mode", "ui_cancel",
			"ui_right", "pickLoot", "inventory", "quaffPotion",
			"assert_last_printed_quaffed", "ui_cancel"
		]
	],
	13: [
		"Read scroll",
		Vector2(10, 10),
		[
			["spawn_scroll", 1, Vector2(11, 10)],
			["spawn_monster", Data.MO_DUMMY, Vector2(11, 6)],
		],
		[
			"inventory", "ui_right", "ui_right", "readScroll",
			"assert_last_printed_null", "assert_inventory_mode", "ui_cancel",
			"ui_right", "pickLoot", "inventory",
			#"readScroll", TODO re-enable when target scroll exist
			#"assert_target_mode",
			"ui_cancel"
		]
	],
	14: [
		"Throw item",
		Vector2(10, 10),
		[
			["spawn_throwable", 0, Vector2(11, 10)],
			["spawn_monster", Data.MO_DUMMY, Vector2(11, 6)],
		],
		[
			"inventory", "ui_right", "ui_right", "ui_right", "ui_right", "throw",
			"assert_last_printed_null", "assert_inventory_mode", "ui_cancel",
			"ui_right", "pickLoot", "inventory", "throw",
			"assert_target_mode", "ui_cancel"
		]
	],
	15: [
		"Throw a knife",
		Vector2(10, 10),
		[
			["spawn_throwable", 0, Vector2(11, 10)],
			["spawn_monster", Data.MO_DUMMY, Vector2(11, 6)],
		],
		[
			"ui_right", "pickLoot", "fake_remember_throwings", "inventory",
			"ui_right", "ui_right", "ui_right", "ui_right", "throw",
			"assert_target_mode", "ui_accept",
			"fake_wait", "fake_wait", "fake_wait", "fake_wait", "fake_wait",
			"fake_wait", "fake_wait", "fake_wait", "fake_wait", "fake_wait",
			"fake_wait", "fake_wait", "fake_wait", "fake_wait", "fake_wait",
			"fake_wait", "fake_wait", "fake_wait", "fake_wait", "fake_wait",
			"assert_normal_mode", "assert_throwing_used"
		]
	],
	16: [
		"The save stores the armor in the bag",
		Vector2(10, 10),
		[
			["spawn_armor", 0, null],
			["spawn_armor", 1, null],
		],
		["assert_save_keeps_armors"]
	],
	17: [
		"An unknown potion shows a flavor until it is drunk",
		Vector2(10, 10),
		[
			["spawn_potion", Data.PO_MIGHT, null],
		],
		["assert_potion_unknown", "assert_flavors_distinct", "fake_drink_first_potion", "assert_potion_known"]
	],
	18: [
		"An unknown scroll shows a label, and learning renames the ones in the bag",
		Vector2(10, 10),
		[
			["spawn_scroll", 1, null],
			["spawn_scroll", 1, null],
		],
		["assert_scroll_unknown", "fake_learn_scroll", "assert_scroll_known"]
	],
	19: [
		"The new potions do what they say",
		Vector2(10, 10),
		[],
		["fake_drink_each_potion", "assert_potion_effects"]
	],
	20: [
		"Regeneration heals one HP a turn and Might adds damage",
		Vector2(10, 10),
		[],
		["fake_regeneration", "assert_regeneration"]
	],
	21: [
		"Hunger eats a ration when you get hungry",
		Vector2(10, 10),
		[],
		["fake_hunger", "assert_ate_ration"]
	],
	22: [
		"A torch that runs out is replaced, and with none left the view shrinks",
		Vector2(10, 10),
		[],
		["assert_full_light", "fake_burn_out_torches", "assert_dark"]
	],
	23: [
		"Rations and lockpicks on the same floor cell stay separate",
		Vector2(10, 10),
		[
			["spawn_supply", Data.SUP_RATION, Vector2(11, 10)],
			["spawn_supply", Data.SUP_LOCKPICK, Vector2(11, 10)],
			["spawn_supply", Data.SUP_RATION, Vector2(11, 10)],
		],
		["assert_supplies_not_merged", "fake_pick_supplies", "assert_supplies_counted"]
	],
	24: [
		"Firing a sling uses a stone, a sling in melee only bashes",
		Vector2(10, 10),
		[
			["spawn_weapon", Data.W_SLING, null],
		],
		["fake_wield_sling", "assert_sling_bashes", "fake_fire_sling", "assert_stone_used"]
	],
}
func assert_choice_mode(testId: int):
	assert(GLOBAL.currentMode == GLOBAL.MODE_CHOICE)

func assert_number_mode(testId: int):
	assert(GLOBAL.currentMode == GLOBAL.MODE_NUMBER)

func assert_target_mode(testId: int):
	assert(GLOBAL.currentMode == GLOBAL.MODE_TARGET)

func assert_normal_mode(testId: int):
	assert(GLOBAL.currentMode == GLOBAL.MODE_NORMAL)

func assert_inventory_mode(testId: int):
	assert(GLOBAL.currentMode == GLOBAL.MODE_INVENTORY)

func assert_no_move(testId: int):
	assert(Ref.character.pos == tests[testId][get_parent().TEST_POS])

func assert_last_printed_pickup(testId: int):
	assert(Ref.ui.lastPrinted == "writePickupLoot")

func assert_last_printed_quaffed(testId: int):
	assert(Ref.ui.lastPrinted == "writeCharacterHeal")

func assert_last_printed_null(testId: int):
	assert(Ref.ui.lastPrinted == "")

func assert_selected_item_index(testId: int, index: int):
	assert(Ref.game.inventoryMenu.itemList.currentIndex == index)

func assert_no_loot(testId: int, cell: Vector2):
	assert(not GLOBAL.itemsOnFloor.has(cell))

func assert_one_loot(testId: int, cell: Vector2):
	assert(GLOBAL.itemsOnFloor[cell][GLOBAL.FLOOR_IDS].size() == 1)

func assert_two_loots(testId: int, cell: Vector2):
	assert(GLOBAL.itemsOnFloor[cell][GLOBAL.FLOOR_IDS].size() == 2)

func assert_weapon_in_bag(testId: int, id: int):
	assert(Ref.character.inventory.weapons.has(get_parent().spawnedItems[id]))

func assert_potions_in_bag(testId: int, count: int):
	assert(Ref.character.inventory.potions.size() == count)

func assert_inventory_tab_size(testId: int, size: int):
	assert(Ref.game.inventoryMenu.itemList.currentItems.size() == size)

func assert_five_lockpicks(testId: int):
	assert(Ref.character.inventory.lockpicks == 5)

func assert_five_golds(testId: int):
	assert(Ref.character.inventory.golds == 35)

func assert_item_in_item_list(testId:int, id: int):
	var result = false
	for item in Ref.game.inventoryMenu.itemList.currentItems:
		if item[1] == id:
			result = true
	assert(result)

func assert_stackable_in_item_list(testId:int, id: int):
	var result = false
	for item in Ref.game.inventoryMenu.itemList.currentItems:
		if item[4][0] == id:
			result = true
	assert(result)

# Throwing a knife used to abort on the Array effect, the item was never consumed
func assert_throwing_used(testId: int):
	assert(Ref.character.inventory.throwings.size() < get_parent().rememberedThrowings)

# Saving used to store the rest count under "armors", so the armor in the bag was lost on every load
func assert_save_keeps_armors(testId: int):
	var saved = Ref.game.saveSystem.saveCharacter()["inventory"]
	assert(Ref.character.inventory.armors.size() >= 2)
	assert(saved["armors"] == Ref.character.inventory.armors)
	assert(saved["rests"] == Ref.character.inventory.rests)

# Was a name taken straight from the data: the player could read what every potion was before drinking it
func assert_potion_unknown(testId: int):
	var item = GLOBAL.items[Ref.character.inventory.potions[0]]
	assert(item[GLOBAL.IT_NAME] != Data.potions[Data.PO_MIGHT][Data.PO_NAME])
	assert(item[GLOBAL.IT_NAME].ends_with(" potion"))
	assert(not Identify.isKnown("potion", Data.PO_MIGHT))

func assert_potion_known(testId: int):
	assert(Identify.isKnown("potion", Data.PO_MIGHT))
	assert(Identify.displayName("potion", Data.PO_MIGHT) == Data.potions[Data.PO_MIGHT][Data.PO_NAME])

func assert_scroll_unknown(testId: int):
	for id in Ref.character.inventory.scrolls:
		assert(GLOBAL.items[id][GLOBAL.IT_NAME].begins_with("Scroll labelled"))

func assert_scroll_known(testId: int):
	assert(Ref.character.inventory.scrolls.size() == 2)
	for id in Ref.character.inventory.scrolls:
		assert(GLOBAL.items[id][GLOBAL.IT_NAME] == Data.scrolls[1][Data.SC_NAME])

# The flavors are a shuffle of the run seed: two kinds never share a flavor
func assert_flavors_distinct(testId: int):
	var seen = {}
	for idx in Data.potions.keys():
		var n = Identify.flavorName("potion", idx)
		assert(not seen.has(n))
		seen[n] = true

func assert_potion_effects(testId: int):
	var c = Ref.character
	assert(c.statuses.has(Data.STATUS_MIGHT))
	assert(c.statuses.has(Data.STATUS_BRILLIANCE))
	assert(c.statuses.has(Data.STATUS_REGENERATE))
	assert(c.statuses.has(Data.STATUS_INVISIBLE))

func assert_regeneration(testId: int):
	var c = Ref.character
	assert(c.stats.hp == get_parent().rememberedXp + 3)

func assert_ate_ration(testId: int):
	var inv = Ref.character.inventory
	assert(inv.rations == 1)
	assert(inv.food > Supplies.HUNGRY)

func assert_full_light(testId: int):
	assert(Supplies.lightRadius() == GLOBAL.VIEW_RANGE)

func assert_dark(testId: int):
	assert(Supplies.lightRadius() == Supplies.DARK_RADIUS)
	assert(Ref.character.inventory.torches == 0)

func assert_supplies_not_merged(testId: int):
	var cell = Vector2(11, 10)
	assert(GLOBAL.itemsOnFloor[cell][GLOBAL.FLOOR_IDS].size() == 2)

func assert_supplies_counted(testId: int):
	var inv = Ref.character.inventory
	assert(inv.rations == 2 + 2)
	assert(inv.lockpicks == get_parent().rememberedXp + 1)

func assert_sling_bashes(testId: int):
	assert(Ref.character.stats.dmgDices[0].dice.d == 2)
	assert(Supplies.ammoCount() == 5)

func assert_stone_used(testId: int):
	assert(Ref.character.inventory.stones == 4)
