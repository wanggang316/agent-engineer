---
title: "Lesson 14: Agent 协议 — MCP 与 A2A"
---

## 引言

你能构建一个 Agent，能为它配备 tool，甚至能搭建一个相互协作的 Agent 团队。但如果 Agent 需要使用别人构建的 tool 怎么办？或者它需要与另一家公司、另一个团队、另一个框架构建的 Agent 协作呢？

没有标准的话，你就要为每种组合写定制集成代码。这是无法规模化的。

本课时介绍两个解决该问题的开放协议：用于把 Agent 连接到 tool 与数据的 **Model Context Protocol (MCP)**，以及让 Agent 跨组织、跨厂商协作的 **Agent-to-Agent Protocol (A2A)**。它们共同构成现代 Agent 生态的通信层。

---

## 为什么需要协议

### N x M 的集成问题

设想你有 5 个 Agent 框架和 10 个 tool。没有标准协议，每个框架都要为每个 tool 写一个定制连接器。那是 5 x 10 = 50 个定制集成。

再加 5 个 tool？多 25 个集成。再加一个框架？多 15 个。成本呈乘法增长。

```
Without a standard protocol:

  Agent A ---custom---> Tool 1
  Agent A ---custom---> Tool 2
  Agent A ---custom---> Tool 3
  Agent B ---custom---> Tool 1
  Agent B ---custom---> Tool 2
  Agent B ---custom---> Tool 3
  ...
  (N agents x M tools = N*M integrations)


With a standard protocol:

  Agent A ---\                  /--> Tool 1
  Agent B -----> [Protocol] ---+--> Tool 2
  Agent C ---/                  \--> Tool 3
  (N + M integrations)
```

这跟 USB 解决硬件问题如出一辙。USB 之前，每个设备都有专有接口：打印机要并口，键盘要 PS/2，相机要串口。USB 给所有人一个共同接口，整个生态随之爆发。

协议在 Agent 领域做着同样的事。

### 两种通信

Agent 需要以两种本质不同的方式通信：

1. **Agent 到 tool：**"用这些参数调用这个函数，把结果给我。"这是结构化、具体且同步的。MCP 处理这类。

2. **Agent 到 Agent：**"我需要在这个目标上得到帮助，自己想办法完成，做完通知我。"这是开放式、目标导向，且可能异步的。A2A 处理这类。

理解这一区别，是理解为何需要两个协议而非一个的关键。

---

## Model Context Protocol (MCP)

### MCP 是什么

MCP 是一个开放标准，用于把语言模型和 Agent 连接到外部 tool 与数据源。最初由 Anthropic 创建，如今被业界广泛采用。MCP 提供 AI 应用与其访问的服务之间的通用接口。

把 MCP 想成 AI tool 的 **通用适配器**。就像 USB 接口让任何 USB 设备都能插进任何电脑，MCP 让任何 Agent 都能用任何兼容 MCP 的 tool，而无需定制集成代码。

### 架构：host、client、server

MCP 采用三段式架构：

```
+------------------+
|      Host        |    (Your AI application - IDE, chatbot, agent)
|  +------------+  |
|  |   Client   |  |    (MCP client - manages connections to servers)
|  +-----+------+  |
+---------|---------+
          |
     MCP Protocol
     (JSON-RPC)
          |
+---------|---------+
|     Server        |    (MCP server - wraps a tool or data source)
|  +------------+   |
|  | Tool/Data  |   |    (The actual capability - database, API, file system)
|  +------------+   |
+-------------------+
```

**Host：** 用户与之交互的应用。可以是像 VS Code 这样的 IDE、聊天界面或你的 Agent 应用。host 内含一个或多个 MCP client。

**Client：** MCP client 位于 host 中，管理与 MCP server 的连接。它处理协议协商、消息路由与连接生命周期。一个 client 可以连接多个 server。

**Server：** MCP server 包装某个具体 tool 或数据源，并通过 MCP 协议暴露出来。已有的 server 涵盖数据库、文件系统、API、SaaS 产品等。任何人都能构建 MCP server。

### 关键原语

MCP 定义了 server 可以暴露的三种核心原语：

| 原语 | 是什么 | 方向 | 示例 |
|---|---|---|---|
| **Tools** | 模型可调用的函数 | 模型发起，server 执行 | `search_database(query)`、`send_email(to, body)` |
| **Resources** | 模型可读取的数据 | 模型请求，server 提供 | 文件内容、数据库记录、API 响应 |
| **Prompts** | 模板化交互 | server 提供，用户选择 | "Summarize this document"、"Debug this error" |

