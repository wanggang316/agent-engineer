---
title: "Lesson 4: agentic 设计模式"
---

## 你将学到

- 什么是 agentic 设计模式，以及它们为什么重要
- 四个核心模式：ReAct、Reflection、Tool Use 与 Planning
- 何时使用每种模式以及涉及的取舍
- 如何在真实场景的 agents 中组合多种模式

## 前置条件

- [Lesson 1: What Are AI Agents?](/01-what-are-ai-agents/)
- [Lesson 2: How Agents Think](/02-how-agents-think/)
- [Lesson 3: Tools - Giving Agents Hands](/03-tools-giving-agents-hands/)

---

## ELI5：设计模式像菜谱

想象你想做晚饭。你可以随手抓些食材碰碰运气；也可以照着菜谱来 — 一份别人已经验证好用的步骤集合。

设计模式就是构建 AI agents 的菜谱。它们是行之有效的方式，用来组织 agent 如何思考、行动与学习。就像菜谱书针对不同的菜式有不同的菜谱，我们也针对不同类型的 agent 行为有不同的模式。

而且，正如优秀的厨师会把多份菜谱里的技法组合起来，最好的 agents 通常也是把若干模式组合在一起。

---

## 设计模式为什么重要

如果你写过一段时间的软件，你大概熟悉 Observer、Strategy 或 Factory 这类设计模式。这些模式给工程师提供了共享词汇，以及解决常见问题的成熟蓝图。

agentic 设计模式服务的是同样的目的，只不过面向 AI agents。它们描述了 agents 在以下方面反复出现的结构：

- **推理**问题
- 在世界中**采取行动**
- 从结果中**学习**
- **改进**自己的输出

没有这些模式，构建 agent 就像写意大利面式代码 — 一切都纠缠在一起、难以调试。有了它们，你会得到一个更易构建、测试与维护的清晰架构。

### 从简单到 agentic

并非每次 LLM 交互都需要一个设计模式。下面是一个粗略的连续谱：

| Level | 描述 | 示例 | 所需模式 |
|-------|------------|---------|----------------|
| **Simple prompt** | 一问一答 | 「法国的首都是什么？」 | 无 |
| **Structured output** | LLM 格式化其响应 | 「以 JSON 返回」 | 无 |
| **Chain** | 多次 LLM 调用顺序连接 | 先摘要，再翻译 | 较少 |
| **Agent** | LLM 决定下一步做什么 | 调研一个话题并写报告 | ReAct、Tool Use、Planning |
| **Multi-agent** | 多个 agents 协作 | 一支构建软件的 agents 团队 | 上述全部 + 协作 |

一旦你从简单链式（chains）走向真正 agentic 的行为 — 也就是 LLM 在决定下一步做什么 — 设计模式就变得重要。

---

## 模式 1：react（reason + act）

ReAct 是最基础的 agentic 设计模式。如果你只学一种模式，就学这一种。

### 核心思想

ReAct 把**推理**（思考做什么）与**行动**（真正去做）以交替的循环组合在一起。Agent 会：

1. **思考**当前局势
2. **行动**：调用一个 tool 或采取一步
3. **观察**结果
4. **重复**直到任务完成

### 餐厅服务员类比

把一名餐厅服务员想象成 agent：

1. **想：**「5 号桌点了意大利面。我要去厨房看看好了没。」
2. **做：**走到厨房问。
3. **观察：**主厨说还差 5 分钟。
4. **想：**「那我趁这个时间去看看 3 号桌的饮料。」
5. **做：**去 3 号桌续杯。
6. **观察：**3 号桌满意了。
7. **想：**「时间差不多了，我去厨房看 5 号桌的面。」
8. **做：**回厨房。
9. **观察：**面好了。
10. **做：**把面送到 5 号桌。

服务员不会提前规划整个班次。他思考、行动、观察、调整 — 持续地。

### ReAct 的样子

下面是一般流程：

```
User: "What is the weather in Tokyo and should I pack an umbrella?"

Agent Thought: I need to find the current weather in Tokyo. I will use the weather tool.
Agent Action: call weather_api(location="Tokyo")
Observation: {"temp": 18, "condition": "rain", "forecast": "rain continuing through tomorrow"}

Agent Thought: It is currently raining in Tokyo and rain is expected to continue.
                The user should pack an umbrella.
Agent Action: Respond to user.

Agent Response: "It is currently 18C and raining in Tokyo, with rain expected to
                continue through tomorrow. Definitely pack an umbrella!"
```

### ReAct 的关键特征

- **推理与行动交替进行。** Agent 不会盲目行动 — 它对每一步做思考。
- **以观察为依据。** 每个想法都基于 agent 真正看到的内容，而不是它想象的内容。
- **灵活。** Agent 可以根据新发现改变路线。
- **透明。** 推理轨迹让你更容易调试 agent 当时在想什么。

