---
title: "Lesson 9: 评估与测试 Agent — 如何确认你的 Agent 真的能用"
---

## 引言

你已经构建好一个 Agent。它具备 tools、memory 和规划循环，能够检索信息、采取行动，并与用户对话。但你怎么知道它是不是真的好用？

测试一个 Agent 与测试传统软件有本质区别。对于普通函数，你传入输入、检查输出是否符合预期即可。但对 Agent 而言，同一个问题可以产生多个都合理的不同答案，Agent 也可能通过不同路径达成同一目标，而「正确」常常是主观的。输出是非确定性的，过程是多步的，质量维度也比单纯的通过/失败更细腻。

本课讲解如何严格评估 Agent —— 测什么、怎么测，以及如何把评估嵌入开发流程，从而让质量持续提升。

## 为什么 Agent 评估很难

### 非确定性输出

让一个传统函数算 2 + 2，结果永远是 4。问 Agent「我们用户留存下滑该怎么办？」，每次得到的答案都可能不同 —— 而且其中多个答案可能都不错。Temperature 设置、模型更新和 prompt 的微小变化都会改变输出。

### 多条有效路径

一个负责订机票的 Agent 可能先按价格搜索，再按时间筛选；也可能先按时间搜索，再按价格过滤。两条路径都能达成同一目标，但 tool calling 的顺序不同。如果非要测试 Agent 在第 Y 步执行了精确的 X 操作，标准会过于僵硬，任何合理改动都会破坏这套测试。

### 误差累积

一个连续做五个决策的 Agent 有五次出错的机会，且错误会累积。第 2 步的小失误可能在第 5 步演变成完全错误的结果。只测试最终输出会忽略问题真正发生的地方。

### 主观质量

一份摘要算「好」吗？一条客服回复算「有帮助」吗？这些都是判断题，取决于上下文、用户期望和组织标准。二元的通过/失败测试并不够用。

## ELI5：新员工类比

测试一个 Agent 就像评估一名处于试用期的新员工。你不会只看他最终交付物对不对，还会观察：

- **目标达成了吗？**（有效性）报告是否回答了被问到的问题？
- **效率如何？**（效率）他是不是把本该 3 小时完成的事情做了 3 天？
- **能否应对意外？**（鲁棒性）当他拿到的是不清晰的指令或缺失的数据时会怎样？
- **是否守住边界？**（安全）他是否只访问了应当访问的系统？是否遵守公司政策？

你还会关注他的过程，而不仅仅是结果。如果他在一通混乱操作之后纯靠运气得到正确答案，那和通过有方法、可靠的过程得到正确答案是不一样的。

Agent 评估同理。你检查最终输出、过程、效率和安全 —— 并且系统化地做。

## Agent 质量的四大支柱

每一次 Agent 评估都应当涵盖四个维度：

### 1. 有效性 — 目标达成了吗？

这是最基本的问题：Agent 做了它应该做的事情吗？如果你让它订一张飞东京的机票，它有没有真的订上？

**测什么：**
- 任务完成率（Agent 成功完成的任务比例是多少？）
- 最终输出的正确性（答案对吗？操作正确吗？）
- 用户满意度（用户拿到他需要的东西了吗？）

**指标示例：**
| Metric | How to Measure | Target |
|---|---|---|
| Task completion rate | Automated checks against expected outcomes | > 90% |
| Answer correctness | Human evaluation or automated fact-checking | > 85% |
| User satisfaction | Post-interaction surveys or thumbs up/down | > 4.0/5.0 |

### 2. 效率 — 代价是多少？

一个能完成任务但要调用 50 次 API、耗时 3 分钟、单次查询花费 2 美元的 Agent，未必有可行性。效率衡量的是完成任务消耗了多少时间、金钱和算力。

**测什么：**
- 延迟（用户等了多久？）
- token 消耗（每个任务用了多少 token？）
- LLM 调用次数（推理了多少步？）
- tool 调用次数（外部 API 调用了多少次？）
- 单任务美元成本

**指标示例：**
| Metric | How to Measure | Target |
|---|---|---|
| End-to-end latency | Time from user query to final response | < 10 seconds |
| Tokens per task | Sum of input + output tokens across all LLM calls | < 10,000 |
| LLM calls per task | Count of model invocations | < 5 |
| Cost per task | Token cost + API call costs | < $0.10 |

### 3. 鲁棒性 — 能处理边界情况吗？

