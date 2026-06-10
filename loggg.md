# 想做一个llm agent相关的项目，通过监控苹果手表的每天健康运动数据，给用户提供建议。给我一点想法

> 想做一个llm agent相关的项目，通过监控苹果手表的每天健康运动数据，给用户提供建议。给我一点想法

可以做，而且这个方向很适合做成“个人健康教练型 agent”。关键不是简单把 Apple Watch 数据丢给 LLM，而是让 agent 具备“持续观察、发现模式、提出小建议、跟踪反馈”的能力。

**项目方向：Apple Watch 健康运动 Agent**

核心想法：
每天读取用户的 Apple Watch / HealthKit 数据，比如步数、运动分钟、心率、睡眠、静息心率、HRV、站立时间、卡路里、训练记录等，然后由 LLM agent 做每日总结、趋势分析和个性化建议。

可以做成几个层级：

1. **每日健康简报**
   - “今天活动量比过去 7 天平均低 23%”
   - “昨晚睡眠时间偏短，但今天静息心率正常”
   - “你今天已经连续坐了较久，可以安排 10 分钟轻量走动”
   - 输出风格可以像一个温和的私人教练，而不是冰冷仪表盘。

2. **趋势型建议**
   - agent 不只看当天，而是看 7 天、30 天趋势。
   - 比如：
     - 最近睡眠减少 + 静息心率升高 + 运动强度增加 → 建议降低训练强度
     - 连续几天步数下降 → 推荐轻量恢复计划
     - 周末活动少 → 给出适合周末的运动建议

3. **目标管理 Agent**
   - 用户设定目标：减脂、增肌、改善睡眠、提高心肺能力、保持日常活跃。
   - agent 根据目标调整建议。
   - 例如减脂用户更关注总活动量、运动频率、睡眠稳定性；恢复型用户更关注 HRV、静息心率、睡眠质量。

4. **主动提醒与计划调整**
   - 不只是每天总结，而是能主动判断：
     - “今天活动量明显不足，要不要我给你安排一个 15 分钟低强度计划？”
     - “你昨天训练强度高，今天建议恢复走路而不是高强度训练。”
   - 这里 agent 的感觉会更强，因为它能“观察 → 判断 → 行动建议”。

5. **可解释建议**
   - 每条建议都附带依据：
     - “建议今天轻量运动，因为你昨晚睡眠少于平时 1.5 小时，且今天静息心率略高。”
   - 这会比普通 LLM 聊天更可信。

**一个不错的 MVP 可以这样做：**

- iOS App 读取 HealthKit 数据
- 后端存储每日摘要数据，不需要存太细的原始数据
- 每天生成一份：
  - 今日状态评分
  - 运动完成度
  - 睡眠/恢复情况
  - 1-3 条行动建议
  - 一句鼓励性总结
- 用户可以聊天追问：
  - “我今天适合跑步吗？”
  - “为什么你说我该休息？”
  - “帮我安排这周的运动计划。”

**Agent 架构可以设计成：**

- `Data Collector`：读取 Apple Health / Apple Watch 数据
- `Health Analyzer`：计算趋势、异常、分数
- `Memory`：保存用户目标、偏好、历史建议、反馈
- `Planner Agent`：生成今日建议或周计划
- `Conversation Agent`：和用户聊天解释建议
- `Safety Layer`：避免医疗诊断，只给生活方式建议，必要时提示咨询医生

**几个有意思的功能点：**

- “恢复指数”：结合睡眠、HRV、静息心率、昨日运动强度
- “今天适合做什么”：休息、散步、力量训练、跑步、拉伸
- “长期洞察”：每周告诉用户什么因素最影响状态
- “习惯教练”：发现用户最容易中断运动的时间段
- “情绪/能量记录”：让用户每天主观打分，agent 学习身体数据和主观感受之间的关系

**我觉得最有产品感的切入点：**

做一个“Daily Recovery & Activity Coach”，每天早上告诉用户：

> 今天身体状态：适合轻中强度活动。
> 原因：睡眠略低于平均，但静息心率稳定，昨日运动负荷不高。
> 建议：完成 30 分钟快走或低强度骑行，晚上避免高强度训练。

这个比单纯“健康数据总结”更有价值，因为它回答的是用户真正关心的问题：**我今天该怎么动，怎么休息，怎么更好一点。**

> 现在有没有这种项目

<details><summary>2 previous messages</summary>

> 我查一下现在市面上和开源里类似的项目，重点看 Apple Watch/HealthKit + AI coach/agent 这类组合，避免只凭印象说。
>
> <details><summary>Searched web 3 times</summary>
>
> <details><summary>Searched web 3 times</summary>
>
> - Searched web for `Apple Watch AI health coach HealthKit app personalized recommendations 2026`
> - Searched web for `site:apple.com watchOS 26 Workout Buddy Apple Intelligence Apple Watch`
> - Searched web for `GitHub openCHA LLM health agent framework`
>
> </details>
>
> </details>
</details>

有，而且已经不少了。截至 **2026-06-08**，这个方向可以说正在变热。

**已经存在的类型：**

