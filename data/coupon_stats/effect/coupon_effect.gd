extends Resource
class_name CouponEffect

enum EffectType {
	减算,
	乘算,
}

@export var effect_type: EffectType
@export var value: float

func effect_to_string() -> String:
	var value_str: String
	
	match effect_type:
		EffectType.减算:
			if is_zero_approx(fmod(value, 1.0)):
				value_str = str(int(value))
			else:
				value_str = str(value)
			return "减 " + value_str
		EffectType.乘算:
			var multiplied_value = value * 10
			if is_zero_approx(fmod(multiplied_value, 1.0)):
				value_str = str(int(multiplied_value))
			else:
				value_str = str(multiplied_value)
			return "打 " + value_str + " 折"
	
	return "_"

func effect_to_math() -> String:
	var value_str: String
	if fmod(value, 1.0) == 0.0:
		value_str = str(int(value))
	else:
		value_str = str(value)
	match effect_type:
		EffectType.减算 :
			return "- " + value_str
		EffectType.乘算 :
			return "- " + str( (1 - value) * 100) + "%"
	return "_"
