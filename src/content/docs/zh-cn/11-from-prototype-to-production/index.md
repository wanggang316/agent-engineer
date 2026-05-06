---
title: "Lesson 11: 从原型到生产 — 把你的 Agent 真正交付出去"
---

## 引言

你已经做出一个能跑的 Agent。它能搞定测试用例，演示时让团队赞叹，看起来像魔法一样。现在你需要把它交付给真实用户。这才是难的开始。

「能在我笔记本上跑」与「能为成千上万用户稳定运行」之间的鸿沟巨大。在传统软件中，production readiness 主要意味着处理边界情况、扩容、监控；而对 Agent 而言，除了这一切，你还要面对一个根本性的难题 —— 系统行为是非确定的、难以完全预测的。

### ELI5：把 Agent 推上生产就像开餐厅

你一直在家里给朋友们做菜，大家都喜欢你的手艺。现在你想开一家餐厅。突然之间，那些在家做菜从未需要考虑的事都得想清楚：卫生检查、供应链、保证每盘菜口味一致的标准化食谱、培训员工、处理投诉、控制成本，以及保证忙碌的周六晚上厨房不会着火。烹饪本身没变，但围绕烹饪的一切都被彻底重塑。

这就是从原型到生产的鸿沟。Agent 的核心逻辑可能改变不大，但它周围的一切 —— 评估、部署、监控、成本管理、团队流程 —— 都得从零搭起。

> **关键要点：** 从原型到生产的「最后一公里」往往占整体工作的 80%。从一开始就为它做规划。

---

## 生产化鸿沟

从原型走到生产，下列维度都会变化：

| Dimension | Prototype | Production |
|-----------|-----------|------------|
| **Users** | You and your team | Hundreds or thousands of real users |
| **Inputs** | Curated test cases | Anything anyone types, including adversarial input |
| **Uptime** | Restart when it breaks | Must be available 24/7 with graceful degradation |
| **Latency** | "It takes a few seconds" is fine | Users expect sub-second responses for simple queries |
| **Cost** | Burn rate does not matter | Every token costs money at scale |
| **Quality** | "Usually works" is acceptable | Consistent quality is required; bad responses erode trust |
| **Safety** | Informal testing | Systematic guardrails, monitoring, and incident response |
| **Debugging** | Print statements | Structured logs, traces, and metrics |
| **Updates** | Edit and restart | CI/CD pipeline with evaluation gates |

### 演示为什么会骗人

演示之所以好看，是因为做演示的人知道哪些输入效果好。他们会避开边界情况，失败时悄悄重试，从多次运行中挑最好的那一次。

生产则恰恰相反。真实用户会：
- 拼错字、用俚语、用意想不到的语言
- 问 Agent 从未被设计去处理的问题
- 给出极长或极短的输入
- 不满意时，会反复用同样的查询尝试
- 发现你从未想过的失败模式

这就是为什么 evaluation-gated 部署如此重要。一个尚未在覆盖广泛真实场景的测试集上验证过的 Agent 版本，不应该被发布。

---

## 团队角色：谁在参与

把 Agent 推上生产不是一个人的事，通常需要多个角色协作：

| Role | Responsibility |
|------|---------------|
| **AI Engineer** | Agent logic, prompt design, tool integration, eval creation |
| **Platform Engineer** | Infrastructure, deployment pipelines, service mesh, scaling |
| **Data Engineer** | Data pipelines for RAG, knowledge bases, training data management |
| **ML Ops / AI Ops** | Model serving, versioning, A/B testing, monitoring dashboards |
| **DevOps / SRE** | Reliability, incident response, alerting, cost tracking |
| **Product Manager** | User requirements, success metrics, prioritization |
| **Security / Trust & Safety** | Guardrails, red teaming, compliance, safety reviews |

在小团队里，一个人可能身兼多职，但这些职责依然存在，无论由几个人分担。

---

## evaluation-gated 部署

这是安全交付 Agent 最重要的一项实践。原则很简单：**没通过 evals 的 Agent 版本，绝不上线。**

我们在 Lesson 9 里讲过怎么构建 evals。下面是它在部署流程中的位置：

```
Code Change --> Evals Pass? --No--> Fix and retry
                    |
                   Yes
                    |
                    v
              Deploy to staging
                    |
                    v
            Staging evals pass? --No--> Fix and retry
                    |
                   Yes
                    |
                    v
            Deploy to production (canary)
                    |
                    v
          Production metrics OK? --No--> Rollback
                    |
                   Yes
                    |
                    v
            Full production rollout
```

