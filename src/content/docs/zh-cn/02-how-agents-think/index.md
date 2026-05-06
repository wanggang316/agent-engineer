---
title: "Lesson 2: agents 如何思考 — LLMs 作为推理引擎"
---

## 引言

在 Lesson 1 中我们说过，一个 agent 由三部分构成：模型（大脑）、tools（双手）和 orchestration 层（控制循环）。本节课我们聚焦于大脑。

Language model 是 agent 中最重要的组件。它读懂用户目标，推理该做什么，决定调用哪些 tools，解读结果，并生成最终答案。agent 系统中的其余部分都是为了支撑或扩展模型能做的事。

理解 LLMs 是怎么工作的 — 哪怕只是高层的 — 也会让你成为一个明显更好的 agent 构建者。你会知道为什么某些 prompts 有效而另一些无效。你会理解为什么 agents 有时候会跑偏。你将能就模型选择、prompt 设计和系统架构做出有依据的决定。

---

## LLMs 作为 agent 的大脑

大型 language model 是在海量文本数据上训练的神经网络。本质上，它只做一件事：**预测下一个 token**（粗略地说就是下一个词或词的一部分），基于此前出现过的所有内容。

这听起来简单，但训练带来的涌现能力却令人印象深刻：

- **理解**：理解复杂的问题与指令
- **推理**：处理多步逻辑问题
- **规划**：把目标分解为子任务
- **代码生成**：编写并调试软件
- **tool 选择**：决定调用哪个函数以及参数是什么
- **摘要**：把长文档浓缩成要点
- **翻译**：在不同语言、格式与表达之间转换

### LLMs 擅长做什么

| 能力 | 在 agent 场景中的示例 |
|---|---|
| 自然语言理解 | 解析用户请求：「Cancel my most recent order」 |
| 推理与规划 | 决策：「先找到订单，再判断是否可取消，然后取消」 |
| tool 选择 | 选择调用 `lookup_order(user_id, sort="recent")` |
| 输出格式化 | 返回干净的 JSON 响应或友好消息 |
| 错误解读 | 读懂 API 错误并决定换参数重试 |
| 上下文综合 | 把多次 tool 调用的结果合成一个连贯回答 |

### LLMs 单独做不到的（没有外部辅助时）

| 局限 | 为什么重要 |
|---|---|
| 没有实时数据访问 | 模型的知识有训练截止日期 |
| 计算无保证 | LLMs 数学可能算错 — 它们预测 tokens，不是计算 |
| 没有持久记忆 | 每次对话从零开始，除非你为它构建记忆 |
| 无法行动 | 没有 tools 时，模型只能生成文本 |
| Hallucination 风险 | 模型可能生成看起来合理但其实错误的信息 |
| context window 限制 | 模型一次能处理的文本量存在上限 |

这就是为什么 agents 存在。Tools 弥补了模型无法行动和无法访问实时数据的缺陷。Orchestration 弥补了它缺乏持久记忆与容易跑题的问题。

---

## Language models 如何处理信息

构建 agents 不需要你深入理解 transformer 架构，但理解三个关键概念会帮助你写出更好的 prompts、设计出更好的系统。

### Tokens：语言的最小单位

LLMs 不读字符，也不读单词。它们读 **tokens** — 模型在训练中学会识别的文本块。一个 token 可能是一个完整的词、词的一部分，或一个标点符号。

**示例：**

| 文本 | 大约 token 数 |
|---|---|
| "Hello" | 1 token |
| "Hello, world!" | 3 tokens |
| "ChatGPT is amazing" | 4 tokens |
| 一个典型的代码函数（20 行） | 100-300 tokens |
| 一整页英文文本 | ~500-700 tokens |

**这对 agents 为什么重要：**

- **计费**：大多数 APIs 按 token 收费（输入 + 输出）。agent 工作流比单次 prompt 消耗多得多的 tokens，因为循环每一轮都把完整上下文重新发出去。
- **速度**：tokens 越多 = 生成时间越长。让你的 tool descriptions 保持简洁。
- **上下文上限**：单次调用模型可处理的 tokens 数有上限。如果 agent 累积的上下文超过这个上限，信息就会丢失。

### Context windows：模型的工作记忆

