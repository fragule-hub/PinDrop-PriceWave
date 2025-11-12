extends PanelContainer
class_name MovableContainer

@export var title: String
@export var packed_scene: PackedScene
@export var scene_size: Vector2

@onready var display: TextureRect = %Display
@onready var container: FoldableContainer = %Container
@onready var sub_viewport: SubViewport = $SubViewport

# 倾斜与动画参数
const MAX_YAW_DEG: float = 2.0
const MAX_PITCH_DEG: float = 1.0
const TILT_TWEEN_TIME: float = 0.1
var _tilt_tween: Tween

# 拖拽相关
const DRAG_THRESHOLD: float = 8.0
const PICKUP_SCALE: Vector2 = Vector2(1.02, 1.02)
const NORMAL_SCALE: Vector2 = Vector2.ONE
const TWEEN_TIME: float = 0.12
var _tween: Tween
var _left_pressed := false
var _drag_active := false
var _click_candidate := false
var _press_pos: Vector2 = Vector2.ZERO
var _drag_offset: Vector2 = Vector2.ZERO
var _initial_width: float = 0.0

@onready var shader_material: ShaderMaterial = display.material as ShaderMaterial


func _ready() -> void:
	pivot_offset = size / 2.0
	if packed_scene:
		if title == "":
			container.title = "标题"
		else:
			container.title = title
		var scene_instance = packed_scene.instantiate()
		container.add_child(scene_instance)
		if scene_size != Vector2.ZERO:
			scene_instance.set_size(scene_size)
	container.resized.connect(_update_viewport_size)
	call_deferred("_set_initial_size")
	set_process(false)


func _set_initial_size() -> void:
	_update_viewport_size()
	if container.size.x > 0:
		_initial_width = container.size.x


func _update_viewport_size() -> void:
	var target_width: float = _initial_width if _initial_width > 0 else container.size.x
	var new_size := Vector2(target_width, container.size.y)
	if Vector2(sub_viewport.size) != new_size:
		sub_viewport.size = new_size
	if size != new_size:
		size = new_size


func _on_mouse_entered() -> void:
	_animate_tilt_to_current_pos()


func _on_mouse_exited() -> void:
	_animate_tilt_to_zero()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos := get_viewport().get_mouse_position()
			if event.pressed:
				_left_pressed = true
				_press_pos = mouse_pos
				_click_candidate = true
				set_process(true)
			else:
				_left_pressed = false
				if _drag_active:
					_drag_active = false
					_on_drag_end()
				elif _click_candidate and _is_mouse_inside_display():
					# 将按下事件和释放事件一起传递给视口
					var press_event := InputEventMouseButton.new()
					press_event.button_index = MOUSE_BUTTON_LEFT
					press_event.pressed = true
					press_event.position = display.get_local_mouse_position()
					sub_viewport.push_input(press_event)

					var release_event := event.duplicate() as InputEventMouseButton
					release_event.position = display.get_local_mouse_position()
					sub_viewport.push_input(release_event)
				_click_candidate = false
				set_process(false)
		elif event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			# 将滚轮事件传递给视口
			if _is_mouse_inside_display():
				var new_event = event.duplicate() as InputEventMouseButton
				new_event.position = display.get_local_mouse_position()
				sub_viewport.push_input(new_event)

	elif event is InputEventMouseMotion:
		if _is_mouse_inside_display():
			var new_event = event.duplicate() as InputEventMouseMotion
			new_event.position = display.get_local_mouse_position()
			sub_viewport.push_input(new_event)

		if _tilt_tween and _tilt_tween.is_running():
			_tilt_tween.kill()
		_update_tilt_from_mouse()


func _process(_delta: float) -> void:
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
	_tween.tween_property(self, "scale", PICKUP_SCALE, TWEEN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_drag_end() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", NORMAL_SCALE, TWEEN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _is_mouse_inside_display() -> bool:
	if not display:
		return false
	var pos: Vector2 = display.get_local_mouse_position()
	var rect := Rect2(Vector2.ZERO, display.size)
	return rect.has_point(pos)
