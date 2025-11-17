## 目标
- 保持现有功能（倾斜、拖拽、线条绘制/擦除、禁用/解禁、坠落入场、内容渲染）。
- 优化代码结构与状态管理，统一变量/函数命名，更清晰可维护。
- 增加关键注释与导出参数，便于在编辑器中调整动画与交互参数。

## 调整点
- 命名与结构：
  - 节点引用重命名：`shadow_node/display_node/panel_node/text_node/number_node/line1/line2`（原名保留引用但对外接口使用更语义化变量）。
  - 私有状态统一前缀 `_`：`_shader/_tilt_tween/_drag_tween/_shadow_tween/_left_pressed/_drag_active/_press_pos/_drag_offset`。
  - 方法命名统一动宾结构：`start_drag/end_drag/update_tilt_from_mouse/animate_tilt_to_zero/animate_line_draw/animate_line_erase/play_disable/play_enable/play_drop_in` 等。
- 导出参数：
  - 倾斜：`tilt_max_yaw_deg/tilt_max_pitch_deg/tilt_tween_time`
  - 拖拽：`drag_threshold/drag_pickup_scale/drag_tween_time`
  - 坠落：`drop_total_time/drop_overshoot/pulse_scale/pulse_time/shadow_start_scale`
  - 线条绘制时长：`line_draw_duration`
- 线条端点缓存：
  - 在 `_ready()` 缓存 `Line1/Line2` 初始两点，绘制/擦除始终使用固定端点，确保多次重复调用稳定。
- 拖拽修正：
  - 继续使用 `Control._gui_input`；在 `_process` 管理拖拽阈值与跟随鼠标。
- 坠落动画修正：
  - 阴影从目标位置开始逐渐放大；`Display` 从上方坠落；与现逻辑保持一致但参数可配置。
- 注释：
  - 为每个导出参数、核心方法与状态添加简明注释，说明用途与时序。

## 变更范围
- 仅修改 `scenes/pricelabel/price_label.gd`；不改场景结构与其它脚本。

## 验证
- 拖拽跟随、倾斜缓动正常；线条禁用/解禁动画稳定可重复；坠落动画阴影与 Display 时序正确；内容渲染圆圈序号与文本显示正确。

确认后我将按照上述方案进行重构与注释。