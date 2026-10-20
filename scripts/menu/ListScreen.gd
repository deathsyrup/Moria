extends CanvasLayer

# A list in a panel, used for the saved games and the morgue. Up and Down move (or scroll), Enter
# picks when the list is selectable, Esc closes. "closed" gives the picked index, or -1.

signal closed(index)

const VISIBLE_ROWS = 12

var font: DynamicFont
var titleLabel: Label
var footerLabel: Label
var rows = []
var lines = []
var selectable = false
var owner_node = null
var index = 0
var scrollTop = 0

func _ready():
	font = preload("res://fonts/normalFont.tres").duplicate()
	font.size = 30
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
	box.add_constant_override("separation", 8)
	panel.add_child(box)
	titleLabel = label(Color(1, 0.85, 0.3), Label.ALIGN_CENTER)
	box.add_child(titleLabel)
	for _i in range(VISIBLE_ROWS):
		var row = label(Color(1, 1, 1), Label.ALIGN_LEFT)
		row.rect_min_size = Vector2(1300, 0)
		box.add_child(row)
		rows.append(row)
	footerLabel = label(Color(1, 1, 1, 0.6), Label.ALIGN_CENTER)
	box.add_child(footerLabel)

func label(color: Color, align: int) -> Label:
	var l = Label.new()
	l.add_font_override("font", font)
	l.modulate = color
	l.align = align
	l.clip_text = true
	return l

# owner is the screen that handles input normally, it is paused while the list is open
func open(title: String, newLines: Array, isSelectable: bool, footer: String, owner):
	owner_node = owner
	owner.set_process_input(false)
	lines = newLines
	selectable = isSelectable
	index = 0
	scrollTop = 0
	titleLabel.text = title
	footerLabel.text = footer
	visible = true
	set_process_input(true)
	refresh()

func close(picked: int):
	visible = false
	set_process_input(false)
	if owner_node != null:
		owner_node.set_process_input(true)
	emit_signal("closed", picked)

func _input(event):
	if event.is_action_pressed("ui_up"):
		moveBy(-1)
	elif event.is_action_pressed("ui_down"):
		moveBy(1)
	elif event.is_action_pressed("ui_page_up"):
		moveBy(-VISIBLE_ROWS)
	elif event.is_action_pressed("ui_page_down"):
		moveBy(VISIBLE_ROWS)
	elif event.is_action_released("ui_accept"):
		Sfx.play("ui_accept")
		close(index if selectable else -1)
	elif event.is_action_released("ui_cancel"):
		Sfx.play("ui_back")
		close(-1)
	get_tree().set_input_as_handled()

func moveBy(amount: int):
	if lines.empty():
		return
	index = int(clamp(index + amount, 0, lines.size() - 1))
	if index < scrollTop:
		scrollTop = index
	elif index >= scrollTop + VISIBLE_ROWS:
		scrollTop = index - VISIBLE_ROWS + 1
	Sfx.play("ui_move")
	refresh()

func refresh():
	for i in range(VISIBLE_ROWS):
		var at = scrollTop + i
		if at < lines.size():
			var marker = "> " if selectable and at == index else "  "
			rows[i].text = marker + lines[at]
			rows[i].modulate = Color(1, 0.85, 0.3) if selectable and at == index else Color(1, 1, 1)
		else:
			rows[i].text = ""
