---
title: "Lesson 6: planning 与 reasoning — Agent 如何应对复杂任务"
---

## 你将学到什么

- 为什么 planning 对处理复杂任务的 Agent 至关重要
- agentic 问题求解循环：Get Mission、Scan Scene、Think、Act、Observe
- 先规划后执行 vs. 反应式方法及各自的取舍
- 用层级化 planning 把大任务拆成可管理的部分
- 重新规划：Agent 如何在出问题时调整
- 推理技术：Chain-of-Thought、Tree-of-Thoughts 与 self-consistency
- orchestrator 层在管理计划中的角色
- 常见失败模式及其规避方法

## 前置条件

- [Lesson 2: How Agents Think](/02-how-agents-think/)
- [Lesson 4: Agentic Design Patterns](/04-agentic-design-patterns/)
- [Lesson 5: Memory and Context](/05-memory-and-context/)

---

## ELI5：planning 就像为旅行打包

设想你要为一次两周的旅行打包。你大可以随手抓东西塞进行李箱。运气好的话，需要的东西都齐了；更可能的情况是，你忘了牙刷，却装了三件根本不会穿的外套。

更好的做法：先想清楚要去哪儿、天气如何、有什么活动安排，*然后*列一份打包清单。逐项装入并打勾。如果中途发现行李塞不下了，就重新排优先级——舍弃"以防万一"的物件，留下必需品。

这正是 planning 为 AI agent 所做的事。Agent 不再盲目地对每一步做出反应，而是提前思考、制定计划、有条理地推进。当计划碰到麻烦时，好的 Agent 会调整，而不是抱着失败的方案硬冲。

---

## 为什么 planning 重要

简单任务不需要 planning。如果有人问"现在几点？"，Agent 直接看时钟即可，不需要计划。

但考虑这样的请求："Research the top 5 competitors in the cloud database market, compare their pricing and features, and write a recommendation for which one we should use for our new project."

这个任务需要：
- 找出竞品有哪些
- 调研每一家（定价、特性、限制）
- 理解用户的项目需求
- 将各选项与需求比较
- 把所有内容综合成一份推荐

没有 planning，Agent 可能在第一家竞品上钻得太深，耗尽 context 空间，结果忘了覆盖另外四家；或者在没有充分调研的情况下直接跳到推荐结论。

planning 给 Agent 一张路线图。它知道目的地在哪里，下一步做什么，以及如何分配时间和资源。

### planning 带来什么

| Benefit | Without planning | With planning |
|---------|-----------------|---------------|
| **Task completion** | 可能漏步骤或卡住 | 系统性覆盖所有步骤 |
| **Resource efficiency** | 在岔路上浪费 token | 把精力分配到关键处 |
| **Transparency** | 难以看清 Agent 在做什么 | 进度清晰可追踪 |
| **Error recovery** | 出问题时容易迷失 | 可定位到出问题的环节并调整 |
| **Parallelism** | 一切串行 | 互不依赖的步骤可以并发 |

---

## agentic 问题求解循环

每个 planning Agent 的核心都是一个问题求解循环。不同框架的描述各异，但核心步骤是一致的：

### Get mission -> scan scene -> think -> act -> observe

```
+-------------------------------------------------------------------+
|                                                                   |
|   +------------+     +------------+     +---------+               |
|   | Get Mission| --> | Scan Scene | --> |  Think  |               |
|   +------------+     +------------+     +----+----+               |
|                                              |                    |
|                                              v                    |
|                        +---------+     +-----+-----+              |
|                        | Observe | <-- |    Act     |             |
|                        +----+----+     +-----------+              |
|                             |                                     |
|                             v                                     |
|                      +------+------+                              |
|                      | Goal met?   |                              |
|                      | Yes -> Done |                              |
|                      | No -> Think |                              |
|                      +-------------+                              |
|                                                                   |
+-------------------------------------------------------------------+
```

### 一步一步

**1. Get Mission**

Agent 接收任务。可能来自用户请求、触发事件，或来自另一个 Agent 委派的子任务。

```
Mission: "Create a summary report of our team's GitHub activity this week."
```

**2. Scan Scene**

Agent 收集当前情境的 context。有哪些 tool 可用？已经掌握了哪些信息？存在哪些约束？

```
Available tools: github_api, document_writer, calendar_api
Known context: Team = "platform-eng", Current date = March 15
Constraints: Report should be under 2 pages
```

