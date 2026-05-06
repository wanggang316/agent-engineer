---
title: "Lesson 1: 什么是 AI Agents？"
---

## 引言

你大概用过 ChatGPT、Gemini 或 Claude 来回答问题或写一些代码。你输入一段文字，得到一段回复，然后继续做别的事。这就是 language model 在做它擅长的事 — 基于你的输入预测有用的文本。

AI agent 是另一回事。一个 agent 可以**思考**、**行动**和**记忆**。它不只回答你的问题 — 它会判断需要采取哪些步骤、使用 tools 去执行这些步骤，并根据过程中的情况调整方法。

可以这样理解：如果你雇了一个新工程师，但只允许他说话，从不让他碰键盘、打开浏览器或阅读文档，他能做的事会非常有限。这就是单独的 LLM。现在给他访问代码库的权限、一个终端、公司文档，以及主动提问澄清的能力。这就是 agent。

本课时介绍 AI agents 是什么、它们与普通 language models 的差别、构成它们的组件，以及什么时候应该（和不应该）使用 agents。

---

## 用大白话讲，什么是 AI agent？

AI agent 是一个软件系统，它以 language model 作为核心推理引擎，并配合在真实世界中采取行动的能力。这些行动可能包括：

- 搜索网页
- 查询数据库
- 调用 API
- 读写文件
- 发送邮件
- 运行代码

关键区别在于**自主性**。普通的 LLM 响应单个 prompt。一个 agent 接到一个目标后，会自主决定要采取哪些步骤、执行这些步骤、观察结果，并持续推进直到目标达成（或它判断目标无法达成）。

### 新员工类比

想象你雇了一名新软件工程师。第一天你不会指望他什么都懂。但你会期望他：

1. **阅读文档**以理解代码库
2. **使用 tools**，比如 IDE、终端和浏览器
3. **提问**当某些东西不清楚时
4. **拆解任务**为更小的步骤
5. **检查工作**再宣布完成
6. **从错误中学习**并调整方法

AI agent 的工作方式相同。它有一份知识基础（language model）、可以使用 tools，以及一个 orchestration 层来管理思考、行动、观察的循环。

---

## LLM 与 agent：差别在哪里？

这是早期需要内化的最重要的区分。

| 方面 | 单独的 LLM | AI Agent |
|---|---|---|
| **它做什么** | 基于一个 prompt 生成文本 | 通过多步追求一个目标 |
| **交互方式** | 单轮（或多轮聊天） | 思考与行动的自主循环 |
| **Tools** | 无 — 文本进，文本出 | 可以调用函数、APIs、搜索等 |
| **记忆** | 仅限于 context window | 可以跨步骤持久化信息 |
| **决策** | 响应你提出的问题 | 自行决定下一步做什么 |
| **错误处理** | 给出一个答案（对或错） | 可以观察错误并以新方法重试 |

一个有用的心智模型：

- **LLM** = 大脑
- **Agent** = 大脑 + 双手 + 记忆

大脑（LLM）负责推理。双手（tools）让它采取行动。记忆（状态管理）让它跟踪已经发生了什么、还需要做什么。

### 一个具体例子

**单独的 LLM：** 你问「GOOG 股票现在的价格是多少？」模型可能会说「截至我训练数据的时间点，大约是 $140」 — 这可能已经过时数月。

**Agent：** 你问同样的问题。Agent 会想「我需要当前的股价数据，应该使用一个金融 API。」它调用一个股价 tool，拿到实时价格，并返回一个准确的答案。如果 API 调用失败，它可能会尝试另一个数据源。

这个循环 — 思考、行动、观察、重复 — 正是让 agent 成为 agent 的关键。

---

## AI agent 的核心组件

无论使用哪个框架，每个 agent 系统都有三个基本组件：

### 1. 模型（大脑）

这是位于 agent 中心的 language model。它负责：

- **理解**用户的目标
- **推理**该采取什么步骤
- **决定**使用哪个 tool（以及参数是什么）
- **解读** tool 调用的结果
- **生成**最终回复

你选择的模型很重要。更难的任务（多步推理、复杂代码生成、细致决策）会从前沿模型如 Gemini 或 Opus 中受益。更简单的任务（分类、抽取、直白的 Q&A）可以使用 Gemini Flash 这类轻量模型，以节省成本和延迟。

### 2. tools（双手）

