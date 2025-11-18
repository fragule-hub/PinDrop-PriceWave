extends Node
class_name PriceCalculator

signal price_change(index, price)
signal price_labels_rebuild(from_index: int, new_steps: Array)
signal price_step_added(index: int, text: String, price: float)

# 价格计算器
# - build_price_dict: 统计原价/特价，初始化当前价与基础标签数量
# - _on_coupon_is_clicked: 判定并应用优惠，发出文本步骤信号
# - _on_coupon_is_cancelled: 回退并重算后续步骤，必要时批量失败

var goods_stats: Array[GoodsStat]
var goods_types: Array[GoodsStat.GoodsType] = []

var original_price: float = 0.0 # 商品原价
var special_price: float = 0.0 # 商品特价（0 表示无特价）
var current_price: float = 0.0 # 当前价格（步骤应用后）
var price_list: Array[float] = [] # 仅记录优惠券步骤的价格结果

var current_index: int = 0 # 当前价格索引（从 1 开始）
var base_count: int = 1 # 基础价格数量（原价+特价）
var applied_steps: Array = [] # 已应用的步骤（记录券、条件与效果）

# 辅助：遗物名称索引，避免重复扫描
var _relic_by_name: Dictionary = {}
var _goods_type_set: Dictionary = {}

func _ready() -> void:
	GlobalSignal.coupon_is_clicked.connect(_on_coupon_is_clicked)
	GlobalSignal.coupon_is_cancelled.connect(_on_coupon_is_cancelled)
	# 索引遗物资源，键为遗物名称
	for stat in GlobalRelic.all_relic_stats:
		if stat != null and stat.name != "":
			_relic_by_name[stat.name] = stat

func build_price_dict(stats: Array[GoodsStat]) -> Dictionary:
	goods_stats = stats
	var price_map: Dictionary = {}
	original_price = 0.0
	special_price = 0.0
	goods_types.clear()
	var special_total := 0.0
	var has_any_special := false
	for s in goods_stats:
		if s == null:
			continue
		original_price += s.get_current_price()
		var sp := s.get_currnt_special_price()
		if sp != 0.0:
			has_any_special = true
			special_total += sp
		else:
			special_total += s.get_current_price()
		if not goods_types.has(s.goods_type):
			goods_types.append(s.goods_type)
		_goods_type_set[s.goods_type] = true
	price_map[1] = original_price
	current_index = 0
	if has_any_special:
		special_price = special_total
		price_map[2] = special_price
		current_price = max(0.0, special_price)
		base_count = 2
	else:
		special_price = 0.0
		current_price = max(0.0, original_price)
		base_count = 1
	price_list.clear()

	return price_map

func get_current_price() -> float:
	return current_price

func _on_coupon_is_clicked(coupon: Coupon) -> void:
	var coupon_stat: CouponStat = coupon.coupon_stat
	var conditions: Array[CouponCondition] = coupon_stat.conditions
	var effect: CouponEffect = coupon_stat.effect

	# 统一的条件判定
	if current_price <= 0.0:
		GlobalSignal.coupon_is_failed.emit(coupon)
		return
	var can_pass := _conditions_pass(conditions)
	if not can_pass:
		# 不通过时由容器处理失败动画，这里发出失败信号
		GlobalSignal.coupon_is_failed.emit(coupon)
	elif can_pass:
		GlobalSignal.coupon_is_passed.emit(coupon)
		# 统一的效果应用
		var eff_result := _apply_effect(effect, current_price)
		var new_price: float = eff_result["price"]
		var formula: String = eff_result["formula"]
		
		current_price = max(0.0, new_price)
		current_index += 1
		# 记录步骤并追加价格序列
		price_list.append(current_price)
		applied_steps.append({
			"coupon": coupon,
			"effect": effect,
			"conditions": conditions,
			"index": current_index,
			"price": current_price,
			"formula": formula
		})
		price_change.emit(current_index, current_price)
		price_step_added.emit(current_index, formula, current_price)

## 条件判定：所有条件均需满足；拥有“条件漏洞”时直接通过
func _conditions_pass(conditions: Array[CouponCondition]) -> bool:
	if _has_relic("条件漏洞"):
		GlobalRelic.trigger_relic_by_name("条件漏洞")
		return true
	for cond in conditions:
		match cond.condition_type:
			CouponCondition.ConditionType.无门槛:
				pass
			CouponCondition.ConditionType.满减:
				if current_price < cond.value:
					return false
			CouponCondition.ConditionType.专用:
				if not _goods_type_set.has(cond.goods_type):
					return false
	return true

