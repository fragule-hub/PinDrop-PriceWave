extends Node
class_name GoodsSpawner

signal goods_spawner(goods: Goods)

const GOODS = preload("uid://2mwcjsl4f10w")

@export var container: Node

func spawn_goods(goods_stat: GoodsStat, amount: int = 0) -> Goods:
	var goods: Goods = GOODS.instantiate()
	goods.goods_stat = goods_stat
	
	if amount != 0: 
		goods.need_amount(amount)
	
	if container:
		container.add_child(goods)
	else:
		add_child(goods)
	
	goods_spawner.emit(goods)
	return goods

func spawn_goods_batch_array(goods_stats: Array[GoodsStat]):
	for goods_stat in goods_stats:
		spawn_goods(goods_stat)

func spawn_goods_batch_dict(goods_stats_with_amount: Dictionary) -> Dictionary:
	var spawned_goods := {}
	for goods_stat in goods_stats_with_amount:
		var amount = goods_stats_with_amount[goods_stat]
		var goods_node = spawn_goods(goods_stat, amount)
		spawned_goods[goods_stat] = goods_node
	return spawned_goods
