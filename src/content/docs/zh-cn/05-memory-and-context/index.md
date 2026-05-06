---
title: "Lesson 5: memory 与 context — Agent 如何记忆"
---

## 你将学到什么

- context window 的工作原理及其重要性
- context engineering 作为 prompt engineering 的演进
- Agent 记忆的类型：短期、长期、程序性与陈述性
- session 如何为 Agent 提供对话连续性
- memory 与 RAG 的区别
- 什么是 context rot，以及如何应对
- 管理 context 的实用策略
- memory 存储方案：向量数据库、知识图谱与混合方案

## 前置条件

- [Lesson 2: How Agents Think](/02-how-agents-think/)
- [Lesson 4: Agentic Design Patterns](/04-agentic-design-patterns/)

---

## ELI5：把 context 想象成一张办公桌

设想你正在一张办公桌前工作。这张桌子就是 Agent 的 context window —— 你把当前正在使用的所有东西都放在上面。

桌面空间有限。你可以摊开笔记、参考书、笔记本电脑，还有一杯咖啡。但如果你不停地往上堆东西，桌面终将凌乱到什么也找不着。重要的便条会被埋在不那么相关的纸张下面。你开始忘了自己原本在做什么。

AI agent 的 context 也是一样。context window 就是 Agent 的工作台面。Agent 需要思考的一切——用户的问题、对话历史、tool 结果、指令——都得放在这张桌子上。当桌面被填满，Agent 就要决定保留什么、丢弃什么。

良好的 memory 管理就像保持桌面整洁：把重要的东西摆在显眼可取之处，把不那么关键的信息存放到稍后能找到的地方。

---

## context window 详解

### 什么是 context window？

context window 是 LLM 在单次请求中可以处理的文本总量（以 token 计算）。可以把它想象成模型的工作记忆——它一次能"看到"的全部内容。

```
+------------------------------------------------------------------+
|                        CONTEXT WINDOW                            |
|                                                                  |
|  [System instructions]                                           |
|  [Tool definitions]                                              |
|  [Conversation history - user and agent messages]                |
|  [Retrieved documents / RAG results]                             |
|  [Current user message]                                          |
|  [Agent's working thoughts]                                      |
|                                                                  |
|                    ... all must fit here ...                      |
+------------------------------------------------------------------+
```

### context window 的尺寸

context window 一直在飞速增长：

| Model | Context window |
|-------|---------------|
| GPT-3 (2020) | 4K tokens |
| GPT-4 (2023) | 128K tokens |
| Gemini 1.5 Pro | 1M tokens |
| Gemini 2.0 | 1M+ tokens |

一个 token 在英文中大约相当于 3/4 个单词。所以 100 万 token 约等于 75 万字——大约相当于 10 部小说的篇幅。

### 越大未必越好

你可能以为更大的 context window 能解决一切问题。它确实有帮助，但也有取舍：

| Factor | Small context | Large context |
|--------|--------------|---------------|
| **Cost** | 单次请求成本更低 | 单次请求成本更高 |
| **Latency** | 响应更快 | 响应更慢 |
| **Accuracy** | 聚焦、噪声更少 | 在大量文本中可能难以找出真正相关的信息 |
| **Simplicity** | 迫使你做取舍 | 容易让人把所有东西一股脑塞进去 |

研究表明，LLM 在处理放置于超长 context 中部的信息时常常表现不佳——这种现象有时被称为 "lost in the middle" 效应。能塞进 100 万 token，并不意味着*应该*这么做。

---

## 从 prompt engineering 到 context engineering

### prompt engineering：起点

prompt engineering 关注的是设计正确的输入文本，让 LLM 给出好的输出。你写一段静态 prompt，可能附上几个示例，然后发送出去。

这种方式适用于简单任务，但在 Agent 场景下就会失效。为什么？因为 Agent 处理的是动态、不断变化的信息：

- 对话历史每轮都在增长
- tool 结果在运行时才返回
- 检索到的文档因查询而异
- 用户的需求在会话中途也会变化

### context engineering：下一步

context engineering 是在合适的时机把合适的信息动态组装到 context window 中的实践。它不是一段静态 prompt，而是一个系统，由它来决定：

- **放进什么：** 此刻哪些信息相关？
- **不放什么：** 哪些可以总结、外部存储或丢弃？
- **以什么顺序：** 信息如何排列才能让模型最好地处理？
- **何时刷新：** 旧的 context 何时需要更新或替换？