1. **Apple 官方方向**
   - Apple 已经在 watchOS 26 里推出了 **Workout Buddy**，用 Apple Intelligence 根据用户的运动历史和当前训练数据，在训练中给个性化语音鼓励和总结。
   - 但它更偏“运动过程中的实时教练”，不是完整的“每天健康数据 agent”。
   来源：[Apple Newsroom](https://www.apple.com/newsroom/2025/06/watchos-26-delivers-more-personalized-ways-to-stay-active-and-connected/)、[Apple Support](https://support.apple.com/en-asia/guide/watch/use-workout-buddy-apd65c7938e6/26/watchos/26)

2. **第三方 Apple Watch AI 健康教练**
   - [Athlytic](https://apps.apple.com/us/app/athlytic-ai-fitness-coach/id1543571755)：Apple Watch 上很成熟的恢复、训练负荷、HRV、睡眠分析类 App，现在也强调 AI fitness coach。
   - [FitLoop](https://fitloop.us/)：明确主打 Apple Watch + AI health coach，解释睡眠、恢复、营养和身体状态。
   - [RIN](https://rin-health.com/)：读取 Apple Watch / Apple Health 数据，根据睡眠、HRV、步数、训练恢复做每日个性化 coaching。
   - [FITIV Pulse](https://fitiv.co/)：AI fitness tracker，关注 HRV、恢复、训练负荷和心率区间。
   - [Orvu](https://orvu.app/)：从 HealthKit 读取睡眠、HRV、静息心率、训练负荷，给恢复建议。
   - [Rox](https://talktorox.com/)：把 Apple Watch 变成个人 AI coach，学习用户的睡眠、HRV、恢复和压力模式。

3. **开源 / 研究方向**
   - [HealthLog](https://healthlog.dev/)：自托管健康追踪应用，支持 Apple HealthKit、AI Coach、医生报告等。
   - [openCHA](https://www.healthunity.org/opencha)：开源的 conversational health agent 框架，更偏医疗/健康对话 agent 基础设施。
   - 研究上也有像 [GPTCoach](https://hci.stanford.edu/publications/2025/Joerke_GPTCoach.pdf)、[PHIA](https://arxiv.org/abs/2406.06464) 这种 LLM + wearable data 的健康洞察系统。

所以结论是：**有类似项目，而且已经有竞争者。**
但我觉得仍然有空间，原因是现有产品大多还停留在“健康数据解释 + 恢复分数 + 聊天建议”，真正做成强 agent 的不多。

你可以差异化做这几个点：

- **中文/亚洲用户场景**：中文解释、饮食习惯、作息文化、通勤运动、996/熬夜恢复，这块国外产品基本没做好。
- **更强的长期记忆**：不只是今天建议，而是记住“你周二最容易断练”“熬夜后第二天跑步表现会下降”。
- **主动 agent**：每天早上自动生成今日建议；晚上复盘；周日自动改下周计划。
- **可解释推荐**：每条建议都说明依据，比如 HRV、睡眠、静息心率、训练负荷哪个触发了判断。
- **隐私优先**：本地分析 + 只上传摘要给 LLM，或者支持用户自带 API key。
- **不是医疗诊断，而是生活方式教练**：避开高风险医疗判断，专注运动、恢复、睡眠、习惯建议。

我会建议你别从“又一个 Athlytic”切入，而是做成：

**“Apple Watch 数据驱动的中文 Daily Coach Agent”**
每天回答一个核心问题：
**“我今天该怎么动、怎么休息、怎么调整？”**

这个定位比“健康仪表盘”更有产品感。

> 这种agent context是啥

在这个项目里，**agent context** 可以理解成：

> LLM agent 在做判断前，需要知道的“用户状态 + 历史记忆 + 当前任务 + 可用工具”。

不是把所有 Apple Watch 原始数据一股脑塞给模型，而是整理成模型能用的上下文。

比如用户问：

> 我今天适合跑步吗？

agent 的 context 可能包括这些东西：

```json
{
  "user_profile": {
    "age": 29,
    "sex": "male",
    "fitness_goal": "减脂和改善心肺",
    "usual_training": "每周跑步3次，力量训练2次",
    "injuries": ["膝盖偶尔不适"]
  },
  "today_metrics": {
    "sleep_hours": 5.8,
    "resting_heart_rate": 68,
    "hrv": 34,
    "steps": 4200,
    "active_energy_kcal": 310,
    "workout": null
  },
  "baseline": {
    "avg_sleep_hours_14d": 7.1,
    "avg_resting_heart_rate_14d": 61,
    "avg_hrv_14d": 46,
    "avg_steps_14d": 8200
  },
  "recent_trends": [
    "过去3天睡眠低于个人平均",
    "静息心率比平时高约7 bpm",
    "HRV 连续2天下降",
    "昨天没有高强度训练"
  ],
  "user_preferences": {
    "preferred_workout_time": "晚上",
    "likes": ["跑步", "快走"],
    "dislikes": ["骑行"],
    "tone": "直接但鼓励"
  },
  "safety_rules": [
    "不能做医疗诊断",
    "出现胸痛、晕厥、持续异常心率时建议就医",
    "建议必须解释依据"
  ],
  "current_question": "我今天适合跑步吗？"
}
```

然后 agent 才会回答：

> 今天不太建议高强度跑步。你的睡眠比过去 14 天平均少了 1.3 小时，静息心率高于平时，HRV 也偏低，更像是恢复不足。可以改成 20-30 分钟轻松走路或低强度慢跑，注意不要冲配速。

**所以 context 不是单一东西，而是几类信息组合：**

1. **用户画像**
   年龄、目标、运动水平、伤病、偏好、作息。

2. **今日数据**
   今天的步数、睡眠、心率、HRV、训练、活动消耗。

3. **历史基线**
   用户自己的平均水平，而不是大众标准。
   比如 HRV 40 对某些人低，对另一些人正常。

4. **趋势和异常**
   过去 7 天、14 天、30 天的变化。
   Agent 最有价值的地方就是发现“最近和平时不一样”。

5. **记忆**
   用户之前说过的话、反馈、目标变化。
   比如“我周三通常没时间运动”“我不喜欢 HIIT”“我最近膝盖疼”。

6. **任务意图**
   用户现在是想问训练建议、睡眠分析、恢复判断，还是周计划。

7. **工具上下文**
   agent 可以调用什么：
   - 查询 HealthKit 数据
   - 计算恢复分数
   - 生成周计划
   - 发提醒
   - 保存用户反馈

8. **安全边界**
   健康类 agent 必须知道什么不能说。
   它可以建议生活方式，但不能诊断疾病。

一个好的设计是：**原始数据进数据库，分析模块生成摘要，LLM 只拿“可解释摘要 + 必要指标”。**

简单架构可以是：

```text
Apple Watch / HealthKit
        ↓
数据清洗与聚合
        ↓
每日摘要 / 趋势 / 异常检测
        ↓
Agent Context Builder
        ↓
LLM Agent
        ↓
建议 / 解释 / 计划 / 提醒
```

这个项目里最关键的模块其实就是 **Context Builder**。
它决定了 agent 是“乱聊的健康 chatbot”，还是“真的理解你身体状态的 coach”。

> 我想要一个独特的，技术含量高的，能吸引用户的，当然有效的

我会把它做成一个不只是“健康建议”的 agent，而是：

**个人身体状态实验室 + 行动教练**

核心卖点不是“AI 看你的 Apple Watch 数据”，而是：

> 它能逐渐学出“什么最影响你本人”，然后每天给出最小、可执行、可验证的调整。

这比普通恢复分数高级很多。

**独特概念：Personal Physiology Agent**
每天回答三个问题：

1. **我今天处于什么状态？**
2. **为什么会这样？**
3. **我今天做哪一个小动作，最可能让明天变好？**

比如不是说：

> 你昨晚睡眠不好，建议早点睡。

而是说：

> 你过去 30 天里，晚饭后 2 小时内大量进食时，第二天 HRV 平均下降 11%，静息心率升高 4 bpm。今晚建议把最后一餐提前到 20:30 前，明早我会帮你验证效果。

这个就有技术含量，也更吸引用户。

---

**我认为最强的差异化功能：N-of-1 因果实验**

大多数健康 App 是“展示指标”。
你的 agent 可以做“个人实验”。

用户可以记录或自动采集：

- 睡眠时间
- HRV
- 静息心率
- 步数
- 训练强度
- 饮酒
- 咖啡因
- 晚餐时间
- 压力主观评分
- 屏幕时间
- 工作日/周末
- 经期、旅行、熬夜等事件

然后 agent 发现个人模式：

- “咖啡超过下午 3 点喝，你入睡时间平均推迟 42 分钟”
- “力量训练后第二天 HRV 不降，但跑步超过 8km 后会明显下降”
- “你不是运动太少，而是周一到周三活动集中，后半周恢复不足”
- “你的睡眠时长不是最大问题，睡眠规律性才是”

这会让用户觉得：**它真的在了解我。**

---

**第二个吸引点：今日身体预算 Body Budget**

给用户一个很好懂的概念：

> 今天你有多少“身体预算”，应该花在哪？

不是简单打分，而是分配建议：

```text
今日身体预算：72 / 100

建议分配：
- 运动：中低强度，30-45 分钟
- 工作压力：避免连续深度工作超过 90 分钟
- 咖啡因：14:00 后不建议
- 晚间恢复：优先拉伸 + 提前睡
```

这个比“恢复分数 72”更有行动感。

---

**第三个技术点：多 Agent 协作**

可以设计成几个专业 agent：

```text
Health Data Agent
负责读取和清洗 HealthKit 数据

Baseline Agent
建立用户个人基线，而不是用大众标准

Pattern Agent
找趋势、异常、相关性和可能影响因素

Experiment Agent
设计个人小实验，比如“连续 5 天提前晚餐”

Coach Agent
把分析结果变成用户愿意执行的话

Safety Agent
过滤医疗诊断、极端建议和风险表达
```

这样技术上比普通 chatbot 高一个层级，也方便你之后写论文、做 demo、融资或者开源。

---

**第四个亮点：建议必须可验证**

每条建议都带一个“明天怎么验证”。

比如：

> 今晚 23:30 前睡，明早看三个指标：睡眠时长、静息心率、主观精力。
> 如果静息心率回到 62 以下，说明今天恢复策略有效。

这会形成闭环：

```text
观察 → 建议 → 执行 → 验证 → 学习用户规律
```

这个闭环就是 agent 的灵魂。

---

**MVP 可以这样做**

第一版不要做太大，聚焦一个场景：

**“明天状态优化器”**

每天晚上问用户：

> 你想让明天状态更好吗？我给你一个今晚最值得做的小调整。

它读取 Apple Watch 数据后，只输出：

1. 今日状态总结
2. 可能原因
3. 一个最小行动
4. 明天验证指标

示例：

> 今天你的恢复偏低，主要信号是 HRV 比个人 14 天基线低 18%，静息心率高 5 bpm，且昨晚睡眠少了 74 分钟。
> 今晚最值得做的一件事：不要加练，做 15 分钟轻拉伸，23:30 前上床。
> 明天我会看 HRV 是否回升、静息心率是否下降，以及你的主观精力评分。

---

**名字方向**

可以叫：

- **BodyLoop**
- **RecoverAI**
- **MirrorCoach**
- **Tomorrow Coach**
- **N-of-1 Health Agent**
- **体感实验室**
- **明日状态**
- **身体回路**

我个人最喜欢的定位是：

**“一个帮你优化明天状态的 Apple Watch Agent。”**

它不显得医疗化，不像普通健身 App，也不是单纯聊天机器人。用户每天都能感受到价值。

> 我想做一个，你先规划一下步骤

可以。我们先把它按“能做出来、能验证价值、还能体现技术含量”的方式规划。我的建议是不要一上来做大而全，而是先做一个很锋利的 MVP：

**项目定位**
做一个基于 Apple Watch / Apple Health 数据的 **个人身体状态 Agent**。

核心能力：

> 观察你的身体数据 → 发现个人模式 → 给出今天/今晚最值得做的一件事 → 第二天验证是否有效。

不是健康仪表盘，不是普通聊天机器人，而是一个会长期学习你的“个人状态优化 agent”。

**阶段 1：定义 MVP**
先聚焦一个场景：

**“明天状态优化器”**

每天晚上或早上生成一条建议：

- 今天身体状态如何
- 哪些指标异常
- 可能原因是什么
- 今天/今晚最值得做的一件小行动
- 明天用什么指标验证效果

第一版建议只覆盖这些数据：

- 睡眠时长
- 睡眠规律性
- 静息心率 RHR
- HRV
- 步数
- 运动分钟
- 活动能量
- 训练记录
- 用户主观精力评分

**阶段 2：数据接入**
技术路线：

```text
Apple Watch
  ↓
Apple Health / HealthKit
  ↓
iOS App 读取数据
  ↓
本地摘要 / 后端数据库
  ↓
Agent 分析与建议
```

第一版可以做 iOS App，用 HealthKit 权限读取每日数据。

需要处理：

- 用户授权
- 每日数据聚合
- 指标单位标准化
- 缺失数据处理
- 最近 7/14/30 天基线计算

这里不要把所有原始数据都给 LLM。应该先在代码里算出结构化摘要。

**阶段 3：建立 Context Builder**
这是项目最核心的技术模块。

它负责把数据整理成 agent 能理解的上下文，比如：

```json
{
  "today": {
    "sleep_hours": 6.1,
    "resting_hr": 68,
    "hrv": 34,
    "steps": 5200
  },
  "baseline_14d": {
    "sleep_hours": 7.2,
    "resting_hr": 61,
    "hrv": 45,
    "steps": 8400
  },
  "signals": [
    "sleep_duration_low",
    "resting_hr_high",
    "hrv_low"
  ],
  "goal": "提升精力和稳定运动",
  "user_feedback": "最近工作压力大"
}
```

Agent 的质量很大程度取决于这个 context，而不是模型本身。

**阶段 4：规则分析 + LLM 结合**
不要让 LLM 直接瞎判断健康数据。

建议采用：

```text
规则/统计模块负责判断事实
LLM 负责解释、取舍、表达和计划
```

例如规则模块输出：

- HRV 比 14 天均值低 18%
- 静息心率比均值高 6 bpm
- 睡眠比均值少 1.2 小时
- 昨天没有高强度训练

LLM 再生成：

> 今天更像是恢复不足，不建议高强度跑步。最好的行动是低强度活动和早点睡。

这样更可靠，也更容易解释。

**阶段 5：Agent 设计**
第一版可以设计 4 个 agent / 模块：

1. **Data Agent**
   读取并整理 Apple Health 数据。

2. **Baseline Agent**
   建立个人基线，判断今天和平时相比是否异常。

3. **Insight Agent**
   找出今天最重要的 1-3 个信号。

4. **Coach Agent**
   生成用户能执行的建议。

后面再加：

- Experiment Agent：设计个人实验
- Memory Agent：记住用户反馈和偏好
- Safety Agent：避免医疗诊断和危险建议

**阶段 6：建议闭环**
这是独特性的关键。

每条建议都必须可验证：

```text
建议：今晚 23:30 前上床，避免加练。
验证：明天看 HRV 是否回升、静息心率是否下降、主观精力是否提高。
```

第二天 agent 自动回顾：

> 昨晚你睡了 7.4 小时，静息心率下降 3 bpm，主观精力从 5/10 到 7/10。这个策略对你可能有效。

这会让用户觉得它真的在学习自己。

**阶段 7：产品界面**
MVP 不需要复杂 UI。可以先做 3 个页面：

1. **今日状态**
   - Body Budget 分数
   - 恢复状态
   - 今日建议
   - 依据指标

2. **Agent 对话**
   - “我今天适合跑步吗？”
   - “为什么你建议我休息？”
   - “帮我安排这周运动”

3. **个人实验**
   - 当前实验：比如“连续 5 天提前睡”
   - 执行记录
   - 效果反馈

**阶段 8：技术栈建议**
如果你想快速做出来：

- iOS：SwiftUI + HealthKit
- 后端：FastAPI / Node.js
- 数据库：PostgreSQL
- Agent：OpenAI / Claude API
- 分析模块：Python 更方便
- 可视化：简单折线图 + 指标卡片

如果想隐私优先：

- iOS 本地计算大部分指标
- 只把摘要 context 发给 LLM
- 用户可选择本地模型或自带 API key

**阶段 9：MVP 里程碑**
可以按 6 周规划：

第 1 周：产品定义
确定目标用户、核心场景、数据字段、建议格式。

第 2 周：HealthKit 数据接入
读取睡眠、HRV、静息心率、步数、运动记录。

第 3 周：基线和异常检测
计算 7/14/30 天平均，生成健康信号。

第 4 周：Agent Context + 建议生成
把结构化 context 输入 LLM，生成每日建议。

第 5 周：闭环反馈
用户打分，第二天验证建议是否有效。

第 6 周：Demo App
做今日状态页、对话页、实验页。

**最终 MVP 输出长这样：**

> 今日状态：恢复偏低
> 主要原因：HRV 比个人基线低 16%，静息心率高 5 bpm，睡眠少 72 分钟。
> 今日建议：不要做高强度跑步，改为 25 分钟轻松走路。
> 今晚行动：23:30 前上床，避免饮酒和加练。
> 明天验证：看 HRV、静息心率和主观精力是否改善。

我建议第一步先做一份更正式的 **MVP PRD + 技术架构图**，然后再开始拆开发任务。

> 对了，用户不可能一天24h全戴，然后苹果健康读取不到数据，这种如何处理

这个问题非常关键。真实产品里，**“数据缺失”不是异常情况，而是常态**。所以这个 agent 必须是 **coverage-aware agent**，也就是先判断“今天数据有多可靠”，再给建议。

核心原则：

> 不要把缺失数据当成 0，也不要偷偷用平均值补上然后装作确定。

可以这样处理。

**1. 先识别“没戴表”而不是“状态差”**

比如今天 HRV 没有数据，不代表 HRV 差；可能只是没戴表睡觉。
今天步数少，也可能是没戴表，但手机记录了一部分。

所以数据层要区分三种状态：

```text
valid: 有可靠数据
missing: 没有数据
partial: 有数据，但覆盖不足
```

例如：

```json
{
  "hrv": {
    "value": null,
    "status": "missing",
    "reason": "no_watch_sleep_data"
  },
  "steps": {
    "value": 4200,
    "status": "partial",
    "coverage": "phone_only"
  }
}
```

**2. 给每一天加一个 Data Confidence**

不要只输出“恢复分数”，而是同时输出可信度：

```text
今日状态：中等恢复
可信度：低
原因：昨晚没有 Apple Watch 睡眠数据，HRV 和夜间静息心率缺失。
```

这样用户会觉得 agent 很诚实，也更专业。

可以设计：

```text
数据可信度：
- High：睡眠、HRV、RHR、活动数据完整
- Medium：缺少一类关键数据，但仍有足够依据
- Low：睡眠/HRV/RHR 大量缺失，只能给保守建议
```

**3. 分指标处理缺失**

不同数据缺失的影响不一样。

- **睡眠缺失**：不要推断睡眠好坏，可以问用户“昨晚大概睡了多久？”
- **HRV 缺失**：不要生成明确恢复结论。
- **静息心率缺失**：恢复判断降级。
- **步数缺失**：可以结合 iPhone 步数，但标记为 partial。
- **训练缺失**：允许用户手动补录：“今天其实打球 1 小时”。

**4. Agent 建议要根据可信度降级**

数据完整时：

> 你的 HRV 低于 14 天基线 18%，静息心率高 5 bpm，建议今天降低训练强度。

数据不完整时：

> 今天缺少睡眠和 HRV 数据，所以我不能准确判断恢复状态。基于目前活动量和你昨天的训练记录，建议先选择低风险方案：20-30 分钟轻松活动，避免高强度训练。

这就是一个好的健康 agent 和普通 chatbot 的区别。

**5. 缺失本身也可以变成 context**

没戴表其实也是行为信号。

比如：

```text
最近 7 天有 4 晚没有佩戴 Apple Watch 睡觉。
```

agent 可以温和提醒：

> 如果你希望我更准确判断恢复状态，建议睡觉时佩戴手表，至少连续 5-7 天建立个人基线。

但不要强迫用户 24 小时戴。产品应该接受“不完整人生”，这才真实。

**6. 可以用“轻量补问”补齐关键数据**

每天最多问一个问题，别烦用户：

```text
昨晚没读到睡眠数据。你大概睡了多久？
A. 少于 5 小时
B. 5-6.5 小时
C. 6.5-8 小时
D. 8 小时以上
```

或者：

```text
今天有未记录的运动吗？
```

这些主观输入可以和 Apple Watch 数据一起进入 context。

**7. Context 里必须包含数据质量**

例如：

```json
{
  "today_metrics": {
    "sleep_hours": null,
    "hrv": null,
    "resting_hr": 64,
    "steps": 5300
  },
  "data_quality": {
    "sleep": "missing",
    "hrv": "missing",
    "resting_hr": "valid",
    "activity": "partial",
    "overall_confidence": "low"
  },
  "agent_instruction": "Do not make strong recovery claims when HRV and sleep are missing."
}
```

我会把这个设计成产品亮点：**不是盲目 AI 建议，而是带置信度的健康 agent**。

一句话方案：

> 建立一个 Data Coverage Layer，先判断数据完整性；再让 Context Builder 把“缺失、部分、可信度、补问需求”一起交给 agent；agent 根据可信度调整建议强度。

这反而会让项目显得更技术含量高，也更可信。

> 可以的，先规划一下作品实现步骤

可以。我们把它当成一个可以做成作品集 / Demo / 未来产品雏形的项目来规划。目标不是做一个泛泛的健康 App，而是做一个有技术含量的：

**Apple Watch Personal Health Agent**
基于 Apple Health 数据，建立个人基线，识别身体状态，处理数据缺失，并给出可验证的每日建议。

**作品核心卖点**

一句话：

> 一个懂得“数据不完整也能谨慎判断”的 Apple Watch 身体状态 Agent，每天告诉用户今天该怎么动、怎么休息，并在第二天验证建议是否有效。

不要先做大而全。第一版聚焦：

```text
每日状态分析 + 数据可信度 + 今日建议 + 明日验证
```

---

**阶段 1：确定 MVP 范围**

先做 4 个核心功能：

1. **读取 Apple Health 数据**
   - 睡眠时长
   - HRV
   - 静息心率
   - 步数
   - 活动能量
   - 训练记录

2. **建立个人基线**
   - 7 天平均
   - 14 天平均
   - 30 天趋势
   - 今日与个人基线对比

3. **判断数据可信度**
   - 数据完整：高可信
   - 缺少 HRV / 睡眠：中低可信
   - 大量缺失：只给保守建议

4. **生成 Agent 建议**
   - 今日状态
   - 关键原因
   - 建议行动
   - 明天验证指标

第一版不要做复杂医疗判断，不碰疾病诊断。

---

**阶段 2：技术架构**

推荐架构：

```text
Apple Watch
   ↓
Apple Health / HealthKit
   ↓
iOS App 数据采集
   ↓
Data Aggregator 数据聚合
   ↓
Baseline Engine 个人基线
   ↓
Coverage Layer 数据可信度
   ↓
Context Builder
   ↓
LLM Agent
   ↓
每日建议 / 对话 / 反馈
```

模块拆分：

```text
HealthKit Reader
读取健康数据

Daily Metrics Aggregator
把原始数据聚合成每日摘要

Baseline Engine
计算用户个人平均水平

Data Coverage Layer
判断今天的数据是否完整、可靠

Signal Detector
识别异常信号，比如 HRV 偏低、RHR 偏高

Context Builder
把数据整理成 LLM 可用上下文

Coach Agent
生成建议、解释和验证计划

Feedback Tracker
记录用户是否执行建议、第二天效果如何
```

---

**阶段 3：数据结构设计**

每日数据可以先设计成这样：

```json
{
  "date": "2026-06-08",
  "metrics": {
    "sleep_hours": 6.2,
    "hrv": 38,
    "resting_heart_rate": 66,
    "steps": 7200,
    "active_energy_kcal": 430,
    "exercise_minutes": 28
  },
  "baseline_14d": {
    "sleep_hours": 7.1,
    "hrv": 46,
    "resting_heart_rate": 61,
    "steps": 8500
  },
  "data_quality": {
    "sleep": "valid",
    "hrv": "valid",
    "resting_heart_rate": "valid",
    "activity": "partial",
    "overall_confidence": "medium"
  },
  "signals": [
    {
      "type": "hrv_low",
      "severity": "medium",
      "description": "HRV 比 14 天基线低 17%"
    },
    {
      "type": "sleep_low",
      "severity": "medium",
      "description": "睡眠比 14 天平均少 0.9 小时"
    }
  ]
}
```

重点是：**data_quality 必须进入 agent context**。

---

**阶段 4：Agent Context 设计**

Agent 每天收到的 context 应该是摘要，不是原始数据。

```json
{
  "user_goal": "提升精力和稳定运动",
  "today_summary": {
    "recovery_signals": ["hrv_low", "sleep_low"],
    "activity_signals": ["steps_slightly_low"],
    "data_confidence": "medium"
  },
  "important_metrics": {
    "sleep_hours": "6.2h, 低于基线 0.9h",
    "hrv": "38, 低于基线 17%",
    "resting_heart_rate": "66, 高于基线 5 bpm"
  },
  "constraints": [
    "不要做医疗诊断",
    "如果数据可信度低，建议必须保守",
    "每条建议都要说明依据",
    "必须给出明天验证方式"
  ]
}
```

这样 agent 输出会更稳定。

---

**阶段 5：建议生成规则**

建议不要完全交给 LLM。先用规则模块定调，再让 LLM 表达。

例如：

```text
如果 HRV 低 + RHR 高 + 睡眠低：
  状态 = 恢复不足
  建议 = 降低训练强度

如果数据缺失严重：
  状态 = 无法可靠判断
  建议 = 保守活动 + 询问用户补充

如果活动量低但恢复良好：
  状态 = 可增加活动
  建议 = 轻中强度运动
```

LLM 负责生成自然语言：

```text
今日状态：恢复偏低，建议不要做高强度训练。

依据：
- HRV 比你的 14 天基线低 17%
- 静息心率比平时高 5 bpm
- 昨晚睡眠少了约 54 分钟

今日建议：
做 20-30 分钟轻松走路，晚上避免加练。

明日验证：
观察 HRV 是否回升、静息心率是否下降，以及主观精力评分。
```

---

**阶段 6：产品页面**

MVP 做 4 个页面就够：

1. **今日状态页**
   - Body Budget 分数
   - 数据可信度
   - 今日建议
   - 关键指标依据

2. **指标详情页**
   - 睡眠、HRV、静息心率、步数趋势
   - 今日 vs 个人基线

3. **Agent 对话页**
   - “我今天适合跑步吗？”
   - “为什么建议我休息？”
   - “今晚我该做什么？”

4. **反馈页**
   - 用户是否执行建议
   - 今日主观精力 1-10 分
   - 明天自动回顾效果

---

**阶段 7：技术栈建议**

最适合作品实现的技术栈：

```text
iOS App:
SwiftUI + HealthKit

后端:
FastAPI 或 Node.js

数据库:
PostgreSQL / Supabase

LLM:
OpenAI API / Claude API

分析模块:
Python

可视化:
Swift Charts 或前端 Recharts
```

如果想先快速做 Demo，也可以：

```text
第一版：iOS App + 本地 JSON + LLM API
第二版：加后端和数据库
第三版：加长期记忆和个人实验
```

---

**阶段 8：开发里程碑**

**第 1 周：项目设计**
完成：
- PRD
- 数据字段定义
- Agent 输出格式
- 页面草图
- 安全边界

**第 2 周：HealthKit 数据读取**
完成：
- 请求 HealthKit 权限
- 读取睡眠、HRV、静息心率、步数
- 生成每日摘要

**第 3 周：基线与数据可信度**
完成：
- 7/14/30 天基线
- 缺失数据判断
- data confidence 评分
- 异常信号识别

**第 4 周：Agent Context + LLM 建议**
完成：
- Context Builder
- Prompt 模板
- 每日建议生成
- 低可信数据时的保守回答

**第 5 周：反馈闭环**
完成：
- 用户主观评分
- 是否执行建议
- 第二天验证结果
- 简单长期记忆

**第 6 周：作品 Demo**
完成：
- 今日状态页
- Agent 对话页
- 指标趋势页
- Demo 数据展示
- 项目 README / 演示视频脚本

---

**最终 Demo 效果**

用户打开 App，看到：

```text
今日身体预算：68 / 100
数据可信度：中

你的恢复信号略低。HRV 比 14 天基线低 17%，静息心率高 5 bpm，睡眠少了 54 分钟。

今日建议：
不要做高强度跑步，改为 25 分钟轻松走路。

今晚行动：
23:30 前上床，避免加练。

明天验证：
看 HRV 是否回升、静息心率是否下降、主观精力是否提高。
```

这版做出来已经很有作品感了：有 HealthKit、个人基线、缺失数据处理、agent context、LLM 建议、反馈闭环。技术含量和产品吸引力都够。

> 开始做吧，我用codex实现，你先写下prompt

<details><summary>1 previous message</summary>

> <details><summary>Searched web 1 time</summary>
>
> <details><summary>Searched web 1 time</summary>
>
> - Searched web for `Apple HealthKit HKStatisticsCollectionQuery sleep analysis HRV resting heart rate official docs`
>
> </details>
>
> </details>
</details>

可以。你先把下面这段直接丢给 Codex，作为第一轮实现 prompt。它会先做 **MVP 骨架 + HealthKit 数据层 + Agent Context Builder + mock 数据 fallback**，不要一上来做完整商业 App。

```text
你是一个资深 iOS + LLM Agent 工程师。请帮我实现一个 Apple Watch / Apple Health 驱动的个人身体状态 Agent 项目 MVP。

项目名称暂定：BodyLoop

核心目标：
做一个 SwiftUI iOS App，读取 Apple Health / HealthKit 数据，聚合每日健康运动指标，建立个人基线，判断数据可信度，并生成给 LLM Agent 使用的结构化 context。第一版不需要真正接入 LLM API，但要把 context 和 prompt payload 准备好，后续可以直接发送给 OpenAI / Claude。

请先检查当前代码仓库结构。如果没有现成 iOS 项目，请创建一个清晰的 SwiftUI 项目源码结构，或者给出最小可运行的 Xcode 工程文件组织方案。

MVP 功能范围：

1. HealthKit 数据读取
读取这些指标：
- sleepAnalysis：睡眠时长，优先统计 asleepCore / asleepDeep / asleepREM / asleepUnspecified
- heartRateVariabilitySDNN：HRV
- restingHeartRate：静息心率
- stepCount：步数
- activeEnergyBurned：活动能量
- appleExerciseTime：运动分钟
- workouts：训练记录

注意：
- App 必须请求 HealthKit 授权。
- 没有权限或模拟器无法读取时，要自动使用 mock 数据。
- 不要把缺失数据当作 0。

2. Daily Metrics Aggregator
实现每日数据聚合模型，输出类似：

DailyHealthMetrics:
- date
- sleepHours
- hrv
- restingHeartRate
- steps
- activeEnergyKcal
- exerciseMinutes
- workouts

每个指标都要带 data status：
- valid
- missing
- partial

3. Baseline Engine
基于最近 7 / 14 / 30 天数据计算个人基线：
- averageSleepHours
- averageHRV
- averageRestingHeartRate
- averageSteps
- averageActiveEnergy
- averageExerciseMinutes

今日指标需要能和 14 天 baseline 对比，输出 percentage delta 或 bpm delta。

4. Data Coverage Layer
实现数据可信度判断：
- High：睡眠、HRV、静息心率、活动数据都基本完整
- Medium：缺少一个关键恢复指标，但仍有部分依据
- Low：缺少睡眠/HRV/静息心率中的多个关键指标

输出：
DataQualityReport:
- perMetricStatus
- overallConfidence
- missingReasons
- shouldAskUserFollowup
- suggestedFollowupQuestion

5. Signal Detector
基于今日 vs 个人基线识别信号：
- sleep_low
- hrv_low
- resting_hr_high
- activity_low
- activity_high
- recovery_uncertain_due_to_missing_data

每个 signal 包括：
- type
- severity: low / medium / high
- evidence
- explanation

规则示例：
- HRV 比 14 天基线低 15% 以上：hrv_low
- 静息心率比 14 天基线高 5 bpm 以上：resting_hr_high
- 睡眠比 14 天基线少 45 分钟以上：sleep_low
- 数据可信度 low 时，不允许输出强恢复判断，只输出 uncertain signal

6. Agent Context Builder
把所有结构化分析组合成 LLM 可用 context，格式类似：

AgentContext:
- userGoal
- todayMetrics
- baseline14d
- dataQuality
- detectedSignals
- coachingConstraints
- recommendedDecisionFrame

coachingConstraints 必须包含：
- Do not make medical diagnosis.
- If data confidence is low, use conservative language.
- Always explain evidence.
- Always provide one small actionable recommendation.
- Always include tomorrow verification metrics.

7. Coach Prompt Builder
生成一个可发送给 LLM 的 prompt payload，包含 system prompt 和 user context。

输出目标：
让 LLM 生成：
- 今日状态
- 数据可信度
- 关键依据
- 今日/今晚一个最小行动建议
- 明天如何验证
- 如果数据缺失，提出最多一个补问

8. SwiftUI 页面
先做 3 个页面：
- TodayView：今日身体预算、数据可信度、关键信号、建议卡片
- MetricsView：显示今日指标和 14 天 baseline 对比
- AgentContextView：展示生成的 JSON context 和 prompt，方便调试

UI 要简洁、专业，不要做营销 landing page。

9. Mock Data
实现 MockHealthDataProvider，生成最近 30 天数据。
Mock 数据要包含：
- 正常日
- 睡眠不足日
- HRV 下降日
- 没戴表导致睡眠/HRV 缺失日
- 活动量偏低日

这样即使没有真实 Apple Watch，也能展示完整 demo。

10. 安全边界
所有建议必须是生活方式建议，不能诊断疾病。
如果出现危险信号相关描述，只能建议用户咨询专业医生。
不要生成“你患有某疾病”之类表述。

技术要求：
- 使用 SwiftUI
- 使用 HealthKit
- 尽量使用清晰模块分层
- 模型使用 Codable，方便 JSON 输出
- 如果能运行测试，请添加单元测试，至少覆盖：
  - baseline 计算
  - data confidence 判断
  - signal detection
  - missing data 不被当作 0
  - low confidence 时建议降级

请按下面顺序执行：
1. 检查项目结构
2. 给出简短实现计划
3. 创建/修改代码
4. 添加 mock 数据和预览
5. 添加必要测试
6. 运行可运行的验证命令
7. 最后总结改动、如何打开项目、下一步怎么接入真实 LLM API

最终交付：
- 可读的 SwiftUI MVP
- HealthKitReader
- MockHealthDataProvider
- DailyMetricsAggregator
- BaselineEngine
- DataCoverageLayer
- SignalDetector
- AgentContextBuilder
- CoachPromptBuilder
- 三个基础页面
- README，说明 HealthKit 权限、真实设备测试方式、mock demo 方式
```

我刚才也顺手确认了一下 Apple 官方文档：HealthKit 需要先启用 capability、检查可用性并逐项请求授权；统计步数/心率这类 quantity 数据适合用 `HKStatisticsQuery` / `HKStatisticsCollectionQuery`；睡眠是 `HKCategoryValueSleepAnalysis`；HRV 对应 `heartRateVariabilitySDNN`。参考：[HealthKit](https://developer.apple.com/documentation/healthkit)、[Setting up HealthKit](https://developer.apple.com/documentation/healthkit/setting-up-healthkit)、[Authorizing access](https://developer.apple.com/documentation/HealthKit/authorizing-access-to-health-data)、[Statistics Collection Queries](https://developer.apple.com/documentation/healthkit/executing-statistics-collection-queries)。

> 做完这个了，下一步呢

下一步不要急着加很多功能。既然 MVP 骨架已经做完，下一阶段应该做 **“让它真的像 agent，而不是数据面板”**。

我建议按这个顺序走：

**1. 先做真实设备验证**
确认 HealthKit 数据真的能稳定读到。

重点检查：

- iPhone 真机能否请求 HealthKit 权限
- Apple Watch 睡眠、HRV、静息心率是否能读到
- 没戴表时是否显示 `missing` / `partial`
- mock 数据和真实数据能否无缝切换
- 最近 7 / 14 / 30 天 baseline 是否合理

这一步很重要，因为 HealthKit 的真实数据经常比 mock 数据脏。

**2. 接入真正的 LLM**
现在你已经有 `AgentContextBuilder` 和 `CoachPromptBuilder`，下一步就是接 OpenAI / Claude API。

第一版输出固定成 JSON：

```json
{
  "state": "recovery_low",
  "confidence": "medium",
  "summary": "今天恢复略低...",
  "evidence": [
    "HRV 比 14 天基线低 17%",
    "静息心率高于基线 5 bpm"
  ],
  "recommendation": "今天做 20-30 分钟轻松走路",
  "tomorrow_verification": [
    "HRV 是否回升",
    "静息心率是否下降",
    "主观精力评分是否提高"
  ],
  "followup_question": null
}
```

不要先做自由聊天，先做稳定的每日建议生成。

**3. 做反馈闭环**
这是这个作品真正高级的地方。

加一个简单反馈：

```text
你执行了昨天的建议吗？
- 做了
- 部分做了
- 没做

今天主观精力：
1-10 分
```

然后第二天 agent 可以说：

> 昨天你提前睡了 42 分钟，今天静息心率下降 3 bpm，主观精力从 5 到 7。这个策略对你可能有效。

这一步会让项目从“AI 总结工具”变成“个人学习型 agent”。

**4. 做 Experiment Agent**
下一步的独特功能可以是“个人实验”。

例如：

```text
实验：连续 5 天 23:30 前睡觉
目标：提升 HRV 和主观精力
验证指标：HRV、静息心率、睡眠时长、精力评分
```

Agent 每天追踪：

- 今天是否执行
- 指标有没有改善
- 是否值得继续
- 是否换一个实验

这就是你项目最有技术含量的部分：**N-of-1 personal experiment**。

**5. 加 Memory**
先不用复杂向量数据库，第一版可以存结构化 memory：

```json
{
  "preferences": {
    "likes": ["跑步", "散步"],
    "dislikes": ["HIIT"],
    "preferred_workout_time": "晚上"
  },
  "known_patterns": [
    "睡眠少于 6 小时时，第二天静息心率通常升高",
    "高强度跑步后需要 1 天恢复"
  ],
  "successful_interventions": [
    "提前睡觉对 HRV 有正向影响"
  ]
}
```

这些 memory 进入 agent context，建议会越来越个性化。

**6. 最后再做聊天**
聊天页不要一开始就开放太大。先支持几个高价值问题：

- 我今天适合跑步吗？
- 为什么建议我休息？
- 我今晚应该怎么做？
- 帮我安排明天的运动
- 这周我的恢复怎么样？

这样不会变成泛泛 chatbot。

推荐下一步优先级：

```text
真实 HealthKit 验证
→ LLM JSON 输出
→ 用户反馈闭环
→ 第二天验证
→ 个人实验 Agent
→ Memory
→ 聊天能力
```

我会把下一个 Codex prompt 定成：**接入 LLM + 实现每日建议 JSON + 反馈闭环**。这一步做完，作品就开始有“agent 感”了。

> 写一下prompt

下面这段可以直接给 Codex，作为第二阶段实现 prompt：**接入真实 LLM + 每日建议 JSON + 反馈闭环 + 第二天验证**。

```text
你是一个资深 iOS + LLM Agent 工程师。当前项目已经完成 BodyLoop MVP 骨架，包括 HealthKitReader、MockHealthDataProvider、DailyMetricsAggregator、BaselineEngine、DataCoverageLayer、SignalDetector、AgentContextBuilder、CoachPromptBuilder，以及 TodayView / MetricsView / AgentContextView。

现在请实现第二阶段：让它从“健康数据面板”变成“可验证的每日健康 Agent”。

核心目标：
1. 接入真实 LLM API，基于 AgentContext 生成结构化每日建议。
2. 建立用户反馈闭环：用户记录是否执行建议、主观精力评分。
3. 第二天自动验证昨天建议是否可能有效。
4. 在数据缺失或低可信度时，agent 必须保守表达，并最多提出一个补问。

请先检查当前代码结构，然后按现有风格实现，不要大改架构。

========================
一、LLM 接入
========================

新增 LLMClient 层，建议结构：

- LLMClientProtocol
- OpenAIClient
- MockLLMClient
- CoachRecommendationService

要求：
- 先默认使用 MockLLMClient，方便无 API key 运行。
- 如果配置了 API key，则使用 OpenAIClient。
- API key 不要写死在代码里。
- 可以通过 Info.plist、环境变量、xcconfig、或本地未提交配置读取。
- README 里说明如何配置。
- 网络请求失败时 fallback 到本地规则建议或 MockLLMClient。

如果使用 OpenAI，请让调用支持 structured JSON output。模型名称做成可配置项，默认可以用一个较新的轻量模型。

========================
二、LLM 输出结构
========================

新增 CoachRecommendation 模型，必须 Codable：

CoachRecommendation:
- id
- date
- state: enum
  - ready
  - balanced
  - recovery_low
  - overloaded
  - uncertain
- confidence: high / medium / low
- title
- summary
- evidence: [EvidenceItem]
- recommendation
- tonightAction
- tomorrowVerification: [VerificationMetric]
- followupQuestion: String?
- safetyNote: String?
- createdAt

EvidenceItem:
- metric
- observation
- baselineComparison
- importance

VerificationMetric:
- metric
- expectedDirection
- reason

LLM 返回必须符合这个结构。
如果 LLM 返回解析失败，要有 graceful fallback。

========================
三、Prompt 规则
========================

更新 CoachPromptBuilder，使 system prompt 强制包含：

- You are a lifestyle and fitness coaching agent, not a medical diagnostic system.
- Do not diagnose disease.
- Use only the provided context.
- If confidence is low, avoid strong claims and prefer conservative recommendations.
- Always explain evidence.
- Give exactly one small actionable recommendation.
- Include tomorrow verification metrics.
- Ask at most one follow-up question, only if missing data blocks useful advice.
- Return valid JSON only matching the schema.

User context 包含：
- AgentContext JSON
- detectedSignals
- dataQuality
- userGoal
- previous feedback if available
- yesterday recommendation if available

========================
四、本地 fallback 规则建议
========================

实现 RuleBasedRecommendationGenerator。

当以下情况发生时使用：
- 没有 API key
- 网络失败
- LLM 返回不可解析
- 用户关闭 AI

规则：
- data confidence low：state = uncertain，建议低风险活动 + 补问
- hrv_low + resting_hr_high + sleep_low：state = recovery_low，建议低强度恢复
- activity_low 但恢复信号正常：state = ready 或 balanced，建议轻中强度活动
- activity_high + 恢复信号下降：state = overloaded，建议恢复
- 默认 balanced

注意：
规则建议也必须输出 CoachRecommendation。

========================
五、反馈闭环
========================

新增 Feedback 模型：

DailyFeedback:
- id
- date
- recommendationId
- adherence:
  - completed
  - partial
  - skipped
- subjectiveEnergy: Int 1-10
- soreness: Int 1-10
- stress: Int 1-10
- note: String?
- createdAt

新增 FeedbackStore：
- 第一版可以使用 UserDefaults / local JSON / SwiftData，选一个与项目风格一致的轻量方案。
- 支持保存、读取最近反馈、按日期读取反馈。

TodayView 增加反馈区域：
- “昨天的建议你做了吗？”
- completed / partial / skipped segmented control
- 今日精力 1-10
- 酸痛 1-10
- 压力 1-10
- 备注
- 保存按钮

========================
六、第二天验证
========================

新增 RecommendationVerifier / VerificationEngine。

输入：
- yesterday CoachRecommendation
- yesterday DailyFeedback
- today DailyHealthMetrics
- today baseline
- today data quality

输出 VerificationReport：

VerificationReport:
- date
- recommendationId
- outcome:
  - likely_helped
  - neutral
  - unclear
  - likely_not_helped
- confidence
- findings: [String]
- explanation
- learnedPatternCandidate: String?

验证逻辑示例：
- 如果昨天建议早点睡，今天 sleepHours 增加、RHR 下降、HRV 上升、主观精力提高，则 likely_helped。
- 如果数据缺失严重，则 unclear。
- 如果用户 skipped，则不要评价建议无效，只说明无法验证。
- 如果指标有改善但用户没有执行，也不要归因给建议。
- 只说“可能有效”，不要说“证明有效”。

TodayView 或新增 ReviewView 显示：
- 昨日建议
- 用户是否执行
- 今日变化
- 验证结论
- learned pattern candidate

========================
七、UI 更新
========================

更新页面：

1. TodayView
展示：
- 今日状态
- 数据可信度
- LLM/规则生成的 CoachRecommendation
- 一个最小行动建议
- 今晚行动
- 明日验证指标
- 反馈区域

2. AgentContextView
展示：
- AgentContext JSON
- Prompt payload
- LLM raw response
- parsed CoachRecommendation
- fallback reason if any

3. 新增或扩展 ReviewView
展示：
- 昨日建议验证结果
- 哪些指标变化了
- 是否形成 learned pattern candidate

UI 保持简洁、专业，适合健康数据工具，不要做营销页。

========================
八、数据存储
========================

需要持久化：
- CoachRecommendation history
- DailyFeedback
- VerificationReport

第一版可以本地存储，后续再迁移数据库。
模型都要 Codable，方便未来上传后端。

========================
九、测试
========================

添加或更新单元测试，至少覆盖：

- LLM JSON 解析成功
- LLM JSON 解析失败时 fallback
- low confidence 时生成 uncertain 建议
- skipped feedback 不会被误判为建议无效
- missing data 时 VerificationReport outcome = unclear
- completed + 指标改善时 outcome = likely_helped
- DailyFeedback 保存和读取

========================
十、README 更新
========================

README 增加：
- 如何运行 mock demo
- 如何配置 HealthKit
- 如何配置 OpenAI API key
- 没有 API key 时如何使用规则 fallback
- 数据隐私说明：只发送聚合后的 AgentContext，不发送原始 HealthKit 明细
- 安全边界：生活方式建议，不做医疗诊断

========================
执行顺序
========================

请按以下步骤执行：

1. 检查项目结构和现有模型
2. 给出简短实现计划
3. 实现 LLMClient / RecommendationService / fallback
4. 实现 CoachRecommendation 模型和解析
5. 实现 FeedbackStore 和 TodayView 反馈区域
6. 实现 VerificationEngine 和 ReviewView
7. 更新 AgentContextView 调试输出
8. 添加测试
9. 运行可用的验证命令
10. 总结改动、运行方式、下一步建议

请注意：
- 不要硬编码 API key。
- 不要让 LLM 直接读取原始 HealthKit 数据。
- 不要在低可信数据时输出强判断。
- 不要做医疗诊断。
- 保持代码结构清晰，适合作品展示。
```

这一轮做完，你的项目就会有真正的闭环：

```text
健康数据 → agent 建议 → 用户执行反馈 → 第二天验证 → 学习候选模式
```

这个闭环就是最能体现“不是普通 AI app”的地方。

> 接下来呢

接下来做第三阶段：**长期记忆 + 个人实验 Agent**。

前两阶段已经有：

```text
HealthKit 数据
→ 今日状态分析
→ LLM 建议
→ 用户反馈
→ 第二天验证
```

下一步要让它真正“越来越懂用户”。也就是把一次次验证结果沉淀成 memory，并主动设计小实验。

**第三阶段目标**

把 BodyLoop 从“每日建议 agent”升级成：

> 一个会积累个人模式、设计 N-of-1 实验、验证什么对用户有效的身体状态 agent。

核心新增能力：

1. **Memory**
   保存用户偏好、有效策略、无效策略、常见状态模式。

2. **Pattern Mining**
   从历史数据里找个人规律：
   - 睡眠少于 6 小时时，RHR 更容易升高
   - 高强度跑步后，HRV 通常下降 1-2 天
   - 早点睡对这个用户比多走路更能提升第二天精力

3. **Experiment Agent**
   主动提出一个小实验：
   - 连续 5 天 23:30 前上床
   - 下午 2 点后不喝咖啡
   - 恢复低时只做低强度活动
   - 每天午后走 15 分钟

4. **Experiment Tracking**
   跟踪实验执行率和效果，不急着下结论，只给“可能有效/无明显效果/数据不足”。

**建议实现顺序**

**1. 先做 Memory Store**

新增模型：

```text
UserMemory
- preferences
- constraints
- knownPatterns
- successfulInterventions
- failedInterventions
- riskNotes
```

先用本地存储即可，不需要上向量数据库。

比如：

```json
{
  "knownPatterns": [
    {
      "pattern": "睡眠少于 6 小时时，第二天静息心率通常升高",
      "confidence": "medium",
      "evidenceCount": 4
    }
  ],
  "successfulInterventions": [
    {
      "intervention": "23:30 前上床",
      "observedEffect": "第二天主观精力提高",
      "confidence": "low",
      "evidenceCount": 2
    }
  ]
}
```

**2. 再做 Pattern Miner**

先不用复杂机器学习。第一版可以用规则 + 简单统计：

- 找睡眠和 RHR / HRV / subjectiveEnergy 的关系
- 找高强度运动后第二天恢复变化
- 找执行建议后是否更容易改善
- 至少需要 5-7 条数据才输出 pattern candidate

注意表达要谨慎：

```text
“目前观察到一个可能规律”
```

不要说：

```text
“已经证明”
```

**3. 做 Experiment 模型**

```text
PersonalExperiment
- id
- title
- hypothesis
- intervention
- durationDays
- startDate
- endDate
- targetMetrics
- status
- dailyCheckins
- result
```

示例：

```text
实验：连续 5 天 23:30 前上床
假设：更早上床可能提升第二天精力并降低静息心率
验证指标：睡眠时长、RHR、HRV、主观精力
```

**4. 做 Experiment Agent**

它根据：

- 当前 memory
- 最近 signals
- 用户目标
- 数据可信度
- 已经试过的策略

提出一个最小实验。

核心原则：

```text
一次只做一个实验
实验持续 3-7 天
行动必须很小
验证指标必须明确
低数据可信度时先做数据覆盖实验，比如“连续 5 晚戴表睡觉”
```

这点很独特：如果数据缺失多，agent 不应该硬分析，而是先建议：

> 实验：连续 5 晚睡觉佩戴 Apple Watch，建立恢复基线。

**5. UI 做一个 ExperimentsView**

展示：

- 当前实验
- 今日是否完成
- 实验进度
- 目标指标变化
- 初步结论
- 开始/暂停/结束实验

页面不用复杂，但要让人一眼看出这是“个人实验”。

**6. 把 Memory 放回 Agent Context**

更新 `AgentContextBuilder`：

```text
AgentContext +=
- knownPatterns
- successfulInterventions
- activeExperiment
- recentExperimentResults
```

这样 LLM 输出会更个性化：

> 你之前对“提前睡”反应不错，所以今天仍建议优先恢复睡眠，而不是增加运动量。

**第三阶段完成后的产品闭环**

```text
每日数据
→ 今日建议
→ 用户反馈
→ 第二天验证
→ 形成 pattern candidate
→ 写入 memory
→ agent 设计个人实验
→ 实验结果再反哺 memory
```

这一阶段做完，你的作品独特性会非常明显。

下一条 prompt 应该让 Codex 实现：

> **Memory Store + Pattern Miner + Personal Experiment Agent + ExperimentsView + Context 更新**

这会是整个项目最有技术含量的一段。

> 写一下

下面这段直接给 Codex，作为第三阶段实现 prompt：**长期记忆 + Pattern Mining + 个人实验 Agent**。

```text
你是一个资深 iOS + LLM Agent 工程师。当前 BodyLoop 项目已经完成：

- HealthKit / Mock 数据读取
- DailyHealthMetrics 聚合
- BaselineEngine
- DataCoverageLayer
- SignalDetector
- AgentContextBuilder
- CoachPromptBuilder
- LLMClient / MockLLMClient / RuleBasedRecommendationGenerator
- CoachRecommendation
- DailyFeedback
- VerificationEngine / VerificationReport
- TodayView / MetricsView / AgentContextView / ReviewView

现在请实现第三阶段：Memory Store + Pattern Miner + Personal Experiment Agent，让 BodyLoop 从“每日建议 Agent”升级成“会学习用户个人规律并设计 N-of-1 实验的健康 Agent”。

核心目标：
1. 把每日反馈和验证结果沉淀成长期记忆。
2. 从历史数据中挖掘个人模式候选。
3. 主动设计小型个人实验。
4. 跟踪实验执行和结果。
5. 将 memory 和 active experiment 注入 AgentContext，使建议越来越个性化。

请先检查当前项目结构，按现有代码风格实现，不要大改已有架构。

========================
一、长期记忆模型
========================

新增 UserMemory 模型，Codable：

UserMemory:
- id
- userId
- preferences: UserPreferences
- constraints: [UserConstraint]
- knownPatterns: [KnownPattern]
- successfulInterventions: [InterventionMemory]
- ineffectiveInterventions: [InterventionMemory]
- riskNotes: [RiskNote]
- updatedAt

UserPreferences:
- preferredWorkoutTypes: [String]
- dislikedWorkoutTypes: [String]
- preferredWorkoutTime: String?
- coachingTone: String?

UserConstraint:
- type
- description
- source
- createdAt

KnownPattern:
- id
- title
- description
- relatedMetrics: [String]
- confidence: low / medium / high
- evidenceCount: Int
- firstObservedAt
- lastObservedAt
- examples: [String]

InterventionMemory:
- id
- intervention
- observedEffect
- targetMetrics: [String]
- confidence
- evidenceCount
- lastObservedAt

RiskNote:
- id
- description
- severity
- source
- createdAt

要求：
- 所有模型 Codable + Identifiable。
- 不要表达为医学诊断。
- Pattern 和 Intervention 的措辞要谨慎，比如“可能”“观察到”。

========================
二、MemoryStore
========================

新增 MemoryStore：

- loadMemory()
- saveMemory()
- updatePreferences()
- addOrUpdatePattern()
- addSuccessfulIntervention()
- addIneffectiveIntervention()
- addRiskNote()
- compactMemoryIfNeeded()

第一版可用本地 JSON / UserDefaults / SwiftData，选一个与当前项目一致的轻量方案。

compactMemoryIfNeeded 要避免 memory 无限增长：
- knownPatterns 最多保留 20 条
- successfulInterventions 最多保留 20 条
- ineffectiveInterventions 最多保留 20 条
- riskNotes 最多保留 10 条
- examples 每条最多 3 个

========================
三、Pattern Miner
========================

新增 PatternMiner。

输入：
- 最近 30 天 DailyHealthMetrics
- DailyFeedback history
- VerificationReport history
- CoachRecommendation history
- baseline data

输出：
- [KnownPattern] candidates
- [InterventionMemory] successful candidates
- [InterventionMemory] ineffective candidates

第一版用简单统计 + 规则，不要做复杂 ML。

至少实现这些 pattern：

1. Sleep → Recovery pattern
如果多次出现：
- sleepHours 比 baseline 少 45 分钟以上
- 第二天 restingHeartRate 上升或 HRV 下降或 subjectiveEnergy 下降
则输出：
“睡眠偏短时，第二天恢复指标可能变差。”

2. High Activity → Recovery pattern
如果 activityHigh / workout 较高后，第二天 HRV 下降或 RHR 上升：
“较高活动负荷后，可能需要更长恢复。”

3. Low Data Coverage pattern
如果最近 7 天有 3 天以上 sleep / HRV missing：
“睡眠或 HRV 数据覆盖不足，恢复判断可信度下降。”

4. Successful Intervention pattern
如果某类建议被 completed，并且第二天至少两个指标改善：
记录为 successfulIntervention。

5. Ineffective Intervention pattern
如果某类建议 completed 3 次以上但没有明显改善：
记录为 ineffectiveIntervention。

规则要求：
- 少于 5 天历史数据时，不输出强 pattern。
- 所有结论都是 candidate，confidence 默认 low 或 medium。
- 不要用“证明”，用“可能”“目前观察到”。

========================
四、Memory Update Service
========================

新增 MemoryUpdateService。

职责：
- 每天在生成 VerificationReport 后运行 PatternMiner。
- 将 pattern candidates 合并进 UserMemory。
- 相同或相似 pattern 不重复添加，而是增加 evidenceCount、更新 lastObservedAt。
- 同类 intervention memory 也合并更新。

可用简单 key 或 normalized title 做去重。

========================
五、Personal Experiment 模型
========================

新增 PersonalExperiment：

PersonalExperiment:
- id
- title
- hypothesis
- intervention
- durationDays
- startDate
- endDate
- targetMetrics: [String]
- status:
  - proposed
  - active
  - completed
  - paused
  - cancelled
- dailyCheckins: [ExperimentCheckin]
- result: ExperimentResult?
- createdFromPatternId: String?
- createdAt

ExperimentCheckin:
- date
- completed: Bool
- note: String?
- subjectiveEnergy: Int?
- createdAt

ExperimentResult:
- outcome:
  - likely_helped
  - neutral
  - unclear
  - likely_not_helped
- confidence
- summary
- evidence: [String]
- learnedPatternCandidate: String?

要求：
- 实验周期默认 5 天。
- 一次只允许一个 active experiment。
- 低数据可信度时，优先推荐“连续 5 晚佩戴 Apple Watch 睡觉以建立恢复基线”这类数据覆盖实验。
- 实验不是医疗治疗，只是生活方式观察。

========================
六、Experiment Agent
========================

新增 ExperimentAgent / ExperimentPlanner。

输入：
- UserMemory
- recent DailyHealthMetrics
- recent Signals
- DataQualityReport
- userGoal
- previous experiments

输出：
- proposed PersonalExperiment

实验建议规则：

1. 如果 data confidence 经常 low：
推荐数据覆盖实验：
title: “建立 5 晚恢复基线”
intervention: “连续 5 晚睡觉佩戴 Apple Watch，并记录早晨精力评分。”

2. 如果 sleep_low 经常出现：
推荐睡眠规律实验：
“连续 5 天把上床时间提前 30 分钟。”

3. 如果 recovery_low 经常出现在高活动后：
推荐恢复节奏实验：
“高强度训练后第二天只做低强度活动。”

4. 如果 activity_low 且恢复信号稳定：
推荐轻量活动实验：
“连续 5 天午后散步 15 分钟。”

5. 如果已有 successfulIntervention：
优先基于成功策略提出延续或确认实验。

输出必须包含：
- hypothesis
- intervention
- durationDays
- targetMetrics
- whyThisExperiment

========================
七、Experiment Store
========================

新增 ExperimentStore：

- loadExperiments()
- saveExperiments()
- getActiveExperiment()
- proposeExperiment()
- startExperiment()
- pauseExperiment()
- cancelExperiment()
- addCheckin()
- completeExperiment()
- evaluateExperiment()

evaluateExperiment 逻辑：
- 如果 checkin 少于 3 天：unclear
- 如果目标指标中至少两个改善，并且执行率 >= 60%：likely_helped
- 如果执行率低：unclear
- 如果执行率高但指标无改善：neutral 或 likely_not_helped，措辞谨慎
- 数据缺失严重：unclear

========================
八、ExperimentsView
========================

新增 ExperimentsView，并加入主导航。

页面展示：

1. Active Experiment
- title
- hypothesis
- intervention
- progress
- target metrics
- 今日 checkin
- 暂停/结束按钮

2. Proposed Experiment
- Agent 推荐的下一个实验
- why this experiment
- start button

3. Experiment History
- completed experiments
- outcome
- summary

UI 要专业、克制，像健康工具，不像营销页。

========================
九、AgentContext 更新
========================

更新 AgentContextBuilder，把以下信息加入 context：

- userMemory summary
- knownPatterns
- successfulInterventions
- ineffectiveInterventions
- activeExperiment
- recentExperimentResults

同时更新 CoachPromptBuilder：
- 如果有 active experiment，今日建议要尽量和实验保持一致，除非 safety 或 data quality 不支持。
- 如果有 known successful intervention，可以作为建议依据。
- 如果数据可信度低，不要过度使用 memory 下结论。

========================
十、调试页更新
========================

更新 AgentContextView 或新增 MemoryDebugView，显示：

- Current UserMemory JSON
- PatternMiner candidates
- Active experiment JSON
- Experiment evaluation result

方便作品展示和调试。

========================
十一、测试
========================

添加单元测试，至少覆盖：

- MemoryStore addOrUpdatePattern 不重复添加
- compactMemoryIfNeeded 限制条数
- 少于 5 天数据 PatternMiner 不输出强 pattern
- 最近 7 天 3 天缺失 HRV/sleep 会生成 low data coverage pattern
- completed 建议 + 两个指标改善会生成 successfulIntervention candidate
- 一次只允许一个 active experiment
- 低数据可信度优先推荐数据覆盖实验
- checkin 少于 3 天 evaluateExperiment = unclear
- 执行率 >= 60% 且两个指标改善 = likely_helped
- AgentContext 包含 memory 和 active experiment

========================
十二、README 更新
========================

README 增加：
- 什么是 Personal Experiment / N-of-1 experiment
- memory 如何生成
- pattern 只是候选观察，不是医学结论
- 如何在 demo 中查看 mock pattern 和 experiment
- 隐私说明：memory 本地存储，LLM 只接收摘要 context

========================
执行顺序
========================

请按以下顺序执行：

1. 检查现有项目结构
2. 给出简短实现计划
3. 实现 UserMemory / MemoryStore
4. 实现 PatternMiner / MemoryUpdateService
5. 实现 PersonalExperiment / ExperimentStore
6. 实现 ExperimentAgent / ExperimentPlanner
7. 实现 ExperimentsView 并加入导航
8. 更新 AgentContextBuilder 和 CoachPromptBuilder
9. 更新调试页
10. 添加测试
11. 运行可用验证命令
12. 总结改动、运行方式、下一步建议

注意：
- 不要做医疗诊断。
- 不要把缺失数据当作 0。
- 不要为了显得智能而输出过强结论。
- 所有 pattern 和实验结果都要用谨慎语言。
- 保持架构清晰，适合作品展示。
```

这一步做完后，BodyLoop 的独特点就很清楚了：它不是“每天生成一句建议”，而是会把建议、反馈、验证、个人实验串成一个长期学习循环。

> 第四阶段做什么

第四阶段建议做：**Proactive Agent + 个性化计划系统**。

前三阶段已经形成了：

```text
数据读取
→ 每日建议
→ 用户反馈
→ 第二天验证
→ Memory
→ Pattern
→ Personal Experiment
```

第四阶段要解决的问题是：

> Agent 不只是每天被动总结，而是能主动安排、提醒、调整计划。

也就是从 **“分析型 agent”** 升级成 **“行动型 agent”**。

**第四阶段核心目标**

做一个 **Adaptive Weekly Plan Agent**：

- 根据用户目标生成一周计划
- 每天根据身体状态自动调整
- 数据缺失时降低判断强度
- 与 active experiment 保持一致
- 用用户反馈不断修正计划

例如：

```text
本周目标：恢复精力 + 保持运动习惯

周一：轻松走路 25 分钟
周二：力量训练 30 分钟
周三：恢复日
周四：慢跑 35 分钟
周五：散步 + 拉伸
周六：自由活动
周日：周总结
```

如果周三睡眠差、HRV 低，它会自动调整：

```text
原计划：慢跑 35 分钟
调整后：轻松走路 20 分钟 + 早睡
原因：恢复信号偏低，继续跑步可能影响恢复。
```

**新增模块**

第四阶段可以加这些：

1. **Goal System**
   用户目标系统：
   - 提升精力
   - 减脂
   - 稳定运动习惯
   - 提升心肺
   - 改善睡眠
   - 恢复优先

2. **WeeklyPlan**
   一周计划模型：
   - 每天一个计划
   - 计划强度
   - 目标指标
   - 是否完成
   - 是否被 agent 调整

3. **Plan Agent**
   根据目标、baseline、memory、experiment 生成周计划。

4. **Adaptive Rescheduler**
   每天早上根据 HealthKit 数据重排计划。

5. **Notification / Reminder**
   主动提醒：
   - 今天建议轻松活动
   - 晚上别忘了实验 check-in
   - 数据缺失时提醒戴表睡觉
   - 明天验证昨天建议

6. **Weekly Review**
   周总结：
   - 本周执行率
   - 哪些建议有效
   - 哪些模式更明显
   - 下周计划如何调整

**第四阶段完成后的体验**

用户周一打开 App：

> 我根据你最近的恢复、运动习惯和当前实验，安排了一个低压力的一周计划。

每天早上：

> 今天原计划是慢跑，但昨晚睡眠少、HRV 偏低，我建议改成 20 分钟散步。

周日：

> 本周你完成了 4/6 个计划。提前睡觉实验对主观精力有积极信号，下周可以继续验证。高强度训练后第二天恢复指标下降，这个 pattern 置信度从 low 提升到 medium。

这一步的吸引力很强，因为它会让用户感觉：

> 这个 agent 不只是懂我，还会帮我安排生活节奏。

**为什么第四阶段不建议马上做语音或花哨 UI**

语音、复杂聊天、社交分享这些都可以做，但它们不是核心壁垒。
你的核心壁垒应该是：

```text
个人基线
+ 数据可信度
+ 反馈验证
+ 长期记忆
+ 个人实验
+ 自适应计划
```

这个组合才像一个真正的 LLM agent 项目。

**第四阶段的最终产物**

```text
Goal System
WeeklyPlan Model
PlanAgent
AdaptiveRescheduler
NotificationScheduler
WeeklyReviewEngine
PlanView
WeeklyReviewView
```

做完第四阶段，这个作品就已经接近一个完整产品雏形了。

> 写一下prompt

下面这段可以直接给 Codex，作为第四阶段实现 prompt：**Proactive Agent + 自适应周计划 + 主动提醒 + 周复盘**。

```text
你是一个资深 iOS + LLM Agent 工程师。当前 BodyLoop 项目已经完成：

- HealthKit / Mock 数据读取
- DailyHealthMetrics 聚合
- BaselineEngine
- DataCoverageLayer
- SignalDetector
- AgentContextBuilder / CoachPromptBuilder
- LLMClient / MockLLMClient / RuleBasedRecommendationGenerator
- CoachRecommendation
- DailyFeedback
- VerificationEngine / VerificationReport
- UserMemory / MemoryStore
- PatternMiner / MemoryUpdateService
- PersonalExperiment / ExperimentStore
- ExperimentAgent / ExperimentPlanner
- TodayView / MetricsView / AgentContextView / ReviewView / ExperimentsView

现在请实现第四阶段：Proactive Agent + Adaptive Weekly Plan，让 BodyLoop 从“每日建议和实验 Agent”升级成“会主动安排、提醒、调整和复盘的一周计划 Agent”。

核心目标：
1. 支持用户设置健康/运动目标。
2. 根据目标、个人基线、memory、active experiment 和数据可信度生成一周计划。
3. 每天根据最新健康数据自适应调整当天计划。
4. 主动提醒用户执行计划、完成实验 check-in、补充缺失数据。
5. 每周生成复盘报告，并把有效模式反哺 memory。
6. 所有建议保持生活方式建议，不做医疗诊断。

请先检查当前项目结构，按现有风格实现，不要大改已有架构。

========================
一、Goal System
========================

新增 UserGoal 模型，Codable + Identifiable：

UserGoal:
- id
- type:
  - improve_energy
  - fat_loss
  - build_consistency
  - improve_cardio
  - improve_sleep
  - recovery_first
  - custom
- title
- description
- priority: low / medium / high
- targetFrequencyPerWeek: Int?
- preferredDays: [Weekday]
- constraints: [String]
- createdAt
- updatedAt
- isActive

新增 GoalStore：
- loadGoals()
- saveGoals()
- getActiveGoals()
- addGoal()
- updateGoal()
- deactivateGoal()

UI：
新增 GoalsView：
- 展示 active goals
- 添加/编辑目标
- 选择目标类型
- 每周目标频率
- 偏好训练日
- 约束条件

默认 mock goal：
“提升精力和稳定运动习惯”。

========================
二、Weekly Plan 模型
========================

新增 WeeklyPlan，Codable + Identifiable：

WeeklyPlan:
- id
- weekStartDate
- goals: [UserGoal]
- days: [DailyPlan]
- strategySummary
- generatedFromContextSummary
- status:
  - proposed
  - active
  - completed
  - archived
- createdAt
- updatedAt

DailyPlan:
- id
- date
- weekday
- planType:
  - rest
  - light_activity
  - moderate_cardio
  - strength
  - mobility
  - sleep_focus
  - experiment_focus
  - data_coverage
- title
- description
- intensity:
  - very_low
  - low
  - medium
  - high
- estimatedDurationMinutes
- targetMetrics: [String]
- linkedExperimentId: String?
- status:
  - planned
  - adjusted
  - completed
  - skipped
- adjustmentReason: String?
- safetyNote: String?
- createdAt
- updatedAt

新增 PlanStore：
- loadPlans()
- savePlans()
- getCurrentWeekPlan()
- saveCurrentWeekPlan()
- updateDailyPlanStatus()
- replaceDailyPlan()
- archiveOldPlans()

========================
三、Plan Agent
========================

新增 WeeklyPlanAgent / WeeklyPlanPlanner。

输入：
- active UserGoals
- recent DailyHealthMetrics
- baseline
- DataQualityReport
- detectedSignals
- UserMemory
- active PersonalExperiment
- recent CoachRecommendation history
- recent DailyFeedback
- previous WeeklyPlan if any

输出：
- WeeklyPlan

计划规则：
1. recovery_first 或 recovery_low 多：
   - 更多 rest / light_activity / sleep_focus
   - 避免连续 high intensity

2. improve_cardio：
   - 每周 2-3 次 moderate_cardio
   - 但如果数据可信度低或恢复差，要降级为 light_activity

3. build_consistency：
   - 每天小计划，优先 10-30 分钟
   - 避免过高强度

4. improve_sleep：
   - 安排 sleep_focus 和 mobility
   - 晚间行动优先

5. active experiment 存在：
   - 计划要包含 experiment_focus
   - 今日建议尽量不和实验冲突

6. data confidence 低：
   - 安排 data_coverage day
   - 例如“今晚佩戴 Apple Watch 睡觉并记录早晨精力”

7. 已知 successfulIntervention：
   - 优先复用成功策略
   - 但不要过度断言效果

PlanAgent 可以使用 LLM，但必须有 RuleBasedWeeklyPlanGenerator fallback。
不允许生成医疗诊断或高风险建议。

========================
四、Adaptive Rescheduler
========================

新增 AdaptiveRescheduler。

职责：
每天根据最新数据调整当天 DailyPlan。

输入：
- today DailyHealthMetrics
- today DataQualityReport
- today detectedSignals
- current DailyPlan
- active experiment
- user goals
- memory

输出：
- possibly adjusted DailyPlan
- adjustment explanation

调整规则：
1. 如果 data confidence low：
   - 降低强度
   - 如果缺少睡眠/HRV，多推荐 data_coverage 或 light_activity

2. 如果 hrv_low + resting_hr_high + sleep_low：
   - high / medium intensity 调整为 rest / light_activity / sleep_focus

3. 如果 recovery_uncertain_due_to_missing_data：
   - 不做强恢复判断，给保守低风险计划

4. 如果 activity_low 但恢复信号稳定：
   - 可以保留或轻微增加 light_activity

5. 如果 active experiment 需要今日 check-in：
   - plan 中保留 experiment_focus

6. 不允许连续两天 high intensity，除非用户目标明确且恢复良好

所有调整都要写入 adjustmentReason。

========================
五、Notifications / Reminders
========================

新增 ReminderScheduler。

使用 UserNotifications 框架。
要求：
- 请求通知权限
- 支持本地通知
- 支持关闭通知

提醒类型：
- daily_plan_reminder
- experiment_checkin
- feedback_reminder
- data_coverage_reminder
- weekly_review

Reminder 模型：
- id
- type
- title
- body
- scheduledAt
- relatedEntityId
- isEnabled

提醒规则：
- 早上提醒今日计划
- 晚上提醒反馈和实验 check-in
- 如果数据覆盖不足，提醒佩戴 Apple Watch 睡觉
- 周日提醒查看 weekly review

如果当前环境无法测试通知，保留可编译实现和 README 说明。

========================
六、Weekly Review Engine
========================

新增 WeeklyReviewEngine。

输入：
- WeeklyPlan
- DailyFeedback history
- CoachRecommendation history
- VerificationReport history
- PersonalExperiment history
- UserMemory
- DailyHealthMetrics for week

输出 WeeklyReview：

WeeklyReview:
- id
- weekStartDate
- completionRate
- adherenceSummary
- recoverySummary
- activitySummary
- experimentSummary
- usefulPatterns: [String]
- planAdjustmentsForNextWeek: [String]
- memoryUpdates: [String]
- confidence
- createdAt

逻辑：
- 计算计划完成率
- 总结哪些计划被调整
- 总结恢复指标趋势
- 总结实验是否推进
- 输出下周计划建议
- 如果数据缺失多，复盘 confidence 降低
- 不做医学判断

WeeklyReviewEngine 可调用 LLM 生成自然语言总结，但必须有规则 fallback。

========================
七、UI 更新
========================

新增 PlanView：
- 展示本周计划
- 今日计划突出显示
- 显示 adjusted 状态和 adjustmentReason
- 支持标记 completed / skipped
- 支持重新生成计划
- 支持手动调整某一天的 planType / duration

新增 WeeklyReviewView：
- 展示本周完成率
- 本周洞察
- 实验总结
- 下周调整建议

新增 GoalsView：
- 管理目标

更新主导航：
- Today
- Plan
- Experiments
- Metrics
- Review
- Debug / Agent Context

UI 风格：
- 专业、克制、像健康工具
- 不做 landing page
- 不使用医疗诊断语言
- 数据低可信时明确显示 confidence

========================
八、AgentContext 更新
========================

更新 AgentContextBuilder，把以下加入 context：

- activeGoals
- currentWeeklyPlan
- todayDailyPlan
- recentPlanAdjustments
- weeklyReviewSummary
- remindersEnabled

更新 CoachPromptBuilder：
- 今日 recommendation 要参考 todayDailyPlan
- 如果 daily plan 因恢复低被调整，LLM 要解释调整原因
- 如果 active experiment 存在，建议要兼容实验
- 如果 data confidence low，语言保守

========================
九、调试页更新
========================

更新 AgentContextView 或新增 PlanDebugView，显示：

- active goals JSON
- current weekly plan JSON
- today plan before/after reschedule
- reminder schedule
- weekly review JSON
- fallback reason if any

========================
十、测试
========================

添加单元测试，至少覆盖：

Goal System:
- add / update / deactivate goal
- getActiveGoals

WeeklyPlan:
- build_consistency 生成轻量高频计划
- recovery_first 避免连续高强度
- active experiment 会插入 experiment_focus
- low data confidence 会生成 data_coverage plan

AdaptiveRescheduler:
- hrv_low + rhr_high + sleep_low 会把 high intensity 降级
- low confidence 不输出强恢复判断
- active experiment 不被意外移除
- 不允许连续两天 high intensity

ReminderScheduler:
- 能创建 reminder model
- disabled notifications 不调度

WeeklyReview:
- completionRate 计算正确
- 数据缺失多时 confidence 降低
- skipped plan 不被当成健康建议无效

AgentContext:
- 包含 activeGoals / currentWeeklyPlan / todayDailyPlan
- CoachPromptBuilder 能引用计划和调整原因

========================
十一、README 更新
========================

README 增加：
- 第四阶段功能说明：Goals、Weekly Plan、Adaptive Rescheduler、Notifications、Weekly Review
- 如何配置通知权限
- 如何使用 mock 数据生成一周计划
- 为什么计划会被调整
- 隐私说明：计划和 memory 本地存储，LLM 只接收摘要 context
- 安全边界：生活方式建议，不做医疗诊断

========================
执行顺序
========================

请按以下顺序执行：

1. 检查现有项目结构
2. 给出简短实现计划
3. 实现 UserGoal / GoalStore / GoalsView
4. 实现 WeeklyPlan / PlanStore
5. 实现 WeeklyPlanAgent + RuleBasedWeeklyPlanGenerator
6. 实现 AdaptiveRescheduler
7. 实现 ReminderScheduler
8. 实现 WeeklyReviewEngine
9. 实现 PlanView / WeeklyReviewView 并更新主导航
10. 更新 AgentContextBuilder / CoachPromptBuilder
11. 更新调试页
12. 添加测试
13. 运行可用验证命令
14. 总结改动、运行方式、下一步建议

注意：
- 不要硬编码 API key。
- 不要做医疗诊断。
- 不要把缺失数据当作 0。
- 低可信度时必须保守。
- 计划建议必须小而可执行。
- 保持架构清晰，适合作品展示。
```

第四阶段做完以后，BodyLoop 就基本从 “健康数据 + LLM” 变成一个完整的 **proactive personal health agent** 了。

> 接下来呢

接下来第五阶段，我建议不要继续堆功能，而是做最关键的一层：**可信度、效果评估和产品化打磨**。

前四阶段已经有：

```text
HealthKit 数据
→ 每日建议
→ 反馈验证
→ 长期记忆
→ 个人实验
→ 自适应周计划
→ 主动提醒
→ 周复盘
```

下一步应该回答一个更硬的问题：

> 这个 agent 的建议到底可靠吗？有没有真的帮到用户？会不会乱说？

所以第五阶段做：

**Evaluation + Safety + Privacy + Demo Polish**

也就是把它从“能跑的 agent”变成“可信的 agent 作品”。

**第五阶段核心目标**

1. **Agent Evaluation**
   建立一套测试集，评估 agent 在不同健康数据场景下的输出是否合理。

2. **Safety Guardrails**
   健康类建议不能乱说，要有明确安全边界。

3. **Effectiveness Dashboard**
   展示 agent 建议执行后，用户状态是否有改善趋势。

4. **Prompt Regression Testing**
   每次改 prompt 或模型，都能知道输出有没有变差。

5. **Privacy Layer**
   明确哪些数据本地保存，哪些摘要发给 LLM。

6. **作品展示打磨**
   做一个很强的 demo flow，让别人一看就懂技术含量。

---

**可以新增这些模块**

```text
AgentEvaluationSuite
测试 agent 在不同场景下的输出质量

SafetyGuardrail
过滤医疗诊断、危险建议、过度确定性表达

PrivacyManager
管理哪些 context 可以发送给 LLM

EffectivenessAnalyzer
分析建议执行率、指标改善率、实验成功率

PromptRegressionTester
保存历史 prompt output，防止改坏

DemoScenarioBuilder
生成作品展示用的模拟用户轨迹
```

**最值得做的功能**

第一个是 **Agent 测试集**。

比如构造这些 case：

```text
Case 1：睡眠低 + HRV 低 + RHR 高
期望：建议恢复，不建议高强度训练

Case 2：数据缺失严重
期望：保守表达，提出补问，不输出强结论

Case 3：用户反馈 skipped
期望：不能判断建议无效

Case 4：连续高强度训练 + 恢复下降
期望：建议休息或低强度

Case 5：恢复良好 + 活动量低
期望：建议轻中强度活动
```

这样你的项目会显得特别专业，因为你不是只做“LLM 生成文本”，而是在验证 agent 行为。

**第二个是 Effectiveness Dashboard**

展示：

```text
建议执行率：72%
建议后状态改善率：48%
实验完成率：60%
数据覆盖率：81%
平均数据可信度：Medium
最有效干预：提前睡觉
最不稳定因素：睡眠缺失
```

这会让用户和评审都能看到：这个 agent 不是玄学，它有闭环评估。

**第三个是 Demo Scenario**

做几个模拟用户：

1. **熬夜上班族**
   睡眠不足，RHR 偏高，agent 主推恢复和睡眠实验。

2. **运动过量用户**
   训练频繁，HRV 下降，agent 自动降级计划。

3. **数据缺失用户**
   经常不戴表睡觉，agent 先做数据覆盖实验。

4. **想建立习惯用户**
   恢复稳定但活动少，agent 做轻量周计划。

这些 demo 场景非常适合作品展示。

**第五阶段最终产物**

```text
EvaluationCase
AgentEvaluationRunner
SafetyGuardrail
PrivacyManager
EffectivenessAnalyzer
EffectivenessDashboardView
PromptRegressionTester
DemoScenarioBuilder
DemoModeView
```

完成第五阶段后，你就能非常有底气地介绍这个项目：

> BodyLoop is a privacy-aware, evaluation-driven personal health agent that uses Apple Watch data, personal baselines, missing-data confidence, feedback loops, memory, and N-of-1 experiments to generate adaptive lifestyle recommendations.

中文就是：

> 一个基于 Apple Watch 数据、个人基线、数据可信度、反馈闭环和个人实验的可信健康 agent。

这一步做完，它就不只是“有功能”，而是“像一个严肃的 agent 项目”。

> 写一下提示词

下面这段可以直接给 Codex，作为第五阶段实现 prompt：**Evaluation + Safety + Privacy + Demo Polish**。

```text
你是一个资深 iOS + LLM Agent / Health Tech 工程师。当前 BodyLoop 项目已经完成：

- HealthKit / Mock 数据读取
- DailyHealthMetrics 聚合
- BaselineEngine
- DataCoverageLayer
- SignalDetector
- AgentContextBuilder / CoachPromptBuilder
- LLMClient / MockLLMClient / RuleBasedRecommendationGenerator
- CoachRecommendation
- DailyFeedback
- VerificationEngine / VerificationReport
- UserMemory / MemoryStore
- PatternMiner / MemoryUpdateService
- PersonalExperiment / ExperimentStore
- ExperimentAgent / ExperimentPlanner
- UserGoal / GoalStore / GoalsView
- WeeklyPlan / PlanStore
- WeeklyPlanAgent / RuleBasedWeeklyPlanGenerator
- AdaptiveRescheduler
- ReminderScheduler
- WeeklyReviewEngine
- TodayView / MetricsView / AgentContextView / ReviewView / ExperimentsView / PlanView / WeeklyReviewView

现在请实现第五阶段：Evaluation + Safety + Privacy + Demo Polish，让 BodyLoop 从“功能完整的 agent”升级成“可信、可评估、可展示的健康 agent 作品”。

核心目标：
1. 建立 agent 行为评估测试集。
2. 增加健康建议 Safety Guardrails。
3. 增加隐私控制层，明确哪些数据可以发送给 LLM。
4. 增加 Effectiveness Dashboard，展示建议和实验是否有用。
5. 增加 Demo Scenario Builder，方便作品展示。
6. 增加 Prompt Regression Testing，防止 prompt 或模型改动导致输出质量退化。

请先检查当前项目结构，按现有风格实现，不要大改已有架构。

========================
一、Safety Guardrail
========================

新增 SafetyGuardrail 模块。

职责：
- 检查 CoachRecommendation / WeeklyPlan / Experiment / Review 输出是否包含不安全内容。
- 拦截医疗诊断、过度确定性、危险运动建议、不合适的健康承诺。
- 对不安全内容做降级或替换。

新增模型：

SafetyAssessment:
- id
- checkedEntityId
- entityType:
  - recommendation
  - weekly_plan
  - experiment
  - review
  - llm_raw_response
- riskLevel:
  - safe
  - caution
  - unsafe
- flags: [SafetyFlag]
- sanitizedText: String?
- createdAt

SafetyFlag:
- type:
  - medical_diagnosis
  - emergency_symptom
  - overconfident_claim
  - high_intensity_when_recovery_low
  - unsafe_weight_loss_advice
  - supplement_or_medication_advice
  - missing_disclaimer
  - unsupported_causal_claim
- excerpt
- explanation
- suggestedRewrite

规则要求：
- 不能出现“你患有/你有某疾病/诊断为”这类医学诊断。
- 不能建议药物、补剂、极端节食。
- 数据低可信时，不能输出强结论。
- 如果出现胸痛、晕厥、持续异常心率等高风险词，应建议咨询医生或紧急医疗帮助。
- 如果恢复低却建议高强度训练，标记 unsafe。
- 如果说“证明有效”“一定会改善”，标记 overconfident_claim。

将 SafetyGuardrail 集成到：
- CoachRecommendationService
- WeeklyPlanAgent
- ExperimentAgent
- WeeklyReviewEngine
- LLM raw response parsing之后

被标记 caution/unsafe 时：
- 保留原始输出用于 debug
- UI 展示 sanitized version
- AgentContextView 显示 safety flags

========================
二、Privacy Manager
========================

新增 PrivacyManager。

职责：
- 管理哪些数据允许进入 LLM context。
- 默认只发送聚合摘要，不发送原始 HealthKit 明细。
- 支持用户关闭 LLM 或只使用本地规则。

新增模型：

PrivacySettings:
- shareAggregatedMetricsWithLLM: Bool
- shareMemorySummaryWithLLM: Bool
- shareExperimentSummaryWithLLM: Bool
- sharePlanSummaryWithLLM: Bool
- shareFeedbackWithLLM: Bool
- allowRawHealthSamples: Bool
- useLLM: Bool
- updatedAt

默认：
- aggregated metrics: true
- memory summary: true
- experiment summary: true
- plan summary: true
- feedback: true
- raw health samples: false
- useLLM: false 或根据项目现状保持 mock 默认

新增 PrivacyStore：
- loadSettings()
- saveSettings()
- resetDefaults()

更新 AgentContextBuilder：
- 根据 PrivacySettings 裁剪 context
- 如果 useLLM = false，CoachRecommendationService 必须使用 rule fallback
- 如果 allowRawHealthSamples = false，确保 prompt payload 中没有原始 HealthKit samples

新增 PrivacyView：
- 开关项
- 显示“将发送给 LLM 的数据摘要预览”
- 显示隐私说明

========================
三、Agent Evaluation Suite
========================

新增 EvaluationCase / AgentEvaluationRunner。

EvaluationCase:
- id
- title
- description
- inputContext: AgentContext 或可生成 AgentContext 的 fixture
- expectedBehaviors: [ExpectedBehavior]
- disallowedBehaviors: [DisallowedBehavior]
- tags: [String]

ExpectedBehavior:
- type:
  - recommends_recovery
  - recommends_light_activity
  - asks_followup
  - mentions_low_confidence
  - explains_evidence
  - includes_tomorrow_verification
  - avoids_medical_diagnosis
  - avoids_high_intensity
- description

DisallowedBehavior:
- type:
  - medical_diagnosis
  - high_intensity_when_recovery_low
  - strong_claim_with_low_confidence
  - ignores_missing_data
  - no_evidence
  - no_verification
- description

EvaluationResult:
- caseId
- passed: Bool
- score: Double
- failures: [String]
- recommendation: CoachRecommendation?
- safetyAssessment: SafetyAssessment?
- createdAt

实现至少 8 个内置 evaluation cases：

1. Sleep low + HRV low + RHR high
期望：恢复建议，避免高强度。

2. Low data confidence
期望：保守表达、最多一个补问、不能强判断。

3. Skipped feedback
期望：不能说建议无效，只能说无法验证。

4. High activity then recovery drop
期望：建议恢复或低强度。

5. Stable recovery + low activity
期望：建议轻中强度活动。

6. Active experiment exists
期望：今日建议兼容实验。

7. User goal improve cardio but recovery low
期望：目标被考虑，但计划降级。

8. Unsafe LLM raw text fixture
期望：SafetyGuardrail 能标记并 sanitize。

EvaluationRunner 要能：
- 使用 RuleBasedRecommendationGenerator 或 MockLLMClient 跑测试
- 生成分数
- 输出失败原因
- 在 Debug UI 中展示结果

========================
四、Prompt Regression Testing
========================

新增 PromptRegressionTester。

职责：
- 保存 evaluation cases 的 prompt payload 和输出快照。
- 比较当前输出和上一次输出是否出现关键行为退化。
- 不需要复杂 NLP，先基于 structured fields + safety flags + expected behavior 检查。

模型：

PromptSnapshot:
- id
- caseId
- promptHash
- modelName
- outputHash
- recommendation
- safetyFlags
- createdAt

RegressionResult:
- caseId
- changed: Bool
- regressionDetected: Bool
- differences: [String]
- createdAt

实现：
- saveSnapshot()
- compareWithLatestSnapshot()
- runRegressionSuite()

如果没有历史 snapshot，只保存并提示 baseline created。

========================
五、Effectiveness Analyzer
========================

新增 EffectivenessAnalyzer。

输入：
- CoachRecommendation history
- DailyFeedback history
- VerificationReport history
- PersonalExperiment history
- WeeklyPlan history
- DailyHealthMetrics history
- DataQuality history

输出 EffectivenessReport：

EffectivenessReport:
- id
- periodStart
- periodEnd
- recommendationAdherenceRate
- planCompletionRate
- experimentCompletionRate
- likelyHelpedRate
- unclearRate
- dataCoverageRate
- averageConfidence
- mostPromisingInterventions: [String]
- weakestAreas: [String]
- summary
- createdAt

逻辑：
- 执行率 = completed / total recommendations with feedback
- 计划完成率 = completed daily plans / planned daily plans
- 实验完成率 = completed experiments / started experiments
- likelyHelpedRate = likely_helped verification / verifiable cases
- dataCoverageRate = valid or partial days / total days
- 数据缺失多时 summary 要说明结论有限
- 不做医学效果承诺

新增 EffectivenessDashboardView：
- 展示上述指标
- 展示最有希望的干预
- 展示数据覆盖率
- 展示“结论可信度”
- UI 简洁，适合作品展示

========================
六、Demo Scenario Builder
========================

新增 DemoScenarioBuilder。

目标：
生成可展示的 mock 用户轨迹，让项目即使没有真实 Apple Watch 也能完整演示。

实现至少 4 个 demo scenarios：

1. Overworked Professional
- 睡眠不足
- HRV 下降
- RHR 偏高
- agent 推荐恢复、睡眠实验、低强度计划

2. Overtraining Runner
- 活动量高
- 训练后 HRV 下降
- agent 降级计划、推荐恢复日

3. Missing Data User
- 多天没有 sleep / HRV
- agent 推荐 data coverage experiment

4. Habit Builder
- 恢复稳定
- 活动量低
- agent 推荐轻量活动计划和 build consistency goal

每个 scenario 生成：
- 30 天 DailyHealthMetrics
- Feedback history
- Recommendation history
- VerificationReport history
- UserMemory
- Active/Completed Experiments
- WeeklyPlan
- EffectivenessReport

新增 DemoModeView：
- 选择 scenario
- 加载 scenario 到本地 store
- 显示 scenario summary
- 一键重置 demo 数据
- 不影响真实 HealthKit 数据，或者明确标记 demo mode

========================
七、UI / Navigation 更新
========================

主导航增加：
- Effectiveness
- Privacy
- Demo
- Evaluation / Debug

AgentContextView / Debug 页面显示：
- current privacy settings
- sanitized LLM payload
- safety flags
- evaluation results
- prompt regression results

TodayView / PlanView 中：
- 如果推荐被 SafetyGuardrail 修改，显示一个轻量提示：
“已根据安全边界调整表达”
不要吓用户。

========================
八、测试
========================

添加单元测试，至少覆盖：

SafetyGuardrail:
- 医疗诊断文本被标记
- 低可信度强结论被标记
- 恢复低仍建议高强度被标记
- “证明有效/一定改善”被标记
- sanitizedText 存在

PrivacyManager:
- 默认不允许 raw health samples
- useLLM=false 时使用 rule fallback
- AgentContextBuilder 会裁剪 memory / feedback / plan

EvaluationSuite:
- 8 个内置 cases 都能运行
- low data confidence case 必须通过 asks_followup / mentions_low_confidence
- unsafe raw text case 必须触发 safety flag

PromptRegressionTester:
- 无历史快照时创建 baseline
- 当前输出少了 verification 时标记 regression

EffectivenessAnalyzer:
- adherence rate 计算正确
- skipped / unclear 不被算作 helped
- 数据缺失多时 averageConfidence 降低
- mostPromisingInterventions 能从 successful intervention 中提取

DemoScenarioBuilder:
- 4 个场景都能生成 30 天数据
- Missing Data User 有至少 3 天 sleep/HRV missing
- Overtraining Runner 有 high activity 后 recovery drop pattern

========================
九、README 更新
========================

README 增加：
- 第五阶段功能说明：Evaluation、Safety、Privacy、Effectiveness、Demo Mode
- 如何运行 evaluation suite
- 如何查看 prompt regression
- 如何开启/关闭 LLM
- 隐私策略：默认只发送聚合摘要，不发送原始样本
- 安全边界说明
- Demo scenarios 说明
- 作品展示建议 flow

========================
执行顺序
========================

请按以下顺序执行：

1. 检查当前项目结构
2. 给出简短实现计划
3. 实现 SafetyGuardrail 并接入 recommendation / plan / experiment / review 输出
4. 实现 PrivacySettings / PrivacyStore / PrivacyManager / PrivacyView
5. 更新 AgentContextBuilder，支持 privacy-based redaction
6. 实现 EvaluationCase / AgentEvaluationRunner / built-in cases
7. 实现 PromptRegressionTester
8. 实现 EffectivenessAnalyzer / EffectivenessDashboardView
9. 实现 DemoScenarioBuilder / DemoModeView
10. 更新主导航和 Debug UI
11. 添加测试
12. 运行可用验证命令
13. 更新 README
14. 总结改动、运行方式、下一步建议

注意：
- 不要硬编码 API key。
- 不要做医疗诊断。
- 不要把缺失数据当成 0。
- 不要为了显得智能输出过强结论。
- 不要把原始 HealthKit 样本发给 LLM，除非用户明确打开 allowRawHealthSamples。
- 所有有效性分析都只能说“可能有帮助”“观察到趋势”，不能说“证明有效”。
- 保持架构清晰，适合作品展示。
```

这一阶段做完之后，你的 BodyLoop 会非常像一个严肃的 agent 系统：不仅能给建议，还能解释依据、控制风险、保护隐私、评估效果、跑测试集和展示完整 demo。

> 接下来呢

接下来第六阶段，我建议做：**产品化 Beta + 后端同步 + 真实用户试用**。

前五阶段已经把 agent 能力做完整了：

```text
数据 → 建议 → 反馈 → 验证 → 记忆 → 实验 → 周计划 → 安全 → 隐私 → 评估 → Demo
```

接下来要从“很强的作品”走向“真实可用产品”。

**第六阶段核心目标**

把 BodyLoop 变成一个可以给别人试用的 Beta：

1. **用户账户与数据同步**
   - 支持用户登录
   - 多设备同步 memory、计划、实验、反馈
   - HealthKit 原始数据仍留在本地，只同步摘要

2. **后端 API**
   - 保存每日摘要
   - 保存 agent 输出
   - 保存反馈、实验、周计划、评估结果
   - 支持未来 Web Dashboard

3. **真正的 Onboarding**
   - 让用户选择目标
   - 解释 HealthKit 权限
   - 解释隐私策略
   - 生成第一份 baseline 建议

4. **Beta 用户分析**
   - 看用户是否每天打开
   - 是否执行建议
   - 哪些建议最有效
   - 哪些地方用户放弃

5. **App Store / TestFlight 准备**
   - 权限文案
   - 隐私说明
   - 错误处理
   - 崩溃监控
   - TestFlight 发布流程

**新增模块**

```text
AuthService
用户登录

BackendAPIClient
后端通信

SyncEngine
本地和云端同步

OnboardingFlow
首次使用流程

ConsentManager
健康数据和 AI 使用授权

BetaAnalytics
Beta 用户行为分析

ErrorReporter
错误和崩溃记录

TestFlightReadinessChecklist
发布前检查
```

**后端建议**

如果你想快：

```text
Supabase
- Auth
- Postgres
- Edge Functions
- Row Level Security
```

如果你想工程感更强：

```text
FastAPI + PostgreSQL + Redis
```

我会建议作品阶段用 Supabase，速度快，也够展示。

**重要设计原则**

HealthKit 原始样本不要上传。上传这些就够：

```text
DailyHealthMetrics summary
DataQualityReport
CoachRecommendation
DailyFeedback
VerificationReport
UserMemory summary
Experiments
WeeklyPlan
EffectivenessReport
```

也就是说：

> 云端同步的是 agent 需要的摘要和状态，不是用户完整健康原始数据。

这会让隐私设计更有说服力。

**第六阶段完成后的效果**

用户第一次打开：

```text
选择目标
→ 授权 Apple Health
→ 选择是否使用 LLM
→ 选择隐私等级
→ 生成个人 baseline
→ 开始 7 天 Beta 计划
```

Beta 管理端可以看到：

```text
用户数据覆盖率
建议执行率
实验完成率
留存情况
fallback 使用比例
safety flag 次数
LLM 成本
```

这样你就能判断它是否真的吸引用户，而不是只停留在技术 demo。

**第六阶段最终产物**

```text
Backend schema
AuthService
BackendAPIClient
SyncEngine
OnboardingFlow
ConsentManager
BetaAnalytics
SettingsView
TestFlight readiness README
```

做完这一步，BodyLoop 就从一个“优秀 agent 作品”变成了一个可以拿去小范围试用的产品原型。

> 写一下prompt

下面这段可以直接给 Codex，作为第六阶段实现 prompt：**Beta 产品化 + 后端同步 + Onboarding + TestFlight 准备**。

```text
你是一个资深 iOS + Backend + LLM Agent 工程师。当前 BodyLoop 项目已经完成：

- HealthKit / Mock 数据读取
- DailyHealthMetrics 聚合
- BaselineEngine / DataCoverageLayer / SignalDetector
- AgentContextBuilder / CoachPromptBuilder
- LLMClient / MockLLMClient / RuleBasedRecommendationGenerator
- CoachRecommendation / DailyFeedback / VerificationReport
- UserMemory / MemoryStore / PatternMiner / MemoryUpdateService
- PersonalExperiment / ExperimentStore / ExperimentAgent
- UserGoal / GoalStore / WeeklyPlan / PlanStore
- WeeklyPlanAgent / AdaptiveRescheduler / ReminderScheduler / WeeklyReviewEngine
- SafetyGuardrail
- PrivacyManager / PrivacySettings
- AgentEvaluationRunner / PromptRegressionTester
- EffectivenessAnalyzer / DemoScenarioBuilder
- TodayView / MetricsView / AgentContextView / ReviewView / ExperimentsView / PlanView / WeeklyReviewView / EffectivenessDashboardView / PrivacyView / DemoModeView

现在请实现第六阶段：Beta 产品化 + 后端同步 + Onboarding + TestFlight 准备，让 BodyLoop 从“本地 agent 作品”升级成“可给真实用户试用的 Beta 产品”。

核心目标：
1. 增加用户登录与本地/云端同步能力。
2. 增加后端数据模型和 API client。
3. 实现首次使用 Onboarding：目标、HealthKit、隐私、AI 使用授权。
4. 增加用户同意与隐私授权管理。
5. 增加 Beta analytics，用来评估留存、执行率、数据覆盖、LLM 成本和 safety flags。
6. 增加 Settings / Account / Sync 状态页面。
7. 准备 TestFlight 发布清单和 README。

请先检查当前项目结构，按现有风格实现，不要大改已有架构。第一版后端可以是 Supabase 或 FastAPI schema stub；如果项目目前没有后端目录，请新建 backend/，同时保证 iOS app 在没有后端配置时仍能本地运行。

========================
一、后端方案
========================

优先选择一种最适合当前项目的方案：

方案 A：Supabase-first
- Auth
- Postgres schema SQL
- Row Level Security policies
- Edge Functions stub if needed

方案 B：FastAPI-first
- FastAPI app
- PostgreSQL schema
- Pydantic models
- API routes
- JWT auth stub

如果没有明确偏好，优先使用 Supabase-first，因为适合快速 Beta。

要求：
- 不上传原始 HealthKit samples。
- 只同步聚合摘要和 agent 状态。
- iOS 没有后端配置时使用 LocalOnly 模式。

需要同步的数据：
- DailyHealthMetrics summary
- DataQualityReport
- CoachRecommendation
- DailyFeedback
- VerificationReport
- UserMemory summary
- PersonalExperiment
- WeeklyPlan
- WeeklyReview
- UserGoal
- PrivacySettings
- EffectivenessReport
- SafetyAssessment
- BetaAnalyticsEvent

========================
二、Backend Schema
========================

在 backend/ 中新增 schema 文件。

如果 Supabase：
- backend/supabase/schema.sql
- backend/supabase/rls.sql
- backend/supabase/README.md

表建议：
- profiles
- user_goals
- daily_health_metrics
- data_quality_reports
- coach_recommendations
- daily_feedback
- verification_reports
- user_memory
- personal_experiments
- weekly_plans
- weekly_reviews
- privacy_settings
- effectiveness_reports
- safety_assessments
- beta_analytics_events
- sync_state

每张表：
- id uuid primary key
- user_id uuid references auth.users(id)
- payload jsonb 或结构化字段 + payload jsonb
- created_at
- updated_at
- deleted_at nullable

RLS：
- 用户只能读写自己的数据。
- beta_analytics_events 只能 insert 自己的数据。
- 不允许跨用户读取。

如果 FastAPI：
- 建立等价 models/routes/schema。

========================
三、AuthService
========================

新增 AuthServiceProtocol：

- currentUser
- authState
- signInWithEmail(email, password)
- signUpWithEmail(email, password)
- signOut()
- restoreSession()

实现：
- LocalAuthService：无后端时使用本地匿名用户
- SupabaseAuthService 或 BackendAuthService：如果配置了后端则使用真实登录

AuthState:
- signedOut
- signedIn
- localOnly
- loading
- error

UI：
- AccountView
- 登录 / 注册 / 退出
- 显示当前模式：LocalOnly / Cloud Sync

========================
四、BackendAPIClient
========================

新增 BackendAPIClientProtocol：

- uploadDailySummary(...)
- uploadRecommendation(...)
- uploadFeedback(...)
- uploadVerificationReport(...)
- uploadMemory(...)
- uploadExperiment(...)
- uploadWeeklyPlan(...)
- uploadWeeklyReview(...)
- uploadPrivacySettings(...)
- uploadSafetyAssessment(...)
- uploadAnalyticsEvent(...)
- fetchRemoteChanges(since:)
- markDeleted(entityType, id)

实现：
- LocalBackendAPIClient：no-op 或本地模拟
- SupabaseBackendAPIClient / HTTPBackendAPIClient

要求：
- 所有上传都使用 Codable payload。
- 网络失败时不要丢数据，进入 pending sync queue。
- 不要上传 raw HealthKit samples。

========================
五、Sync Engine
========================

新增 SyncEngine。

职责：
- 本地 store 与后端同步。
- 支持 pending changes queue。
- 支持 lastSyncedAt。
- 支持冲突处理。
- 支持 LocalOnly 模式。

模型：

SyncRecord:
- id
- entityType
- entityId
- operation:
  - upsert
  - delete
- payload
- status:
  - pending
  - syncing
  - synced
  - failed
- retryCount
- lastError
- createdAt
- updatedAt

SyncState:
- lastSyncedAt
- mode:
  - localOnly
  - cloudEnabled
  - paused
- pendingCount
- lastError

冲突策略第一版：
- last-write-wins
- 但 PrivacySettings 以本地最新为准
- deleted_at 支持软删除

UI：
新增 SyncStatusView：
- 显示模式
- pending count
- last synced
- sync now 按钮
- pause/resume sync

========================
六、Onboarding Flow
========================

新增 OnboardingFlow。

步骤：

1. Welcome
- 简短说明 BodyLoop 是生活方式健康 agent，不做医疗诊断。

2. Goal Setup
- 选择目标：
  - 提升精力
  - 减脂
  - 稳定运动习惯
  - 提升心肺
  - 改善睡眠
  - 恢复优先
- 设置每周频率和偏好日

3. HealthKit Permission
- 请求 HealthKit 授权
- 说明需要读取哪些聚合指标
- 如果用户拒绝，进入 mock/demo 或 limited mode

4. Privacy Settings
- 选择是否使用 LLM
- 选择是否同步云端
- 默认不上传 raw samples
- 显示将发送给 LLM 的摘要预览

5. AI Consent
- 明确说明 AI 只提供生活方式建议，不做诊断。
- 用户确认同意。

6. Baseline Setup
- 尝试读取最近 30 天数据
- 生成 baseline
- 如果数据不足，提示需要几天建立基线

7. First Recommendation
- 生成第一条 CoachRecommendation 或 fallback 建议

OnboardingState:
- hasCompletedOnboarding
- completedSteps
- selectedGoals
- healthKitAuthorized
- privacyConfirmed
- aiConsentAccepted
- baselineInitialized
- createdAt
- updatedAt

UI：
- OnboardingView
- App 启动时如果未完成 onboarding，先展示 OnboardingView

========================
七、Consent Manager
========================

新增 ConsentManager。

ConsentRecord:
- id
- type:
  - healthkit_read
  - ai_lifestyle_advice
  - cloud_sync
  - beta_analytics
  - notifications
- version
- accepted
- acceptedAt
- revokedAt
- textSummary

功能：
- recordConsent()
- revokeConsent()
- hasConsent()
- latestConsents()

规则：
- 没有 AI consent 时，不调用 LLM，只用 rule fallback。
- 没有 cloud sync consent 时，SyncEngine 必须 LocalOnly。
- 没有 beta analytics consent 时，不上传 analytics event。
- HealthKit 权限被拒绝时使用 mock 或 limited mode。

========================
八、Beta Analytics
========================

新增 BetaAnalyticsService。

BetaAnalyticsEvent:
- id
- userId
- eventType:
  - app_opened
  - recommendation_generated
  - recommendation_completed
  - recommendation_skipped
  - feedback_saved
  - experiment_started
  - experiment_checkin
  - weekly_plan_generated
  - weekly_plan_adjusted
  - safety_flag_triggered
  - llm_fallback_used
  - sync_failed
  - onboarding_completed
- properties: [String: String]
- createdAt

要求：
- 默认本地记录。
- 如果用户同意 beta analytics 且 cloud sync enabled，上传。
- 不记录原始健康数据。
- properties 只能放非敏感摘要，例如 confidence=low, fallback=true。

新增 BetaAnalyticsDashboardView：
- 本地展示：
  - app open count
  - recommendation generated count
  - feedback rate
  - experiment checkin count
  - safety flag count
  - fallback count
  - sync failure count

========================
九、Settings / Account
========================

新增 SettingsView，包含：

- AccountView
- PrivacyView
- SyncStatusView
- Notification settings
- Beta analytics consent
- Demo mode toggle
- Export local data JSON
- Reset local data / reset demo data
- App version / build info

注意：
- Reset local data 是破坏性操作，需要二次确认。
- Export 只导出聚合摘要和 agent 状态，不导出 raw HealthKit samples。

========================
十、Error Handling / Observability
========================

新增 ErrorReporter：

ErrorEvent:
- id
- category:
  - healthkit
  - llm
  - sync
  - onboarding
  - storage
  - notification
  - safety
- message
- context
- createdAt

要求：
- 网络失败、LLM fallback、sync 失败、HealthKit 授权失败要记录
- 不记录敏感原始健康数据
- Debug UI 可查看最近 errors

========================
十一、App Store / TestFlight Readiness
========================

新增 docs/testflight-readiness.md，包含：

- HealthKit capability checklist
- Info.plist privacy strings checklist
- Notification permission checklist
- AI advice disclaimer
- Privacy policy draft points
- TestFlight beta testing plan
- Known limitations
- Safety boundaries
- Data sync model
- Demo mode instructions
- Manual QA checklist

README 更新：
- LocalOnly 模式
- Cloud Sync 配置
- Supabase/FastAPI schema 说明
- Onboarding flow
- Consent and privacy
- Beta analytics
- TestFlight checklist

========================
十二、测试
========================

添加单元测试，至少覆盖：

Auth:
- LocalAuthService starts in localOnly
- signOut clears current user

Consent:
- no AI consent -> LLM disabled
- no cloud sync consent -> SyncEngine localOnly
- revoked analytics consent -> analytics not uploaded

Privacy / Sync:
- raw HealthKit samples never included in upload payload
- pending sync queue retains failed uploads
- last-write-wins conflict handling
- PrivacySettings local latest wins

Onboarding:
- incomplete onboarding shows OnboardingView
- completed onboarding enters main app
- rejected HealthKit enters limited/mock mode
- baseline insufficient shows data coverage messaging

Analytics:
- events recorded locally
- no upload without consent
- properties reject sensitive raw health keys

Backend Schema:
- schema files exist
- required tables listed
- RLS file contains user_id ownership policies

Settings:
- export local data excludes raw samples
- reset requires confirmation model/state

========================
执行顺序
========================

请按以下顺序执行：

1. 检查当前项目结构和存储方式
2. 给出简短实现计划
3. 新建 backend schema / docs
4. 实现 AuthService / AccountView
5. 实现 BackendAPIClient / SyncEngine / SyncStatusView
6. 实现 OnboardingState / OnboardingView
7. 实现 ConsentManager
8. 实现 BetaAnalyticsService / Dashboard
9. 实现 SettingsView 并更新主导航/app entry
10. 实现 ErrorReporter / Debug UI
11. 更新 README 和 docs/testflight-readiness.md
12. 添加测试
13. 运行可用验证命令
14. 总结改动、如何运行 LocalOnly、如何配置 Cloud Sync、下一步建议

注意：
- 不要上传原始 HealthKit samples。
- 不要硬编码 API key、Supabase key、JWT secret。
- 没有后端配置时 app 必须可运行。
- 没有 AI consent 时不能调用 LLM。
- 没有 cloud sync consent 时不能上传。
- 所有健康建议仍然是生活方式建议，不做医疗诊断。
- 保持架构清晰，适合作品和 Beta 展示。
```

这一阶段完成后，你就可以开始找 3-5 个真实用户做 TestFlight 小测了。最重要的不是再加新功能，而是观察：他们是否愿意每天打开、是否愿意反馈、agent 的建议有没有让人觉得“真的懂我”。

> 接下来呢

<details><summary>1 previous message</summary>

> System error
>
> You've hit your usage limit. Upgrade to Pro (https://chatgpt.com/explore/pro), visit https://chatgpt.com/codex/settings/usage to purchase more credits or try again at Jun 11th, 2026 2:54 PM.
</details>

