extends Node
class_name RelicSpawner

signal relic_spawner(relic: Relic)

const RELIC = preload("res://scenes/relic/relic.tscn")

@export var container: Node

func spawn_relic(relic_stat: RelicStat) -> Relic:
	var relic: Relic = RELIC.instantiate()
	relic.relic_stat = relic_stat
	
	if container:
		container.add_child(relic)
	else:
		add_child(relic)
	
	relic_spawner.emit(relic)
	return relic

func spawn_relics_batch_array(relic_stats: Array[RelicStat]):
	for relic_stat in relic_stats:
		spawn_relic(relic_stat)