**3. Think**

Agent 推理下一步要做什么。这就是 planning 发生的地方——Agent 衡量选项并决定行动方向。

```
Thought: "I need to:
  1. Get the list of team members
  2. For each member, fetch their commits, PRs, and reviews this week
  3. Aggregate the data
  4. Write a summary highlighting key contributions
  I will start by getting the team member list."
```

**4. Act**

Agent 执行一个动作——调用 tool、生成文本或做出决策。

```
Action: github_api.get_team_members(team="platform-eng")
```

**5. Observe**

Agent 检查动作的结果。是否成功？提供了什么信息？计划需要调整吗？

```
Observation: Team has 8 members: [alice, bob, carol, dave, eve, frank, grace, hank]
```

随后循环回到 **Think**，Agent 基于观察结果决定下一步。如此往复，直到任务完成。

---

## 先规划后执行 vs. 反应式方法

Agent 处理任务有两种基本理念。多数实际 Agent 是两者混合，但理解纯粹形式有助于做设计决策。

### 先规划后执行

**工作方式：** Agent 在采取任何动作之前，先制定一份完整（或接近完整）的计划，然后逐步执行。

```
User: "Migrate our application from Python 2 to Python 3."

Planning phase:
  Step 1: Audit codebase for Python 2-specific syntax
  Step 2: Identify incompatible dependencies
  Step 3: Update dependencies to Python 3-compatible versions
  Step 4: Convert print statements to print functions
  Step 5: Fix string/unicode handling
  Step 6: Update integer division operators
  Step 7: Run test suite and fix failures
  Step 8: Update CI/CD pipeline to use Python 3

Execution phase:
  [Execute steps 1-8 in order]
```

**优点：**
- 结构清晰，进度可追踪
- 可在前期识别步骤间的依赖
- 支持互不相干的步骤并行执行
- 易于估算总投入与沟通进度

**缺点：**
- 计划可能错误或不完整（你不知道你不知道的事）
- 僵化——难以适应突发情况
- 前期规划耗时间和 token
- 简单任务上可能过度规划

### 反应式方法

**工作方式：** Agent 一步一步来。它观察当前情境，决定最佳的下一步动作，执行后再评估。这本质上就是 [Lesson 4](/04-agentic-design-patterns/) 中介绍的 ReAct 模式。

```
User: "Migrate our application from Python 2 to Python 3."

Step 1:
  Think: "First, I should understand the codebase. Let me scan for Python 2 syntax."
  Act: Search for Python 2 patterns
  Observe: Found 47 print statements, 12 unicode issues, 3 deprecated imports

Step 2:
  Think: "The print statements are the most common issue. Let me start there."
  Act: Convert print statements
  Observe: 47 print statements converted

Step 3:
  Think: "Now let me tackle the unicode issues..."
  [continues step by step]
```

**优点：**
- 高度自适应——根据实际发现做出反应
- 没有浪费的规划成本
- 适合探索性任务
- 天然能处理意外情况

**缺点：**
- 缺少全局进度视角
- 可能漏掉前期规划本可发现的关键步骤
- 难以并行——每一步都依赖上一步的观察
- 没有指导计划，容易跑偏

### 务实的折中

大多数生产级 Agent 采用混合方式：

1. **轻量前期规划：** 制定一个粗略的高层计划（3-7 步）
2. **反应式执行：** 在每一步内部使用 ReAct 风格推理
3. **周期性重规划：** 在重大步骤之后重新评估并调整计划

```
High-level plan (light):
  1. Audit the codebase
  2. Fix syntax issues
  3. Update dependencies
  4. Run tests and fix failures

Executing step 1 (reactive):
  Think -> Act -> Observe -> Think -> Act -> Observe -> Step complete

Re-plan after step 1:
  "The audit revealed more issues than expected. Adding step 2b for
   database migration code that uses a deprecated library."
```

这样既有 planning 的结构，又有反应式执行的适应性。

### 何时偏向哪种方法

| Situation | Favor planning | Favor reactive |
|-----------|---------------|----------------|
| 任务已被充分理解 | Yes | |
| 任务为探索性 | | Yes |
| 多个互不依赖的子任务 | Yes | |
| 对将要发现的内容高度不确定 | | Yes |
| 需要沟通进度 | Yes | |
| 速度比彻底性更重要 | | Yes |
| 失败代价高 | Yes | |
| 任务简单（少于 3 步） | | Yes |

