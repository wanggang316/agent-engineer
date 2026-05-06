---
title: "Lesson 13: 用 ADK 构建你的第一个 Agent"
---

## 引言

你已经走完了基础部分。你了解 Agent 是什么、它们如何思考、如何使用 tool、如何记忆，以及如何评估它们是否做得好。现在该真正动手构建一个了。

本课时将带你用 Google 的 Agent Development Kit (ADK) 构建一个实用的 Agent。结束时，你将掌握如何搭建项目、定义 Agent、为它配备 tool、在本地测试，甚至构建一个能协同工作的小型 Agent 团队。

我们会保持概念性讲解，并链接到官方 quickstart 获取确切的代码示例——这样你始终能拿到最新语法，我们也可以专注在真正重要的思路上。

---

## 我们要构建什么

我们的目标是构建一个实用 Agent，它能够：

- 用 Google Search 回答某个主题的问题
- 调用你定义的自定义 tool（比如查询天气或商品信息）
- 在本地运行，方便快速测试和迭代

把它想成 Agent 的 "hello world"——简单到一坐就能搞懂，又足够真实，能展示各部分如何串起来。

### 前置条件

开始之前，请确保你已经准备好：

- **Python 3.9+** 已安装
- **ADK 已安装**（`pip install google-adk`）
- **一个启用了 Gemini API 的 Google Cloud 项目**
- **API key 或 application default credentials 已配置**

