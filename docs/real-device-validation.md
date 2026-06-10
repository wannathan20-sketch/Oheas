# OHeas — Real Device Validation Audit

> 审计日期：2026-06-09 | 范围：HealthKitReader → DailyMetricsAggregator → TodayView 数据链路

---

## 1. HealthKit 查询审计

### 1.1 查询清单

| # | 指标 | 查询类型 | 代码位置 | 可空性 | 异常风险 |
|---|------|---------|---------|--------|---------|
| 1 | Sleep | `HKSampleQuery` (category) | `HealthKitReader.swift:83-105` | 返回 `[]` 当无数据 | 高 |
| 2 | HRV | `HKSampleQuery` (quantity) | `HealthKitReader.swift:107-127` | 返回 `[]` 当无数据 | 高 |
| 3 | Resting Heart Rate | `HKSampleQuery` (quantity) | `HealthKitReader.swift:107-127` | 返回 `[]` 当无数据 | 高 |
| 4 | Steps | `HKStatisticsQuery` (cumulative) | `HealthKitReader.swift:129-148` | 返回 `nil` 当无数据 | 中 |
| 5 | Active Energy | `HKStatisticsQuery` (cumulative) | `HealthKitReader.swift:129-148` | 返回 `nil` 当无数据 | 中 |
| 6 | Exercise Minutes | `HKStatisticsQuery` (cumulative) | `HealthKitReader.swift:129-148` | 返回 `nil` 当无数据 | 中 |
| 7 | Workouts | `HKSampleQuery` | `HealthKitReader.swift:150-173` | 返回 `[]` 当无数据 | 低 |

### 1.2 当前 nil 处理策略

- **Sleep/HRV/RHR**：数组空 → `DailyMetricsAggregator` 计算平均值为 `nil` → `perMetricStatus` 设为 `.missing`
- **Steps/Energy/Exercise**：`HKStatisticsQuery` 返回 `nil` → `RawDailyHealthData` 保持 `nil` → `perMetricStatus` 设为 `.missing`
- **Workouts**：数组空 → `perMetricStatus` 根据 `workoutsQueried` 判断
- **Mock fallback**：HealthKit 读取失败或未授权 → 自动降级到 `MockHealthDataProvider`

### 1.3 已发现的代码可靠性点

✅ **正确做法：**
- 缺失值**不归零**（`DailyMetricsAggregator` 用 `compactMap` + `average`，空数组返回 `nil`）
- 极短睡眠（<2h）标记为 `partial` 而非 `valid`
- 每天独立查询，某天失败不影响其他天
- `HealthKitReader` 在非 iOS 平台有编译时 fallback（`#else` 分支）
- 授权失败时向上抛出错误，由 ViewModel 层自动切到 mock

⚠️ **已确认但不是bug的行为：**
- `HKStatisticsQuery` 的 `cumulativeSum` 在没有当天活动数据时返回 `nil`，此时 `steps`/`energy`/`exercise` 保持 `nil` → 正确行为
- Steps 用 `HKStatisticsQuery` 而非 `HKQuantityType` 的 `stepCount`（`HKStatisticsQuery` 更省电，正确）

---

## 2. 真实设备数据异常场景

### 场景 A：用户没戴表睡觉

| 属性 | 值 |
|------|-----|
| 触发条件 | Apple Watch 夜间未佩戴 |
| 影响指标 | Sleep、HRV（夜间测量） |
| 当前行为 | `sleepSegments` 返回 `[]`，`hrvSamples` 可能返回白天少量读数或 `[]` |
| 聚合结果 | `sleepHours = nil`, `hrv = nil or 少数值`, `perMetricStatus[.sleepHours] = .missing` |
| 信号检测 | `DataCoverageLayer` 检测到 2 项关键指标缺失 → `confidence = .low` |
| Agent 表现 | 输出 `recovery_uncertain_due_to_missing_data`，建议保守 |
| 严重度 | ⚠️ Medium — 行为正确，但用户可能每天看到相同提示 |

**建议：** 连续 3 天关键数据缺失时，在 Today 增加提示：「Apple Watch 是否未被佩戴睡觉？连续佩戴 5 晚可建立可靠的恢复基线。」

### 场景 B：用户关闭了睡眠追踪

| 属性 | 值 |
|------|-----|
| 触发条件 | Apple Watch → Settings → Sleep → 关闭 Track Sleep |
| 影响指标 | Sleep（Apple Watch 不记录睡眠分段） |
| 当前行为 | `sleepSegments` 始终返回 `[]`，`perMetricStatus[.sleepHours]` 始终 `.missing` |
| 聚合结果 | `sleepHours` 始终 `nil` |
| 信号检测 | 永久 `confidence = .medium` 或 `.low`（取决于 HRV 是否也有） |
| Agent 表现 | 长期只给出不确定信号 |
| 严重度 | 🔴 High — **用户反馈无价值，Agent 永远无法建立恢复基线** |

**修复方案：** `DataCoverageLayer` 连续 7 天 sleep 缺失时，`missingReasons` 新增：「Sleep tracking might be disabled in Apple Watch settings. Open the Watch app → Sleep to check.」

### 场景 C：HRV 一天只有一次读数

