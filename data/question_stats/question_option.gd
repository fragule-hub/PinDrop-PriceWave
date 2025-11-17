# 问题选项资源类
# 定义问题选项的各种配置，包括优惠券、商品、遗物的发放规则
extends Resource
class_name QuestionOption

# 选项类型枚举
enum QuestionOptionEnum { 否, 随机, 指定 }

# 基础选项配置
@export var enabled: bool = false                    # 是否启用此选项
@export var text: String = ""                        # 选项显示文本

@export_category("优惠券")
@export var is_coupon: QuestionOptionEnum = QuestionOptionEnum.否  # 优惠券发放类型
@export var coupons: Array[CouponStat] = []           # 指定发放的优惠券列表
@export var coupon_rarity_offset: int = 0            # 优惠券稀有度偏移值

@export_category("商品")
@export var is_goods: QuestionOptionEnum = QuestionOptionEnum.否      # 商品发放类型
@export var goods: Array[GoodsStat] = []            # 指定发放的商品列表
@export var goods_rarity: int = 1                     # 商品稀有度 (1-5)
@export var goods_count: int = 1                     # 商品数量
@export var goods_type: GoodsStat.GoodsType = GoodsStat.GoodsType.食品  # 商品类型筛选

@export_category("遗物")
@export var is_relics: QuestionOptionEnum = QuestionOptionEnum.否    # 遗物发放类型
@export var relics: Array[RelicStat] = []           # 指定发放的遗物列表
@export var relics_rarity: RelicStat.Rarity = RelicStat.Rarity.普通  # 遗物稀有度
@export var relics_count: int = 1                   # 遗物数量