> **环境搭建：** 跟随 [ADK Getting Started](https://google.github.io/adk-docs/get-started/) 的官方指引完成详细安装步骤。

---

## ELI5：我们到底在做什么？

构建第一个 Agent 就像拼乐高套装。你有一块底板（项目结构）、一个小人脑袋（语言模型）、若干配件 tool（搜索、自定义函数），以及一份说明书（system instructions），告诉小人该如何行动。

每个零件都按特定方式拼合。脑袋决定做什么；tool 让它能做事；instructions 让它保持专注；底板把所有东西固定住，不让它散架。

精彩的地方在于，一旦你理解了这些零件如何拼接，就可以替换、增加或重新组合，构建完全不同的东西。

---

## 一步一步走一遍

让我们一步一步过一遍构建第一个 Agent 的过程。每一步都会讲解概念，并指向官方 quickstart 中的确切代码。

### Step 1：搭建项目结构

ADK 期望特定的项目布局。最简形式下，你只需要一个 Agent 文件夹，里面放两个文件：

```
my_first_agent/
    __init__.py
    agent.py
```

文件夹名会成为你 Agent 的模块名。`__init__.py` 文件告诉 Python 这是一个包并导出你的 Agent。`agent.py` 文件是你定义 Agent 本体的地方。

这个结构很重要，因为 ADK 工具链（如 `adk web` 和 `adk eval`）就是靠这种模式来发现你的 Agent。从一开始就保持整洁、一致。

> **小贴士：** 你也可以用 `adk create my_first_agent` 自动搭好这个结构。

### Step 2：定义你的 Agent

每个 ADK Agent 至少需要三样东西：

1. **A name** —— Agent 的唯一标识符
2. **A model** —— 用于推理的 Gemini 模型
3. **System instructions** —— 告诉 Agent 它是谁、应如何行动的 prompt

概念上看是这样：

```python
from google.adk.agents import Agent

my_agent = Agent(
    name="my_first_agent",
    model="gemini-2.5-flash",
    instruction="You are a helpful assistant that answers questions clearly and concisely.",
)
```

`model` 参数决定哪个 Gemini 模型负责推理。学习和原型阶段，`gemini-2.5-flash` 是个不错的选择——速度快且成本低。需要更复杂的推理时，可以升级到 `gemini-2.5-pro`。

`instruction` 参数是 Agent 的 system prompt。它定义了 Agent 的人设、能力与边界。本课时稍后会讲如何写好 instructions。

### Step 3：创建一个自定义的 function tool

tool 是把 Agent 与聊天机器人区分开的关键。我们给 Agent 加一个可调用的自定义函数。

ADK 中，一个 tool 只是带有清晰 docstring 的 Python 函数。docstring 很重要，因为 ADK 会用它告诉模型这个 tool 是做什么的、何时使用。

```python
def get_weather(city: str) -> dict:
    """Get the current weather for a given city.

    Args:
        city: The name of the city to get weather for.

    Returns:
        A dictionary with weather information.
    """
    # In a real agent, this would call a weather API
    # For now, return mock data
    return {
        "city": city,
        "temperature": "72F",
        "conditions": "Sunny",
    }
```

需要注意的几个要点：

- **类型注解**（`city: str`、`-> dict`）帮助模型理解该传什么参数、能拿回什么
- **docstring** 是模型了解 tool 用途的方式——把它写得像在向同事解释这个函数
- **函数名**应当具有描述性——模型用它来决定何时调用 tool

然后把 tool 挂到 Agent 上：

```python
my_agent = Agent(
    name="my_first_agent",
    model="gemini-2.5-flash",
    instruction="You are a helpful assistant. Use the get_weather tool when asked about weather.",
    tools=[get_weather],
)
```

### Step 4：加入内置 tool（google search）

ADK 自带了几个内置 tool。最有用的之一是 Google Search 接地（grounding），能让 Agent 在网上搜索最新信息。

```python
from google.adk.tools import google_search

my_agent = Agent(
    name="my_first_agent",
    model="gemini-2.5-flash",
    instruction="You are a helpful assistant. Use search for current events and get_weather for weather.",
    tools=[get_weather, google_search],
)
```

现在你的 Agent 既能搜网，也能查天气。模型会根据用户的问题决定用哪个 tool。问新闻就走搜索，问天气就调用你的自定义函数。

### Step 5：本地运行与测试

ADK 自带本地开发服务器，提供一个 Web UI 与 Agent 交互：

```bash
adk web
```

它会启动一个本地服务器（通常在 `http://localhost:8000`）并提供聊天界面。你可以：

- 向 Agent 发送消息
- 查看它调用了哪些 tool 以及为什么
- 检查完整的对话历史
- 实时调试问题

也可以从命令行测试：

```bash
adk run my_first_agent
```

这是你最快的反馈循环。改一下、刷新、测试。重复，直到 Agent 表现得如你所愿。

### Step 6：用 ADK eval 进行评估

Agent 跑起来后，你希望随着改动它依然好用。ADK 自带评估框架：

```bash
adk eval my_first_agent eval_data.json
```

评估让你定义测试用例——成对的输入和期望行为——并自动检查 Agent 是否处理正确。这就是 Agent 版的单元测试。

我们在 Lesson 9 中深入讲过评估的概念。这里的关键是：从第一个 Agent 起就尽早写 eval 用例，能避免日后的回归问题。

> **完整 quickstart：** 跟随 [ADK Quickstart](https://google.github.io/adk-docs/get-started/quickstart/) 中的完整代码一起走。

---

## ADK 中的 Agent 类型

ADK 提供了四种 Agent 类型，每一种针对不同的任务而设计。选对类型就像选对数据结构——它会塑造之后的一切。

### LlmAgent（默认）

这是你最常用的 Agent 类型。它使用语言模型来决定下一步做什么。

**何时使用：**
- 任务需要推理与判断
- Agent 需要根据上下文决定调用哪个 tool
- 用户交互是对话式的

**工作方式：** 模型接收用户消息、可用 tool 与对话历史，决定是调用 tool、追问澄清问题还是直接回复。这就是 ReAct 循环的实战。

```python
from google.adk.agents import Agent

researcher = Agent(
    name="researcher",
    model="gemini-2.5-flash",
    instruction="You research topics thoroughly using search.",
    tools=[google_search],
)
```

### SequentialAgent（按顺序执行步骤）

SequentialAgent 像流水线一样依次运行一组固定的子 Agent。

**何时使用：**
- 任务有明确、有序的阶段
- 每个阶段依赖上一个的输出
- 你希望执行可预测、可重复

**示例：** 一个内容创作流水线，第一个 Agent 做研究，第二个写草稿，第三个做语法和风格的润色。

```python
from google.adk.agents import SequentialAgent

pipeline = SequentialAgent(
    name="content_pipeline",
    sub_agents=[researcher, writer, editor],
)
```

**类比：** SequentialAgent 像工厂里的装配线。每个工位干一件事，把结果交给下一个工位。

### ParallelAgent（同时执行步骤）

ParallelAgent 并发运行多个子 Agent，并收集它们的结果。

**何时使用：**
- 你有彼此独立的子任务
- 速度很重要，希望减少墙上时间
- 你需要对同一输入获得多种视角

**示例：** 评估一段代码时，让安全审查者、性能审查者、风格审查者同时进行。

```python
from google.adk.agents import ParallelAgent

review_team = ParallelAgent(
    name="code_review",
    sub_agents=[security_reviewer, perf_reviewer, style_reviewer],
)
```

**类比：** ParallelAgent 像团队头脑风暴——每个人同时各做一部分，再汇总结论。

### LoopAgent（循环直到完成）

LoopAgent 循环运行子 Agent，直到满足终止条件。

**何时使用：**
- 任务需要迭代式打磨
- 你希望持续改进直到达到质量阈值
- 迭代次数无法事先确定

**示例：** 一个写作 Agent 先起草、再按标准评估、再修改，直到质量分超过阈值。

```python
from google.adk.agents import LoopAgent

refiner = LoopAgent(
    name="iterative_writer",
    sub_agents=[drafter, evaluator, reviser],
    max_iterations=5,
)
```

**类比：** LoopAgent 像一次代码评审循环——你写代码、收到反馈、修改、再循环，直到评审者通过。

### 选择合适的 Agent 类型

| Agent 类型 | 适用场景 | 示例 |
|---|---|---|
| LlmAgent | 需要灵活推理 | 聊天机器人、研究助手 |
| SequentialAgent | 固定步骤的流水线 | ETL、内容创作 |
| ParallelAgent | 独立的并行任务 | 多评审者系统 |
| LoopAgent | 迭代打磨 | 质量提升循环 |

这些类型也可以组合。一个 SequentialAgent 的某个步骤可以是 LlmAgent；一个 LoopAgent 内部可以包含 ParallelAgent。这种可组合性是 ADK 的优势之一。

> **了解更多：** [ADK Agent Types](https://google.github.io/adk-docs/agents/)

---

## 构建多 tool 的 Agent

大多数真实 Agent 都需要多个 tool。我们来看怎样组合多种能力。

### 组合搜索、代码执行与自定义 tool

```python
from google.adk.agents import Agent
from google.adk.tools import google_search

def look_up_product(product_id: str) -> dict:
    """Look up product details by ID.

    Args:
        product_id: The unique product identifier.

    Returns:
        Product details including name, price, and availability.
    """
    # Call your product database/API here
    return {"id": product_id, "name": "Widget Pro", "price": 29.99}

def calculate_discount(price: float, discount_percent: float) -> float:
    """Calculate the discounted price.

    Args:
        price: The original price.
        discount_percent: The discount percentage (e.g., 20 for 20%).

    Returns:
        The price after discount.
    """
    return price * (1 - discount_percent / 100)

shopping_agent = Agent(
    name="shopping_assistant",
    model="gemini-2.5-flash",
    instruction="""You are a shopping assistant. You can:
    - Search the web for product reviews and comparisons
    - Look up specific products in our catalog by ID
    - Calculate discounts on prices

    Always look up the product first before calculating discounts.""",
    tools=[google_search, look_up_product, calculate_discount],
)
```

多 tool Agent 的关键是清楚说明何时使用哪个 tool。没有指引，模型可能在该查数据库时去搜网，或者反过来。

### tool 设计原则

在为 Agent 构建 tool 时，遵循以下准则：

1. **一个 tool 做一件事。** 每个 tool 把一件事做好。不要做一个能处理五种操作的"超级 tool"。

2. **描述性的名字与 docstring。** 模型按名字与描述挑选 tool。`get_order_status` 比 `fetch_data` 好。

3. **明确的参数类型。** 用类型注解。模型需要知道传字符串、数字还是对象。

4. **优雅的错误处理。** 返回有用的错误信息，而不是直接崩溃。模型若知道哪里出错，往往能恢复。

5. **尽量确定性。** 同样输入给出一致结果的 tool，模型更容易推理。

---

## 构建一个 Agent 团队

有时一个 Agent 搞不定全部。你可能需要专才——一个负责研究，一个负责写作，第三个负责事实核查。ADK 允许你构建带 root agent 的 Agent 团队，由 root agent 委派子 Agent。

### root agent 模式

```python
from google.adk.agents import Agent

# Specialist agents
researcher = Agent(
    name="researcher",
    model="gemini-2.5-flash",
    instruction="You research topics using web search. Return factual findings.",
    tools=[google_search],
)

writer = Agent(
    name="writer",
    model="gemini-2.5-flash",
    instruction="You write clear, engaging content based on research findings.",
)

fact_checker = Agent(
    name="fact_checker",
    model="gemini-2.5-flash",
    instruction="You verify claims by searching for supporting evidence.",
    tools=[google_search],
)

# Root agent that orchestrates
coordinator = Agent(
    name="content_team",
    model="gemini-2.5-pro",
    instruction="""You coordinate a content creation team. For any content request:
    1. Ask the researcher to gather information
    2. Ask the writer to create content based on the research
    3. Ask the fact_checker to verify key claims

    Delegate tasks to your team members and synthesize their work.""",
    sub_agents=[researcher, writer, fact_checker],
)
```

### 子 Agent 还是多 tool

| 方式 | 适用场景 | 取舍 |
|---|---|---|
| 一个 Agent，多个 tool | 单一推理链能搞定的任务 | 更简单，但 tool 太多时 Agent 容易迷失 |
| 多个子 Agent | 受益于专业化分工的任务 | 更灵活，但增加协作开销 |

**经验法则：** 如果单个 Agent 的 tool 超过 10–15 个并开始混淆，考虑拆成 tool 集更聚焦的子 Agent。

### Agent 之间的通信

ADK 中的子 Agent 共享一个 session state，相当于共享工作区。root agent 可向子 Agent 传上下文，子 Agent 之间也可通过它共享结果。

把它想成团队项目里的共享文档。协调者写下任务简报，研究者添加调研结果，写作者基于这些产出内容。

---

## 写好 system instructions 的小贴士

system instruction（prompt）是决定 Agent 行为的最重要因素。下面是实操指南。

### 角色要具体

**弱：**
```
You are a helpful assistant.
```

**更好：**
```
You are a customer support agent for Acme Corp. You help customers
with order tracking, returns, and product questions. You have access
to the order database and can look up orders by ID or email.
```

### 设定清晰边界

明确告诉 Agent 该做什么、不该做什么：

```
You ONLY handle questions about orders, returns, and products.
For billing questions, tell the customer to contact billing@acme.com.
Never make promises about delivery dates unless the tracking system confirms them.
Never share internal pricing or cost information.
```

### 提供示例

把你期望的行为做给 Agent 看：

```
When a customer asks about their order status, follow this pattern:
1. Ask for their order ID if they have not provided one
2. Look up the order using the get_order tool
3. Summarize the status in plain language
4. If the order is delayed, apologize and offer to escalate

Example:
Customer: "Where is my order?"
You: "I'd be happy to help track your order. Could you share your order ID? It should start with ORD- and you can find it in your confirmation email."
```

### 定义输出格式

如果你要求结构化回复，就明说：

```
Always respond in this format:
- Start with a one-sentence summary
- Provide details in bullet points
- End with a suggested next step
```

### 常见的 instruction 误区

| 误区 | 为什么是问题 | 修正 |
|---|---|---|
| 太模糊（"be helpful"） | 模型缺少具体指引 | 定义角色、范围与行为 |
| 太长（2000+ 词） | 关键指令淹没在噪声里 | 保持聚焦、用结构 |
| 不指引 tool 使用 | 模型靠猜决定何时用 tool | 解释每个 tool 的适用场景 |
| 没有错误处理 | 出错时 Agent 不知所措 | 加入 fallback 指令 |
| 没有边界 | Agent 试图样样都揽 | 明确范围之外的事项 |

---

## 初学者常见的错误

### 1. 一上来就太复杂

第一天不需要带 10 个 tool 的多 Agent 系统。从一个 Agent、一个 tool 起步。先把它跑得完美，再加复杂度。

### 2. 忽视 system instruction

很多初学者只盯着 tool 与代码，instruction 写一行了事。instruction 是控制 Agent 行为的主要杠杆，要在它上面投入时间。

### 3. 不测试 tool 调用

Agent 的可靠性取决于它的 tool。把 tool 函数接入 Agent 之前先独立测试。如果 `get_weather("London")` 抛异常，Agent 也会跟着崩。

### 4. 忘记处理错误

tool 会失败、API 会超时、数据会缺失。Agent 需要在出错时知道该怎么办。在 tool 代码和 system instruction 中都加入错误处理。

### 5. 模型选错

并不是每个任务都需要最强模型。简单的路由与 tool 调用，用 Flash 之类更轻量的模型就很好，也省钱。把更大的模型留给真正需要复杂推理的任务。

### 6. 跳过评估

没有 eval 用例，你就不知道改动是变好还是变坏。在迭代 prompt 之前，至少写 5–10 个测试用例。

### 7. 把密钥写进代码

不要把 API key 或凭据硬编码在 Agent 代码里。用环境变量或 secrets manager。这是基本的软件工程实践，但原型阶段很容易忘。

---

## 把它们串起来

这是构建 ADK Agent 全流程的心智模型：

```
1. Define the goal
   "What should this agent accomplish?"
        |
        v
2. Choose the agent type
   LlmAgent? Sequential? Parallel? Loop?
        |
        v
3. Write the system instruction
   Role, scope, boundaries, examples
        |
        v
4. Define the tools
   What actions does the agent need?
        |
        v
5. Wire it together
   Agent + model + instruction + tools
        |
        v
6. Test locally
   adk web / adk run
        |
        v
7. Write eval cases
   Input -> expected behavior
        |
        v
8. Iterate
   Improve instructions, add tools, refine
        |
        v
9. Deploy
   Agent Engine or your own infrastructure
```

每一步喂给下一步。第 6–8 步是个循环——在进入第 9 步之前，你会反复走多次。

---

## 速查：ADK CLI 命令

| 命令 | 作用 |
|---|---|
| `pip install google-adk` | 安装 ADK |
| `adk create <name>` | 搭建一个新的 Agent 项目 |
| `adk web` | 启动带 Web UI 的本地开发服务器 |
| `adk run <agent>` | 从命令行运行 Agent |
| `adk eval <agent> <data>` | 对 Agent 运行评估用例 |
| `adk deploy` | 把 Agent 部署到 Agent Engine |

---

## 进一步学习

- **Getting started with ADK：** [https://google.github.io/adk-docs/get-started/](https://google.github.io/adk-docs/get-started/)
- **完整 quickstart 教程：** [https://google.github.io/adk-docs/get-started/quickstart/](https://google.github.io/adk-docs/get-started/quickstart/)
- **Agent 类型详解：** [https://google.github.io/adk-docs/agents/](https://google.github.io/adk-docs/agents/)
- **Tools 参考：** [https://google.github.io/adk-docs/tools/](https://google.github.io/adk-docs/tools/)

---

## 关键要点

1. **ADK Agent 需要三样东西：** name、model、system instructions。tool 是可选的，但正是它们让 Agent 真正有用。

2. **从 LlmAgent 开始。** 它能覆盖大多数场景。只有出于明确的结构性原因，才考虑 SequentialAgent、ParallelAgent 或 LoopAgent。

3. **system instructions 是你的主要控制杆。** 角色要具体，划定边界，给出示例，并加入错误处理指引。

4. **早测试、勤测试。** 用 `adk web` 做交互式测试，用 `adk eval` 做自动化回归检查。

5. **增量构建。** 一个 Agent、一个 tool、一个 eval 用例。每块跑通了，再加下一块。

---

## 下一步是什么？

你已经能构建一个 Agent，接下来需要理解 Agent 如何与外部世界沟通。下一课时将探索两个重要协议——MCP 与 A2A——它们让 Agent 用开放标准与 tool 以及彼此对话。

[Next: Lesson 14 - Agent Protocols: MCP and A2A -->](/14-agent-protocols-mcp-and-a2a/)