Tools 让 agent 能够超越文本生成，与世界互动。没有 tools，agent 不过是个聊天机器人。有了 tools，它可以：

- **检索信息**：搜索网页、查询数据库、读文件
- **采取行动**：发送邮件、创建工单、部署代码
- **计算**：执行计算、运行代码、转换数据

Tools 通常被定义为带有清晰名称、描述和参数 schema 的函数。模型决定何时调用以及如何调用它们。我们在 Lesson 3 中会深入讨论 tools。

### 3. orchestration 层（控制循环）

这是把模型与 tools 连接成一个可运行系统的胶水。orchestration 层管理：

- **agent 循环**：思考 -> 行动 -> 观察 -> 重复
- **状态管理**：到目前为止发生了什么、模型需要哪些上下文
- **错误处理**：tool 调用失败时怎么办
- **终止条件**：何时停止循环并返回结果
- **guardrails**：安全检查、输出验证、范围限制

最简单的 orchestration 模式如下：

```
1. Receive user goal
2. Send goal + available tools to the model
3. Model returns either:
   a. A final answer -> Return to user
   b. A tool call -> Execute the tool, add result to context, go to step 2
```

这通常被称为 **ReAct loop**（Reasoning + Acting）。还有更复杂的模式 — 我们将在后续课时中探索它们。

### 各组件如何协同工作

```
User Goal
    |
    v
+-------------------+
| Orchestration     |
| Layer             |
|                   |
|  +-------------+  |
|  |   Model     |  |    "I need to search for X"
|  |  (Brain)    |--+--->  Tool Call
|  +-------------+  |         |
|        ^          |         v
|        |          |  +-------------+
|        +----------+--+   Tools     |
|     Tool results  |  |  (Hands)   |
|                   |  +-------------+
+-------------------+
    |
    v
Final Response
```

---

## agent 系统的分类

并非所有 agents 都生而平等。把 agent 系统放在一个自主性与能力的连续谱上来看会很有帮助，从 Level 0 到 Level 4。

### Level 0：基础推理（简单 LLM）

**它是什么：** 一个不带 tools 也无记忆的 language model 在回答问题。

**示例：** 你问 Gemini「解释一下 CAP 定理」，它给你一段基于训练数据的清晰解释。

**能力：**
- 文本生成与理解
- 单轮或多轮对话
- 没有外部数据访问
- 无法采取行动

**适用场景：** 通用知识问答、创意写作、头脑风暴、对给定文本做摘要。

### Level 1：可连接的问题求解器（使用 tool 的 agent）

**它是什么：** 一个可以调用 tools 来检索信息或执行简单动作的模型。这是从「聊天机器人」迈向「agent」的分界。

**示例：** 一个客服机器人可以通过调用你的订单 API 查询订单状态；或者一个编码助手可以搜索文档。

**能力：**
- Level 0 的所有内容
- function calling（tools）
- 用 Retrieval-Augmented Generation (RAG) 把回答 grounded 在真实数据上
- 简单的单步或少量步骤的任务完成

**适用场景：** 需要当前数据、API 集成、步骤较少的直白工作流。

### Level 2：策略性 agent（具备上下文的自主体）

**它是什么：** 一个能够规划多步路径、在更长会话中保持上下文、并根据中间结果调整策略的 agent。

**示例：** 一个研究 agent 接到「比较前三大云厂商在 serverless 定价上的差异」这样的问题后，去搜索定价页面、抽取数据、构建对比表并总结发现。

**能力：**
- Level 1 的所有内容
- 多步规划与执行
- 在情况变化时进行动态重规划
- 跨步骤的工作记忆
- 自我评估（「这个结果够好吗？」）

**适用场景：** 研究类任务、复杂故障排查，以及路径依赖中间结果的多步工作流。

### Level 3：协作型多 Agent 系统

**它是什么：** 多个专业化 agents 协同工作，每个负责更大任务的一部分。某个 agent 可能负责协调其他 agents。

**示例：** 一个软件开发系统中，一个 agent 写代码，另一个写测试，第三个做代码审查，由一个 orchestrator agent 管理整个工作流。

**能力：**
- Level 2 的所有内容
- agent 之间的通信
- 专业化角色与委派
- 子任务的并行执行
- 用于质量控制的共识或投票机制

**适用场景：** 受益于专业化分工的复杂项目，以及需要多视角或质量门的任务。

### Level 4：自我进化 agent

