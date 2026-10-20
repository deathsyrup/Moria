extends Node

# What carries over between runs: the tips already shown, a few totals, and the starting bonuses they
# unlock. Kept in user://progress.json next to the settings.

const PATH = "user://progress.json"

# Each unlock is earned once a total reaches `need`, and then helps every new character
const UNLOCKS = [
	{"id": "coin", "name": "Lucky coin", "text": "start with 40 more gold", "stat": "best_floor", "need": 3, "why": "reach floor 3"},
	{"id": "picks", "name": "Lockpick set", "text": "start with 3 more lockpicks", "stat": "chests", "need": 8, "why": "open 8 chests"},
	{"id": "potion", "name": "Healer's kit", "text": "start with a potion of healing", "stat": "kills", "need": 50, "why": "slay 50 monsters"},
	{"id": "rest", "name": "Veteran's pack", "text": "start with 1 more rest", "stat": "best_floor", "need": 10, "why": "reach floor 10"},
]

var data = {"tips": [], "stats": {}, "unlocked": []}

func _ready():
	loadProgress()

func loadProgress():
	var file = File.new()
	if not file.file_exists(PATH) or file.open(PATH, File.READ) != OK:
		return
	var parsed = JSON.parse(file.get_as_text())
	file.close()
	if parsed.error == OK and parsed.result is Dictionary:
		for key in data.keys():
			if parsed.result.has(key):
				data[key] = parsed.result[key]

func saveProgress():
	if not Settings.canWrite():
		return
	var file = File.new()
	if file.open(PATH, File.WRITE) == OK:
		file.store_string(to_json(data))
		file.close()

func stat(name: String) -> int:
	return int(data["stats"].get(name, 0))

func add(name: String, amount: int = 1):
	data["stats"][name] = stat(name) + amount
	checkUnlocks()
	saveProgress()

func best(name: String, value: int):
	if value > stat(name):
		data["stats"][name] = value
		checkUnlocks()
		saveProgress()

func isUnlocked(id: String) -> bool:
	return data["unlocked"].has(id)

func checkUnlocks():
	for unlock in UNLOCKS:
		if not isUnlocked(unlock["id"]) and stat(unlock["stat"]) >= unlock["need"]:
			data["unlocked"].append(unlock["id"])
			if is_instance_valid(Ref.game) and Ref.ui != null and not GeneralEngine.isFaking:
				Ref.ui.write(Ref.ui.color("Unlocked: " + unlock["name"] + " (" + unlock["text"] + " in every new run).", "yellow"))

# Tips are shown once, ever
func hasSeen(tip: String) -> bool:
	return data["tips"].has(tip)

func markSeen(tip: String):
	if not hasSeen(tip):
		data["tips"].append(tip)
		saveProgress()

# The starting bonuses of the unlocks, for a character that has just been created
func applyToNewCharacter():
	if isUnlocked("coin"):
		Ref.character.inventory.golds += 40
	if isUnlocked("picks"):
		Ref.character.inventory.lockpicks += 3
	if isUnlocked("rest"):
		Ref.character.inventory.rests += 1
	if isUnlocked("potion"):
		Ref.character.pickItem(Ref.game.itemGenerator.getPotion(Data.PO_HEALING))
	add("runs")

func summaryLines() -> Array:
	var lines = ["Runs: " + str(stat("runs")) + "    Best floor: " + str(stat("best_floor")) + "    Monsters slain: " + str(stat("kills")) + "    Chests opened: " + str(stat("chests")), ""]
	for unlock in UNLOCKS:
		var state = "unlocked" if isUnlocked(unlock["id"]) else str(min(stat(unlock["stat"]), unlock["need"])) + "/" + str(unlock["need"])
		lines.append(unlock["name"] + ": " + unlock["text"] + "   (" + unlock["why"] + ")   " + state)
	lines.append("")
	return lines
