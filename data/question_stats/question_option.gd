extends Resource
class_name QuestionOption

enum QuestionCouponOption { 否, 随机, 指定 }

@export var enabled: bool = false
@export var text: String = ""

@export_category("优惠券")
@export var is_coupon: QuestionCouponOption = QuestionCouponOption.否
@export var coupons: Array[CouponStat] = [] # 如果指定发放优惠券

@export_category("商品")
@export var is_goods: bool = false
@export var goods: Array[GoodsStat] = []

@export_category("遗物")
@export var is_relics: bool = false
@export var relics: Array[RelicStat] = []
