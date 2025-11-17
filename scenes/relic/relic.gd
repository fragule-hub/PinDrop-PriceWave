extends Control
class_name Relic

@onready var icon: TextureRect = $Container/Icon
@onready var label: Label = $Container/Label
@onready var label_container: PanelContainer = $LabelContainer
@onready var description: RichTextLabel = $LabelContainer/Description
@onready var progress_bar: ProgressBar = $Container/ProgressBar

@export var relic_stat: RelicStat : set = _set_relic_stat, get = _get_relic_stat

var _is_hovering: bool = false
var _reached_max: bool = false

var _relic_stat: RelicStat

# 定义不同稀有度对应的颜色
const RARITY_COLORS = {
	RelicStat.Rarity.普通: Color("#01796f"),
	RelicStat.Rarity.稀有: Color("#d4af37"),
	RelicStat.Rarity.罕见: Color("#800020")
}

func _set_relic_stat(value: RelicStat) -> void:
	_relic_stat = value
	if is_node_ready():
		_update_self()

func _get_relic_stat() -> RelicStat:
	return _relic_stat

func _ready() -> void:
	label_container.visible = false
	progress_bar.value = 0
	set_physics_process(false)
	_update_self()
	resized.connect(_update_font_size)
	GlobalRelic.relic_triggered.connect(_on_relic_triggered)

func _update_self() -> void:
	if _relic_stat == null:
		return
	icon.texture = _relic_stat.icon
	label.text = _relic_stat.name
	_update_font_size()
	if description != null:
		description.text = _relic_stat.description
	
	# 根据稀有度设置 ProgressBar 背景颜色
	var rarity = _relic_stat.rarity
	if RARITY_COLORS.has(rarity):
		var stylebox = progress_bar.get_theme_stylebox("background").duplicate() as StyleBoxFlat
		stylebox.bg_color = RARITY_COLORS[rarity]
		progress_bar.add_theme_stylebox_override("background", stylebox)

func _update_font_size() -> void:
	var width = size.x
	var font_size = width / 8
	label.add_theme_font_size_override("font_size", font_size)

func _physics_process(delta: float) -> void:
	if not _is_hovering or _reached_max:
		return
	progress_bar.value += delta * 120
	if progress_bar.value >= progress_bar.max_value:
		progress_bar.value = progress_bar.max_value
		_reached_max = true
		label_container.visible = true
		label_container.global_position = get_global_mouse_position()
		set_physics_process(false)

func _on_mouse_entered() -> void:
	if not _is_hovering:
		_is_hovering = true
		if not _reached_max:
			set_physics_process(true)


func _on_mouse_exited() -> void:
	# 若鼠标仍在描述框上，则不视为离开
	if label_container.visible:
		var rect := label_container.get_global_rect()
		if rect.has_point(get_global_mouse_position()):
			return
	_is_hovering = false
	_reached_max = false
	progress_bar.value = 0
	label_container.visible = false
	set_physics_process(false)


func _on_label_container_mouse_exited() -> void:
	# 鼠标离开描述框时，隐藏描述框
	_is_hovering = false
	_reached_max = false
	progress_bar.value = 0
	label_container.visible = false
	set_physics_process(false)

func _on_relic_triggered(stat: RelicStat) -> void:
	if _relic_stat == null:
		return
	if stat == _relic_stat:
		_play_trigger_anim()

func _play_trigger_anim() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if icon != null:
		tw.tween_property(icon, "modulate", Color(icon.modulate.r, icon.modulate.g, icon.modulate.b, 0.6), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if icon != null:
		tw.tween_property(icon, "modulate", Color(icon.modulate.r, icon.modulate.g, icon.modulate.b, 1.0), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
