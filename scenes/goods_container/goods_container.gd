extends GridContainer
class_name GoodsContainer

@onready var spawner: GoodsSpawner = $GoodsSpawner

@export var is_check_backpack: bool = false

var _goods_nodes: Dictionary = {}

func _ready():
	if is_check_backpack:
		GlobalGoods.goods_amount_changed.connect(_on_goods_amount_changed)
		var owned_goods = GlobalGoods.get_owned_goods()
		if not owned_goods.is_empty():
			_goods_nodes = spawner.spawn_goods_batch_dict(owned_goods)

func _on_goods_amount_changed(stat: GoodsStat, new_total: int) -> void:
	if _goods_nodes.has(stat):
		if new_total > 0:
			var goods_node: Goods = _goods_nodes[stat]
			goods_node.need_amount(new_total)
		else:
			var goods_node: Goods = _goods_nodes[stat]
			_goods_nodes.erase(stat)
			goods_node.queue_free()
	elif new_total > 0:
		var goods_node = spawner.spawn_goods(stat, new_total)
		_goods_nodes[stat] = goods_node