---

## 层级化 planning

### 把大任务拆成小任务

有些任务过于复杂，无法在一份扁平清单里规划完。层级化 planning 把一个大目标分解为子目标，再细分为子子目标——就像项目管理中的工作分解结构。

### 项目管理类比

想想软件项目通常如何组织：

```
Epic: Launch new payment system
  |
  +-- Story: Design payment API
  |     +-- Task: Define endpoints
  |     +-- Task: Design data models
  |     +-- Task: Write API specification
  |
  +-- Story: Implement payment processing
  |     +-- Task: Integrate with payment gateway
  |     +-- Task: Handle error cases
  |     +-- Task: Add retry logic
  |
  +-- Story: Add monitoring and alerts
        +-- Task: Set up logging
        +-- Task: Define SLOs
        +-- Task: Configure alert rules
```

Agent 也用同样的结构。例如，"Write a blog post about Kubernetes networking" 可拆为：

```
Sub-goal 1: Research
  Task 1.1: Identify key networking concepts
  Task 1.2: Find recent developments and best practices

Sub-goal 2: Outline and Write
  Task 2.1: Create section structure
  Task 2.2: Write each section with code examples

Sub-goal 3: Review
  Task 3.1: Check technical accuracy
  Task 3.2: Verify code examples work
```

### 层级化 planning 的好处

- **可管理的小块。** 每个任务都足够小，可以专注完成。
- **依赖清晰。** 你能看到哪些任务相互依赖，哪些可以并行。
- **进度跟踪。** 你清楚地知道在整体计划中处于何处。
- **委派。** 在多 Agent 系统中，不同子目标可分配给专门的 Agent。

### 抽象层级

| Level | What it describes | Example |
|-------|------------------|---------|
| **Goal** | 成功的样子 | "Deploy the application to production" |
| **Sub-goal** | 工作的主要阶段 | "Prepare the environment" |
| **Task** | 具体动作 | "Create the Cloud Run service" |
| **Step** | 原子操作 | "Run `gcloud run deploy`" |

Agent 通常在 sub-goal 与 task 层级做规划。step 由各 task 内部的 ReAct 风格执行处理。

---

## 重新规划：在事情出错时调整

没有计划能在遭遇现实后毫发无损。好的 Agent 能侦测计划失败并加以调整。

### 何时该重新规划

| Trigger | Example | Response |
|---------|---------|----------|
| **Task failure** | API 返回错误 | 尝试替代方案，或跳过稍后再处理 |
| **New information** | 发现数据库 schema 与预期不符 | 更新计划以适应实际 schema |
| **Changed requirements** | 用户在任务中途新增需求 | 把新需求纳入计划 |
| **Resource constraints** | context 空间或 API 配额吃紧 | 简化剩余步骤 |
| **Blocked dependency** | 所需服务宕机 | 重排任务，先做未阻塞的项 |

### 重新规划策略

**1. 局部调整**

在不改动整体计划的前提下解决眼前的问题。

```
Original plan step: "Query the users table for active accounts"
Failure: "Table 'users' does not exist"
Adjustment: "Query the 'accounts' table instead (it has the same data)"
```

**2. 步骤插入**

新增步骤以应对意外情况。

```
Original plan:
  1. Fetch data
  2. Process data
  3. Generate report

After discovering data needs cleaning:
  1. Fetch data
  1b. Clean and validate data    <-- inserted
  2. Process data
  3. Generate report
```

**3. 计划修订**

基于新认识，对剩余计划做较大幅度的重组。

```
Original plan: "Migrate the monolith to microservices"
After analysis: "The codebase is too tightly coupled for a direct migration."
Revised plan: "First, introduce module boundaries within the monolith
               (strangler fig pattern), then gradually extract services."
```

**4. 目标修改**

在极端情况下，Agent 意识到原目标无法实现，并提出修订后的目标。例如，目标是"reduce latency to under 50ms"，但仅数据库查询就需要 80ms，Agent 可能提议改为对常被访问的端点引入缓存，将目标调整为 100ms。

关键原则：先尝试局部修复，只有当局部修复不可行时才重组剩余计划。

---

## 推理技术

planning 离不开 reasoning——逻辑性地思考问题的能力。下面几种技术帮助 Agent 更有效地推理。

