extends Control
class_name Goods

@onready var goods_icon: TextureRect = $Container/Icon
@onready var goods_label: Label = $Container/Label
@onready var progress_bar: ProgressBar = $Container/ProgressBar
@onready var amount: Label = $Container/Amount

@onready var label_container: PanelContainer = $LabelContainer
@onready var description: RichTextLabel = $LabelContainer/Description

@export var goods_stat: GoodsStat : set = _set_goods_stat, get = _get_goods_stat

var _is_hovering: bool = false
var _reached_max: bool = false

var _goods_stat: GoodsStat

func _set_goods_stat(value: GoodsStat) -> void:
	_goods_stat = value
	if is_node_ready():
		_update_self()

func _get_goods_stat() -> GoodsStat:
	return _goods_stat

func _ready() -> void:
	label_container.visible = false
	progress_bar.value = 0
	set_physics_process(false)
	_update_self()
	resized.connect(_update_font_size)

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

func _update_self() -> void:
	if _goods_stat == null:
		return
	goods_icon.texture = _goods_stat.icon
	goods_label.text = _goods_stat.name
	_update_font_size()
	if description != null:
		description.text = _goods_stat.get_bbcode_introduction()

func _update_font_size() -> void:
	var width = size.x
	var font_size = width / 8
	goods_label.add_theme_font_size_override("font_size", font_size)

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

func need_amount(value: int) -> void:
	if value != 0:
		amount.text = str(value)
		if not amount.visible:
			amount.visible = true
