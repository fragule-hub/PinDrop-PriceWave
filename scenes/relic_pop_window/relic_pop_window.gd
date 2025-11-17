# 遗物弹窗管理器
# 负责显示遗物选择界面，支持随机生成和指定遗物
extends PanelContainer
class_name RelicPopWindow
# 确认信号
signal confirmed

# UI容器引用
@onready var relic_container: RelicContainer = $VBoxContainer/RelicContainer

# 当前显示的遗物列表
var _current_relics: Array[RelicStat] = []

# 节点初始化
func _ready() -> void:
	toggle(false)

# 切换弹窗显示状态
func toggle(visible_state: bool) -> void:
	visible = visible_state

# 随机生成遗物
func generate_relics_random(rarity: RelicStat.Rarity, count: int) -> void:
	# 获取所有可用遗物
	var available_relics = GlobalRelic.all_relic_stats
	var filtered_relics: Array[RelicStat] = []
	var current_rarity_int = int(rarity)  # 将枚举转换为整数进行处理
	var selected_relics: Array[RelicStat] = []
	var remaining_count = count
	
	# 检查是否有可用遗物
	if available_relics.size() == 0:
		print("警告：没有可用的遗物")
		return
	
	# 循环直到找到足够的遗物或没有更多遗物可选
	while remaining_count > 0:
		filtered_relics.clear()
		
		# 根据当前稀有度筛选未拥有的遗物
		for relic_stat in available_relics:
			if int(relic_stat.rarity) <= current_rarity_int and not GlobalRelic.has_relic(relic_stat):
				filtered_relics.append(relic_stat)
		
		# 如果有可用遗物，随机选择
		if filtered_relics.size() > 0:
			var random_index = randi() % filtered_relics.size()
			selected_relics.append(filtered_relics[random_index])
			filtered_relics.remove_at(random_index)
			remaining_count -= 1
		else:
			# 当前稀有度没有可用遗物，提升稀有度
			current_rarity_int += 1
			
			# 如果稀有度超过最大值且还没有找到任何遗物，跳出循环
			if current_rarity_int > int(RelicStat.Rarity.罕见) and selected_relics.size() == 0:
				break
			
			# 如果已经提升了很多稀有度但仍然找不到遗物，跳出循环
			if current_rarity_int > int(RelicStat.Rarity.罕见) + 2:
				break
	
	_current_relics = selected_relics
	
	# 显示遗物
	if relic_container and relic_container.relic_spawner:
		if _current_relics.size() > 0:
			relic_container.relic_spawner.spawn_relics_batch_array(_current_relics)
		else:
			print("警告：没有选中任何遗物")
	else:
		print("警告：遗物容器或生成器未找到")

# 显示指定遗物
func generate_relics_specific(relics_list: Array[RelicStat]) -> void:
	_current_relics = relics_list
	
	# 显示遗物
	if relic_container and relic_container.relic_spawner:
		relic_container.relic_spawner.spawn_relics_batch_array(_current_relics)

# 确认按钮点击事件
func _on_确认_pressed() -> void:
	# 将遗物添加到玩家背包
	for relic_stat in _current_relics:
		GlobalRelic.add_relic(relic_stat)
	
	confirmed.emit()
	# 清空当前遗物列表
	_current_relics.clear()
	toggle(false)  # 隐藏弹窗
