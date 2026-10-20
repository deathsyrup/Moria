extends Node2D

class_name Ui

signal coroutine_signal

onready var numberHandler = get_node("Utils/NumberHandler")
onready var choiceHandler = get_node("Utils/ChoiceHandler")
onready var yesNoHandler = get_node("Utils/YesNoHandler")
onready var directionHandler = get_node("Utils/DirectionHandler")
onready var targetHandler = get_node("Utils/TargetHandler")
onready var continueHandler = get_node("Utils/ContinueHandler")

onready var diary = get_node("TextBox/TextContainer/DiaryPanel")
onready var shortcuts = get_node("Shortcuts/TextContainer/Label")
onready var nameLabel = get_node("SideMenu/Name/Label")
onready var locationLabel = get_node("SideMenu/Location/Label")
onready var levelLabel = get_node("SideMenu/Level/Label/Level")
onready var xpLabel = get_node("SideMenu/Level/Label/CurrentXP")
onready var maxXpLabel = get_node("SideMenu/Level/Label/MaxXP")
onready var hpMaxLabel = get_node("SideMenu/HPContainer/Label/Max")
onready var hpLabel = get_node("SideMenu/HPContainer/Label/Current")
onready var fatigueLabel = get_node("SideMenu/FatigueContainer/Label/Current")
onready var fatigueMaxLabel = get_node("SideMenu/FatigueContainer/Label/Max")
onready var caLabel = get_node("SideMenu/CAContainer/Label/Current")
onready var protLabel = get_node("SideMenu/ProtContainer/Label/Current")
onready var dmgLabel = get_node("SideMenu/DmgContainer/Label/Current")
onready var hitLabel = get_node("SideMenu/HitContainer/Label/Current")
onready var lockLabel = get_node("SideMenu/LockContainer/Label/Current")
onready var goldLabel = get_node("SideMenu/GoldContainer/Label/Current")
onready var foodLabel = get_node("SideMenu/FoodContainer/Label/Current")
onready var lightLabel = get_node("SideMenu/LightContainer/Label/Current")
onready var ammoLabel = get_node("SideMenu/AmmoContainer/Label/Current")
onready var rFire = get_node("SideMenu/rFire/Label/Current")
onready var rPois = get_node("SideMenu/rPoison/Label/Current")
onready var statusBar = get_node("StatusBar")
onready var fadePanel = get_node("FadePanel")
onready var fadeLabel = get_node("FadePanel/TextContainer/Label")
onready var monsterPanelList = get_node("MonsterPanelList")
onready var bossBar = get_node("BossBar")

var currentChoice = ""
var currentSuffix = ""
var currentMax = 0
# Every diary event sets this name, the setter plays the matching sound effect.
# Inside this script assign it as self.lastPrinted or the setter is skipped
var lastPrinted: String = "" setget setLastPrinted

func setLastPrinted(value: String):
	lastPrinted = value
	Sfx.playEvent(value)
var previousMode: int = GLOBAL.MODE_NONE
var diaryContent: String = ""

func _ready():
	Ref.ui = self
	Ref.character.shortcuts.setUIHsortcutList()
	for _i in range(7):
		diary.append_bbcode('\n')

func askForNumber(maxNb: int, inputer, msg = "How much?"):
	previousMode = GLOBAL.currentMode
	GLOBAL.currentMode = GLOBAL.MODE_NUMBER
	numberHandler.startCoroutine(maxNb, msg)
	var result = yield(numberHandler, "end_coroutine")
	GLOBAL.currentMode = previousMode
	MasterInput.setMaster(inputer)
	emit_signal("coroutine_signal", result)

func askForChoice(list: Array, inputer):
	previousMode = GLOBAL.currentMode
	GLOBAL.currentMode = GLOBAL.MODE_CHOICE
	choiceHandler.startCoroutine(list)
	var result = yield(choiceHandler, "end_coroutine")
	if result == -1:
		writeOk()
	GLOBAL.currentMode = previousMode
	MasterInput.setMaster(inputer)
	emit_signal("coroutine_signal", result)

func askForYesNo(inputer):
	previousMode = GLOBAL.currentMode
	GLOBAL.currentMode = GLOBAL.MODE_YESNO
	yesNoHandler.startCoroutine()
	var result = yield(yesNoHandler, "end_coroutine")
	if !result:
		writeOk()
	GLOBAL.currentMode = previousMode
	MasterInput.setMaster(inputer)
	emit_signal("coroutine_signal", result)