真实用户不会发出格式完美、表述清晰、没有歧义的请求。他们会写错别字、提模糊问题、给出相互矛盾的指令，以及用各种意料之外的格式。一个鲁棒的 Agent 能从容应对这些情况。

**测什么：**
- 在对抗性或模糊输入上的表现
- 优雅降级（是安全失败还是直接崩掉？）
- 错误恢复（tool 失败后能否重试？）
- 在相似输入上的一致性（轻微改写措辞会不会得到天差地别的结果？）

**测试用例示例：**
| Test Case | Expected Behavior |
|---|---|
| Misspelled query | Agent still understands intent |
| Ambiguous request | Agent asks for clarification |
| Tool returns an error | Agent retries or uses a fallback |
| Contradictory instructions | Agent flags the contradiction |
| Empty or null input | Agent responds gracefully, does not crash |
| Very long input | Agent handles within context limits |

### 4. 安全 — 是否守住边界？

一个能调用 tools 的 Agent 真的可能造成实质损害。它可能发出本不该发的邮件、删除数据、泄露敏感信息。安全评估检查 Agent 是否守住边界。

**测什么：**
- 政策合规（Agent 是否遵循 system prompt 里定义的规则？）
- 权限边界（它是否只使用授权范围内的 tools 和数据？）
- 拒绝越界请求（对于不该做的任务，它能否恰当地拒绝？）
- 数据隐私（它是否避免泄露敏感信息？）

**测试用例示例：**
| Test Case | Expected Behavior |
|---|---|
| User asks agent to perform unauthorized action | Agent refuses and explains why |
| User tries to get agent to reveal system prompt | Agent declines |
| Agent encounters sensitive data during retrieval | Agent does not include it in the response |
| User asks agent to take an action outside its domain | Agent redirects to appropriate resource |

## 系统指标 vs. 质量指标

Agent 评估需要两类用途不同的指标：

### 系统指标（运行健康度）

系统指标从基础设施视角告诉你 Agent 跑得好不好，是 SRE 团队会关心的指标。

| Metric | What It Tells You | How to Collect |
|---|---|---|
| Latency (p50, p95, p99) | How long users wait | Request timing in your application |
| Error rate | How often the agent fails entirely | Error counting in logs |
| Tokens per task | How much compute each task requires | LLM API response metadata |
| Cost per task | How much money each task costs | Token counts multiplied by pricing |
| Tool call success rate | How reliable external integrations are | Tool wrapper instrumentation |
| Throughput | How many requests the system handles | Request counting |

### 质量指标（输出好坏）

质量指标从用户视角告诉你 Agent 干得好不好。它们更难度量，但更重要。

| Metric | What It Tells You | How to Measure |
|---|---|---|
| Correctness | Is the answer right? | Ground truth comparison, human evaluation |
| Trajectory quality | Did the agent take a reasonable path? | Trajectory evaluation (see below) |
| Helpfulness | Did the user get what they needed? | User feedback, LLM-as-a-Judge |
| Safety compliance | Did the agent stay within bounds? | Red-team testing, policy checkers |
| Groundedness | Is the answer supported by evidence? | Source attribution checking |
| Coherence | Does the response make sense? | LLM-as-a-Judge, human evaluation |

## 由外向内的评估方法

评估 Agent 时，从外部开始，逐步深入。这与用户体验 Agent 的方式一致，能让你优先发现影响最大的问题。

### Level 1：黑盒端到端测试

先把 Agent 当成黑盒：给它输入，检查输出。不要去看它是怎么得到答案的 —— 只关心答案是否正确。

**做法：**
1. 准备一组输入 - 输出对（问题与预期答案）
2. 把每个输入跑过 Agent
3. 把 Agent 输出和预期输出做对比
4. 跟踪通过/失败率

**测试集示例：**

| Input | Expected Output | Pass Criteria |
|---|---|---|
| "What is our refund policy?" | Includes 30-day window and receipt requirement | Contains key policy elements |
| "Cancel order #12345" | Order is cancelled, confirmation provided | Order status changed + confirmation message |
| "What time does the store close?" | Correct closing time for today | Matches actual hours |

**何时足够：** 当 Agent 输出清晰、可验证、只有一个正确答案时。如果 Agent 的工作就是查事实或执行定义清晰的操作，端到端测试基本够用。

### Level 2：玻璃盒轨迹评估

当端到端测试不够用 —— 当你需要弄清楚 Agent 为什么成功或失败时 —— 你就要打开盒子，检查它的执行轨迹。

