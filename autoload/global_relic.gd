extends Node

signal relic_ownership_changed
signal relic_triggered(stat: RelicStat)

const RELIC_STATS_PATH = "res://data/relic_stats"

var all_relic_stats: Array[RelicStat]
var relic_ownership: Dictionary

func _ready() -> void:
	_load_all_relic_stats()
	for rs in all_relic_stats:
		if rs:
			add_relic(rs)

func _load_all_relic_stats() -> void:
	var dir = DirAccess.open(RELIC_STATS_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				pass
			elif file_name.ends_with(".tres"):
				var resource_path = RELIC_STATS_PATH.path_join(file_name)
				var relic_stat = load(resource_path) as RelicStat
				if relic_stat:
					all_relic_stats.append(relic_stat)
					relic_ownership[relic_stat] = false
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func get_owned_relics() -> Array[RelicStat]:
	var owned_relics: Array[RelicStat]
	for stat in relic_ownership:
		if relic_ownership[stat] == true:
			owned_relics.append(stat)
	return owned_relics

func has_relic(stat: RelicStat) -> bool:
	if relic_ownership.has(stat):
		return relic_ownership[stat]
	return false

func add_relic(stat: RelicStat) -> void:
	if relic_ownership.has(stat):
		relic_ownership[stat] = true
		relic_ownership_changed.emit()

func remove_relic(stat: RelicStat) -> void:
	if relic_ownership.has(stat):
		relic_ownership[stat] = false
		relic_ownership_changed.emit()

func trigger_relic(stat: RelicStat) -> void:
	if has_relic(stat):
		relic_triggered.emit(stat)

func trigger_relic_by_name(relic_name: String) -> void:
	for s in all_relic_stats:
		if s != null and s.name == relic_name:
			if has_relic(s):
				relic_triggered.emit(s)
			return
