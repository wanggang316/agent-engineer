---
title: "Lesson 12: Vertex AI 与 ADK 入门"
---

## 引言

在前 11 课里，我们打下了 Agent 工作机制的扎实基础 —— 推理、tools、记忆、规划、多 Agent 系统、RAG、评估、安全和生产运维。所有这些概念都与平台无关。

现在我们转向实战。本课把那些概念映射到 Google Cloud 上具体的工具与服务，目标是让你清晰看到都有什么、各部分如何组合，以及在构建特定类型的 Agent 时该选哪个服务。

### ELI5：把 Google Cloud AI 技术栈想象成一个工坊

想象你要建一个木工工坊。你需要原料（木材、金属）、电动工具（锯、钻）、工作台（稳固的工作面）、安全装备（护目镜、手套），还有一个展示或售卖成品的空间。

Google Cloud AI 技术栈也类似：

- **Gemini 模型** 是你的原料 —— 驱动一切的智能
- **ADK（Agent Development Kit）** 是你的电动工具 —— 用来构建 Agent 的框架
- **Vertex AI 平台** 是你的工作台 —— 提供模型托管、评估、部署的基础设施
- **Agent Engine** 是托管的展厅 —— 在生产中运行 Agent，无需你管服务器
- **Model Armor** 是你的安全装备 —— guardrails 与内容过滤
- **Vertex AI Search 与 RAG Engine** 是你的资料库 —— 让 Agent 能访问你的数据

这些组件可以独立使用，也可以组合使用。不是每个项目都需要每一件工具。

> **关键要点：** Google Cloud 为构建 Agent 提供了从模型到托管运行时的完整技术栈。理解每一块的职责，能帮你为每个任务挑对工具。

---

## Google Cloud 上面向 Agent 的 AI 技术栈

下面是主要组件及其相互关系的全景图：

```
+------------------------------------------------------------------+
|                        Your Agent Application                     |
+------------------------------------------------------------------+
|                                                                    |
|  +--------------------+    +----------------------------------+   |
|  |  Agent Development |    |  Agent Engine                    |   |
|  |  Kit (ADK)         |    |  (Managed Runtime)               |   |
|  |                    |    |                                  |   |
|  |  - Build agents    |    |  - Deploy and run agents         |   |
|  |  - Define tools    |--->|  - Session management            |   |
|  |  - Orchestration   |    |  - Scaling and monitoring        |   |
|  +--------------------+    +----------------------------------+   |
|           |                            |                          |
|           v                            v                          |
|  +----------------------------------------------------+          |
|  |              Vertex AI Platform                     |          |
|  |                                                     |          |
|  |  - Model hosting (Gemini, partner models)           |          |
|  |  - Evaluation tools                                 |          |
|  |  - Context caching                                  |          |
|  |  - Grounding with Google Search                     |          |
|  +----------------------------------------------------+          |
|           |                            |                          |
|           v                            v                          |
|  +----------------------+    +------------------------+           |
|  | Vertex AI Search &   |    |  Model Armor           |           |
|  | RAG Engine           |    |  (Safety & Guardrails) |           |
|  +----------------------+    +------------------------+           |
|                                                                    |
+------------------------------------------------------------------+
|                     Gemini Models                                  |
|  Pro (complex reasoning) | Flash (balanced) | Flash-Lite (volume) |
+------------------------------------------------------------------+
```

下面逐个看每一块。

---

## Gemini 模型

Gemini 是 Google 的多模态 AI 模型家族。在 Agent 开发中，你主要会接触三个等级：

| Model | Best For | Characteristics |
|-------|----------|----------------|
| **Gemini Pro** | Complex reasoning, multi-step planning, nuanced decisions | Highest capability, higher latency, higher cost |
| **Gemini Flash** | Balanced tasks - tool use, summarization, conversation | Good capability, fast, moderate cost |
| **Gemini Flash-Lite** | High-volume, simpler tasks - classification, routing, extraction | Fast, lowest cost, good for high-throughput use cases |

### 选择合适的模型

把模型选择想象成为一次出行选交通工具：

- **Flash-Lite** 是自行车 —— 又快又便宜，适合短途（简单分类、意图识别、基础抽取）
- **Flash** 是汽车 —— 多面手，适合大多数行程（一般 Agent 任务、tool use、RAG、对话）
- **Pro** 是卡车 —— 强大，能拉重活（复杂多步推理、长文档、困难规划）

大多数生产 Agent 通过 **模型路由**（见 Lesson 11）使用多个模型等级：简单步骤用 Flash-Lite，核心逻辑用 Flash，只有任务确实需要时才上 Pro。

