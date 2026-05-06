---
title: "Lesson 17: MCP 专题深入 — 把 Agent 接到真实世界"
---

## 引言

在 [Lesson 14](/14-agent-protocols-mcp-and-a2a/) 中，我们高层介绍了 MCP（Model Context Protocol）与 A2A。本课时专门深入 MCP——它在底层原理上如何工作、何时它能带来真正价值、何时更简单的方法更好，以及如何思考它的安全性。

我们也会触及当下 AI 工程社区争论最激烈的问题之一：什么时候应该用 MCP server，什么时候直接让 Agent 用 CLI tool 就好？

### ELI5：把 MCP 想成带安全功能的插线板

你的笔记本可以直接插墙上插座，在家里没问题。但在一个有 50 台设备的办公室，你会想要一个带浪涌保护、独立开关与断路器的插线板。MCP 就是这个插线板——它在 Agent 与所用 tool 之间加了一层管理。是否需要这一层，取决于你有多少 tool、谁在用，以及你需要多少控制力。

> **关键要点：** MCP 是把 Agent 接到外部 tool 与数据的强大协议，但在成本与复杂度上有真实取舍。理解 MCP 何时增加价值、何时简单方案更优，是 Agent 构建者的关键技能。

---

## MCP 架构 —— 底层原理

MCP 采用 client-server 架构，包含三种角色：

### 三种角色

```
+------------------+     +------------------+     +------------------+
|                  |     |                  |     |                  |
|   MCP Host       |     |   MCP Client     |     |   MCP Server     |
|   (Your app)     |---->|   (Protocol      |---->|   (Tool          |
|                  |     |    handler)       |     |    provider)     |
|                  |     |                  |     |                  |
+------------------+     +------------------+     +------------------+
```

- **Host** —— Agent 运行所在的应用（Claude Desktop、IDE、你的自定义应用）。它创建并管理 MCP client。
- **Client** —— 处理协议通信。维护与单个 MCP server 的 1:1 连接，管理能力协商与消息路由。
- **Server** —— 向 client 暴露 tool、resource 与 prompt。每个 server 通常包装一个具体服务（数据库、API、文件系统）。

### 通信

所有消息都使用 JSON-RPC 2.0。协议支持两种传输方式：

| 传输 | 适用场景 | 工作方式 |
|-----------|----------|-------------|
| **stdio** | 本地 tool | server 作为子进程运行，通过 stdin/stdout 通信。简单、快、无网络开销。 |
| **Streamable HTTP** | 远端 tool | 使用单一 HTTP 端点，双向通信。支持 serverless 部署（Lambda、Cloud Functions）。 |

注意：原先的 SSE（Server-Sent Events）传输已在 2025 年 3 月规范修订中弃用。SSE 是单向的，需要两个端点。Streamable HTTP 用单端点、双向设计取代了它。

### MCP 原语

MCP server 可以暴露三类能力：

| 原语 | 是什么 | 由谁掌控 | 示例 |
|-----------|-----------|----------------|---------|
| **Tools** | Agent 可调用的函数 | 模型决定何时使用 | `query_database`、`send_email`、`create_file` |
| **Resources** | Agent 可读的数据 | 由应用或用户选择 | 数据库 schema、文件内容、API 文档 |
| **Prompts** | 可复用的 prompt 模板 | 由用户调用 | "Summarize this codebase"、"Review this PR" |

实践中，Tools 是最广泛使用的原语。截至 2025 年底，99% 的 MCP client 支持 Tools，而 Resources 与 Prompts 的采用率约为 30–35%。

---

## MCP vs. CLI 之争

这是当下 AI 工程领域讨论最活跃的话题之一。核心问题：如果一个 AI agent 能跑 shell 命令，为什么还需要 MCP？

### 支持 CLI 的论点