func askForDirection(inputer):
	previousMode = GLOBAL.currentMode
	directionHandler.startCoroutine()
	var result = yield(directionHandler, "end_coroutine")
	GLOBAL.currentMode = previousMode
	MasterInput.setMaster(inputer)
	emit_signal("coroutine_signal", result)

func askForTarget(targets: Array, inputer):
	previousMode = GLOBAL.currentMode
	GLOBAL.currentMode = GLOBAL.MODE_TARGET
	targetHandler.startCoroutine(targets)
	var result = yield(targetHandler, "end_coroutine")
	if result == -1:
		writeOk()
	GLOBAL.currentMode = previousMode
	MasterInput.setMaster(inputer)
	emit_signal("coroutine_signal", result)

func askForContinue(inputer):
	previousMode = GLOBAL.currentMode
	continueHandler.startCoroutine()
	var result = yield(continueHandler, "end_coroutine")
	GLOBAL.currentMode = previousMode
	MasterInput.setMaster(inputer)
	emit_signal("coroutine_signal", result)

func write(text, signet: String = ""):
	if text == null:
		return
	text = '\n' + '<' + String(GeneralEngine.turn) + '> ' + text
	diary.append_bbcode(text)
	diaryContent += text
	Ref.game.autoexplore = false
	if not signet.empty():
		self.lastPrinted = signet

func simpleWrite(text):
	if text == null:
		return
	diary.append_bbcode(text)
	diaryContent += text

func color(text: String, color: String):
	match color:
		"red": return "[color=#c13137]" + text + "[/color]"
		"green": return "[color=#24b537]" + text + "[/color]"
		"yellow": return "[color=#d7b537]" + text + "[/color]"
	return text

func writeOk():
	write("Ok then.")
	self.lastPrinted = "writeOk"

func writeXpGain(xp: int):
	write("You earn " + color(String(xp), "yellow") + " XP.")
	self.lastPrinted = "writeXpGain"

func writeLevelUp(level: int, hp: int, skp: int, feat: int):
	write(color("You reach level " + String(level) + " !", "green"))
	var msg = "You gain " + String(hp) + " HP"
	if feat == 1:
		msg += ", " + String(skp) + " skill point and you can choose a feat."
	else:
		msg += " and " + String(skp) + " skill points."
	write(color(msg, "green"))
	write(color("Press [K] to spend your points.", "green"))
	self.lastPrinted = "writeLevelUp"
	

func writeAssignedKey(key: int, item: String):
	item[0] = item[0].capitalize()
	write(item + " assigned to key " + color(String(key), "yellow") + ".")
	self.lastPrinted = "writeAssignedKey"

func writeNoPotionAssigned():
	write("You don't have any potion assigned.")
	self.lastPrinted = "writeNoPotionAssigned"

func writeWhichPotion(choices: Array):
	var msg = "Quaff which potion?"
	msg += listToChoices(choices)
	write(msg)
	self.lastPrinted = "writeWhichPotion"

func writeNoScrollAssigned():
	write("You don't have any scroll assigned.")
	self.lastPrinted = "writeNoScrollAssigned"

func writeWhichScroll(choices: Array):
	var msg = "Read which scroll?"
	msg += listToChoices(choices)
	write(msg)
	self.lastPrinted = "writeWhichScroll"

func writeNoThrowingAssigned():
	write("You don't have any throwing weapon assigned.")
	self.lastPrinted = "writeNoThrowingAssigned"

func writeWhichThrowing(choices: Array):
	var msg = "Throw what?"
	msg += listToChoices(choices)
	write(msg)
	self.lastPrinted = "writeWhichThrowing"

func writeNoSpellAssigned():
	write("You don't have any spell assigned.")
	self.lastPrinted = "writeNoSpellAssigned"

func writeSpellDirection():
	write("Cast spell in which direction?")
	self.lastPrinted = "writeSpellDirection"

func writeWhichSpell(choices: Array):
	var msg = "Cast which spell?"
	msg += listToChoices(choices)
	write(msg)
	self.lastPrinted = "writeWhichSpell"

func writeCastSpell(spell: String):
	write("You cast " + color(spell, "yellow") + ".")
	self.lastPrinted = "writeCastSpell"

func writeMonsterCastSpell(entityName: String, spell: String):
	write(entityName + " casts " + color(spell, "yellow") + ".")
	self.lastPrinted = "writeMonsterCastSpell"

