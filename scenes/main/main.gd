extends Node2D
class_name Main


@onready var 每日签到: MovableButton = $每日签到
@onready var coupon_pop_window: PanelContainer = $每日签到/CouponPopWindow


func _on_movable_button_button_is_clicked(_button: Button) -> void:
	coupon_pop_window.generate_coupons_random()
	coupon_pop_window.toggle(true)


func _on_coupon_pop_window_confirmed() -> void:
	每日签到.queue_free()
