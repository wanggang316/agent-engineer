---
title: Agent Engineer
description: 面向软件工程师的 AI agents 课程，介绍如何使用 Google Cloud AI 构建 agents。
template: doc
---

学习 AI agents 的基础，以及如何使用 Google Cloud AI 构建 agents。

## 适合谁阅读？

希望理解 AI agents 是什么、如何工作、以及如何构建它们的软件工程师。无需任何 AI/ML 经验，只需保持好奇心并具备一定的 Python 知识。

## 课程概览

本课程分为三部分：

**Part 1：基础（101）** — 理解 AI agents 背后的核心概念。这些课时与具体平台无关，重点在于建立心智模型。

**Part 2：构建与交付（201）** — 使用 Google Cloud AI、Vertex AI 和 Agent Development Kit (ADK) 把基础落到实处。

**Part 3：专题深入（301）** — 围绕真实场景中开发 agent 时关键的话题做更深入的探讨。

## 课时

### Part 1：基础

| # | 课时 | 你将学到 |
|---|--------|-------------------|
| 01 | [What are AI agents?](/01-what-are-ai-agents/) | 整体概览 — agents 是什么、为什么重要、何时使用 |
| 02 | [How agents think](/02-how-agents-think/) | LLMs 作为推理引擎 — 模型如何规划、决策与生成 |
| 03 | [Tools - giving agents hands](/03-tools-giving-agents-hands/) | function calling、tool 设计，以及让 agents 与真实世界连接 |
| 04 | [Agentic design patterns](/04-agentic-design-patterns/) | ReAct、reflection、planning 等核心模式 |
| 05 | [Memory and context](/05-memory-and-context/) | agents 如何记忆 — 会话、context window 与长期记忆 |
| 06 | [Planning and reasoning](/06-planning-and-reasoning/) | agents 如何拆解复杂任务并做决策 |
| 07 | [Multi-agent systems](/07-multi-agent-systems/) | 一个 Agent 不够用时 — 协作、委派与团队协作 |
| 08 | [Agentic RAG](/08-agentic-rag/) | 超越基础检索 — 能够搜索、评估并精炼结果的 agents |
| 09 | [Evaluating and testing agents](/09-evaluating-and-testing-agents/) | 如何判断你的 agent 是否真的好用 — 指标、evals 与可观测性 |
| 10 | [Guardrails and safety](/10-guardrails-and-safety/) | 让 agents 保持可信 — 安全、alignment 与负责任的 AI |

### Part 2：构建与交付

| # | 课时 | 你将学到 |
|---|--------|-------------------|
| 11 | [From prototype to production](/11-from-prototype-to-production/) | 从演示到上线 — CI/CD、上线与运维 |
| 12 | [Getting started with Vertex AI and ADK](/12-getting-started-with-vertex-and-adk/) | 面向 agents 的 Google Cloud AI 技术栈 — 都有什么、如何组合 |
| 13 | [Building your first agent](/13-building-your-first-agent/) | 实战 — 使用 ADK 一步一步构建一个可运行的 agent |
| 14 | [Agent protocols - MCP and A2A](/14-agent-protocols-mcp-and-a2a/) | agents 如何通过开放标准与 tools 以及彼此通信 |

### Part 3：专题深入

| # | 课时 | 你将学到 |
|---|--------|-------------------|
| 15 | [AGENTS.md](/15-agents-md/) | 用一个标准配置文件，为 AI 编码 agents 提供项目上下文 |
| 16 | [MCP deep dive](/16-mcp-deep-dive/) | MCP 的底层原理、MCP 与 CLI tools 的对比，以及安全考量 |
| 17 | [Agent skills](/17-agent-skills/) | 把可复用的领域专业知识打包成便携的技能模块 |
| 18 | [Orchestrators](/18-orchestrators/) | 管理 agent 的控制流 — 模式、框架与最佳实践 |
| 19 | [Where to go from here](/19-where-to-go-from-here/) | 资源、codelabs、社区与下一步 |

## 如何使用本课程

- **按顺序阅读**：如果你刚接触 agents，每节课都建立在前一节的基础上。
- **按需跳读**：如果已经了解基础，每节课的内容也足够独立，可以单独阅读。
- **跟随链接**：跳转到官方文档、codelabs 与教程进行实战练习。我们刻意链接到持续维护的资料，而不是复制那些容易过时的 API 文档或代码样例。

## 编写理念

本课程遵循以下几条原则：

- **类比优先。** 在深入技术细节之前，先用日常类比解释复杂概念。
- **基础重于框架。** 先理解「为什么」，再学「怎么做」。框架在变，但核心思想会留下来。
- **链接，而非复制。** 对于 API references、代码样例与配置说明，我们会直接指向 Google Cloud 的官方文档和 codelabs。这让我们的内容聚焦于概念，并保证你看到的是最新信息。
- **诚实面对取舍。** 任何架构选择都有代价。我们会尽量呈现两面。

## 前置条件

- 基本的 Python 知识（函数、类、HTTP 请求）
- 一个 Google Cloud 账号（[提供免费试用](https://cloud.google.com/free)）
- 熟悉 REST APIs 与 JSON

## 补充资源

- [Google Cloud AI documentation](https://cloud.google.com/ai)
- [Vertex AI documentation](https://cloud.google.com/vertex-ai/docs)
- [Agent Development Kit (ADK) documentation](https://google.github.io/adk-docs/)
- [Google Cloud AI codelabs](https://codelabs.developers.google.com/?cat=AI)
- [Gemini API documentation](https://ai.google.dev/docs)

## 参与贡献

发现错别字？有改进建议？欢迎提交 PRs 与 issues。详见 [CONTRIBUTING.md](./CONTRIBUTING.md)。

## License

本项目采用 Apache 2.0 License — 详见 [LICENSE](./LICENSE) 文件。