很多 MCP server 只是已经拥有优秀 CLI 的 tool 的薄包装。GitHub MCP Server 重新实现了 `gh` 已有的功能；Docker MCP Server 包装了 `docker` 命令；Kubernetes MCP Server 包装了 `kubectl`。

LLM 已经知道怎么用这些 CLI——它们在数百万 man page、Stack Overflow 回答和 GitHub 仓库上训练过。Agent 用 `gh pr list` 时，调用的是已有的知识；用 MCP server 时，则要先把 tool schema 加进 context window。

数字差异很惊人：

| 指标 | CLI 方式 | MCP 方式 |
|--------|-------------|-------------|
| **token 成本（简单查询）** | ~1,400 tokens | ~44,000 tokens（多 32 倍） |
| **初始化成本** | 接近零 | 加载 schema 可达 50,000+ tokens |
| **可靠性（基准）** | 100% | 72% |
| **所需配置** | 无（tool 已安装） | 安装并配置 MCP server |

token 成本差异源于 MCP 需要把完整的 tool schema（名称、描述、参数类型、返回类型）加进 context window。一个有 106 个 tool 的数据库 MCP server 仅初始化就要消耗 54,600 tokens——还没开始干活。

### 支持 MCP 的论点

让 MCP 显得昂贵的属性，正是让它可治理的属性：

**安全与鉴权。** CLI tool 以用户的环境权限运行。如果 Agent 能跑 `rm -rf /`，它一旦决定就会跑。MCP 提供权限边界。规范要求基于 HTTP 的 server 使用 OAuth 2.1 + PKCE，提供标准化的鉴权、token 轮换与撤销。

**多用户环境。** 当 Agent 代表你行动时，CLI 的环境安全足够了。但当 Agent 代表他人行动——读他们的仓库、写他们的 Jira、给他们的 Slack 发消息——你就需要按用户鉴权、作用域权限与审计追踪。MCP 为此提供了框架。

**tool 发现。** MCP server 通过 schema 公布自己的能力。Agent 无需事先被告知就能在运行时发现可用 tool。当 tool 发生变化或不同用户能访问不同 tool 时，这一点尤为重要。

**结构化 I/O。** MCP tool 的输入输出有类型。CLI 输出是非结构化文本，Agent 必须解析。简单 tool 还好，但对响应是嵌套 JSON 的复杂 API，结构化输出更可靠。

### 何时用哪个

| 情境 | 推荐方式 | 原因 |
|-----------|---------------------|-----|
| 开发者本地工作 | CLI | 零配置、Agent 已熟悉、最便宜 |
| 知名工具（git、docker、kubectl、jq） | CLI | LLM 训练数据强、解析可靠 |
| 单用户 Agent | CLI | 环境权限可接受 |
| 多用户 / 多租户 | MCP | 需要按用户鉴权与作用域权限 |
| 有审计要求的企业 | MCP | 需要结构化日志与访问控制 |
| 高频且范围窄的 tool 集 | MCP | schema 成本被多次调用摊平 |
| tool 面广但偶尔使用 | CLI | 避免为很少用的 tool 付出 schema 成本 |
| 自研内部 API、没有 CLI | MCP | 没有现成 CLI 可借力 |
| 频繁变化的 tool | MCP | 动态发现自动跟上变化 |

### 实务上的答案

大多数生产系统两者并用。例如 Claude Code 既有用于直接 CLI 访问的 Bash tool，也支持 MCP server。决策是按集成而定，而非系统级一刀切。

合理的默认：**先用 CLI。当你遇到 MCP 能解决的具体瓶颈时再加 MCP**——通常是鉴权、多租户或结构化 tool 发现。

### mcp2cli：搭桥工具

