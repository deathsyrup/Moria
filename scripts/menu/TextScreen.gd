extends CanvasLayer
class_name TextScreen

# A scrolling text page, used for the manual. Up, Down, Page Up and Page Down scroll, Esc or Enter close.

signal closed

var font: DynamicFont
var text: RichTextLabel
var owner_node = null

func _ready():
	font = preload("res://fonts/normalFont.tres").duplicate()
	font.size = 28
	layer = 100
	set_process_input(false)
	visible = false
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.85)
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
		style.set_default_margin(margin, 28)
	panel.add_stylebox_override("panel", style)
	center.add_child(panel)
	var box = VBoxContainer.new()
	panel.add_child(box)
	text = RichTextLabel.new()
	text.bbcode_enabled = true
	text.scroll_active = true
	text.rect_min_size = Vector2(1400, 820)
	text.add_font_override("normal_font", font)
	text.add_font_override("bold_font", font)
	box.add_child(text)
	var footer = Label.new()
	footer.add_font_override("font", font)
	footer.text = "Up / Down / Page Up / Page Down: scroll      Esc: back"
	footer.modulate = Color(1, 1, 1, 0.6)
	footer.align = Label.ALIGN_CENTER
	box.add_child(footer)

func open(bbcode: String, owner, toEnd: bool = false):
	owner_node = owner
	owner.set_process_input(false)
	text.bbcode_text = bbcode
	text.scroll_to_line(0)
	visible = true
	set_process_input(true)
	if toEnd:
		call_deferred("scrollToEnd")

func scrollToEnd():
	# Was scroll_to_line(get_line_count()), one past the last line (an engine error)
	var bar = text.get_v_scroll()
	bar.value = bar.max_value

func close():
	visible = false
	set_process_input(false)
	if owner_node != null:
		owner_node.set_process_input(true)
	emit_signal("closed")

func _input(event):
	var bar = text.get_v_scroll()
	if event.is_action_pressed("ui_up"):
		bar.value -= 60
	elif event.is_action_pressed("ui_down"):
		bar.value += 60
	elif event.is_action_pressed("ui_page_up"):
		bar.value -= 600
	elif event.is_action_pressed("ui_page_down"):
		bar.value += 600
	elif event.is_action_released("ui_cancel") or event.is_action_released("ui_accept"):
		Sfx.play("ui_back")
		close()
	get_tree().set_input_as_handled()

# MANUAL.md is the one place the manual is written. This turns the parts of Markdown it uses
# (headings, bullets, tables, bold, code) into text a RichTextLabel can show.
static func markdownToBbcode(markdown: String) -> String:
	var out = []
	var headerSeen = false
	for raw in markdown.split("\n"):
		var line = raw.strip_edges(false, true)
		if line.begins_with("|"):
			headerSeen = true
			if "---" in line:
				continue
			var cells = []
			for cell in line.trim_prefix("|").trim_suffix("|").split("|"):
				cells.append(cell.strip_edges())
			line = "[color=#9ad7ff]" + cells[0] + "[/color]" + ("   " + "   ".join(cells.slice(1, cells.size() - 1)) if cells.size() > 1 else "")
		elif line.begins_with("# ") or line.begins_with("## "):
			out.append("")
			line = "[color=#ffd84d][b]" + line.lstrip("# ") + "[/b][/color]"
		elif line.begins_with("- "):
			line = "  • " + line.substr(2)
		line = line.replace("`", "")
		var parts = line.split("**")
		if parts.size() > 1:
			line = ""
			for i in range(parts.size()):
				line += ("[b]" + parts[i] + "[/b]") if i % 2 == 1 else parts[i]
		out.append(line)
	return "\n".join(out)