### 何时使用 ReAct

| 适合 | 不适合 |
|----------|----------|
| 需要外部信息的任务 | 纯文本生成任务 |
| 路径不确定的多步问题 | 简单的一问一答 |
| 需要审计轨迹的场景 | 对延迟敏感的应用 |
| 需要根据新信息适配的任务 | 顺序固定且已知的任务 |

### 常见陷阱

- **推理循环。** Agent 反复想同一个想法却没有进展。加一个最大迭代次数。
- **幻觉式动作。** Agent 「调用」了一个并不存在的 tool。在执行前校验 tool 名称。
- **观察盲区。** Agent 忽视 tool 返回的内容，仍按先前假设继续。确保观察被清晰地注入到上下文中。

---

## 模式 2：reflection

### 核心思想

在 Reflection 模式中，agent 审视自己的输出并加以改进。它不是产生一个回复就结束，而是先生成一份草稿、批评它，然后再修订。

### 作家类比

想象一位作家在写文章：

1. **草稿：**先写第一版。
2. **复盘：**重读一遍。「嗯，开头偏弱，第三段还跟第一段矛盾。」
3. **修订：**重写开头并修正矛盾。
4. **再次复盘：**「好多了。但结尾的行动号召还可以更有力。」
5. **再次修订：**改进结尾。
6. **完成：**最终版比初稿好得多。

没有一位有经验的作家会直接发表第一稿。同样，会反思自己输出的 agents 也能产出明显更好的结果。

### Reflection 的样子

```
Step 1 - Generate:
  Agent produces initial response to user's request.

Step 2 - Critique:
  Agent (or a separate critic) reviews the response:
  "This code has a bug on line 12 - the loop index is off by one.
   Also, the function lacks error handling for empty input."

Step 3 - Revise:
  Agent fixes the identified issues and produces an improved version.

Step 4 - Evaluate:
  "The bug is fixed and error handling is added. The code now handles
   edge cases. This meets the requirements."
```

### Reflection 的变体

| 变体 | 怎么工作 | 示例 |
|-----------|-------------|---------|
| **Self-reflection** | 同一个 LLM 审视自身输出 | 「检查你写的代码是否有 bug」 |
| **Critic agent** | 一个独立的 LLM 实例做审视 | 专门的 code reviewer agent |
| **Rubric-based** | 由具体标准引导的反思 | 「检查准确性、完整性、语气」 |
| **Test-driven** | 用具体检查测试输出 | 跑单元测试、检查格式 |

### 何时使用 reflection

| 适合 | 不适合 |
|----------|----------|
| 代码生成（在交付前抓 bug） | 实时对话回复 |
| 写作任务（提升清晰度与结构） | 简单的事实查询 |
| 复杂推理（捕捉逻辑错误） | 速度比质量更重要的任务 |
| 任何质量重于速度的任务 | 答案有客观可验证标准的任务 |

### 实操建议

- **设置最大反思轮次。** 通常两到三轮就够。再多往往收益递减。
- **使用具体标准。** 「让它更好」太模糊。「检查 SQL 注入漏洞、缺失的错误处理与性能问题」让反思有焦点。
- **考虑给 critic 用不同的模型或 prompt。** 一个新的视角比同样的眼光重读发现的问题更多。
- **追踪变更。** 记录每次修订之间的差异，以便核实反思是否真的改进了内容。

---

## 模式 3：tool use

### 核心思想

在 Tool Use 模式中，agent 决定调用哪些 tools、传什么参数、按什么顺序。LLM 充当一个推理引擎，编排外部能力，而不是事事都自己做。

我们在 [Lesson 3](/03-tools-giving-agents-hands/) 中已深入讨论 tools。本节聚焦于 agents 决定使用 tools 的*模式*。

### 工匠类比

想象一位有经验的木匠在做一个项目。他工坊里满是工具 — 锯、电钻、砂纸机、夹钳。对项目的每一步，他会：

1. 评估接下来要做什么
2. 为这一步选合适的工具
3. 使用该工具
4. 检查结果
5. 决定下一步

他不会用锤子搞定一切。他会按需选工具。有时项目做到一半才发现需要原本没打算用的工具。

### tool use 的样子

```
User: "Find the top 3 trending repositories on GitHub about AI agents
       and summarize what each one does."

Agent Thought: I need to search GitHub for trending AI agent repositories.
Agent Action: github_search(query="AI agents", sort="stars", limit=3)
Observation: [repo1: "autogen", repo2: "crewai", repo3: "langchain-agents"]

Agent Thought: Now I need to get details about each repository.
Agent Action: github_get_repo(name="autogen")
Observation: {description: "...", readme: "...", stars: 42000}

Agent Action: github_get_repo(name="crewai")
Observation: {description: "...", readme: "...", stars: 28000}

Agent Action: github_get_repo(name="langchain-agents")
Observation: {description: "...", readme: "...", stars: 19000}

Agent Thought: I now have enough information to summarize all three.
Agent Response: "Here are the top 3 trending AI agent repositories..."
```