### 一个好的 eval gate 应当包含什么

用于部署的 eval 套件应覆盖：

| Category | What to Test | Pass Criteria |
|----------|-------------|---------------|
| **Functional correctness** | Does the agent produce correct answers? | >= threshold on accuracy metrics |
| **Tool usage** | Does the agent call the right tools with correct arguments? | Tools called correctly in >= X% of cases |
| **Safety** | Does the agent resist prompt injection and follow policies? | 100% pass rate on safety-critical cases |
| **Latency** | Does the agent respond within acceptable time? | P95 latency < target |
| **Cost** | Does the agent stay within token budgets? | Average cost per interaction < budget |
| **Regression** | Do previously passing cases still pass? | No regressions on known-good cases |

安全 evals 应设硬门槛 —— 任何失败都阻止部署。其他类别可以设置更宽松的阈值，在整体质量提升的前提下接受小幅回退。

---

## 面向 Agent 的 CI/CD

Agent 的持续集成与持续部署遵循与传统 CI/CD 相同的原则，但增加了 Agent 特有的步骤。可以把它分成三个阶段。

### 阶段 1：合并前（每个 pull request）

这些检查跑得快，能在代码合并前抓出明显问题。

```yaml
# Example: Pre-merge checks
pre_merge:
  - lint:
      - Check prompt formatting and syntax
      - Validate tool definitions match schemas
      - Static analysis of agent configuration

  - unit_tests:
      - Test individual tool functions
      - Test guardrail logic
      - Test input/output parsers

  - basic_evals:
      - Run a small, fast eval set (50-100 cases)
      - Focus on regression detection
      - Target: completes in < 5 minutes
```

### 阶段 2：合并后（每次合入 main）

代码合并后，跑更全面的检查，再推上 staging。

```yaml
# Example: Post-merge validation
post_merge:
  - staging_deployment:
      - Deploy to staging environment
      - Verify health checks pass

  - broad_evals:
      - Run full eval suite (500-1000+ cases)
      - Include safety evals
      - Include latency and cost benchmarks
      - Target: completes in < 30 minutes

  - integration_tests:
      - Test end-to-end flows with real tool connections
      - Verify external service integrations
```

### 阶段 3：生产 gate（部署到生产前）

真实用户看到新版本之前的最后一道门。

```yaml
# Example: Production gate
production_gate:
  - full_evals:
      - Complete eval suite including edge cases
      - Adversarial test cases
      - Cross-model consistency checks (if using multiple models)

  - safety_review:
      - Automated safety evals must pass 100%
      - Human review for significant prompt changes
      - Red team sign-off for major feature changes

  - approval:
      - Automated approval if all checks pass
      - Manual approval required if any check is marginal
```

### 在 CI/CD 中管理 prompt

prompt 应享有与代码同等的版本管理纪律：

- 把 prompt 放进版本控制（不要塞进数据库或难以 diff 的配置服务）
- 像审代码一样，在 pull request 中审 prompt 改动
- 跟踪每个环境部署的是哪个 prompt 版本
- 保证可以方便地回滚到上一版 prompt

```
prompts/
  customer_support/
    system_prompt.txt      # The main system instructions
    tool_descriptions.txt  # Tool descriptions and schemas
    safety_rules.txt       # Safety-specific instructions
    version.txt            # Current version identifier
```

---

## 安全的 rollout 策略

哪怕 evals 再充分，生产环境也总能给你惊喜。安全的 rollout 策略让出问题时的影响范围可控。

### canary 部署

把一小部分流量导到新版本上，观察问题，再决定是否扩大比例。

```
Traffic ---> [Load Balancer]
                |         |
               95%       5%
                |         |
                v         v
         [Version 1]  [Version 2 - Canary]
         (current)     (new)
```

**怎么做：**
1. 把新版本和当前版本同时部署
2. 把 5% 流量导到新版本
3. 监控关键指标（错误率、延迟、用户满意度、安全事件）
4. 如果一段时间内指标健康，依次提升到 25%、50%、100%
5. 如果任何指标恶化，把所有流量切回当前版本

### blue-green 部署

维护两套完全相同的生产环境，把所有流量从一套切到另一套。