**它是什么：** 能够反思自身表现、从历史运行中学习、更新策略，并在没有人工干预的情况下随时间变得更好的 agent。

**示例：** 一个部署 agent 跟踪过去哪些回滚策略效果最好，并据此调整未来的部署方法。

**能力：**
- Level 3 的所有内容
- 长期记忆与学习
- 基于历史结果的策略优化
- 自我修改 prompts 或 tool 选择
- 性能监控与自我纠正

**适用场景：** 模式会随时间出现的重复性任务，以及能从持续改进中受益的系统。

### 汇总表

| Level | 名称 | 关键特征 | 示例 |
|---|---|---|---|
| 0 | Basic Reasoning | 文本进，文本出 | Chatbot、Q&A |
| 1 | Connected Problem-Solver | 使用 tool | 订单查询机器人 |
| 2 | Strategic Agent | 多步规划 | 研究助手 |
| 3 | Collaborative Multi-Agent | agent 协作 | 研发团队模拟 |
| 4 | Self-Evolving | 从经验中学习 | 自适应运维 agent |

如今大多数生产级 agent 系统运行在 Level 1 或 Level 2。Level 3 和 Level 4 是活跃的研究领域，正在变得越来越实用，但它们会带来显著的复杂度。从简单做起，只有当确有必要时再向上提升。

---

## 何时使用 agents、何时一个简单 prompt 就够

Agents 增加了能力，但同时也带来复杂度、成本和延迟。并非每个问题都需要 agent。下面是一些实用指导。

### 使用简单 prompt 的场景：

- 任务可以一步完成
- 不需要外部数据或动作
- 答案存在于模型的训练数据中
- 低延迟至关重要（agents 会增加多次往返）
- 多次模型调用的成本不值得

**例子：**
- 「Summarize this paragraph」
- 「Convert this JSON to a Python dataclass」
- 「Write a regex that matches email addresses」
- 「Explain the difference between TCP and UDP」

### 使用 agent 的场景：

- 任务涉及多个相互依赖的步骤
- 需要外部数据或 tools（APIs、数据库、搜索）
- 任务需要实时或最新信息
- 方法可能需要根据中间结果调整
- 任务需要采取行动（不仅仅是生成文本）

**例子：**
- 「找出我们 issue tracker 中最近的三个 bug，并为团队站会准备一份摘要」
- 「查找客户的订单，检查发货状态，并发送一封更新邮件」
- 「调研竞争对手定价，并构建一份对比表」
- 「审查这个 pull request，运行测试，并提出改进建议」

### 决策流程图

```
Does the task require external data or actions?
  |
  +-- No --> Can the model answer from its training data?
  |            |
  |            +-- Yes --> Use a simple prompt
  |            +-- No  --> Consider RAG (retrieval) first, then an agent
  |
  +-- Yes --> Is it a single tool call?
               |
               +-- Yes --> A simple function-calling setup may suffice
               +-- No  --> Use an agent with orchestration
```

### 成本与延迟考量

agent 循环中的每一步都涉及一次模型调用。一个 5 步的 agent 工作流意味着至少 5 次模型调用，再加上 tool 执行时间。这些会累加：

- **延迟**：每次模型调用根据模型和 prompt 大小耗时 1-10 秒。一个 5 步的 agent 可能需要 15-30 秒。
- **成本**：每次模型调用都会消耗 tokens。agent 工作流的 token 消耗可能是单次 prompt 的 10-50 倍。
- **可靠性**：步骤越多，出现错误或 hallucinations 的机会越多。

工程原则在哪里都一样：用能解决问题的最简方案。

---

## 真实场景示例

### 客服 agent

**目标：** 端到端处理客户咨询。

**它是怎么工作的：**
1. 客户写道：「我的订单 #12345 在哪里？」
2. Agent 用订单 ID 调用订单查询 tool
3. 拿到状态：「已发货，运单号 XYZ，预计 3 月 20 日送达」
4. Agent 用友好的措辞和运单链接回复
5. 如果客户要求更改收货地址，agent 会调用地址更新 tool

**Level：** 1-2（使用 tool 并带有部分多步逻辑）

### 编码助手 agent

**目标：** 帮助开发者编写、调试与改进代码。

**它是怎么工作的：**
1. 开发者问：「这个函数为什么返回 null？」
2. Agent 读取相关源文件
3. 搜索相关测试
4. 找到 bug（第 42 行缺少 null 检查）
5. 给出附带代码的修复建议
6. 可选地运行测试以验证修复有效

