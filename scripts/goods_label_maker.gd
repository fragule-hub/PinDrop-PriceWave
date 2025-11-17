extends Node
class_name GoodsLabelMaker

## Factory for GoodsLabel creation with single and batch APIs.

const GOODSLABEL := preload("res://scenes/goods_label/goods_label.tscn")

@export var container: Node

func spawn_one(goods_stat: GoodsStat, time_limit: GoodsLabel.TimeLimit = GoodsLabel.TimeLimit.HOURS_8) -> GoodsLabel:
	var c := container
	if c == null:
		push_error("GoodsLabelMaker: container is not resolved.")
		return null
	var label: GoodsLabel = GOODSLABEL.instantiate() as GoodsLabel
	if label == null:
		push_error("Failed to instantiate GOODS_LABEL scene.")
		return null
	if goods_stat != null:
		label.configure(goods_stat, time_limit)
	c.add_child(label)
	_ensure_trade_button_bottom()
	return label

func spawn_batch(goods_stats: Array[GoodsStat], time_limit: GoodsLabel.TimeLimit = GoodsLabel.TimeLimit.HOURS_8) -> Array[GoodsLabel]:
	var result: Array[GoodsLabel] = []
	var c := container
	if c == null:
		push_error("GoodsLabelMaker: container is not resolved.")
		return result
	for stat in goods_stats:
		var label: GoodsLabel = GOODSLABEL.instantiate() as GoodsLabel
		if label == null:
			push_error("Failed to instantiate GOODS_LABEL scene.")
			continue
		if stat != null:
			label.configure(stat, time_limit)
		c.add_child(label)
		result.append(label)
	_ensure_trade_button_bottom()
	return result

func _ensure_trade_button_bottom() -> void:
	if container == null:
		return
	var trade_btn: Node = null
	for child in container.get_children():
		if child is Button and child.name == "交易":
			trade_btn = child
			break
	if trade_btn != null:
		var last_index := container.get_child_count() - 1
		container.move_child(trade_btn, last_index)
