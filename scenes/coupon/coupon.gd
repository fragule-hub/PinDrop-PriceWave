extends TextureRect
class_name Coupon

@onready var first: RichTextLabel = %First
@onready var last: RichTextLabel = %Last

@export var coupon_stat: CouponStat : set = _set_coupon_stat, get = _get_coupon_stat

var _coupon_stat: CouponStat

enum State {
	BASE,
	CLICKED
}
var current_state: State = State.BASE


func _set_coupon_stat(value: CouponStat) -> void:
	_coupon_stat = value
	_update_text()

func _get_coupon_stat() -> CouponStat:
	return _coupon_stat


func _ready() -> void:
	_update_text()


func _update_text() -> void:
	if _coupon_stat != null and first != null and last != null:
		first.text = _coupon_stat.coupon_stat_to_string()
		if _coupon_stat.get_conditions_count() > 1:
			first.add_theme_font_size_override("normal_font_size", 32)
		last.text = _coupon_stat.effect.effect_to_math()
		if _coupon_stat.effect.effect_type == CouponEffect.EffectType.乘算:
			last.add_theme_font_size_override("normal_font_size", 36)


func move_left() -> void:
	var tween := create_tween()
	# 使用弹性插值到目标位置，产生末尾弹跳
	tween.tween_property(self, "position", self.position - Vector2(100,0), 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func move_back() -> void:
	var tween := create_tween()
	# 使用弹性插值回到原位，产生末尾弹跳
	tween.tween_property(self, "position", self.position + Vector2(100,0), 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


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
