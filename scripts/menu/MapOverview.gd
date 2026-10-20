extends CanvasLayer

# The whole floor as far as it has been explored (Tab, or Select on a gamepad).

var font: DynamicFont
var canvas: Control
var titleLabel: Label
var isOpen = false

func _ready():
	font = preload("res://fonts/normalFont.tres").duplicate()
	font.size = 30
	layer = 100
	set_process_input(false)
	visible = false
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
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
		style.set_default_margin(margin, 26)
	panel.add_stylebox_override("panel", style)
	center.add_child(panel)
	var box = VBoxContainer.new()
	box.add_constant_override("separation", 14)
	panel.add_child(box)
	titleLabel = Label.new()
	titleLabel.add_font_override("font", font)
	titleLabel.align = Label.ALIGN_CENTER
	titleLabel.modulate = Color(1, 0.85, 0.3)
	box.add_child(titleLabel)
	canvas = preload("res://scripts/menu/MapCanvas.gd").new()
	box.add_child(canvas)
	var legend = RichTextLabel.new()
	legend.bbcode_enabled = true
	legend.fit_content_height = true
	legend.scroll_active = false
	legend.add_font_override("normal_font", font)
	legend.bbcode_text = "[center][color=#66ffff]you[/color]   [color=#ffd84d]stairs[/color]   [color=#f2e666]loot[/color]   [color=#ff9933]chest[/color]   [color=#ff4d4d]enemy[/color]   [color=#e64de6]trap[/color]   [color=#a66b33]door[/color]      Esc: close[/center]"
	box.add_child(legend)

func open():
	isOpen = true
	titleLabel.text = "FLOOR " + str(max(1, WorldHandler.currentFloor))
	visible = true
	canvas.update()
	GLOBAL.currentMode = GLOBAL.MODE_MAP
	MasterInput.setMaster(self)

func close():
	isOpen = false
	visible = false
	GLOBAL.currentMode = GLOBAL.MODE_NORMAL
	MasterInput.setMaster(Ref.game)

func _input(event):
	if event.is_action_released("ui_cancel") or event.is_action_released("ui_accept") or event.is_action_released("overview"):
		Sfx.play("ui_back")
		close()
	get_tree().set_input_as_handled()
