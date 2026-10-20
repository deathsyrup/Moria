extends Reference
class_name Tips

# One-time hints for new players, shown in the log the first time something comes up.
# Switched off by Options > Tips. Never shown in the test harness.

static func shouldShow(id: String) -> bool:
	return Settings.tips and not Progress.hasSeen(id)

static func show(id: String, text: String):
	if GeneralEngine.isFaking or not shouldShow(id) or not is_instance_valid(Ref.game):
		return
	Progress.markSeen(id)
	Ref.ui.write(Ref.ui.color("Tip: " + text, "green"))