## 效果应用：接入遗物“减算错误”“乘算错误”，并保证结果不为负
func _apply_effect(effect: CouponEffect, price_before: float) -> Dictionary:
	var result_val := price_before
	var formula := ""
	match effect.effect_type:
		CouponEffect.EffectType.减算:
			var sub_val := effect.value
			var sub_str := _fmt(sub_val)
			if _has_relic("减算错误"):
				var mul := _get_relic_param1("减算错误", 1.0)
				sub_val *= float(mul)
				sub_str = _fmt(effect.value) + "*" + _fmt(mul)
				GlobalRelic.trigger_relic_by_name("减算错误")
			result_val = price_before - sub_val
			formula = _fmt(price_before) + " - " + sub_str + " = " + _fmt(result_val)
		CouponEffect.EffectType.乘算:
			var mul_factor := effect.value
			if _has_relic("乘算错误"):
				var bonus := _get_relic_param1("乘算错误", 0.0)
				mul_factor = max(0.0, mul_factor - float(bonus))
				result_val = price_before * mul_factor
				formula = _fmt(price_before) + " * (" + _fmt(effect.value) + " - " + _fmt(bonus) + ") = " + _fmt(result_val)
				GlobalRelic.trigger_relic_by_name("乘算错误")
			else:
				result_val = price_before * mul_factor
				formula = _fmt(price_before) + " * " + _fmt(mul_factor) + " = " + _fmt(result_val)
	if result_val < 0.0:
		result_val = 0.0
		var eq_pos := formula.find(" = ")
		if eq_pos != -1:
			formula = formula.substr(0, eq_pos + 3) + _fmt(result_val)
	return {"price": result_val, "formula": formula}

func _fmt(v: float) -> String:
	if is_zero_approx(fmod(v, 1.0)):
		return str(int(v))
	return str(v)

## 遗物检索：通过名称获取资源与参数（使用本地名称索引避免重复扫描）
func _find_relic_by_name(relic_name: String) -> RelicStat:
	if _relic_by_name.has(relic_name):
		return _relic_by_name[relic_name]
	return null

func _has_relic(relic_name: String) -> bool:
	var s := _find_relic_by_name(relic_name)
	if s == null:
		return false
	return GlobalRelic.has_relic(s)

func _get_relic_param1(relic_name: String, default_val: float) -> float:
	var s := _find_relic_by_name(relic_name)
	if s == null:
		return default_val
	return float(s.parameter1)

func _on_coupon_is_cancelled(coupon: Coupon) -> void:
	# 查找被取消的步骤
	var found_idx := -1
	for i in range(applied_steps.size()):
		var step := applied_steps[i] as Dictionary
		if step.has("coupon") and step["coupon"] == coupon:
			found_idx = i
			break
	if found_idx == -1:
		return

	var start_label_index: int = int(applied_steps[found_idx]["index"])
	# 移除该步骤
	applied_steps.remove_at(found_idx)

	# 回退至该步骤之前的价格与索引，并截断价格列表
	current_index = start_label_index - 1
	if current_index >= 1:
		current_price = price_list[current_index - 1]
	else:
		current_price = max(0.0, special_price) if special_price != 0.0 else max(0.0, original_price)
	while price_list.size() > current_index:
		price_list.pop_back()

	# 重算剩余步骤并重新校验条件；如不通过，记录失败并终止
	var new_steps: Array = []
	var fail_start := -1
	var k := found_idx
	while k < applied_steps.size():
		var step := applied_steps[k] as Dictionary
		var conds: Array[CouponCondition] = step["conditions"]
		var eff: CouponEffect = step["effect"]
		var can_pass := _conditions_pass(conds)
		if not can_pass:
			fail_start = k
			break
		# 应用效果
		var eff_result2 := _apply_effect(eff, current_price)
		var np: float = eff_result2["price"]
		np = max(0.0, np)
		var formula2: String = eff_result2["formula"]
		current_price = np
		current_index += 1
		price_list.append(current_price)
		step["index"] = current_index
		step["price"] = current_price
		step["formula"] = formula2
		new_steps.append({"index": current_index, "price": current_price, "formula": formula2})
		k += 1

	# 若在重算中发现不通过，则批量发送失败并移除后续步骤
	if fail_start != -1:
		var fail_coupons: Array = []
		for m in range(fail_start, applied_steps.size()):
			var c: Coupon = applied_steps[m]["coupon"]
			fail_coupons.append(c)
		# 移除失败及其后的步骤
		while applied_steps.size() > fail_start:
			applied_steps.pop_back()
		# 批量失败信号（容器负责回退基础状态与取消标记）
		GlobalSignal.coupons_recalc_failed.emit(fail_coupons)

	# 价格标签从 start_label_index 起删除并按 new_steps 重建
	price_labels_rebuild.emit(start_label_index, new_steps)
