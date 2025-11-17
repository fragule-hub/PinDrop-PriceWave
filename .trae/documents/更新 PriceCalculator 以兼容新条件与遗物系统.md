## 目标
- 适配优惠券条件从单一到数组的变更，确保“全部满足”后才通过。
- 切换遗物管理到 `GlobalRelic` 资源化接口，去除旧 `RelicGlobal`/`RelicId`/`get_value` 依赖。
- 正确实现现有遗物：“条件漏洞”“减算错误”“乘算错误”。

## 代码差异确认
- `CouponStat` 结构：现在为 `conditions: Array[CouponCondition]` 与 `effect: CouponEffect`（见 `data/coupon_stats/coupon_stat.gd:9-11`）。
- 遗物系统：`GlobalRelic` 以 `RelicStat` 资源存储（见 `autoload/global_relic.gd`），遗物资源在 `data/relic_stats/*.tres`，含：
  - 条件漏洞（无视全部条件，视为无门槛）：`data/relic_stats/condition_error.tres:9-11`
  - 减算错误（减算数值×参数1）：`data/relic_stats/subtraction_error.tres:9-11`
  - 乘算错误（乘算系数再-参数1）：`data/relic_stats/multiplication_error.tres:9-11`
- 现有 `PriceCalculator` 仍使用旧接口：
  - 取单条件与效果：`scripts/price_calculator.gd:47-50`
  - 条件判断为单一 `match`：`scripts/price_calculator.gd:52-61` 与重算处 `129-137`
  - 遗物判定与取值使用 `RelicGlobal.has_relic(...)`、`RelicGlobal.get_value(...)`：`scripts/price_calculator.gd:69-77`、`145-153`，且枚举 `RelicId` 不存在于新系统

## 修改方案
- 接口替换与字段重命名（两处）：
  - `coupon_stat.条件 → coupon_stat.conditions`（数组）
  - `coupon_stat.效果 → coupon_stat.effect`
- 条件判定改为“全部满足”：
  - 若拥有遗物“条件漏洞”，直接 `can_pass = true`；否则遍历 `conditions`：
    - `无门槛`：跳过
    - `满减`：要求 `current_price >= condition.value`
    - `专用`：要求 `condition.goods_type == goods_stat.goods_type`
  - 位置：点击应用处 `scripts/price_calculator.gd:52-61`、重算处 `129-137`
  - 步骤记录中保存 `conditions` 数组：`scripts/price_calculator.gd:87-93`
- 遗物效果实现（两处应用与重算皆一致）：
  - 减算：`sub_val = effect.value`；若拥有“减算错误”，`sub_val *= subtraction_error.parameter1`
  - 乘算：`mul_factor = effect.value`；若拥有“乘算错误”，`mul_factor = max(0.0, mul_factor - multiplication_error.parameter1)`
  - 价格下限保持 `0`
- `GlobalRelic` 访问方式：
  - 替换所有 `RelicGlobal` 为 `GlobalRelic`
  - 通过名称检索遗物资源：在 `PriceCalculator` 内新增辅助：
    - `_find_relic_by_name(name: String) -> RelicStat`：扫描 `GlobalRelic.all_relic_stats`
    - `_has_relic(name: String) -> bool`：`GlobalRelic.has_relic(_find_relic_by_name(name))`
    - `_get_relic_param1(name: String, default_val: float) -> float`：读取 `parameter1`
  - 遗物名常量：`"条件漏洞"`、`"减算错误"`、`"乘算错误"`

## 精确改动点
- 替换字段与条件逻辑：
  - `scripts/price_calculator.gd:47-50、52-61` 改为按数组全判定；保存 `conditions`
  - 重算逻辑：`scripts/price_calculator.gd:126-137` 改为数组全判定
- 遗物逻辑：
  - 减算分支：`scripts/price_calculator.gd:67-73` 与 `143-149`，按参数1乘增
  - 乘算分支：`scripts/price_calculator.gd:73-79` 与 `149-155`，按参数1下调折扣系数
- 引用替换：
  - 将 `RelicGlobal` → `GlobalRelic`：`scripts/price_calculator.gd:69-77、145-153`
- 步骤记录：
  - 在 `applied_steps.append(...)` 新增 `"conditions": conditions`：`scripts/price_calculator.gd:87-93`

## 验证与回归
- 用 `data/coupon_stats/test_coupon_stat.tres` 验证：
  - 满减+专用组合在无“条件漏洞”时需同时满足；拥有“条件漏洞”时直接通过
- 用三遗物分别验证：
  - “减算错误”：`-10`→`-15`（参数1=1.5）
  - “乘算错误”：`×0.7`→`×0.6`（参数1=0.1）
  - 条件重算（取消券）路径与点击路径一致

## 兼容性
- 仅改动 `scripts/price_calculator.gd` 与内部辅助函数；不新增资源与场景
- 保持所有信号与 UI 标签重建时序不变

请确认以上方案后，我将据此实现并提交修改。