| 属性 | 值 |
|------|-----|
| 触发条件 | Apple Watch 只在早晨自动测量一次 HRV（或用户手动触发 Mindfulness） |
| 影响指标 | HRV（样本数极少） |
| 当前行为 | `hrvSamples` 返回 1-2 个值 |
| 聚合结果 | `hrv` = 单点平均值，即原始值 |
| 信号检测 | 单点 HRV 波动大，可能与基线产生 ±20% 偏差 |
| Agent 表现 | 可能触发 `hrv_low` 或 `hrv_percent_drop` 误报 |
| 严重度 | ⚠️ Medium — 单点 HRV 噪声导致建议质量下降 |

**修复方案：** `DailyMetricsAggregator` 在 `hrvSamples.count < 3` 时标记 `perMetricStatus[.hrv] = .partial`（当前标记为 `.valid`）。`SignalDetector` 在 `hrv` 为 `.partial` 时下调 signal 的 `severity`。

### 场景 D：Apple Watch 未同步 / 数据滞后

| 属性 | 值 |
|------|-----|
| 触发条件 | Watch 数据尚未同步到 iPhone（常见于刚起床时打开 app） |
| 影响指标 | 所有指标 |
| 当前行为 | 所有查询返回空或部分数据 |
| 聚合结果 | 大量 `nil` 值，`.missing` 状态 |
| 信号检测 | `confidence = .low` |
| Agent 表现 | 输出 `recovery_uncertain` |
| 严重度 | ⚠️ Medium — 只在早晨打开时发生，几分钟后自然恢复 |

**建议：** 无需代码修复。在 `DataQualityReport` 的 `missingReasons` 中加一句提示：「Apple Watch data may still be syncing. If Apple Watch was worn, wait a few minutes and refresh.」

### 场景 E：用户首次授权，基线不足

| 属性 | 值 |
|------|-----|
| 触发条件 | 新用户，HealthKit 授权后第一天 |
| 影响指标 | 所有指标 |
| 当前行为 | 读取 30 天数据，但只有授权后的天有数据 |
| 聚合结果 | 能用的天远少于 14 天 |
| 信号检测 | `BaselineEngine` 的 `window` 数据很少，`sampleCounts` 不足 |
| Agent 表现 | 基线不可靠，给出的建议参考价值低 |
| 严重度 | 🔴 High — **用户首次体验极差，可能不再打开** |

**修复方案：**
1. 在 Today 页检测基线天数。当 `baseline. sampleCounts` 总量 < 7 天时，显示 onboarding 式引导而非正常建议。
2. `DailyMetricsAggregator` 在 `hrvSamples.count < 3` 时标记 `.partial`（上文已提）。

---

## 3. 逐指标风险矩阵

| 指标 | 空数据风险 | 误报风险 | 真实数据与 Mock 差异 |
|------|-----------|---------|---------------------|
| Sleep | 🔴 高（没戴表/关闭追踪） | 中（片段化睡眠未检测） | Mock 有 3 段分段，真实可能只有 `asleepUnspecified` |
| HRV | 🔴 高（一天一次） | 🔴 高（单点噪声 → HRV 偏低误报） | Mock 有 3 个样本，真实可能只有 1 个 |
| RHR | 🟡 中（需连续佩戴） | 低（相对稳定） | Mock 值稳定，真实可能有测量误差 |
| Steps | 🟢 低（iPhone 也有计步） | 低 | Mock 可预测，真实与携带方式有关 |
| Active Energy | 🟡 中（依赖手表佩戴） | 低 | Mock 可预测，真实 = 0 常见于久坐日 |
| Exercise | 🟡 中（依赖手表） | 低 | Mock 可预测，真实可能漏记瑜伽/力量 |
| Workouts | 🟢 低 | 低 | Mock 类型有限，真实有更多 workout 类型 |

---

## 4. 按优先级修复建议

### P0 — 阻塞真机验证

1. **HRV 单点噪声**（场景 C）：`hrvSamples.count < 3` → `perMetricStatus = .partial`
2. **基线不足引导**（场景 E）：基线少于 7 天时显示特殊 UI

### P1 — 影响用户体验

3. **睡眠追踪关闭检测**（场景 B）：连续 7 天无 sleep → `missingReasons` 提示检查 Watch → Sleep 设置
4. **数据同步延迟提示**（场景 D）：`missingReasons` 加同步提示

### P2 — 提升建议质量

5. **连续缺失恢复关键数据**（场景 A）：连续 3 天提示佩戴建议
6. **HRV 日间读取策略**：考虑使用 `HKStatisticsQuery` 查询 HRV 的日均值

---

## 5. 需要真机上验证的假设

1. **Apple Watch Series 3+ 的 HRV 一天默认读几次？** → 实测确认
2. **睡眠分段在启用了 Sleep Focus 但未戴表时返回什么？** → 实测确认
3. **`HKStatisticsQuery.cumulativeSum` 在跨时区旅行时行为？** → 实测确认
4. **iPhone 记步 vs Apple Watch 记步的优先级？** → HealthKit 自动优先级合并，但需验证
5. **用户关闭 iPhone Health 来源优先级后 `HKStatisticsQuery` 行为？** → 实测确认
