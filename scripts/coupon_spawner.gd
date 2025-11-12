# CouponSpawner.gd
extends Node
class_name CouponSpawner

## 优惠券生成器
##
## 负责根据不同的规则和参数创建和生成优惠券。
## 可以生成优惠券的数据（CouponStat）或直接在场景中实例化优惠券节点。

# 当一个优惠券被实例化时发出此信号
signal coupon_spawned(coupon: Coupon)

# 预加载优惠券场景，用于实例化
const COUPON_SCENE = preload("uid://kdqhiljpvin5")

# 优惠券实例化的容器节点
@export var container: Node

# ==============================================================================
# 效果和门槛配置
#
# 这些字典定义了不同稀有度下优惠券的效果值和满减门槛。
# 稀有度越高，效果越强。
# ==============================================================================

# 减算效果（直接减去一个数值）
@export var subtract_effect_by_rarity: Dictionary = {
	1: 5, 
	2: 10, 
	3: 20, 
	4: 40, 
	5: 60, 
	6: 80, 
	7: 100, 
	8: 120,
}

# 乘算效果（折扣）
@export var multiply_effect_by_rarity: Dictionary = {
	1: 0.9, 
	2: 0.7, 
	3: 0.5, 
	4: 0.4, 
	5: 0.3, 
	6: 0.2, 
	7: 0.1, 
	8: 0.01,
}

# 满减门槛
@export var threshold_by_rarity: Dictionary = {
	1: 9, 
	2: 18, 
	3: 36, 
	4: 72, 
	5: 108, 
	6: 144, 
	7: 180, 
	8: 216,
}

# ==============================================================================
# 稀有度权重配置
#
# 定义了在游戏的不同天数，不同稀有度优惠券出现的权重。
# 天数越多，高稀有度的优惠券出现的概率越大。
# ==============================================================================

@export var rarity_share_by_day: Dictionary = {
	1: {1: 1},
	2: {1: 1, 2: 1},
	3: {1: 1, 2: 1, 3: 1},
	4: {1: 1, 2: 1, 3: 1, 4: 1},
	5: {1: 0, 2: 1, 3: 1, 4: 1, 5: 1},
	6: {1: 0, 2: 0, 3: 1, 4: 1, 5: 1, 6: 1},
	7: {1: 0, 2: 0, 3: 0, 4: 1, 5: 1, 6: 1, 7: 1},
	8: {1: 0, 2: 0, 3: 0, 4: 0, 5: 1, 6: 1, 7: 1, 8: 1},
}

var _rng := RandomNumberGenerator.new()

func _ready():
	_rng.randomize()


# ==============================================================================
# 公共接口
# ==============================================================================

## 生成优惠券统计数据 (CouponStat) 数组
##
## 这是生成优惠券数据的主要接口。
##
## @param p_count: 生成优惠券的数量。
## @param p_condition_type: 优惠券的条件类型 (无门槛, 满减, 专用)。
## @param p_goods_type: 如果是专用品类券，需要指定商品类型。
## @param p_rarity_offset: 稀有度偏移量，用于调整稀有度计算所基于的天数。
## @return: 返回一个包含生成好的 [CouponStat] 的数组。
func generate_coupon_stats(p_count: int, p_condition_type: CouponCondition.ConditionType, p_goods_type: GoodsStat.GoodsType = GoodsStat.GoodsType.食品, p_rarity_offset: int = 0) -> Array[CouponStat]:
	if p_count <= 0:
		return []

	var rarity_shares: Dictionary = _get_rarity_shares_for_day(p_rarity_offset)

	# 随机分配减算和乘算优惠券的数量
	var subtract_count: int = _rng.randi_range(0, p_count)
	var multiply_count: int = p_count - subtract_count

	var stats: Array[CouponStat] = []
	stats.append_array(_generate_stats_for_effect_type(subtract_count, CouponEffect.EffectType.减算, p_condition_type, p_goods_type, rarity_shares))
	stats.append_array(_generate_stats_for_effect_type(multiply_count, CouponEffect.EffectType.乘算, p_condition_type, p_goods_type, rarity_shares))
	
	stats.shuffle()
	return stats


