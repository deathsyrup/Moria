extends CanvasLayer

# Small visual feedback so fights feel like something: floating damage numbers, a white flash on
# the sprite that was hit, a short screen shake and a red flash when the player is hurt.
# All of it can be switched off in the options menu (Settings.effects).

const RISE = 70.0
const LIFETIME = 0.8

var font: DynamicFont
var flashRect: ColorRect
var tween: Tween
var shaking = false
var strengthNow = 1.0
var lowHealth = false
var warnBars = []
var warnLabel: Label
var warnTime = 0.0
var blackRect: ColorRect
var cardBox: VBoxContainer
var cardFloor: Label
var cardArea: Label
var cardSummary: Label
var tipPanel: PanelContainer
var tipLabel: Label
var transitioning = false
var transitionToken = 0

func _ready():
	layer = 60
	font = preload("res://fonts/normalFont.tres").duplicate()
	font.size = 36
	font.outline_size = 3
	font.outline_color = Color(0, 0, 0)
	flashRect = ColorRect.new()
	flashRect.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	flashRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flashRect.color = Color(0.8, 0.05, 0.05, 0.0)
	add_child(flashRect)
	tween = Tween.new()
	add_child(tween)
	# A calm pulsing red frame and a short label while health is low
	for anchor in [[0, 0, 1, 0, 0, 14], [0, 1, 1, 1, -14, 0], [0, 0, 0, 1, 0, 14], [1, 0, 1, 1, -14, 0]]:
		var bar = ColorRect.new()
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.color = Color(0.85, 0.1, 0.1, 0.0)
		bar.anchor_left = anchor[0]
		bar.anchor_top = anchor[1]
		bar.anchor_right = anchor[2]
		bar.anchor_bottom = anchor[3]
		if anchor[1] == anchor[3]:
			bar.margin_top = anchor[4]
			bar.margin_bottom = anchor[5]
		else:
			bar.margin_left = anchor[4]
			bar.margin_right = anchor[5]
		add_child(bar)
		warnBars.append(bar)
	warnLabel = Label.new()
	warnLabel.add_font_override("font", font)
	warnLabel.text = "LOW HEALTH"
	warnLabel.modulate = Color(1, 0.35, 0.35, 0.0)
	warnLabel.anchor_left = 0.5
	warnLabel.anchor_right = 0.5
	warnLabel.margin_left = -120
	warnLabel.margin_right = 120
	warnLabel.margin_top = 12
	warnLabel.align = Label.ALIGN_CENTER
	add_child(warnLabel)
	# Level transitions: a black cover and a title card, above the map and below the menus
	blackRect = ColorRect.new()
	blackRect.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	blackRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blackRect.color = Color(0, 0, 0, 0)
	add_child(blackRect)
	cardBox = VBoxContainer.new()
	cardBox.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	cardBox.alignment = BoxContainer.ALIGN_CENTER
	cardBox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cardBox.modulate = Color(1, 1, 1, 0)
	add_child(cardBox)
	cardFloor = Label.new()
	var bigFont = font.duplicate()
	bigFont.size = 96
	cardFloor.add_font_override("font", bigFont)
	cardFloor.align = Label.ALIGN_CENTER
	cardBox.add_child(cardFloor)
	cardArea = Label.new()
	var midFont = font.duplicate()
	midFont.size = 46
	cardArea.add_font_override("font", midFont)
	cardArea.align = Label.ALIGN_CENTER
	cardBox.add_child(cardArea)
	cardSummary = Label.new()
	var smallFont = font.duplicate()
	smallFont.size = 30
	cardSummary.add_font_override("font", smallFont)
	cardSummary.align = Label.ALIGN_CENTER
	cardBox.add_child(cardSummary)
	tipPanel = PanelContainer.new()
	var tipStyle = StyleBoxFlat.new()
	tipStyle.bg_color = Color(0.04, 0.04, 0.07, 0.92)
	tipStyle.border_color = Color(1, 1, 1, 0.7)
	tipStyle.set_border_width_all(2)
	for margin in [MARGIN_LEFT, MARGIN_RIGHT, MARGIN_TOP, MARGIN_BOTTOM]:
		tipStyle.set_default_margin(margin, 8)
	tipPanel.add_stylebox_override("panel", tipStyle)
	tipPanel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tipPanel.visible = false
	tipLabel = Label.new()
	var tipFont = font.duplicate()
	tipFont.size = 28
	tipLabel.add_font_override("font", tipFont)
	tipPanel.add_child(tipLabel)
	add_child(tipPanel)
	set_process(false)

