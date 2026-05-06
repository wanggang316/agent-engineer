---
title: "Lesson 18: agent skills — Agent 的可复用知识"
---

## 引言

在 [Lesson 3](/03-tools-giving-agents-hands/) 中，我们学习了 tools——让 Agent 能够调用 API、查询数据库、运行代码等执行动作的函数。Tools 关注的是 **做事**。

Skills 关注的是 **知事**。一个 skill 把领域专长——指令、最佳实践、决策框架与参考资料——打包成模块化单元，供 Agent 在需要时发现并使用。

类比一下，给某人一把扳手（一个 tool）和给他一本维修手册（一个 skill）的区别。扳手让他能拧螺栓。手册告诉他该拧哪些螺栓、按什么顺序、需要注意什么。

### ELI5：把 skills 想成厨房里的菜谱卡

一间专业厨房里既有 tools（刀、锅、烤箱）也有菜谱卡。新来的厨师不需要说明书就能拿起一把刀。但要做某道菜，他就需要菜谱卡——它告诉他用哪些 tools、按什么顺序、用什么温度，以及最终成品应该是什么样子。

Agent skills 的工作方式相同。它们就是菜谱卡，告诉 Agent 如何处理某种特定类型的任务、使用哪些 tools、好的产出应是什么样子。

> **关键要点：** Skills 把领域专长编码为便携、可复用的包。Tools 让 Agent 能行动。Skills 告诉 Agent 在何时、如何行动。

---

## 为什么需要 skills

设想这样一个场景：你团队里有一个帮助做 code review 的 Agent。你希望它遵循团队特定的 review 清单，标记你关心的常见模式，并以特定方式格式化反馈。

你可以把这一切都写进 Agent 的 system prompt。但 system prompt 很快就会臃肿。如果你把 review 指令、部署流程、文档规范、测试约定都塞进同一个 prompt，最终得到的是一个膨胀的 context window 和一个样样平庸的 Agent。

Skills 通过以下方式解决这个问题：

1. **把专长分开打包**——每个 skill 都是独立文件，专注于一个领域
2. **按需加载**——skill 只在相关时才加载，节省 context window 空间
3. **跨团队共享**——一个写得好的 skill 可以在多个项目和 Agent 间复用
4. **独立迭代**——更新一个 skill 不需要改动 Agent 的核心配置

### context window 问题

这是关键的技术动机。context window 中的每一个 token 都有成本——既是金钱成本也是注意力成本。如果你在启动时加载 50,000 个 token 的指令，Agent 在每一轮交互中都要支付这份成本，即便其中绝大多数指令此刻并不相关。

Skills 通过渐进式披露（progressive disclosure）来降低这部分成本：

- 启动时只加载 skill 的名称与描述（每个约 100 个 token）
- 当某个 skill 被触发时，加载它的完整指令
- 仅当指令明确需要时，才加载参考资料

一项分析显示，这种做法把一份 150,000 token 的工作流在启动阶段降到了约 2,000 个 token。

---

## skill 规范

