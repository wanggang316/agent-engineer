---
title: "Lesson 19: orchestrators — 管理 Agent 的控制流"
---

## 引言

在前面的课程里，我们讲过 Agent 是什么、它们如何使用 tools，以及多个 Agent 如何协作。但我们还没有仔细看过让这一切运转起来的那一层——orchestration 层。

orchestrator 是控制系统，它决定：下一步做什么？哪个 Agent 运行？哪些信息进入 context？什么时候停下？它处于用户目标与实际执行之间，协调一切。

如果说 Agent 是工人，那么 orchestrator 就是项目经理。

### ELI5：把 orchestrator 想成电影导演

电影导演不演戏、不操作摄影机、不打灯。相反，他协调所有专业人员："摄影师，给个特写。演员，把这句台词说出来。音响师，加一段音乐。" 他决定顺序，在某一场戏拍不好时处理问题，让一切朝着完成的电影推进。

Agent orchestrator 做的是同样的事——它协调哪些 Agent 运行、按什么顺序、用什么输入，并决定出错时怎么办。

> **关键要点：** orchestrator 管理你 Agent 系统的控制流。选择正确的 orchestration 模式是你将做出的最重要的架构决策之一。

---

## orchestrator 究竟做什么？

orchestrator 管理四个核心关切：

### 1. 控制流

决定下一步做什么。Agent 应该调用 tool 吗？把任务交给另一个 Agent？向用户请求澄清？因目标已达成而停止？

### 2. context 组装

为每一步组装合适的 context。这意味着选择哪些信息进入 LLM 的 context window——system 指令、相关记忆、tool 结果、对话历史——并避免窗口溢出。

### 3. 状态管理

追踪已经做了什么、还要做什么、哪些成功了、哪些失败了。在多 Agent 系统中，这还包括管理 Agent 之间的共享状态。

### 4. 错误处理

决定出错时怎么办。Agent 应该重试？换一种方法？回退到更简单的方案？升级到人工？

orchestrator 运行的是核心 Agent 循环：

```
               +----> Assemble Context
               |            |
               |            v
  Receive Goal |      Invoke LLM (Reason)
               |            |
               |            v
               |      Execute Action (Act)
               |            |
               |            v
               +---- Observe Result
                            |
                   Goal met? ---> Return Result
```

每一次循环就是一个 "step"。orchestrator 决定何时继续循环、何时停止。

---

## orchestration 的两种类型

最根本的设计决策是：你的 orchestrator 在确定性控制与动态控制之间的光谱上落在哪里。

### 确定性（基于 workflow）

控制流是预先定义好的。orchestrator 按既定蓝图执行——它不会咨询 LLM 来决定下一步。各步骤按预定顺序、预定条件执行。

**优势：**
- 行为可预测——你确切知道会发生什么
- 易于调试——像普通代码一样单步执行 workflow
- 速度快——orchestration 决策不消耗 LLM 调用
- 可靠——orchestrator 不会跑偏

**局限：**
- 无法处理 workflow 没设计过的新情境
- 需要事先掌握所有可能的路径
- 修改 workflow 需要修改代码

**示例：** 一个文档处理流水线，固定地执行：抽取文本、分类文档类型、抽取实体、校验、入库。

### 动态（LLM 驱动）

orchestrator 用 LLM 决定下一步做什么。每一步它都会基于当前状态进行推理并选择下一步动作。这就是经典的 ReAct 循环。

**优势：**
- 能处理新颖的、开放式任务
- 计划失败时能自我适应
- 能处理开发者没有预想到的任务

**局限：**
- 较不可预测——相同输入可能产生不同的执行路径
- 更难调试——"Agent 为什么这么做？"
- 更昂贵——orchestration 用的 LLM 调用会累积
- 可能陷入循环或做出糟糕的路由决策

**示例：** 一个研究助手，根据已掌握的信息动态决定是上网搜索、查询数据库、阅读文档，还是向用户请求澄清。

### 混合（实用之选）