```
Before:  Traffic --> [Blue - v1.2 ACTIVE]    [Green - idle]
During:  Traffic --> [Blue - v1.2]            [Green - v1.3 ACTIVE]
```

优势是切换干净、回滚瞬时（切回 Blue 即可）。代价是过渡期需要双倍基础设施。

### A/B 测试

把流量导给不同的 Agent 版本，在真实交互上比较它们的表现。

| Version A | Version B | Metric | Winner |
|-----------|-----------|--------|--------|
| GPT-based, verbose prompts | Gemini-based, concise prompts | Task completion rate | Compare after N interactions |
| ReAct pattern | Plan-then-execute | User satisfaction | Compare after N interactions |
| Model A, 3 tool retries | Model A, 1 tool retry | Cost per interaction | Compare after N interactions |

A/B 测试对 Agent 尤其有价值，因为它能让你在真实流量上比较不同模型、prompt 与架构。

### feature flag

用运行时开关控制 Agent 能力，无需重新部署即可切换。

```python
# Example: Feature flags for agent capabilities
if feature_flags.is_enabled("new_refund_flow", user_id=user.id):
    agent.enable_tool("process_refund_v2")
else:
    agent.enable_tool("process_refund_v1")

if feature_flags.is_enabled("extended_context_window"):
    agent.set_max_context(128000)
else:
    agent.set_max_context(32000)
```

feature flag 让你可以渐进发布新能力、快速关停问题特性，并对部分用户做实验。

---

## 生产环境的可观测性

Agent 跑在生产环境后，你需要看清它在做什么。Agent 的可观测性同样有三大支柱，与传统系统类似 —— 但具体做法有差异。

### Logs

捕获 Agent 生命周期中每一个重要事件的结构化日志：

```json
{
  "timestamp": "2025-06-15T10:23:45Z",
  "session_id": "sess_abc123",
  "event": "tool_call",
  "tool": "search_knowledge_base",
  "arguments": {"query": "return policy for electronics"},
  "result_status": "success",
  "latency_ms": 234,
  "tokens_used": {"input": 1250, "output": 380}
}
```

**该记录什么：**
- 每次 LLM 调用（模型、输入 token、输出 token、延迟）
- 每次 tool 调用（tool 名、参数、结果状态、延迟）
- Agent 决策（选了哪条路径，原因是什么）
- guardrail 触发（拦截了什么，为什么）
- 升级事件
- 会话开始/结束及汇总指标

### Traces

Traces 展示一次请求穿过 Agent 的完整旅程，包括沿途所有步骤、tool 调用与决策。

```
[User Request] "Help me return my order"
    |
    +-- [LLM Call 1] Understand intent (150ms)
    |       Model: gemini-2.0-flash, Tokens: 800 in / 120 out
    |
    +-- [Tool Call] lookup_order(order_id="12345") (340ms)
    |       Status: success
    |
    +-- [Tool Call] check_return_eligibility(order_id="12345") (180ms)
    |       Status: success, eligible=true
    |
    +-- [LLM Call 2] Generate response (200ms)
    |       Model: gemini-2.0-flash, Tokens: 1200 in / 250 out
    |
    +-- [Output Guardrail] PII check (15ms)
    |       Status: pass
    |
    [Response] "Your order #12345 is eligible for return..."

    Total: 885ms, Cost: $0.003
```

