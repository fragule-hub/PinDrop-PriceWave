extends Node2D
class_name Battle

@export var goods_array: Array[GoodsStat]

@onready var shake_body_maker: ShakeBodyMaker = $ShakeBodyMaker
@onready var price_calculator: PriceCalculator = $PriceCalculator
@onready var price_label_maker: PriceLabelMaker = $PriceLabelMaker

func _ready() -> void:
	shake_body_maker.create_shake_body(goods_array, Vector2(680, 300))
	var price_map := price_calculator.build_price_dict(goods_array)
	var label_datas: Array[Dictionary] = []
	var keys := price_map.keys()
	keys.sort()
	for k in keys:
		var price: float = price_map[k]
		var title := "原价: " if int(k) == 1 else "特价: "
		label_datas.append({"num": int(k), "text": title + str(price)})
	price_label_maker.create_price_labels_sequential(label_datas)
	price_calculator.price_step_added.connect(_on_price_step_added)
	price_calculator.price_labels_rebuild.connect(_on_price_labels_rebuild)

func _on_price_step_added(index: int, text: String, _price: float) -> void:
	var label_num := price_calculator.base_count + index
	price_label_maker.create_price_label({"num": label_num, "text": text}, Vector2.ZERO, true)

func _on_price_labels_rebuild(from_index: int, new_steps: Array) -> void:
	var start_label_num := price_calculator.base_count + from_index
	price_label_maker.remove_labels_from_index(start_label_num)
	var label_datas: Array[Dictionary] = []
	for step in new_steps:
		var idx := price_calculator.base_count + int(step.get("index", from_index))
		var formula := str(step.get("formula", ""))
		label_datas.append({"num": idx, "text": formula})
	if not label_datas.is_empty():
		price_label_maker.create_price_labels_sequential(label_datas)
	else:
		price_label_maker.enable_last_label()
