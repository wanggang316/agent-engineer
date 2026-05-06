---
title: "Lesson 15: 接下来去哪"
---

## 引言

你做到了。十五课内容覆盖了从「什么是 Agent？」到使用协议与生产基础设施构建多 Agent 系统的方方面面。这是一份扎实的基础。

但基础是用来在其上继续搭建的。这最后一课是你的发射台——根据你的目标量身定制的下一站地图，最值得收藏的资源，以及将塑造 Agent 开发未来的新兴领域。

---

## 你已经学到了什么

让我们快速回顾整门课程。把它当作复习材料，也当作一种方式，回过头看看哪些内容你想重温。

### Part 1：fundamentals

| Lesson | 标题 | 核心思想 |
|---|---|---|
| 01 | What Are AI Agents? | Agent 把推理模型、tools 与 orchestration 循环组合起来，自主追求目标。它们处于一个光谱上，从简单的 tool 调用者到自我演进的系统。 |
| 02 | How Agents Think | LLM 是推理引擎。理解 tokenization、context window 与采样能帮助你预测和控制 Agent 行为。 |
| 03 | Tools - Giving Agents Hands | Tools 让 Agent 与世界交互。良好的 tool 设计——清晰的命名、带类型的参数、有用的描述——直接影响 Agent 的可靠性。 |
| 04 | Agentic Design Patterns | ReAct、reflection、planning、tool-use 等模式为 Agent 解决问题的方式提供了结构。挑可行的最简模式即可。 |
| 05 | Memory and Context | Agent 需要多个层次的记忆——短期（context window）、会话级（对话状态）、长期（持久化存储）——才能处理复杂任务。 |
| 06 | Planning and Reasoning | Agent 通过规划策略把复杂目标拆成步骤。Chain-of-thought、tree-of-thought 与动态重规划各有其适用之处。 |
| 07 | Multi-Agent Systems | 当一个 Agent 处理不了所有事时，多个专门化的 Agent 可以通过层级、点对点、黑板等 orchestration 模式协作。 |
| 08 | Agentic RAG | 超越基础 retrieval，让 Agent 决定要搜索什么、评估结果，并在回答前迭代精炼自己的知识。 |
| 09 | Evaluating and Testing Agents | 衡量 Agent 质量需要任务相关的指标、轨迹分析与系统化的测试用例。评估不是可选项——它就是你判断 Agent 是否可用的方式。 |
| 10 | Guardrails and Safety | Agent 需要边界——输入校验、输出过滤、范围限制、human-in-the-loop 控制——才能保持安全与可信。 |

### Part 2：building and shipping

| Lesson | 标题 | 核心思想 |
|---|---|---|
| 11 | From Prototype to Production | 工作 demo 与生产 Agent 之间的鸿沟，由 CI/CD、监控、优雅降级与运维实践来弥合。 |
| 12 | Getting Started with Vertex AI and ADK | Google Cloud 提供 Vertex AI Agent Engine 用于托管部署、Gemini 模型用于推理，以及 ADK 这个开源工具包用于构建 Agent。 |
| 13 | Building Your First Agent | ADK Agent 需要 name、model 与 instructions。从 LlmAgent 起步，逐步加上 tools，并用 `adk web` 与 `adk eval` 进行测试。 |
| 14 | Agent Protocols - MCP and A2A | MCP 标准化 Agent 与 tool 的通信。A2A 标准化 Agent 与 Agent 的协作。两者一起解决了集成问题。 |

涉及面相当广。如果其中某些总结你觉得陌生，不妨回去重读那一课再继续。

---

## ELI5：学会开车之后去哪？

想想学开车这件事。你上完课（fundamentals）、通过笔试（理解理论）、做完路考（构建第一个 Agent）。现在你能开车了。

但「会开车」打开了一个充满选择的世界。有人想每天开车上班（构建实用的 Agent）。有人想成为机修工，深入了解发动机（钻研理论）。有人想横跨全国（大规模部署）。还有人想参加比赛（探索 Agent 的边界）。

