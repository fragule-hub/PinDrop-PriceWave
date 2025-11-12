extends Resource
class_name GoodsStat

enum GoodsType{
	食品,
	日用百货,
	电器,
	医药,
	奢侈品,
}

@export var goods_type: GoodsType
@export var price: float # 原价
@export var special_price: float # 特价

@export var level: int = 1 # 稀有度，等级

@export var icon: Texture2D # 图标
@export var name: String # 名称
@export var description: String # 描述

@export var value: float # 效果值（如果有的话）


func goods_type_to_string() -> String:
	match goods_type:
		GoodsType.食品 : return "食品"
		GoodsType.日用百货 : return "日用百货"
		GoodsType.电器 : return "电器"
		GoodsType.医药 : return "医药"
		GoodsType.奢侈品 : return "奢侈品"
	return "_"

func get_current_price() -> float:
	return price

func get_currnt_special_price() -> float:
	return special_price

func get_bbcode_introduction() -> String:
	return "[b]" + "类别：" + "[/b]" + goods_type_to_string() + "\n" \
		+ "[b]" + "名称：" + "[/b]" + name + "\n" \
		+ "[b]" + "原价：" + "[/b]" + str(get_current_price()) + "\n" \
		+ "[b]" + "描述：" + "[/b]" + description