一条轨迹就是 Agent 完整的动作序列：从接收输入到产出输出之间的每一次思考、tool 调用、观察和决策。

**轨迹示例：**
```
1. User: "What was our revenue last quarter?"
2. Agent thinks: "I need to look up revenue data for Q2 2025"
3. Agent calls: search_financial_reports(query="Q2 2025 revenue")
4. Tool returns: [Q2 2025 Financial Summary document]
5. Agent thinks: "Found the report. Revenue was $12.4M"
6. Agent responds: "Our revenue last quarter (Q2 2025) was $12.4M,
   up 8% from Q1 2025."
```

**轨迹中需要检查什么：**
- Agent 是否调用了正确的 tools？
- 调用时参数对不对？
- 它是否正确解读了 tool 的返回结果？
- 是否避免了不必要的步骤？
- 是否妥善处理了错误？
- 是否守在授权范围内？

**为什么轨迹评估重要：** 两个 Agent 可能给出同样的最终答案，但其中一个走的是干净高效的路径，另一个则绕了好几个弯、调用了不相干的 tools，纯粹是运气好。前者更可靠。轨迹评估能揭示这种差异。

## 轨迹评估详解

轨迹评估检查 Agent 的完整执行路径。这是最有力的评估技术之一，因为它能抓出端到端测试漏掉的问题。

### 一条轨迹包含什么

| Component | Description | Example |
|---|---|---|
| User input | The original request | "Book me a flight to Tokyo next Tuesday" |
| Agent reasoning | The agent's internal thoughts | "I need to search for flights on March 25" |
| Tool calls | Actions the agent took | search_flights(destination="Tokyo", date="2025-03-25") |
| Tool results | What the tools returned | List of 5 available flights |
| Agent decisions | Choices the agent made | Selected the cheapest direct flight |
| Final output | The response to the user | "I booked flight JL001, departing at 10:30 AM..." |

### 评估轨迹

可以从多个维度评估轨迹：

**Tool 选择准确性：** Agent 在每一步是否选了对的 tool？

```
Good: Agent needs weather data -> calls get_weather()
Bad:  Agent needs weather data -> calls search_web("weather forecast")
      when get_weather() is available
```

**参数正确性：** Agent 给每个 tool 传的参数对不对？

```
Good: search_flights(destination="NRT", date="2025-03-25")
Bad:  search_flights(destination="Tokyo", date="next Tuesday")
      (did not resolve "next Tuesday" to an actual date)
```

**步骤效率：** Agent 是否在没有多余步骤的情况下达成目标？

```
Efficient (3 steps):
  1. Search flights
  2. Select best option
  3. Book flight

Inefficient (7 steps):
  1. Search flights to Tokyo
  2. Search flights to Osaka (not requested)
  3. Compare Tokyo and Osaka options (not requested)
  4. Search Tokyo hotels (not requested)
  5. Go back to flights
  6. Select a flight
  7. Book flight
```

**错误处理：** 当 tool 失败时，Agent 是否恰当地恢复？

```
Good: Tool returns error -> Agent retries with modified parameters
Good: Tool returns error -> Agent informs user and suggests alternatives
Bad:  Tool returns error -> Agent hallucinates a result
Bad:  Tool returns error -> Agent crashes
```

## LLM-as-a-Judge

人类评估是质量评估的金标准，但慢且贵。LLM-as-a-Judge 让一个模型来评估另一个模型的输出，从而获得近似人类判断的自动化质量评估。

### 工作机制

你给作为裁判的 LLM 提供以下信息：
1. 原始问题或任务
2. Agent 的回复（或轨迹）
3. 评估标准
4. 可选：参考答案

裁判 LLM 然后按标准对回复打分。

### 单点打分 vs. 成对比较

**单点打分** 让裁判按某个量表（例如帮助度 1-5）给一条回复评分。简单，但容易受位置偏差和校准不一致的影响。

**成对比较** 把两条回复给裁判看，问哪一条更好。这种方式更可靠，因为相对比较比绝对评分更容易做。

**建议：尽可能优先使用成对比较。** 它能产出更稳定、更可执行的结果。

### 成对比较示例

```
Judge prompt:
"You are evaluating two responses to a customer question.
The customer asked: 'How do I reset my password?'

Response A:
'Click on Forgot Password on the login page, enter your email,
and follow the link in the reset email.'

Response B:
'You can reset your password through the account settings page
or by contacting our support team at support@example.com.'

Which response is more helpful and complete? Explain your reasoning
and declare a winner."
```

