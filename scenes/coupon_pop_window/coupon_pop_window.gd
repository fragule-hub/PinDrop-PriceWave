extends PanelContainer
class_name CouponPpoWindow

signal confirmed

@onready var coupon_container: CouponContainer = $VBoxContainer/CouponContainer

var _coupons: Array[CouponStat] = []

@export var requests_by_day: Dictionary = {
		1: [
			{"condition_type": CouponCondition.ConditionType.无门槛, "n": 1},
			{"condition_type": CouponCondition.ConditionType.满减, "n": 1},
		],
		2: [
			{"condition_type": CouponCondition.ConditionType.无门槛, "n": 1},
			{"condition_type": CouponCondition.ConditionType.满减, "n": 2},
		],
		3: [
			{"condition_type": CouponCondition.ConditionType.无门槛, "n": 2},
			{"condition_type": CouponCondition.ConditionType.满减, "n": 2},
		],
		4: [
			{"condition_type": CouponCondition.ConditionType.无门槛, "n": 2},
			{"condition_type": CouponCondition.ConditionType.满减, "n": 3},
		],
		5: [
			{"condition_type": CouponCondition.ConditionType.无门槛, "n": 2},
			{"condition_type": CouponCondition.ConditionType.满减, "n": 3},
		],
		6: [
			{"condition_type": CouponCondition.ConditionType.无门槛, "n": 2},
			{"condition_type": CouponCondition.ConditionType.满减, "n": 3},
		],
		7: [
			{"condition_type": CouponCondition.ConditionType.无门槛, "n": 2},
			{"condition_type": CouponCondition.ConditionType.满减, "n": 3},
		],
		8: [
			{"condition_type": CouponCondition.ConditionType.无门槛, "n": 2},
			{"condition_type": CouponCondition.ConditionType.满减, "n": 3},
		],
	}

func _ready() -> void:
	toggle(false)


func toggle(visible_state: bool) -> void:
	visible = visible_state

func generate_coupons_random() -> void:
	var day = GlobalPlayer.days
	var requests = requests_by_day.get(day, [])

	for request in requests:
		var condition_type = request["condition_type"]
		var n = request["n"]
		# 使用默认商品类型（食品）
		var coupons = coupon_container.coupon_spawner.generate_coupon_stats(n, condition_type, GoodsStat.GoodsType.食品, 0) as Array[CouponStat]
		_coupons.append_array(coupons)
	
	coupon_container.coupon_spawner.spawn_coupons(_coupons)

func generate_coupons_random_with_rarity(rarity_offset: int) -> void:
	var day = GlobalPlayer.days
	var requests = requests_by_day.get(day, [])

	for request in requests:
		var condition_type = request["condition_type"]
		var n = request["n"]
		# 应用稀有度偏移生成优惠券
		var coupons = generate_coupons_with_rarity_offset(n, condition_type, rarity_offset) as Array[CouponStat]
		_coupons.append_array(coupons)
	
	coupon_container.coupon_spawner.spawn_coupons(_coupons)

func generate_coupons_with_rarity_offset(n: int, condition_type, rarity_offset: int) -> Array[CouponStat]:
	# 根据稀有度偏移生成优惠券
	return coupon_container.coupon_spawner.generate_coupon_stats(n, condition_type, GoodsStat.GoodsType.食品, rarity_offset)

func generate_coupons_specific(coupons: Array[CouponStat]) -> void:
	_coupons = coupons
	coupon_container.coupon_spawner.spawn_coupons(_coupons)

func _on_确认_pressed() -> void:
	# 使用GlobalPlayer的函数接口添加优惠券到背包
	if _coupons.size() > 0:
		GlobalPlayer.add_coupons_to_backpack(_coupons)
	
	confirmed.emit()
	# 清空当前优惠券数组，避免下次显示时重复
	_coupons.clear()
	toggle(false)  # 隐藏弹窗而不是释放整个场景
