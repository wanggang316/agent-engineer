---
title: "Lesson 8: agentic RAG — 更聪明的 retrieval"
---

## 引言

在前面的课程中，你学到 Agent 如何使用 tool 与世界互动。Agent 最重要的能力之一就是查询的能力——搜索知识库、查询数据库或检索文档。这正是 Retrieval-Augmented Generation（RAG）的基础。

基本 RAG 遵循一个简单模式：把用户的问题拿来，搜索相关文档，把这些文档塞进 LLM 的 context，再生成答案。这种做法对直白的查询很有效。但当问题复杂、第一次搜索没拿回正确文档、或答案需要从多个来源综合得出时，它就会失灵。

agentic RAG 通过让 Agent 接管 retrieval 过程来解决这一问题。它不再是僵化的"先 retrieve 再 read"流水线，而是由 Agent 决定何时搜索、搜索什么、结果是否足够、何时换种方式再试。Agent 把 retrieval 当作可以策略性使用的 tool，而不是必须固定执行的步骤。

## 快速回顾：什么是 RAG？

RAG 即 Retrieval-Augmented Generation。它的思路很简单：LLM 有知识截止日期，无法知晓所有内容。所以在回答问题之前，先从外部来源检索相关信息，并把它纳入 prompt。

**基本 RAG 流水线：**

```
User Question
     |
     v
[Retriever] -- searches --> [Document Store]
     |
     v
Retrieved Documents
     |
     v
[LLM] -- generates answer using question + documents
     |
     v
Answer
```

**RAG 为何重要：**
- LLM 有知识截止——RAG 提供最新信息
- LLM 会 hallucinate——RAG 让答案扎根于真实文档
- LLM 无法访问私有数据——RAG 把它们与你的数据库相连
- RAG 让你无需重训模型即可更新知识

**简单类比：** RAG 就像开卷考试。你不再仅依赖记忆中的内容（LLM 的训练数据），还可以在写答案前查阅笔记（文档存储）。

## 基本 RAG 的局限

基本 RAG 在简单、直接、答案存在于单一文档中的问题上表现良好。但在以下几种常见情形中容易失灵：

### 问题 1：查询与文档不匹配

用户用与文档不同的措辞提问。retriever 搜索 "how to fix a slow database"，而相关文档讨论的是 "query optimization techniques"。语义鸿沟让 retriever 错过最佳文档。

### 问题 2：答案跨多个文档

用户问："What are our company's policies on remote work for international employees?" 答案需要综合远程办公政策、国际雇佣指南与税务合规文档。基本 RAG 一次性检索一小批文档，并希望正确的那些被包含进来。

### 问题 3：第一次结果不够好

基本 RAG 检索一次就不再回头。如果排在前面的结果平庸或不相关，LLM 就会生成平庸或错误的答案。它没有"这些结果不够用，让我换个搜索"的机制。

### 问题 4：问题需要被拆解

用户提出复杂问题，例如 "Compare our Q3 revenue in North America vs Europe and explain the key drivers of the difference."。这需要多个子查询：北美 Q3 营收、欧洲 Q3 营收、差异主要驱动因素分析。基本 RAG 试图用一次搜索就解决。

### 问题 5：没有验证

基本 RAG 缺乏自检机制。LLM 基于检索到的文档生成答案，无论这些文档是否过时、不相关或互相矛盾。它没有一步去问"基于这些证据，这个答案真的成立吗？"

## 是什么让 RAG 变得 "agentic"

agentic RAG 把 retrieval 过程的主导权交给 LLM。它不再走固定流水线，而是由 Agent 在每一步做决策：

### Agent 决定何时搜索

并非每个问题都需要 retrieval。agentic RAG 可以识别自己已经知道答案（来自训练数据或当前对话 context）的情况，并跳过 retrieval。它也能识别什么时候确实需要外部信息并发起搜索。

### Agent 重新表述查询

如果初始搜索结果差，Agent 不会就此放弃。它分析为何结果不佳，再换一种查询尝试。或许原问题太宽泛，于是收窄；或许用错了术语，于是换种说法。

**示例：**
```
Original query: "fix slow database"
    Results: generic articles about databases
    Agent thinks: "Too vague. Let me be more specific."
Reformulated: "PostgreSQL query optimization for slow JOIN operations"
    Results: specific optimization techniques
    Agent thinks: "Much better. These are relevant."
```

### Agent 跨多个来源相互印证

Agent 不依赖单次搜索，可以同时查询多个来源、对比结果并综合出更完整的答案。它可能先查内部知识库，再到公开文档核对，再与最近的支持工单交叉印证。

