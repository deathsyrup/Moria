extends Node2D

# The title screen menu: New game, Load game, Options, Morgue, Manual, Exit.
# Was a script embedded in the scene where only New game, Load game and Exit did anything.

onready var labels = get_node("Background/Title/Menu/Labels").get_children()
onready var cursor = get_node("Background/Title/Menu/Cursor")
onready var animator = get_node("Animator")

const NEW_GAME = 0
const LOAD_GAME = 1
const OPTIONS = 2
const MORGUE = 3
const MANUAL = 4
const EXIT = 5

var choice = 0
var optionsMenu = preload("res://scripts/menu/OptionsMenu.gd").new()
var listScreen = preload("res://scripts/menu/ListScreen.gd").new()
var textScreen = preload("res://scripts/menu/TextScreen.gd").new()
var messageLabel: Label
var font: DynamicFont

func _ready():
	add_child(optionsMenu)
	add_child(listScreen)
	add_child(textScreen)
	messageLabel = Label.new()
	font = preload("res://fonts/normalFont.tres").duplicate()
	font.size = 36
	messageLabel.add_font_override("font", font)
	messageLabel.rect_position = Vector2(0, 980)
	messageLabel.rect_size = Vector2(1920, 60)
	messageLabel.align = Label.ALIGN_CENTER
	messageLabel.modulate = Color(1, 0.85, 0.3, 0)
	add_child(messageLabel)
	# With a saved game the cursor starts on Load game, and C continues the newest one at once
	var saves = SaveFiles.list()
	setChoice(LOAD_GAME if not saves.empty() else NEW_GAME)
	if not saves.empty():
		var hint = Label.new()
		hint.add_font_override("font", font)
		hint.text = "C: continue " + saves[0]["name"]
		hint.rect_position = Vector2(0, 1030)
		hint.rect_size = Vector2(1920, 40)
		hint.align = Label.ALIGN_CENTER
		hint.modulate = Color(1, 1, 1, 0.6)
		add_child(hint)
	Sfx.playMusic("dungeon")
	if GLOBAL.titleMessage != "":
		showMessage(GLOBAL.titleMessage)
		GLOBAL.titleMessage = ""
	set_process_input(true)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.scancode == KEY_C:
		var saves = SaveFiles.list()
		if not saves.empty():
			startLoading(saves[0]["name"])
		return
	if event.is_action_released("ui_down"):
		Sfx.play("ui_move")
		setChoice(choice + 1)
	elif event.is_action_released("ui_up"):
		Sfx.play("ui_move")
		setChoice(choice - 1)
	elif event.is_action_released("ui_accept"):
		validateChoice()

func setChoice(newChoice: int):
	newChoice = Utils.modulo(newChoice, labels.size())
	labels[choice].remove_color_override("font_color")
	choice = newChoice
	labels[choice].add_color_override("font_color", Colors.yellow)
	cursor.position.y = choice * 36

func validateChoice():
	match choice:
		NEW_GAME:
			Sfx.play("ui_accept")
			enterDoor()
		LOAD_GAME:
			Sfx.play("ui_accept")
			loadGame()
		OPTIONS:
			Sfx.play("ui_accept")
			optionsMenu.openFromTitle(self)
		MORGUE:
			Sfx.play("ui_accept")
			showMorgue()
		MANUAL:
			Sfx.play("ui_accept")
			showManual()
		EXIT:
			# Was get_tree().notification(NOTIFICATION_WM_QUIT_REQUEST), which does not quit the game
			get_tree().quit()

func enterDoor():
	set_process_input(false)
	animator.play("EnterDoor")

func loadGame():
	var saves = SaveFiles.list()
	if saves.empty():
		showMessage("There is no saved game yet.")
		return
	if saves.size() == 1:
		startLoading(saves[0]["name"])
		return
	var lines = []
	for save in saves:
		lines.append(save["name"] + "     " + SaveFiles.dateText(save["modified"]))
	listScreen.connect("closed", self, "onSavePicked", [saves], CONNECT_ONESHOT)
	listScreen.open("LOAD GAME", lines, true, "Up / Down: choose      Enter: load      Esc: back", self)

func onSavePicked(index: int, saves: Array):
	if index >= 0:
		startLoading(saves[index]["name"])

func startLoading(saveName: String):
	GLOBAL.loadName = saveName
	enterDoor()

func showMorgue():
	var lines = Progress.summaryLines()
	var any = false
	for entry in Morgue.entries():
		lines.append(Morgue.line(entry))
		any = true
	if not any:
		lines.append("Nobody has died yet.")
	listScreen.open("THE MORGUE", lines, false, "Up / Down: scroll      Esc: back", self)

func showManual():
	var text = ""
	var file = File.new()
	if file.open("res://MANUAL.md", File.READ) == OK:
		text = TextScreen.markdownToBbcode(file.get_as_text())
		file.close()
	else:
		text = "The manual file (MANUAL.md) is not part of this build.\nPress H in the game for the controls."
	textScreen.open(text, self)

func showMessage(text: String):
	messageLabel.text = text
	messageLabel.modulate.a = 1.0
	var tween = Tween.new()
	messageLabel.add_child(tween)
	tween.interpolate_property(messageLabel, "modulate:a", 1.0, 0.0, 0.6, Tween.TRANS_LINEAR, Tween.EASE_IN, 2.0)
	tween.start()

func _on_Animator_animation_finished(anim_name):
	match choice:
		NEW_GAME:
			GLOBAL.startingMode = 0
			get_tree().change_scene("res://scenes/Game.tscn")
		LOAD_GAME:
			GLOBAL.startingMode = 7
			get_tree().change_scene("res://scenes/Game.tscn")