有一个有意思的工具 [mcp2cli](https://github.com/knowsuchagency/mcp2cli)，能在运行时把任意 MCP server 转成 CLI。它不在前期把所有 tool schema 都加载进来，而是仅在需要时让 Agent 查询 `--list` 与 `--help`。基准测试中，它在保留 MCP 结构化 API 的同时实现了 96–99% 的 token 减少。

---

## MCP 安全 —— 可能出错的地方

MCP 引入了新的攻击面。OWASP 基金会发布了 [MCP Top 10](https://owasp.org/www-project-mcp-top-10/) 安全风险清单。下面这些对 Agent 构建者最重要：

### 1. Tool poisoning

恶意或被攻陷的 MCP server 会返回被篡改的结果。如果 Agent 不加校验地相信 tool 输出，就可能被引导去做有害操作。

**缓解：** 校验 tool 输出。关键决策使用多源信息。实现输出过滤。

### 2. Tool shadowing

恶意 tool 模仿合法 tool。如果 Agent 同时能访问名字相近的两个 tool——比如来自可信 server 的 `query_database` 和来自不可信 server 的 `query_db`——它可能用错。

**缓解：** 控制 Agent 可连接的 MCP server。审阅 tool 名称与描述。对 tool 访问使用 allowlist。

### 3. 权限过大

MCP 没有原生的范围限制。一个数据库 MCP server 可能同时暴露读写操作。如果 Agent 只需要读，它仍然能写。

**缓解：** 构建或选用只暴露所需操作的 MCP server。在 server 端实现访问控制。在 MCP server 前面加 API gateway（如 Apigee）做细粒度权限管理。

### 4. context window 膨胀

太多 MCP tool 会拖累 Agent 表现。每个 tool 定义都消耗上下文 token。一个有 100+ tool 的 server，在真正干活前就会吃掉很大一部分 context window。

**缓解：** 控制单个 server 的 tool 数（在 20 个以下）。多个聚焦的 server 优于一个超大 server。考虑对 tool schema 做懒加载。

### 5. 密钥泄漏

对 5,200 个开源 MCP server 的分析表明，超过半数依赖长期不变的静态 API key。只有约 8.5% 使用 OAuth 这类现代鉴权。

**缓解：** 使用短期、作用域明确的凭据。把密钥存放在 secret manager（如 Google Cloud Secret Manager），不要放环境变量或配置文件。定期轮换凭据。

### MCP 部署的安全清单

- [ ] 审计 Agent 连接的 MCP server
- [ ] 检查 tool schema 的权限是否过宽
- [ ] 远端 MCP server 使用 OAuth 2.1
- [ ] 把密钥放进 secret manager，而不是环境变量
- [ ] 在采取行动前校验并清洗 tool 输出
- [ ] 限制每个 server 的 tool 数量
- [ ] 记录所有 tool 调用以便审计
- [ ] 使用对抗性输入做测试（tool poisoning、通过 tool 结果注入 prompt）
- [ ] 企业级 MCP 部署使用 API gateway
- [ ] 尽量在 sandbox 环境中运行 MCP server

---

## Google Cloud 上的 MCP

Google Cloud 提供多个与 MCP 的集成点：

### ADK 与 MCP

Google 的 Agent Development Kit (ADK) 内置了对 MCP tool 的支持。你可以连接到任何 MCP server，并在 ADK Agent 中使用其 tool。

具体配置 MCP tool 的方法见 [ADK MCP Tools 文档](https://google.github.io/adk-docs/tools/mcp-tools/)。

### Apigee 作为 MCP 网关

对企业部署，[Apigee](https://cloud.google.com/apigee) 可以充当 MCP 的 API 与 Agent 网关。它带来：

- 限流与配额管理
- 鉴权与授权策略
- 分析与监控
- tool 注册与发现
- 跨多个 MCP server 的流量管理

当多个团队部署 MCP server 且需要集中治理时，这一点尤其有用。

### Model Armor

[Model Armor](https://cloud.google.com/security/products/model-armor) 可对流经 MCP tool 调用的输入与输出进行过滤与校验，针对 prompt injection 与通过 tool 交互泄漏数据提供额外防护。

---

## 构建 MCP server —— 关键决策

如果你决定为自己的服务构建 MCP server，下面是关键决策点：

### 传输选择

| 问题 | stdio | Streamable HTTP |
|----------|-------|----------------|
| server 是否与 Agent 同一台机器？ | 是 | 都行 |
| 需要远端访问吗？ | 否 | 是 |
| 需要 serverless 部署吗？ | 否 | 是 |
| 延迟是否关键？ | 是 | 没那么关键 |

### tool 粒度

倾向细粒度而非粗粒度的 tool：

- 好：`get_user_by_id`、`list_users`、`create_user`、`update_user_email`
- 差：`manage_users`（一个根据模式参数处理一切的 tool）

细粒度 tool 给 LLM 更清晰的选择，效果更好。但保持总量可控——5–20 个 tool 是个不错的范围。

### 命名与描述

tool 名称与描述是 LLM 决定调用哪个 tool 的主要依据。请认真打磨：

- 名字应描述动作：`search_documents_by_topic` 而非 `search`
- 描述应说明何时使用、返回什么、有哪些重要约束
- 参数描述应包含类型、有效范围与示例
- 错误消息应帮助 LLM 恢复："User not found. Try searching by email instead of ID."

### 输出设计

让 tool 输出保持精简。输出会进入 Agent 的 context window，过大的响应会吃掉预算。

- 只返回 Agent 做下一步决策所需的内容
- 大结果集做分页
- 总结，而不是直接倾倒原始数据
- 使用结构化格式（JSON）便于机器解析

---

## 综合一下 —— 一棵决策树

当你要决定如何把 Agent 接到外部服务时：

```
Do you need to connect to an external service?
|
+-- Is there a well-known CLI for it? (git, docker, aws, gcloud, kubectl)
|   |
|   +-- Yes: Does the agent need multi-user auth or audit trails?
|   |   |
|   |   +-- No: Use the CLI directly
|   |   +-- Yes: Use MCP with OAuth
|   |
|   +-- No: Continue below
|
+-- Is there an existing MCP server for it?
|   |
|   +-- Yes: Is it actively maintained and from a trusted source?
|   |   |
|   |   +-- Yes: Use the MCP server
|   |   +-- No: Consider building your own or using CLI/API directly
|   |
|   +-- No: Continue below
|
+-- Does the service have a REST API?
    |
    +-- Yes: Build an MCP server or use ADK OpenAPI tools
    +-- No: Build a custom function tool or MCP server
```

---

## 关键要点

- MCP 提供带 schema、鉴权与发现的结构化 tool 集成——但有 token 成本
- 对于知名开发者 tool，CLI 更便宜，往往也更可靠
- 决策是按集成而定的，而非整套系统统一——大多数生产 Agent 同时使用 MCP 与 CLI
- 默认从 CLI 起步；当需要鉴权、多租户或 tool 发现时再加 MCP
- MCP 安全需要主动关注——审计 server、限制权限、校验输出
- 在 Google Cloud 上，ADK 原生支持 MCP，Apigee 可作为企业级 MCP 网关
- 让 MCP server 保持聚焦：每个 server 5–20 个描述清晰的 tool、精简输出、明确的错误消息

---

## 延伸阅读

- [MCP Specification](https://modelcontextprotocol.io/)
- [ADK MCP Tools](https://google.github.io/adk-docs/tools/mcp-tools/)
- [OWASP MCP Top 10](https://owasp.org/www-project-mcp-top-10/)
- [Agentic AI Foundation (AAIF)](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation)
- [mcp2cli - Bridge MCP to CLI](https://github.com/knowsuchagency/mcp2cli)
- [Google Cloud Apigee](https://cloud.google.com/apigee)

---

[Previous Lesson: AGENTS.md](/16-agents-md/) | [Next Lesson: Agent Skills ->](/18-agent-skills/)
