---
title: "Lesson 7: 多 Agent 系统 — 当一个 Agent 不够用"
---

## 引言

在本课程之前的部分，我们一直专注于构建单一 Agent——一个 LLM 加上 tool、memory 和一个 planning 循环。这种做法在许多任务上都表现得相当不错。但随着自动化目标的范围扩大，单一 Agent 会逐渐不堪重负。它变慢，变糊涂，试图样样精通，最终一事不通。

多 Agent 系统通过把工作拆分给多个专门化的 Agent 来解决这个问题，让它们协作达成共同目标。把它想成自由职业者与一个组织良好的团队之间的差别。自由职业者能做很多事，但一支由各领域专家组成的团队——每人负责自己的领域——能解决任何单人都无法独立处理的问题。

这一课中你将了解何时以及为什么使用多个 Agent，组织它们的主要架构模式，Agent 之间如何通信，以及如何处理分布式系统带来的协作挑战。

## 为什么使用多个 Agent？

### 单一 Agent 的局限

一个拥有二十种 tool、巨大 system prompt、覆盖五个不同领域指令的 Agent，就像一位入职第一天就被塞进五份不同岗位说明书的新人。技术上他可能样样都能做，但同时兼顾所有这些会导致错误、迟缓和混乱。

下面是把任务拆给多个 Agent 的具体理由：

| Problem with Single Agent | How Multi-Agent Helps |
|---|---|
| Prompt 变得过于庞大且难以维护 | 每个 Agent 拿到聚焦、可维护的 prompt |
| tool 太多导致选择错误 | 每个 Agent 只看到与其角色相关的 tool |
| 一处失败拖垮整个工作流 | 失败被隔离在单个 Agent；其他 Agent 继续工作 |
| 难以为瓶颈步骤扩容 | 可以独立地为单个 Agent 扩容 |
| 难以测试与调试 | 每个 Agent 可独立测试 |
| 安全上的单点失效 | 不同 Agent 可拥有不同权限级别 |

### ELI5：医院类比

多 Agent 系统就像一家医院。当你因身体不适走进医院，并不会有一位医生包揽一切——量体征、化验、读 X 光、做手术、处理账单。相反，你会经过一系列专家：分诊护士评估、医生诊断、放射科医生读影、必要时由外科医生手术、行政人员处理保险。每个人都是各自角色的专家，并通过共享记录与交接协议进行协作。

AI 多 Agent 系统也是同样的原理。每个 Agent 都是某一专长的专家，拥有聚焦的角色、自己的 tool 集，以及关于"自己处理什么、转交什么"的清晰边界。

### 单 Agent 还是多 Agent

并非每个问题都需要多个 Agent。这里有一个简单的判断框架：

**坚持单 Agent 的情形：**
- 任务定义清晰且范围窄（如 "summarize this document"）
- 需要的 tool 少于 5-7 个
- 工作流线性且可预测
- 延迟要求严格（多 Agent 会增加开销）

**考虑多 Agent 的情形：**
- 任务跨多个领域（如 customer service + payments + compliance）
- 不同步骤需要不同权限级别
- 你希望各部分独立开发、测试、部署
- 系统需要按不同速率扩展不同能力
- 你需要故障隔离——某部分失败不应让整个系统停摆

## 单 Agent vs. 多 Agent：街角小店 vs. 百货商场

设想一家由一个人经营的街角小店。店主迎客、找货、收银、处理退货、补货。对于客流量小的小店，这种方式很好。店主什么都懂，什么都能做。

现在设想同一个人独自经营一家百货商场。成千上万的顾客、数十个部门、复杂的库存、各类专门商品。那将是一团糟。百货商场之所以运转良好，是因为有专业分工的员工：电子部、服装部、收银员、楼层经理、退货柜台。每个人都有清晰的角色，并通过既定流程协作。

| Aspect | Single Agent (Corner Shop) | Multi-Agent (Department Store) |
|---|---|---|
| 应对复杂度 | 适合简单任务 | 为复杂工作流而设计 |
| 专门化 | 万金油 | 各自领域的专家 |
| 失败影响 | 全部停摆 | 仅受影响的 Agent 受波及 |
| 开发速度 | 原型化快 | 各部分迭代更快 |
| 协作开销 | 无 | 需要显式的协作逻辑 |
| 简单任务的成本 | 较低 | 较高（更多 LLM 调用） |

## 多 Agent 架构

组织多个 Agent 主要有四种模式。各有侧重，实际系统中常常组合使用。

