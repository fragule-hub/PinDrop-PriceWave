extends Resource
class_name CouponStat

enum CouponType {
	优惠券,
	膨胀神券,
}

@export var conditions: Array[CouponCondition]
@export var effect: CouponEffect
@export var coupon_type: CouponType

func coupon_stat_to_string() -> String:
	var result_string = ""
	var sorted_conditions = conditions.duplicate()
	sorted_conditions.sort_custom(func(a, b):
		# 排序逻辑：专用 > 满减 > 无门槛
		# ConditionType.专用 = 2, ConditionType.满减 = 1, ConditionType.无门槛 = 0
		return a.condition_type > b.condition_type
	)
	for condition in sorted_conditions:
		result_string += condition.condition_to_string() + "\n"
	result_string += effect.effect_to_string()
	return result_string

func get_conditions_count() -> int:
	return conditions.size()
