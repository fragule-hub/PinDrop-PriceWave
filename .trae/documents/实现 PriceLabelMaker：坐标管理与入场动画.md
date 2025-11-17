## 目标
- 通过一个 Maker 节点实例化 `PriceLabel` 并作为其子节点。
- 接收两个参数：
  - `data: {num:int, text:string}` 用于设置序号与文本。
  - `position: Vector2 = Vector2.ZERO` 指定生成位置；为 `ZERO` 时使用规则计算。
- 位置规则与坐标缓存：
  - 若 `position != ZERO`：直接使用该位置（不做范围限制）。
  - 若 `position == ZERO`：
    - 首次出现的 `num`：计算基础坐标 `base = Vector2(num * 100, num * 100)`，保存到缓存。
    - 非首次的 `num`：读取缓存 `base`，在 `x/y` 分别加一个 `50..150` 的随机偏移，得到新坐标。
  - 对于非直接赋予的位置，若坐标不在范围 `[Vector2(100,100), Vector2(randf_range(100,1200), randf_range(100,1000))]` 内，则在该范围内随机生成一个坐标。
- 创建后立即播放坠落入场动画。

## 设计与接口
- 新增脚本 `scenes/pricelabel/price_label_maker.gd`，`extends Node`。
- 字段：
  - `@export var price_label_scene: PackedScene`（默认加载 `res://scenes/pricelabel/price_label.tscn`）。
  - 私有缓存 `var _saved_positions := {}`，键为 `int num`，值为 `Vector2 base_pos`。
- 方法：
  - `func create_price_label(data: Dictionary, position: Vector2 = Vector2.ZERO) -> PriceLabel`
    - 实例化、设置内容、计算坐标（按规则与范围限制）、加入子节点、调用 `play_drop_in(target_pos)`，返回实例。

## 实现要点
- 范围限制仅对“非直接赋予”的位置生效；用 `[min(100), max(randf_range(...))]` 生成与校验范围。
- 偏移随机：`dx = randi_range(50, 150)`, `dy = randi_range(50, 150)`。
- 坠落动画调用 `label.play_drop_in(final_pos)`，与 PriceLabel 当前实现兼容。

## 验证
- 传入 `position != ZERO` 时，直接在该点生成并播放坠落动画。
- 同一 `num` 多次创建：第一次使用 `num*100` 并缓存；后续在缓存基础上添加随机偏移；越界时回退到范围内随机位置。
- 内容渲染：使用已实现的 `set_content({num,text})`。

确认后我将新增脚本并按上述接口与规则实现。