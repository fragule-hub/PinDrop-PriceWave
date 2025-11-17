extends Node2D
class_name Battle

# 战斗主场景入口
# - 初始化摇摆物体与基础价格标签
# - 监听价格计算器的步骤新增与重算信号，驱动 PriceLabel 的创建与重建

@export var goods_array: Array[GoodsStat]

@onready var shake_body_maker: ShakeBodyMaker = $ShakeBodyMaker
@onready var price_calculator: PriceCalculator = $PriceCalculator
@onready var price_label_maker: PriceLabelMaker = $PriceLabelMaker

func _ready() -> void:
	shake_body_maker.create_shake_body(goods_array, Vector2(680, 300))
	var price_map := price_calculator.build_price_dict(goods_array)
	var label_data_array: Array[Dictionary] = []
	var price_keys := price_map.keys()
	price_keys.sort()
	for k in price_keys:
		var price: float = price_map[k]
		var title := "原价: " if int(k) == 1 else "特价: "
		label_data_array.append({"num": int(k), "text": title + str(price)})
	price_label_maker.create_price_labels_sequential(label_data_array)
	price_calculator.price_step_added.connect(_on_price_step_added)
	price_calculator.price_labels_rebuild.connect(_on_price_labels_rebuild)
	_configure_coupon_container_for_battle()

func _on_price_step_added(index: int, text: String, _price: float) -> void:
	# 单次新增步骤：立即禁用上一个标签，再创建新的可用标签
	var step_label_num := price_calculator.base_count + index
	price_label_maker.create_price_label({"num": step_label_num, "text": text}, Vector2.ZERO, true)

func _on_price_labels_rebuild(from_index: int, new_steps: Array) -> void:
	# 重算：释放从起始编号起的标签，若有新步骤则顺序重建，否则启用最后一个保留标签
	var start_label_num := price_calculator.base_count + from_index
	price_label_maker.remove_labels_from_index(start_label_num)
	var label_data_array: Array[Dictionary] = []
	for step in new_steps:
		var idx := price_calculator.base_count + int(step.get("index", from_index))
		var formula := str(step.get("formula", ""))
		label_data_array.append({"num": idx, "text": formula})
	if not label_data_array.is_empty():
		price_label_maker.create_price_labels_sequential(label_data_array)
	else:
		price_label_maker.enable_last_label()

func _configure_coupon_container_for_battle() -> void:
	var cc: CouponContainer = get_node_or_null("Player/优惠券/SubViewport/Container/CouponContainer") as CouponContainer
	if cc:
		cc.is_battle = true
		cc.is_check_backpack = false

func _on_成交_button_is_clicked(_btn: Button) -> void:
	for gs in goods_array:
		if gs:
			GlobalGoods.add_requested.emit(gs, 1)
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_返回_button_is_clicked(_btn: Button) -> void:
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
