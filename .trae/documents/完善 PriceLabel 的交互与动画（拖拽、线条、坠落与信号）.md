## 目标
- 纠正拖拽未生效的问题，使 PriceLabel 可跟随鼠标移动。
- 修复线条绘制/擦除的可见性切换，确保禁用/解禁动画可靠。
- 增强坠落入场动画，加入中途与完成信号，效果更丰富。
- 保持现有倾斜效果，完善内容设置接口。

## 问题定位
- 拖拽未生效：当前实现使用 `_on_gui_input(event)`，但 Control 的输入回调应为 `_gui_input(event)`，导致逻辑未被调用。
- 线条绘制：擦除动画结束后将 `Line2D.visible=false`，绘制动画需要显式恢复 `visible=true`（将确保绘制入口强制可见）。
- 坠落动画：现有版本简单，缺少中途/完成信号与更自然的阴影/回弹；参考你提供的方案进行增强。

## 修改方案
### 拖拽交互
- 将 `_on_gui_input(event)` 更名为 `_gui_input(event)`；其余拖拽状态管理逻辑保持不变。
- 确保根 Control 默认接收 GUI 输入；子节点 `Display/PanelContainer` 已设为忽略输入，不会拦截事件。

### 线条动画
- 绘制：在 `_animate_line_draw(line, duration)` 开始时 `line.visible = true`（已存在，保留并确认）。
- 擦除：结束回调后 `line.visible = false`（已实现，保留）。
- 提供 `play_disable()`/`play_enable()` 一键入口；禁用时调灰 `PanelContainer` 并绘制两条线，解禁时撤销线条并恢复颜色。

### 坠落入场（增强版）
- 新增信号：`drop_in_midway(label: PriceLabel)`、`drop_in_finished(label: PriceLabel)`。
- 新增方法：`play_drop_in_advanced()`
  - 以 `Display` 的目标局部位置为落点；从视口高度之外上方开始下落。
  - 阴影初始缩小并延迟显示，伴随下落逐渐变大；加入轻微超冲与回弹；着地脉冲缩放。
  - 在总时长的 50% 发出 `drop_in_midway`，结束时发出 `drop_in_finished`。
  - 阴影样式使用 `StyleBoxFlat.duplicate()` 避免共享资源被修改。

### 内容设置
- 保留 `set_content({num:int,text:string})`；确保圆圈数字与文本渲染稳定。

## 变更范围
- 仅修改 `scenes/pricelabel/price_label.gd`，不改场景结构与其它脚本。

## 验证
- 拖拽：按住左键超过阈值后跟随鼠标移动；拾起/释放时缩放过渡与阴影尺寸变化正常。
- 线条：禁用时两条线绘制出现，解禁时撤销并隐藏；面板颜色变化正确。
- 入场：显示从上方坠落，阴影延迟出现并扩大，回弹与脉冲效果自然；中途与完成信号按时发出。
- 内容：传入 `{num:1,text:"示例"}` 显示为 `①` 与文本。