这一课就是你的公路地图。它不告诉你该去哪里——它把所有道路展示给你，并帮你选出与目的地匹配的那一条。

---

## 推荐学习路径

不是每个人下一步都一样。下面是基于常见目标的四条路径。

### 路径 1：「我想构建我的第一个 Agent」

你已读完理论，想动手实操。

**从这里开始：**
1. 完整跟着 [ADK Quickstart](https://google.github.io/adk-docs/get-started/quickstart/) 走一遍。构建示例 Agent，本地运行，确保一切都跑得通。
2. 修改 quickstart Agent。改动 system 指令。加一个自定义 tool。把它弄坏，再修好，理解各部件如何协同。
3. 克隆 [Agent Starter Pack](https://github.com/GoogleCloudPlatform/agent-starter-pack)，获得已配置好 CI/CD、监控与部署的生产级模板。
4. 挑一个小而真实的问题，构建 Agent 去解决。控制好范围——一个 Agent、两到三个 tools、一个清晰的成功指标。

**重温：** Lesson 3（Tools）、Lesson 13（Building Your First Agent）

### 路径 2：「我想改进现有的 Agent」

你已有 Agent，但表现还不够好。

**从这里开始：**
1. 回到 Lesson 9，为你的 Agent 建立一套评估套件。无法度量的东西就无法改进。
2. 阅读 Google Cloud 关于 "Agent Quality" 的白皮书，了解系统化提升 Agent 可靠性与准确性的方法。
3. 用 Lesson 13 的指南审视你的 system 指令。模糊的指令是糟糕行为最常见的来源。
4. 检查你的 tool 设计。tool 名称是否清晰？描述是否准确？错误情形是否处理过？
5. 如果还没有 guardrails（Lesson 10），把它加上。可靠性与安全是相辅相成的。

**重温：** Lesson 9（Evaluation）、Lesson 10（Guardrails）、Lesson 4（Design Patterns）

### 路径 3：「我想大规模部署 Agent」

你已有可用的 Agent，需要把它运行在生产环境。

**从这里开始：**
1. 重读 Lesson 11（From Prototype to Production），重点关注运维问题：监控、日志、错误处理与回滚。
2. 探索 [Vertex AI Agent Engine](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview)——它能托管部署、处理扩缩容、会话管理与基础设施。
3. 学习 Google Cloud 关于 "From Prototype to Production" 的白皮书，详细了解部署生命周期。
4. 为你的 Agent 配置 CI/CD。把 prompt 改动当作代码改动一样严肃对待——做版本管理、做评审、做测试。
5. 实现完善的可观测性。你需要看到 Agent 在生产中到底在做什么，而不只是它有没有返回响应。

**重温：** Lesson 11（Production）、Lesson 12（Vertex AI 与 ADK）

### 路径 4：「我想更深入地理解理论」

你想要研究级的理解。

**从这里开始：**
1. 阅读下面列出的 Google Cloud 白皮书。它们对本课程涉及的每一个主题都有深入的技术阐述。
2. 跟读那些白皮书所引用的关于规划、推理与多 Agent 协调的研究论文。
3. 在高级模式上做实验——多 Agent 系统（Lesson 7）、agentic RAG（Lesson 8）、基于循环的精炼 Agent。
4. 直接研究 MCP 与 A2A 的协议规范，从协议层面深入理解 Agent 通信的工作原理。

**重温：** Lesson 2（How Agents Think）、Lesson 6（Planning）、Lesson 7（Multi-Agent Systems）

---

## Google Cloud 资源

### Codelabs

可在浏览器中完成的实战引导式教程：

- **Google Cloud AI/ML Codelabs：** [https://codelabs.developers.google.com/?cat=AI](https://codelabs.developers.google.com/?cat=AI) —— 浏览完整的 AI codelabs 目录，包含 Agent 相关教程、Gemini API 指南与 Vertex AI 实操。

### 文档

构建时的主要参考：

| 资源 | 涵盖内容 | 链接 |
|---|---|---|
| Vertex AI Docs | Agent Engine、模型服务、评估，以及完整的 Vertex AI 平台 | [cloud.google.com/vertex-ai/docs](https://cloud.google.com/vertex-ai/docs) |
| ADK Docs | Agent Development Kit —— Agent 的构建、测试与部署 | [google.github.io/adk-docs](https://google.github.io/adk-docs/) |
| Gemini API Docs | 模型能力、function calling、上下文缓存与 API 参考 | [ai.google.dev/docs](https://ai.google.dev/docs) |
| Google Cloud AI | Google Cloud 上所有 AI 服务的概览 | [cloud.google.com/ai](https://cloud.google.com/ai) |

### 模板与起步项目

不必从零开始：

- **Agent Starter Pack：** [https://github.com/GoogleCloudPlatform/agent-starter-pack](https://github.com/GoogleCloudPlatform/agent-starter-pack) —— 在 Google Cloud 上构建并部署 Agent 的生产级模板。包含 CI/CD 流水线、监控配置、评估框架与部署配置。这是从想法到生产的最快路径。

### 社区

与其他 Agent 构建者建立联系：

- **Google Cloud Community 论坛** —— 提问，分享你正在构建的东西
- **Stack Overflow** —— 用 `google-cloud-vertex-ai` 或 `google-adk` 标签提问
- **GitHub Issues** —— 在 ADK 仓库提交 bug 与功能请求
- **Google Cloud Discord** —— 与其他开发者实时交流

当团队里只有你在做 Agent 时，构建过程会让人感到孤单。社区是你能找到那些遇到过同样问题的人的地方。不要害怕提问——整个生态还很年轻，大家都还在学习。

### 教程与样例

除了官方文档，可关注：

- **ADK 仓库中的样例 Agent** —— ADK GitHub 仓库提供了示例 Agent，演示多 tool Agent、顺序工作流与 Agent 团队等常见模式
- **Google Cloud 博客文章** —— Google Cloud 博客经常发布关于 Agent 架构与部署模式的实操文章
- **大会演讲** —— Google I/O 与 Google Cloud Next 上关于 Agent 与 AI 的会议通常会录制并发布

---

## Google Cloud 关于 Agent 的关键白皮书

Google Cloud 发布了一系列深入的白皮书，覆盖了 Agent 领域的方方面面。它们比我们的课时更深入，无论作为实践者还是决策者，都是优秀的参考。

| 白皮书 | 涵盖内容 |
|---|---|
| **Introduction to Agents** | 基础概念——Agent 是什么、核心组件、认知架构与 Agent 能力光谱 |
| **Agent Quality** | 度量与改进 Agent 表现的系统化方法——评估方法论、指标与质量保证策略 |
| **Agent Tools and Interoperability with MCP** | tool 设计、Model Context Protocol 与构建可互操作 Agent-tool 生态的深度剖析 |
| **Context Engineering: Sessions and Memory** | Agent 如何管理 context——会话状态、记忆架构、context window 优化与长期知识保留 |
| **From Prototype to Production** | 从 demo 到部署的完整生命周期——基础设施、CI/CD、监控、扩缩容与运维最佳实践 |
| **Agents Companion** | 一份实用参考指南，把所有白皮书串联起来，并给出可操作的指引与决策框架 |

无论你是否在 Google Cloud 上构建，这些白皮书都很有价值。它们描述的概念与模式具有广泛的适用性。

---

## 值得探索的开源项目

### Google 的项目

| 项目 | 是什么 | 链接 |
|---|---|---|
| **ADK (Agent Development Kit)** | Google 的开源、代码优先工具包，用于构建、评估与部署 Agent | [github.com/google/adk-python](https://github.com/google/adk-python) |
| **Agent Starter Pack** | Google Cloud 上 Agent 项目的生产级模板 | [github.com/GoogleCloudPlatform/agent-starter-pack](https://github.com/GoogleCloudPlatform/agent-starter-pack) |

### 社区框架

Agent 生态远不止单一供应商。以下社区框架提供了不同的思路，值得了解：

| 框架 | 思路 | 最佳场景 |
|---|---|---|
| **LangChain** | 构建 LLM 应用的模块化组件，含 chain 与 agent | 快速原型开发，集成生态广泛 |
| **LangGraph** | 在 LangChain 之上构建的基于图的 Agent orchestration | 复杂多步工作流、有状态 Agent |
| **CrewAI** | 角色化的多 Agent 协作框架 | 由专门 Agent 组成、协同工作的团队 |

每个框架都做出不同的取舍。ADK 强调 Google Cloud 集成、代码优先与生产部署。LangChain 强调集成的广度。CrewAI 强调多 Agent 团队的隐喻。没有所谓「最好」的框架——正确的选择取决于你的需求、现有基础设施与团队偏好。

**关于框架选择的提示：** 不要花上几周时间评估框架。挑一个适合你生态的，先用它构建点东西，确有需要再切换。概念在框架间是可迁移的。在 ADK 学到的关于 tool 设计的内容同样适用于 LangChain。在某个框架学到的关于评估的内容适用于所有框架。框架是交通工具，不是目的地。

### 协议实现

- **MCP Specification：** [modelcontextprotocol.io](https://modelcontextprotocol.io) —— 协议规范与参考实现
- **A2A Protocol：** [a2a-protocol.org](https://a2a-protocol.org/latest/) —— 规范与文档

---

## 值得关注的新兴领域

Agent 领域发展迅速。以下是几个在不远的将来可能产生重大影响的方向。

### 计算机操作 Agent

能够看见并与图形界面交互的 Agent——点击按钮、填写表单、浏览网站——就像人类用户一样。这为那些没有 API、只有可视界面的应用打开了自动化的大门。

**为何重要：** 大多数企业软件是为人类通过 GUI 交互而设计的。计算机操作 Agent 可以自动化此前在不构建定制集成的情况下无法自动化的工作流。

**值得关注的方向：** 视觉语言模型的进步、GUI 交互的标准化框架，以及控制桌面与浏览器环境的 Agent 的安全模型。

### 自我演进 Agent

能从自身过往表现中学习的 Agent——分析哪些奏效、哪些失败、原因是什么。它们在没有人工介入的情况下持续更新策略、精炼 prompt、改进 tool 使用。

**为何重要：** 今天，改进一个 Agent 需要人工审阅日志、识别问题并做出修改。自我演进 Agent 可能大幅减少这种维护负担。

**值得关注的方向：** 更好的 Agent 自我反思方式、自动化 prompt 优化，以及让 Agent 在不损坏系统的前提下尝试新方法的安全探索策略。

### Agentic 商务

能够发现产品与服务、协商条件、完成购买并代表用户管理交易的 Agent。想象一下，旅行 Agent 不只规划行程，还能真的帮你下单——比价、用券、付款全包。

**为何重要：** 这把 Agent 从「信息助手」推进到经济活动中的「行动者」。其中的信任与安全意味深远。

**值得关注的方向：** Agent 与商家通信的标准、支付授权框架，以及面向 AI 中介交易的消费者保护模型。

### 生产环境中的持续学习

无需重新部署，Agent 就能基于生产中的交互更新其知识与能力。这包括学习新事实、适应不断变化的用户需求，以及融入反馈回路。

**为何重要：** 今天，更新 Agent 的知识需要重新部署带新指令的版本，或更新知识库。持续学习有可能让 Agent 自动保持最新。

**值得关注的方向：** 安全的在线学习技术、对学到的信息的质量控制，以及把稳定能力与演进知识分离的架构。

### 多模态 Agent

除文本之外，还能处理图像、音频、视频与文档的 Agent。一个多模态 Agent 可能在同一工作流中分析报错截图、听客服电话录音、处理 PDF 发票。

**为何重要：** 真实世界并不只有文本。许多业务流程都涉及文档、图像与录音。多模态 Agent 能处理这类工作流，而不必让人工去转录或描述非文本内容。

**值得关注的方向：** 视觉语言模型的进步、在 Agent 协议间传递多模态内容的标准化方式，以及原生支持多模态 tool 输入与输出的框架。

### Agent 的可观测性与调试

随着 Agent 变得更复杂，理解它们在做什么、为何这么做也变得更困难。新的工具与实践正在涌现，用于追踪 Agent 决策、可视化多步执行，以及诊断生产环境中的失败。

**为何重要：** 看不到的东西就无法修复。今天，调试 Agent 往往意味着逐行翻日志。更好的可观测性工具会让 Agent 开发体验更接近现代软件开发——拥有合适的调试器与剖析器。

**值得关注的方向：** 专门的 Agent tracing 平台、面向 Agent 执行的标准化 telemetry 格式，以及多 Agent 交互的可视化工具。

---

## 第一个真实项目的常见模式

在你不再做教程之后，下面这些实用项目模式很适合作为第一个真实项目：

### 内部知识 Agent

**做什么：** 回答关于团队文档、运行手册或代码库的问题。

**为何适合作为第一个项目：** 范围清晰、数据可获取，并且容易衡量是否成功（回答正确吗？）。它把 RAG 与 tool 使用结合起来，立刻就能给团队带来价值。

**所需 tools：** 一个文档检索 tool（向量搜索或访问你文档的 API），可选地用 Google Search 作为兜底。

### 分诊 Agent

**做什么：** 阅读到来的事项（bug 报告、客服工单、pull requests），并对其进行分类、优先级排序或路由。

**为何适合作为第一个项目：** 分类任务正契合 LLM 的强项。输出是结构化的、易于评估。而大多数组织里事项的体量也让它真有用武之地。

**所需 tools：** 从问题跟踪或工单系统读取事项的 API tool，以及更新标签或分配人的 tool。

### 每日摘要 Agent

**做什么：** 从多个来源（邮件、Slack、日历、项目管理工具）汇集信息，并产生摘要。

**为何适合作为第一个项目：** 它锻炼多个 tool 与基本的整合能力，而不需要复杂的多步推理。输出对人类来说易于审阅。

**所需 tools：** 为每个数据源提供 MCP 服务器或自定义 tool，以及输出格式化的 tool。

### 代码审查助手

**做什么：** 审查 pull requests，关注常见问题——缺少测试、风格问题、潜在 bug、命名不清。

**为何适合作为第一个项目：** 开发者可以立刻用自己的判断验证输出。它是低风险的（建议而非自动改动）且高价值。

**所需 tools：** 从源码控制系统读取 PR diff 的 tool，以及可选地发布审查评论的 tool。

---

## 下一个 Agent 项目的清单

启动下一次构建时，把这个当作规划工具：

### 开始之前

- [ ] 明确目标——Agent 应该达成什么？
- [ ] 验证 Agent 是合适的方案（参见 Lesson 1 的决策流程图）
- [ ] 识别 Agent 所需的 tools 与数据源
- [ ] 选择与任务复杂度匹配的模型
- [ ] 搭好开发环境（ADK、API 访问、凭据）

### 开发过程中

- [ ] 撰写详细的 system 指令（角色、范围、边界、示例）
- [ ] 在接入 Agent 之前，单独构建并测试 tool
- [ ] 早期就建立评估用例——至少先有 5-10 个
- [ ] 部署到任何地方之前，先用 `adk web` 在本地测试
- [ ] 加上保障安全与可靠性的 guardrails

### 部署之前

- [ ] 跑一遍完整的评估套件并修复失败项
- [ ] 配置好监控与日志
- [ ] 定义回滚流程
- [ ] 规划错误处理与优雅降级
- [ ] 审查安全性——鉴权、授权、数据处理

### 部署之后

- [ ] 监控 Agent 的性能指标（延迟、成功率、成本）
- [ ] 定期审阅日志，留意异常行为
- [ ] 收集用户反馈，并把它转化为评估用例
- [ ] 基于生产数据迭代指令与 tools
- [ ] 让依赖（模型、tools、MCP 服务器）保持最新

---

## 一份可收藏的资源清单

把这些链接放在手边。它们是你会反复回去查阅的主要参考：

**学习与构建：**
- ADK Documentation：[https://google.github.io/adk-docs/](https://google.github.io/adk-docs/)
- ADK Quickstart：[https://google.github.io/adk-docs/get-started/quickstart/](https://google.github.io/adk-docs/get-started/quickstart/)
- Agent Starter Pack：[https://github.com/GoogleCloudPlatform/agent-starter-pack](https://github.com/GoogleCloudPlatform/agent-starter-pack)
- Gemini API Docs：[https://ai.google.dev/docs](https://ai.google.dev/docs)

**Google Cloud Platform：**
- Vertex AI Docs：[https://cloud.google.com/vertex-ai/docs](https://cloud.google.com/vertex-ai/docs)
- Agent Engine：[https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview)
- AI/ML Codelabs：[https://codelabs.developers.google.com/?cat=AI](https://codelabs.developers.google.com/?cat=AI)

**协议：**
- MCP Specification：[https://modelcontextprotocol.io](https://modelcontextprotocol.io)
- A2A Protocol：[https://a2a-protocol.org/latest/](https://a2a-protocol.org/latest/)
- MCP Tools in ADK：[https://google.github.io/adk-docs/tools/mcp-tools/](https://google.github.io/adk-docs/tools/mcp-tools/)

**开源：**
- ADK Python：[https://github.com/google/adk-python](https://github.com/google/adk-python)

---

## 保持与时俱进

Agent 生态变化很快。下面是一种在不被信息淹没的前提下保持更新的实用策略。

### 关注什么

- **ADK 发布说明：** 关注 [ADK GitHub repository](https://github.com/google/adk-python) 中的新版本。大版本通常会引入新的 Agent 类型、tool 集成或部署选项。
- **Vertex AI 更新日志：** Google Cloud 经常为 Agent Engine、模型服务与评估推出新功能。Vertex AI 文档中有更新日志。
- **模型发布：** 新的 Gemini 模型版本可能解锁此前不可能的能力——更好的推理、更长的 context window、更优的 function calling。用你已有的评估套件测试新模型，看是否能带来提升。
- **协议更新：** MCP 与 A2A 都在积极演进。关注新原语、安全改进与生态增长。

### 暂时可以忽略什么

不是每一个新进展都值得你关注。可以跳过那些：

- 解决你目前还没有的问题
- 需要重构一个原本运转良好的系统
- 只是发布说明，没有可用的实现
- 只有跑分结果，没有实际应用

把注意力放在今天就能帮你构建更好 Agent 的事情上。其余的留待以后。

---

## 最后的话

学习 Agent 开发的最佳方式就是去构建 Agent。从小处着手。挑一个你真有的问题——也许是总结早晨的邮件，或在多个内部工具之间查找信息，或为 bug 报告做分诊。构建一个简单的 Agent 去解决它。一个模型、一两个 tools、清晰的指令。

可用之后，再迭代。加一个 tool。改进指令。写评估用例。接一个 MCP 服务器。试一种多 Agent 模式。每次迭代都会教给你文档教不了的东西。

这个领域演进得很快。具备更强推理能力的新模型不断推出。新的 tools 与协议不断涌现。随着越来越多团队把 Agent 投入生产，最佳实践也在演变。你在本课程中学到的基础——Agent 循环、tool 设计、记忆管理、评估、安全——即使具体内容变化，依然会保持适用。但具体的 API、模型版本与框架特性会演进。

把上面的资源清单收藏起来，并经常回来看看。关注 ADK 与 Vertex AI 的更新日志。新的白皮书发布时去读它们。加入社区论坛，看看其他人在构建什么。

最重要的是：交付点东西。「我理解了 Agent」与「我已经构建并部署了一个 Agent」之间的鸿沟，正是真正的学习发生的地方。

祝你构建顺利。

---

## 课程完结

恭喜完成 AI Agents 101。你已从理解 Agent 是什么，走到了知道如何用业界标准 tools 与协议构建、测试、部署、连接 Agent。

[Back to Course Overview](/)