### 多模态能力

Gemini 模型可以处理文本、图像、音频和视频。这意味着你的 Agent 可以：

- 分析用户上传的图片（产品照片、截图、文件）
- 处理音频输入（语音命令、会议录音）
- 理解视频内容（教程、演示）
- 原生处理 PDF 等文档格式

相比纯文本模型，这是一项显著优势，让你能构建以更丰富方式与真实世界交互的 Agent。

模型详情与能力请参见 [Gemini 模型文档](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models)。

---

## Vertex AI 平台

Vertex AI 是 Google Cloud 的机器学习平台。对 Agent 开发者来说，最相关的能力包括：

### 模型托管与 API 访问

Vertex AI 提供 Gemini 模型以及合作与开源模型的 API 访问。你能拿到：

- **托管 endpoint** —— 无需管理基础设施
- **context caching** —— 缓存长 system prompt 或文档，在重复调用时降低成本与延迟
- **基于 Google Search 的 grounding** —— 让模型用网页搜索结果验证并补充其知识
- **批处理预测** —— 高效处理大批量请求

### 评估工具

Vertex AI 包含与 Lesson 9 中所讨论一致的评估能力：

- **AutoSxS（Auto Side-by-Side）** —— 自动比较两个模型版本
- **Pointwise evaluation** —— 在质量维度上对单条回复打分
- **Custom metrics** —— 定义你自己的评估标准
- **Bulk evaluation** —— 在大数据集上批量跑 evals

这些工具与你的 CI/CD 流水线集成，用于 evaluation-gated 部署（见 Lesson 11）。

### Model Garden

Vertex AI Model Garden 提供 Gemini 之外大量模型的访问入口 —— 包括开源模型与合作伙伴的模型。当你需要针对特定任务的专用模型，或想比较不同选项时，这很有用。