func isOn() -> bool:
	return Settings.effects and not GeneralEngine.isFaking

# A monster or an ally took damage
func hit(entity, amount: int):
	if not isOn() or not is_instance_valid(entity):
		return
	number(entity, str(amount), Color(1, 1, 1))
	flash(entity)

# The player took damage
func hurt(entity, amount: int):
	if not isOn():
		return
	number(entity, str(amount), Color(1, 0.3, 0.3))
	flash(entity)
	shake(0.9, 0.25)
	tween.interpolate_property(flashRect, "color:a", 0.35, 0.0, 0.35)
	tween.start()

func heal(entity, amount: int):
	if not isOn() or amount <= 0:
		return
	number(entity, "+" + str(amount), Color(0.4, 1, 0.5))

func number(entity, text: String, color: Color):
	var label = Label.new()
	label.add_font_override("font", font)
	label.text = text
	label.modulate = color
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The map is scaled, so convert the entity's cell into screen coordinates. The cell is used
	# instead of the sprite position, which lags behind while the sprite slides to its new cell
	var origin = Ref.currentLevel.get_global_transform_with_canvas().xform(entity.pos * 9.0)
	label.rect_position = origin + Vector2(10 + randi() % 20, -30)
	add_child(label)
	var t = Tween.new()
	label.add_child(t)
	t.interpolate_property(label, "rect_position:y", label.rect_position.y, label.rect_position.y - RISE, LIFETIME, Tween.TRANS_QUAD, Tween.EASE_OUT)
	t.interpolate_property(label, "modulate:a", 1.0, 0.0, LIFETIME * 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN, LIFETIME * 0.5)
	t.start()
	yield(get_tree().create_timer(LIFETIME + 0.05), "timeout")
	if is_instance_valid(label):
		label.queue_free()

func flash(entity):
	var sprite = entity.get_node_or_null("BodySprite")
	if sprite == null:
		return
	sprite.modulate = Color(3, 3, 3)
	tween.interpolate_property(sprite, "modulate", Color(3, 3, 3), Color(1, 1, 1), 0.18)
	tween.start()

func shake(strength: float, duration: float):
	if not isOn() or shaking or Ref.currentLevel == null:
		return
	shaking = true
	strengthNow = strength
	tween.interpolate_method(self, "shakeStep", 1.0, 0.0, duration)
	tween.interpolate_callback(self, duration, "shakeDone")
	tween.start()

# Was setting the level position itself from a remembered base, which would fight the scrolling camera
func shakeStep(amount: float):
	Ref.currentLevel.shakeOffset = Vector2(rand_range(-1, 1), rand_range(-1, 1)) * strengthNow * amount
	Ref.currentLevel.applyPosition()

func shakeDone():
	Ref.currentLevel.shakeOffset = Vector2.ZERO
	Ref.currentLevel.applyPosition()
	shaking = false

# Called whenever the player's hit points change (Stats.updateHp)
func refreshHealth():
	if Ref.character == null or Ref.character.stats == null:
		return
	var low = Settings.effects and Ref.character.stats.hp > 0 and Ref.character.stats.hpPercent() < 0.3
	setWarning(low)

