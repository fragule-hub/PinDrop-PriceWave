extends Node

# 事件：数量变化（供 UI 监听刷新）（对应的goods，新的总数）
signal goods_amount_changed(stat: GoodsStat, new_total: int)
# 事件：外部请求（供业务层通过信号调用）（对应的goods，变化的数值）
signal add_requested(stat: GoodsStat, value: int)
signal remove_requested(stat: GoodsStat, value: int)

const GOODS_STATS_PATH = "res://data/goods_stats"

var all_goods_stats: Array[GoodsStat]
var goods_amounts: Dictionary

func _ready() -> void:
	_load_all_goods_stats()
	add_requested.connect(_on_add_requested)
	remove_requested.connect(_on_remove_requested)

func _load_all_goods_stats() -> void:
	var dir = DirAccess.open(GOODS_STATS_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				pass
			elif file_name.ends_with(".tres"):
				var resource_path = GOODS_STATS_PATH.path_join(file_name)
				var goods_stat = load(resource_path) as GoodsStat
				if goods_stat:
					all_goods_stats.append(goods_stat)
					goods_amounts[goods_stat] = 0
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func _on_add_requested(stat: GoodsStat, value: int) -> void:
	if goods_amounts.has(stat):
		goods_amounts[stat] += value
		goods_amount_changed.emit(stat, goods_amounts[stat])

func _on_remove_requested(stat: GoodsStat, value: int) -> void:
	if goods_amounts.has(stat):
		goods_amounts[stat] = max(0, goods_amounts[stat] - value)
		goods_amount_changed.emit(stat, goods_amounts[stat])

func get_owned_goods() -> Dictionary:
	var owned_goods: Dictionary
	for stat in goods_amounts:
		if goods_amounts[stat] > 0:
			owned_goods[stat] = goods_amounts[stat]
	return owned_goods
