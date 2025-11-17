extends Node2D
class_name Main

@onready var daily_check_button: MovableButton = $每日签到
@onready var coupon_pop_window: PanelContainer = $每日签到/CouponPopWindow
@onready var goods_label_maker: GoodsLabelMaker = $GoodsLabelMaker
@export var  goods_label_plan: GoodsLabelPlan

enum SelectionLimitMode { BLOCK, DROP_OLDEST }
@export var max_select_count: int = 2
@export var selection_limit_mode: SelectionLimitMode = SelectionLimitMode.BLOCK
var _selected_labels: Array[GoodsLabel] = []

@onready var _coupon_container_instance: CouponContainer = get_node_or_null("Player/优惠券/SubViewport/Container/CouponContainer") as CouponContainer
@onready var spawner: GoodsSpawner = $GoodsSpawner


func _ready() -> void:
	if _coupon_container_instance:
		_coupon_container_instance.is_battle = false
		_coupon_container_instance.is_check_backpack = true
	if daily_check_button:
		daily_check_button.visible = GlobalPlayer.daily_reward_available
	GlobalPlayer.daily_reward_changed.connect(func(_available):
		if daily_check_button:
			daily_check_button.visible = _available
	)

	# 根据天数选择计划：1..8，超过8固定为8
	var plan_day: int = clamp(GlobalPlayer.days, 1, 8)
	var plan_path: String = "res://data/goods_label_plan/plans/plan_%d.tres" % plan_day
	var loaded_plan: GoodsLabelPlan = load(plan_path) as GoodsLabelPlan
	if loaded_plan != null:
		goods_label_plan = loaded_plan

	# 按时间段设置时间限制步进（上午:0，下午:1，夜晚:2）
	var time_steps: int = 0
	match GlobalPlayer.times:
		ClockPointer.TimeSegment.上午:
			time_steps = 0
		ClockPointer.TimeSegment.下午:
			time_steps = 1
		ClockPointer.TimeSegment.夜晚:
			time_steps = 2



	# 根据资源计划创建 GoodsLabel
	if goods_label_maker and goods_label_plan:
		var spawner_node: GoodsSpawner = spawner
		if spawner_node == null:
			spawner_node = coupon_pop_window.get_node_or_null("VBoxContainer/GoodsContainer/GoodsSpawner") as GoodsSpawner
		# 随机项
		if spawner_node and goods_label_plan.random_entries.size() > 0:
			for rand in goods_label_plan.random_entries:
				var stats: Array[GoodsStat] = spawner_node.select_goods_random(rand.rarity, rand.count, rand.type)
				for s in stats:
					var label_r = goods_label_maker.spawn_one(s, rand.time_limit)
					if label_r:
						label_r.toggled.connect(_on_goods_label_toggled.bind(label_r))
		# 指定项（根据时间段降低时长；低于8视为不存在）
		if goods_label_plan.specific_entries.size() > 0:
			for it in goods_label_plan.specific_entries:
				if it.goods_stat:
					var adjusted: int = _adjust_time_limit(it.time_limit, time_steps)
					if adjusted != -1:
						var label_s = goods_label_maker.spawn_one(it.goods_stat, adjusted)
						if label_s:
							label_s.toggled.connect(_on_goods_label_toggled.bind(label_s))

func _on_goods_label_toggled(toggled_on: bool, label: GoodsLabel) -> void:
	if toggled_on:
		if _selected_labels.size() >= max_select_count:
			match selection_limit_mode:
				SelectionLimitMode.BLOCK:
					label.set_pressed(false)
					return
				SelectionLimitMode.DROP_OLDEST:
					if _selected_labels.size() > 0:
						var oldest: GoodsLabel = _selected_labels[0]
						_selected_labels.remove_at(0)
						if oldest:
							oldest.set_pressed(false)
		if not _selected_labels.has(label):
			_selected_labels.append(label)
	else:
		_selected_labels.erase(label)


func _on_movable_button_button_is_clicked(_button: Button) -> void:
	coupon_pop_window.generate_coupons_random()
	coupon_pop_window.toggle(true)


func _on_coupon_pop_window_confirmed() -> void:
	GlobalPlayer.claim_daily_reward()
	if daily_check_button:
		daily_check_button.visible = GlobalPlayer.daily_reward_available

func _adjust_time_limit(limit: int, steps: int) -> int:
	var seq: Array[int] = [GoodsLabel.TimeLimit.HOURS_24, GoodsLabel.TimeLimit.HOURS_16, GoodsLabel.TimeLimit.HOURS_8]
	var i: int = seq.find(limit)
	if i == -1:
		return -1
	var new_index: int = i + steps
	if new_index >= seq.size():
		return -1
	return seq[new_index]
