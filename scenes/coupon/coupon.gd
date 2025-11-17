extends TextureRect
class_name Coupon

@onready var first: RichTextLabel = %First
@onready var last: RichTextLabel = %Last
@onready var label_box: HBoxContainer = $LabelBox

@export var coupon_stat: CouponStat : set = _set_coupon_stat, get = _get_coupon_stat
@export var move_shift: float = 100.0
@export var max_shift: float = 120.0

var _coupon_stat: CouponStat

enum State {
	BASE,
	CLICKED
}
var current_state: State = State.BASE
var _base_local_position: Vector2
var _anim_tween: Tween
var _fail_tween: Tween


func _set_coupon_stat(value: CouponStat) -> void:
	_coupon_stat = value
	_update_text()

func _get_coupon_stat() -> CouponStat:
	return _coupon_stat


func _ready() -> void:
	_update_text()
	await get_tree().process_frame
	_base_local_position = position
	resized.connect(_update_base_positions)

func _update_base_positions() -> void:
	_base_local_position = position


func _update_text() -> void:
	if _coupon_stat != null and first != null and last != null:
		first.text = _coupon_stat.coupon_stat_to_string()
		if _coupon_stat.get_conditions_count() > 1:
			first.add_theme_font_size_override("normal_font_size", 32)
		last.text = _coupon_stat.effect.effect_to_math()
		if _coupon_stat.effect.effect_type == CouponEffect.EffectType.乘算:
			last.add_theme_font_size_override("normal_font_size", 36)


func move_left() -> void:
	if _anim_tween and _anim_tween.is_running():
		_anim_tween.kill()
	_anim_tween = create_tween()
	var current_dx: float = position.x - _base_local_position.x
	var target_dx: float = clamp(current_dx - move_shift, -max_shift, max_shift)
	var target_pos: Vector2 = Vector2(_base_local_position.x + target_dx, position.y)
	_anim_tween.tween_property(self, "position", target_pos, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func move_back() -> void:
	if _anim_tween and _anim_tween.is_running():
		_anim_tween.kill()
	_anim_tween = create_tween()
	_anim_tween.tween_property(self, "position", _base_local_position, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("鼠标左键"):
		match current_state:
			State.BASE:
				GlobalSignal.coupon_is_clicked.emit(self)
			State.CLICKED:
				GlobalSignal.coupon_is_cancelled.emit(self)

func cancel() -> void:
	GlobalSignal.coupon_is_cancelled.emit(self)

func switch_state(state: State) -> void:
	current_state = state
	
func switch_to_base() -> void:
	current_state = State.BASE
	
func switch_to_clicked() -> void:
	current_state = State.CLICKED

func play_fail_bump() -> void:
	if _fail_tween and _fail_tween.is_running():
		_fail_tween.kill()
	_fail_tween = create_tween()
	var orig: Vector2 = position
	_fail_tween.tween_property(self, "position", orig - Vector2(40,0), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_fail_tween.tween_property(self, "position", _base_local_position, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
