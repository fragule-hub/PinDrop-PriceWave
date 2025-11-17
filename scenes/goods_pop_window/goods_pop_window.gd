# 商品弹窗管理器
# 负责显示商品选择界面，支持随机生成和指定商品
extends PanelContainer
class_name GoodsPopWindow
# 确认信号
signal confirmed

# UI容器引用
@onready var goods_container: GoodsContainer = $VBoxContainer/GoodsContainer

# 当前显示的商品列表
var _current_goods: Array[GoodsStat] = []

# 节点初始化
func _ready() -> void:
	toggle(false)

# 切换弹窗显示状态
func toggle(visible_state: bool) -> void:
	visible = visible_state

# 随机生成商品
func generate_goods_random(rarity: int, count: int, type_filter: GoodsStat.GoodsType = GoodsStat.GoodsType.食品) -> void:
	# 获取所有可用商品
	var available_goods = GlobalGoods.all_goods_stats
	var filtered_goods: Array[GoodsStat] = []
	
	# 根据稀有度和类型筛选商品
	for goods_stat in available_goods:
		if goods_stat.level <= rarity:  # 使用level作为稀有度
			# 检查商品类型是否匹配
			if goods_stat.goods_type == type_filter:
				filtered_goods.append(goods_stat)
	
	# 随机选择指定数量的商品
	var selected_goods: Array[GoodsStat] = []
	var max_attempts = min(count, filtered_goods.size())
	
	for i in range(max_attempts):
		var random_index = randi() % filtered_goods.size()
		selected_goods.append(filtered_goods[random_index])
		filtered_goods.remove_at(random_index)
	
	_current_goods = selected_goods
	
	# 显示商品
	if goods_container and goods_container.spawner:
		goods_container.spawner.spawn_goods_batch_array(_current_goods)

# 显示指定商品
func generate_goods_specific(goods_list: Array[GoodsStat]) -> void:
	_current_goods = goods_list
	
	# 显示商品
	if goods_container and goods_container.spawner:
		goods_container.spawner.spawn_goods_batch_array(_current_goods)

# 确认按钮点击事件
func _on_确认_pressed() -> void:
	# 将商品添加到玩家背包
	for goods_stat in _current_goods:
		GlobalGoods.add_requested.emit(goods_stat, 1)
	
	confirmed.emit()
	# 清空当前商品列表
	_current_goods.clear()
	toggle(false)  # 隐藏弹窗
