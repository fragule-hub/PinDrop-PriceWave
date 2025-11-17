# 商品展示组件
# 用于显示商品图标、名称、数量以及悬浮描述信息
extends Control
class_name Goods

# UI节点引用
@onready var goods_icon: TextureRect = $Container/Icon
@onready var goods_label: Label = $Container/Label
@onready var progress_bar: ProgressBar = $Container/ProgressBar
@onready var amount_label: Label = $Container/Amount

@onready var label_container: PanelContainer = $LabelContainer
@onready var description_label: RichTextLabel = $LabelContainer/Description

# 商品数据属性
@export var goods_stat: GoodsStat : set = _set_goods_stat, get = _get_goods_stat

# 状态变量
var _is_hovering: bool = false          # 鼠标是否悬停
var _reached_max: bool = false          # 进度条是否达到最大值

# 内部商品数据
var _goods_stat: GoodsStat

# 设置商品数据
func _set_goods_stat(value: GoodsStat) -> void:
	_goods_stat = value
	if is_node_ready():
		_update_self()

# 获取商品数据
func _get_goods_stat() -> GoodsStat:
	return _goods_stat

# 节点初始化
func _ready() -> void:
	label_container.visible = false
	progress_bar.value = 0
	set_physics_process(false)
	_update_self()
	resized.connect(_update_font_size)

# 物理帧处理 - 处理悬浮描述框的进度条动画
func _physics_process(delta: float) -> void:
	if not _is_hovering or _reached_max:
		return
	
	# 增加进度条值
	progress_bar.value += delta * 120
	
	# 检查是否达到最大值
	if progress_bar.value >= progress_bar.max_value:
		progress_bar.value = progress_bar.max_value
		_reached_max = true
		label_container.visible = true
		label_container.global_position = get_global_mouse_position()
		set_physics_process(false)

# 更新UI显示
func _update_self() -> void:
	if _goods_stat == null:
		return
	
	# 设置商品图标和名称
	goods_icon.texture = _goods_stat.icon
	goods_label.text = _goods_stat.name
	
	# 更新字体大小
	_update_font_size()
	
	# 设置商品描述
	if description_label != null:
		description_label.text = _goods_stat.get_bbcode_introduction()

# 根据组件宽度调整字体大小
func _update_font_size() -> void:
	var width = size.x
	var font_size = width / 8
	goods_label.add_theme_font_size_override("font_size", font_size)

# 鼠标进入事件
func _on_mouse_entered() -> void:
	if not _is_hovering:
		_is_hovering = true
		if not _reached_max:
			set_physics_process(true)

# 鼠标离开事件
func _on_mouse_exited() -> void:
	# 若鼠标仍在描述框上，则不视为离开
	if label_container.visible:
		var rect := label_container.get_global_rect()
		if rect.has_point(get_global_mouse_position()):
			return
	
	_reset_hover_state()

# 鼠标离开描述框事件
func _on_label_container_mouse_exited() -> void:
	# 鼠标离开描述框时，隐藏描述框
	_reset_hover_state()

# 重置悬停状态
func _reset_hover_state() -> void:
	_is_hovering = false
	_reached_max = false
	progress_bar.value = 0
	label_container.visible = false
	set_physics_process(false)

# 设置商品数量显示
func need_amount(value: int) -> void:
	if value != 0:
		# 如果节点已准备好，直接设置
		if is_node_ready() and amount_label != null:
			amount_label.text = str(value)
			if not amount_label.visible:
				amount_label.visible = true
		else:
			# 如果节点还没准备好，延迟设置
			await ready
			if amount_label != null:
				amount_label.text = str(value)
				if not amount_label.visible:
					amount_label.visible = true