把 prompt engineering 想成写一封漂亮的邮件。context engineering 则是搭建整个邮件系统。

### 为什么 context engineering 对 Agent 至关重要

```
Prompt Engineering:            Context Engineering:
+------------------+          +---------------------------+
| Static prompt    |          | System instructions       |
| + user question  |          | + Relevant memory         |
|                  |          | + Session history (pruned) |
|                  |          | + Tool schemas (selected)  |
|                  |          | + Retrieved context        |
|                  |          | + Current task state       |
|                  |          |                           |
| "Answer this"    |          | All dynamically assembled |
+------------------+          +---------------------------+
```

预订酒店的 Agent 与编写代码的 Agent 所需的 context 截然不同。即使是同一个 Agent，在任务的不同阶段也需要不同的 context。context engineering 让这种动态组装成为可能。

---

## memory 的类型

Agent 因不同目的而需要不同类型的 memory。这与人类的记忆机制相互呼应。

### 短期 memory（session/conversation）

**是什么：** 用户与 Agent 当前的对话。它直接存在于 context window 中。

**人类类比：** 你的工作记忆——你此刻正在主动思考的内容。

**特征：**
- 在一次 session 期间存在
- 随每次交互增长
- 受 context window 大小限制
- session 结束即丢失（除非被持久化）

**示例：**
```
User: "My name is Alex and I prefer dark mode."
Agent: "Got it, Alex. I will use dark mode settings."

[50 messages later]

User: "What theme am I using?"
Agent: "You are using dark mode, Alex."  <-- Only works if the earlier
                                             message is still in context
```

### 长期 memory（跨 session 持久化）

**是什么：** 存储在 context window 之外、跨 session 持久存在的信息。Agent 在相关时检索它。

**人类类比：** 你的长期记忆——即便此刻没在思考，依然记得的事实和经历。

**特征：**
- 跨 session 留存
- 外部存储（数据库、文件系统、向量库）
- 必须显式检索并加载到 context 中
- 可以无限增长

**示例用途：**
- 用户偏好（"Alex likes dark mode and uses TypeScript"）
- 过往交互（"Last week, Alex asked about deploying to Cloud Run"）
- 已学到的事实（"The production database is on us-central1"）

### 程序性 memory（如何做事）

**是什么：** 关于*如何*执行任务的知识——工作流、标准操作流程和分步流程。

**人类类比：** 知道怎么骑自行车或敲键盘。你不会去思考每一步——就是知道怎么做。

**特征：**
- 通常编码在 system instructions 或 tool 定义中
- 相对稳定——不常变化
- 包含模式、模板与标准流程

**示例：**
```
Procedural memory: "When a user reports a bug:
  1. Ask for reproduction steps
  2. Check the error logs
  3. Search for similar issues
  4. Propose a fix or workaround"
```

### 陈述性 memory（事实与知识）

**是什么：** Agent 已知或可访问的事实信息——数据、文档、规范和参考资料。

**人类类比：** 知道巴黎是法国的首都。一个你能陈述的事实，而非你执行的技能。

**特征：**
- 可通过 RAG 动态检索
- 包含文档、数据库与知识库
- 可能过时，需要更新

### memory 类型小结

| Memory type | Duration | Location | Updated how | Example |
|------------|----------|----------|-------------|---------|
| **Short-term** | 一次 session | context window | 自动（对话增长） | 当前的对话消息 |
| **Long-term** | 跨 session | 外部存储 | 由 Agent 或系统显式更新 | 用户偏好 |
| **Procedural** | 永久 | system prompt / 配置 | 由开发者更新 | 工作流指令 |
| **Declarative** | 视情况而定 | 知识库 / RAG | 由数据 pipeline 更新 | 产品文档 |

---

## session：对话的容器

session 是承载用户与 Agent 之间对话的容器。session 为 Agent 提供连续性——记住此次交互中已经发生过的事情。

### session 里有什么？

```
Session
+-----------------------------------------------+
| Session ID: abc-123                           |
| User ID: user-456                             |
| Created: 2025-01-15T10:30:00Z                |
|                                               |
| Events:                                       |
|   [User message: "Help me plan a trip"]       |
|   [Agent message: "Where would you like..."]  |
|   [User message: "Tokyo, 5 days"]             |
|   [Tool call: flight_search(dest="Tokyo")]    |
|   [Tool result: {flights: [...]}]             |
|   [Agent message: "I found several..."]       |
|                                               |
| State:                                        |
|   destination: "Tokyo"                        |
|   duration: "5 days"                          |
|   budget: null                                |
+-----------------------------------------------+
```