**Tools** 是最常用的原语。它们的工作方式跟 Lesson 3 中讲的函数 tool 一样，但接口标准化，可在任何兼容 MCP 的 Agent 间通用。

**Resources** 在不需要函数调用的情况下为模型提供上下文。把它们看作模型可引用的只读数据源。

**Prompts** 是 server 可提供的预置交互模板。它们帮助用户发现 server 能做什么。

### 通用适配器类比

没有 MCP 时，把一个 Agent 连接到新的数据源是这样：

1. 阅读数据源的 API 文档
2. 写鉴权代码
3. 写请求/响应处理
4. 写错误处理
5. 为你的具体框架定义 tool schema
6. 测试集成

有了 MCP，则是这样：

1. 安装该数据源对应的 MCP server
2. 把 Agent 连上去
3. 完成

MCP server 处理鉴权、请求格式化、错误处理与 schema 定义，你的 Agent 只需要会说 MCP。

### MCP 的好处

- **一次构建，处处可用。** 一个以 MCP server 形式构建的 tool，可与任何兼容 MCP 的 Agent 协作——ADK、Claude、Cursor 或其他任何 host。

- **动态 tool 发现。** Agent 能在运行时发现可用 tool，而不是事先全部硬编码。连上一个新的 MCP server，Agent 就自动获得新能力。

- **生态杠杆效应。** 社区已为流行服务构建了数百个 MCP server。需要连 GitHub？Slack？PostgreSQL 数据库？很可能已经有现成的 MCP server。

- **关注点分离。** tool 构建者专注 tool。Agent 构建者专注 Agent。协议处理两者之间的接口。

### 在 ADK 中使用 MCP tool

ADK 内置了对 MCP 的支持。你可以连接到任何 MCP server，并像使用原生 ADK tool 一样使用它的 tool。

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import MCPToolset, SseServerParams

# Connect to an MCP server
mcp_tools = MCPToolset(
    connection_params=SseServerParams(
        url="http://localhost:3000/mcp",
    )
)

