extends Button
class_name MovableButton

signal button_is_clicked(button: Button)

@onready var shadow: PanelContainer = %Shadow
@onready var display: TextureRect = %Display
@onready var panel: PanelContainer = %PanelContainer
@onready var rich_text: RichTextLabel = %RichTextLabel

@onready var shader_material: ShaderMaterial = display.material as ShaderMaterial

# 倾斜与动画参数（化繁为简）
const MAX_YAW_DEG: float = 10.0
const MAX_PITCH_DEG: float = 5.0
const TILT_TWEEN_TIME: float = 0.1
var _tilt_tween: Tween

# 拖拽相关（统一在按钮自身处理输入）
const DRAG_THRESHOLD: float = 8.0
const PICKUP_SCALE: Vector2 = Vector2(1.05, 1.05)
const NORMAL_SCALE: Vector2 = Vector2.ONE
const TWEEN_TIME: float = 0.12
var _tween: Tween
var _shadow_tween: Tween
var _left_pressed := false
var _drag_active := false
var _click_candidate := false
var _press_pos: Vector2 = Vector2.ZERO
var _drag_offset: Vector2 = Vector2.ZERO

# 阴影样式（复制以避免共享资源被改动）
const SHADOW_NORMAL_SIZE: int = 16
const SHADOW_PICKUP_SIZE: int = 24
var _shadow_style: StyleBoxFlat

# 字体大小动态调整
const MAX_TEXT_LENGTH_FOR_NORMAL_FONT: int = 5
const NORMAL_FONT_SIZE: int = 48  # 默认字体大小
const SMALL_FONT_SIZE: int = 36    # 长文本的字体大小

func _ready() -> void:
	_init_shadow_style()
	_init_text()
	pivot_offset = size / 2.0

func _init_shadow_style() -> void:
	if shadow:
		var sb := shadow.get_theme_stylebox("panel")
		if sb is StyleBoxFlat:
			_shadow_style = (sb as StyleBoxFlat).duplicate()
			shadow.add_theme_stylebox_override("panel", _shadow_style)

func _init_text() -> void:
	if not rich_text:
		return
	rich_text.text = text.replace("\\n", "\n")
	_update_font_size()

func _update_font_size() -> void:
	if not rich_text:
		return
	
	var current_length := rich_text.text.length()
	var theme_override = rich_text.get_theme_font_size("normal_font_size")

	if current_length > MAX_TEXT_LENGTH_FOR_NORMAL_FONT:
		if theme_override != SMALL_FONT_SIZE:
			rich_text.add_theme_font_size_override("normal_font_size", SMALL_FONT_SIZE)
	else:
		if theme_override != NORMAL_FONT_SIZE:
			rich_text.add_theme_font_size_override("normal_font_size", NORMAL_FONT_SIZE)


func _on_mouse_entered() -> void:
	_animate_tilt_to_current_pos()

func _on_mouse_exited() -> void:
	_animate_tilt_to_zero()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos := get_viewport().get_mouse_position()
		if event.pressed:
			_left_pressed = true
			_press_pos = mouse_pos
			_click_candidate = true
		else:
			_left_pressed = false
			if _drag_active:
				_drag_active = false
				_on_drag_end()
			elif _click_candidate and _is_mouse_inside_display():
				button_is_clicked.emit(self)
			_click_candidate = false
	elif event is InputEventMouseMotion:
		# 移动时更新倾斜；若正在拖拽则跟随
		if _tilt_tween and _tilt_tween.is_running():
			_tilt_tween.kill()
		_update_tilt_from_mouse()
		if _left_pressed and _drag_active:
			var mouse_pos := get_viewport().get_mouse_position()
			_follow_mouse(mouse_pos)

func _process(_delta: float) -> void:
	# 拖拽判定和兜底释放（更合理的状态管理）
	var mouse_pos := get_viewport().get_mouse_position()
	if _left_pressed:
		if _drag_active:
			_follow_mouse(mouse_pos)
		elif _click_candidate and _press_pos.distance_to(mouse_pos) > DRAG_THRESHOLD:
			_drag_active = true
			_click_candidate = false
			_drag_offset = global_position - mouse_pos
			_on_drag_start()

	if _left_pressed and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_left_pressed = false
		if _drag_active:
			_drag_active = false
			_on_drag_end()
		elif _click_candidate and _is_mouse_inside_display():
			button_is_clicked.emit(self)
		_click_candidate = false