### Chain-of-Thought (CoT)

**是什么：** Agent 一步一步走完问题，在每个阶段展示推理。它不是直接给答案，而是"思考出声"。

**类比：** 数学考试中写出过程。除了答案，还要写下每一步的计算。

```
Without Chain-of-Thought:
  Q: "If a server handles 100 requests/second and we need to handle 10,000
      requests/second, how many servers do we need?"
  A: "100 servers"

With Chain-of-Thought:
  Q: [same question]
  A: "Let me work through this:
      - One server handles 100 requests/second
      - We need 10,000 requests/second total
      - 10,000 / 100 = 100 servers for the raw capacity
      - But we should account for redundancy. With N+1 redundancy, we need 101.
      - And servers do not run at 100% efficiency. At 80% target utilization:
        10,000 / (100 * 0.8) = 125 servers
      - With N+1 redundancy: 126 servers
      Answer: 126 servers for production, assuming 80% target utilization
              and N+1 redundancy."
```

逐步推理能捕捉到瞬间答案错过的细节（冗余、利用率）。

**何时使用 CoT：**
- 数学与逻辑问题
- 多步推理
- 中间步骤本身重要的任务
- 调试与根因分析

### Tree-of-Thoughts (ToT)

**是什么：** Agent 不沿单条推理链走到底，而是探索多条可能路径并评估哪条最有希望。可以理解为在选定方案前先头脑风暴几种途径。

**类比：** 象棋手考虑几种可能的走法，对每种都向前推演几步，然后选出最佳路径。

```
Problem: "Our API is timing out under load. How should we fix it?"

Branch 1: Add caching
  -> Evaluate: "Would reduce database load by ~60%. Implementation
     takes 2 days. Risk: cache invalidation complexity."
  Score: 7/10

Branch 2: Optimize database queries
  -> Evaluate: "Could improve query time by ~40%. Implementation
     takes 3 days. Risk: low, well-understood approach."
  Score: 6/10

Branch 3: Add horizontal scaling
  -> Evaluate: "Handles any load level. Implementation takes 1 day
     with Kubernetes. Risk: increases infrastructure cost."
  Score: 8/10

Decision: Start with horizontal scaling (fastest win), then add
          caching for long-term efficiency.
```

**何时使用 ToT：**
- 有多种合理途径的问题
- 战略性决策
- 第一反应未必最佳的任务
- 架构与设计决策

### self-consistency

**是什么：** Agent 用不同的推理路径多次解决同一个问题，再核对答案是否一致。如果多数路径得出同一结论，置信度高；如果分歧较大，需要进一步调查。

**类比：** 让三位修车师傅诊断同一个车辆故障。如果都说"发电机坏了"，你可以放心；如果各说各的，你就需要更多检查。

```
Problem: "Is this code change safe to deploy on a Friday?"

Reasoning path 1 (risk analysis):
  "The change modifies the payment flow. Payment changes on Friday
   mean weekend incidents. Verdict: No."

Reasoning path 2 (scope analysis):
  "The change is 5 lines and has 95% test coverage. Small, well-tested
   changes are low risk. Verdict: Yes, with monitoring."

Reasoning path 3 (historical analysis):
  "Similar changes in the past have caused issues 15% of the time.
   That is above our 10% threshold. Verdict: No."

Consensus: 2 out of 3 say No. Recommendation: Wait until Monday.
```

**何时使用 self-consistency：**
- 高风险决策
- 错误代价昂贵的任务
- 没有明确单一答案的模糊问题
- 关键推理的验证

### 推理技术对比

| Technique | Approach | Strength | Cost | Best for |
|-----------|----------|----------|------|----------|
| **Chain-of-Thought** | 线性逐步 | 周密 | 1x（单次） | 多数推理任务 |
| **Tree-of-Thoughts** | 探索多路径 | 找到最佳途径 | 3-5x（多分支） | 战略性决策 |
| **Self-consistency** | 多次独立尝试 | 置信度校准 | 3-5x（多次推理） | 高风险验证 |

---

## orchestrator 层

orchestrator 层是管理 Agent 如何 planning、reasoning 与执行的控制系统。把它想成乐团的指挥——他不演奏任何乐器，但决定谁在何时演奏什么。

### orchestrator 层做什么

