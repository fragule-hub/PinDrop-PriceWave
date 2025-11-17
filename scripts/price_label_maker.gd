extends Node
class_name PriceLabelMaker

# 价格标签生成器
# - create_price_label: 生成单个 PriceLabel 并播放坠落动画；可选择立即禁用上一标签
# - create_price_labels_sequential: 批量顺序生成，以上一个标签坠落动画的“中点”信号推进
# - remove_labels_from_index: 按序号释放后续标签
# - enable_last_label/disable_last_label: 控制当前保留的最后一个标签的启用/禁用动画

@export var price_label_scene: PackedScene = preload("uid://cuynesxxsyf7q")

var _base_positions_by_num: Dictionary = {}
var _labels: Array[PriceLabel] = []
var _previous_label: PriceLabel
var _label_index_map: Dictionary = {}

func create_price_label(label_data: Dictionary, position: Vector2 = Vector2.ZERO, disable_prev_immediately: bool = false) -> PriceLabel:
	# 实例化并设置内容
	var label := price_label_scene.instantiate() as PriceLabel
	add_child(label)
	label.set_content(label_data)

	# 计算最终位置：优先使用传入位置，否则基于编号位置并带随机偏移与越界修正
	var final_position: Vector2
	if position != Vector2.ZERO:
		final_position = position
	else:
		var label_num := int(label_data.get("num", 0))
		if _base_positions_by_num.has(label_num):
			var base: Vector2 = _base_positions_by_num[label_num]
			var dx := float(randi_range(50, 150))
			var dy := float(randi_range(50, 150))
			final_position = base + Vector2(dx, dy)
		else:
			var base := Vector2(label_num * 100, label_num * 100)
			_base_positions_by_num[label_num] = base
			final_position = base

		var limit_max := Vector2(randf_range(100.0, 1200.0), randf_range(100.0, 1000.0))
		var min_bound := Vector2(100.0, 100.0)
		if final_position.x < min_bound.x or final_position.y < min_bound.y or final_position.x > limit_max.x or final_position.y > limit_max.y:
			final_position = Vector2(randf_range(min_bound.x, limit_max.x), randf_range(min_bound.y, limit_max.y))

	label.play_drop_in(final_position)

	var prev := _previous_label
	if disable_prev_immediately and prev and is_instance_valid(prev):
		prev.play_disable()
	_previous_label = label
	_labels.append(label)
	var idx := int(label_data.get("num", 0))
	_label_index_map[label] = idx
	if not disable_prev_immediately:
		label.drop_in_finished.connect(_on_label_drop_finished.bind(prev))
	return label

func create_price_labels_sequential(data_array: Array[Dictionary]) -> Array[PriceLabel]:
	# 批量顺序生成：第一个立即生成，其后在前一个标签坠落动画的中点信号触发后生成
	var labels: Array[PriceLabel] = []
	if data_array.is_empty():
		return labels
	var state := {"index": 0}
	_create_next_label_in_sequence(data_array, labels, state)
	return labels

func _create_next_label_in_sequence(data_array: Array[Dictionary], labels: Array[PriceLabel], state: Dictionary) -> void:
	# 生成当前 index 的标签并连接中点推进
	var current_index := int(state["index"]) 
	if current_index >= data_array.size():
		return
	var label := create_price_label(data_array[current_index], Vector2.ZERO, false)
	labels.append(label)
	state["index"] = current_index + 1
	label.drop_in_midway.connect(_on_label_drop_midway.bind(data_array, labels, state))

func _on_label_drop_midway(_label: PriceLabel, data_array: Array[Dictionary], labels: Array[PriceLabel], state: Dictionary) -> void:
	# 在“中点”信号触发时继续生成下一个
	_create_next_label_in_sequence(data_array, labels, state)

func _on_label_drop_finished(_label: PriceLabel, prev: PriceLabel) -> void:
	if prev and is_instance_valid(prev):
		prev.play_disable()

func remove_labels_from_index(start_index: int) -> void:
	var remaining: Array[PriceLabel] = []
	for label in _labels:
		var idx := int(_label_index_map.get(label, 0))
		if idx >= start_index:
			_label_index_map.erase(label)
			label.queue_free()
		else:
			remaining.append(label)
	_labels = remaining
	_previous_label = _labels.back() if _labels.is_empty() == false else null

func enable_last_label() -> void:
	if _previous_label and is_instance_valid(_previous_label):
		_previous_label.play_enable()

func disable_last_label() -> void:
	if _previous_label and is_instance_valid(_previous_label):
		_previous_label.play_disable()