### Agent 自我纠错

生成答案后，Agent 对照检索到的证据进行核查。答案是否确实由文档支持？是否有矛盾？是否遗漏了关键信息？如果答案站不住脚，Agent 会回头检索更多信息。

## agentic RAG 循环

agentic RAG 的核心是一个循环，而不是一条流水线。Agent 在 retrieval、评估与精炼之间反复迭代，直到得到令人满意的答案，或耗尽可选项。

```
        User Query
            |
            v
    [1. Query Planning]
     "What do I need to find?"
            |
            v
    [2. Retrieve]
     Search knowledge base(s)
            |
            v
    [3. Evaluate Results]
     "Are these results good enough?"
           / \
         No   Yes
         |      \
         v       v
    [4. Refine]  [5. Generate Answer]
     Reformulate     |
     query and       v
     go back to  [6. Verify Answer]
     step 2      "Does this answer check out?"
                    / \
                  No   Yes
                  |      \
                  v       v
             Go back    Return Answer
             to step 1   to User
```

下面逐步说明每一步。

### 第 1 步：query planning

Agent 分析用户问题并决定 retrieval 策略。简单问题可能只需一次搜索；复杂问题则会被拆为多个子查询。

**示例：**

用户问："How did our customer satisfaction scores change after we launched the new support chatbot?"

Agent 规划：
1. 找到 chatbot 上线前的客户满意度分数
2. 找到 chatbot 上线日期
3. 找到 chatbot 上线后的客户满意度分数
4. 寻找把两者关联起来的分析或报告

### 第 2 步：retrieve

Agent 执行规划好的搜索。这可能涉及查询向量数据库、调用搜索 API、查询结构化数据，或它们的组合。

### 第 3 步：评估结果

这是 agentic RAG 与基本 RAG 分道扬镳的地方。Agent 审视检索到的文档并做出判断：

- **相关性：** 这些文档是否真的回应了我的问题？
- **完整性：** 我所需的信息都齐了吗？
- **新鲜度：** 这些文档是否过时？
- **一致性：** 来源之间是否互相印证？

### 第 4 步：精炼（如有必要）

如果结果不够好，Agent 调整方法：

- **重新表述查询：** 换关键词，更具体或更宽泛
- **换一个来源：** 从通用知识库切换到专门库
- **进一步拆解：** 把问题再分得更小
- **扩展搜索：** 找寻可能引向答案的相关概念

### 第 5 步：生成答案

当 Agent 拥有足够证据，便基于检索到的文档生成答案。答案应注明来源，便于用户核验。

### 第 6 步：验证答案

Agent 进行最终检查：

- 答案是否与检索到的任何文档相矛盾？
- 答案中的所有论断是否都有证据支撑？
- 是否存在缺口或含糊之处，提示需要继续 retrieval？

若验证失败，Agent 回到循环并继续收集信息。

## agentic RAG 的关键能力

### 自主的 query planning

Agent 自动把复杂问题拆为子查询，无需预定义模板或规则。它通过对问题的理解来确定需要哪些信息。

**Basic RAG：** 直接把用户原问题发给 retriever。
**Agentic RAG：** 分析问题、识别信息需求、规划多次有针对性的搜索。

### 自适应的来源选择

Agent 可以根据问题选择查询哪些知识源。公司政策问题进入政策库；客户问题进入 CRM；最近事件问题进入网络搜索。

| Question Type | Source Selection |
|---|---|
| 公司政策 | 内部政策数据库 |
| 客户信息 | CRM 系统 |
| 技术文档 | 工程 wiki |
| 近期事件 | 网络搜索 |
| 产品规格 | 产品目录 |
| 历史数据 | 数据仓库 |

### 上下文感知的查询扩展

Agent 利用对话 context 与已检索到的信息来改进后续查询。如果首次搜索返回了关于 "Project Alpha" 的信息，Agent 可能在后续查询里加入 "Project Alpha"，以找到相关文档。

### 多跳推理

有些问题需要一连串的 retrieval。第一个查询的答案决定下一次该查什么。

**示例：**
```
Question: "Who manages the team that built our recommendation engine?"

Hop 1: Search for "recommendation engine team"
  -> Found: "The recommendation engine was built by the ML Platform team"

Hop 2: Search for "ML Platform team manager"
  -> Found: "The ML Platform team is managed by Sarah Chen"

Answer: "Sarah Chen manages the ML Platform team, which built
         the recommendation engine."
```

## 自我纠错机制

agentic RAG 最有价值的特性之一就是能识别并从错误中恢复。

