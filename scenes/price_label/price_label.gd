extends Control
class_name PriceLabel

signal drop_in_midway(label: PriceLabel)
signal drop_in_finished(label: PriceLabel)

# 交互与动画参数（可在编辑器中调整）
@export var tilt_max_yaw_deg: float = 10.0 # 最大水平倾斜角度（度）
@export var tilt_max_pitch_deg: float = 5.0 # 最大垂直倾斜角度（度）
@export var tilt_tween_time: float = 0.1 # 倾斜过渡时间（秒）

@export var drag_threshold: float = 8.0 # 拖拽阈值（像素）
@export var drag_pickup_scale: Vector2 = Vector2(1.05, 1.05) # 拾起时缩放
@export var drag_tween_time: float = 0.12 # 拖拽缩放过渡时间（秒）

@export var line_draw_duration: float = 0.2 # 线条绘制/撤销动画时长（秒）

@export var drop_total_time: float = 0.48 # 坠落总时长（秒）
@export var drop_overshoot: float = 16.0 # 轻微超冲距离（像素）
@export var pulse_scale: Vector2 = Vector2(1.04, 1.04) # 着地脉冲缩放
@export var pulse_time: float = 0.1 # 着地脉冲时长（秒）
@export var shadow_start_scale: Vector2 = Vector2(0.3, 0.3) # 阴影初始缩放

@onready var shadow_node: PanelContainer = %Shadow
@onready var display_node: TextureRect = %Display
@onready var panel_node: PanelContainer = %PanelContainer
@onready var text_node: RichTextLabel = %RichTextLabel
@onready var number_node: Label = %Number
@onready var line1: Line2D = %Line1
@onready var line2: Line2D = %Line2

@onready var _shader: ShaderMaterial = display_node.material as ShaderMaterial # Display 使用的透视着色器

var _tilt_tween: Tween
var _drag_tween: Tween
var _shadow_tween: Tween
var _left_pressed := false
var _drag_active := false
var _click_candidate := false
var _press_pos: Vector2 = Vector2.ZERO
var _drag_offset: Vector2 = Vector2.ZERO

var _shadow_style: StyleBoxFlat

var _circled_numbers := [
	"①","②","③","④","⑤","⑥","⑦","⑧","⑨","⑩",
	"⑪","⑫","⑬","⑭","⑮","⑯","⑰","⑱","⑲","⑳"
]

var _line1_start: Vector2
var _line1_end: Vector2
var _line2_start: Vector2
var _line2_end: Vector2

func _ready() -> void:
	# 连接鼠标进入/离开以驱动倾斜动画
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	# 复制阴影样式避免修改共享资源
	_init_shadow_style()
	if line1 and line1.points.size() >= 2:
		_line1_start = line1.points[0]
		_line1_end = line1.points[1]
	if line2 and line2.points.size() >= 2:
		_line2_start = line2.points[0]
		_line2_end = line2.points[1]

func _init_shadow_style() -> void:
	if shadow_node:
		var sb := shadow_node.get_theme_stylebox("panel")
		if sb is StyleBoxFlat:
			_shadow_style = (sb as StyleBoxFlat).duplicate()
			shadow_node.add_theme_stylebox_override("panel", _shadow_style)

func _on_mouse_entered() -> void:
	_animate_tilt_to_current_pos()

func _on_mouse_exited() -> void:
	_animate_tilt_to_zero()

func _gui_input(event: InputEvent) -> void:
	# 在 Control 上处理输入：左键按下进入拖拽候选，移动超过阈值开始拖拽
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
			_click_candidate = false
	elif event is InputEventMouseMotion:
		# 鼠标移动更新倾斜；拖拽中则跟随鼠标
		if _tilt_tween and _tilt_tween.is_running():
			_tilt_tween.kill()
		_update_tilt_from_mouse()
		if _left_pressed and _drag_active:
			var mouse_pos := get_viewport().get_mouse_position()
			_follow_mouse(mouse_pos)

func _process(_delta: float) -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	if _left_pressed:
		if _drag_active:
			_follow_mouse(mouse_pos)
		elif _click_candidate and _press_pos.distance_to(mouse_pos) > drag_threshold:
			_drag_active = true
			_click_candidate = false
			_drag_offset = global_position - mouse_pos
			_on_drag_start()
	if _left_pressed and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_left_pressed = false
		if _drag_active:
			_drag_active = false
			_on_drag_end()
		_click_candidate = false

