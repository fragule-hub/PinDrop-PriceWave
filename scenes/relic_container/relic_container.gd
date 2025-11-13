extends Node
class_name RelicContainer

@onready var relic_spawner: RelicSpawner = $RelicSpawner

func _ready() -> void:
	GlobalRelic.relic_ownership_changed.connect(_on_relic_ownership_changed)
	_update_relics()

func _on_relic_ownership_changed() -> void:
	_update_relics()

func _update_relics() -> void:
	for child in get_children():
		child.queue_free()
	
	var owned_relics = GlobalRelic.get_owned_relics()
	relic_spawner.spawn_relics_batch_array(owned_relics)