func writeNoSpell(spell: String):
	write("You cannot cast " + spell + " anymore until you rest.")
	self.lastPrinted = "writeNoSpell"

func writeCharacterSavingThrowSuccess():
	write("You succeed your saving throw.")
	self.lastPrinted = "writeCharacterSavingThrowSuccess"

func writeSavingThrowSuccess(entityName: String):
	write(entityName + " succeed its saving throw.")
	self.lastPrinted = "writeSavingThrowSuccess"

func writeNoGoingBack():
	write("A shadow force blocks the way. There is no going back...")
	self.lastPrinted = "writeNoGoingBack"

func askToChangeFloor():
	write("Do you want to go to the next floor? (Y/n)")
	self.lastPrinted = "askToChangeFloor"

func askToOpenChest():
	write("Do you want to open the chest? (Y/n)")
	self.lastPrinted = "askToOpenChest"

func askToPickChest(dd: int):
	var msg = "The chest is locked. Do you want to pick the lock? (DC "
	msg += String(dd) + ") (Y/n)"
	write(color(msg, "yellow"))
	self.lastPrinted = "askToPickChest"

func askToPickDoor(dd: int):
	var msg = "The door is locked. Do you want to pick the lock? (DC "
	msg += String(dd) + ") (Y/n)"
	write(color(msg, "yellow"))
	self.lastPrinted = "askToPickDoor"

func writeDoorUnlocked():
	write("The door is unlocked.")
	self.lastPrinted = "writeDoorUnlocked"

func writeChestUnlocked():
	write("The chest is unlocked.")
	self.lastPrinted = "writeChestUnlocked"

func writeLockpickSuccess(rolled: int):
	var msg = "You successfully pick the lock ! (rolled "
	msg +=  String(rolled) + ")"
	write(color(msg, "green"))
	self.lastPrinted = "writeLockpickSuccess"

func writeLockpickFailure(rolled: int):
	var msg = "You fail your atempt and the lockpick broke ! (rolled "
	msg +=  String(rolled) + ")"
	write(color(msg, "red"))
	self.lastPrinted = "writeLockpickFailure"

func noLockpicksChest():
	write("The chest is locked and you don't have any lockpicks to pick it.")
	self.lastPrinted = "noLockpicksChest"

func noLockpicksDoor():
	write("The door is locked and you don't have any lockpicks to pick it.")
	self.lastPrinted = "noLockpicksDoor"

func writeNoLockedDoor():
	write("There is no locked door or chest to unlock there.")
	self.lastPrinted = "writeNoLockedDoor"

func writeSearch():
	write("You look for hidden secrets around you...")
	self.lastPrinted = "writeSearch"

func writeHiddenDoorDetected():
	write(color("You detect a hidden door !", "yellow"))
	self.lastPrinted = "writeHiddenDoorDetected"

func writeHiddenTrapDetected(name: String):
	write(color("You detect " + Utils.addArticle(name) + " !", "yellow"))
	self.lastPrinted = "writeHiddenTrapDetected"

func writeNoLoot():
	write("Nothing to pick here.")
	self.lastPrinted = "writeNoLoot"

func writePickupLoot(item: String, count: int):
	write("You pick " + Utils.addArticle(item, count) + ".")
	self.lastPrinted = "writePickupLoot"

func writeBuyLoot(item: String, count: int, price: int):
	write(color("You buy " + Utils.addArticle(item, count) + " for " + String(price) + " golds.", "yellow"))
	self.lastPrinted = "writeBuyLoot"

func writeNoMoney():
	write("You don't have enough golds for that.")
	self.lastPrinted = "writeNoMoney"

func writeAskToBuy(price: int):
	write("Do you want to buy that? (Y/n)")
	self.lastPrinted = "writeAskToBuy"

func writeNoSkp():
	write("You don't have any remaining skill point.")
	self.lastPrinted = "writeNoSkp"

func writeNoMastery():
	write("You don't have enough mastery to improve that skill.")
	self.lastPrinted = "writeNoMastery"

func writeTriggerTrap(name: String):
	write(color("You trigger " + Utils.addArticle(name) + " !", "yellow"))
	self.lastPrinted = "writeTriggerTrap"

func writeCharacterStrike(name: String, hit: int, ca: int):
	var msg = "You strike the " + name
	msg += " (rolled " + String(hit) + " vs " + String(ca) + ")."
	write(color(msg, "yellow"))
	self.lastPrinted = "writeCharacterStrike"

