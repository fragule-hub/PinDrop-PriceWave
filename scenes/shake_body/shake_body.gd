extends AnimatableBody2D
class_name ShakeBody

# 视觉节点
@onready var _visual: PanelContainer = $PanelContainer

# --- 物理参数 ---
# 二阶弹簧-阻尼模型
var _angle_rad: float = 0.0
var _angular_vel: float = 0.0
var _impulse_sign: int = 1

# --- 可调常量 ---
# 晃动特性
const FREQ_HZ: float = 6.0               # 自然频率（越大越快）
const DAMPING_RATIO: float = 0.22        # 阻尼比（越大越容易停）

# 脉冲强度, 对应强度 1, 2, 3
const _IMPULSES: Array[float] = [4.6, 7.7, 10.8] # 小, 中, 大

# 视觉效果
const STRETCH_GAIN: float = 0.08         # 由角速度映射到拉伸强度的系数
const STRETCH_MAX: float = 0.30          # 最大拉伸
const HORIZONTAL_SHAKE_GAIN: float = 15.0 # 左右晃动幅度系数

# --- 预计算常量 ---
const _W: float = TAU * FREQ_HZ
const _W_SQUARED: float = _W * _W
const _2_DAMP_W: float = 2.0 * DAMPING_RATIO * _W

# --- 初始状态 ---
var _initial_position: Vector2
var _initial_scale: Vector2


func _ready() -> void:
	_initial_position = position
	_initial_scale = _visual.scale
	# 将视觉节点的旋转轴心设置到其中心
	_visual.pivot_offset = _visual.size * 0.5
	# 初始时禁用物理处理，以节省性能
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	# 如果角速度和角度都非常小，则停止动画
	if abs(_angular_vel) < 0.01 and abs(_angle_rad) < 0.01:
		_reset_state()
		return

	# 更新物理模型
	var acceleration: float = -_W_SQUARED * _angle_rad - _2_DAMP_W * _angular_vel
	_angular_vel += acceleration * delta
	_angle_rad += _angular_vel * delta

	# 应用视觉效果
	_visual.rotation = _angle_rad
	position.x = _initial_position.x + _angle_rad * HORIZONTAL_SHAKE_GAIN

	var stretch: float = clamp(abs(_angular_vel) * STRETCH_GAIN, 0.0, STRETCH_MAX)
	_visual.scale.x = _initial_scale.x * (1.0 + stretch)
	_visual.scale.y = _initial_scale.y * (1.0 - stretch * 0.6)


# intensity: 1 (小), 2 (中), 3 (大)
func shake(intensity: int) -> void:
	# 将 1-based intensity 转换为 0-based index
	var index: int = intensity - 1
	
	# 确保 intensity 在有效范围内
	if index < 0 or index >= _IMPULSES.size():
		push_warning("Shake intensity %d is out of range." % intensity)
		return
	
	_apply_impulse(_IMPULSES[index])
	# 如果未激活，则激活物理处理
	if not is_physics_processing():
		set_physics_process(true)


func _apply_impulse(power: float) -> void:
	# 多次触发可以叠加，通过角速度脉冲累加实现
	_angular_vel += power * _impulse_sign
	# 交替施加力的方向，使晃动更自然
	_impulse_sign = -_impulse_sign


func _reset_state() -> void:
	# 恢复到初始状态
	_visual.rotation = 0.0
	_visual.scale = _initial_scale
	position = _initial_position
	_angular_vel = 0.0
	_angle_rad = 0.0
	# 禁用物理处理，直到下一次 shake() 调用
	set_physics_process(false)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		shake(1)
