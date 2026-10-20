extends Reference
class_name Morgue

# The record of finished runs, shown by "Morgue" on the title screen. One entry per death.

const PATH = "user://morgue.json"
const MAX_ENTRIES = 200

# Newest first
static func entries() -> Array:
	var file = File.new()
	if not file.file_exists(PATH) or file.open(PATH, File.READ) != OK:
		return []
	var parsed = JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK or not parsed.result is Array:
		return []
	var result = parsed.result.duplicate()
	result.invert()
	return result

static func record(entry: Dictionary):
	if not Settings.canWrite():
		return
	var all = entries()
	all.invert()
	all.append(entry)
	if all.size() > MAX_ENTRIES:
		all = all.slice(all.size() - MAX_ENTRIES, all.size() - 1)
	var file = File.new()
	if file.open(PATH, File.WRITE) == OK:
		file.store_string(to_json(all))
		file.close()

static func line(entry: Dictionary) -> String:
	var text = str(entry.get("name", "?"))
	if entry.get("class", "") != "":
		text += " the " + entry["class"]
	text += "   floor " + str(entry.get("floor", 1)) + ", level " + str(entry.get("level", 1))
	text += "   " + str(entry.get("kills", 0)) + " slain"
	text += "   killed by " + str(entry.get("killer", "something"))
	text += "   " + str(entry.get("date", ""))
	if entry.has("seed"):
		text += "   seed " + str(entry["seed"])
	return text
