# 问题场景管理器
# 负责显示问题描述、处理选项点击、管理弹窗交互
extends Node2D
class_name Question

# UI节点引用
@onready var description_label: RichTextLabel = %RichTextLabel
@onready var option_button_1: MovableButton = $Panel/MovableButton1
@onready var option_button_2: MovableButton = $Panel/MovableButton2
@onready var option_button_3: MovableButton = $Panel/MovableButton3
@onready var coupon_popup_window: PanelContainer = $CouponPopWindow
@onready var goods_popup_window: PanelContainer = $GoodsPopWindow
@onready var relic_popup_window: PanelContainer = $RelicPopWindow

# 问题数据
@export var question_stat: QuestionStat
var _current_question_stat: QuestionStat

# 设置问题数据
func set_question_stat(value: QuestionStat) -> void:
	_current_question_stat = value
	update_ui()

# 获取问题数据
func get_question_stat() -> QuestionStat:
	return _current_question_stat

# 节点初始化
func _ready() -> void:
	# 初始化时如果有question_stat，则更新UI
	if question_stat:
		set_question_stat(question_stat)
	
	# 连接弹窗的确认信号
	if coupon_popup_window:
		coupon_popup_window.confirmed.connect(_on_coupon_confirmed)
	if goods_popup_window:
		goods_popup_window.confirmed.connect(_on_goods_confirmed)
	if relic_popup_window:
		relic_popup_window.confirmed.connect(_on_relic_confirmed)

# 优惠券确认回调
func _on_coupon_confirmed() -> void:
	# 优惠券确认后的处理
	pass

# 商品确认回调
func _on_goods_confirmed() -> void:
	# 商品确认后的处理
	pass

# 遗物确认回调
func _on_relic_confirmed() -> void:
	# 遗物确认后的处理
	pass

# 更新UI显示
func update_ui() -> void:
	if not _current_question_stat:
		return
	
	# 更新描述文本
	description_label.text = _current_question_stat.info_text
	
	# 更新按钮状态
	update_button(option_button_1, _current_question_stat.option_1)
	update_button(option_button_2, _current_question_stat.option_2)
	update_button(option_button_3, _current_question_stat.option_3)

func update_button(button: MovableButton, option: QuestionOption) -> void:
	if not option or not option.enabled:
		button.visible = false
		return
	
	button.visible = true
	# 设置按钮文本
	button.text = option.text
	# 直接更新RichTextLabel以确保文本立即显示
	var rich_text_label = button.get_node_or_null("SubViewport/PanelContainer/RichTextLabel")
	if rich_text_label:
		rich_text_label.text = option.text.replace("\\n", "\n")


func _on_movable_button_1_button_is_clicked(_button: Button) -> void:
	if _current_question_stat and _current_question_stat.option_1:
		handle_option(_current_question_stat.option_1)

func _on_movable_button_2_button_is_clicked(_button: Button) -> void:
	if _current_question_stat and _current_question_stat.option_2:
		handle_option(_current_question_stat.option_2)

func _on_movable_button_3_button_is_clicked(_button: Button) -> void:
	if _current_question_stat and _current_question_stat.option_3:
		handle_option(_current_question_stat.option_3)

# 处理选项逻辑
func handle_option(option: QuestionOption) -> void:
	# 处理优惠券
	if option.is_coupon == QuestionOption.QuestionOptionEnum.随机:
		# 使用优惠券弹窗的随机生成方法
		if option.coupon_rarity_offset != 0:
			# 使用带稀有度偏移的随机生成
			coupon_popup_window.toggle(true)
			coupon_popup_window.generate_coupons_random_with_rarity(option.coupon_rarity_offset)
		else:
			# 使用默认随机生成
			coupon_popup_window.toggle(true)
			coupon_popup_window.generate_coupons_random()
		await coupon_popup_window.confirmed
	elif option.is_coupon == QuestionOption.QuestionOptionEnum.指定:
		# 生成指定的优惠券
		if option.coupons.size() > 0:
			# 显示优惠券弹窗并生成指定优惠券
			coupon_popup_window.toggle(true)
			coupon_popup_window.generate_coupons_specific(option.coupons)
			await coupon_popup_window.confirmed
	
	# 处理商品
	if option.is_goods == QuestionOption.QuestionOptionEnum.随机:
		# 使用商品弹窗的随机生成方法
		goods_popup_window.toggle(true)
		goods_popup_window.generate_goods_random(option.goods_rarity, option.goods_count, option.goods_type)
		await goods_popup_window.confirmed
	elif option.is_goods == QuestionOption.QuestionOptionEnum.指定:
		# 生成指定的商品
		if option.goods.size() > 0:
			# 显示商品弹窗并生成指定商品
			goods_popup_window.toggle(true)
			goods_popup_window.generate_goods_specific(option.goods)
			await goods_popup_window.confirmed
	
	# 处理遗物
	if option.is_relics == QuestionOption.QuestionOptionEnum.随机:
		# 使用遗物弹窗的随机生成方法
		relic_popup_window.toggle(true)
		relic_popup_window.generate_relics_random(option.relics_rarity, option.relics_count)
		await relic_popup_window.confirmed
	elif option.is_relics == QuestionOption.QuestionOptionEnum.指定:
		# 生成指定的遗物
		if option.relics.size() > 0:
			# 显示遗物弹窗并生成指定遗物
			relic_popup_window.toggle(true)
			relic_popup_window.generate_relics_specific(option.relics)
			await relic_popup_window.confirmed