Skills 遵循一份开放规范，由 [agentskills.io](https://agentskills.io/specification) 维护。格式很简单：

### 目录结构

```
my-skill/
  SKILL.md          # Required: metadata + instructions
  references/       # Optional: additional documentation
  assets/           # Optional: templates, schemas, data files
  scripts/          # Optional: executable code
```

唯一必需的文件是 `SKILL.md`。其它都是可选的。

### SKILL.md 格式

一个 SKILL.md 文件包含两部分：用于 metadata 的 YAML frontmatter，以及用于指令的 Markdown 正文。

```markdown
---
name: code-review
description: >
  Reviews pull requests following team standards. Checks for
  security issues, test coverage, naming conventions, and
  documentation. Use when asked to review code or a PR.
---

## Code Review Process

When reviewing code, follow these steps in order:

### 1. Security check
- Look for hardcoded secrets, SQL injection, XSS vulnerabilities
- Check that user input is validated and sanitized
- Verify authentication and authorization on new endpoints

### 2. Test coverage
- New public functions should have tests
- Edge cases should be covered (empty input, null values, errors)
- Check that tests actually assert meaningful behavior

### 3. Naming and structure
- Functions and variables should have descriptive names
- Files should be in the correct directory per project conventions
- No single function should exceed 50 lines

### 4. Documentation
- Public APIs should have docstrings
- Non-obvious logic should have inline comments
- README should be updated if behavior changes

### Output format
Present findings as a list grouped by category (Security, Tests,
Style, Docs). For each finding, include the file path, line number,
severity (high/medium/low), and a suggested fix.
```

### Frontmatter 字段

| 字段 | 是否必填 | 用途 |
|-------|----------|---------|
| `name` | 是 | 唯一标识，全小写并用连字符分隔（例如 `code-review`） |
| `description` | 是 | 该 skill 的功能与触发条件（最多 1024 字符） |
| `license` | 否 | skill 的许可证 |
| `compatibility` | 否 | 环境要求（例如 "Requires Python 3.10+"） |
| `metadata` | 否 | 任意键值对（作者、版本、标签） |

`description` 字段至关重要。它是 Agent 决定是否激活某个 skill 的主要依据。撰写时应清楚说明该 skill 的功能与适用场景。

---

## 渐进式披露——三层结构

Skills 被设计为分层加载。这是让它们具备实用性的关键架构思想：

### Level 1：Metadata（始终加载）

启动时，Agent 仅从每个已安装 skill 的 frontmatter 中加载 `name` 与 `description`。每个 skill 大约消耗 100 个 token。即便安装了 50 个 skill，启动开销也只有约 5,000 个 token。

Agent 用这些 metadata 来判断："给定当前任务，这个 skill 是否相关？"

### Level 2：Instructions（激活时加载）

当 Agent 判断某个 skill 相关时，它会加载完整的 SKILL.md 正文。这里就是逐步指令、决策框架与示例所在的地方。建议将这部分控制在 5,000 个 token 以内。

### Level 3：Resources（按需加载）

`references/`、`assets/` 与 `scripts/` 目录中的文件，仅在 Level 2 指令引用到时才被加载。它们可能包括：

- `references/security-checklist.md` —— 扩展的安全审查标准
- `assets/api-schema.json` —— 用于校验的 API 规范
- `assets/response-template.md` —— 格式化输出的模板
- `scripts/run-linter.sh` —— Agent 可执行的脚本

这种三层结构让你可以撰写非常详尽的 skill，而无需在前期就支付全部 context 成本。

```
Startup:      [L1: name + description]     ~100 tokens per skill
                        |
Task matches: [L2: full instructions]      ~2,000-5,000 tokens
                        |
As needed:    [L3: reference files]        Variable
```

---

## Skills、tools 与 MCP 的对比

这三者位于不同的层。理解它们的差别有助于你选择合适的方案：

| 维度 | Skills | Tools / Function Calling | MCP |
|-----------|--------|------------------------|-----|
| **提供什么** | 知识与指令 | 可执行函数 | 标准化的 tool 集成协议 |
| **类比** | 一张菜谱卡 | 一台厨房电器 | 电源插座标准 |
| **本质** | 自然语言指引 | 运行的代码 | JSON-RPC 通信层 |
| **执行方式** | LLM 解释指令 | 确定性的函数调用 | 调用远端 tool 的协议 |
| **延迟** | 本地（仅文本） | 取决于函数 | 网络往返 |
| **最佳场景** | 编码专长、工作流、审查标准 | 执行动作（API 调用、文件操作、查询） | 连接需要鉴权与发现的外部服务 |
| **context 成本** | 低（渐进式加载） | 中（每个 tool 一份 schema） | 较高（前期就需加载完整 schema） |

### 三者如何协同

在一个典型的 Agent 中，三者都会被使用：

1. **Skills** 告诉 Agent 如何处理任务以及该用哪些 tools
2. **Tools**（function calling）让 Agent 执行动作
3. **MCP** 提供连接远端 tool 服务的标准方式

示例：一个 "deploy-to-staging" skill 可能包含这样的指令：
- 第 1 步：使用 `run_tests` tool 运行测试套件
- 第 2 步：通过 Kubernetes MCP 服务器检查 staging 环境状态
- 第 3 步：若测试通过且 staging 健康，使用 `deploy` tool 部署
- 第 4 步：通过检查健康端点验证部署结果

skill 提供工作流逻辑。tools 与 MCP 服务器提供执行能力。

---

## 编写优秀的 skill

### 聚焦单一领域

一个 skill 应做好一件事。不要写一个无所不包的 "development" skill，而要为 code review、部署、文档、测试分别建立独立的 skill。

### 写给 LLM 看，而不是给人看

Skills 由语言模型解释。要明确说明：
- **何时**使用该 skill（触发条件）
- **哪些**步骤要执行（有序流程）
- **如何**处理边界情况（决策点）
- **怎样**才算好的产出（示例或模板）

### 包含决策点

真正的专长包括知道何时偏离标准流程：

```markdown
### Handling large PRs (>500 lines changed)

If the PR changes more than 500 lines:
- Focus review on the most critical files first (API endpoints, auth, data models)
- Skip cosmetic issues (formatting, naming) unless they affect readability
- Suggest splitting the PR if the changes cover multiple unrelated concerns
```

### 展示期望的输出

包含 skill 输出应有的样例：

```markdown
### Example output

**Security - High**
`src/api/auth.py:45` - Password is compared using `==` instead of
`hmac.compare_digest()`. This is vulnerable to timing attacks.
Suggested fix: Replace with `hmac.compare_digest(stored_hash, provided_hash)`
```

### 让 L2 指令保持在 5,000 token 以下

如果指令越写越长，把详细的参考材料移到 `references/` 目录中的 L3 文件，并在主指令中引用：

```markdown
For the full security checklist, refer to `references/security-checklist.md`.
```

---

## 在 Google ADK 中的 skills

Google 的 Agent Development Kit 通过 `SkillToolset` 类支持 skills。下面是其工作方式的概念性概览：

### 基于文件的 skills（推荐）

把 skill 目录放在 Agent 项目下的 `skills/` 文件夹中：

```
my-agent/
  agent.py
  skills/
    code-review/
      SKILL.md
      references/
        security-checklist.md
    deploy/
      SKILL.md
      scripts/
        pre-deploy-check.sh
```

Agent 会从该目录发现并加载 skills。启动时只加载 L1 metadata。Agent 激活某个 skill 时再加载完整指令。

### 基于代码的 skills

对于动态创建或修改 skill 的场景，ADK 也支持通过 `Skill` 模型类在代码中定义 skill。当 skill 内容需要根据运行时条件变化时，这种方式很有用。

详细实现指南请参见 [ADK Skills documentation](https://google.github.io/adk-docs/skills/)。

---

## 多平台中的 skills

Agent Skills 规范已被多个平台采用：

| 平台 | 是否支持 | 详情 |
|----------|---------|---------|
| **Claude Code**（Anthropic） | 是 | Skills 作为 `/slash-commands`，仓库见 [anthropics/skills](https://github.com/anthropics/skills) |
| **Google ADK** | 是 | `SkillToolset` 类，支持基于文件与基于代码两种方式 |
| **GitHub Copilot** | 是 | 在 VS Code、CLI 与 Copilot coding agent 中均可用 |
| **OpenAI** | 是 | Agents SDK 提供 skills 支持 |
| **Spring AI** | 是 | Java 生态中通过 `spring-ai-agent-utils` 提供 |

该规范由社区工作组维护，发布在 [agentskills.io](https://agentskills.io/specification)。由于其格式只是目录中的 Markdown 文件，因此 skills 可以在任何支持该规范的平台间便携使用。

---

## 实际示例

### 示例 1：数据库迁移 skill

```markdown
---
name: database-migration
description: >
  Creates and reviews database migrations. Use when the user asks to
  add, modify, or remove database tables or columns, or when reviewing
  migration files.
---

## Creating Migrations

1. Verify the current migration state: run `alembic heads` to check for conflicts
2. Create the migration: `alembic revision --autogenerate -m "description"`
3. Review the generated migration file for:
   - Correct up/down operations (both directions should work)
   - No data loss in down migration
   - Appropriate indexes for new columns
   - Nullable columns for existing tables (to avoid breaking existing rows)
4. Test the migration: `alembic upgrade head` then `alembic downgrade -1`

## Common Pitfalls

- Adding a NOT NULL column to an existing table without a default value
  will fail if the table has existing rows. Always add a default or make
  it nullable first, then backfill.
- Renaming columns requires a two-step migration: add new column, migrate
  data, drop old column. Alembic's autogenerate does not handle renames.
- Large table alterations should be done in batches on production. Add a
  note in the migration file if the table has >1M rows.
```

### 示例 2：故障响应 skill

```markdown
---
name: incident-response
description: >
  Guides incident response and post-mortem creation. Use when there is
  a production incident, outage, or when creating post-mortem documents.
---

## During an Incident

1. Assess severity using the service dashboard at `monitoring.internal/overview`
2. Check recent deployments: `gcloud run revisions list --service=api --limit=5`
3. Check error rates: `gcloud logging read "severity>=ERROR" --limit=50 --freshness=1h`
4. If a recent deployment is suspect, rollback:
   `gcloud run services update-traffic api --to-revisions=PREVIOUS_REVISION=100`

## After Resolution

Create a post-mortem document using the template in `assets/postmortem-template.md`
with these sections filled in:
- Timeline of events (with timestamps)
- Root cause analysis
- Impact (users affected, duration, data loss if any)
- What went well in the response
- Action items with owners and due dates
```

---

## 何时使用 skills，何时使用其它方案

| 场景 | 使用 Skills | 使用其它方案 |
|-----------|-----------|-------------------|
| 团队有特定的审查标准 | 是 | - |
| Agent 需要遵循多步骤工作流 | 是 | - |
| Agent 需要调用 API | 否 | 用 tool 或 MCP |
| Agent 需要项目上下文（构建命令、结构） | 否 | 用 AGENTS.md |
| 工作流简单、一次性 | 否 | 直接写进 prompt |
| 知识较少变化、且属于特定领域 | 是 | - |
| 知识频繁变化或需要实时数据 | 否 | 用 RAG 或 tools |

---

## 关键要点

- Skills 把领域专长打包为便携、可复用的 Markdown 文件
- 它们通过渐进式披露（L1/L2/L3）将 context window 成本降到最低
- Skills 告诉 Agent 在何时、如何行动；tools 让 Agent 真正去行动
- SKILL.md 是唯一必需的组成部分——frontmatter 存放 metadata，正文存放指令
- 编写 skill 应聚焦单一领域，包含清晰的步骤、决策点和输出示例
- L2 指令控制在 5,000 个 token 以内；详细材料移到 L3 references
- Skills 已在多个平台获得支持：Claude Code、ADK、GitHub Copilot、OpenAI、Spring AI
- Skills、tools 与 MCP 工作在不同层，相互补充

---

## 延伸阅读

- [Agent Skills Specification](https://agentskills.io/specification)
- [ADK Skills Documentation](https://google.github.io/adk-docs/skills/)
- [Anthropic Skills Repository](https://github.com/anthropics/skills)
- [GitHub Copilot Agent Skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
- [Skills vs. MCP Tools - LlamaIndex](https://www.llamaindex.ai/blog/skills-vs-mcp-tools-for-agents-when-to-use-what)

---

[Previous Lesson: MCP Deep Dive](/17-mcp-deep-dive/) | [Next Lesson: Orchestrators ->](/19-orchestrators/)
