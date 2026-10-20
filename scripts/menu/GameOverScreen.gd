extends CanvasLayer

# Shown when the character dies: how far the run went, then back to the title screen.

var font: DynamicFont
var body: Label

func _ready():
	font = preload("res://fonts/normalFont.tres").duplicate()
	font.size = 36
	layer = 110
	set_process_input(false)
	visible = false
	var dim = ColorRect.new()
	dim.color = Color(0.1, 0, 0, 0.85)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	add_child(dim)
	var center = CenterContainer.new()
	center.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	add_child(center)
	var box = VBoxContainer.new()
	box.add_constant_override("separation", 22)
	center.add_child(box)
	box.add_child(label("YOU HAVE DIED", Color(0.9, 0.2, 0.2), Label.ALIGN_CENTER, 64))
	body = label("", Color(1, 1, 1), Label.ALIGN_CENTER, 36)
	box.add_child(body)
	box.add_child(label("Press Enter to return to the title screen", Color(1, 1, 1, 0.6), Label.ALIGN_CENTER, 30))

func label(text: String, color: Color, align: int, size: int) -> Label:
	var l = Label.new()
	var f = font.duplicate()
	f.size = size
	l.add_font_override("font", f)
	l.text = text
	l.modulate = color
	l.align = align
	return l

func open(lines: Array):
	body.text = "\n".join(lines)
	visible = true
	GLOBAL.currentMode = GLOBAL.MODE_GAMEOVER
	MasterInput.setMaster(self)

func _input(event):
	if event.is_action_released("ui_accept") or event.is_action_released("ui_cancel"):
		get_tree().set_input_as_handled()
		get_tree().change_scene("res://scenes/UI/TitleScreen.tscn")
