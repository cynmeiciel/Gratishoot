extends Control
## Pause overlay. process_mode = ALWAYS so it receives input while tree is paused.
## Attach this to the "Overlay" Control inside the PauseMenu CanvasLayer.

signal quit_to_menu

## Set to false after the match ends so ESC is handed back to arena_manager.
var can_open := true

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var resume_btn: Button = $Panel/Margin/VBox/ResumeButton
@onready var quit_btn: Button = $Panel/Margin/VBox/QuitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_apply_styles()
	resume_btn.pressed.connect(close)
	quit_btn.pressed.connect(_on_quit)


func _process(_delta: float) -> void:
	if visible:
		# Animate title colour
		var t := Time.get_ticks_msec() * 0.003
		title_label.modulate = Color(
			0.80 + 0.20 * sin(t),
			0.75 + 0.20 * sin(t + 0.8),
			0.30 + 0.20 * sin(t + 1.6)
		)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode != KEY_ESCAPE:
		return
	if visible:
		get_viewport().set_input_as_handled()
		close()
	elif can_open:
		get_viewport().set_input_as_handled()
		open()


func open() -> void:
	visible = true
	AudioManager.play_sfx_varied("ui_click", -5.5, 0.98, 1.03)
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false
	AudioManager.play_sfx_varied("ui_back", -5.5, 0.98, 1.03)


func _on_quit() -> void:
	AudioManager.play_sfx_varied("ui_back", -5.5, 0.98, 1.03)
	get_tree().paused = false
	quit_to_menu.emit()


func _apply_styles() -> void:
	# Panel background
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.05, 0.05, 0.10, 0.92)
	box.border_width_left   = 2
	box.border_width_top    = 2
	box.border_width_right  = 2
	box.border_width_bottom = 2
	box.border_color = Color(0.60, 0.55, 0.15, 1.0)
	box.set_corner_radius_all(8)
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	box.shadow_size = 12
	panel.add_theme_stylebox_override("panel", box)

	# Buttons
	_style_button(resume_btn, Color(0.15, 0.60, 0.22), Color(0.22, 0.80, 0.30))
	_style_button(quit_btn,   Color(0.55, 0.14, 0.12), Color(0.80, 0.22, 0.18))


func _style_button(btn: Button, normal_col: Color, hover_col: Color) -> void:
	var nb := StyleBoxFlat.new()
	nb.bg_color = normal_col
	nb.set_corner_radius_all(5)
	nb.border_width_left = 1; nb.border_width_top = 1
	nb.border_width_right = 1; nb.border_width_bottom = 1
	nb.border_color = normal_col.lightened(0.25)
	btn.add_theme_stylebox_override("normal", nb)

	var hb := StyleBoxFlat.new()
	hb.bg_color = hover_col
	hb.set_corner_radius_all(5)
	hb.border_width_left = 1; hb.border_width_top = 1
	hb.border_width_right = 1; hb.border_width_bottom = 1
	hb.border_color = hover_col.lightened(0.30)
	btn.add_theme_stylebox_override("hover", hb)

	var pb := StyleBoxFlat.new()
	pb.bg_color = hover_col.darkened(0.15)
	pb.set_corner_radius_all(5)
	btn.add_theme_stylebox_override("pressed", pb)

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