平台总览请参见 [Vertex AI 文档](https://cloud.google.com/vertex-ai/docs)。

---

## Agent Development Kit (ADK)

ADK 是 Google 推出的开源、code-first 的 Agent 构建框架。如果说 Vertex AI 是工作台，ADK 就是你用来动手做事的电动工具集合。

### 关键特性

| Feature | Detail |
|---------|--------|
| **Open source** | Available on GitHub, MIT licensed |
| **Multi-language** | Python, TypeScript/JavaScript, Go, Java |
| **Model-agnostic** | Works with Gemini, but also supports other LLMs |
| **Deployment-agnostic** | Run locally, on Agent Engine, on Cloud Run, on any container platform |
| **Opinionated but flexible** | Provides structure without locking you in |

### 为什么需要框架？

你完全可以直接调用 Gemini API 来构建 Agent —— 自己写 tool calling 循环、维护对话状态、处理 orchestration。ADK 让你不必反复重造这些常见模式：

- tool 注册与执行
- 对话状态管理
- 多轮 orchestration 循环
- 多 Agent 协作
- 会话与 memory 管理
- 用于 guardrails 与日志的回调钩子

把它类比成裸写 HTTP handler 与使用 Web 框架的差别。两者都能跑，但框架替你处理样板代码，让你能聚焦于 Agent 自身的独特逻辑。

### ADK 的核心概念

ADK 将 Agent 分为三类：

#### 1. LLM agents

由语言模型驱动、能进行推理、规划并决定调用哪些 tool 的 Agent。这是最常见的类型，对应 Lesson 4 中讲过的 ReAct 风格 Agent。

```python
from google.adk.agents import Agent
from google.adk.tools import FunctionTool

# Define a tool
def get_weather(city: str) -> str:
    """Get the current weather for a city."""
    # In practice, this would call a weather API
    return f"The weather in {city} is sunny, 72F."

# Create an agent
weather_agent = Agent(
    name="weather_agent",
    model="gemini-2.0-flash",
    instruction="You are a helpful weather assistant. Use the get_weather "
                "tool to answer questions about weather conditions.",
    tools=[get_weather],
)
```

#### 2. workflow agents

这类 Agent 按预定义的 orchestration 模式执行，而非由 LLM 决定流程。ADK 内置三种 workflow 类型：

| Workflow Type | How It Works | Use When |
|--------------|-------------|----------|
| **SequentialAgent** | Runs sub-agents one after another in a fixed order | Steps must happen in sequence (e.g., validate -> process -> respond) |
| **ParallelAgent** | Runs sub-agents simultaneously | Steps are independent and can happen at the same time (e.g., search multiple sources) |
| **LoopAgent** | Runs a sub-agent repeatedly until a condition is met | Iterative refinement (e.g., generate -> evaluate -> improve) |

```python
from google.adk.agents import SequentialAgent

# A pipeline that validates input, processes it, and formats the response
pipeline = SequentialAgent(
    name="order_pipeline",
    sub_agents=[
        input_validator_agent,
        order_processor_agent,
        response_formatter_agent,
    ],
)
```

Workflow agent 直接对应 Lesson 4 中讲过的 agentic 设计模式。Sequential 对应 pipeline 模式；Parallel 对应 fan-out/fan-in；Loop 对应 reflection 与迭代精化。

#### 3. custom agents

对于内置类型无法覆盖的 orchestration 模式，你可以继承基础 Agent 类，实现自定义控制流来构建自定义 Agent。

### ADK tools 生态

ADK 的最大优势之一是 tools 生态。tools 是 Agent 与外部世界交互的途径（见 Lesson 3），ADK 提供多种定义方式：

| Tool Type | What It Is | Example |
|-----------|-----------|---------|
| **Function Tools** | Plain Python/JS functions decorated as tools | A function that queries your database |
| **MCP Tools** | Tools from Model Context Protocol servers | Connect to any MCP-compatible tool server |
| **OpenAPI Tools** | Auto-generated from OpenAPI/Swagger specs | Wrap any REST API as agent tools |
| **Built-in Tools** | Pre-built integrations provided by ADK | Google Search, code execution, RAG |

ADK 包含 60 多个内置 tool 集成，覆盖常见需求：

- Google Search 与网页浏览
- 代码执行（沙箱）
- 文件操作
- 数据库查询
- API 调用
- Google Workspace（Gmail、Calendar、Drive）

```python
from google.adk.tools import FunctionTool

# A simple function tool
def search_products(query: str, max_results: int = 5) -> list[dict]:
    """Search the product catalog.

    Args:
        query: The search query string.
        max_results: Maximum number of results to return.

    Returns:
        A list of matching products with name, price, and description.
    """
    # Your implementation here
    return product_database.search(query, limit=max_results)

# ADK automatically generates the tool schema from the function signature
# and docstring, so the LLM knows how to call it correctly.
```

### ADK Skills

skills 是 ADK 较新的概念，把 Agent 能力打包成自包含、可复用的单元。可以把它们想象成 Agent 的「插件」。

skills 按复杂度分为三个等级：

| Level | What It Includes | Example |
|-------|-----------------|---------|
| **L1 - Metadata** | Name, description, and tags that help the agent understand when to use the skill | "This skill handles flight booking" |
| **L2 - Instructions** | Detailed instructions for how the agent should use the skill | Step-by-step guide for the booking flow |
| **L3 - Resources** | Tools, data sources, and sub-agents that the skill needs | Flight search API tool, airline database |

skills 让在团队和项目之间分享和组合 Agent 能力变得更容易。

完整 ADK 文档请参见 [ADK 文档站](https://google.github.io/adk-docs/)。

---

## Agent Engine

Agent Engine 是 Google Cloud 上用于部署与运行 Agent 的托管运行时服务。如果说 ADK 是构建 Agent 的方式，Agent Engine 就是在生产中运行 Agent、不必你管基础设施的方式。

### Agent Engine 提供什么

| Capability | What It Does |
|-----------|-------------|
| **Managed hosting** | Run your agent without provisioning servers or containers |
| **Session management** | Built-in conversation state persistence |
| **Scaling** | Automatic scaling based on traffic |
| **Monitoring** | Integration with Cloud Monitoring and Cloud Logging |
| **Security** | IAM-based access control, VPC Service Controls support |

### Agent Engine 与其他部署选项的取舍

| Deployment Option | Best For |
|-------------------|----------|
| **Agent Engine** | Production agents where you want managed infrastructure and do not want to handle scaling, session management, or deployment yourself |
| **Cloud Run** | Agents that need custom runtime environments, specific dependencies, or more control over the container |
| **GKE (Kubernetes)** | Agents that are part of a larger microservices architecture already running on Kubernetes |
| **Local / Self-hosted** | Development, testing, or when you cannot use cloud services |

ADK Agent 可以部署到上述任意目标。Agent Engine 是托管程度最高的选项 —— 你把 Agent 代码交给它，剩下的它来处理。

部署细节请参见 [Agent Engine 文档](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview)。

---

## Vertex AI Search 与 RAG Engine

Lesson 8 讲过 Agent 如何用 retrieval-augmented generation (RAG) 访问你的数据。Vertex AI 为此提供托管服务：

### Vertex AI Search

一个托管搜索服务，可以索引并搜索：

- 网站
- 非结构化文档（PDF、Word、HTML）
- 结构化数据（数据库、电子表格）

它把切片、embedding、索引、检索 —— 即我们在 Lesson 8 讨论过的完整 RAG 流水线 —— 作为托管服务来处理。

### RAG Engine

RAG Engine 提供专为 LLM 回复 grounding 设计的托管检索流水线：

- **文档摄入** —— 自动上传与处理文档
- **切片策略** —— 可配置的文档切分方式
- **向量搜索** —— 托管的 embedding 与相似度检索
- **与 Gemini 集成** —— Gemini 模型调用内置 grounding

这些托管服务的优势是你不必自己跑向量数据库、管理 embedding，或自建检索流水线。代价是对细节的控制力变弱。

RAG 能力请参见 [RAG Engine 总览](https://cloud.google.com/vertex-ai/generative-ai/docs/rag-overview)。

---

## Model Armor

Model Armor 是 Google Cloud 的托管 guardrails 服务（我们在 Lesson 10 详细讨论过 guardrails）。它提供：

| Feature | What It Does |
|---------|-------------|
| **Prompt screening** | Detect and block harmful or adversarial prompts before they reach the model |
| **Response filtering** | Screen model outputs for harmful, toxic, or inappropriate content |
| **Prompt injection detection** | Identify attempts to override model instructions |
| **Configurable policies** | Set your own thresholds for different content categories |
| **Integration** | Works with Vertex AI endpoints and can be added to any generative AI application |

Model Armor 让你不用从零搭建内容过滤，就能拿到一个 production-ready 的 Layer 2 防御（即 Lesson 10 中纵深防御模型里的第二层）。

---

## 快速上手指南

下面是用 ADK 与 Google Cloud 进行 Agent 开发的入门步骤。

### 前置条件

- 一个 Google Cloud 账号（可以从 [免费层](https://cloud.google.com/free) 开始）
- Python 3.9+（用于 Python SDK）
- 一个启用了计费的 Google Cloud 项目

### 第 1 步：安装 ADK

```bash
pip install google-adk
```

### 第 2 步：配置认证

你有两种认证方式可选：

**方案 A：API Key（最简单的入门方式）**
```bash
export GOOGLE_API_KEY="your-api-key-here"
```

可以在 [Google AI Studio](https://aistudio.google.com/) 获取 API key。

**方案 B：Google Cloud 项目（用于生产与 Vertex AI 特性）**
```bash
# Install the Google Cloud CLI
# https://cloud.google.com/sdk/docs/install

# Authenticate
gcloud auth application-default login

# Set your project
gcloud config set project YOUR_PROJECT_ID
```

### 第 3 步：创建你的第一个 Agent

新建文件 `agent.py`：

```python
from google.adk.agents import Agent

root_agent = Agent(
    name="greeting_agent",
    model="gemini-2.0-flash",
    instruction="You are a friendly assistant that greets users "
                "and answers basic questions.",
)
```

### 第 4 步：本地运行

```bash
adk web
```

这会启动一个本地 Web 界面，你可以与 Agent 对话并检查它的行为。ADK 的开发 UI 会展示 Agent 的推理步骤、tool 调用与状态 —— 对调试极有帮助。

### 第 5 步：加入 tools 与更多复杂度

之后你可以加 tools、构建多 Agent 系统、集成 RAG，最终部署到 Agent Engine 或 Cloud Run。[ADK 入门指南](https://google.github.io/adk-docs/get-started/) 详细介绍了这些步骤。

---

## 决策树：我该用哪个服务？

构建 Agent 时，用这棵决策树来挑选合适的 Google Cloud 服务：

```
"I want to build..."
    |
    +-- "A simple chatbot with no tools"
    |       --> Gemini API directly (no framework needed)
    |
    +-- "An agent with tools and reasoning"
    |       --> ADK + Gemini Flash
    |       |
    |       +-- "...and I need it in production"
    |               --> Deploy to Agent Engine or Cloud Run
    |
    +-- "An agent that searches my documents"
    |       --> ADK + Vertex AI Search or RAG Engine
    |
    +-- "A multi-agent system"
    |       --> ADK (multi-agent orchestration built in)
    |
    +-- "An agent with strict safety requirements"
    |       --> ADK + Model Armor + custom guardrails
    |
    +-- "A high-volume, cost-sensitive application"
    |       --> Model routing (Flash-Lite for simple tasks,
    |           Flash for complex) + context caching
    |
    +-- "An agent that needs to use external APIs"
            --> ADK with OpenAPI tools or MCP tools
```

### 快速参考表

| I Need... | Use... |
|-----------|--------|
| An LLM to call | Gemini models via Vertex AI or AI Studio |
| A framework to build agents | Agent Development Kit (ADK) |
| Managed agent hosting | Agent Engine |
| Custom container hosting | Cloud Run or GKE |
| Document search / RAG | Vertex AI Search or RAG Engine |
| Content safety guardrails | Model Armor |
| Model evaluation | Vertex AI Evaluation tools |
| Prompt management | Vertex AI prompt management |
| Interop with external tools | MCP tools in ADK |
| Interop with other agents | A2A protocol (covered in Lesson 14) |

---

## 各部分如何串起来：一个完整示例

下面是一个典型生产 Agent 如何把多个 Google Cloud 服务一起用的例子：

```
User asks: "What is the return policy for my recent order?"

1. [ADK Agent] receives the request
       |
2. [Model Armor] screens the input for safety
       |
3. [Gemini Flash] reasons about the request:
       "I need to look up the order and find the return policy"
       |
4. [ADK Tool: Order Lookup] calls your order database
       |
5. [RAG Engine] searches your policy documents
       for the relevant return policy
       |
6. [Gemini Flash] synthesizes a response from
       the order details and policy documents
       |
7. [Model Armor] screens the output for safety
       |
8. [Agent Engine] manages the session state
       and returns the response to the user
```

每个 Google Cloud 服务负责其中一块。ADK 编排流程，Gemini 提供推理，RAG Engine 提供知识，Model Armor 提供安全，Agent Engine 提供运行时。

---

## 各课概念到 Google Cloud 的映射

下表把前几课的概念与具体的 Google Cloud 服务对应起来：

| Lesson | Concept | Google Cloud Service |
|--------|---------|---------------------|
| 2 - How Agents Think | LLM reasoning | Gemini models |
| 3 - Tools | Function calling | ADK Function Tools, MCP Tools, OpenAPI Tools |
| 4 - Design Patterns | Orchestration | ADK Sequential/Parallel/Loop Agents |
| 5 - Memory | Session state, long-term memory | ADK session management, Agent Engine |
| 6 - Planning | Multi-step reasoning | Gemini Pro for complex planning |
| 7 - Multi-Agent | Agent coordination | ADK multi-agent support |
| 8 - RAG | Knowledge retrieval | Vertex AI Search, RAG Engine |
| 9 - Evaluation | Testing agents | Vertex AI Evaluation |
| 10 - Safety | Guardrails | Model Armor |
| 11 - Production | Deployment, CI/CD | Agent Engine, Cloud Run, Agent Starter Pack |

---

## 关键要点

1. **Google Cloud 为 Agent 提供完整技术栈。** 从底层的 Gemini 模型到顶层的 Agent Engine，可以构建并部署完整的 Agent 系统。

2. **ADK 是 code-first 框架。** 开源、多语言、模型无关、部署无关。它处理常见模式（tool calling、orchestration、状态管理），让你专注 Agent 自身逻辑。

3. **挑对模型等级。** 简单任务用 Flash-Lite，大多数 Agent 工作用 Flash，复杂推理用 Pro。跨等级的模型路由是关键的成本优化策略。

4. **托管服务降低运维负担。** Agent Engine、RAG Engine、Model Armor 处理基础设施与运维，让你专注构建。代价是对实现细节的控制力变弱。

5. **一切皆可组合。** 可以用 ADK 而不用 Agent Engine，可以用 Vertex AI 而不用 ADK，也可以一起用整套技术栈。从你需要的开始，按需扩展。

6. **ADK 的 Agent 直接对应本课程中的概念。** LLM Agents 对应推理，Workflow Agents 对应 orchestration 模式，tools 对应外部交互，skills 对应可复用能力。

---

## 延伸阅读

- [ADK 文档](https://google.github.io/adk-docs/) — 用 ADK 构建 Agent 的完整指南
- [Vertex AI 文档](https://cloud.google.com/vertex-ai/docs) — Vertex AI 平台完整参考
- [Agent Engine 总览](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview) — Agent 的托管运行时
- [RAG Engine 总览](https://cloud.google.com/vertex-ai/generative-ai/docs/rag-overview) — 托管的 retrieval-augmented generation
- [Agent Starter Pack](https://github.com/GoogleCloudPlatform/agent-starter-pack) — 内置 CI/CD 与可观测性的 production-ready 模板
- [Google AI Studio](https://aistudio.google.com/) — 获取 API key 并体验 Gemini 模型

---

下一课：[Building Your First Agent](/13-building-your-first-agent/)