**Level：** 2（多步推理 + 使用 tool）

### 研究 agent

**目标：** 从多个来源收集并综合信息。

**它是怎么工作的：**
1. 用户问：「2026 年服务端渲染的优缺点有哪些？」
2. Agent 搜索近期的文章与基准测试
3. 阅读并从多个来源中提取要点
4. 交叉对照声明，并检查一致性
5. 输出一份带引用的结构化摘要

**Level：** 2（搜索、阅读、跨多步综合）

### DevOps 事件响应 agent

**目标：** 协助诊断并解决生产事件。

**它是怎么工作的：**
1. 告警触发：「service-auth 出现 API latency 飙升」
2. Agent 查询过去 30 分钟的监控仪表盘
3. 检查近期部署是否有变更
4. 检视日志中的错误模式
5. 关联各项发现：「Latency 飙升发生在 deploy #789 之后 5 分钟，该次部署修改了 auth token 缓存的 TTL」
6. 建议回滚并起草一份事件报告

**Level：** 2-3（多步调查，可能需要与其他 agents 协作）

---

## ELI5：什么是 AI agent？

### 把 agent 想象成一个非常能干的实习生

想象你迎来一个第一天上班的全新实习生。他很聪明 — 在班里名列前茅 — 但从未见过你的代码库。

**单独的 LLM 就像这个实习生坐在一个没有电脑的房间里。** 你可以问他问题，他会基于学校里学到的知识给出深思熟虑的回答。但他无法查任何资料，无法运行任何代码，也无法发送任何邮件。他能做的只有说话。

**Agent 就像是这位实习生坐在一张配置齐全的工位前。** 他有笔记本电脑、可以访问内部 tools、有浏览器，还有公司 Slack。这时你问他问题，他可以：

- 不会的就去查
- 试着跑代码来验证想法
- 翻阅文档以确认正确性
- 向同事（另一个 agent）求助
- 带着已核实的答案回到你这里

实习生有时仍会出错 — 毕竟是新人。但他能抓到大部分错误，因为他会检查自己的工作。当他卡住时，他知道要寻求帮助而不是猜测。

**关键洞察：** 实习生的大脑没变。变的是他可以接触到什么、以及他处理工作的方式。这正是 LLM 与 agent 的差别所在。同样的大脑，更多的能力，更好的流程。

---

## Google Cloud 在其中的位置

Google Cloud 通过若干服务为构建与部署 agents 提供基础设施：

- **Vertex AI Agent Engine** — 用于在生产环境构建、部署和管理 AI agents 的托管平台。它处理 orchestration、tool 管理、会话状态和扩缩容，让你可以专注于 agent 逻辑而非基础设施。

- **Gemini Models** — 作为你 agents「大脑」的 language models，提供不同规格以适配不同用例。

- **Agent Development Kit (ADK)** — 一个开源、代码优先的工具包，用来构建 agents，特性包括 multi-agent orchestration、内建 tool 支持，以及到 Agent Engine 的便捷部署。

我们将在课程中持续使用这些工具。现在，知道它们存在即可。

> **了解更多：** [Vertex AI Agent Engine Overview](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview)

---

## 关键要点

1. **AI agent 是一个使用 language model 进行推理、用 tools 行动、并由 orchestration 层管理思考与行动循环的系统。**

2. **LLM = 大脑。Agent = 大脑 + 双手 + 记忆。** 模型负责推理。Tools 负责行动。Orchestration 层负责控制流。

3. **agents 处于一条连续谱上**，从简单的使用 tool 的助手（Level 1）到自我进化的系统（Level 4）。从能解决你问题的最低 Level 开始。

4. **不是所有事情都需要 agent。** 如果一个 prompt 就能搞定，就用一个 prompt。只有当任务确实需要 tools、多步推理或真实世界的行动时，再加入 agent 能力。

5. **核心循环很简单：** 接收目标 -> 思考做什么 -> 使用一个 tool -> 观察结果 -> 重复直到完成。

---

## 下一步是什么？

下一节课我们会深入 agent 的「大脑」 — language model — 看看底层原理。你将学到 LLMs 如何处理信息、不同的推理策略如何影响 agent 表现，以及如何为任务挑选合适的模型。

[Next: Lesson 2 - How Agents Think: LLMs as the Reasoning Engine -->](/02-how-agents-think/)
