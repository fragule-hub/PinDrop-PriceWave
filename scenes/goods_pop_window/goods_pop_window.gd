## 商品弹窗管理器：展示随机/指定商品，确认后写入全局。
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

# 随机生成商品：委托 GoodsSpawner 实现策略与生成
func generate_goods_random(rarity: int, count: int, type_filter: GoodsStat.GoodsType = GoodsStat.GoodsType.食品) -> void:
	if goods_container and goods_container.spawner:
		_current_goods = goods_container.spawner.spawn_goods_random(rarity, count, type_filter)

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