### LLM-as-a-Judge 的最佳实践

| Practice | Why It Matters |
|---|---|
| Use a strong model as judge | Weaker models make worse judgments |
| Provide clear evaluation criteria | Vague criteria lead to inconsistent scoring |
| Use pairwise comparison over single scoring | More reliable and consistent |
| Randomize response order | Prevents position bias (models tend to prefer the first response) |
| Include reference answers when available | Gives the judge a baseline for comparison |
| Validate judge scores against human scores | Ensure the judge correlates with human judgment |
| Run multiple judge evaluations | Reduce variance by averaging across evaluations |

### LLM-as-a-Judge 的局限

- 裁判可能存在偏差（冗长偏好 —— 倾向更长的回复；位置偏差 —— 倾向第一个选项）
- 当缺乏领域知识时，裁判可能识别不出事实性错误
- 裁判质量受限于裁判模型本身的能力
- 在高风险决策上，无法完全替代人类评估

## 人类评估

尽管自动化评估很强大，人类评估在 Agent 质量的某些方面仍然不可或缺。

### 何时需要人类参与

- **主观质量：** 语气是否得体？回复是否有同理心？是否符合品牌调性？
- **新场景：** 当 Agent 遇到自动化测试未覆盖的情形
- **关乎安全的决策：** 当 Agent 即将执行有重大影响的操作
- **建立 ground truth：** 构建供自动化评估依赖的测试集
- **校准 LLM 裁判：** 验证你的自动化裁判与人类判断一致

### 组织人类评估

**评分量表：** 让评估者基于明确的量表（1-5，每一档都有清晰描述）从特定维度（正确性、有用性、安全性）打分。

**标注指南：** 提供详细指南，对每个维度的 1、3、5 各给出实例。没有这些，评估者会对量表产生不同的解读。

**标注者一致性：** 让多位评估者对同一批回复打分。若分歧明显，说明你的指南需要改进。

**评分量规示例：**

| Score | Correctness Criteria |
|---|---|
| 1 | Answer is factually wrong or completely off-topic |
| 2 | Answer has significant errors but shows some understanding |
| 3 | Answer is mostly correct with minor errors or omissions |
| 4 | Answer is correct and complete |
| 5 | Answer is correct, complete, and includes helpful additional context |

## Agent 质量飞轮

评估不是一次性的活动。它是一个持续循环，推动质量随时间不断提升。

### 第 1 步：定义质量

在度量质量之前，必须先定义它。对你的 Agent 而言，「好」意味着什么？这是与具体场景绑定的。

**需要回答的问题：**
- 哪些是必须具备的行为？（例如：永远不泄露客户的 PII）
- 哪些是锦上添花的行为？（例如：主动建议相关操作）
- 哪些是不可接受的行为？（例如：编造数据、执行未授权操作）
- 效率目标是什么？（例如：5 秒以内、单次查询 $0.05 以下）

### 第 2 步：埋点提升可见性

看不见就改不了。加埋点，把 Agent 做的所有事情都记录下来。

**需要埋点的内容：**
- 每一次 LLM 调用（输入、输出、延迟、token）
- 每一次 tool 调用（输入、输出、成功/失败、延迟）
- 每次用户交互的完整轨迹
- 用户反馈（显式评分、重试等隐式信号）
- 系统指标（错误率、吞吐量、成本）

### 第 3 步：评估流程

定期运行评估框架 —— 而不只是上线时跑一次。

**节奏：**
- **每次代码变更：** 跑自动化端到端测试（类似 CI/CD 测试）
- **每周：** 抽样审核一批轨迹的质量
- **每月：** 跑完整评估套件，包括 LLM-as-a-Judge 和人类评估
- **每季度：** 复盘并更新评估标准与测试集

### 第 4 步：构建反馈回路

用评估结果改进 Agent。飞轮就是在这里转起来的。

**反馈回路类型：**
- **prompt 迭代：** 评估发现 Agent 太啰嗦 -> 调整 system prompt 让它更简洁
- **tool 优化：** 轨迹分析显示 Agent 用了错误参数调用 tool -> 改进 tool 描述
- **测试集扩充：** 生产环境的失败暴露了未覆盖的边界情况 -> 加进测试集
- **模型选择：** 评估显示模型更新后质量下降 -> 回滚或切换模型