绝大多数生产系统会两者结合。它们用确定性 orchestration 控制整体结构，同时在每一步内部允许 LLM 驱动的灵活性。

**示例：** 一个客服系统，外层是确定性流程（接收工单、分类、路由到专员、确认解决、关闭），其中每一步内部使用一个 LLM Agent，可以自由推理如何处理具体任务。

---

## 核心 orchestration 模式

下面列出最常用的几种模式，并指出各自的适用场景：

### 顺序（pipeline）

Agent 按既定顺序依次执行。每个 Agent 的输出作为下一个 Agent 的输入。

```
Input --> [Agent A] --> [Agent B] --> [Agent C] --> Output
```

**适用：**
- 各阶段层层递进的任务
- 精炼工作流（草拟、审阅、编辑）
- 数据处理流水线（抽取、转换、校验）

**不适用：**
- 各阶段相互独立、本可并行执行
- 需要回溯（Agent C 失败时需重跑 Agent A）

**示例：** 代码生成流水线：需求分析 Agent 产出规格说明，编码 Agent 写实现，测试 Agent 写测试，审查 Agent 检查问题。

在 ADK 中，这就是 `SequentialAgent`：
```python
pipeline = SequentialAgent(
    name="code_pipeline",
    sub_agents=[analyzer, coder, tester, reviewer]
)
```