## 根据提供的 CouponStat 数组在场景中生成优惠券实例。
##
## @param p_stats: 一个包含 [CouponStat] 的数组。
## @return: 返回一个包含实例化的 [Coupon] 节点的数组。
func spawn_coupons(p_stats: Array[CouponStat]) -> Array[Coupon]:
	var coupons: Array[Coupon] = []
	if p_stats == null or p_stats.is_empty():
		return coupons

	for stat in p_stats:
		if not stat is CouponStat:
			continue
		
		var coupon_node: Coupon = COUPON_SCENE.instantiate()
		coupon_node.coupon_stat = stat
		
		if container != null:
			container.add_child(coupon_node)
			
		coupon_spawned.emit(coupon_node)
		coupons.append(coupon_node)
		
	return coupons


# ==============================================================================
# 私有辅助函数
# ==============================================================================

## 根据效果类型生成指定数量的优惠券数据
func _generate_stats_for_effect_type(p_count: int, p_effect_type: CouponEffect.EffectType, p_condition_type: CouponCondition.ConditionType, p_goods_type: GoodsStat.GoodsType, p_rarity_shares: Dictionary) -> Array[CouponStat]:
	var stats: Array[CouponStat] = []
	for _i in range(p_count):
		var base_rarity: int = _pick_rarity_from_shares(p_rarity_shares)
		
		# 对于某些条件，效果的稀有度会更高
		var effect_rarity: int = base_rarity
		if p_condition_type == CouponCondition.ConditionType.满减 or p_condition_type == CouponCondition.ConditionType.专用:
			effect_rarity = min(base_rarity + 1, 8)

		var condition: CouponCondition = _create_condition(p_condition_type, p_goods_type, effect_rarity)
		var effect: CouponEffect = _create_effect(p_effect_type, effect_rarity)
		
		var stat: CouponStat = _create_coupon_stat(condition, effect)
		stats.append(stat)
	return stats


## 创建优惠券条件
func _create_condition(p_type: CouponCondition.ConditionType, p_goods_type: GoodsStat.GoodsType, p_rarity: int) -> CouponCondition:
	var condition := CouponCondition.new()
	condition.condition_type = p_type
	
	match p_type:
		CouponCondition.ConditionType.满减:
			condition.value = float(threshold_by_rarity.get(p_rarity, 128))
		CouponCondition.ConditionType.专用:
			condition.goods_type = p_goods_type
			
	return condition


## 创建优惠券效果
func _create_effect(p_type: CouponEffect.EffectType, p_rarity: int) -> CouponEffect:
	var effect := CouponEffect.new()
	effect.effect_type = p_type
	
	if p_type == CouponEffect.EffectType.减算:
		effect.value = float(subtract_effect_by_rarity.get(p_rarity, 3))
	else:
		effect.value = float(multiply_effect_by_rarity.get(p_rarity, 0.1))
		
	return effect


## 创建优惠券统计数据资源
func _create_coupon_stat(p_condition: CouponCondition, p_effect: CouponEffect) -> CouponStat:
	var stat := CouponStat.new()
	stat.conditions = [p_condition] # 注意：conditions 是一个数组
	stat.effect = p_effect
	stat.coupon_type = CouponStat.CouponType.优惠券
	return stat


## 根据天数和稀有度偏移获取稀有度权重
func _get_rarity_shares_for_day(p_rarity_offset: int) -> Dictionary:
	var current_day: int = GlobalPlayer.days
	var day_for_rarity: int = clamp(current_day + p_rarity_offset, 1, 8)
	
	var shares: Dictionary = rarity_share_by_day.get(day_for_rarity, {})
	if shares.is_empty():
		# 如果没有为当天配置权重，则为所有低于或等于天数的稀有度提供均等权重
		shares = {}
		var max_rarity: int = min(day_for_rarity, 8)
		for r in range(1, max_rarity + 1):
			shares[r] = 1
			
	return shares


## 根据权重随机选择一个稀有度
func _pick_rarity_from_shares(p_shares: Dictionary) -> int:
	var total_weight: int = 0
	for weight in p_shares.values():
		total_weight += int(weight)

	if total_weight <= 0:
		return 1

	var random_pick: int = _rng.randi_range(1, total_weight)
	var accumulated_weight: int = 0
	
	# 对稀有度进行排序以确保一致性
	var sorted_rarities: Array = p_shares.keys()
	sorted_rarities.sort()

	for rarity in sorted_rarities:
		accumulated_weight += int(p_shares[rarity])
		if random_pick <= accumulated_weight:
			return int(rarity)
			
	return 1 # 作为备用