### session 与 state

- **Session：** 一次对话中所有事件（消息、tool call、结果）的完整历史。
- **State：** 从 session 中抽取的关键信息的结构化摘要。可以把它视为 Agent 的便签。

state 之所以有用，是因为它让 Agent 能够快速访问关键事实，而不必重新通读整个对话历史。

### Google Cloud 中的 session 管理

Google Cloud 通过 Agent Development Kit (ADK) 与 Vertex AI 提供 session 管理：

- **ADK Sessions：** [ADK session 系统](https://google.github.io/adk-docs/sessions/) 内置 session 管理，支持事件追踪与 state。
- **Vertex AI Sessions：** [Vertex AI Agent Engine sessions](https://cloud.google.com/agent-builder/agent-engine/sessions/overview) 提供托管的 session 存储，并自动扩缩。

它们处理 session 存取的基础设施，让你专注于 Agent 逻辑。

---

## memory 与 RAG

memory 与 Retrieval-Augmented Generation (RAG) 相关但用途不同。工程师常常把两者混淆。

### 私人助理 vs. 图书馆

**Memory** 就像有一位私人助理，记得你的偏好、日程和过往对话。Ta 了解*你*。

**RAG** 就像可以使用一座图书馆。当你需要某个事实时，你去查阅。图书馆并不认识你——只是有大量信息可供查询。

### 并排对比

| Aspect | Memory | RAG |
|--------|--------|-----|
| **存储什么** | 与用户、交互相关的特定数据 | 通用知识、文档、数据 |
| **关于谁** | 这个用户、这个 Agent、这段 context | 任何人——共享的知识 |
| **何时写入** | 在 Agent 交互过程中 | 在数据导入时（通常离线） |
| **何时读取** | 在 session 开始时或进行中 | 在 Agent 需要特定信息时 |
| **个性化** | 高——为该用户定制 | 低——对所有人一致 |
| **示例** | "This user prefers concise answers" | "The API rate limit is 100 requests/minute" |

### 它们如何协同

实际上，Agent 同时使用两者：

```
User: "Remind me, what was that deployment issue we had last month?"

Agent:
  1. Check MEMORY: "This user works on the payments team and
     had a Cloud Run deployment failure on Jan 3."
  2. Use RAG: Search incident reports for "Cloud Run deployment
     failure January" to get specific details.
  3. Combine: "Last month you had a Cloud Run deployment failure
     related to a misconfigured service account. Here are the
     details from the incident report..."
```

memory 告诉 Agent *该找什么*。RAG 提供*详细信息*。

我们将在 [Lesson 8: Agentic RAG](/08-agentic-rag/) 中深入讨论 RAG。

---

## context rot

### 什么是 context rot？

context rot 是指 context window 被逐渐填满时，关键信息被丢失、稀释或淹没的现象。Agent "忘记"重要内容——并非因为信息被删除，而是因为它已经不在模型关注的那部分 context 中。

### 凌乱办公桌的类比

还记得那张办公桌的类比吗？context rot 就发生在你的桌面凌乱到这种地步：写着数据库密码的关键便利贴被一摞会议笔记掩埋。便利贴严格来说还在桌上，但你需要时却找不到。

### context rot 是怎么发生的

1. **冗长的对话。** 每一轮都会向 context 添加消息。50 多轮之后，靠前的消息距离模型关注区域已经很远。

2. **冗长的 tool 结果。** 一个 tool 返回了庞大的 JSON 块。其中大部分无关紧要，却占用了宝贵的 context 空间。

3. **指令累积。** system instructions、few-shot 示例和 guardrails 占用了本可以容纳用户相关信息的空间。

4. **重复内容。** 相似的消息或结果不断堆积而未被合并。

### context rot 的迹象

- Agent "忘记"了用户在对话早期告诉它的事情
- Agent 与早前的陈述或决定自相矛盾
- session 早期的 tool 结果被忽略
- Agent 反复询问用户已经提供的信息

---

## 管理 context 的策略

### 1. 滑动窗口

**工作方式：** 只在 context 中保留最近的 N 条消息。更早的消息被丢弃。

```
Window size: 10 messages

Messages 1-5:   [dropped]
Messages 6-15:  [in context]
Message 16:     [new message arrives, message 6 gets dropped]
```

**优点：** 实现简单，内存占用可预测。

**缺点：** 会丢失重要的早期 context。用户可能会引用第 2 条消息中的内容，而它已经不在窗口里。

**适用场景：** 以最近 context 为主的休闲对话型 Agent。

### 2. 摘要化

**工作方式：** 周期性地把较早的对话轮次摘要化，并用摘要替换原始消息。摘要占用的空间远小于原始消息。

```
Before summarization:
  [20 detailed messages about trip planning]  -> 4,000 tokens

After summarization:
  [Summary: "User is planning a 5-day trip to Tokyo with a budget
   of $3,000. They prefer boutique hotels and want to visit temples
   and try local food. Flights are booked for March 15-20."]  -> 200 tokens
```

**优点：** 在节省空间的同时保留关键信息。

**缺点：** 摘要化可能丢失细节。负责摘要的 Agent 可能错过重要内容。

**适用场景：** 历史 context 重要的长时运行 session。

### 3. 基于 token 的截断

**工作方式：** 为 context 的每个部分（system instructions、conversation history、tool results）设置 token 预算，超出预算时进行截断。

```
Total budget: 32,000 tokens
  System instructions:     4,000 tokens (fixed)
  Tool definitions:        2,000 tokens (fixed)
  Conversation history:   20,000 tokens (sliding)
  Current turn:            6,000 tokens (reserved)
```

**优点：** 对 context 分配的细粒度控制。确保始终有空间留给当前任务。

**缺点：** 需要仔细调参。硬性边界可能在消息中途被切断。

**适用场景：** 需要可预测成本与延迟的生产级 Agent。

### 4. 基于重要性的筛选

**工作方式：** 根据每条 context 与当前任务的相关性打分，仅保留最相关的项目。

```
Current task: "Book a hotel in Tokyo"

High relevance (keep):
  - User's destination: Tokyo
  - User's dates: March 15-20
  - User's budget: $3,000
  - User's hotel preferences: boutique

Low relevance (drop):
  - Discussion about restaurant recommendations
  - Earlier conversation about flight options (already booked)
```

**优点：** 最大化 context 的信噪比。

**缺点：** 相关性打分并不完美。Agent 可能丢弃后来证明很重要的内容。

**适用场景：** 多种 context 类型争夺空间的复杂 Agent。

### 5. 外部化与检索

**工作方式：** 将信息存储在外部 memory（数据库、向量库或知识图谱）中，仅在需要时检索。

```
Instead of keeping everything in context:

  User preferences -> stored in user profile database
  Past conversations -> stored in conversation archive
  Reference docs -> stored in vector database

When needed:
  Agent queries the relevant store and loads just the
  pieces it needs into the current context.
```

**优点：** 存储几乎无上限。只有相关信息才会进入 context。

**缺点：** 检索引入延迟。检索质量取决于搜索系统。

**适用场景：** 需要访问大量信息但任意时刻只用其中很小一部分的 Agent。

### 策略对比

| Strategy | Context savings | Information loss risk | Complexity | Latency impact |
|----------|----------------|----------------------|------------|---------------|
| Sliding window | High | High | Low | None |
| Summarization | High | Medium | Medium | Some (summarization step) |
| Token truncation | Medium | Medium | Medium | None |
| Importance selection | High | Medium | High | Some (scoring step) |
| Externalize + retrieve | Very high | Low | High | Higher (retrieval step) |

---

## memory 存储方案

外部化 memory 后，需要选择放在哪里。下面是主要的几种方案。

### 向量数据库

**作用：** 将信息存储为数学向量（embeddings），并通过相似度进行检索。

**工作方式：**
1. 用 embedding 模型把文本转换成向量
2. 把向量与原文一同存储
3. 检索时，把查询转换成向量
4. 找出与查询向量最相似的存储向量

**适用：** 查找语义相近的内容。"What did we discuss about deployment?" 即便措辞不同，也能匹配到过往关于部署的对话。

**示例：** Vertex AI Vector Search、Pinecone、Weaviate、ChromaDB

**取舍：**
- 擅长语义相似度搜索
- 对精确匹配或结构化查询效果较差
- embedding 质量影响检索质量

### 知识图谱

**作用：** 把信息存储为图结构中的实体与关系。

**工作方式：**
```
[User: Alex] --works_on--> [Project: Payments API]
[Project: Payments API] --deployed_on--> [Platform: Cloud Run]
[User: Alex] --prefers--> [Theme: Dark Mode]
```

**适用：** 表达实体间的结构化关系。"Who works on the Payments API?" 或 "What platform is the Payments API deployed on?"

**示例：** Neo4j、Amazon Neptune、Google Cloud's Knowledge Graph

**取舍：**
- 极擅长关系查询
- 需要 schema 设计与维护
- 对非结构化文本不太自然

### 混合方案

实践中，许多系统会同时使用：

- **向量数据库** 用于非结构化 memory（对话、文档、笔记）
- **知识图谱** 用于结构化 memory（关系、事实、偏好）
- **键值存储** 用于 session 状态和快速查找

```
"What does Alex prefer?"
  -> Key-value store: {theme: "dark", language: "TypeScript"}

"What did Alex and I discuss about deployments?"
  -> Vector search: [similar past conversations about deployments]

"What services does Alex's team own?"
  -> Knowledge graph: Alex -> team -> services -> dependencies
```

### 选择存储方案

| Need | Best approach |
|------|--------------|
| 对话的语义搜索 | 向量数据库 |
| 用户偏好与设置 | 键值存储 |
| 实体关系 | 知识图谱 |
| 最近的 session 历史 | 内存 / session 存储 |
| 文档检索 | 向量数据库 + 元数据过滤 |
| 复杂的多跳查询 | 知识图谱 |

---

## 整合在一起

下面展示 memory 与 context 如何融入 Agent 架构：

```
                         +-------------------+
                         |   User Message    |
                         +--------+----------+
                                  |
                                  v
                    +-------------+-------------+
                    |   Context Engineering     |
                    |   Layer                   |
                    |                           |
                    |  1. Load system prompt    |
                    |  2. Retrieve relevant     |
                    |     memory                |
                    |  3. Load session history  |
                    |     (pruned/summarized)   |
                    |  4. Add tool definitions  |
                    |  5. Include current       |
                    |     message               |
                    +-------------+-------------+
                                  |
                         Assembled context
                                  |
                                  v
                         +--------+----------+
                         |       LLM         |
                         +--------+----------+
                                  |
                          Agent response
                                  |
                                  v
                    +-------------+-------------+
                    |   Memory Update Layer     |
                    |                           |
                    |  1. Save to session       |
                    |  2. Extract key facts     |
                    |     for long-term memory  |
                    |  3. Update user profile   |
                    +---------------------------+
```

context engineering 层在 LLM 看到 context *之前*完成组装。memory 更新层在 LLM 响应*之后*抽取重要信息。两者协同，让 Agent 既能记住，又能保持专注。

---

## 关键要点

1. **context window 就是 Agent 的工作记忆。** Agent 思考的所有内容都必须放在这块空间内。把它管好至关重要。

2. **context engineering 超越了 prompt engineering。** Agent 需要的是 context 的动态组装，而非一段静态 prompt。进入 context window 的内容应当随情境而变。

3. **Agent 需要多种类型的 memory。** 短期 memory 服务于当前对话，长期 memory 跨 session 持久化，程序性 memory 表达"如何做事"，陈述性 memory 承载事实。

4. **session 提供对话连续性。** 它跟踪交互的历史与状态，让 Agent 能够维持连贯的对话。

5. **memory 与 RAG 用途不同。** memory 是个人化的、与具体交互相关；RAG 用于访问通用知识。多数 Agent 两者都需要。

6. **context rot 是真实存在的问题。** 随着 context 增长，重要信息会被掩埋。通过摘要、裁剪和外部存储进行主动管理，能让 Agent 保持高效。

7. **根据访问模式选择存储。** 向量数据库用于语义搜索，知识图谱用于关系，键值存储用于快速查找。混合方案往往最有效。

---

## 延伸阅读

- [ADK Sessions documentation](https://google.github.io/adk-docs/sessions/)
- [Vertex AI Agent Engine - Manage Sessions](https://cloud.google.com/agent-builder/agent-engine/sessions/overview)
- [Vertex AI Vector Search](https://cloud.google.com/vertex-ai/docs/vector-search/overview)
- [Google Cloud AI codelabs](https://codelabs.developers.google.com/?cat=AI)

---

**下一课：** [Planning and Reasoning - How Agents Tackle Complex Tasks](/06-planning-and-reasoning/)