agent = Agent(
    name="mcp_agent",
    model="gemini-2.0-flash",
    instruction="You are a helpful assistant with access to external tools.",
    tools=[mcp_tools],
)
```

Agent 在运行时从 MCP server 发现可用 tool。如果 server 暴露了 `search_database` 与 `create_ticket` 两个 tool，你的 Agent 不用额外写代码就能两个都用。

> **了解更多：** [MCP Tools in ADK](https://google.github.io/adk-docs/tools/mcp-tools/)

### 局限与安全考量

MCP 很强大，但也有要理解的取舍：

**Tool shadowing。** 如果两个 MCP server 暴露名称或描述相近的 tool，模型可能搞不清该调用哪个。要刻意挑选连接的 server，并检查命名冲突。

**context window 膨胀。** 每个连接的 MCP server 都会向 context window 添加 tool 定义。连太多 server 会挤占真正对话的空间。每个 tool 定义通常消耗 100–500 tokens。

**没有原生的范围限制。** MCP 没有内置的细粒度权限控制。如果 Agent 连了一个数据库的 MCP server，它就可能访问该 server 暴露的任意数据。你需要在 server 端或通过 guardrails 处理鉴权。

**信任与供应链。** 社区构建的 MCP server 是 Agent 要执行的第三方代码。请像对待任何开源依赖一样谨慎——审阅代码、查看维护者，并在 sandbox 环境中运行。

**延迟。** 每次 MCP tool 调用都涉及与 MCP server 的网络通信。对时延敏感的应用，要把这部分开销算上。

| 考量 | 风险 | 缓解 |
|---|---|---|
| Tool shadowing | 模型调用错误的 tool | 审计 tool 名称，限制连接的 server |
| 上下文膨胀 | 推理质量下降 | 只连必要的 server |
| 没有范围限制 | 数据访问范围过宽 | server 端鉴权、guardrails |
| 供应链 | 恶意或有缺陷的 server | 代码评审、sandbox |
| 延迟 | tool 响应慢 | 本地 server、缓存 |

---

## Agent-to-Agent Protocol (A2A)

### A2A 是什么？

A2A 是 Google 开发的开放协议，让 Agent 能发现、与之通信并委派任务给其他 Agent——即便对方是不同团队、用不同框架、在不同组织里构建的。

如果说 MCP 解决"Agent 与 tool 对话"的问题，A2A 解决的就是"Agent 与 Agent 对话"的问题。

### 职业网络的类比

想想现实中专业人士如何协作。需要法律建议时，你不会自己变成律师。你会找一位合格的律师，说明你的需求，由他来处理。

你怎么找到那位律师？

1. **发现：** 通过目录、推荐或职业网络查到他们
2. **能力检查：** 查看他们的资料，确认他们处理你这类案件
3. **接洽：** 描述情况和你的需求
4. **委派：** 他们离开去工作，并发来进展更新
5. **交付：** 他们带着结果回来

A2A 在 Agent 之间是一样的：

1. **发现：** 你的 Agent 通过 Agent Card 找到其他 Agent
2. **能力检查：** 读取 card 看对方能做什么
3. **接洽：** 发送任务，描述要做的事
4. **委派：** 远端 Agent 开始处理，并发送状态更新
5. **交付：** 远端 Agent 返回完成的结果

### 关键概念

#### Agent Card

Agent Card 就像 Agent 的名片。它是一份标准化 JSON 文档，描述 Agent 能做什么、如何与之通信，以及它需要什么鉴权。

```json
{
  "name": "Travel Booking Agent",
  "description": "Books flights and hotels based on travel requirements",
  "url": "https://travel-agent.example.com/a2a",
  "capabilities": {
    "streaming": true,
    "pushNotifications": true
  },
  "skills": [
    {
      "id": "book_flight",
      "name": "Book Flight",
      "description": "Search and book flights between cities"
    },
    {
      "id": "book_hotel",
      "name": "Book Hotel",
      "description": "Find and reserve hotel rooms"
    }
  ],
  "authentication": {
    "schemes": ["oauth2"]
  }
}
```

Agent Card 托管在一个 well-known URL 上（通常是 `/.well-known/agent.json`），让发现变得简单。你的 Agent 只需检查一个已知端点，就能知道对方提供什么。

#### 任务

任务是 A2A 的基本工作单元。当一个 Agent 要让另一个 Agent 做事时，它会创建任务：

- **任务创建：** 调用方 Agent 发送一条消息，描述要做的事
- **任务生命周期：** 任务在状态间流转——submitted、working、input-required、completed 或 failed
- **任务更新：** 工作中的 Agent 可发送进度更新，让调用方了解情况
- **任务完成：** 工作中的 Agent 以 artifact 形式返回结果

#### Artifact

artifact 是任务的输出，可以是文本、文件、结构化数据，或工作中的 Agent 产生的任何其他内容。

#### 事件队列

A2A 通过 Server-Sent Events (SSE) 支持实时通信。这让 Agent 能流式发送进度更新，而不是等整个任务完成。这对长任务尤为重要——调用方 Agent（或人类）想看到中间进度。

### A2A 与直接 API 调用的对比

你也许会问：为什么不直接调另一个 Agent 的 API？可以，但你会面临前面提到的同样的 N x M 问题。A2A 给你：

- **标准化发现** —— 不必了解 Agent 的具体 API 也能找到它
- **共同的任务生命周期** —— 每个 Agent 都用相同方式处理任务
- **默认流式** —— 不必自己写 WebSocket 也能实时更新
- **跨框架兼容** —— 你的 ADK Agent 可以与 LangChain Agent 协作
- **鉴权标准** —— 跨 Agent 的安全模型保持一致

### 何时用 A2A、何时用 MCP

这是你最需要理解的区分之一：

| 维度 | MCP | A2A |
|---|---|---|
| **谁与谁通信** | Agent 与 tool | Agent 与 Agent |
| **通信风格** | "做这件具体的事" | "达成这个目标" |
| **请求复杂度** | 单次函数调用 | 开放式任务 |
| **对方是否会推理** | tool（不推理） | Agent（会推理） |
| **示例** | "Query this database" | "Research this topic and write a report" |
| **类比** | 用计算器 | 雇顾问 |

**MCP 用于 tool。** 你确切知道想调用什么函数、要传什么参数。tool 执行后返回结果。对方不做推理。

**A2A 用于 Agent。** 你描述目标，让对方自己想办法完成。对方有自己的推理、自己的 tool、自己的方法。

**实战例子：** 假设你在构建一个旅行规划 Agent。

- 你会用 **MCP** 连接航班搜索 API（一个传入出发地、到达地与日期，返回航班的 tool）
- 你会用 **A2A** 把任务委派给一个酒店预订 Agent，它能理解像"会议场馆附近安静的地方"这种偏好，并自行找出最优选择

> **了解更多：** [A2A in ADK](https://google.github.io/adk-docs/a2a/) 与 [A2A Protocol Spec](https://a2a-protocol.org/latest/)

---

## MCP 与 A2A 如何协同

MCP 与 A2A 不是相互竞争的标准。它们处在不同层级，互为补充。

```
+---------------------------------------------+
|              Your Agent                      |
|                                              |
|  "I need to book a trip to Tokyo"            |
|                                              |
|  +-------------------+  +----------------+   |
|  | MCP Client        |  | A2A Client     |   |
|  | (talks to tools)  |  | (talks to      |   |
|  |                   |  |  other agents)  |   |
|  +--------+----------+  +-------+--------+   |
+-----------|-----------------------|----------+
            |                       |
    +-------v--------+     +-------v--------+
    | MCP Servers     |     | Remote Agents  |
    |                 |     |                |
    | - Flight API    |     | - Hotel Agent  |
    | - Weather API   |     | - Budget Agent |
    | - Calendar      |     | - Review Agent |
    +--+---------+----+     +---+--------+---+
       |         |              |        |
       v         v              v        v
    [Flight   [Weather      [Hotel    [Budget
     Data]     Data]        Booking]   Analysis]
