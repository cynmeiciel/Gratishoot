extends Control

signal buy_requested(player_id: int, offer_index: int)
signal reroll_requested(player_id: int)
signal ready_toggled(player_id: int, ready: bool)

const TITLE_COL := Color(1.0, 0.92, 0.42)

var _player_panels: Dictionary = {}
var _credit_labels: Dictionary = {}
var _status_labels: Dictionary = {}
var _offer_boxes: Dictionary = {}
var _ready_buttons: Dictionary = {}
var _equipped_labels: Dictionary = {}
var _timer_label: Label
var _info_label: Label


func _ready() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.anchors_preset = Control.PRESET_FULL_RECT
	dim.color = Color(0.04, 0.06, 0.1, 0.86)
	add_child(dim)

	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	add_child(center)

	var shell := PanelContainer.new()
	shell.custom_minimum_size = Vector2(1140, 640)
	center.add_child(shell)

	var shell_margin := MarginContainer.new()
	shell_margin.add_theme_constant_override("margin_left", 16)
	shell_margin.add_theme_constant_override("margin_right", 16)
	shell_margin.add_theme_constant_override("margin_top", 14)
	shell_margin.add_theme_constant_override("margin_bottom", 14)
	shell.add_child(shell_margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	shell_margin.add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	root.add_child(top)

	var title := Label.new()
	title.text = "ARMS DEALER - BUY PHASE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 30)
	title.modulate = TITLE_COL
	top.add_child(title)

	_timer_label = Label.new()
	_timer_label.text = "12.0s"
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_timer_label.add_theme_font_size_override("font_size", 28)
	top.add_child(_timer_label)

	_info_label = Label.new()
	_info_label.text = "Buy gear, then lock in."
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.add_theme_font_size_override("font_size", 16)
	root.add_child(_info_label)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	root.add_child(row)

	_create_player_panel(row, 1, "Player 1")
	_create_player_panel(row, 2, "Player 2")


func configure_players(p1_name: String, p2_name: String) -> void:
	var panel1: VBoxContainer = _player_panels[1]
	var panel2: VBoxContainer = _player_panels[2]
	(panel1.get_node("Name") as Label).text = p1_name
	(panel2.get_node("Name") as Label).text = p2_name


func set_timer(seconds_left: float) -> void:
	_timer_label.text = "%.1fs" % maxf(0.0, seconds_left)
	if seconds_left <= 3.0:
		var pulse := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.016)
		_timer_label.modulate = Color(1.0, 0.25, 0.25).lerp(Color.WHITE, pulse)
	else:
		_timer_label.modulate = Color.WHITE


func set_info(text: String) -> void:
	_info_label.text = text


func set_credits(player_id: int, credits: int) -> void:
	if _credit_labels.has(player_id):
		(_credit_labels[player_id] as Label).text = "Credits: %d" % credits


func set_status(player_id: int, status: String, col: Color = Color.WHITE) -> void:
	if _status_labels.has(player_id):
		var lbl: Label = _status_labels[player_id]
		lbl.text = status
		lbl.modulate = col


func set_ready(player_id: int, ready: bool) -> void:
	if _ready_buttons.has(player_id):
		var btn: Button = _ready_buttons[player_id]
		btn.text = "Ready" if not ready else "Ready!"
		btn.modulate = Color(1.0, 1.0, 1.0) if not ready else Color(0.5, 1.0, 0.6)


func set_equipped(player_id: int, text: String) -> void:
	if _equipped_labels.has(player_id):
		(_equipped_labels[player_id] as Label).text = "Equipped: %s" % text


func set_offers(player_id: int, offers: Array) -> void:
	if not _offer_boxes.has(player_id):
		return
	var box: VBoxContainer = _offer_boxes[player_id]
	for c in box.get_children():
		c.queue_free()
	for i in offers.size():
		var offer = offers[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 38)
		btn.text = "[%d] %s (%s)" % [int(offer["price"]), String(offer["name"]), String(offer["kind"]).capitalize()]
		if offer.has("color"):
			btn.modulate = Color(offer["color"])
		btn.pressed.connect(func() -> void:
			buy_requested.emit(player_id, i)
		)
		box.add_child(btn)


func _create_player_panel(parent: Control, player_id: int, player_name: String) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)

	var name_label := Label.new()
	name_label.name = "Name"
	name_label.text = player_name
	name_label.add_theme_font_size_override("font_size", 22)
	v.add_child(name_label)

	var credits := Label.new()
	credits.text = "Credits: 0"
	credits.add_theme_font_size_override("font_size", 19)
	v.add_child(credits)

	var equipped := Label.new()
	equipped.text = "Equipped: -"
	equipped.add_theme_font_size_override("font_size", 14)
	equipped.modulate = Color(0.84, 0.9, 1.0)
	v.add_child(equipped)

	var offers_title := Label.new()
	offers_title.text = "Offers"
	offers_title.add_theme_font_size_override("font_size", 16)
	v.add_child(offers_title)

	var offers_box := VBoxContainer.new()
	offers_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	offers_box.add_theme_constant_override("separation", 5)
	v.add_child(offers_box)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	v.add_child(controls)

	var reroll_btn := Button.new()
	reroll_btn.text = "Reroll"
	reroll_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reroll_btn.pressed.connect(func() -> void:
		reroll_requested.emit(player_id)
	)
	controls.add_child(reroll_btn)

	var ready_btn := Button.new()
	ready_btn.text = "Ready"
	ready_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ready_btn.pressed.connect(func() -> void:
		ready_toggled.emit(player_id, true)
	)
	controls.add_child(ready_btn)

	var status := Label.new()
	status.text = ""
	status.add_theme_font_size_override("font_size", 14)
	v.add_child(status)

	_player_panels[player_id] = v
	_credit_labels[player_id] = credits
	_equipped_labels[player_id] = equipped
	_status_labels[player_id] = status
	_offer_boxes[player_id] = offers_box
	_ready_buttons[player_id] = ready_btn