### tool 选择策略

Agents 用多种策略来决定使用哪个 tool：

| 策略 | 描述 | 取舍 |
|----------|------------|-----------|
| **直接匹配** | tool 名称/描述匹配需求 | 快，但若 tool 命名糟糕则脆弱 |
| **能力推理** | Agent 推理每个 tool 能做什么 | 更灵活，但消耗更多 tokens |
| **少样本示例** | Prompt 中的示例展示何时使用每个 tool | 可靠，但占用上下文空间 |
| **Tool 推荐** | 系统根据查询提示相关 tools | 减轻 LLM 的决策负担 |

### 并行 vs 顺序的 tool 调用

有些任务允许同时调用多个 tools：

- **顺序：** 先查找一个用户，再查他的订单历史（需要先拿到 user ID）
- **并行：** 同时查三个不同城市的天气（彼此独立）

并行 tool 调用能显著降低延迟。设计 agent 时，识别哪些 tool 调用相互独立、可以同时进行。

### 何时使用 tool use

这一模式几乎适用于任何与外部系统交互的 agent。关键设计决策包括：

- **多少个 tools？** 从小做起。一个有 3-5 个设计良好 tools 的 agent，通常胜过一个有 50 个糟糕设计 tools 的 agent。
- **tool 的 schema 描述得多详尽？** 描述越好，tool 选择越准。
- **tool 失败时怎么办？** 好的 agents 会优雅地处理错误 — 重试、换一个 tool，或向用户求助。

---

## 模式 4：planning

### 核心思想

在 Planning 模式中，agent 在执行前先制定一个计划。它不是边走边想（像 ReAct 那样），而是提前思考并铺出一个结构化的方法。

### 项目经理类比

想象一位项目经理收到了实现一个新特性的请求：

1. **拆解：**「我们需要更新数据库 schema、写 API 接口、构建 UI 并加测试。」
2. **排序：**「先 schema，然后 API，再 UI，最后测试 — 每一步都依赖前一步。」
3. **分配资源：**「数据库工作交给后端团队，UI 交给前端团队。」
4. **执行与跟踪：**按计划推进，完成后逐项打勾。
5. **必要时调整：**「schema 变更比预期复杂 — 我重新规划一下时间线。」

### Planning 的样子

```
User: "Write a comprehensive blog post about Kubernetes security best practices."

Agent Plan:
  1. Research current Kubernetes security threats and CVEs
  2. Identify the top 5-7 security best practices
  3. For each practice, find concrete examples and commands
  4. Write an outline with introduction, main sections, and conclusion
  5. Draft each section
  6. Review the full post for accuracy and flow
  7. Add code examples and formatting

Agent Execution:
  [Executes steps 1-7 in order, adjusting as needed]
```

### 规划策略

| 策略 | 怎么工作 | 适合 |
|----------|-------------|----------|
| **顺序规划** | 创建线性的步骤列表 | 简单、易理解的任务 |
| **层级规划** | 拆为高层目标，再分解为子任务 | 复杂、多阶段的项目 |
| **条件规划** | 在计划中包含 if/then 分支 | 结果不确定的任务 |
| **迭代规划** | 计划几步、执行、再重新规划 | 后续步骤依赖早期结果的任务 |

### 先规划再执行 vs ReAct

这两个模式代表了不同的哲学：

| 方面 | Planning | ReAct |
|--------|----------|-------|
| **何时做决策** | 主要在前期 | 一步一步 |
| **适应性** | 需要显式重规划 | 天然适应性强 |
| **效率** | 可并行独立步骤 | 通常顺序执行 |
| **透明度** | 完整计划提前可见 | 每一步的推理可见 |
| **白做风险** | 计划错时更高 | 较低，边走边调整 |
| **最适合** | 结构良好的任务 | 探索性任务 |

实践中，多数 agents 会混合两种方法：先做一个大致的规划，再在执行时使用 ReAct 风格的推理。

### 何时使用 planning

| 适合 | 不适合 |
|----------|----------|
| 结构清晰的多步任务 | 简单的一步任务 |
| 顺序重要的任务 | 纯反应式/对话式 agents |
| 可并行化的工作 | 路径完全未知的任务 |
| 需要进度跟踪的项目 | 临时性的简短请求 |

---

## 模式对比

下面是一份并排对比，帮助你做选择：

