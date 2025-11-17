# 遗物容器管理器
# 负责管理玩家已拥有的遗物展示
extends Node
class_name RelicContainer

# 遗物生成器引用
@onready var relic_spawner: RelicSpawner = $RelicSpawner

# 节点初始化
func _ready() -> void:
	# 连接遗物所有权变化信号
	GlobalRelic.relic_ownership_changed.connect(_on_relic_ownership_changed)
	_update_relics()

# 遗物所有权变化回调
func _on_relic_ownership_changed() -> void:
	_update_relics()

# 更新遗物展示
func _update_relics() -> void:
	# 只清除遗物节点，保留RelicSpawner节点
	for child in get_children():
		if child is Relic:
			child.queue_free()
	
	# 获取玩家拥有的遗物并重新生成
	var owned_relics = GlobalRelic.get_owned_relics()
	if relic_spawner and owned_relics.size() > 0:
		relic_spawner.spawn_relics_batch_array(owned_relics)
