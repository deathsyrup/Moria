extends CanvasLayer

# Options menu. In the game it is the pause menu (Esc while exploring), on the title screen it only
# has the settings. It builds its own controls, so there is no scene file. Up and Down choose,
# Left and Right change a value, Enter activates, Esc closes.

const GAME_ITEMS = [["resume", "Resume"], ["fullscreen", "Fullscreen"], ["music", "Music volume"],
	["sfx", "Sound effects"], ["effects", "Screen effects"], ["controls", "Controls"], ["save", "Save game"],
	["quit", "Quit to title"]]
const TITLE_ITEMS = [["back", "Back"], ["fullscreen", "Fullscreen"], ["music", "Music volume"],
	["sfx", "Sound effects"], ["effects", "Screen effects"], ["difficulty", "Difficulty"], ["tips", "Tips"]]
const STEP = 0.1

signal closed

# Bigger than the in-game text, the menu is read at a glance
var font: DynamicFont
var box: VBoxContainer
var rows = []
var items = []
var hint: Label
var index = 0
var isOpen = false
var fromTitle = false
var message = ""
var confirmQuit = false

func _ready():
	font = preload("res://fonts/normalFont.tres").duplicate()
	font.size = 34
	layer = 100
	set_process_input(false)
	visible = false
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
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
		style.set_default_margin(margin, 36)
	panel.add_stylebox_override("panel", style)
	center.add_child(panel)
	box = VBoxContainer.new()
	box.add_constant_override("separation", 14)
	panel.add_child(box)
	var title = makeLabel("OPTIONS")
	title.align = Label.ALIGN_CENTER
	box.add_child(title)
	hint = makeLabel("")
	hint.modulate = Color(1, 1, 1, 0.6)
	hint.align = Label.ALIGN_CENTER

func makeLabel(text: String) -> Label:
	var label = Label.new()
	label.add_font_override("font", font)
	label.text = text
	return label

func build(newItems: Array):
	items = newItems
	for row in rows:
		box.remove_child(row)
		row.queue_free()
	rows = []
	if hint.get_parent() != null:
		box.remove_child(hint)
	for _i in range(items.size()):
		var row = makeLabel("")
		row.rect_min_size = Vector2(780, 0)
		box.add_child(row)
		rows.append(row)
	box.add_child(hint)

func open():
	fromTitle = false
	start(GAME_ITEMS)
	GLOBAL.currentMode = GLOBAL.MODE_OPTIONS
	MasterInput.setMaster(self)

# The title screen has its own input handling, it is paused while this is open
func openFromTitle(title):
	fromTitle = true
	title.set_process_input(false)
	connect("closed", title, "set_process_input", [true], CONNECT_ONESHOT)
	start(TITLE_ITEMS)
	set_process_input(true)

func start(newItems: Array):
	index = 0
	message = ""
	confirmQuit = false
	isOpen = true
	visible = true
	build(newItems)
	refresh()

func close():
	isOpen = false
	visible = false
	set_process_input(false)
	if fromTitle:
		emit_signal("closed")
		return
	GLOBAL.currentMode = GLOBAL.MODE_NORMAL
	MasterInput.setMaster(Ref.game)

func _input(event):
	if event.is_action_pressed("ui_up"):
		move(-1)
	elif event.is_action_pressed("ui_down"):
		move(1)
	elif event.is_action_pressed("ui_left"):
		change(-1)
	elif event.is_action_pressed("ui_right"):
		change(1)
	elif event.is_action_released("ui_accept"):
		activate()
	elif event.is_action_released("ui_cancel"):
		Sfx.play("ui_back")
		close()
	get_tree().set_input_as_handled()

func current() -> String:
	return items[index][0]

func move(direction: int):
	index = posmod(index + direction, items.size())
	message = ""
	confirmQuit = false
	Sfx.play("ui_move")
	refresh()

func change(direction: int):
	match current():
		"fullscreen":
			Settings.setFullscreen(not Settings.fullscreen)
		"music":
			Settings.setMusicVolume(stepVolume(Settings.musicVolume, direction))
		"sfx":
			Settings.setSfxVolume(stepVolume(Settings.sfxVolume, direction))
			Sfx.play("pickup")
		"effects":
			Settings.setEffects(not Settings.effects)
		"difficulty":
			Settings.setDifficulty(Settings.difficulty + direction)
		"tips":
			Settings.setTips(not Settings.tips)
		_:
			return
	refresh()

func activate():
	match current():
		"resume", "back":
			Sfx.play("ui_back")
			close()
		"controls":
			Sfx.play("ui_accept")
			close()
			Ref.game.helpMenu.open()
		"save":
			Sfx.play("ui_accept")
			Ref.game.saveSystem.saveGame()
			message = "Game saved."
			refresh()
		"quit":
			# One slip of the finger must not lose the game
			if not confirmQuit:
				confirmQuit = true
				message = "Press Enter again to quit to the title screen. The game is saved."
				Sfx.play("ui_move")
				refresh()
				return
			Sfx.play("ui_accept")
			Ref.game.saveSystem.saveGame()
			Fx.clearWarning()
			close()
			get_tree().change_scene("res://scenes/UI/TitleScreen.tscn")
		_:
			Sfx.play("ui_accept")
			change(1)

func stepVolume(value: float, direction: int) -> float:
	return stepify(clamp(value + direction * STEP, 0.0, 1.0), STEP)

func refresh():
	for i in range(items.size()):
		var text = items[i][1]
		match items[i][0]:
			"fullscreen":
				text += ":  " + ("On" if Settings.fullscreen else "Off (windowed)")
			"music":
				text += ":  " + volumeBar(Settings.musicVolume)
			"sfx":
				text += ":  " + volumeBar(Settings.sfxVolume)
			"effects":
				text += ":  " + ("On (numbers, flash, shake)" if Settings.effects else "Off")
			"difficulty":
				text += ":  " + Settings.DIFFICULTY_NAMES[Settings.difficulty] + ["  (monsters 25% weaker, 3 rests)", "", "  (monsters 35% tougher, 1 rest)"][Settings.difficulty]
			"tips":
				text += ":  " + ("On (one-time hints in the log)" if Settings.tips else "Off")
		rows[i].text = ("> " if i == index else "  ") + text
		rows[i].modulate = Color(1, 0.85, 0.3) if i == index else Color(1, 1, 1)
	var seedText = "" if fromTitle or not is_instance_valid(Ref.game) else "     Seed " + str(Ref.game.runSeed)
	hint.text = message if message != "" else "F11 or Alt+Enter: fullscreen" + seedText

func volumeBar(value: float) -> String:
	var filled = int(round(value * 10.0))
	return "[" + "#".repeat(filled) + "-".repeat(10 - filled) + "] " + String(int(round(value * 100.0))) + "%"
