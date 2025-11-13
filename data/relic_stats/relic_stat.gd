extends Resource
class_name RelicStat

enum Rarity { 普通, 稀有, 罕见 }

@export var icon: Texture2D
@export var name: String
@export var rarity: Rarity
@export var description: String

# 数值参数（按需使用）
@export var parameter1: float = 0.0
@export var parameter2: float = 0.0

func rarity_to_string() -> String:
	match rarity:
		Rarity.普通: return "普通"
		Rarity.稀有: return "稀有"
		Rarity.罕见: return "罕见"
	return "_"

func get_bbcode_introduction() -> String:
	return "[b]" + "名称：" + "[/b]" + name + "\n" \
		 + "[b]" + "稀有度：" + "[/b]" + rarity_to_string() + "\n" \
		 + "[b]" + "描述：" + "[/b]" + description
