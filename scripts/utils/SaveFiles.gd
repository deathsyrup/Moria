extends Reference
class_name SaveFiles

# Finds the saved games, newest first. Older versions saved next to the project (res://usr/).

const FOLDERS = ["user://saves/", "res://usr/"]

static func list() -> Array:
	var result = []
	var seen = {}
	var dir = Directory.new()
	var file = File.new()
	for folder in FOLDERS:
		if dir.open(folder) != OK:
			continue
		dir.list_dir_begin(true, true)
		var fileName = dir.get_next()
		while fileName != "":
			if fileName.ends_with(".sav") and not seen.has(fileName):
				seen[fileName] = true
				result.append({"name": fileName.get_basename(), "modified": file.get_modified_time(folder + fileName)})
			fileName = dir.get_next()
		dir.list_dir_end()
	# Newest first. A plain insertion sort: sort_custom needs the class to name itself, which Godot forbids
	for i in range(1, result.size()):
		var item = result[i]
		var j = i - 1
		while j >= 0 and result[j]["modified"] < item["modified"]:
			result[j + 1] = result[j]
			j -= 1
		result[j + 1] = item
	return result

static func dateText(unix: int) -> String:
	var d = OS.get_datetime_from_unix_time(unix)
	return "%04d-%02d-%02d %02d:%02d" % [d["year"], d["month"], d["day"], d["hour"], d["minute"]]
