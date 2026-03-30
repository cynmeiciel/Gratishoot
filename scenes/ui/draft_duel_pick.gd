extends Control

const TITLE_COL := Color(0.82, 0.95, 1.0)
const P1_COL := Color(0.35, 0.75, 1.0)
const P2_COL := Color(1.0, 0.45, 0.45)

var _title: Label
var _constraint_label: Label
var _turn_label: Label
var _options_scroll: ScrollContainer
var _options_grid: GridContainer
var _p1_label: Label
var _p2_label: Label
var _help_label: Label
var _option_buttons: Array[Button] = []


func _ready() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.anchors_preset = Control.PRESET_FULL_RECT
	dim.color = Color(0.02, 0.03, 0.08, 0.86)
	add_child(dim)

	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	add_child(center)

	var shell := PanelContainer.new()
	shell.custom_minimum_size = Vector2(980, 560)
	var shell_style := StyleBoxFlat.new()
	shell_style.bg_color = Color(0.06, 0.09, 0.16, 0.96)
	shell_style.border_width_left = 2
	shell_style.border_width_right = 2
	shell_style.border_width_top = 2
	shell_style.border_width_bottom = 2
	shell_style.border_color = Color(0.32, 0.45, 0.62, 0.9)
	shell_style.corner_radius_top_left = 10
	shell_style.corner_radius_top_right = 10
	shell_style.corner_radius_bottom_left = 10
	shell_style.corner_radius_bottom_right = 10
	shell.add_theme_stylebox_override("panel", shell_style)
	center.add_child(shell)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	shell.add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	_title = Label.new()
	_title.text = "DRAFT DUEL"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 38)
	_title.modulate = TITLE_COL
	root.add_child(_title)

	_constraint_label = Label.new()
	_constraint_label.text = "Constraint: NONE"
	_constraint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_constraint_label.add_theme_font_size_override("font_size", 24)
	root.add_child(_constraint_label)

	_turn_label = Label.new()
	_turn_label.text = "Player 1 Choosing"
	_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_turn_label.add_theme_font_size_override("font_size", 22)
	_turn_label.modulate = P1_COL
	root.add_child(_turn_label)

	var options_shell := PanelContainer.new()
	options_shell.custom_minimum_size = Vector2(900, 360)
	options_shell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	options_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var options_style := StyleBoxFlat.new()
	options_style.bg_color = Color(0.09, 0.12, 0.2, 0.95)
	options_style.border_width_left = 1
	options_style.border_width_right = 1
	options_style.border_width_top = 1
	options_style.border_width_bottom = 1
	options_style.border_color = Color(0.28, 0.38, 0.54, 0.85)
	options_style.corner_radius_top_left = 8
	options_style.corner_radius_top_right = 8
	options_style.corner_radius_bottom_left = 8
	options_style.corner_radius_bottom_right = 8
	options_shell.add_theme_stylebox_override("panel", options_style)
	root.add_child(options_shell)

	var options_margin := MarginContainer.new()
	options_margin.add_theme_constant_override("margin_left", 10)
	options_margin.add_theme_constant_override("margin_right", 10)
	options_margin.add_theme_constant_override("margin_top", 10)
	options_margin.add_theme_constant_override("margin_bottom", 10)
	options_shell.add_child(options_margin)

	_options_scroll = ScrollContainer.new()
	_options_scroll.custom_minimum_size = Vector2(860, 320)
	_options_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_options_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_options_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	options_margin.add_child(_options_scroll)

	var options_center := CenterContainer.new()
	options_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_options_scroll.add_child(options_center)

	_options_grid = GridContainer.new()
	_options_grid.columns = 3
	_options_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_options_grid.add_theme_constant_override("h_separation", 12)
	_options_grid.add_theme_constant_override("v_separation", 12)
	options_center.add_child(_options_grid)

	var bottom := VBoxContainer.new()
	bottom.add_theme_constant_override("separation", 4)
	root.add_child(bottom)

	_p1_label = Label.new()
	_p1_label.text = "P1: -"
	_p1_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_label.add_theme_font_size_override("font_size", 18)
	_p1_label.modulate = P1_COL
	bottom.add_child(_p1_label)

	_p2_label = Label.new()
	_p2_label.text = "P2: -"
	_p2_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p2_label.add_theme_font_size_override("font_size", 18)
	_p2_label.modulate = P2_COL
	bottom.add_child(_p2_label)

	_help_label = Label.new()
	_help_label.text = "Navigate: Left/Right/Up/Down    Confirm: Attack"
	_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_help_label.add_theme_font_size_override("font_size", 15)
	_help_label.modulate = Color(0.82, 0.86, 0.95)
	root.add_child(_help_label)