**Context window** 是模型一次能考虑的总 tokens 数。把它想象成模型的桌面 — 它需要参考的所有东西必须放得下这张桌子。

| 模型 | Context Window |
|---|---|
| Gemini 2.5 Pro | 1,000,000 tokens |
| Gemini 2.0 Flash | 1,000,000 tokens |
| GPT-4o | 128,000 tokens |
| Claude 3.5 Sonnet | 200,000 tokens |

**一次 agent 调用中，context window 里通常包含：**

```
+------------------------------------------+
| System instructions ("You are a...")     |  ~200-500 tokens
+------------------------------------------+
| Tool definitions (names, descriptions,   |  ~500-2000 tokens
| parameter schemas)                       |
+------------------------------------------+
| Conversation history                     |  Variable
+------------------------------------------+
| Previous tool calls and results          |  Variable (can grow fast)
+------------------------------------------+
| Current user message                     |  Variable
+------------------------------------------+
| = Total must fit within context window   |
+------------------------------------------+
```

**这对 agents 为什么重要：**

随着 agent 执行多个步骤，上下文会随每一次 tool 调用与结果增长。一个 5 步的 agent 工作流可能累积数千 tokens 的 tool 结果。如果不小心，你可能在任务进行到一半时就耗尽 context window。

管理这一点的策略：
- **总结**中间结果，而不是保留原始数据
- **截断**长 tool 输出，只保留相关部分
- **使用大 context window 的模型**来应对复杂的多步任务
- **实现滑动窗口**，丢弃较旧、相关性较低的上下文

### Attention：模型如何聚焦

**attention 机制**让模型能识别上下文中哪些部分对当前决策重要。在决定下一个生成什么 token 时，模型会给输入的不同部分赋予不同权重。

可以把它想成读一篇长文档时给重要段落画重点。模型「画重点」给当前最相关的 tokens。

**这对 agents 为什么重要：**

- **把重要信息放在模型容易找到的位置。** 模型往往更关注上下文的开头与结尾。关键指令应放在 system prompt（开头）或靠近用户查询的位置（结尾）。
- **要具体、清晰。** 模糊的指令迫使模型猜测哪些信息要紧。具体的指令让 attention 机制更容易锁定到正确信息。
- **结构有帮助。** 清晰的标题、编号列表与一致的格式有助于模型解析并关注到正确内容。

---

## 推理策略

agent 如何「思考」一个问题，很大程度上取决于你如何 prompt 模型。不同的推理策略会产生差别很大的结果，尤其是在复杂任务上。

### Chain-of-Thought (CoT)

**它是什么：** prompt 模型在给出最终答案前先一步一步思考问题。

**怎么工作：** 模型不是直奔答案，而是生成中间推理步骤。这能显著提升在需要逻辑、数学或多步分析的任务上的准确率。

**没有 CoT 的示例：**
```
Prompt: "If a server handles 100 requests/second and we have 3 servers,
         with 40% of traffic going to server 1, how many requests/second
         does server 1 handle?"

Model response: "120 requests per second"  (wrong)
```

**带 CoT 的示例：**
```
Prompt: "Think step by step. If a server handles 100 requests/second and
         we have 3 servers, with 40% of traffic going to server 1, how
         many requests/second does server 1 handle?"

Model response:
"Step 1: Total capacity is 3 servers x 100 req/s = 300 req/s
 Step 2: Server 1 receives 40% of total traffic
 Step 3: 40% of 300 = 120 req/s
 Step 4: Server 1 can handle 100 req/s but receives 120 req/s
 Answer: Server 1 receives 120 req/s but can only handle 100 req/s,
         so it is overloaded by 20 req/s"
```

一步一步的方法捕捉到了直接回答漏掉的过载情况。

**何时为 agents 使用 CoT：**
- 复杂的 tool 选择决策（「在这 5 个 tools 中，哪个能帮上忙？」）
- 多步规划（「什么样的动作序列能达成此目标？」）
- 错误诊断（「tool 返回了错误 — 哪里出了问题？接下来该尝试什么？」）

### Tree-of-Thoughts (ToT)

**它是什么：** Chain-of-Thought 的扩展，模型探索多条推理路径、对它们打分，再选择最好的一条。

