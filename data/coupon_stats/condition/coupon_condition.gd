extends Resource
class_name CouponCondition

enum ConditionType {
	无门槛,
	满减,
	专用,
}

@export var condition_type: ConditionType
@export var value: float # 满减门槛（如果有的话）
@export var goods_type: GoodsStat.GoodsType # 专用品类（如果有的话）

func condition_to_string() -> String:
	match condition_type:
		ConditionType.无门槛:
			return "无门槛券"
		ConditionType.满减:
			var value_str: String
			if is_zero_approx(fmod(value, 1.0)):
				value_str = str(int(value))
			else:
				value_str = str(value)
			return "满 " + value_str + " 可用"
		ConditionType.专用:
			return " " + goods_type_to_string(goods_type) + " 专用"
	return "_"

func goods_type_to_string(type: GoodsStat.GoodsType) -> String:
	match type:
		GoodsStat.GoodsType.食品 : return "食品"
		GoodsStat.GoodsType.日用百货 : return "日用百货"
		GoodsStat.GoodsType.电器 : return "电器"
		GoodsStat.GoodsType.医药 : return "医药"
		GoodsStat.GoodsType.奢侈品 : return "奢侈品"
	return "_"
