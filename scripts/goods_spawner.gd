extends Node
class_name GoodsSpawner

## Spawns Goods nodes into a container with helpers for batch and random selection

signal goods_spawner(goods: Goods)

const GOODS: PackedScene = preload("uid://2mwcjsl4f10w")

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

func select_goods_random(rarity: int, count: int, type_filter: GoodsStat.GoodsType = GoodsStat.GoodsType.食品) -> Array[GoodsStat]:
	var available_goods = GlobalGoods.all_goods_stats
	var filtered_goods: Array[GoodsStat] = []
	for goods_stat in available_goods:
		if goods_stat.level <= rarity:
			if goods_stat.goods_type == type_filter:
				filtered_goods.append(goods_stat)
	var selected_goods: Array[GoodsStat] = []
	var max_attempts = min(count, filtered_goods.size())
	for i in range(max_attempts):
		var random_index = randi() % filtered_goods.size()
		selected_goods.append(filtered_goods[random_index])
		filtered_goods.remove_at(random_index)
	return selected_goods

func spawn_goods_random(rarity: int, count: int, type_filter: GoodsStat.GoodsType = GoodsStat.GoodsType.食品) -> Array[GoodsStat]:
	var selected_goods = select_goods_random(rarity, count, type_filter)
	spawn_goods_batch_array(selected_goods)
	return selected_goods