实现细节参见 [ADK SequentialAgent documentation](https://adk.dev/agents/workflow-agents/sequential-agents/)。

### 并行（fan-out / gather）

多个 Agent 在同一输入上同时执行。结果被收集并合并。

```
            +--> [Agent A] --+
            |                |
Input ------+--> [Agent B] --+--> Combine --> Output
            |                |
            +--> [Agent C] --+
```

**适用：**
- 从多个角度独立分析
- 对延迟敏感、并行执行能省时间的任务
- 对同一输入获取多样观点

**不适用：**
- Agent 之间需要彼此的输出才能工作
- 结果可能冲突且没有冲突解决策略

**示例：** code review 中，安全 Agent、性能 Agent、风格 Agent 同时审查同一个 PR，结果合并为一份评审。

在 ADK 中，这就是 `ParallelAgent`：
```python
review = ParallelAgent(
    name="code_review",
    sub_agents=[security_reviewer, performance_reviewer, style_reviewer]
)
```

实现细节参见 [ADK ParallelAgent documentation](https://adk.dev/agents/workflow-agents/parallel-agents/)。

### 循环（迭代精炼）

Agent 重复执行直到满足条件。这里有两种重要的子模式：

**生成—评审（Maker-Checker）：** 一个 Agent 生成输出，另一个评估它，循环持续直到评估者通过。

```
+--> [Generator Agent] --> [Critic Agent] --+
|                              |            |
|         Not good enough -----+            |
|                                           |
+-------------------------------------------+
                    |
              Good enough --> Output
```

**渐进式精炼：** 单个 Agent 通过多轮改写来改进自己的输出，就像作者反复修订草稿。

**适用：**
- 对质量敏感、首次产出几乎都不够好的任务
- 有明确验收标准的任务
- 迭代改进类工作流

**不适用：**
- 无法定义清晰的停止条件（有无限循环风险）
- 首次产出通常已经足够好

**重要：** 始终设置最大迭代次数。否则，如果评审者永不通过，循环会永远进行下去。

在 ADK 中，这就是 `LoopAgent`：
```python
refiner = LoopAgent(
    name="content_refiner",
    sub_agents=[writer, editor],
    max_iterations=5
)
```

实现细节参见 [ADK LoopAgent documentation](https://adk.dev/agents/workflow-agents/loop-agents/)。

### 路由（handoff / dispatch）

输入被分类后，导向某个专门的 Agent。每个请求只由一个 Agent 处理。

```
            +--> [Billing Agent]
            |
Input --> [Router] +--> [Technical Support Agent]
            |
            +--> [General Inquiry Agent]
```

路由可以是：
- **确定性：** 基于规则的分类（消息中包含 "invoice" 就路由到计费）
- **LLM 驱动：** 路由 Agent 通过推理挑选最合适的专员

**适用：**
- 含有专门部门的客服系统
- 不同输入需要不同专长的多领域系统
- 希望进行完整的控制权转移（同时只有一个 Agent 活跃）

**不适用：**
- 请求难以归入清晰类别
- 多个 Agent 需要协作处理同一请求

### 层级（Coordinator-Worker）

主控 Agent 协调整个流程，并把任务委派给专门的子 Agent。

```
                +---> [Research Agent]
                |
[Coordinator] --+---> [Analysis Agent]
                |
                +---> [Writing Agent]
```

主控 Agent：
1. 把整体目标拆分为子任务
2. 把子任务分派给合适的专员
3. 监控进度并处理依赖
4. 把结果合并为最终输出

**适用：**
- 需要多种专长的复杂任务
- 计划事先不明、必须边做边定的任务
- 研究型工作，一处的发现决定了下一步要探索什么

**不适用：**
- 简单任务，不值得引入协调开销
- 顺序流水线已经够用的情况

在 ADK 中，可通过 `AgentTool` 把子 Agent 包装成 tool，让主控 Agent 像调用函数一样调用它们。

### 群聊（roundtable）

多个 Agent 在一段共享对话中各自发言，由一个聊天管理者协调。

```
[Chat Manager]
      |
      +---> [Agent A]: "I think we should..."
      |
      +---> [Agent B]: "Building on that..."
      |
      +---> [Agent C]: "I disagree because..."
      |
      +---> [Agent A]: "Good point, let me revise..."
```

**适用：**
- 形成共识
- 多元视角能改善结果的头脑风暴
- 迭代式校验（多位专家审阅并精炼）

**不适用：**
- 效率比深度更重要时（群聊在 token 上很贵）
- 参与者超过三个 Agent 时（对话会变得混乱）

---

## 选择合适的模式

| 模式 | 可预测性 | 灵活性 | Token 成本 | 最佳场景 |
|---------|---------------|-------------|------------|----------|
| 顺序 | 高 | 低 | 低 | 清晰的逐步流程 |
| 并行 | 高 | 低 | 中（并发） | 独立的分析任务 |
| 循环 | 中 | 中 | 可变 | 质量精炼 |
| 路由 | 高 | 中 | 低 | 多领域分类 |
| 层级 | 中 | 高 | 较高 | 复杂的多步骤研究 |
| 群聊 | 低 | 高 | 最高 | 共识与头脑风暴 |

决策流程图：

```
Is the task a clear step-by-step process?
  Yes --> Sequential

Are there independent subtasks that can run simultaneously?
  Yes --> Parallel

Does the output need iterative improvement?
  Yes --> Loop

Does the task type determine which specialist handles it?
  Yes --> Routing

Is the task complex and requires planning and delegation?
  Yes --> Hierarchical

Does the task benefit from multiple perspectives and debate?
  Yes --> Group Chat
```

---

## 模式的组合

真实系统经常会嵌套各种模式。下面是一个内容创作系统的示例：

```
SequentialAgent("content_pipeline")
  |
  +-- ParallelAgent("research")
  |     +-- web_search_agent
  |     +-- database_query_agent
  |     +-- document_review_agent
  |
  +-- LlmAgent("writer")
  |     (uses research results to draft content)
  |
  +-- LoopAgent("refinement")
        +-- editor_agent
        +-- fact_checker_agent
        (loops until both approve)
```

它把并行研究、顺序推进与迭代精炼组合到了同一系统中。在 ADK 里，每个 workflow agent 都可以再包含 LLM agent、其它 workflow agent，或自定义 agent。

---

## 在 Google Cloud 上用 ADK 进行 orchestration

Google 的 Agent Development Kit 为确定性 orchestration 提供了三种内置 workflow agent 类型，并通过 LLM 驱动的协调处理动态场景。

### 内置 workflow agent

| Agent 类型 | 控制流 | ADK 类 |
|-----------|-------------|-----------|
| Sequential | 按顺序运行 agent | `SequentialAgent` |
| Parallel | 同时运行 agent | `ParallelAgent` |
| Loop | 重复直到满足条件 | `LoopAgent` |

它们都是确定性的——orchestration 决策不涉及 LLM。LLM 仅在各个子 Agent 内部用于其具体任务。

### LLM 驱动的协调

对于动态路由，可以使用一个父 `LlmAgent`（也叫 `Agent`）并挂上若干子 Agent。父 Agent 用其 LLM 根据对话与当前状态决定委派给哪个子 Agent。这就是实现路由与层级模式的方式。

### 自定义 Agent

对于不适合内置类型的 orchestration 逻辑，可以扩展 `BaseAgent` 来创建具有任意控制流的自定义 Agent。

### Agent-as-tool

ADK 允许通过 `AgentTool` 把任何 Agent 包装为 tool。这让协调者 Agent 可以像调用函数那样调用子 Agent，并接收结构化结果。

完整实现细节参见：
- [ADK Workflow Agents](https://google.github.io/adk-docs/agents/workflow-agents/)
- [ADK Multi-Agent Systems](https://google.github.io/adk-docs/agents/)
- [Multi-Agent Patterns in ADK - Google Developers Blog](https://developers.googleblog.com/developers-guide-to-multi-agent-patterns-in-adk/)

---

## 框架对比

ADK 是众多提供 orchestration 能力的框架之一。下面是主要选项的比较：

| 框架 | 思路 | 优势 | 注意事项 |
|-----------|----------|-----------|---------------|
| **Google ADK** | 三种确定性原语（Sequential、Parallel、Loop）+ LLM 驱动的协调 | workflow 与 reasoning 分离清晰。可部署到 Vertex AI Agent Engine。 | 较新的框架，社区比 LangChain 小 |
| **LangGraph** | 基于图的 workflow，由节点与边组成 | 对复杂分支与条件逻辑支持最强。可观测性成熟。 | 学习曲线较陡 |
| **CrewAI** | 角色化模型，把 Agent 定义成团队成员 | 上手最快。直观的 YAML 配置驱动。 | 在复杂的企业场景下可能不够精细 |
| **AutoGen**（Microsoft） | 对话式架构，支持动态角色扮演 | 适合 human-in-the-loop 与多方对话。 | 生产环境的搭建相当复杂 |
| **Claude Agent SDK** | 主控—Worker 模式，子 Agent 使用隔离的 context window | 子 Agent 使用隔离 context，仅返回相关信息。 | 仅适用于 Anthropic |

选择取决于你的优先级：想要 Vertex AI 集成与清晰的 workflow 原语就选 ADK；需要复杂图式流程就选 LangGraph；想用角色化团队快速搭起来就选 CrewAI。

---

## 最佳实践

### 从简单开始，必要时再增加复杂度

一个配备良好 tools 的单一 Agent，通常胜过 orchestration 糟糕的多 Agent 系统。从可行的最简方案开始：

1. 单一 Agent 加 tools
2. 顺序流水线（如果需要分阶段）
3. 并行执行（如果需要速度）
4. 完整的多 Agent 协作（如果需要专业分工）

不要因为听起来高大上就直接上层级多 Agent 系统。只有当单 Agent 明显处理不了任务时，才增加更多 Agent。

### 让模型与任务匹配

在你的 orchestration 中，并非每个 Agent 都需要相同的模型。一个分类路由器可以用又快又便宜的模型（Gemini Flash-Lite）。一个复杂推理 Agent 应该用能力更强的模型（Gemini Pro）。这样能显著节省成本。

### 设置迭代上限

任何循环或递归式 orchestration 都必须有最大迭代次数。否则，一个永远满足不了自身条件的 Agent 会一直运行下去。精炼循环常用 3-5 次作为默认。

### 在步骤之间做校验

在顺序流水线中，把每个 Agent 的输出在传给下一个之前先做校验。Agent A 输出的格式错误或跑题结果会沿着 B、C 一路传下去，浪费 token 并产生垃圾。

### 跨 Agent 管理 context

在多 Agent 系统中，context window 增长很快。控制策略包括：

- 在 Agent 之间传递前先做摘要
- 对大型共享数据使用外部状态存储
- 只把必要的 context 给到每个 Agent，而不是全部
- 对长时间运行的任务使用 context 压缩（滑动窗口、摘要）

### 为可观测性埋点

按 Agent 与按 orchestration 运行追踪性能：
- 每一步的延迟
- 每个 Agent 的 token 使用量
- 每一步的成功/失败率
- 端到端任务完成率

使用分布式 tracing（例如 OpenTelemetry）跟随一次请求穿过多个 Agent。这是出错时调试的关键。

实现指南参见 [ADK Tracing documentation](https://google.github.io/adk-docs/) 与 [Google Cloud Trace](https://cloud.google.com/trace)。

### 为失败设计

Agent 会失败。Tools 会返回错误。LLM 会出现 hallucination。你的 orchestrator 必须优雅地应对：

- **带退避的重试** 应对瞬时错误（API 超时、限流）
- **回退策略** 应对持续性失败（换一个 tool、用更简单的模型）
- **熔断器** 防止级联失败
- **人工升级** 作为关键任务的最后兜底

---

## 常见反模式

| 反模式 | 问题 | 修复 |
|-------------|---------|-----|
| orchestration 过度设计 | 单 Agent 就能处理的任务用了多 Agent 系统 | 从一个 Agent 开始，确有需要再加 |
| Agent 没有专业分工 | 多个 Agent 干的事大致雷同 | 给每个 Agent 明确不同的角色与专长 |
| 共享可变状态 | 并发 Agent 写入同一状态，引发竞态 | 使用不可变消息或合理的状态加锁 |
| 没有迭代上限 | 退出条件永远不满足，循环不停 | 总是设置 max_iterations |
| context window 膨胀 | 在流水线中把完整对话历史传给每个 Agent | 在步骤之间做摘要与裁剪 |
| 该用动态却用了确定性 | 对需要适应性推理的任务使用固定流水线 | 对不可预测任务使用 LLM 驱动的路由 |
| 该用确定性却用了动态 | 对清晰、已知顺序的任务用了 LLM 路由 | 用 workflow agent 节省成本并提升可靠性 |

---

## 关键要点

- orchestrator 管理控制流、context 组装、状态与错误处理
- 两种基本类型：确定性（可预测、便宜、有限）与 LLM 驱动（灵活、昂贵、可预测性低）
- 大多数生产系统采用混合——确定性结构搭配步骤内的 LLM 灵活性
- 核心模式：顺序、并行、循环、路由、层级、群聊
- 模式可组合——通过嵌套用简单的部件构建出复杂系统
- ADK 提供 SequentialAgent、ParallelAgent、LoopAgent 用于确定性 orchestration，并提供 LLM 驱动的协调用于动态路由
- 从简单开始。一个装备良好的单 Agent 胜过糟糕的 Agent 团队
- 设定迭代上限、在步骤间做校验、积极地管理 context、并为失败做设计

---

## 延伸阅读

- [ADK Workflow Agents](https://google.github.io/adk-docs/agents/workflow-agents/)
- [Multi-Agent Patterns in ADK](https://developers.googleblog.com/developers-guide-to-multi-agent-patterns-in-adk/)
- [Anthropic - Building Effective AI Agents](https://www.anthropic.com/research/building-effective-agents)
- [Microsoft Azure - AI Agent Orchestration Patterns](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns)
- [LangGraph Documentation](https://langchain-ai.github.io/langgraph/)
- [CrewAI Documentation](https://docs.crewai.com/)

---

[Previous Lesson: Agent Skills](/18-agent-skills/) | [Back to Course Overview](/)