### 重新查询

当 Agent 发现初次结果不足时，它基于第一轮所学到的内容设计新查询。这不是随机重试——而是有依据的精炼。

```
Initial query: "deployment process"
Results: Too many general documents about various deployment processes
Agent analysis: "I need to be more specific about which service"
Refined query: "deployment process for the payment microservice"
Results: Specific runbook for the payment service deployment
```

### 诊断 tool

Agent 可以使用诊断 tool 来评估 retrieval 的质量：

- **相关性评分：** 为每个检索文档对问题的相关性打分
- **覆盖检查：** 验证问题的各个方面都被覆盖
- **矛盾检测：** 标记不同来源之间的不一致
- **置信度估计：** 基于证据评估对答案的置信程度

### 人工兜底

当多次尝试后仍找不到满意答案时，Agent 会上报给人工，而不是胡乱猜测。这是关键的安全机制。

```
Agent: "I searched our knowledge base for information about
the 2024 data migration project but could not find sufficient
documentation. I found references to it in three documents,
but none contained the specific timeline you asked about.
I recommend checking with the Data Engineering team directly."
```

## 何时使用 basic RAG，何时使用 agentic RAG

并非每个用例都需要完整的 agentic 方案。下面是选择指南：

### 使用 basic RAG 的情形：

- 问题简单直接（"What is our return policy?"）
- 答案通常存在于单一文档中
- 延迟至关重要（agentic RAG 增加多次 LLM 调用）
- 成本是主要约束
- 知识库较小且组织良好
- 准确率要求中等

### 使用 agentic RAG 的情形：

- 问题复杂且开放（"Analyze our customer churn trends"）
- 答案需要综合多个文档
- 用户期望研究级深度
- 知识库庞大、多样或组织混乱
- 准确性至关重要，错误代价高
- 问题往往需要澄清或拆解

### 成本与延迟对比

| Aspect | Basic RAG | Agentic RAG |
|---|---|---|
| 每次查询的 LLM 调用 | 1 | 3-10+ |
| 每次查询的检索调用 | 1 | 2-5+ |
| 典型延迟 | 1-3 秒 | 5-30 秒 |
| token 成本 | 低 | 高出 3-10 倍 |
| 简单问题的答案质量 | 好 | 类似（杀鸡用牛刀） |
| 复杂问题的答案质量 | 一般 | 好到出色 |

## ELI5：图书管理员 vs. 研究助理

basic RAG 就像向图书管理员问一个问题。你走到柜台说："Do you have a book about dinosaurs?" 管理员查目录、找到一本书递给你。如果这本书没回答你的具体问题，那也没办法——你只能拿到这一本。

agentic RAG 则像雇了一位研究助理。你说："I need to understand why dinosaurs went extinct." 助理跑到图书馆，抽出几本书，翻阅之后发现一本过时了，把它放回；找到一篇更新的论文，对照两种不同的理论，核实引用，最后带回一份引用清晰的小结。如果在图书馆找不到足够信息，他还会查在线数据库。如果发现信息有冲突，他会指出分歧并说明双方观点。

图书管理员给你一本书。研究助理给你一个答案。

## 在 Google Cloud 上做 agentic RAG

Google Cloud 提供多种实现 agentic RAG 的构件：

### Vertex AI RAG engine