```

### 分层架构

把它看作分层：

1. **Tool 层（MCP）：** 你的 Agent 通过 MCP server 接到具体的数据源与 API。这层提供原始能力——查数据库、调 API、读文件。

2. **Agent 层（A2A）：** 你的 Agent 与拥有自己 tool、推理与专长的其他 Agent 协作。这层提供更高层的能力——需要判断、规划与多步执行的任务。

3. **协调层（你的 Agent）：** 你的 Agent 根据手头任务，决定何时直接调用 tool（MCP），何时委派给另一个 Agent（A2A）。

### 一个具体场景

用户对你的旅行 Agent 说：「下个月用 3000 美元预算去东京玩 3 天，帮我安排一下。」

你的 Agent 可能会：

1. **MCP 调用：** 检查用户日历，找出可行日期（calendar MCP server）
2. **MCP 调用：** 获取这些日期的当前机票价格（flight API MCP server）
3. **A2A 委派：** 让一个酒店预订 Agent 在涩谷附近找单晚低于 200 美元的住宿
4. **A2A 委派：** 让一个本地活动 Agent 给出 3 天行程建议
5. **MCP 调用：** 获取这些日期东京的天气预报（weather MCP server）
6. **推理：** 综合所有结果，对照预算，给出方案

注意这一模式：MCP 用于具体的数据获取，A2A 用于需要另一个 Agent 的专长与判断的任务。

---

## ELI5：理解 MCP 与 A2A

### MCP 像电源转接头

不同国家有不同的电源插座。如果你从美国去英国，你的笔记本充电器插不上去，需要一个转接头。

MCP 就是 AI Agent 的转接头。过去每个 tool 都有自己的专有插头（定制 API 集成）。MCP 给所有人一个通用插座。把任意 tool 接入 MCP，任意 Agent 都能用它。

tool 本身不会变聪明。电源转接头不会让笔记本更快，但能让它在原本不能用的地方也能工作。MCP 同理——它让 Agent 能触达原本触达不了的 tool。

### A2A 像同事间的电话

设想你正在公司做一个大项目。你负责工程，但需要营销素材。你不会自己学营销，而是给市场部的同事打电话。

你说：「我们下周二要发布新 API，能帮忙做一篇发布博客和社媒方案吗？」

同事说：「好，我先起草一版，过程中会跟你同步进展。」

A2A 就是这通电话。一个 Agent（你）带着目标去找另一个 Agent（市场部）。对方用自己的技能与 tool 完成它，过程中给你更新，并在做完后把成品交付给你。

你不需要知道市场部用什么 tool，也不需要了解他们的流程。你只需要描述你想要什么，并相信他们会想办法做到。

### 为什么两者都需要

回到同事的类比：

- **MCP** 像桌上的工具——键盘、显示器、代码编辑器。你直接用。
- **A2A** 像你的同事——你把工作委派给他们，他们用自己的工具完成。

两者都需要。有些事你用自己的工具自己做，有些事你交给专家来处理。

---

## 两个协议的安全考量

### MCP 安全

- **server 鉴别：** 连接 MCP server 前先校验其身份，所有通信用 TLS。
- **最小权限：** 只连接 Agent 真正需要的 MCP server。每多一个 server，攻击面就增大。
- **输入校验：** MCP server 要校验它收到的所有参数。不要假定模型总会发送格式正确的输入。
- **审计日志：** 记录所有 MCP tool 调用，便于调试与安全审查。

### A2A 安全

- **Agent 验证：** 委派任务前，通过 Agent Card 与鉴权方案校验远端 Agent 的身份。
- **数据最小化：** 只把远端 Agent 完成任务必需的信息交给它，不要把整个上下文都发过去。
- **结果校验：** 对来自远端 Agent 的结果保持适度怀疑。在采取行动前，验证关键输出。
- **访问控制：** 明确哪些 Agent 能访问你 Agent 的哪些能力。

### 纵深防御

两个协议都受益于分层安全：

1. **传输安全：** 处处 TLS
2. **鉴权：** 双方都要核实身份
3. **授权：** 限制每条连接能做什么
4. **监控：** 关注异常模式
5. **guardrails：** 在每个边界校验输入与输出

---

## 当前生态状况

### MCP 生态

MCP 自推出以来获得了快速采纳，生态包括：

- 流行服务（数据库、云平台、SaaS tool、开发工具）的 **数百个 MCP server**
- 主流 AI 平台 **支持 MCP**，包括 Claude、ADK、VS Code 等
- **不断壮大的社区** 在构建与维护 server

### A2A 生态

A2A 较新，生态仍在发展：

- **ADK 支持** 创建兼容 A2A 的 Agent，并连接远端 A2A Agent
- **参考实现** 演示常见模式
- 构建多 Agent 系统的组织 **关注度上升**

### 可以期待的发展

两个协议都在积极演进，可以期待看到：

- 更多面向企业 tool 与服务的 MCP server
- 更多 Agent 框架支持 A2A
- 更好的工具，用于发现、测试与监控协议连接
- 安全模式与最佳实践的标准化

---

## 实操贴士

### 上手 MCP 时

1. **先用官方 server。** 在尝试社区版本之前，先用受信任来源的、维护良好的官方 MCP server。
2. **先在本地测试。** 开发期先在本地跑 MCP server，再指向远端。
3. **关注 token 用量。** 每个连上的 MCP server 都会向上下文添加 tool 定义。盯紧 tool 占用的上下文空间。
4. **锁定 server 版本。** MCP server 是软件依赖。锁版本以避免意外。

### 上手 A2A 时

1. **先用你能掌控的 Agent。** 自己先构建两个 Agent，练习 A2A 通信，再连接外部 Agent。
2. **明确合同。** 清楚约定希望远端 Agent 处理什么任务、产出什么结果。
3. **优雅处理失败。** 远端 Agent 可能慢、不可用或返回意外结果。要写好重试与 fallback 逻辑。
4. **凡事记录。** 多 Agent 通信很难调试，详细日志必不可少。

---

## 关键要点

1. **协议解决 N x M 集成问题。** 没有标准时，每个 Agent–tool、Agent–Agent 组合都需要定制代码。MCP 与 A2A 用通用接口取代它们。

2. **MCP 把 Agent 接到 tool。** 它是一个通用适配器，让任何 Agent 都能用任何兼容 MCP 的 tool。AI 界的 USB。

3. **A2A 把 Agent 接到 Agent。** 它让 Agent 能跨组织、跨框架发现、通信并委派任务。

4. **MCP 与 A2A 互补。** MCP 在 tool 层（具体的函数调用）。A2A 在 Agent 层（目标导向的任务）。两者并用，灵活性最强。

5. **安全在两层都需要关注。** 校验身份、最小化数据共享、校验结果、记录一切。

---

## 进一步学习

- **MCP Tools in ADK：** [https://google.github.io/adk-docs/tools/mcp-tools/](https://google.github.io/adk-docs/tools/mcp-tools/)
- **A2A in ADK：** [https://google.github.io/adk-docs/a2a/](https://google.github.io/adk-docs/a2a/)
- **A2A Protocol Specification：** [https://a2a-protocol.org/latest/](https://a2a-protocol.org/latest/)
- **MCP Specification：** [https://modelcontextprotocol.io](https://modelcontextprotocol.io)

---

## 下一步是什么？

你已经掌握了基础与构建模块。最后一课时我们会拉远视角，看大局——从这里出发，下一步该走哪、还有哪些资源可以探索，以及如何持续成长为 Agent 构建者。

[Next: Lesson 15 - Where to Go From Here -->](/15-where-to-go-from-here/)
