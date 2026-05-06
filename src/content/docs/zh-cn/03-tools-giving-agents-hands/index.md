---
title: "Lesson 3: tools — 给 agents 装上双手"
---

## 引言

在 Lesson 1 中我们确立了 agent = 大脑（LLM）+ 双手（tools）+ 控制循环（orchestration）。Lesson 2 我们探索了大脑。现在轮到给 agent 装上双手。

没有 tools，LLM 只能生成文本。它可以推理一个问题，却无法去数据库里查答案。它可以规划一次部署，但无法真正运行部署脚本。它可以起草一封邮件，却无法把它发出去。

Tools 是连接思考与行动的桥梁。它们是 agent 与外部世界互动 — 读取数据、调用 APIs、运行代码、采取行动 — 的机制。

本课时介绍 tools 是什么、它们有哪些类型、function calling 在底层是怎么工作的、设计 tools 的最佳实践，以及连有经验的工程师都常踩的坑。

---

## 为什么 agents 需要 tools

设想这样一个场景。用户问你的 agent：「分配给我的开放 bug 有几个？」

**没有 tools：**
LLM 无法访问你的 bug tracker。它可能说「我无法访问你的 bug tracker」（运气好的话），也可能 hallucinate 一个数字（运气不好的话）。

**有 tools：**
Agent 想：「我需要去查 bug tracker。」它调用 `get_bugs(assignee="current_user", status="open")`。tool 查询你的 Jira/Linear/GitHub Issues 实例，返回 `[{id: 1234, title: "Login timeout"}, {id: 1235, title: "CSS overflow on mobile"}]`。Agent 计数后回复：「你有 2 个开放 bug：Login timeout (#1234) 与 CSS overflow on mobile (#1235)。」

Tools 把 agent 从一个聪明的对话伙伴，转变为一个能真正把事办成的能干助手。

### tools 让你能做什么

| 没有 Tools | 有 Tools |
|---|---|
| 用训练数据回答（可能过时） | 用实时数据回答 |
| 描述应该做什么 | 真正去做 |
| 推理代码 | 运行代码并查看输出 |
| 猜测当前状态 | 查询并观察真实状态 |
| 起草一条消息 | 把消息发出去 |

---

## tools 的类型

Tools 有多种形式。理解不同类型有助于你为 agent 选择合适的方法。

### 1. function tools（自定义函数）

这些是你定义的、agent 可以调用的函数。你掌控实现、输入、输出与错误处理。

**示例：**
- `search_database(query, filters)` — 查询你的内部数据库
- `create_ticket(title, description, priority)` — 创建一个支持工单
- `send_notification(user_id, message)` — 发送一条推送通知
- `get_weather(city)` — 从第三方 API 获取天气
- `run_test_suite(test_path)` — 运行测试并返回结果

Function tools 是最常见的一类。它们是把 agent 的能力扩展到你具体用例上的主要方式。

### 2. built-in tools（平台提供）

这些是平台或框架提供的 tools，开箱即用。

**Google Cloud / Gemini built-in tools：**

| Tool | 它做什么 |
|---|---|
| **Google Search** | 用实时网页搜索结果 ground 模型回答。通过提供当前信息减少 hallucination。 |
| **Code Execution** | 在沙箱环境中运行 Python 代码。适合数学、数据分析与生成图表。 |
| **URL Context** | 抓取并处理给定 URL 的内容。 |

**何时使用 built-in tools：**
- 当你需要的功能已经作为 built-in 存在
- 当你希望平台来管理执行、sandboxing 与扩缩容
- 当你不想自行维护对常见能力的实现

**何时改为构建自定义 function tools：**
- 当你需要访问自己的系统与数据
- 当你需要自定义逻辑或业务规则
- 当 built-in tools 无法覆盖你的用例

### 3. agent tools（把 agent 当作 tool）

这是一个强大模式：一个 agent 把另一个 agent 当作 tool 使用。调用方 agent 把子任务委派给一个专门的 agent，拿回结果，然后继续自己的工作流。

**示例：**

```
Main Agent (Trip Planner)
    |
    +-- calls --> Flight Search Agent
    |                (specialized in finding flights)
    |
    +-- calls --> Hotel Agent
    |                (specialized in hotel bookings)
    |
    +-- calls --> Activity Agent
                     (specialized in local activities)
```

主 Agent 协调整个行程规划。每个子 Agent 在其领域内是专家，拥有自己的 tools 与指令。主 Agent 不需要知道航班搜索如何工作 — 它只是问 Flight Search Agent 并拿回结果。

**何时使用 agent tools：**
- 当一个子任务复杂到值得拥有自己的 agent，连同专门的 tools 与指令
- 当你想分离关注点、让每个 agent 都更简单
- 当不同子任务受益于不同的模型或配置

---

## function calling 一步一步解析

function calling 是支撑 tool 使用的核心机制。下面一步一步说明它是怎么工作的。

### 流程

```
Step 1: You define tools and send them to the model with the user's message
Step 2: The model decides whether to call a tool (and which one)
Step 3: The model returns a structured tool call (function name + arguments)
Step 4: YOUR CODE executes the function (the model never runs it)
Step 5: You send the function result back to the model
Step 6: The model uses the result to generate a response (or call another tool)
```

这一点非常关键：**模型不执行 tools**。它提议 tool 调用。你的代码去执行它们。模型从不直接接触你的数据库、APIs 或系统。控制权始终在你手里。

### 一步一步示例

让我们用一个天气 agent 走一遍具体例子。

**Step 1：定义 tool 并发送请求**

```python
tools = [
    {
        "name": "get_weather",
        "description": "Get the current weather for a given city. Returns temperature, conditions, and humidity.",
        "parameters": {
            "type": "object",
            "properties": {
                "city": {
                    "type": "string",
                    "description": "The city name, e.g. 'London' or 'San Francisco'"
                },
                "units": {
                    "type": "string",
                    "enum": ["celsius", "fahrenheit"],
                    "description": "Temperature units"
                }
            },
            "required": ["city"]
        }
    }
]

# Send to model with user message
response = model.generate(
    messages=[{"role": "user", "content": "What is the weather in Tokyo?"}],
    tools=tools
)
```

**Step 2-3：模型返回一个 tool 调用**

模型不会用文本回复。相反，它返回一个结构化的 tool 调用：

```json
{
    "tool_call": {
        "name": "get_weather",
        "arguments": {
            "city": "Tokyo",
            "units": "celsius"
        }
    }
}
```

模型推断出：
- 它需要 weather tool（而不是别的 tool）
- 城市是「Tokyo」（从用户消息中抽取）
- 摄氏度对 Tokyo 大概合适（从上下文推断）

**Step 4：你的代码执行函数**

```python
# This is YOUR code - you control what happens here
def get_weather(city, units="celsius"):
    # Call a real weather API
    response = weather_api.get(city=city, units=units)
    return {
        "city": city,
        "temperature": response.temp,
        "conditions": response.conditions,
        "humidity": response.humidity
    }

# Execute the tool call
result = get_weather(**tool_call.arguments)
# result = {"city": "Tokyo", "temperature": 18, "conditions": "Partly cloudy", "humidity": "65%"}
```

**Step 5-6：把结果回传并拿到回复**

```python
response = model.generate(
    messages=[
        {"role": "user", "content": "What is the weather in Tokyo?"},
        {"role": "assistant", "tool_call": tool_call},
        {"role": "tool", "content": json.dumps(result)}
    ],
    tools=tools
)
# Model responds: "The weather in Tokyo is 18 degrees Celsius and partly cloudy
#                  with 65% humidity."
```

### 多次 tool 调用

有时模型需要调用多个 tools 才能回答一个问题。这可以通过两种方式发生：

**顺序（一次接一次）：**
```
User: "Compare the weather in Tokyo and London"

Step 1: Model calls get_weather(city="Tokyo")
Step 2: You execute, return result
Step 3: Model calls get_weather(city="London")
Step 4: You execute, return result
Step 5: Model synthesizes both results into a comparison
```

**并行（同时进行）：**
有些模型支持并行 tool 调用，模型在一次响应里同时提议多次调用。在上面的天气对比例子中，模型可以同时返回 `get_weather("Tokyo")` 与 `get_weather("London")`。你执行两者，把两份结果一起回传，模型再做综合。这样更快，因为省了一次往返。

### 带 tools 的完整 agent 循环

在真实 agent 中，tool calling 发生在一个循环里：把用户消息与 tools 发送给模型，检查响应是文本答案（结束）还是一个 tool 调用（执行它，把结果追加到对话，循环回去）。这会持续直到模型认为信息足够给出回复。

---

## tool 设计最佳实践

你如何设计 tools 直接影响 agent 的表现。模型需要理解你的 tools 才能正确使用它们。下面是最重要的几条原则。

### 1. 使用清晰、描述性的名称

tool 名称是模型看到的第一件事。它应当一眼就传达 tool 是干什么的。

| 糟糕命名 | 良好命名 | 原因 |
|---|---|---|
| `do_thing` | `search_knowledge_base` | 明确搜索的对象 |
| `api_call` | `create_support_ticket` | 描述了动作与目标 |
| `process` | `validate_email_address` | 清楚说明处理对象与方式 |
| `get_data` | `get_order_by_id` | 指明数据类型与查找方式 |
| `run` | `execute_sql_query` | 明确运行的是什么 |

### 2. 单一职责

每个 tool 应只做好一件事。就像代码里的函数一样，tools 应有清晰单一的目的。

**糟糕：一个 tool 包揽一切**
```json
{
    "name": "manage_orders",
    "description": "Create, read, update, or delete orders",
    "parameters": {
        "action": {"type": "string", "enum": ["create", "read", "update", "delete"]},
        "order_id": {"type": "string"},
        "order_data": {"type": "object"}
    }
}
```

模型现在既要决定使用哪个 action，又要知道每种 action 需要哪些参数。这会带来错误。

**良好：每个动作各自一个 tool**
```json
[
    {
        "name": "get_order",
        "description": "Look up an order by its ID. Returns order status, items, and shipping info.",
        "parameters": {
            "order_id": {"type": "string", "description": "The order ID, e.g. 'ORD-12345'"}
        }
    },
    {
        "name": "create_order",
        "description": "Create a new order with the specified items.",
        "parameters": {
            "items": {"type": "array", "description": "List of item IDs and quantities"},
            "shipping_address": {"type": "string"}
        }
    },
    {
        "name": "cancel_order",
        "description": "Cancel an existing order. Only works for orders not yet shipped.",
        "parameters": {
            "order_id": {"type": "string"},
            "reason": {"type": "string", "description": "Reason for cancellation"}
        }
    }
]
```

每个 tool 目的清晰、参数明确。模型很容易选对。

### 3. 写出有描述性的参数

参数描述告诉模型该传什么。要在格式、约束与默认值上具体说明。

**糟糕：**
```json
{
    "name": "search",
    "parameters": {
        "q": {"type": "string"},
        "n": {"type": "integer"}
    }
}
```

模型只能猜 `q` 与 `n` 是什么意思。

**良好：**
```json
{
    "name": "search_products",
    "parameters": {
        "query": {
            "type": "string",
            "description": "Search query for product name or description, e.g. 'wireless headphones'"
        },
        "max_results": {
            "type": "integer",
            "description": "Maximum number of results to return. Range: 1-50. Default: 10"
        }
    }
}
```

### 4. 返回简洁、有用的输出

Tool 的结果会回到模型的 context window。返回过多数据会浪费 tokens 并可能让模型困惑。

**糟糕：返回带有一切字段的原始 API 响应**
```json
{
    "status": 200,
    "headers": {"content-type": "application/json", "x-request-id": "abc123", ...},
    "data": {
        "order": {
            "id": "ORD-12345",
            "internal_id": "a1b2c3d4-e5f6-7890",
            "created_at": "2024-03-15T10:30:00Z",
            "updated_at": "2024-03-15T14:22:00Z",
            "customer_id": "CUST-789",
            "customer_hash": "sha256:abcdef...",
            "status": "shipped",
            "status_code": 3,
            "status_history": [...50 entries...],
            "items": [...full product details with all fields...],
            "shipping": {...full carrier details...},
            "billing": {...full payment details...},
            "metadata": {...internal tracking data...}
        }
    }
}
```

**良好：只返回 agent 需要的内容**
```json
{
    "order_id": "ORD-12345",
    "status": "shipped",
    "items": ["Wireless Headphones x1", "USB-C Cable x2"],
    "tracking_number": "1Z999AA10123456784",
    "estimated_delivery": "March 20, 2026"
}
```

### 5. 给出清晰的错误信息

当 tool 调用失败时，错误信息应能帮助模型理解出错原因和下一步该做什么。

**糟糕的错误：**
```json
{"error": "Failed"}
```

**良好的错误：**
```json
{
    "error": "ORDER_NOT_FOUND",
    "message": "No order found with ID 'ORD-99999'. Please verify the order ID and try again. Order IDs follow the format ORD-XXXXX."
}
```

良好的错误信息提供了足够的内容，让模型可以修正其方法（也许它用了错的 ID 格式），或清楚地告知用户。

### 6. 在描述中说明 tool 行为

Tool 描述是你告诉模型何时以及如何使用它的机会。需要包括：

- **tool 做什么**（主要动作）
- **何时使用**（条件与触发）
- **返回什么**（输出格式）
- **限制**（它做不了什么）

**示例：**
```json
{
    "name": "search_knowledge_base",
    "description": "Search the company knowledge base for relevant articles and documentation. Use this tool when the user asks a question about company policies, product features, or internal processes. Returns the top 5 most relevant articles with titles, summaries, and links. Does not search external websites - use web_search for that."
}
```

---

## N x M 集成问题

随着 agent 系统变大，tool 集成成为一个明显的挑战。原因在于：

### 问题

设想你有 N 个不同的 AI 应用（编码助手、研究 agent、支持机器人），与 M 个不同的服务（Slack、Jira、GitHub、Salesforce）。没有标准化时，每个应用都需要自定义代码去对接每个服务 — 这就是 N x M 个集成需要构建与维护。

### 标准化为什么重要

**Model Context Protocol (MCP)** 之类的标准旨在通过在 AI 应用与 tool 提供方之间建立统一接口来解决这一问题。每个应用实现一次该协议，每个 tool 提供方实现一次该协议。新应用自动可用所有已有 tools，反之亦然。

**把它想象成 USB。** 在 USB 出现以前，每个设备都有专属线缆。USB 之后，任何设备都能连接任何电脑。Tool 标准的目标就是成为「AI tools 的 USB」。

在选择框架或构建 tools 时，请考虑其他 agents 是否能复用你的 tools（构建为 MCP servers 以便携性），以及你的 agent 是否能使用其他来源的 tools（支持 MCP 以获得广泛兼容）。标准仍在演化中，请结合你的时间线评估。

---

## tool 设计中的常见陷阱

### 1. tools 太多会拥塞上下文

每个 tool 定义都占用模型 context window 的空间。更重要的是，模型必须从全部 tools 中推理选谁。tools 太多会导致：

- **决策瘫痪**：模型难以挑出正确的 tool
- **错误选择**：在多个相似 tools 中，模型挑错
- **浪费上下文**：tool 定义挤占了有用的对话历史

**多少 tools 算太多？**

没有硬性规则，但这是一些指南：

| Tool 数量 | 指引 |
|---|---|
| 1-5 | 多数模型都没问题。无需特别处理。 |
| 5-15 | 只要名称与描述清晰、彼此区分良好即可。 |
| 15-30 | 考虑把相关 tools 分组，或加一个 tool 选择步骤。 |
| 30+ | 可能太多。采用两阶段方法：先选类别，再选具体 tool。 |

**面向大量 tools 的两阶段方法：**

```
Stage 1: Model picks a category
  "User wants to manage their order -> Category: Order Management"

Stage 2: Model sees only the tools in that category
  [get_order, create_order, cancel_order, update_shipping]
  -> Model picks: get_order
```

这样每次决策都更可控。

### 2. 含糊的 tool 描述

如果模型分辨不出何时使用某个 tool，它要么会用错，要么干脆不用。

**糟糕：**
```json
{
    "name": "lookup",
    "description": "Looks up information"
}
```

查什么的信息？模型什么时候应当调用它而不是别的 tool？返回的是什么格式？

**良好：**
```json
{
    "name": "lookup_employee",
    "description": "Look up an employee by name or employee ID. Returns their department, role, email, and manager. Use this when the user asks about a specific person at the company."
}
```

### 3. 薄薄的 API 包装（暴露实现细节）

一个常见错误是把原始 API 接口直接当 tool 暴露给模型，没做任何抽象。一个通用的 `api_request(method, url, headers, body)` tool 强迫模型知道你的 URL 结构、auth headers 与请求格式 — 它经常会搞错。

更好的做法是构建专用的 tools，比如 `get_customer_orders(customer_email, status_filter)`，把 HTTP 细节藏在干净的接口背后。你的代码处理认证、URL 构造与响应解析。模型只说出它想要什么。

### 4. 错误信息缺失

当 tool 调用失败而错误信息毫无用处时，agent 就会陷入重试循环或干脆放弃。

**常见失败模式：**

| 错误类型 | 糟糕响应 | 良好响应 |
|---|---|---|
| 未找到 | `{"error": true}` | `{"error": "CUSTOMER_NOT_FOUND", "message": "No customer with email 'jn@example.com'. Did you mean 'jane@example.com'?"}` |
| 输入无效 | `500 Internal Server Error` | `{"error": "INVALID_DATE_FORMAT", "message": "Expected date in YYYY-MM-DD format, got '03/15/2024'"}` |
| 速率限制 | `{"error": "fail"}` | `{"error": "RATE_LIMITED", "message": "Too many requests. Try again in 30 seconds."}` |
| 鉴权失败 | `null` | `{"error": "UNAUTHORIZED", "message": "API key expired. This tool is temporarily unavailable."}` |

### 5. 返回过多数据

巨大的 tool 响应会吃掉 context window，并可能用无关细节混淆模型。管理策略包括：

- **在源头过滤**：只从数据库/API 取你需要的部分
- **挑选相关字段**：不要返回每个字段 — 只挑 agent 需要的
- **分页**：返回一个子集，并提供继续获取的能力
- **总结**：对于大段文本响应，先总结再返回
- **截断**：限制长字符串字段的长度（例如 `message[:200]`）

### 6. 不处理 tool 超时

外部 APIs 可能很慢或无响应。一定要为 HTTP 调用设置超时，并在失败时返回描述性的错误信息，而不是让 agent 无限挂起。

---

## tool 设计清单

设计 agent 的 tools 时使用这份清单：

```
[ ] Name clearly describes the action (verb + noun)
[ ] Description explains what, when, and what it returns
[ ] Each tool has a single responsibility
[ ] Parameters have descriptive names (not abbreviations)
[ ] Parameters include descriptions with format examples
[ ] Required vs optional parameters are clearly marked
[ ] Output is concise - only fields the agent needs
[ ] Error messages are descriptive and actionable
[ ] Timeouts are implemented for external calls
[ ] Authentication is handled in the tool code, not by the model
[ ] Output size is bounded (truncation, pagination, or summarization)
[ ] Tool is tested independently before connecting to the agent
```

---

## ELI5：tools 是什么？

### tools 就像手机上的 apps

想象你的智能手机。手机本身很聪明 — 它有强大的处理器、漂亮的屏幕和好用的操作系统。但没有 apps，它做不了什么。

- 想看天气？你需要**天气 app**。
- 想发消息？你需要**消息 app**。
- 想去某个地方？你需要**地图 app**。
- 想拍照？你需要**相机 app**。

每个 app 给手机一项新能力。手机本身不知道如何预测天气 — 它只知道如何打开天气 app、请求预报、并把结果显示给你。

**LLM 就像没装 apps 的手机。** 它聪明，但不能查实时天气、发真实消息或查找实际路线。它只能基于训练时学到的内容来谈论这些。

**tools 就像在手机上装 apps。** 每个 tool 给 agent 一项新能力：
- `get_weather` 是天气 app
- `send_email` 是邮件 app
- `search_database` 像是为你的数据定制的搜索 app
- `run_code` 像是编程 app

并且，就像 apps 一样：
- 手机（模型）根据你的请求决定打开哪个 app
- App（tool）做实际工作
- 手机把结果显示给你

当你设计 tools 时，本质上是在为你的 agent 搭建 app store。命名清晰、功能有用的好 apps 让手机更能干。命名混乱、行为不稳的坏 apps 让人沮丧。

---

## Google Cloud 上的 tools

Google Cloud 提供多种方式给 agents 装上 tools：

### Vertex AI function calling

Vertex AI 支持在 Gemini 模型上做 function calling。你以函数声明的形式定义 tools，模型在适合时会生成结构化的函数调用。

> **了解更多：** [Vertex AI Function Calling](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/function-calling)

### Agent Development Kit ADK tools

Agent Development Kit (ADK) 提供了一种结构化的方式来定义并管理 agents 的 tools。ADK 支持：

- **Function tools**：把任意 Python 函数包装为 agent 的 tool
- **Built-in tools**：Google Search、Code Execution 等
- **Agent tools**：把另一个 ADK agent 当作 tool
- **第三方 tools**：与 LangChain tools、CrewAI tools、MCP servers 的集成

ADK 处理 tool 定义格式、执行与结果传递，让你专注于 tool 的逻辑而非管线。

> **了解更多：** [ADK Tools Documentation](https://google.github.io/adk-docs/tools/)

### built-in 的 grounding tools

Google Search grounding 在 Vertex AI 的 Gemini 模型上以 built-in tool 形式提供。启用后，模型可以搜索网络以把回答 ground 在最新信息上 — 无需自定义 tool 代码。

---

## 综合起来：一个实用例子

让我们为一个简单的 DevOps agent 设计 tools，它帮助工程师调查生产事件。

### agent 的目的

帮助 on-call 工程师诊断并响应生产告警。

### tool 集合设计

| Tool | 用途 | 何时使用 |
|---|---|---|
| `get_alert_details` | 获取某个具体告警的详情 | 当工程师询问某个告警时 |
| `query_metrics` | 获取某个服务的时间序列指标 | 调查性能问题时 |
| `search_logs` | 按服务与时间范围搜索应用日志 | 查找错误或模式时 |
| `list_recent_deployments` | 列出某个服务近期的部署 | 检查是否由部署导致问题时 |
| `get_runbook` | 获取某类告警的 runbook | 当 agent 需要建议修复步骤时 |
| `create_incident` | 创建事件工单 | 当问题已确认并需要追踪时 |

注意每个 tool 都遵循我们的最佳实践：清晰的「动词+名词」命名、解释「做什么/何时用/返回什么」的描述、单一职责、带示例的描述性参数。

### 示例交互

```
Engineer: "Alert ALT-9876 just fired. What is going on?"

Agent thinking: "I need to look up this alert first."
-> Calls: get_alert_details(alert_id="ALT-9876")
<- Returns: {service: "auth-service", type: "high_latency", severity: "P1",
             description: "p99 latency >2s for 5 minutes"}

Agent thinking: "High latency on auth-service. Let me check metrics and recent deploys."
-> Calls: query_metrics(service="auth-service", metric="latency_p99", time_range="1h")
-> Calls: list_recent_deployments(service="auth-service", limit=5)
<- Metrics show latency spike starting at 14:05
<- Deploy #456 happened at 14:02

Agent thinking: "Latency spiked 3 minutes after a deploy. Let me check error logs."
-> Calls: search_logs(service="auth-service", query="timeout OR slow", level="error", time_range="1h")
<- Logs show: "Database connection pool exhausted" errors starting at 14:05

Agent thinking: "The deploy likely changed something that exhausts the DB connection pool.
                Let me get the runbook for guidance."
-> Calls: get_runbook(alert_type="high_latency")
<- Runbook: Step 1: Check recent deploys. Step 2: Compare config changes...

Agent responds:
"Here is what I found for ALT-9876:

**Issue:** auth-service p99 latency spiked above 2 seconds starting at 14:05.

**Likely cause:** Deploy #456 (at 14:02) appears to have triggered database connection pool
exhaustion. Error logs show 'Database connection pool exhausted' errors starting 3 minutes
after the deploy.

**Recommended actions:**
1. Review the changes in deploy #456, particularly any database configuration changes
2. Consider rolling back deploy #456 if the latency is impacting users
3. Check the connection pool size setting - it may need to be increased

Would you like me to create an incident ticket for this?"
```

这个例子展示了名称清晰、描述良好、输出简洁的 tools 是如何让 agent 通过多步高效调查问题的。

---

## 关键要点

1. **Tools 弥合了思考与行动之间的差距。** 没有 tools 的 agent 只是聊天机器人。有了 tools，它能与真实系统和数据互动。

2. **模型从不直接执行 tools。** 它提议 tool 调用，由你的代码来执行。真实发生的事始终在你掌控之中。

3. **三种类型的 tools**：function tools（自定义）、built-in tools（平台提供），以及 agent tools（把另一个 agent 当 tool）。优先用 function tools 满足你的特定用例。

4. **tool 设计就是 UX 设计 — 面向模型的。** 清晰的命名、有描述的参数、简洁的输出与有用的错误信息，是「模型用得好」与「模型挣扎着用」的分界。

5. **关注你的 tool 数量。** 越多的 tools 意味着越多的上下文消耗与更难的决策。把 tool 集合聚焦到 agent 真正需要的范围。

6. **标准化降低集成负担。** MCP 这类协议旨在通过在 AI 应用与 tools 之间建立统一接口来解决 N x M 问题。

---

## 下一步是什么？

理解了大脑（LLM）和双手（tools）之后，下一节课会把它们与 orchestration 层 — 控制循环 — 结合起来，由它管理 agent 的思考、行动、观察并不断重复直到把工作完成。

[Next: Lesson 4 - Orchestration: The Agent Loop -->](/04-orchestration/)