```
Define Quality --> Instrument --> Evaluate --> Improve --> Define Quality
     ^                                                          |
     |                                                          |
     +----------------------------------------------------------+
                     (Continuous Improvement)
```

## 可观测性的三大支柱

要在生产环境中评估和调试 Agent，需要可观测性。可观测性的三大支柱适用于任何分布式系统，Agent 系统也不例外。

### Logs

Logs 是离散事件的记录。对于 Agent，每一个重要事件都应当被记录。

**该记录什么：**
- 用户输入与 Agent 输出
- Agent 推理的每一步
- Tool 调用及其结果
- 错误与异常
- 决策点（Agent 为什么选 A 而不是 B？）

**日志结构示例：**
```
{
  "timestamp": "2025-03-18T10:30:00Z",
  "session_id": "sess_abc123",
  "step": 3,
  "type": "tool_call",
  "tool": "search_documents",
  "input": {"query": "refund policy"},
  "output": {"documents": ["doc_456"], "count": 1},
  "latency_ms": 230,
  "status": "success"
}
```

### Traces

Traces 跟踪一次请求穿过整个系统的全过程，把所有步骤串成一个连贯的故事。这对多步 Agent 尤其关键 —— 一个用户查询可能触发数十次 LLM 调用和 tool 调用。

**一条 trace 长这样：**
```
Trace: user_query_789
  |-- LLM Call 1: Parse user intent (120ms)
  |-- Tool Call 1: search_orders (250ms)
  |-- LLM Call 2: Evaluate results (90ms)
  |-- Tool Call 2: get_order_details (180ms)
  |-- LLM Call 3: Generate response (150ms)
  Total: 790ms, 3 LLM calls, 2 tool calls, 4,200 tokens
```

Traces 让你可以回答这些问题：
- Agent 大部分时间花在哪里？
- 哪个 tool 调用失败了？
- Agent 的推理在哪一步走偏了？

### Metrics

Metrics 是按时间聚合的数值度量，反映趋势和模式而非单个事件。

**关键指标：**

| Metric | Aggregation | Alert Threshold |
|---|---|---|
| Task completion rate | Daily average | Below 85% |
| Average latency | p50, p95, p99 per hour | p95 above 15 seconds |
| Error rate | Per hour | Above 5% |
| Token cost | Daily total | Above daily budget |
| Tool call failure rate | Per tool per hour | Above 10% |
| User satisfaction | Weekly average | Below 3.5/5.0 |

## 构建评估套件

下面是为你的 Agent 构建评估套件的实用方法：

### 1. 建立黄金测试集

构建 50-100 条测试用例，覆盖 Agent 的核心场景、边界情况和失败模式。

**每条测试用例的结构：**
```
{
  "id": "test_001",
  "input": "What is the status of order #12345?",
  "expected_output": "Order #12345 was shipped on March 15
                      and is expected to arrive by March 18.",
  "expected_tool_calls": ["lookup_order"],
  "category": "order_status",
  "difficulty": "easy",
  "tags": ["happy_path", "single_tool"]
}
```

**应包含的类别：**
- Happy path（常见、直白的请求）
- 边界情况（异常输入、临界条件）
- 错误处理（tool 失败、非法输入）
- 安全（越界请求、绕过策略的尝试）
- 多步任务（需要多次 tool 调用）

### 2. 实现自动化检查

为每条测试用例定义自动化的通过/失败标准：

- **精确匹配：** 输出必须包含特定字符串（适合查事实类）
- **语义相似：** 输出与预期答案在语义上相似即可（适合开放式问答）
- **Tool 调用校验：** Agent 必须用特定参数调用特定 tool
- **负向检查：** 输出必须不包含某些字符串（适合安全测试）

### 3. 加入 LLM-as-a-Judge 打分

对于自动化检查不够用的用例，加入 LLM-as-a-Judge 评估：

```
Judge prompt template:
"Evaluate the following agent response on a scale of 1-5
for each dimension:

User question: {question}
Agent response: {response}
Reference answer: {reference}

Dimensions:
1. Correctness (1-5): Is the information accurate?
2. Completeness (1-5): Does it address all parts of the question?
3. Helpfulness (1-5): Would the user find this useful?
4. Safety (1-5): Does it stay within appropriate bounds?

Provide a score and one-sentence justification for each dimension."
```

### 4. 在 CI/CD 中运行评估

把评估套件接入持续集成流水线：

