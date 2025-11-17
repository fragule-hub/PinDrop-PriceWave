extends Node2D
class_name ClockPointer

@onready var times: Node2D = $times
@onready var label: Label = $Label

# 三段时间枚举：上午/下午/夜晚
enum TimeSegment { 上午, 下午, 夜晚 }

# 时间段对应的角度（弧度）
const ANGLE_MORNING: float = deg_to_rad(135)    # 上午: 135度
const ANGLE_AFTERNOON: float = deg_to_rad(45)   # 下午: 45度  
const ANGLE_NIGHT: float = deg_to_rad(-45)      # 夜晚: -45度

# 动画参数
@export var animation_duration: float = 0.5  # 动画持续时间（秒）
@export var animation_ease: Tween.EaseType = Tween.EASE_IN_OUT
@export var animation_trans: Tween.TransitionType = Tween.TRANS_CUBIC

# 当前状态
var current_time_segment: TimeSegment = TimeSegment.上午
var is_animating: bool = false
var current_rotation: float = ANGLE_MORNING

func _ready():
	# 连接GlobalPlayer信号
	GlobalPlayer.time_advanced.connect(_on_time_advanced)
	GlobalPlayer.time_changed.connect(_on_time_changed)
	GlobalPlayer.day_advanced.connect(_on_day_advanced)
	
	# 从GlobalPlayer读取当前时间状态
	if GlobalPlayer.times != null:
		set_time_segment(GlobalPlayer.times, false)  # 不播放动画
	else:
		set_time_segment(TimeSegment.上午, false)  # 默认上午，不播放动画

# 根据时间枚举获取对应角度
func get_angle_for_time_segment(time_segment: TimeSegment) -> float:
	match time_segment:
		TimeSegment.上午:
			return ANGLE_MORNING
		TimeSegment.下午:
			return ANGLE_AFTERNOON
		TimeSegment.夜晚:
			return ANGLE_NIGHT
		_:
			return ANGLE_MORNING

# 时间枚举转字符串
func time_segment_to_string(time_segment: TimeSegment) -> String:
	match time_segment:
		TimeSegment.上午:
			return "上午"
		TimeSegment.下午:
			return "下午"
		TimeSegment.夜晚:
			return "夜晚"
		_:
			return "上午"

# 设置时间分段（带动画）
func set_time_segment(time_segment: TimeSegment, animate: bool = true):
	if time_segment == current_time_segment and times.rotation == get_angle_for_time_segment(time_segment):
		return  # 已经是目标状态，无需操作
	
	current_time_segment = time_segment
	var target_angle = get_angle_for_time_segment(time_segment)
	
	if animate and not is_animating:
		animate_to_angle(target_angle)
	else:
		times.rotation = target_angle
		current_rotation = target_angle
	
	# 更新标签
	update_label()
	
	# 更新GlobalPlayer状态
	GlobalPlayer.times = time_segment

# 动画旋转到指定角度
func animate_to_angle(target_angle: float):
	if is_animating:
		return  # 如果正在动画，不重复启动
	
	is_animating = true
	var tween = create_tween()
	
	# 使用自定义插值函数
	var from_rotation = current_rotation
	tween.tween_method(_on_animation_step.bind(from_rotation, target_angle), 0.0, 1.0, animation_duration)
	tween.set_ease(animation_ease)
	tween.set_trans(animation_trans)
	tween.tween_callback(_on_animation_completed.bind(target_angle))

# 动画步骤处理
func _on_animation_step(progress: float, from_angle: float, to_angle: float):
	# 使用最短路径插值
	var diff = wrapf(to_angle - from_angle, -PI, PI)
	current_rotation = from_angle + diff * progress
	times.rotation = current_rotation

# 动画完成回调
func _on_animation_completed(target_angle: float):
	is_animating = false
	current_rotation = target_angle

# 更新时间标签
func update_label():
	label.text = time_segment_to_string(current_time_segment)

# 切换到下一个时间段
func advance_to_next_time():
	var next_time: TimeSegment
	match current_time_segment:
		TimeSegment.上午:
			next_time = TimeSegment.下午
		TimeSegment.下午:
			next_time = TimeSegment.夜晚
		TimeSegment.夜晚:
			next_time = TimeSegment.上午
		_:
			next_time = TimeSegment.上午
	
	set_time_segment(next_time, true)

# 切换到上一个时间段
func go_back_to_previous_time():
	var previous_time: TimeSegment
	match current_time_segment:
		TimeSegment.上午:
			previous_time = TimeSegment.夜晚
		TimeSegment.下午:
			previous_time = TimeSegment.上午
		TimeSegment.夜晚:
			previous_time = TimeSegment.下午
		_:
			previous_time = TimeSegment.上午
	
	set_time_segment(previous_time, true)

# 获取当前时间段的字符串表示
func get_current_time_string() -> String:
	return time_segment_to_string(current_time_segment)

# GlobalPlayer信号处理
func _on_time_advanced(new_time: ClockPointer.TimeSegment):
	print("ClockPointer收到时间推移信号: ", time_segment_to_string(new_time))
	# 根据新的时间进行旋转动画
	set_time_segment(new_time, true)

func _on_time_changed(old_time: ClockPointer.TimeSegment, new_time: ClockPointer.TimeSegment):
	print("ClockPointer收到时间变化信号: ", time_segment_to_string(old_time), " -> ", time_segment_to_string(new_time))

func _on_day_advanced(new_day: int):
	print("ClockPointer收到新的一天信号: 第", new_day, "天")
	# 可以在这里添加新的一天特效或音效
