# Translation Glossary

Translators MUST follow this glossary. The goal is consistent, idiomatic Chinese translation while preserving the precise English terms that the AI/agents community already uses.

## 1. Hard rules

- **Do NOT translate code, code comments, command-line text, file paths, identifiers, URLs, or YAML/JSON keys.** Keep them in English exactly as in the source.
- **Do NOT translate the terms in the "Keep in English" list** below — even when they appear in prose. Wrap them as plain text (no italics added).
- Keep all Markdown structure identical: headings, lists, tables, blockquotes, code fences, link targets, image paths.
- Preserve frontmatter (`---` blocks) verbatim except for translating the `title` and `description` values.
- Preserve all internal links unchanged (e.g. `(/05-memory-and-context/)`). The Chinese site reuses the same slugs.
- Keep external URLs unchanged.
- When source mixes English with quoted Chinese-friendly term, keep both.

## 2. Keep in English (do NOT translate)

These are technical terms / proper nouns / canonical jargon. Always keep English form, capitalisation as in source:

```
Agent, agent, AI agent, AI agents, agentic
LLM, LLMs, model, models
prompt, prompting, system prompt
tool, tool calling, function calling, tool use
ReAct, Chain-of-Thought, CoT, Tree-of-Thoughts
RAG, retrieval, retrieval-augmented generation
MCP, Model Context Protocol, A2A, Agent2Agent
ADK, Agent Development Kit, Vertex AI, Gemini, Google Cloud
AGENTS.md, CLAUDE.md, README.md
guardrails
orchestrator, orchestration
context window, context, embeddings, embedding
fine-tune, fine-tuning, RLHF, alignment
skills, agent skills
prompt injection, jailbreak, jailbreaking
sandbox, sandboxing
hallucination, hallucinate
token, tokens, tokenizer
streaming, batch, batching
evals, eval, evaluation harness
observability, tracing, telemetry
checkpoint, replay
multi-agent, single-agent
human-in-the-loop, HITL
function-calling JSON, JSON Schema
SDK, API, CLI, REST, gRPC, HTTP
codelab, codelabs
DAG
```

When such a term needs an explanation on first use, it is fine to add a short Chinese gloss in parentheses. Example: `LLM（大语言模型）`. Use this sparingly — once per chapter at most for any given term.

## 3. Preferred Chinese renderings (translate consistently)

| English | 中文 |
|---|---|
| course | 课程 |
| lesson | 课时 |
| fundamentals | 基础 |
| building and shipping | 构建与交付 |
| deep dives | 专题深入 |
| software engineer | 软件工程师 |
| design pattern | 设计模式 |
| memory | 记忆 |
| planning | 规划 |
| reasoning | 推理 |
| multi-agent systems | 多 Agent 系统 |
| safety | 安全 |
| trustworthy | 可信 |
| from prototype to production | 从原型到生产 |
| protocol | 协议 |
| open standard | 开放标准 |
| reference | 参考 |
| trade-off, tradeoff | 取舍 |
| best practice | 最佳实践 |
| under the hood | 底层原理 |
| getting started | 入门 |
| official docs | 官方文档 |
| analogy | 类比 |
| mental model | 心智模型 |
| step by step | 一步一步 |
| stack | 技术栈 |
| pattern | 模式 |
| coordination | 协作 |
| delegation | 委派 |
| teamwork | 团队协作 |
| retrieval | 检索 |
| evaluate | 评估 |
| evaluating | 评估 |
| test | 测试 |
| testing | 测试 |
| metrics | 指标 |
| observability | 可观测性 |
| safety / responsible AI | 安全 / 负责任的 AI |
| rollout | 上线 |
| operations | 运维 |
| hands-on | 实战 |
| reusable | 可复用 |
| portable | 便携 |
| skill module | 技能模块 |
| control flow | 控制流 |
| framework | 框架 |
| prerequisite | 前置条件 |
| community | 社区 |
| resources | 资源 |
| next steps | 下一步 |

## 4. Tone & style

- 受众：Gemini/Vertex/ADK 不熟悉、但有一定开发经验的软件工程师。
- 句式偏简洁、技术化、直叙；避免「让我们…」「我们将…」之类口语化扩写。
- 行文以「Agent」「LLM」等英文词为主词时，量词使用「个」：一个 Agent、几个 Agent。
- 列表条目尽量动宾结构开头。
- 标题大小写：源文档常用 sentence case；中文标题不需要冒号后大写规则，遵循自然中文标点。中文与英文/数字之间空一格。

## 5. Frontmatter handling

Source page (English) uses:
```yaml
---
title: "Lesson 5: memory and context - how agents remember"
---
```

Chinese page should become:
```yaml
---
title: "Lesson 5: memory 与 context — Agent 如何记忆"
---
```

Rules:
- Keep `Lesson N:` prefix in English.
- Translate descriptive part to Chinese; keep technical terms per glossary.
- Replace ASCII hyphen `-` (used as title dash) with em dash `—` for readability.

## 6. Markdown anchors and tables

- Translate table headers and cell text per glossary. Do not change column counts.
- Don't manually localise heading anchors. Starlight regenerates them from the translated heading text.
- For internal cross-references (`see Lesson 7`), keep `Lesson 7` in English, e.g. `参见 Lesson 7`.