**怎么工作：** 模型不只产生一条推理链，而是生成多种可能方法，对每条进行打分或批评，然后沿着最有前景的路径推进。

```
Goal: "Optimize this slow database query"

Path A: "Add an index on the WHERE clause column"
  -> Evaluation: "Likely effective, low risk, easy to implement"

Path B: "Rewrite as a materialized view"
  -> Evaluation: "Might help, but adds complexity and maintenance"

Path C: "Denormalize the table structure"
  -> Evaluation: "Could work but high risk, affects other queries"

Decision: Proceed with Path A first, try Path B if A is insufficient
```

**何时为 agents 使用 ToT：**
- 当存在多个有效方法、你希望模型权衡取舍时
- 根因不确定的复杂调试
- 需要评估备选方案的架构决策

**取舍：** ToT 消耗更多 tokens、耗时更长。把它留给做错代价高的决策。

### 一步一步分解（Step-by-Step Decomposition）

**它是什么：** 在执行任何步骤之前，先把一个复杂目标拆解为一系列更简单的子任务。

**怎么工作：** Agent 先创建一个计划，然后逐步执行，并在过程中检查进度。

```
User goal: "Set up monitoring for our new API endpoint"

Plan:
1. Check what monitoring tools are currently configured
2. Determine what metrics matter for this endpoint (latency, error rate, throughput)
3. Create the monitoring dashboard
4. Set up alerting thresholds
5. Test that alerts fire correctly
6. Document the monitoring setup

Execution: [proceeds step by step, with each step potentially using tools]
```

**何时为 agents 使用分解：**
- 顺序很重要的多步任务
- 你希望 agent 对其方法保持透明
- 受益于检查点（checkpoints）的复杂工作流

---

## 模型选择：为任务挑选合适的模型

并非所有任务都需要最强的模型。选择合适的模型是一项工程决策，需要在能力、成本、速度与可靠性之间取得平衡。

### 模型连续谱

```
Lighter / Faster / Cheaper                  Heavier / Smarter / More Expensive
|----------------------------------------------------------|
Gemini Flash          Gemini Pro          Gemini 2.5 Pro
(simple tasks)        (balanced)          (complex reasoning)
```

### 何时使用什么

| 任务类型 | 推荐档位 | 原因 |
|---|---|---|
| 分类（「这是垃圾邮件吗？」） | Light (Flash) | 决策简单，无需复杂推理 |
| 数据抽取（「从这封邮件中抽出日期」） | Light (Flash) | 模式匹配，输出明确 |
| 摘要 | Light 到 Medium | 取决于源文本长度与复杂度 |
| 多步推理 | Medium 到 Heavy (Pro) | 需要持续的逻辑链 |
| 复杂代码生成 | Heavy (2.5 Pro) | 需要对模式与边界情况的深入理解 |
| Agentic 使用 tool | Medium 到 Heavy | tool 选择与结果解读需要较强的推理 |
| 创意写作 | Medium | 不必使用最重的模型也能有好结果 |

### 模型路由：不同步骤使用不同模型

成熟的 agent 系统不会每一步都用同一个模型。这叫做**模型路由** — 根据复杂度把工作流的不同部分分发到不同模型。

**示例架构：**

```
User query arrives
    |
    v
[Light model: Classify intent]  --> "order_status"
    |
    v
[Light model: Extract parameters]  --> order_id: 12345
    |
    v
[Tool call: Look up order]  --> status data
    |
    v
[Light model: Format response]  --> "Your order #12345 shipped on March 15"
```

在这个流程里，每一步都使用一个快速、便宜的模型，因为没有任何单一步骤需要重度推理。整体的成本和延迟比对整个交互都用前沿模型要低很多。

**与一个更难的任务相比：**

```
User: "Review this pull request and suggest improvements"
    |
    v
[Heavy model: Analyze code changes, reason about patterns,
 identify bugs, suggest improvements]
    |
    v
[Return detailed review]
```

这个任务需要深入推理，因此值得使用更强的模型。

### Google Cloud 模型选项

Google Cloud 通过 Vertex AI 提供 Gemini 模型：

