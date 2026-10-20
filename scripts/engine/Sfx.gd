extends Node

# Sound effects and music, all made with the SID model in tools/sidsynth.py.
# Sound effects play for the events the game already announces in the diary (the write* names
# in UI.gd), music follows the biome. Volumes come from Settings through two audio buses.

const EVENTS = {
	"writeCharacterStrike": "sword_hit",
	"writeCharacterMiss": "swing_miss",
	"writeMonsterMiss": "swing_miss",
	"writeCharacterTakeHit": "player_hurt",
	"writeMonsterStrike": "player_hurt",
	"writeMonsterTakeHit": "monster_hurt",
	"writeMonsterDie": "monster_death",
	"writePickupLoot": "pickup",
	"writeDoorUnlocked": "unlock",
	"writeChestUnlocked": "unlock",
	"writeLockpickSuccess": "unlock",
	"writeLockpickFailure": "lockpick_fail",
	"writeTriggerTrap": "trap",
	"writeHiddenDoorDetected": "discover",
	"writeHiddenTrapDetected": "discover",
	"writeCastSpell": "spell_cast",
	"writeMonsterCastSpell": "spell_cast",
	"writeQuaffedPotion": "quaff",
	"writeCharacterHeal": "heal",
	"writeLevelUp": "level_up",
	"writeCharacterShoot": "throw",
	"writeMonsterShoot": "throw",
}

# Played directly, they have no diary line
const DIRECT = ["door_open", "chest_open", "player_death", "descend", "ui_move", "ui_accept", "ui_back", "low_hp", "bump"]

const MUSIC = ["dungeon", "cavern", "boss", "crypt", "mine", "volcano"]

const VOICES = 6
const MIN_GAP_MS = 70          # the same sound is not retriggered faster than this
const FADE = 1.2
const SFX_FOLDER = "res://sounds/sfx/"
const MUSIC_FOLDER = "res://sounds/music/"
# The built-in SID tracks, used when there is no file of that name in the folder above
const MUSIC_FALLBACK_FOLDER = "res://sounds/music/sid/"
# Players can drop their own tracks here without rebuilding the game, see sounds/music/README.md
const USER_MUSIC_FOLDER = "user://music/"
const MUSIC_FORMATS = ["ogg", "mp3"]
const MAX_VARIANTS = 9

var cache = {}
var voices = []
var nextVoice = 0
var lastPlayed = {}
var musicPlayers = []
var nextMusic = 0
var currentMusic = ""
var tween: Tween

func _ready():
	for busName in ["Music", "SFX"]:
		if AudioServer.get_bus_index(busName) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, busName)
	for _i in range(VOICES):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		voices.append(player)
	for _i in range(2):
		var player = AudioStreamPlayer.new()
		player.bus = "Music"
		add_child(player)
		musicPlayers.append(player)
	tween = Tween.new()
	add_child(tween)
	applyVolumes()

func applyVolumes():
	setBus("Music", Settings.musicVolume)
	setBus("SFX", Settings.sfxVolume)

func setBus(busName: String, volume: float):
	var idx = AudioServer.get_bus_index(busName)
	AudioServer.set_bus_mute(idx, volume <= 0.0)
	AudioServer.set_bus_volume_db(idx, linear2db(max(volume, 0.0001)))

func playEvent(event: String):
	if EVENTS.has(event):
		play(EVENTS[event])

func play(sound: String):
	# The test harness fakes dice and drives the game headless, keep it silent
	if GeneralEngine.isFaking:
		return
	var now = OS.get_ticks_msec()
	if lastPlayed.has(sound) and now - lastPlayed[sound] < MIN_GAP_MS:
		return
	var stream = getStream(SFX_FOLDER, sound)
	if stream == null:
		return
	lastPlayed[sound] = now
	var player = voices[nextVoice]
	nextVoice = (nextVoice + 1) % VOICES
	player.stream = stream
	player.play()

func playMusic(track: String):
	if GeneralEngine.isFaking or track == currentMusic:
		return
	var stream = getMusicStream(track)
	if stream == null:
		return
	stream.loop = true
	currentMusic = track
	var incoming = musicPlayers[nextMusic]
	nextMusic = (nextMusic + 1) % 2
	var outgoing = musicPlayers[nextMusic]
	incoming.stream = stream
	incoming.volume_db = -60.0
	incoming.play()
	tween.remove_all()
	tween.interpolate_property(incoming, "volume_db", incoming.volume_db, 0.0, FADE)
	tween.interpolate_property(outgoing, "volume_db", outgoing.volume_db, -60.0, FADE)
	tween.start()
	yield(get_tree().create_timer(FADE + 0.1), "timeout")
	if currentMusic == track:
		outgoing.stop()

func stopMusic():
	currentMusic = ""
	for player in musicPlayers:
		tween.interpolate_property(player, "volume_db", player.volume_db, -60.0, FADE)
	tween.start()

func playMusicForBiome(biome: int):
	match biome:
		Data.BIOME_CAVERN:
			playMusic("cavern")
		Data.BIOME_TROLL_BOSS:
			playMusic("boss")
		Data.BIOME_CRYPT:
			playMusic("crypt")
		Data.BIOME_MINE:
			playMusic("mine")
		Data.BIOME_VOLCANO:
			playMusic("volcano")
		_:
			playMusic("dungeon")

func getStream(folder: String, sound: String):
	var key = folder + sound
	if not cache.has(key):
		var path = folder + sound + ".ogg"
		cache[key] = load(path) if ResourceLoader.exists(path) else null
		# Godot imports OGG files with looping ON. Was missing: every sound effect repeated
		# forever once it played, whatever the import settings say
		if cache[key] != null and folder == SFX_FOLDER:
			cache[key].loop = false
	return cache[key]

# A track is "dungeon", "cavern" or "boss". The file can be dungeon.ogg or dungeon.mp3, and extra
# versions dungeon_2.ogg ... dungeon_9.ogg are picked at random, a new one on each floor.
# Tracks in user://music win over the ones shipped in res://sounds/music.
func getMusicStream(track: String):
	var found = userMusicFiles(track)
	for folder in [MUSIC_FOLDER, MUSIC_FALLBACK_FOLDER]:
		if not found.empty():
			break
		for variant in musicVariants(track):
			for format in MUSIC_FORMATS:
				var path = folder + variant + "." + format
				if ResourceLoader.exists(path):
					found.append(path)
	if found.empty():
		return null
	var path = found[randi() % found.size()]
	if path.begins_with("user://"):
		return loadUserStream(path)
	if not cache.has(path):
		cache[path] = load(path)
	return cache[path]

func musicVariants(track: String) -> Array:
	var names = [track]
	for i in range(2, MAX_VARIANTS + 1):
		names.append(track + "_" + str(i))
	return names

func userMusicFiles(track: String) -> Array:
	var result = []
	var file = File.new()
	for variant in musicVariants(track):
		for format in MUSIC_FORMATS:
			var path = USER_MUSIC_FOLDER + variant + "." + format
			if file.file_exists(path):
				result.append(path)
	return result

func loadUserStream(path: String):
	var file = File.new()
	if file.open(path, File.READ) != OK:
		return null
	var bytes = file.get_buffer(file.get_len())
	file.close()
	var stream
	if path.ends_with(".mp3"):
		stream = AudioStreamMP3.new()
	else:
		stream = AudioStreamOGGVorbis.new()
	stream.data = bytes
	return stream
