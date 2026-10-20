extends CanvasLayer

# Controls reference, opened with H (or from the options menu). The keys are read from the
# input map, so it always shows what the game really uses.

const ROWS = [
	["Move / attack", ["ui_up", "ui_down", "ui_left", "ui_right"]],
	["Walk to a spot", "Left click a visible cell"],
	["Search for secrets", "search"],
	["Pick up loot", "pickLoot"],
	["Inventory", "inventory"],
	["Character sheet", "characterMenu"],
	["Spell list", "spellMenu"],
	["Cast a spell", "castSpell"],
	["Drink a potion", "quaffPotion"],
	["Read a scroll", "readScroll"],
	["Throw something", "throw"],
	["Fire sling or bow", "fire"],
	["Drop an item", "dropItem"],
	["Rest", "rest"],
	["Auto-explore", "autoexplore"],
	["Quick use slots", ["shortcut1", "shortcut0"]],
	["Give an item a slot", "assignShortcut"],
	["Save / load", ["save", "load"]],
	["Options menu", "ui_cancel"],
	["Fullscreen", "F11 or Alt+Enter"],
	["Map of the floor", "overview"],
	["Message history", "history"],
	["This help", "help"],
	["Gamepad", "D-pad or stick move, A ok, B or Start back / menu"],
	["", "X pick up, Y inventory, LB sheet, RB search, Select map"],
]

var font: DynamicFont
var isOpen = false

func _ready():
	font = preload("res://fonts/normalFont.tres").duplicate()
	font.size = 28
	layer = 100
	set_process_input(false)
	visible = false
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	add_child(dim)
	var center = CenterContainer.new()
	center.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	add_child(center)
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08)
	style.border_color = Color(1, 1, 1)
	style.set_border_width_all(3)
	for margin in [MARGIN_LEFT, MARGIN_RIGHT, MARGIN_TOP, MARGIN_BOTTOM]:
		style.set_default_margin(margin, 32)
	panel.add_stylebox_override("panel", style)
	center.add_child(panel)
	var box = VBoxContainer.new()
	box.add_constant_override("separation", 6)
	panel.add_child(box)
	box.add_child(label("CONTROLS", Color(1, 0.85, 0.3), Label.ALIGN_CENTER))
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_constant_override("hseparation", 60)
	grid.add_constant_override("vseparation", 2)
	box.add_child(grid)
	for row in ROWS:
		grid.add_child(label(row[0], Color(1, 1, 1)))
		grid.add_child(label(keysFor(row[1]), Color(0.6, 0.9, 1)))
	box.add_child(label("Press Enter or Esc to close", Color(1, 1, 1, 0.6), Label.ALIGN_CENTER))

func label(text: String, color: Color, align = Label.ALIGN_LEFT) -> Label:
	var l = Label.new()
	l.add_font_override("font", font)
	l.text = text
	l.modulate = color
	l.align = align
	return l

# Names of the keys bound to an action, or a plain text when the entry is not an action
func keysFor(entry) -> String:
	if entry is Array:
		if entry[0] == "ui_up":
			return "Arrow keys"
		return keyName(entry[0]) + " - " + keyName(entry[1]) if entry[0].begins_with("shortcut") else keyName(entry[0]) + " / " + keyName(entry[1])
	if InputMap.has_action(entry):
		return keyName(entry)
	return entry

func keyName(action: String) -> String:
	for e in InputMap.get_action_list(action):
		if e is InputEventKey:
			var code = e.scancode if e.scancode != 0 else e.physical_scancode
			return OS.get_scancode_string(code)
	return "?"

func open():
	isOpen = true
	visible = true
	GLOBAL.currentMode = GLOBAL.MODE_HELP
	MasterInput.setMaster(self)

func close():
	isOpen = false
	visible = false
	GLOBAL.currentMode = GLOBAL.MODE_NORMAL
	MasterInput.setMaster(Ref.game)

func _input(event):
	if event.is_action_released("ui_cancel") or event.is_action_released("ui_accept") or event.is_action_released("help"):
		Sfx.play("ui_back")
		close()
	get_tree().set_input_as_handled()