```
+----------------------------------------------------------+
|                   ORCHESTRATION LAYER                    |
|                                                          |
|  +----------+  +-----------+  +----------+  +--------+  |
|  | Plan     |  | Execute   |  | Monitor  |  | Re-plan|  |
|  | Manager  |  | Engine    |  | & Eval   |  | Logic  |  |
|  +----------+  +-----------+  +----------+  +--------+  |
|                                                          |
|  Responsibilities:                                       |
|  - Break goals into executable steps                     |
|  - Decide execution order and parallelism                |
|  - Route steps to the right tools or sub-agents          |
|  - Track progress and state                              |
|  - Detect failures and trigger re-planning               |
|  - Manage context window usage                           |
|  - Enforce guardrails and safety checks                  |
+----------------------------------------------------------+
```

### 实践中的 orchestration

在 Google Cloud 的 [Vertex AI Agent Engine](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview) 中，orchestrator 层负责：

- **路由：** 把用户请求引导到合适的 Agent 或 tool
- **state 管理：** 跟踪 Agent 在计划中的位置
- **tool 执行：** 调用 tool 并处理结果
- **错误处理：** 捕获失败并决定如何恢复
- **context 管理：** 保持 context window 井然有序

[Agent Development Kit (ADK)](https://google.github.io/adk-docs/) 提供了自定义 orchestrator 行为的构件。你定义 Agent 的 tool、指令和行为——框架处理执行循环。

### 关键的 orchestration 决策

| Decision | Options | Trade-off |
|----------|---------|-----------|
| **前期规划多少** | 完整计划 vs. 仅下一步 | 周密 vs. 灵活 |
| **何时重规划** | 每步之后 vs. 仅在失败时 | 适应性 vs. 开销 |
| **如何处理失败** | 重试、跳过、终止或重规划 | 韧性 vs. 成本 |
| **串行 vs. 并行** | 一次一步 vs. 并发 | 简单 vs. 速度 |
| **暴露多少推理** | 仅内部 vs. 展示给用户 | 透明 vs. 噪声 |

---

## 常见失败模式

即便设计良好的 planning Agent 也会以可预见的方式出错。了解这些失败模式有助于建立防御。

### 1. 死循环

**现象：** Agent 卡在重复同一个动作或不断重规划，毫无进展。

**示例：**
```
Think: "I need to find the user's email. Let me search the database."
Act: search_database(query="user email")
Observe: No results found.
Think: "I need to find the user's email. Let me search the database."
Act: search_database(query="user email")
Observe: No results found.
[repeats forever]
```

**预防：**
- 为任何循环设最大迭代次数
- 跟踪已采取的动作，检测重复
- 同一动作连续 N 次失败后，强制 Agent 改换思路
- 提供"优雅放弃"的选项——向用户求助

### 2. 计划漂移

**现象：** Agent 逐渐偏离原始目标，沿着有趣的旁支前进，而非紧扣主线。

**示例：**
```
Original goal: "Write a summary of Q4 sales performance"
Step 1: Fetch Q4 sales data [on track]
Step 2: Notice an anomaly in November data [slightly off track]
Step 3: Deep dive into November anomaly [drifting]
Step 4: Research industry trends that might explain the anomaly [lost]
Step 5: Write a report about industry trends [completely off track]
```

**预防：**
- 周期性自检："我现在做的事是否与原目标对齐？"
- 在每次推理中包含原目标
- 在计划里设定范围边界
- 设独立的评估步骤检查相关性

### 3. 简单任务过度规划

**现象：** Agent 花在规划上的时间比直接做完还要多。

**示例：**
```
User: "What is 2 + 2?"

Agent Plan:
  Step 1: Identify the mathematical operation (addition)
  Step 2: Identify the operands (2 and 2)
  Step 3: Verify the operands are valid numbers
  Step 4: Perform the addition
  Step 5: Verify the result
  Step 6: Format the response

[Just say "4"!]
```

**预防：**
- 在决定是否规划前先估算任务复杂度
- 简单任务（单步、答案明确）应跳过规划
- 设置与任务复杂度成比例的规划时间预算

### 4. 级联失败

**现象：** 一个失败的步骤引发后续步骤连锁失败，而 Agent 没有发现根本原因。

**示例：**
```
Step 1: Fetch user profile -> Returns error (auth expired)
Step 2: Process user preferences -> Fails (no profile data)
Step 3: Generate recommendations -> Fails (no preferences)
Step 4: Format output -> Fails (no recommendations)
Agent: "I was unable to complete the task due to formatting errors."
  [Wrong! The real problem was expired authentication in step 1]
```

**预防：**
- 把每一步的输出当作下一步的输入校验
- 失败时回溯查找根因
- 在关键依赖上 fail fast，不要试图绕过去
- 报告真正的根因，而非最新的症状

### 5. context 耗尽

**现象：** 计划及其执行历史占满了 context window，Agent 没有空间推理当前步骤。

**预防：**
- 用摘要替代已完成步骤的完整细节
- 把中间结果外部存储，只引用 ID
- 预算化 context 空间：为当前步骤的推理预留固定额度
- 详细策略见 [Lesson 5: Memory and Context](/05-memory-and-context/)

### 失败模式小结

| Failure mode | Symptom | Key prevention |
|-------------|---------|---------------|
| 死循环 | 同一动作反复 | 最大迭代次数 + 重复检测 |
| 计划漂移 | Agent 偏离主题 | 周期性目标对齐检查 |
| 过度规划 | 简单任务上规划过多 | 规划前先估算复杂度 |
| 级联失败 | 报告错误的根因 | 失败时回溯 + fail fast |
| context 耗尽 | Agent 失去连贯性 | context 预算化 + 摘要 |

---

## 整合在一起：实践示例

下面是一个浓缩示例，展示 planning、reasoning 与重规划如何协同：

```
User: "Analyze our error logs from the past week and create Jira tickets
       for the top issues."

PLAN:
  Phase 1: Query error logs (past 7 days, ERROR + FATAL severity)
  Phase 2: Group by type, rank by frequency, identify top 5
  Phase 3: For each issue, check for existing tickets, create if new
  Phase 4: Summarize findings

EXECUTE (ReAct within each phase):
  Act: log_query(severity=["ERROR","FATAL"], days=7)
  Observe: 12,847 entries returned
  Act: log_analyze(group_by="error_message", sort="count_desc")
  Observe: Top issues identified (connection timeouts, null pointer, rate limits)

  Act: jira_search(query="Connection timeout payment-service")
  Observe: No existing ticket -> Create new ticket PLATFORM-1234

RE-PLAN (mid-execution):
  Observe: PLATFORM-999 already exists for NullPointerException
  Adjust: Update existing ticket with new occurrence count instead of creating duplicate

DELIVER:
  "Analyzed 12,847 errors. Created 4 new tickets, updated 1 existing one."
```

注意 Agent 如何在前期使用层级化 planning，在每个阶段内使用 ReAct 风格执行，并在发现已有 ticket 时进行重规划。所有模式协同发挥作用。

---

## 关键要点

1. **planning 把复杂任务转化为可管理的步骤。** 没有它，Agent 要么漏掉重要步骤，要么把精力浪费在岔路上。

2. **问题求解循环（Mission, Scene, Think, Act, Observe）是每个 planning Agent 的引擎。** 理解这一循环有助于你设计与调试 Agent 行为。

3. **先规划后执行与反应式方法是光谱的两端。** 多数实用 Agent 采用混合：轻量前期规划 + 反应式执行。

4. **层级化 planning 处理复杂任务**，把它们分解为目标、子目标、任务和步骤。这与项目管理的方式一致。

5. **重规划必不可少。** 计划终会失效。好的 Agent 能尽早发现失败并调整。能否适应，决定了 Agent 是有用还是脆弱。

6. **推理技术（CoT、ToT、self-consistency）让 planning 更有效。** Chain-of-Thought 用于逐步逻辑，Tree-of-Thoughts 用于探索备选，self-consistency 用于验证关键决策。

7. **警惕常见失败模式。** 死循环、计划漂移、过度规划、级联失败和 context 耗尽是有规律的问题，且都有已知的解决办法。

8. **orchestrator 层把这一切串起来。** 它管理计划生命周期、调度执行、处理错误，让 Agent 不偏离主线。

---

## 延伸阅读

- [Vertex AI Agent Engine overview](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview)
- [Agent Development Kit (ADK) documentation](https://google.github.io/adk-docs/)
- [Google Cloud AI codelabs](https://codelabs.developers.google.com/?cat=AI)

---

**下一课：** [Multi-Agent Systems](/07-multi-agent-systems/)