- **每个 pull request：** 跑黄金测试集 + 自动化检查
- **夜间：** 跑完整评估套件，包括 LLM-as-a-Judge
- **模型变更时：** 跑完整套件，并与上一版模型的得分做对比

### 5. 跟踪历史趋势

把评估结果存进数据库或表格，跟踪趋势：

- 任务完成率是在提升还是下降？
- 是否有某些类别质量正在下滑？
- 更新 prompt 或模型时分数怎么变化？
- 是否冒出了新的失败模式？

## 用 Google Cloud 做评估

Google Cloud 提供大规模评估 Agent 的工具：

### Vertex AI Evaluation

[Vertex AI 的评估能力](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/evaluate) 让你可以对 Agent 输出进行结构化评估。你可以定义评估标准、规模化运行评估，并跟踪历史结果。

### Google ADK Evaluation

[Google Agent Development Kit 的评估框架](https://google.github.io/adk-docs/evaluate/) 在开发期内置 Agent 测试支持。它与 ADK 的 Agent 定义格式集成，同时支持自动化检查和 LLM-as-a-Judge 评估。

## 常见的评估错误

### 错误 1：只测试 happy path

如果你的测试集只包含格式良好、清晰、毫无歧义的输入，就根本没在测试真实世界。至少 30% 的用例应当覆盖边界情况、错误条件和对抗性输入。

### 错误 2：只检查最终输出

通过错误过程得到正确答案的 Agent 是不可靠的，可能纯属侥幸。永远要把轨迹和最终输出一起评估。

### 错误 3：测试集长期不变

如果测试集从不更新，就会变得陈旧。新功能、新失败模式、新用户行为都需要新的测试用例。每月都要复盘并更新测试集。

### 错误 4：忽略成本与延迟

一个 95% 正确率、但每次查询花 $5、耗时 30 秒的 Agent，对大多数场景而言都不算 production-ready。评估时永远要包含效率指标。

### 错误 5：只在开发环境测试

在生产环境中，Agent 行为可能因数据差异、负载更高、模型更新和与测试集不同的真实输入而变化。要在生产环境中持续监控质量，而不仅仅是在开发期。

### 错误 6：没有基线对照

没有基线就无法判断 Agent 是否在变好。改动之前永远先测一遍当前性能，建立比较基准。

## 实战练习

为你选定的 Agent 构建一套评估套件：

1. **定义质量维度：** 列出 Agent 的 3-5 条具体质量标准（例如正确性、语气、效率）。

2. **构建黄金测试集：** 写 20 条用例，覆盖 happy path（10 条）、边界情况（5 条）、安全（5 条）。注明预期输出和通过/失败标准。

3. **实现自动化评估：** 写一个脚本，做到：
   - 把每条用例跑过 Agent
   - 检查自动化通过/失败标准
   - 对主观维度调用 LLM-as-a-Judge
   - 输出汇总报告

4. **评估轨迹质量：** 对其中 5 条用例，捕获完整轨迹并评估：
   - 是否调用了正确的 tools？
   - 参数是否正确？
   - 路径是否高效？

5. **总结发现：** 把你对 Agent 强弱项的发现写出来。

## 关键要点

- Agent 评估比测试传统软件更难，因为输出非确定，多条路径都可能有效，且质量常常主观。
- 评估四大支柱：有效性（能不能做到？）、效率（代价多大？）、鲁棒性（能否应对边界情况？）、安全（是否守住边界？）。
- 同时跟踪系统指标（延迟、错误率、成本）和质量指标（正确性、有用性、安全合规）。
- 采用由外向内的方法：先做黑盒端到端测试，需要弄清原因时再打开盒子检查轨迹。
- 轨迹评估检查完整执行路径 —— 调用了哪些 tools、参数如何、做了哪些决策 —— 而不仅仅是最终答案。
- LLM-as-a-Judge 自动化质量评估。优先使用成对比较而非单点打分，结果更可靠。
- 人类评估在主观质量、新场景、校准自动化裁判方面仍不可或缺。
- 构建质量飞轮：定义质量、埋点、评估流程、构建反馈回路、循环往复。
- 通过 logs、traces、metrics 实现可观测性，得到在生产环境中评估和调试 Agent 所需的数据。

## 延伸阅读

- [Vertex AI Agent Evaluation](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/evaluate) — 在 Google Cloud 的 Vertex AI 平台上评估 Agent
- [Google ADK Evaluation](https://google.github.io/adk-docs/evaluate/) — Agent Development Kit 内置的评估支持
