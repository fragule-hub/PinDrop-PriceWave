# coupon_container.gd
# 优惠券容器，负责管理和显示优惠券
extends ScrollContainer
class_name CouponContainer

# --- 导出变量 ---

# 是否检查背包
@export var is_check_backpack: bool = false
# 是否处于战斗场景
@export var is_battle: bool = false

# --- 节点引用 ---

@onready var number_icon_factory: NumberIconFactory = $NumberIconFactory
@onready var coupon_spawner: CouponSpawner = $CouponSpawner

# --- 私有变量 ---

# 保存当前被选中的优惠券, 按选中顺序排列
var _selected_coupons: Array[Coupon] = []

# --- Godot生命周期函数 ---

func _ready() -> void:
	# 连接全局信号
	if is_battle:
		GlobalSignal.coupon_is_passed.connect(_on_coupon_passed)
	else:
		GlobalSignal.coupon_is_clicked.connect(_on_coupon_clicked)
	GlobalSignal.coupon_is_cancelled.connect(_on_coupon_cancelled)
	GlobalSignal.coupon_is_failed.connect(_on_coupon_failed)
	GlobalSignal.coupons_recalc_failed.connect(_on_coupons_recalc_failed)
	
	# 如果配置为检查背包，则连接背包更新信号并初始化
	if is_check_backpack:
		GlobalPlayer.backpack_updated.connect(_on_backpack_updated)
		spawn_backpack_coupons()

func _input(event: InputEvent) -> void:
	# 处理右键点击取消最后一个选中的优惠券
	if event.is_action_pressed("鼠标右键"):
		var last_selected_coupon = _get_last_selected_coupon()
		if is_instance_valid(last_selected_coupon):
			last_selected_coupon.cancel()

# --- 公共方法 ---

# 更新优惠券容器
func update_coupons() -> void:
	# 清空所有图标和选择 - 使用正确的清除方法
	_clear_all_icons()
	_selected_coupons.clear()
	
	# 释放所有现有的优惠券子节点
	for n in get_children():
		if n is Coupon:
			n.queue_free()

# 清除所有数字图标
func _clear_all_icons() -> void:
	# 从最大序号开始删除，避免索引问题
	for i in range(_selected_coupons.size(), 0, -1):
		number_icon_factory.remove_number_icon(i)

# 获取当前所有选中的优惠券节点
func get_selected_coupons() -> Array[Coupon]:
	return _selected_coupons.duplicate() # 返回副本以防外部修改

# 获取当前所有选中的优惠券的统计信息
func get_selected_coupon_stats() -> Array[CouponStat]:
	var stats: Array[CouponStat] = []
	for coupon in get_selected_coupons():
		stats.append(coupon.coupon_stat)
	return stats

# 生成并添加初始的背包优惠券
func spawn_backpack_coupons() -> void:
	## 从GlobalPlayer获取背包中的优惠券信息
	#var backpack_coupons = GlobalPlayer.get_backpack_coupons()
	#
	#if backpack_coupons.size() > 0:
		## 根据背包中的优惠券统计信息生成实际的优惠券节点
		#coupon_spawner.spawn_coupons(backpack_coupons)
	coupon_spawner.spawn_coupons(coupon_spawner.generate_coupon_stats(4,CouponCondition.ConditionType.无门槛))
	coupon_spawner.spawn_coupons(coupon_spawner.generate_coupon_stats(4,CouponCondition.ConditionType.满减))
	coupon_spawner.spawn_coupons(coupon_spawner.generate_coupon_stats(4,CouponCondition.ConditionType.专用, GoodsStat.GoodsType.食品))

# 处理背包更新信号
func _on_backpack_updated(new_coupons: Array[CouponStat]) -> void:
	print("收到背包更新信号，优惠券数量: ", new_coupons.size())
	
	# 清空当前显示
	update_coupons()
	
	# 如果背包中有优惠券，重新生成显示
	if new_coupons.size() > 0:
		coupon_spawner.spawn_coupons(new_coupons)


# 处理优惠券计算通过的信号
func _on_coupon_passed(coupon: Coupon) -> void:
	# 如果优惠券未被选中，则选中它
	if not coupon in _selected_coupons:
		_selected_coupons.append(coupon)
		var sequence_number = _selected_coupons.size()

		# 在优惠券上显示序列号图标
		number_icon_factory.create_number_icon(sequence_number, Vector2(250,0), coupon)
		
		coupon.move_left()
		coupon.switch_to_clicked()

# 处理优惠券点击事件
func _on_coupon_clicked(coupon: Coupon) -> void:
	# 如果优惠券未被选中，则选中它
	if not coupon in _selected_coupons:
		_selected_coupons.append(coupon)
		var sequence_number = _selected_coupons.size()

		# 在优惠券上显示序列号图标
		number_icon_factory.create_number_icon(sequence_number, Vector2(250,0), coupon)
		
		coupon.move_left()
		coupon.switch_to_clicked()

# 处理优惠券取消选中事件
func _on_coupon_cancelled(coupon: Coupon) -> void:
	var index = _selected_coupons.find(coupon)
	# 如果优惠券已被选中，则取消选中
	if index != -1:
		# 移除优惠券和它的图标
		var removed_sequence_number = index + 1
		number_icon_factory.remove_number_icon(removed_sequence_number)
		_selected_coupons.remove_at(index)
		
		# 更新后续优惠券的图标
		for i in range(index, _selected_coupons.size()):
			var c = _selected_coupons[i]
			# 旧的序列号是 i + 2 (因为数组中移除了一个元素，原来的索引 i+1 移动到了 i)
			# 新的序列号是 i + 1
			number_icon_factory.remove_number_icon(i + 2)
			number_icon_factory.create_number_icon(i + 1, Vector2(250, 0), c)
		
		coupon.move_back()
		coupon.switch_to_base()

# 处理优惠券失败的信号
func _on_coupon_failed(_coupon: Coupon) -> void:
	if is_instance_valid(_coupon):
		_coupon.play_fail_bump()

# 处理所有优惠券重新计算失败的信号
func _on_coupons_recalc_failed(coupons: Array) -> void:
	if coupons.is_empty():
		return
	var first_fail: Coupon = coupons[0]
	var start_idx := _selected_coupons.find(first_fail)
	if start_idx == -1:
		return
	for i in range(start_idx, _selected_coupons.size()):
		var c: Coupon = _selected_coupons[i]
		number_icon_factory.remove_number_icon(i + 1)
		c.move_back()
		c.switch_to_base()
	while _selected_coupons.size() > start_idx:
		_selected_coupons.pop_back()
	for i in range(_selected_coupons.size()):
		var c: Coupon = _selected_coupons[i]
		number_icon_factory.create_number_icon(i + 1, Vector2(250, 0), c)

# --- 私有辅助方法 ---

# 获取最后一个被选中的优惠券
func _get_last_selected_coupon() -> Coupon:
	if not _selected_coupons.is_empty():
		return _selected_coupons.back()
	return null