func writeCharacterShoot(name: String, weapon: String):
	var msg = "You shoot " + Utils.addArticle(weapon)
	msg += " at the " + name + "."
	write(color(msg, "yellow"))
	self.lastPrinted = "writeCharacterShoot"

func writeCharacterMiss(name: String, hit: int, ca: int):
	var msg = "You miss the " + name
	msg += " (rolled " + String(hit) + " vs " + String(ca) + ")."
	write(msg)
	self.lastPrinted = "writeCharacterMiss"

func writeDeflectCharacter():
	var msg = "The projectile was deflected by your spell."
	write(msg)
	self.lastPrinted = "writeDeflectCharacter"

func writeCharacterHitImage():
	write("You destroyed an illusion !")
	self.lastPrinted = "writeCharacterHitImage"

func writeCharacterTakeHit(dmg: int):
	write(color("You suffer " + String(dmg) + " damages.", "red"))
	self.lastPrinted = "writeCharacterTakeHit"

func writeCharacterHeal(dmg: int):
	write("You regain " + String(dmg) + " HP.")
	self.lastPrinted = "writeCharacterHeal"

func writeMonsterStrike(name: String, target: String, hit: int, ca: int):
	var msg = "The " + name + " strikes " + target
	msg += " (rolled " + String(hit) + " vs " + String(ca) + ")."
	write(color(msg, "red"))
	self.lastPrinted = "writeMonsterStrike"

func writeMonsterShoot(name: String, target: String, weapon: String):
	var msg = "The " + name + " shoots " + Utils.addArticle(weapon)
	if target == "you":
		msg += " at " + target
	else:
		msg += " at your " + target
	msg += "."
	write(color(msg, "yellow"))
	self.lastPrinted = "writeMonsterShoot"

func writeMonsterMiss(name: String, target: String, hit: int, ca: int):
	var msg = "The " + name + " misses " + target
	msg += " (rolled " + String(hit) + " vs " + String(ca) + ")."
	write(msg)
	self.lastPrinted = "writeMonsterMiss"

func writeDeflectMonster(name: String):
	var msg = "The projectile was deflected by the " + name + "'s spell."
	write(msg)
	self.lastPrinted = "writeDeflectMonster"

func writeMonsterHitImage(name: String):
	var msg = "The " + name + " destroyed an illusion !"
	write(msg)
	self.lastPrinted = "writeMonsterHitImage"

func writeMonsterTakeHit(name: String, dmg: int):
	var msg = "The " + name + " suffers " + String(dmg) + " damages."
	write(color(msg, "yellow"))
	self.lastPrinted = "writeMonsterTakeHit"

func writeMonsterHeal(name: String, dmg: int):
	write("The " + name + " regain " + String(dmg) + " HP.")
	self.lastPrinted = "writeMonsterHeal"

func writeMonsterDie(name: String):
	write(color("The " + name + " dies.", "yellow"))
	self.lastPrinted = "writeMonsterDie"

func writeQuaffedPotion(potion: String):
	write("You quaff the " + potion + ".")
	self.lastPrinted = "writeQuaffedPotion"

func writeMonsterQuaffedPotion(entityName: String, potion: String):
	write(entityName + " quaffes the " + potion + ".")
	self.lastPrinted = "writeMonsterQuaffedPotion"

func writeRemoveSleep():
	write("You are woken up by the attack.")
	self.lastPrinted = "writeRemoveSleep"

func writeMonsterRemoveSleep(entityName: String):
	write(entityName + " is woken up by the attack.")
	self.lastPrinted = "writeMonsterRemoveSleep"

func noTarget():
	write("There is no targets at range for this.")
	self.lastPrinted = "noTarget"

func writeWishChoice():
	var msg = "Ask for what?"
	msg += listToChoices(["Weapon", "Armor", "Scrolls", "Potions", "Gold"])
	write(msg)
	self.lastPrinted = "writeWishChoice"

func writeFreeToAct():
	write("You are free to move again.")
	self.lastPrinted = "writeFreeToAct"

const ST_SLEEP = "sleeping"
const ST_PARALYSIS = "paralyzed"
const ST_TERROR = "terrorized"

func writeCannotAct(status: String):
	var msg = "You are " + status + ", you cannot act."
	write(color(msg, "red"))
	self.lastPrinted = "writeCannotAct"

func writeCannotMove():
	write(color("You are immobilized, you cannot move.", "red"))
	self.lastPrinted = "writeCannotMove"