func _update_tilt_from_mouse() -> void:
	# 根据鼠标在 Display 上的位置计算倾斜角度，并写入着色器参数
	if not _shader or not display_node:
		return
	var pos: Vector2 = display_node.get_local_mouse_position()
	var disp_size: Vector2 = display_node.size
	if disp_size.x <= 0.0 or disp_size.y <= 0.0:
		return
	var nx := ((pos.x / disp_size.x) - 0.5) * 2.0
	var ny := ((pos.y / disp_size.y) - 0.5) * 2.0
	nx = clamp(nx, -1.0, 1.0)
	ny = clamp(ny, -1.0, 1.0)
	var yaw := nx * tilt_max_yaw_deg
	var pitch := ny * tilt_max_pitch_deg
	_shader.set_shader_parameter("rot_y_deg", yaw)
	_shader.set_shader_parameter("rot_x_deg", pitch)

func _animate_tilt_to_current_pos() -> void:
	# 鼠标进入时，平滑过渡到当前鼠标位置对应的倾斜角
	if not _shader or not display_node:
		return
	var disp_size: Vector2 = display_node.size
	if disp_size.x <= 0.0 or disp_size.y <= 0.0:
		return
	var pos: Vector2 = display_node.get_local_mouse_position()
	var nx := ((pos.x / disp_size.x) - 0.5) * 2.0
	var ny := ((pos.y / disp_size.y) - 0.5) * 2.0
	nx = clamp(nx, -1.0, 1.0)
	ny = clamp(ny, -1.0, 1.0)
	var target_yaw := nx * tilt_max_yaw_deg
	var target_pitch := ny * tilt_max_pitch_deg
	var start_yaw: float = _shader.get_shader_parameter("rot_y_deg") if _shader else 0.0
	var start_pitch: float = _shader.get_shader_parameter("rot_x_deg") if _shader else 0.0
	if _tilt_tween and _tilt_tween.is_running():
		_tilt_tween.kill()
	_tilt_tween = create_tween()
	_tilt_tween.tween_method(_set_rot_y, start_yaw, target_yaw, tilt_tween_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tilt_tween.parallel().tween_method(_set_rot_x, start_pitch, target_pitch, tilt_tween_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _animate_tilt_to_zero() -> void:
	# 鼠标离开时，平滑归零倾斜角
	if not _shader:
		return
	var start_yaw: float = _shader.get_shader_parameter("rot_y_deg")
	var start_pitch: float = _shader.get_shader_parameter("rot_x_deg")
	if _tilt_tween and _tilt_tween.is_running():
		_tilt_tween.kill()
	_tilt_tween = create_tween()
	_tilt_tween.tween_method(_set_rot_y, start_yaw, 0.0, tilt_tween_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tilt_tween.parallel().tween_method(_set_rot_x, start_pitch, 0.0, tilt_tween_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _set_rot_y(val: float) -> void:
	if _shader:
		_shader.set_shader_parameter("rot_y_deg", val)

func _set_rot_x(val: float) -> void:
	if _shader:
		_shader.set_shader_parameter("rot_x_deg", val)

func _follow_mouse(mouse_pos: Vector2) -> void:
	global_position = mouse_pos + _drag_offset

func _on_drag_start() -> void:
	# 拾起动画：Display/Shadow 放大，阴影尺寸增大
	if _drag_tween and _drag_tween.is_running():
		_drag_tween.kill()
	_drag_tween = create_tween()
	_drag_tween.tween_property(display_node, "scale", drag_pickup_scale, drag_tween_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if shadow_node:
		if _shadow_tween and _shadow_tween.is_running():
			_shadow_tween.kill()
		_shadow_tween = create_tween()
		_shadow_tween.tween_property(shadow_node, "scale", drag_pickup_scale, drag_tween_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if _shadow_style:
			var start_size := _shadow_style.shadow_size
			_shadow_tween.parallel().tween_method(_set_shadow_size, float(start_size), 32.0, drag_tween_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_drag_end() -> void:
	# 释放动画：Display/Shadow 恢复，阴影尺寸还原
	if _drag_tween and _drag_tween.is_running():
		_drag_tween.kill()
	_drag_tween = create_tween()
	_drag_tween.tween_property(display_node, "scale", Vector2.ONE, drag_tween_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if shadow_node:
		if _shadow_tween and _shadow_tween.is_running():
			_shadow_tween.kill()
		_shadow_tween = create_tween()
		_shadow_tween.tween_property(shadow_node, "scale", Vector2.ONE, drag_tween_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		if _shadow_style:
			var start_size := _shadow_style.shadow_size
			_shadow_tween.parallel().tween_method(_set_shadow_size, float(start_size), 20.0, drag_tween_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _set_shadow_size(val: float) -> void:
	if _shadow_style and shadow_node:
		_shadow_style.shadow_size = int(val)
		shadow_node.queue_redraw()

func _is_mouse_inside_display() -> bool:
	if not display_node:
		return false
	var pos: Vector2 = display_node.get_local_mouse_position()
	var rect := Rect2(Vector2.ZERO, display_node.size)
	return rect.has_point(pos)

func _set_line_progress(line: Line2D, start: Vector2, end: Vector2, t: float) -> void:
	var p := start.lerp(end, clamp(t, 0.0, 1.0))
	line.points = PackedVector2Array([start, p])

func _animate_line_draw(line: Line2D, duration: float, start: Vector2, end: Vector2) -> void:
	# 从起点到终点按进度绘制线条
	line.visible = true
	var tw := create_tween()
	tw.tween_method(func(v): _set_line_progress(line, start, end, v), 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _animate_line_erase(line: Line2D, duration: float, start: Vector2, end: Vector2) -> void:
	# 从终点向起点撤销线条，结束时隐藏
	var tw := create_tween()
	tw.tween_method(func(v): _set_line_progress(line, start, end, 1.0 - v), 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.finished.connect(func(): line.visible = false)

func play_disable() -> void:
	# 禁用动画：调灰面板并绘制两条线
	panel_node.modulate = Color(0.6, 0.6, 0.6, 1.0)
	_animate_line_draw(line1, line_draw_duration, _line1_start, _line1_end)
	_animate_line_draw(line2, line_draw_duration, _line2_start, _line2_end)

func play_enable() -> void:
	# 解禁动画：撤销两条线并恢复面板颜色
	_animate_line_erase(line1, line_draw_duration, _line1_start, _line1_end)
	_animate_line_erase(line2, line_draw_duration, _line2_start, _line2_end)
	panel_node.modulate = Color(1, 1, 1, 1)

func play_drop_in(target_pos: Vector2) -> void:
	# 阴影在目标位置由小到大；Display 从屏幕上方向目标位置坠落，并带有超冲与回弹
	position = target_pos
	var target_local := display_node.position
	var viewport_h := float(get_viewport().size.y)
	var drop_offset := viewport_h + 100.0
	display_node.position = Vector2(target_local.x, target_local.y - drop_offset)
	shadow_node.scale = shadow_start_scale
	shadow_node.visible = true
	var normal_shadow_size: float = 20.0
	var start_shadow_size: float = 8.0
	var sb = shadow_node.get_theme_stylebox("panel")
	if sb is StyleBoxFlat:
		normal_shadow_size = float((sb as StyleBoxFlat).shadow_size)
		start_shadow_size = max(1.0, normal_shadow_size * 0.4)
		_set_shadow_size(start_shadow_size)
	var tw := create_tween()
	tw.parallel().tween_callback(func(): drop_in_midway.emit(self)).set_delay(drop_total_time * 0.5)
	var overshoot_pos := Vector2(target_local.x, target_local.y + drop_overshoot)
	tw.tween_property(display_node, "position", overshoot_pos, drop_total_time * 0.85).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(shadow_node, "scale", Vector2(1.0, 1.0), drop_total_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.parallel().tween_method(_set_shadow_size, start_shadow_size, normal_shadow_size, drop_total_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.tween_property(display_node, "position", target_local, drop_total_time * 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(display_node, "scale", pulse_scale, pulse_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(display_node, "scale", Vector2.ONE, pulse_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(shadow_node, "scale", Vector2(1.06, 1.06), pulse_time * 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(shadow_node, "scale", Vector2(1.0, 1.0), pulse_time * 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): drop_in_finished.emit(self))

func set_content(data: Dictionary) -> void:
	# 接收 {num:int, text:string} 并分别渲染圆圈序号与文本
	if data.has("num"):
		set_number(int(data["num"]))
	if data.has("text"):
		set_text(str(data["text"]))

func set_number(n: int) -> void:
	var circ := ""
	if n >= 1 and n <= _circled_numbers.size():
		circ = _circled_numbers[n - 1]
	else:
		circ = str(n)
	number_node.text = " " + circ

func set_text(t: String) -> void:
	text_node.text = t
