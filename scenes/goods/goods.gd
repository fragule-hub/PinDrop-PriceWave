extends Control
class_name Goods

@onready var goods_icon: TextureRect = $Container/Icon
@onready var goods_label: Label = $Container/Label
@onready var label_container: PanelContainer = $LabelContainer
@onready var description: RichTextLabel = $LabelContainer/Description
@onready var hover_timer: Timer = $HoverTimer

@export var goods_stat: GoodsStat : set = _set_goods_stat, get = _get_goods_stat

var _is_hovering: bool = false

var _goods_stat: GoodsStat

func _set_goods_stat(value: GoodsStat) -> void:
	_goods_stat = value
	if is_node_ready():
		_update_self()

func _get_goods_stat() -> GoodsStat:
	return _goods_stat

func _ready() -> void:
	label_container.visible = false
	_update_self()

func _on_hover_timer_timeout() -> void:
	label_container.visible = true
	label_container.global_position = get_global_mouse_position()

func _update_self() -> void:
	if _goods_stat == null:
		return
	goods_icon.texture = _goods_stat.icon
	goods_label.text = _goods_stat.name
	if description != null:
		description.text = _goods_stat.get_bbcode_introduction()


func _on_mouse_entered() -> void:
	if not _is_hovering:
		_is_hovering = true
		hover_timer.start()


func _on_mouse_exited() -> void:
	# 若鼠标仍在描述框上，则不视为离开
	if label_container.visible:
		var rect := label_container.get_global_rect()
		if rect.has_point(get_global_mouse_position()):
			return
	_is_hovering = false
	hover_timer.stop()
	label_container.visible = false


func _on_label_container_mouse_exited() -> void:
	# 鼠标离开描述框时，隐藏描述框
	_is_hovering = false
	hover_timer.stop()
	label_container.visible = false