[OpenTelemetry](https://opentelemetry.io/) 是分布式 tracing 的行业标准。许多 Agent 框架原生支持 OpenTelemetry，Google Cloud 的运维套件（Cloud Logging、Cloud Trace、Cloud Monitoring）也原生集成 OpenTelemetry。

### Metrics

按时间聚合、反映整体表现的指标：

| Metric | What It Tells You | Alert Threshold Example |
|--------|-------------------|------------------------|
| **Task completion rate** | How often the agent successfully completes user requests | Drop below 85% |
| **Average latency** | How long users wait for responses | P95 exceeds 5 seconds |
| **Cost per interaction** | How much each conversation costs | Average exceeds $0.10 |
| **Escalation rate** | How often the agent hands off to humans | Exceeds 20% |
| **Safety incident rate** | How often guardrails are triggered | Any increase above baseline |
| **Tool error rate** | How often tool calls fail | Exceeds 5% |
| **User satisfaction** | Thumbs up/down or CSAT scores | Drops below 4.0/5.0 |

### 构建仪表盘

一个生产 Agent 仪表盘应当一眼看清：

```
+-------------------------------------------------------+
|  Agent Health Dashboard                                |
+-------------------------------------------------------+
|                                                        |
|  Status: HEALTHY          Active Sessions: 1,247       |
|                                                        |
|  +-------------------+  +-------------------+          |
|  | Completion Rate   |  | Avg Latency       |          |
|  | 92.3% (+0.5%)     |  | 1.2s (-0.1s)      |          |
|  +-------------------+  +-------------------+          |
|                                                        |
|  +-------------------+  +-------------------+          |
|  | Cost / Session    |  | Escalation Rate   |          |
|  | $0.042 (-$0.003)  |  | 8.1% (+0.2%)      |          |
|  +-------------------+  +-------------------+          |
|                                                        |
|  Recent Safety Incidents: 0 (last 24h)                 |
|  Recent Errors: 12 (last 24h, 0.04% of sessions)      |
|                                                        |
+-------------------------------------------------------+
```

---

## Observe-Act-Evolve 循环

生产并不是终点，而是持续改进周期的起点。

```
    +----------+
    | Observe  |  <-- Collect metrics, logs, traces, user feedback
    +----+-----+
         |
         v
    +----+-----+
    |   Act    |  <-- Identify issues, prioritize improvements
    +----+-----+
         |
         v
    +----+-----+
    |  Evolve  |  <-- Update prompts, tools, evals, guardrails
    +----+-----+
         |
         +-------> Back to Observe
```

### Observe

收集 Agent 在生产中的表现数据：

- **定量：** 指标仪表盘、生产流量上的自动化 eval 结果
- **定性：** 用户反馈、客服工单、对话回看
- **对抗性：** 持续 red teaming、新攻击模式监测

### Act

把观察转化为具体行动：

- 在某类 query 上失败？把它加进 eval 集，并改进 prompt。
- tool 错误率飙升？查根因，加更好的错误处理。
- 用户对某种回复模式持续困惑？修订 Agent 指令。
- 发现新的攻击向量？加 guardrail 与安全 eval。

### Evolve

通过 evaluation-gated 的 CI/CD 流水线发布改进：

- 更新 prompt 并重跑 evals
- 新增或修改 tools
- 扩充 eval 套件覆盖新发现的边界情况
- 根据观察到的威胁调整 guardrail
- 出现更好选择时重训或更换模型

关键在于：你的 eval 套件会随时间不断增长。每一次生产事故、每一次用户投诉、每一种边界情况都成为新的 eval。也就是说，每一次迭代都让 Agent 更难被攻破。

---

## 成本管理

基于 LLM 的 Agent 在规模下可能很贵。一次对话可能涉及多次 LLM 调用，每次消耗数千 token；乘上数千用户，成本累积得很快。

### 模型路由

让最便宜、能胜任任务的模型来处理。不是每一步都需要最强模型。

```
User Query
    |
    v
[Router] --Simple query--> Gemini Flash-Lite ($)
    |
    +-----Medium complexity--> Gemini Flash ($$)
    |
    +-----Complex reasoning--> Gemini Pro ($$$)
```

| Task Type | Recommended Model Tier | Rationale |
|-----------|----------------------|-----------|
| Intent classification | Small / Flash-Lite | Simple classification task |
| Information retrieval | Medium / Flash | Needs good comprehension, moderate generation |
| Complex reasoning | Large / Pro | Multi-step reasoning, nuanced judgment |
| Summarization | Medium / Flash | Good balance of quality and cost |
| Safety checks | Small / Flash-Lite | Pattern matching, classification |

### 缓存

对重复或相似查询缓存回复，避免重复的 LLM 调用。

| Caching Strategy | When to Use |
|-----------------|-------------|
| **Exact match cache** | FAQ-style queries where many users ask the same thing |
| **Semantic cache** | Queries that are different in wording but identical in meaning |
| **Tool result cache** | Tool outputs that do not change frequently (e.g., product catalog lookups) |
| **Prompt cache** | Reuse cached prefixes for system prompts across calls (Vertex AI supports context caching) |

### token 预算

为每个会话设置 Agent 可消耗 token 数的硬上限。

```python
# Example: Token budget enforcement
class TokenBudget:
    def __init__(self, max_tokens: int):
        self.max_tokens = max_tokens
        self.used_tokens = 0

    def can_proceed(self, estimated_tokens: int) -> bool:
        return (self.used_tokens + estimated_tokens) <= self.max_tokens

    def record_usage(self, actual_tokens: int):
        self.used_tokens += actual_tokens

# Usage
budget = TokenBudget(max_tokens=50000)  # per session

while agent.has_next_step():
    estimated = agent.estimate_next_step_tokens()
    if not budget.can_proceed(estimated):
        agent.respond("I have reached my processing limit for this session. "
                      "Let me summarize what I have found so far.")
        break
    result = agent.execute_next_step()
    budget.record_usage(result.tokens_used)
```

### 成本监控

在多个层级跟踪成本：

| Level | What to Track | Why |
|-------|--------------|-----|
| **Per request** | Tokens used, model tier, tool calls | Debug expensive individual requests |
| **Per session** | Total cost of a conversation | Set and enforce per-session budgets |
| **Per user** | Aggregate cost per user over time | Identify usage patterns and outliers |
| **Per feature** | Cost of specific agent capabilities | Decide which features are cost-effective |
| **Overall** | Daily/weekly/monthly spend | Budget planning and forecasting |

---

## production readiness 清单

在让真实用户接触 Agent 之前，逐项过一遍这份清单：

### 可靠性
- [ ] 配置健康检查与 liveness probe
- [ ] 在依赖失败时优雅降级（模型 API 宕机、tool 不可用）
- [ ] 对瞬时错误使用指数退避重试
- [ ] 给外部服务调用加熔断器
- [ ] 给所有 LLM 与 tool 调用加超时

### 部署
- [ ] CI/CD 流水线在每个阶段都有 eval gate
- [ ] 回滚流程已测试并文档化
- [ ] 配置 canary 或 blue-green 部署
- [ ] 用 feature flag 控制新能力
- [ ] prompt 版本管理与变更跟踪

### 可观测性
- [ ] 为所有 Agent 事件配置结构化日志
- [ ] 用 OpenTelemetry 实现分布式 tracing
- [ ] 关键指标仪表盘（完成率、延迟、成本、安全）
- [ ] 关键阈值告警
- [ ] On-call 轮值与事件响应 runbook

### 成本
- [ ] 配置模型路由（每个任务用合适的模型）
- [ ] 实施缓存策略
- [ ] 每会话 token 预算
- [ ] 成本监控与告警
- [ ] 定期成本复盘与优化

### 安全
- [ ] 实现并测试 Lesson 10 中的 guardrails
- [ ] 安全 evals 通过率 100%
- [ ] 完成 red team 评审
- [ ] 安全失败的事件响应预案
- [ ] 用户上报问题的反馈渠道

---

## 关键要点

1. **从原型到生产的鸿沟真实且巨大。** 从一开始就为生产关切做规划。「最后一公里」是大头。

2. **evaluation-gated 部署不可妥协。** 没有通过完整 eval 套件的 Agent 版本不应进入生产。eval 套件就是你的质量保证。

3. **Agent 的 CI/CD 分三阶段。** 合并前检查快速抓出明显问题；合并后跑更广 evals；生产 gate 在影响真实用户前确保安全与质量。

4. **安全的 rollout 策略限制影响范围。** canary 部署、feature flag、A/B 测试让你在影响所有用户前抓出问题。

5. **可观测性必不可少。** 看不到就改不了。从第一天就投入 logs、traces、metrics。

6. **成本管理需要主动投入。** 模型路由、缓存与 token 预算可以在不牺牲质量的前提下显著降低成本。

7. **生产是开始，不是终点。** Observe-Act-Evolve 循环让 Agent 基于真实使用持续进化。

---

## 延伸阅读

- [Deploy Agents on Vertex AI Agent Engine](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/deploy) — 在 Google Cloud 上部署 Agent 的官方指南
- [Agent Starter Pack](https://github.com/GoogleCloudPlatform/agent-starter-pack) — 在 Google Cloud 上部署 Agent 的 production-ready 模板，自带 CI/CD、可观测性与评估
- [Vertex AI Model Monitoring](https://cloud.google.com/vertex-ai/docs/model-monitoring/overview) — 监控生产中的模型表现
- [OpenTelemetry](https://opentelemetry.io/) — 分布式 tracing 与可观测性的行业标准

---

下一课：[Getting Started with Vertex AI and ADK](/12-getting-started-with-vertex-and-adk/)