func writeSancturayBreak():
	write("You broke your sanctuary !")
	self.lastPrinted = "writeSancturayBreak"

func askForRest(rests: int):
	var msg = "You can rest " + String(rests)
	if rests == 1:
		msg += " time."
	else:
		msg += " times."
	msg += " Do you want to rest here? (Y/n)"
	write(msg)
	self.lastPrinted = "askForRest"

func noMoreRest():
	write("You cannot rest anymore.")
	self.lastPrinted = "noMoreRest"

func writeNoSafeRest():
	write("Some hostile creatures lurk in the shadows. You cannot rest here.")
	self.lastPrinted = "writeNoSafeRest"

func writeRested():
	write("You wake up, fully rested.")
	self.lastPrinted = "writeRested"

func writeCannotEquipWeapon():
	write("You don't have enough fighting skill to equip this weapon.")
	self.lastPrinted = "writeCannotEquipWeapon"

func writeWishResult(items: Array):
	var msg = ""
	var list = []
	if items.empty():
		msg = "Nothing"
	else:
		var item = GLOBAL.items[items[0]]
		if item[GLOBAL.IT_TYPE] == GLOBAL.LO_TYPE or item[GLOBAL.IT_TYPE] == GLOBAL.GO_TYPE:
			list.append(Utils.addArticle(item[GLOBAL.IT_NAME], item[GLOBAL.IT_SPEC]))
		else:
			list.append(Utils.addArticle(item[GLOBAL.IT_NAME], items.size()))
	msg += Utils.makeList(list) + " appeared at your feet."
	write(msg)
	self.lastPrinted = "writeWishResult"

func listToChoices(list: Array) -> String:
	var msg = ""
	var count = 0
	for item in list:
		count += 1
		if item != null:
			msg += " [" + Ref.ui.color(String(count), "yellow") + "] "
			msg += item
	return msg

func updateStat(stat: int, value):
	match stat:
		Data.CHAR_NAME:
			nameLabel.text = value[0] + " the " + value[1]
		Data.CHAR_HPMAX:
			hpMaxLabel.text = String(value)
		Data.CHAR_HP:
			hpLabel.text = String(value)
		Data.CHAR_FATIGUE:
			fatigueLabel.text = String(value)
		Data.CHAR_FATIGUEMAX:
			fatigueMaxLabel.text = String(value)
		Data.CHAR_CA:
			caLabel.text = String(value)
		Data.CHAR_PROT:
			protLabel.text = String(value)
		Data.CHAR_DMG:
			dmgLabel.bbcode_text = "[right]"
			dmgLabel.bbcode_text += GeneralEngine.dmgDicesToString(value, true)
			dmgLabel.bbcode_text += "[/right]"
		Data.CHAR_HIT:
			hitLabel.text = value.toString()
		Data.CHAR_LOCK:
			lockLabel.text = String(value)
		Data.CHAR_GOLD:
			goldLabel.text = String(value)
		Data.CHAR_FOOD:
			foodLabel.text = String(value)
		Data.CHAR_LIGHT:
			lightLabel.text = String(value)
		Data.CHAR_AMMO:
			ammoLabel.text = String(value)
		Data.CHAR_LVL:
			levelLabel.text = String(value)
		Data.CHAR_XP:
			xpLabel.text = String(value)
		Data.CHAR_XPMAX:
			maxXpLabel.text = String(value)
		Data.CHAR_R_FIRE:
			rFire.text = ""
			for _i in range(value[1]):
				rFire.text += "-"
			for i in range(value[0]):
				rFire.text[i] = "*"
		Data.CHAR_R_POISON:
			rPois.text = ""
			for _i in range(value[1]):
				rPois.text += "-"
			for i in range(value[0]):
				rPois.text[i] = "*"

func updateLocation(biome: int, currentFloor: int):
	locationLabel.text = "Currently in "
	match biome:
		Data.BIOME_DUNGEON:
			locationLabel.text += "Dungeon "
		Data.BIOME_CAVERN:
			locationLabel.text += "Cavern "
		Data.BIOME_CRYPT:
			locationLabel.text += "Crypt "
		Data.BIOME_MINE:
			locationLabel.text += "Mine "
		Data.BIOME_VOLCANO:
			locationLabel.text += "Volcano "
		Data.BIOME_TROLL_BOSS:
			locationLabel.text += "Encounter "
	locationLabel.text += Utils.toRoman(currentFloor)