func _update_tilt_from_mouse() -> void:
	if not shader_material or not display:
		return
	var pos: Vector2 = display.get_local_mouse_position()
	var disp_size: Vector2 = display.size
	if disp_size.x <= 0.0 or disp_size.y <= 0.0:
		return
	var nx := ((pos.x / disp_size.x) - 0.5) * 2.0
	var ny := ((pos.y / disp_size.y) - 0.5) * 2.0
	nx = clamp(nx, -1.0, 1.0)
	ny = clamp(ny, -1.0, 1.0)
	var yaw := nx * MAX_YAW_DEG
	var pitch := ny * MAX_PITCH_DEG
	shader_material.set_shader_parameter("rot_y_deg", yaw)
	shader_material.set_shader_parameter("rot_x_deg", pitch)

func _animate_tilt_to_current_pos() -> void:
	if not shader_material or not display:
		return
	var disp_size: Vector2 = display.size
	if disp_size.x <= 0.0 or disp_size.y <= 0.0:
		return
	var pos: Vector2 = display.get_local_mouse_position()
	var nx := ((pos.x / disp_size.x) - 0.5) * 2.0
	var ny := ((pos.y / disp_size.y) - 0.5) * 2.0
	nx = clamp(nx, -1.0, 1.0)
	ny = clamp(ny, -1.0, 1.0)
	var target_yaw := nx * MAX_YAW_DEG
	var target_pitch := ny * MAX_PITCH_DEG
	var start_yaw: float = shader_material.get_shader_parameter("rot_y_deg") if shader_material else 0.0
	var start_pitch: float = shader_material.get_shader_parameter("rot_x_deg") if shader_material else 0.0
	if _tilt_tween and _tilt_tween.is_running():
		_tilt_tween.kill()
	_tilt_tween = create_tween()
	_tilt_tween.tween_method(_set_rot_y, start_yaw, target_yaw, TILT_TWEEN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tilt_tween.parallel().tween_method(_set_rot_x, start_pitch, target_pitch, TILT_TWEEN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _animate_tilt_to_zero() -> void:
	if not shader_material:
		return
	var start_yaw: float = shader_material.get_shader_parameter("rot_y_deg")
	var start_pitch: float = shader_material.get_shader_parameter("rot_x_deg")
	if _tilt_tween and _tilt_tween.is_running():
		_tilt_tween.kill()
	_tilt_tween = create_tween()
	_tilt_tween.tween_method(_set_rot_y, start_yaw, 0.0, TILT_TWEEN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tilt_tween.parallel().tween_method(_set_rot_x, start_pitch, 0.0, TILT_TWEEN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _set_rot_y(val: float) -> void:
	if shader_material:
		shader_material.set_shader_parameter("rot_y_deg", val)

func _set_rot_x(val: float) -> void:
	if shader_material:
		shader_material.set_shader_parameter("rot_x_deg", val)

func _follow_mouse(mouse_pos: Vector2) -> void:
	global_position = mouse_pos + _drag_offset

func _on_drag_start() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(display, "scale", PICKUP_SCALE, TWEEN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if shadow:
		if _shadow_tween and _shadow_tween.is_running():
			_shadow_tween.kill()
		_shadow_tween = create_tween()
		_shadow_tween.tween_property(shadow, "scale", PICKUP_SCALE, TWEEN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if _shadow_style:
			var start_size := _shadow_style.shadow_size
			_shadow_tween.parallel().tween_method(_set_shadow_size, float(start_size), float(SHADOW_PICKUP_SIZE), TWEEN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_drag_end() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(display, "scale", NORMAL_SCALE, TWEEN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	if shadow:
		if _shadow_tween and _shadow_tween.is_running():
			_shadow_tween.kill()
		_shadow_tween = create_tween()
		_shadow_tween.tween_property(shadow, "scale", NORMAL_SCALE, TWEEN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		if _shadow_style:
			var start_size := _shadow_style.shadow_size
			_shadow_tween.parallel().tween_method(_set_shadow_size, float(start_size), float(SHADOW_NORMAL_SIZE), TWEEN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _set_shadow_size(val: float) -> void:
	if _shadow_style and shadow:
		_shadow_style.shadow_size = int(val)
		shadow.queue_redraw()

func _is_mouse_inside_display() -> bool:
	if not display:
		return false
	var pos: Vector2 = display.get_local_mouse_position()
	var rect := Rect2(Vector2.ZERO, display.size)
	return rect.has_point(pos)

func shake() -> void:
	if _drag_active:
		return
	var SHAKE_ANGLE_DEG: float = 8.0
	if _tween and _tween.is_running():
		_tween.kill()
	if _tilt_tween and _tilt_tween.is_running():
		_tilt_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "rotation_degrees", -SHAKE_ANGLE_DEG, 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "rotation_degrees", SHAKE_ANGLE_DEG, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "rotation_degrees", 0.0, 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