| 模式 | 核心思想 | 优点 | 缺点 | 成本 |
|---------|-----------|----------|----------|------|
| **ReAct** | 想-做-观察 循环 | 灵活、透明 | 可能慢、可能死循环 | 中（多次 LLM 调用） |
| **Reflection** | 自我审视并改进 | 输出质量更高 | 增加延迟 | 高（多轮处理） |
| **Tool Use** | 编排外部 tools | 扩展 agent 能力 | 取决于 tool 质量 | 视情况而定（依赖 tool） |
| **Planning** | 执行前先规划 | 结构化、高效 | 计划错时脆弱 | 中到高（规划 + 执行） |

### 决策流程图

问自己这些问题：

1. **agent 需要外部信息或动作吗？** 是 -> Tool Use
2. **任务多步且路径不确定吗？** 是 -> ReAct
3. **质量关键且任务有清晰标准吗？** 是 -> Reflection
4. **任务复杂但结构清晰吗？** 是 -> Planning
5. **大多数都是「是」？** -> 组合模式

---

## 组合模式

真实场景下的 agents 几乎从不孤立使用单一模式。最有效的 agents 会把模式叠加起来。

### 常见组合

**ReAct + Tool Use**（最常见的组合）

Agent 推理要做什么、用 tools 行动、观察结果、再次推理。这是大多数实用 agents 的骨架。

```
Think -> Use Tool -> Observe -> Think -> Use Tool -> Observe -> Respond
```

**Planning + ReAct + Tool Use**

Agent 先制定计划，再以 ReAct 风格的推理 + tools 来执行每一步。

```
Plan -> [Think -> Act -> Observe] -> [Think -> Act -> Observe] -> ... -> Done
```

**Planning + Reflection**

Agent 先制定计划、执行，然后在交付之前对整体输出做一次审视。

```
Plan -> Execute -> Reflect -> Revise -> Deliver
```

**全栈：Planning + ReAct + Tool Use + Reflection**

对于复杂、高风险的任务，可能四种都用：

```
Plan the approach
  -> Execute each step with ReAct + Tools
    -> Reflect on the overall result
      -> Revise if needed
        -> Deliver
```

### 示例：一个代码生成 agent

下面是一个代码生成 agent 可能如何组合各种模式：

1. **Planning：**「我需要写一个 REST API。步骤：定义数据模型、创建端点、添加校验、写测试。」
2. **ReAct + Tool Use：** 对每一步，agent 推理要做什么，使用 tools（文件读取、代码搜索、linter）来收集信息并写代码。
3. **Reflection：** 写完代码后，agent 按最佳实践审视。「错误处理到位吗？输入校验了吗？是否存在安全问题？」
4. **修订：** Agent 修复反思中发现的问题。

### 何时不要组合

模式更多并不总是更好。每个模式都会增加：

- **延迟：** 更多 LLM 调用意味着更多时间
- **成本：** 更多 tokens 意味着更多花费
- **复杂度：** 更多组件意味着更多调试

对于一个简单的问答 agent，ReAct + Tool Use 大概就够了。把全栈留给质量足以证明成本合理的复杂、高价值任务。

---

## 模式在 Google Cloud 中的体现

Google Cloud 的 [Vertex AI Agent Engine](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview) 为构建采用这些模式的 agents 提供基础设施。[Agent Development Kit (ADK)](https://google.github.io/adk-docs/) 给你实现这些模式的构件。

Google Cloud 生态中的关键概念：

- **Agent Engine** 管理你的 agents 的生命周期 — 部署、扩缩容与监控
- **ADK** 提供定义 agent 行为、tools 与 orchestration 的框架
- **Gemini models** 作为 LLM 主干，为每种模式中的推理提供动力

我们将在 [Lesson 12](/12-getting-started-with-vertex-and-adk/) 与 [Lesson 13](/13-building-your-first-agent/) 中实战这些。

---

## 关键要点

1. **agentic 设计模式是被验证过的蓝图**，用来组织 agents 如何思考与行动。它们提供共享词汇和架构起点。

2. **ReAct 是基础。** 想-做-观察 的循环是最基础的模式，也是大多数 agents 的起点。

3. **Reflection 显著提升质量**，但代价是时间与 tokens。当质量比速度更重要时使用它。

4. **Tool Use 把 agents 的能力**从 LLM 内建知识之外扩展出去。良好的 tool 设计与良好的 prompt 设计同等重要。

5. **Planning 为复杂任务带来结构。** 当任务边界清晰、步骤可以提前列出时最合适。

6. **审慎地组合模式。** 模式越多，能力越强，但复杂度与成本也更高。从简单做起，按需添加。

7. **没有单一最佳模式。** 正确的选择取决于你的任务、质量要求与延迟、成本预算。

---

## 延伸阅读

- [Vertex AI Agent Engine overview](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview)
- [Agent Development Kit (ADK) documentation](https://google.github.io/adk-docs/)
- [Google Cloud AI codelabs](https://codelabs.developers.google.com/?cat=AI)

---

**下一节课：** [Memory and Context - How Agents Remember](/05-memory-and-context/)