### 1. 顺序式（流水线）

在顺序式架构中，Agent 排成一条流水线。Agent A 完成工作交给 Agent B，B 再交给 C，依次往下。每个 Agent 在交付下一站前对输出进行转换或丰富。

**工作方式：**
```
[Agent A] --> [Agent B] --> [Agent C] --> Final Output
 (Research)   (Draft)       (Review)
```

**类比：** 想象汽车装配线。一站焊接车架，下一站安装发动机，再下一站喷涂车身。每一站都把一件事做精，车辆沿流水线前进。

**何时使用：**
- 任务有清晰、有序的阶段
- 每个阶段依赖前一阶段的输出
- 你想要简单、可预测的流程

**示例：** 内容流水线——Research Agent 收集资料，Writing Agent 产出草稿，Editing Agent 审稿确保质量与准确性。

**优点：**
- 易于理解与调试
- 数据流清晰
- 增加或移除阶段简单

**缺点：**
- 速度由最慢的 Agent 决定
- 没有并行
- 早期 Agent 出错会向后传播

### 2. 层级式（管理者与执行者）

在层级式架构中，一个监督者 Agent（"manager"）接收整体任务，将其拆分为子任务并委派给专门的工作 Agent。manager 收集结果、检查质量，必要时重新委派。

**工作方式：**
```
              [Manager Agent]
             /       |       \
    [Worker A]  [Worker B]  [Worker C]
    (Search)    (Calculate)  (Draft)
```

**类比：** 这就像公司组织架构图。CEO 不写代码、不报税——他设定方向，并委派给部门负责人，再由他们继续向下委派。CEO 审阅结果、做最终决定。

**何时使用：**
- 任务需要动态拆解（无法事先预知子任务）
- 不同子任务需要不同能力
- 你需要单一的协作与质量控制点

**示例：** 项目管理 Agent 接到 "Plan the Q3 product launch"，将调研委派给一个 Agent，时间线创建给另一个，风险评估给第三个。

**优点：**
- 灵活——可处理多样任务
- 集中式质量控制
- 子任务可并行

**缺点：**
- manager 是瓶颈与单点失效
- manager 必须足够聪明才能很好地拆解任务
- 实现比顺序式复杂