- **Gemini 2.0 Flash** — 适用于多数 agent 任务，快速且高效。大 context window（1M tokens）。能力与速度平衡良好。
- **Gemini 2.5 Pro** — 顶级推理，适合复杂任务。当任务需要深入分析、复杂多步逻辑或细致理解时使用。
- **Gemini 2.0 Flash Lite** — 最快、最便宜的选项，适合分类、抽取等简单任务。

> **了解更多：** [Vertex AI Model Documentation](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models)

> **了解更多：** [Gemini API Documentation](https://ai.google.dev/gemini-api/docs)

---

## system instructions 的角色

System instructions 是 agent 的「岗位说明书」。它告诉模型它是谁、能做什么、应当怎样行事，以及什么不该做。

### system instructions 中应包含什么

为 agent 写得好的 system instruction 通常包括：

1. **角色定义**：agent 是谁、为谁服务
2. **能力**：可用的 tools 以及何时使用
3. **约束**：agent 不应该做的事
4. **输出格式**：如何组织回复
5. **错误处理**：出错时该怎么办
6. **个性 / 语气**：如何沟通（如有需要）

### 示例：客服 agent

```
You are a customer support agent for Acme Corp, an online electronics retailer.

Your role:
- Help customers with order inquiries, returns, and product questions
- Be friendly, professional, and concise

Available tools:
- lookup_order(order_id): Returns order status, items, and shipping info
- initiate_return(order_id, reason): Starts a return process
- search_products(query): Searches the product catalog
- escalate_to_human(reason): Transfers to a human agent

Guidelines:
- Always verify the customer's identity before accessing order information
- If you cannot resolve an issue in 3 attempts, escalate to a human agent
- Never make up order information - always use the lookup tool
- Do not offer discounts or refunds beyond standard policy
- Keep responses under 3 paragraphs

When you encounter an error from a tool:
- If it is a temporary error (timeout, 500), retry once
- If it is a permanent error (not found, unauthorized), explain the issue to the customer
- If you are unsure, escalate to a human agent
```

### 写好 system instructions 的建议

| Do | Do Not |
|---|---|
| 对 tool 用法做出明确说明 | 让 tool 选择含糊不清 |
| 定义清晰的边界 | 假设模型知道你的业务规则 |
| 包含错误处理指引 | 指望模型自行搞定错误 |
| 指定输出格式 | 让模型每次自选格式 |
| 使用具体示例 | 写抽象、模糊的指令 |
| 让指令保持简洁 | 写一篇 10 页的长文（浪费上下文） |

### 顺序很重要

模型对 system prompt 开头与结尾的指令更敏感。把 system instructions 这样组织：

```
1. Most critical rules (identity, safety constraints)     <-- Start
2. Tool usage guidelines
3. Output format
4. Examples
5. Edge case handling
6. Reminder of most critical rules                        <-- End
```

这利用了 attention 中的「首因效应与近因效应」。

---

## Temperature、采样与 agent 行为

当 language model 生成文本时，它并不是一律选最可能的下一个 token。它从所有可能 tokens 的概率分布中采样。控制采样的参数对 agent 行为影响巨大。

### Temperature

**Temperature** 控制模型输出的随机程度。

- **Temperature 0（或非常低）**：模型几乎总是选最可能的 token。输出确定且专注。
- **Temperature 1**：模型按 token 概率成比例采样。输出更多样、更具创意。
- **Temperature > 1**：模型变得越发随机，输出变得不可预测。

**直观类比：**

```
Temperature 0:    "The capital of France is Paris."
                  (Always the same answer)

Temperature 0.7:  "The capital of France is Paris, a city known for..."
                  (Slight variation in elaboration)

Temperature 1.5:  "The capital of France is historically rooted in..."
                  (More creative, potentially off-track)
```

### 为 agents 选 temperature

| Agent 任务 | 推荐 Temperature | 原因 |
|---|---|---|
| Tool 选择 | 0 - 0.2 | 你需要确定且正确的 tool 调用 |
| 数据抽取 | 0 | 精确答案，不需要创意 |
| 代码生成 | 0 - 0.3 | 正确性比多样性更重要 |
| 规划 | 0.2 - 0.5 | 一点灵活性有助于探索方案 |
| 创意写作 | 0.7 - 1.0 | 看重多样与新颖 |
| 头脑风暴 | 0.8 - 1.0 | 想要多样的想法 |

**对大多数 agent 用例来说，把 temperature 保持得低（0 到 0.3）。** Agents 需要在 tool 使用、参数抽取与推理上做可靠决策。高 temperature 会在你需要稳定性的地方引入随机性。

### Top-K 与 Top-P 采样

这些是模型选择 tokens 的额外控制项。

**Top-K：** 只考虑概率最高的 K 个 tokens。如果 K=50，模型忽略前 50 之外的所有 token。

**Top-P（nucleus sampling）：** 只考虑累积概率达到 P 的最小 token 集合。如果 P=0.9，模型考虑累积概率达 90% 的最小 token 集合。

```
Token probabilities: [0.4, 0.25, 0.15, 0.08, 0.05, 0.03, 0.02, ...]

Top-K=3:  Consider only [0.4, 0.25, 0.15]
Top-P=0.8: Consider only [0.4, 0.25, 0.15] (cumulative = 0.8)
Top-P=0.9: Consider only [0.4, 0.25, 0.15, 0.08] (cumulative = 0.88... round up)
```

**对于 agents：** 使用保守设置。Top-P 大约 0.9、Top-K 中等是合理的默认值。模型的默认设置对 agent 工作通常已经够用 — temperature 是你最有可能要调整的参数。

### 采样如何影响 agent 循环

考虑一个需要决定调用哪个 tool 的 agent。在低 temperature 下，对相同情境它会一致地（通常正确地）选择同一个 tool。在高 temperature 下，它可能在不同运行中选择不同 tools，从而导致行为不一致。

```
User: "What is the weather in Tokyo?"

Low temperature (0):
  -> Agent thinks: "I need the weather tool"
  -> Calls: get_weather(city="Tokyo")
  -> Consistent, predictable

High temperature (1.2):
  -> Run 1: Calls get_weather(city="Tokyo")
  -> Run 2: Calls web_search("Tokyo weather forecast")
  -> Run 3: Tries to answer from training data (no tool call)
  -> Inconsistent, hard to debug
```

对于生产级 agents，确定性行为几乎总是你想要的。

---

## ELI5：LLM 大脑是怎么工作的

### 把 LLM 想成一位主厨

想象你在经营一家餐厅厨房，LLM 就是你的主厨。

**主厨的训练（模型训练）：**
主厨花了多年研读上千本食谱，看烹饪节目，反复练习。他没有把每个菜谱一字不差地背下来，但已经形成了对什么风味搭配、什么技法适合什么食材、缺料时如何即兴发挥的深厚直觉。

**Tokens 像食材：**
主厨不是一次性想着一道完整的菜。他思考的是单个食材与步骤。「先洋葱、再蒜、再番茄……」每个食材的选择都为下一步做铺垫。这正是 token 预测的方式 — 每个 token 是基于之前所有 tokens 选出来的。

**context window 像料理台：**
主厨只能在台面上能放下的范围内工作。如果台面很大（1M tokens），他可以同时看到很多食材、菜谱与备料。台面小了，他就要把东西收起来腾位置，可能忘了刚刚在做什么。

**Temperature 像主厨的心情：**
- 低 temperature：主厨专注、按部就班，严格按食谱做。每次同一道菜味道都一样。
- 高 temperature：主厨放飞自我，即兴替换食材、尝试新东西。有时惊艳，有时奇怪。

**system instructions 像餐厅定位：**
「你是一家法式 bistro，使用传统技法，不做寿司。」这塑造了主厨的每个决定，无需在每道菜里重复。

**Tools 像厨房设备：**
仅靠主厨的知识无法把食物煮熟。他需要烤箱、炉灶、刀具与量具。同样地，仅靠 LLM 的推理无法查数据或调 APIs，它需要 tools。

**agent 循环像烹饪挑战：**
主厨拿到一个挑战（「为一位无麸质客人做一份三道式套餐」）。他规划方法，开始烹饪，边做边尝味道，调整调味，摆盘，并评估结果。如果酱汁分层了，他会排查并适配。这种「规划 — 行动 — 观察 — 调整」的循环，正是 agent 在做的事。

---

## 综合起来：模型选择如何影响 agent 质量

下面是一个把这些概念结合起来的真实 agent 场景。

### 场景：一个 bug 分诊 agent

你的团队希望有一个 agent 来读取新提交的 bug 报告，按严重程度分类，分配给合适的团队，并起草初步调查计划。

**模型选择决策：**

| 步骤 | 模型选择 | 推理 |
|---|---|---|
| 分类严重程度（P0-P3） | Flash（轻量） | 标准明确的简单分类 |
| 分配给团队 | Flash（轻量） | 基于组件的查表式决策 |
| 起草调查计划 | Pro（重型） | 需要理解 bug、相关系统并提出诊断步骤 |

**Temperature 决策：**

| 步骤 | Temperature | 原因 |
|---|---|---|
| 分类严重程度 | 0 | 必须确定 — 同样的 bug 应得到同样的严重程度 |
| 分配给团队 | 0 | 必须一致 — 同样的组件应路由到同样的团队 |
| 起草调查计划 | 0.3 | 一点点灵活性有助于产生更有用、更多样的调查思路 |

**system instruction 节选：**

```
You are a bug triage agent for the Platform Engineering team.

Severity classification:
- P0: Service is down or data loss is occurring
- P1: Major feature is broken, no workaround
- P2: Feature is impaired but a workaround exists
- P3: Minor issue, cosmetic, or improvement request

Team routing:
- Auth/login issues -> Identity team
- API errors -> Platform team
- UI issues -> Frontend team
- Database/performance -> Infrastructure team

When drafting an investigation plan:
- Start with the most likely root cause
- List 3-5 diagnostic steps in order of priority
- Include relevant log queries or dashboard links
- Note any recent deployments that might be related
```

这个例子展示了理解模型能力、设置合适参数、撰写清晰指令是如何共同促成一个可靠 agent 的。

---

## 在 agents 中使用 LLMs 的常见错误

### 1. 信任模型做数学

LLMs 预测 tokens，并不计算等式。任何重要的计算都应通过代码执行 tool 完成。

```
Bad:  "Calculate the total cost of 47 items at $23.99 each"
      -> Model might say $1,127.53 (the correct answer is $1,127.53,
         but it got lucky - it often gets these wrong)

Good: Have the agent call a calculator tool or code execution tool
      -> calculate("47 * 23.99") -> $1,127.53 (guaranteed correct)
```

### 2. 假设它有完美记忆

模型只「记得」当前 context window 里的内容。如果第 1 步的信息在第 10 步被截断，模型就不会再记得它。

### 3. 过度依赖单一模型

每一步都用前沿模型既浪费钱也增加延迟。使用模型路由让模型能力与任务复杂度匹配。

### 4. 忽视 system prompt

精心打磨的 system prompt 可以把一个只在 50% 时间能用的 agent，变成一个在 95% 时间都能用的 agent。值得花时间打磨并迭代你的 system instructions。

### 5. 没有为 hallucination 留余地

LLMs 会自信地生成看起来合理但其实错误的信息。任何重要的事实都应让 agent 的答案 ground 在 tool 结果上，而非模型的训练数据上。

---

## 关键要点

1. **LLM 是 agent 的推理引擎。** 理解它的能力与局限是构建好 agent 的基础。

2. **Tokens、context windows 与 attention** 是三个关键概念。Tokens 决定成本与速度。Context windows 决定模型能处理多少信息。Attention 决定模型聚焦在什么上。

3. **推理策略很重要。** Chain-of-Thought、Tree-of-Thoughts 与一步一步分解可以显著提升 agent 在复杂任务上的表现。

4. **为每一步挑选合适的模型。** 简单任务用轻量模型，复杂推理用重型模型。模型路由能降低成本与延迟。

5. **system instructions 是控制 agent 行为的主要杠杆。** 仔细写、写具体、并在测试中迭代。

6. **agents 的 temperature 保持低。** 对生产级 agent 系统，确定性行为几乎总是更好。

---

## 下一步是什么？

大脑很重要，但只能思考的 agent 依然只是个聊天机器人。下一节课我们给 agent 装上双手 — 让它能与世界互动、调用 APIs、搜索网页、运行代码的 tools。

[Next: Lesson 3 - Tools: Giving Agents Hands -->](/03-tools-giving-agents-hands/)
