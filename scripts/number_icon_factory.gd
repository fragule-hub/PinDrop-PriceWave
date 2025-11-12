extends Node
class_name NumberIconFactory

const NUMBER_TEXTURES = [
	preload("uid://cdtkt6dwl864n"), preload("uid://clrl7oyv6ysb7"), preload("uid://bf2pusf8j4mhp"),
	preload("uid://dsb765nxggysw"), preload("uid://di27lxbihvacb"), preload("uid://bcp5ncsfn3d3m"),
	preload("uid://cmxtucevrqrxg"), preload("uid://e7cq43bs5cnu"), preload("uid://rtpbaa2q0olp"),
	preload("uid://byno35al0xer6"), preload("uid://bb4bvloi6qfuk"), preload("uid://bncq02gstxryp"),
	preload("uid://bdjh66ga5wh0v"), preload("uid://bhaujyucrwemt"), preload("uid://bjculyt57fy8b"),
	preload("uid://v44066wihi2r"), preload("uid://drkimxcyubltk"), preload("uid://7vppdnaggbaq"),
	preload("uid://cuxg20ajtb5py"), preload("uid://dx1rgh8dupjvy"), preload("uid://bub3qbo7htusl"),
	preload("uid://b34rw0hon88gr"), preload("uid://bjg134xevjnmm"), preload("uid://cth8p3kjsi7ce"),
	preload("uid://d2bwkolrss3jh")
]

const INITIAL_SCALE = Vector2(2.0, 2.0)
const FINAL_SCALE = Vector2.ONE
const REMOVE_SCALE = Vector2(1.5, 1.5)

@export var create_transition_type: Tween.TransitionType = Tween.TRANS_SINE
@export var create_ease_type: Tween.EaseType = Tween.EASE_OUT
@export var remove_transition_type: Tween.TransitionType = Tween.TRANS_SINE
@export var remove_ease_type: Tween.EaseType = Tween.EASE_IN

var _created_icons: Dictionary = {}

@export var create_time: float = 0.3
@export var remove_time: float = 0.3

func create_number_icon(sequence_number: int, icon_position: Vector2, parent: Node = null) -> void:
	if _created_icons.has(sequence_number):
		print("Icon with sequence number %s already exists." % sequence_number)
		return
	
	if sequence_number < 1 or sequence_number > NUMBER_TEXTURES.size():
		print("Invalid sequence number: %s" % sequence_number)
		return
	
	var icon_texture: Texture = NUMBER_TEXTURES[sequence_number - 1]
	
	if icon_texture:
		var number_icon = TextureRect.new()
		number_icon.texture = icon_texture
		number_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		number_icon.z_index = 1
		number_icon.pivot_offset = icon_texture.get_size() / 2.0
		
		number_icon.modulate = Color(1, 1, 1, 0)
		number_icon.scale = INITIAL_SCALE
		
		if parent != null:
			parent.add_child(number_icon)
			number_icon.position = icon_position
		else:
			add_child(number_icon)
			number_icon.global_position = icon_position
		
		_created_icons[sequence_number] = number_icon
		
		_tween_and_icon_create(number_icon)

func remove_number_icon(sequence_number: int) -> void:
	if _created_icons.has(sequence_number):
		var number_icon = _created_icons[sequence_number]
		if number_icon and is_instance_valid(number_icon):
			_created_icons.erase(sequence_number)
			
			var icon_remove_tween = create_tween()
			icon_remove_tween.tween_property(number_icon, "self_modulate:a", 0.0, remove_time).set_trans(remove_transition_type).set_ease(remove_ease_type)
			icon_remove_tween.parallel().tween_property(number_icon, "scale", REMOVE_SCALE, remove_time).set_trans(remove_transition_type).set_ease(remove_ease_type)
			icon_remove_tween.tween_callback(Callable(number_icon, "queue_free"))
		else:
			_created_icons.erase(sequence_number)
	else:
		print("Icon with sequence number %s not found." % sequence_number)


func _tween_and_icon_create(texture: TextureRect) -> void:
	var icon_create_tween = create_tween()
	icon_create_tween.tween_property(texture, "modulate:a", 1.0, create_time).set_trans(create_transition_type).set_ease(create_ease_type)
	icon_create_tween.parallel().tween_property(texture, "scale", FINAL_SCALE, create_time).set_trans(create_transition_type).set_ease(create_ease_type)
