extends Node

signal day_advanced(new_day: int)
signal time_advanced(new_time: ClockPointer.TimeSegment)  # 修复拼写错误
signal time_changed(old_time: ClockPointer.TimeSegment, new_time: ClockPointer.TimeSegment)  # 时间变化信号
signal backpack_updated(new_coupons: Array[CouponStat])  # 背包优惠券更新信号
signal daily_reward_changed(available: bool)  # 每日签到可领取状态变更

var backpack_coupons: Array[CouponStat] # 背包中的优惠券
var used_coupons: Array[CouponStat] # 已使用过的优惠券（墓地）

# 世界
var days: int = 1
var times: ClockPointer.TimeSegment = ClockPointer.TimeSegment.上午
# 属性
var satiety: float = 2.0 # 饱腹度，每天结束时扣除1点
var mood: float = 2.0 # 情绪值，每天结束时扣除1点
var health: float = 2.0 # 健康值，正常不会衰减
var daily_reward_available: bool = true # 每日签到奖励是否可领取

# 下一次交易的待选商品（来自主场景限时特惠的已按下标签）
var next_trade_goods_stats: Array[GoodsStat] = []

# 当日展示的 GoodsLabel 数据缓存（用于返回主场景时复用）：
# 每项为 { goods_stat: GoodsStat, hours: int, minutes: int }
var today_goods_labels_data: Array = []

func clear_today_goods_labels() -> void:
	today_goods_labels_data.clear()

# 问题失败次数
var question_fail_count: int = 0

func increase_question_fail_count() -> void:
	question_fail_count += 1

func reset_question_fail_count() -> void:
	question_fail_count = 0

# 时间推移功能
func advance_time():
	var old_time = times
	var new_day_advanced = false
	
	# 根据当前时间推移到下一个阶段
	match times:
		ClockPointer.TimeSegment.上午:
			times = ClockPointer.TimeSegment.下午
		ClockPointer.TimeSegment.下午:
			times = ClockPointer.TimeSegment.夜晚
		ClockPointer.TimeSegment.夜晚:
			times = ClockPointer.TimeSegment.上午
			days += 1  # 夜晚到上午，新的一天开始
			new_day_advanced = true
	
	# 发出信号
	time_changed.emit(old_time, times)
	time_advanced.emit(times)
	today_goods_labels_data.clear()
	
	if new_day_advanced:
		clear_today_goods_labels()
		daily_reward_available = true
		daily_reward_changed.emit(daily_reward_available)
		day_advanced.emit(days)
		print("新的一天开始了！第", days, "天")
	
	print("时间推移: ", get_time_string(old_time), " -> ", get_time_string(times))

# 获取时间段的字符串表示
func get_time_string(time_segment: ClockPointer.TimeSegment) -> String:
	match time_segment:
		ClockPointer.TimeSegment.上午:
			return "上午"
		ClockPointer.TimeSegment.下午:
			return "下午"
		ClockPointer.TimeSegment.夜晚:
			return "夜晚"
		_:
			return "未知"

# 背包优惠券管理函数
func add_coupon_to_backpack(coupon: CouponStat) -> bool:
	"""添加优惠券到背包，返回是否成功添加"""
	if coupon == null:
		print("错误：尝试添加空的优惠券到背包")
		return false
	
	# 添加到背包
	backpack_coupons.append(coupon)
	
	# 发出背包更新信号
	backpack_updated.emit(backpack_coupons.duplicate())
	
	print("成功添加优惠券到背包：", coupon.coupon_name if coupon.has_method("get_name") else "未知优惠券")
	return true

func add_coupons_to_backpack(coupons: Array[CouponStat]) -> int:
	"""批量添加优惠券到背包，返回成功添加的数量"""
	var added_count = 0
	for coupon in coupons:
		if coupon != null:
			backpack_coupons.append(coupon)
			added_count += 1
	
	if added_count > 0:
		# 发出背包更新信号
		backpack_updated.emit(backpack_coupons.duplicate())
		print("成功添加 ", added_count, " 张优惠券到背包")
	
	return added_count

func remove_coupon_from_backpack(coupon: CouponStat) -> bool:
	"""从背包中移除优惠券，返回是否成功移除"""
	if coupon == null:
		return false
	
	var index = backpack_coupons.find(coupon)
	if index != -1:
		backpack_coupons.remove_at(index)
		backpack_updated.emit(backpack_coupons.duplicate())
		print("从背包中移除优惠券：", coupon.coupon_name if coupon.has_method("get_name") else "未知优惠券")
		return true
	
	return false

func get_backpack_coupons() -> Array[CouponStat]:
	"""获取背包中的优惠券副本"""
	return backpack_coupons.duplicate()

func clear_backpack():
	"""清空背包"""
	backpack_coupons.clear()
	backpack_updated.emit([])
	print("背包已清空")

func claim_daily_reward() -> void:
	"""领取每日签到奖励并更新状态"""
	daily_reward_available = false
	daily_reward_changed.emit(daily_reward_available)
