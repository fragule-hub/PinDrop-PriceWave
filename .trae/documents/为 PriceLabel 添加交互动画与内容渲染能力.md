## 目标
- 跟随鼠标倾斜 + 拖拽交互（参考 MovableButton 的实现）。
- 线条绘制动画：逐步绘制 `Line1` 与 `Line2`，并配合 `PanelContainer` 调色实现“禁用/解禁”动画。
- 坠落入场动画：初始隐藏，阴影缩小；从上方下落并放大阴影，落地轻微回弹。
- 内容渲染：接收 `{num:int, text:string}` 字典，渲染带圆圈序号与文本到 RichTextLabel。

## 现状确认
- PriceLabel 结构：`scenes/pricelabel/price_label.tscn` 已包含 `Shadow/Display/SubViewport/PanelContainer/RichTextLabel/Number/Line1/Line2`，Display 使用 `Faux 3D Perspective.gdshader`。
- PriceLabel 脚本：`scenes/pricelabel/price_label.gd:1-10` 仅声明节点引用，尚未实现交互与动画。
- MovableButton 提供成熟的倾斜与拖拽逻辑可直接复用（`scenes/movable_button/movable_button.gd`）。

## 修改方案
### 倾斜与拖拽
- 在 `price_label.gd` 新增：
  - `@onready var shader_material: ShaderMaterial = display.material as ShaderMaterial`
  - 倾斜参数与 Tween：`MAX_YAW_DEG/MAX_PITCH_DEG/TILT_TWEEN_TIME/_tilt_tween`
  - 拖拽状态与 Tweens：`_left_pressed/_drag_active/_click_candidate/_press_pos/_drag_offset/_tween/_shadow_tween`
  - 阴影样式副本：重复 MovableButton 的 `_init_shadow_style()` 逻辑，避免共享 StyleBox 被直接改动
  - 事件：`_on_mouse_entered/_on_mouse_exited/_on_gui_input/_process`
  - 倾斜与跟随方法：`_update_tilt_from_mouse/_animate_tilt_to_current_pos/_animate_tilt_to_zero/_set_rot_y/_set_rot_x/_follow_mouse/_on_drag_start/_on_drag_end/_set_shadow_size/_is_mouse_inside_display`

### 线条绘制 + 禁用/解禁
- 在 `price_label.gd` 添加线条动画方法：
  - `_animate_line_draw(line: Line2D, start: Vector2, end: Vector2, duration: float)` 使用 `tween_method` 按进度设置 `line.points = [start, lerp(start,end,t)]`
  - `play_disable()`：
    - 调灰 `panel_container.modulate`（或主题样式调色）
    - 显示两条线并调用绘制动画
  - `play_enable()`：
    - 反向绘制（进度从 1 降到 0）或淡出后隐藏
    - 恢复 `panel_container.modulate`

### 坠落入场
- 在 `price_label.gd` 添加：
  - `play_drop_in()`：
    - 初始：`display.visible=false`，`shadow.scale` 小（如 `0.6`），`self.global_position.y` 设为目标上方一定距离
    - 开始播放：`display.visible=true`，两段 Tween：
      - 位移：从上方落到目标位置，使用 `EASE_OUT`，结束一小段回弹（向上稍许再回到位）
      - 阴影：随位移在第一段增大到正常，回弹段恢复正常大小

### 内容渲染
- 在 `price_label.gd` 添加：
  - `set_content(dict: Dictionary)`：
    - `dict.num`：将 `int` 转换为圆圈数字（1..20 使用 `U+2460..U+2473`），如 `1 → ①`，赋值到 `number.text`
    - `dict.text`：赋值到 `rich_text_label.text`，保留已有 `bbcode_enabled` 与字体设置

## 事件与输入
- PriceLabel 根节点需接收输入：确保 `mouse_filter` 默认允许，子节点的 `mouse_filter` 在 tscn 已设为忽略，不会抢占输入。

## 文件改动
- `scenes/pricelabel/price_label.gd`：新增完整交互与动画实现（不改动外部接口）。
- `scenes/pricelabel/price_label.tscn`：若需调整初始可见性或样式（尽量通过代码设置，避免场景结构改动）。

## 验证
- 交互：鼠标进入倾斜、拖拽拾取与释放、阴影大小变化正常。
- 禁用/解禁：两条线按动画绘制/撤销，面板颜色变化与状态一致。
- 入场：初始隐藏，坠落+回弹+阴影放大效果自然。
- 内容：传入 `{num:1, text:"示例"}` 渲染为 `①` 与文本，`rich_text_label` 居中显示。

确认后我将按上述方案实现，并保证与现有风格一致、可读性高，必要处添加简明注释。