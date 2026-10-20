extends Node

# Player settings, kept in user:// so they survive between runs.
# Fullscreen can be toggled with F11 or Alt+Enter, everything else is in the options menu (Esc).

const PATH = "user://settings.cfg"
const WINDOW_SIZE = Vector2(1280, 720)

var fullscreen: bool = false
var effects: bool = true
var tips: bool = true
# 0 easy, 1 normal, 2 hard: monster health and the number of rests a new character starts with
var difficulty: int = 1
const DIFFICULTY_NAMES = ["Easy", "Normal", "Hard"]
const MONSTER_HP = [0.75, 1.0, 1.35]
const START_RESTS = [3, 2, 1]
var musicVolume: float = 0.4
var sfxVolume: float = 0.8

func _ready():
	loadSettings()
	applyWindow()

func _input(event):
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.scancode == KEY_F12:
		takeScreenshot()
		return
	var isAltEnter = event.alt and (event.scancode == KEY_ENTER or event.scancode == KEY_KP_ENTER)
	if event.scancode == KEY_F11 or isAltEnter:
		get_tree().set_input_as_handled()
		setFullscreen(not fullscreen)

func loadSettings():
	var file = ConfigFile.new()
	if file.load(PATH) != OK:
		return
	fullscreen = bool(file.get_value("display", "fullscreen", fullscreen))
	effects = bool(file.get_value("display", "effects", effects))
	tips = bool(file.get_value("game", "tips", tips))
	difficulty = int(clamp(int(file.get_value("game", "difficulty", difficulty)), 0, 2))
	musicVolume = clamp(float(file.get_value("audio", "music", musicVolume)), 0.0, 1.0)
	sfxVolume = clamp(float(file.get_value("audio", "sfx", sfxVolume)), 0.0, 1.0)

# Tests and bots run with MORIA_NO_SAVE=1 (and the harness fakes dice), so they never write the
# settings or the saves of a real player. Was: a bot that wandered through the options menu saved
# its choices into the real settings file.
func canWrite() -> bool:
	return not OS.has_environment("MORIA_NO_SAVE") and not GeneralEngine.isFaking

func saveSettings():
	if not canWrite():
		return
	var file = ConfigFile.new()
	file.set_value("display", "fullscreen", fullscreen)
	file.set_value("display", "effects", effects)
	file.set_value("game", "tips", tips)
	file.set_value("game", "difficulty", difficulty)
	file.set_value("audio", "music", musicVolume)
	file.set_value("audio", "sfx", sfxVolume)
	file.save(PATH)

func setFullscreen(value: bool):
	fullscreen = value
	applyWindow()
	saveSettings()

func setEffects(value: bool):
	effects = value
	saveSettings()

func setTips(value: bool):
	tips = value
	saveSettings()

func setDifficulty(value: int):
	difficulty = int(posmod(value, 3))
	saveSettings()

func monsterHpFactor() -> float:
	return MONSTER_HP[difficulty]

func startRests() -> int:
	return START_RESTS[difficulty]

func setMusicVolume(value: float):
	musicVolume = clamp(value, 0.0, 1.0)
	Sfx.applyVolumes()
	saveSettings()

func setSfxVolume(value: float):
	sfxVolume = clamp(value, 0.0, 1.0)
	Sfx.applyVolumes()
	saveSettings()

# The game draws at 1920x1080 and the stretch mode scales it, so a window of any size works
func applyWindow():
	OS.window_fullscreen = fullscreen
	if fullscreen:
		return
	OS.window_borderless = false
	OS.window_resizable = true
	var screen = OS.get_screen_size()
	var factor = min(1.0, min(screen.x * 0.9 / WINDOW_SIZE.x, screen.y * 0.85 / WINDOW_SIZE.y))
	OS.window_size = WINDOW_SIZE * factor
	OS.center_window()

# F12 saves what is on the screen as a PNG in the user folder
func screenshotPath() -> String:
	var d = OS.get_datetime()
	return "user://screenshots/moria_%04d%02d%02d_%02d%02d%02d.png" % [d["year"], d["month"], d["day"], d["hour"], d["minute"], d["second"]]

func takeScreenshot():
	var image = get_viewport().get_texture().get_data()
	image.flip_y()
	Directory.new().make_dir_recursive("user://screenshots")
	var path = screenshotPath()
	if image.save_png(path) != OK:
		return
	var message = "Screenshot saved: " + ProjectSettings.globalize_path(path)
	if is_instance_valid(Ref.game) and Ref.ui != null:
		Ref.ui.write(message)
	print(message)