func setWarning(on: bool):
	if on == lowHealth:
		return
	lowHealth = on
	set_process(on)
	if on:
		Sfx.play("low_hp")
		Tips.show("low_hp", "Drink a potion (A) or rest (Z) before the next fight. Resting needs a floor with no monsters.")
		warnTime = 0.0
	else:
		for bar in warnBars:
			bar.color.a = 0.0
		warnLabel.modulate.a = 0.0

func clearWarning():
	setWarning(false)

func _process(delta):
	warnTime += delta
	var pulse = 0.5 + 0.5 * sin(warnTime * 2.6)
	for bar in warnBars:
		bar.color.a = 0.18 + 0.32 * pulse
	warnLabel.modulate.a = 0.45 + 0.5 * pulse

# ---------------------------------------------------------------- level transitions

const FADE_OUT = 0.45
const FADE_IN = 0.9
const CARD_FADE = 0.45
const CARD_HOLD = 1.3

func cardTexts(biome: int, floorNo: int) -> Array:
	match biome:
		Data.BIOME_CAVERN:
			return ["FLOOR " + str(floorNo), "The Caverns", Color(0.55, 0.85, 1.0)]
		Data.BIOME_CRYPT:
			return ["FLOOR " + str(floorNo), "The Crypt", Color(0.7, 0.75, 1.0)]
		Data.BIOME_MINE:
			return ["FLOOR " + str(floorNo), "The Mine", Color(1.0, 0.8, 0.5)]
		Data.BIOME_VOLCANO:
			return ["FLOOR " + str(floorNo), "The Volcano", Color(1.0, 0.5, 0.35)]
		Data.BIOME_TROLL_BOSS:
			return ["THE TROLL", "Do not turn your back", Color(1.0, 0.35, 0.3)]
	return ["FLOOR " + str(floorNo), "The Dungeon", Color(1.0, 0.85, 0.4)]

# Fade the screen to black. Yield on the result, it returns at once when effects are off.
func fadeOut():
	if not isOn():
		return
	transitioning = true
	transitionToken += 1
	tween.interpolate_property(blackRect, "color:a", blackRect.color.a, 1.0, FADE_OUT)
	tween.start()
	yield(get_tree().create_timer(FADE_OUT), "timeout")

# Arrive on a floor: black, then fade in while the title card shows the floor and the area
func arrive(biome: int, floorNo: int, summary: String = ""):
	if not isOn():
		transitioning = false
		return
	transitioning = true
	transitionToken += 1
	var token = transitionToken
	var texts = cardTexts(biome, max(1, floorNo))
	cardFloor.text = texts[0]
	cardArea.text = texts[1]
	cardFloor.modulate = texts[2]
	cardArea.modulate = Color(1, 1, 1, 0.85)
	cardSummary.text = summary
	cardSummary.modulate = Color(1, 1, 1, 0.6)
	blackRect.color.a = 1.0
	tween.interpolate_property(blackRect, "color:a", 1.0, 0.0, FADE_IN, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.2)
	tween.interpolate_property(cardBox, "modulate:a", 0.0, 1.0, CARD_FADE, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.2)
	tween.interpolate_property(cardBox, "modulate:a", 1.0, 0.0, CARD_FADE, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.2 + CARD_FADE + CARD_HOLD)
	tween.start()
	# The game takes input again once the screen is mostly visible, the card keeps fading on its own
	yield(get_tree().create_timer(0.55), "timeout")
	# A newer transition owns the flag, an older timer must not clear it early
	if token == transitionToken:
		transitioning = false

# ---------------------------------------------------------------- hover tooltip

func showTip(text: String, mouse: Vector2):
	if text == "":
		hideTip()
		return
	tipLabel.text = text
	tipPanel.rect_size = Vector2.ZERO
	tipPanel.rect_position = mouse + Vector2(24, 24)
	tipPanel.visible = true

func hideTip():
	tipPanel.visible = false