在 [Google Agent Development Kit (ADK)](https://google.github.io/adk-docs/agents/) 中，对层级式模式有良好的支持。你可以定义一个父 Agent 委派给子 Agent，每个子 Agent 拥有自己的 tool 和指令。

### 3. 协作式（对等网络）

在协作式架构中，Agent 平等地协同工作。没有上司。Agent 之间共享信息、在彼此工作之上构建，通过交流逐步收敛到解决方案。

**工作方式：**
```
[Agent A] <--> [Agent B]
    ^              ^
    |              |
    v              v
[Agent C] <--> [Agent D]
```

**类比：** 这就像一群同事的头脑风暴。每个人都贡献想法、回应他人，团队收敛出一个方案。无人主导——最佳想法通过讨论自然浮现。

**何时使用：**
- 问题受益于多元视角
- 没有单一 Agent 拥有所需的全部信息
- 你想要创造性或探索性的产出

**示例：** 一个代码评审系统——Security Agent、Performance Agent、Readability Agent 各自审查同一份代码并分享结论，然后协作产出统一的评审。

**优点：**
- 适合无清晰拆解的复杂问题
- 多元视角提升质量
- 没有单点失效

**缺点：**
- 行为更难预测
- 存在死循环或循环讨论的风险
- 调试更困难

### 4. 竞争式（最佳答案胜出）

在竞争式架构中，多个 Agent 各自独立解决同一问题，再由一个评判者（另一个 Agent 或评分函数）选出最佳输出。

**工作方式：**
```
[Agent A] --\
[Agent B] ----> [Judge] --> Best Output
[Agent C] --/
```

**类比：** 这就像一场设计竞赛。三家建筑事务所各自提交一份新建筑方案。评审团审阅三份方案后选出最佳。竞争产生的结果往往优于任何单一事务所独立完成的方案。

**何时使用：**
- 质量比成本更重要
- 问题有多种合理途径
- 你希望降低产出糟糕的概率

**示例：** 三个不同的编码 Agent 各自为同一编程问题写一份方案。Judge Agent 跑测试、检查代码质量，挑选最佳实现。

**优点：**
- 通过竞争获得更高质量的输出
- 天生具备韧性——一个 Agent 失败仍可能由其他 Agent 成功
- 适合错误代价高的关键任务

**缺点：**
- 昂贵（N 个 Agent 即 N 倍计算量）
- 需要良好的评估机制
- 若 Agent 产出相似则浪费资源

### 架构对比小结

| Architecture | Flow | Best For | Coordination Complexity |
|---|---|---|---|
| Sequential | 线性 pipeline | 有序的多阶段任务 | 低 |
| Hierarchical | 树形（manager + workers） | 动态任务拆解 | 中 |
| Collaborative | 网状（对等） | 需要多元输入的复杂问题 | 高 |
| Competitive | 并行 + 评判者 | 高风险决策 | 中 |

## 通信模式

Agent 之间需要交流。它们的通信方式塑造了系统的行为、可调试性与性能。主要有三种模式：

### 直接消息

Agent 之间直接发送消息。Agent A 知道 Agent B 的存在并向它发起请求。

```
Agent A --"summarize this document"--> Agent B
Agent B --"here is the summary"--> Agent A
```

**优点：** 简单、低延迟、易追踪。
**缺点：** 强耦合——Agent A 必须知道 Agent B 的存在。新增 Agent 需要更新已有 Agent。

### 共享黑板

所有 Agent 从一个共享工作区（"blackboard"）读写。Agent 检查黑板上的新信息，完成自己的工作，把结果再贴回去。

```
[Blackboard / Shared State]
    ^       ^       ^
    |       |       |
Agent A  Agent B  Agent C
```

**优点：** 松耦合——Agent 之间无需相互知晓。容易新增 Agent。适合协作式架构。
**缺点：** 多个 Agent 写同一区域可能产生冲突。因果关系更难追踪（谁改了什么、为什么）。

### 事件式

Agent 把事件发布到消息总线。其他 Agent 订阅自己关心的事件并作出响应。

```
Agent A --publishes "order_refund_requested"--> [Event Bus]
[Event Bus] --notifies--> Agent B (Payment)
[Event Bus] --notifies--> Agent C (Compliance)
```

**优点：** 高度解耦。可扩展性好。对熟悉微服务的工程师很友好。
**缺点：** 基础设施更多。调试更难。需要面对最终一致性挑战。

### 选择哪种模式

| Scenario | Recommended Pattern |
|---|---|
| 两个 Agent 间清晰的请求—响应流程 | 直接消息 |
| 多个 Agent 在共享 context 上累积工作 | 共享黑板 |
| 微服务式、Agent 数量众多的系统 | 事件式 |
| 简单原型 | 直接消息 |
| 大规模生产系统 | 事件式 |

## Agent 角色

在设计良好的多 Agent 系统中，每个 Agent 都有清晰的角色。下面是众多架构中常见的四种角色：

### Planner

Planner 接受高层目标并将其拆分为一系列步骤或子任务。它决定要做什么以及顺序如何。

**职责：**
- 解读用户目标
- 拆分为子任务
- 确定子任务之间的依赖
- 制定执行计划

**示例：** 给定 "Book a team offsite for next month"，Planner 可能产出：(1) 检查团队日历，(2) 寻找可用场地，(3) 比较价格，(4) 预订最佳选项，(5) 发送日历邀请。

### Retriever

Retriever 从外部来源——数据库、API、文档、网络——查找信息。它知道数据在哪里、如何获取。

**职责：**
- 搜索知识库与文档存储
- 查询 API 与数据库
- 按相关性过滤与排序结果
- 把结构化信息返回给其他 Agent

### Executor

Executor 在真实世界中采取行动。它调用 API、写文件、发邮件、修改数据库。它是"动手做事"的 Agent。

**职责：**
- 执行 Planner 给出的步骤
- 调用外部 API 与 tool
- 处理错误与重试
- 回报结果

### Evaluator

Evaluator 检查其他 Agent 完成工作的质量。它验证正确性、安全性与完整性。

**职责：**
- 根据需求验证输出
- 检查错误、hallucination 或政策违规
- 给质量打分，并决定是否需要重做
- 给出改进反馈

## 实例演练：客户退款系统

让我们走一遍一个具体的多 Agent 系统——电商公司的客户退款处理。本例使用层级式架构，包含四个专门化 Agent。

### Agent 列表

| Agent | Role | Tools | Permissions |
|---|---|---|---|
| Customer Agent | Planner + 接口 | Customer lookup, order history | 读取客户数据 |
| Payment Agent | Executor | Refund API, payment gateway | 处理 $500 以内的退款 |
| Compliance Agent | Evaluator | Policy database, fraud detection | 只读访问 |
| Resolution Agent | Manager / Orchestrator | 无（协调他人） | 委派给所有 Agent |

### 流程

**情境：** 客户来信："I never received my order #12345 and I want a refund."

**第 1 步：Resolution Agent 接收请求**

Resolution Agent 是入口。它读取客户信息并决定需要哪些 Agent 介入。

```
Resolution Agent thinks:
"This is a refund request for a missing order. I need to:
1. Verify the customer and order details
2. Check compliance with refund policy
3. Process the refund if approved"
```

**第 2 步：Resolution Agent 委派给 Customer Agent**

Resolution Agent 让 Customer Agent 查询客户与订单。

```
Resolution Agent -> Customer Agent:
"Look up order #12345 and provide the order details,
delivery status, and customer history."
```

Customer Agent 查询订单数据库，发现 #12345 标记为 "shipped" 但物流显示从未送达。它把信息返回给 Resolution Agent。

**第 3 步：Resolution Agent 委派给 Compliance Agent**

拿到订单详情后，Resolution Agent 让 Compliance Agent 判断退款是否合规。

```
Resolution Agent -> Compliance Agent:
"Order #12345, $89.99, shipped but never delivered.
Customer has 2 prior refund requests in the last year.
Is a refund appropriate per our policy?"
```

Compliance Agent 检查退款政策，确认不存在欺诈模式，并答复退款获批——客户在政策范围内，且物流方确认配送失败。

**第 4 步：Resolution Agent 委派给 Payment Agent**

获得合规批准后，Resolution Agent 指示 Payment Agent 处理退款。

```
Resolution Agent -> Payment Agent:
"Process a refund of $89.99 to the original payment
method for order #12345. Compliance approved."
```

Payment Agent 调用 payment gateway API，处理退款，并返回带交易 ID 的确认。

**第 5 步：Resolution Agent 答复客户**

Resolution Agent 汇总结果并生成面向客户的响应，确认退款。

### 这一设计为何有效

- **关注点分离：** 每个 Agent 处理一个领域。Payment Agent 不接触客户数据；Compliance Agent 不处理支付。
- **安全：** Payment Agent 拥有退款权限，但仅限 $500 以内。更大金额需人工审批。Customer Agent 可读数据但不可修改。
- **故障隔离：** 若 Payment API 宕机，Compliance 与 Customer Agent 仍可工作。系统可把退款排队稍后重试。
- **可测试性：** 每个 Agent 可独立测试。Compliance Agent 在客户近期申诉过多时是否正确拒绝退款？无需牵涉支付即可测试。
- **可审计：** 每次委派与响应都有日志。谁决定了什么、为什么，留有清晰链路。

### 用 Google ADK 构建

[Google Agent Development Kit (ADK)](https://google.github.io/adk-docs/agents/) 内置对多 Agent 模式的支持。你可以把 Agent 定义为带有自身指令、tool 和子 Agent 的类。ADK 处理 Agent 间的消息传递，并提供调试用的追踪。

对于行为模式可预测的工作流型 Agent（如我们的顺序式合规检查），ADK 提供 [workflow agents](https://google.github.io/adk-docs/agents/workflow-agents/)，内置 sequential、parallel 与 loop 构造。

## 协作挑战

多 Agent 系统是分布式系统，会出现单 Agent 系统所没有的失败模式。下面是最常见的协作挑战及其处理方式：

### 死锁

**是什么：** 两个或更多 Agent 互相等待对方完成，结果谁都无法推进。

**示例：** Agent A 等 Agent B 的输出再继续；Agent B 等 Agent A 的输出再继续。两人都无法前进。

**预防：**
- 尽可能设计单向数据流
- 为所有 Agent 间通信加超时
- 使用中央 orchestrator 检测并打破环路
- 实现熔断器，超时后优雅失败

### 循环委派

**是什么：** Agent A 委派给 Agent B，B 又把任务推回给 A，形成无限循环。

**示例：** Planner Agent 向 Research Agent 索取信息。Research Agent 觉得需要更多 context，反过来请 Planner Agent 澄清。Planner Agent 没有新信息，又再次问 Research Agent。无限循环。

**预防：**
- 设最大委派深度（例如，单一任务的转交不超过 3 次）
- 跟踪委派历史，拒绝形成环路的请求
- 给 Agent 明确的边界——什么自己处理，什么需上报人工

### 冲突动作

**是什么：** 两个 Agent 各自独立地对同一资源做出相互矛盾的动作。

**示例：** Pricing Agent 基于竞品分析将商品价格设为 $49.99。同时 Promotions Agent 为了限时促销将同一商品设为 $29.99。最终价格取决于谁后写。

**预防：**
- 对共享资源使用锁机制
- 指定单一 Agent 作为各资源的所有者
- 实现冲突解决 Agent 或政策
- 使用事件溯源，让所有变更可追踪、可回滚

### 资源争用

**是什么：** 多个 Agent 争抢有限资源（API 速率限制、token 预算、数据库连接）。

**示例：** 十个 Agent 同时调用同一外部 API，触发限流，全部失败。

**预防：**
- 在系统层面实现限流与排队
- 使用共享资源池，公平调度
- 关键 Agent 享有更高优先级
- 监控资源使用，为每个 Agent 设预算

### 状态不一致

**是什么：** 由于共享 state 的更新尚未传播到所有 Agent，各 Agent 看到的世界不一样。

**示例：** Customer Agent 检查库存后告诉客户某件商品有货。与此同时，Fulfillment Agent 刚卖出最后一件。客户拿到的确认对应已无库存的商品。

**预防：**
- 共享 state 使用单一可信来源
- 实现带版本号的乐观锁
- 设计 Agent 时考虑陈旧数据（动作前再次校验）
- 把不一致窗口尽量压缩

## 多 Agent 系统的设计原则

基于上述模式与挑战，下面是要遵循的关键原则：

### 1. 从简单开始

先从单 Agent 起步。只有在遇到明确瓶颈时才增加 Agent。过早地拆分到多 Agent 会徒增复杂度。

### 2. 明确边界

每个 Agent 都应有定义良好的范围、自己的 tool，以及明确规则——什么自己处理，什么转交他人。模糊的边界会导致重复与冲突。

### 3. 为失败而设计

假设任何 Agent 都可能在任何时刻失败。使用超时、重试、熔断与降级。设计良好的多 Agent 系统会优雅退化，而不是整体崩溃。

### 4. 让通信可观测

记录 Agent 间的每条消息。调试问题时你需要这些日志。如果你无法追踪一个请求在系统中的完整路径，就无法在它出问题时修复它。

### 5. 限制 Agent 自主性

每个 Agent 应只拥有完成任务所需的最低权限。Payment Agent 不应能读取客户邮件；Customer Agent 不应能处理退款。这样可以在 Agent 失控时把影响半径降到最小。

### 6. 让人类作为熔断器

对高风险决策，加入 human-in-the-loop 步骤。Agent 擅长处理常规情况；人类应处理例外、边界情况和后果重大的决策。

## 实战练习

为以下任一情境设计一个多 Agent 系统。对所选情境，定义：
1. Agent 与各自角色
2. 架构模式（顺序式、层级式、协作式或竞争式）
3. 通信模式（直接、黑板或事件式）
4. 至少两个潜在协作挑战及缓解策略

**情境 A：自动化代码评审**
一个评审 pull request 的系统，覆盖代码质量、安全漏洞、性能问题与代码风格合规。

**情境 B：旅行预订助手**
一个帮助用户规划与预订旅行的系统——机票、酒店、租车、活动——并控制在预算内。

**情境 C：内容审核流水线**
一个在内容发布前评审用户生成内容的系统，检查政策违规、垃圾内容、错误信息与有害内容。

## 关键要点

- 多 Agent 系统把工作拆分给一组专门化的 Agent，每个 Agent 拥有聚焦的职责、tool 与权限。
- 主要的四种架构：顺序式（pipeline）、层级式（manager-worker）、协作式（对等网络）、竞争式（最佳答案胜出）。根据任务结构选择。
- 通信模式——直接消息、共享黑板、事件式——决定 Agent 之间的耦合紧密程度。
- 常见 Agent 角色（Planner、Retriever、Executor、Evaluator）为系统设计提供起步词汇。
- 死锁、循环委派、冲突动作等协作挑战才是多 Agent 系统真正的工程难题。从一开始就要为它们做好设计。
- 从单 Agent 起步，在确实需要时再增加复杂度。最好的多 Agent 系统是能解决你问题的最简单的那个。

## 延伸阅读

- [Google ADK - Agents Overview](https://google.github.io/adk-docs/agents/) - 如何使用 Agent Development Kit 构建 Agent 与多 Agent 系统
- [Google ADK - Workflow Agents](https://google.github.io/adk-docs/agents/workflow-agents/) - 多 Agent 工作流的内置 sequential、parallel 与 loop 模式
