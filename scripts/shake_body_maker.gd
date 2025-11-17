extends Node
class_name ShakeBodyMaker

const SHAKE_BODY := preload("res://scenes/shake_body/shake_body.tscn")

func create_shake_body(goods_arrat: Array[GoodsStat], location: Vector2) -> Array[ShakeBody]:
	var shake_bodies: Array[ShakeBody] = []
	
	if goods_arrat.size() == 0:
		return shake_bodies
	
	# 如果只有一个商品，直接生成
	if goods_arrat.size() == 1:
		var shake_body = _create_single_shake_body(goods_arrat[0], location, 1.0)
		shake_bodies.append(shake_body)
		return shake_bodies
	
	# 如果有多个商品，按比例缩小并分布在不同位置
	var positions = _calculate_positions(location, goods_arrat.size())
	
	for i in range(min(goods_arrat.size(), 4)):  # 最多生成4个
		var shake_body = _create_single_shake_body(goods_arrat[i], positions[i], 0.5)
		shake_bodies.append(shake_body)
	
	return shake_bodies

func _create_single_shake_body(goods_stat: GoodsStat, location: Vector2, scale: float) -> ShakeBody:
	var shake_body = SHAKE_BODY.instantiate()
	shake_body.goods_stat = goods_stat
	shake_body.position = location
	
	# 设置缩放
	if shake_body.has_method("set_scale"):
		shake_body.set_scale(Vector2(scale, scale))
	else:
		# 直接访问视觉节点的缩放
		var visual_node = shake_body.get_node_or_null("PanelContainer")
		if visual_node:
			visual_node.scale = Vector2(scale, scale)
	
	# 添加到全局位置（作为子节点）
	get_tree().current_scene.add_child(shake_body)
	
	return shake_body

func _calculate_positions(base_position: Vector2, count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	
	# 第一个位置：基础位置
	positions.append(base_position)
	
	if count > 1:
		# 第二个位置：朝右300px
		positions.append(base_position + Vector2(300, 0))
	
	if count > 2:
		# 第三个位置：朝下300px
		positions.append(base_position + Vector2(0, 300))
	
	if count > 3:
		# 第四个位置：朝左300px
		positions.append(base_position + Vector2(300, 300))
	
	return positions