func configure_players(p1_name: String, p2_name: String) -> void:
	_p1_label.text = "%s: -" % p1_name
	_p2_label.text = "%s: -" % p2_name


func set_constraint_text(text: String) -> void:
	_constraint_label.text = text


func set_turn_text(text: String, is_p1_turn: bool) -> void:
	_turn_label.text = text
	_turn_label.modulate = P1_COL if is_p1_turn else P2_COL


func set_help_text(text: String) -> void:
	_help_label.text = text


func set_selection_names(p1_name: String, p2_name: String, p1_pick: String, p2_pick: String) -> void:
	_p1_label.text = "%s: %s" % [p1_name, p1_pick]
	_p2_label.text = "%s: %s" % [p2_name, p2_pick]


func set_options(options: Array, p1_index: int, p2_index: int, chooser: int, final_round: bool, p1_locked: bool, p2_locked: bool, columns: int = 3) -> void:
	var cols := maxi(1, columns)
	_options_grid.columns = cols
	_ensure_option_buttons(options.size())

	if options.is_empty():
		for btn in _option_buttons:
			btn.visible = false
		return

	for i in _option_buttons.size():
		var btn := _option_buttons[i]
		if i >= options.size():
			btn.visible = false
			continue
		btn.visible = true
		var w = options[i]
		var tag := ""
		if final_round:
			if i == p1_index and i == p2_index:
				tag = "P1+P2"
			elif i == p1_index:
				tag = "P1"
			elif i == p2_index:
				tag = "P2"
		else:
			if chooser == 1 and i == p1_index:
				tag = "P1"
			elif chooser == 2 and i == p2_index:
				tag = "P2"

		var lock_tag := ""
		if final_round:
			if p1_locked and i == p1_index:
				lock_tag += " [LOCKED P1]"
			if p2_locked and i == p2_index:
				lock_tag += " [LOCKED P2]"

		var prefix := ""
		if tag != "":
			prefix = "[%s] " % tag
		btn.text = "%s%s%s" % [prefix, String(w.weapon_name), lock_tag]
		btn.modulate = Color.WHITE

		var selected := false
		if final_round:
			selected = i == p1_index or i == p2_index
		else:
			selected = (chooser == 1 and i == p1_index) or (chooser == 2 and i == p2_index)

		var base := StyleBoxFlat.new()
		base.bg_color = Color(0.14, 0.18, 0.28, 0.96)
		base.corner_radius_top_left = 9
		base.corner_radius_top_right = 9
		base.corner_radius_bottom_left = 9
		base.corner_radius_bottom_right = 9
		base.content_margin_left = 12
		base.content_margin_right = 12
		base.content_margin_top = 10
		base.content_margin_bottom = 10
		base.border_width_left = 2
		base.border_width_right = 2
		base.border_width_top = 2
		base.border_width_bottom = 2
		base.border_color = Color(0.34, 0.45, 0.62)

		if selected:
			base.bg_color = Color(0.24, 0.34, 0.5, 0.98)
			base.border_color = Color(0.9, 0.97, 1.0)
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			btn.add_theme_color_override("font_color", w.get_rarity_color().lerp(Color.WHITE, 0.35))

		btn.add_theme_stylebox_override("normal", base)
		btn.add_theme_stylebox_override("hover", base)
		btn.add_theme_stylebox_override("pressed", base)
		btn.add_theme_stylebox_override("disabled", base)


func _ensure_option_buttons(count: int) -> void:
	while _option_buttons.size() < count:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(272, 58)
		btn.disabled = false
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.clip_text = true
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		btn.add_theme_font_size_override("font_size", 15)
		_options_grid.add_child(btn)
		_option_buttons.append(btn)