[Vertex AI RAG Engine](https://cloud.google.com/vertex-ai/generative-ai/docs/rag-overview) 为 RAG pipeline 提供托管基础设施。它处理文档导入、切分、embedding 与检索，让你专注于 agentic 逻辑。

主要特性：
- 托管式向量搜索，自动建索引
- 多种数据源连接器（Cloud Storage、Google Drive、网页 URL）
- 可配置的切分与 embedding 策略
- 与 Vertex AI 模型 endpoint 集成

### Vertex AI Agent engine

[Vertex AI Agent Engine](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview) 让你构建以 RAG 作为 tool 的 Agent。Agent 可以决定何时搜索、查询哪些数据源以及如何整合结果。

### 构建循环

在 Google Cloud 上的实用 agentic RAG 实现可能是这样：

```
User Query
    |
    v
[Vertex AI Agent Engine]
    |-- Plans retrieval strategy
    |-- Calls RAG Engine (possibly multiple times)
    |-- Evaluates results
    |-- Reformulates if needed
    |-- Generates grounded answer
    |
    v
Verified Answer with Citations
```

## 实用实现模式

### 模式 1：查询拆解

在 retrieval 之前，把复杂查询拆成更简单的子查询。

```
User: "Compare our engineering team's velocity this quarter
       with last quarter and identify bottlenecks"

Agent decomposes into:
  1. "Engineering team velocity metrics Q3 2025"
  2. "Engineering team velocity metrics Q2 2025"
  3. "Engineering bottlenecks Q3 2025"
  4. "Sprint retrospective findings Q3 2025"

Each sub-query retrieves independently, then the agent
synthesizes a comparative analysis.
```

### 模式 2：带验证的 retrieval

生成答案后，对照源文档逐条核验论断。

```
Generated answer: "Revenue increased 15% in Q3..."
Verification step:
  - Claim: "Revenue increased 15%"
  - Source document states: "Revenue grew 15.2% year-over-year"
  - Verdict: Supported (minor rounding)

Generated answer: "...driven primarily by the APAC region"
Verification step:
  - Claim: "driven primarily by APAC"
  - Source documents: No mention of APAC as primary driver
  - Verdict: Not supported - needs re-retrieval
```

### 模式 3：迭代深入

从宽泛搜索开始，根据所得逐步收窄。

```
Round 1: Broad search for "customer complaints Q3"
  -> Found: Common themes include shipping delays, product quality

Round 2: Focused search for "shipping delay root cause Q3"
  -> Found: Warehouse staffing issues in September

Round 3: Specific search for "warehouse staffing September impact"
  -> Found: 40% increase in fulfillment time due to understaffing

Agent now has a complete chain from symptoms to root cause.
```

### 模式 4：来源三角验证

查询多个独立来源并寻找一致之处。

```
Question: "What is the expected release date for Project Phoenix?"

Source 1 (Project tracker): "Target: March 15"
Source 2 (Team standup notes): "Aiming for mid-March release"
Source 3 (Executive update): "Phoenix launching March 15-20 window"

Agent: "Multiple sources converge on a mid-March release,
specifically targeting March 15-20."
```

## 常见陷阱

### 陷阱 1：无限 retrieval 循环

Agent 因为永远不认为结果"足够好"而不停搜索。一定要为 retrieval 迭代设最大次数（通常 3-5 次），并在到达上限时让 Agent 给出附带置信度提示的最佳答案。

### 陷阱 2：检索过多

Agent 检索过多文档，把 context window 撑爆。为每次检索的文档数量与总 context 大小设上限。优先相关性，而非数量。

### 陷阱 3：忽视检索到的 context

Agent 检索了文档，却基于训练数据来生成答案，而非使用检索内容。使用强约束指令，要求 Agent 基于检索文档作答并显式引用。

### 陷阱 4：信息缺失时无兜底

Agent 在知识库不含所需信息时仍试图作答。训练 Agent 识别缺口，并说"在可用资源中未找到关于 X 的信息"，而不是 hallucinate。

## 实战练习

为一个技术文档用例构建一个 agentic RAG 系统：

1. **准备：** 选定一组技术文档（你自己的项目文档，或公开文档集合，如 Google Cloud 文档）。

2. **basic RAG 基线：** 实现一个简单的 retrieve-then-read 流水线。用五个不同复杂度的问题测试。

3. **加入 agentic 能力：** 至少实现以下两项：
   - 复杂问题的查询拆解
   - 带重查的结果评估
   - 多源 retrieval
   - 答案对照源文档的验证

4. **对比：** 用同样的五个问题分别跑两个系统。记录在哪些场景下 agentic 版本产出更好的答案，又在哪些场景下增加了不必要的开销。

## 关键要点

- basic RAG 走的是固定的 retrieve-then-read 流水线。agentic RAG 把 retrieval 的主导权交给 Agent，由它决定何时搜索、搜索什么、结果是否足够。
- agentic RAG 的循环——plan、retrieve、evaluate、refine、answer、verify——以迭代精炼取代了一次性方案。
- 关键能力包括自主的 query planning、自适应的来源选择、上下文感知的扩展，以及多跳推理。
- 通过重查、诊断检查与人工兜底实现的自我纠错，可以避免系统在糟糕结果上勉强提交。
- 对速度优先的简单查询使用 basic RAG；对准确性高于延迟的复杂研究问题使用 agentic RAG。
- 为 retrieval 迭代次数与 context 大小设清晰上限，避免死循环与失控成本。

## 延伸阅读

- [Vertex AI RAG Engine Overview](https://cloud.google.com/vertex-ai/generative-ai/docs/rag-overview) - Google Cloud 上的托管 RAG 基础设施
- [Vertex AI Agent Engine Overview](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview) - 在 Vertex AI 上构建以 RAG 为 tool 的 Agent
