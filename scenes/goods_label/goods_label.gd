extends Button
class_name GoodsLabel

## 商品标签按钮：显示商品图标、名称、原价/特价与限时倒计时
## 通过 `goods_stat` 驱动 UI；使用内部 `Timer` 每秒刷新。

# 商品数据（带 get/set）
@export var goods_stat: GoodsStat : set = _set_goods_stat, get = _get_goods_stat
var _goods_stat: GoodsStat

# 限时小时枚举（8、16、24）
enum TimeLimit { HOURS_8 = 8, HOURS_16 = 16, HOURS_24 = 24 }
@export var time_limit: TimeLimit = TimeLimit.HOURS_8

@onready var icon_rect: TextureRect = %图标
@onready var description_label: RichTextLabel = %描述
@onready var time_label: RichTextLabel = %时间

var _remaining_hours: int = 0
var _remaining_minutes: int = 0
var _countdown_timer: Timer

func _ready() -> void:
	_refresh_content()
	_init_time_from_limit()
	_refresh_time_label()

	_countdown_timer = Timer.new()
	_countdown_timer.wait_time = 1.0
	_countdown_timer.one_shot = false
	_countdown_timer.autostart = true
	_countdown_timer.timeout.connect(_on_countdown_timeout)
	add_child(_countdown_timer)


func _tick_one_second() -> void:
	if _remaining_hours == 0 and _remaining_minutes == 0:
		if _countdown_timer:
			_countdown_timer.stop()
		return
	if _remaining_minutes == 0:
		if _remaining_hours > 0:
			_remaining_hours -= 1
			_remaining_minutes = 59
	else:
		_remaining_minutes -= 1
	_refresh_time_label()

func _init_time_from_limit() -> void:
	_remaining_hours = int(time_limit)
	_remaining_minutes = 0

func _refresh_time_label() -> void:
	if time_label:
		time_label.text = "%d:%02d" % [_remaining_hours, _remaining_minutes]

func _on_countdown_timeout() -> void:
	_tick_one_second()

func _set_goods_stat(value: GoodsStat) -> void:
	_goods_stat = value
	if is_node_ready():
		_refresh_content()

func _get_goods_stat() -> GoodsStat:
	return _goods_stat

func _on_toggled(toggled_on: bool) -> void:
	match toggled_on:
		true : self.modulate = Color8(255,215,0,100)
		false : self.modulate = Color(1,1,1,1)
func _refresh_content() -> void:
	if _goods_stat == null:
		return
	if icon_rect:
		icon_rect.texture = _goods_stat.icon
	var name_text := _goods_stat.name
	var price_text := str(_goods_stat.get_current_price())
	var special_text := str(_goods_stat.get_currnt_special_price())
	var desc_text := _goods_stat.description
	if description_label:
		description_label.text = name_text + "：原价" + price_text + \
			"，[pulse freq=1.0 color=red ease=-1.0]特价" + special_text + "[/pulse]\n" + \
			"简介: " + desc_text

func configure(stat: GoodsStat, limit: TimeLimit) -> void:
	goods_stat = stat
	time_limit = limit
	_init_time_from_limit()
	_refresh_time_label()
	if _countdown_timer:
		_countdown_timer.stop()
		_countdown_timer.start()

func set_remaining_time(hours: int, minutes: int) -> void:
	_remaining_hours = max(hours, 0)
	_remaining_minutes = clamp(minutes, 0, 59)
	_refresh_time_label()
	if _countdown_timer:
		if _remaining_hours == 0 and _remaining_minutes == 0:
			_countdown_timer.stop()
		else:
			_countdown_timer.start()

func get_remaining_time() -> Dictionary:
	return {"hours": _remaining_hours, "minutes": _remaining_minutes}
