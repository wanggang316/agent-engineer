---
title: "Lesson 16: AGENTS.md — 为 Agent 提供项目上下文"
---

## 引言

新工程师加入团队时，你不会只把代码库甩给他说"祝你好运"。你会给他入职文档、解释构建系统、指出测试在哪里，并提醒他哪些代码不要碰。

AI coding agent 也需要同样的东西。没有项目上下文，Agent 会去猜你的约定、用错测试运行器、忽略你的分支策略，最后产出与项目格格不入的代码。AGENTS.md 通过给 Agent 一份结构化的入职文档（开工前先读），来解决这个问题。

### ELI5：把 AGENTS.md 想成欢迎手册

设想公司给每位新员工在第一天发一张一页纸的速查表，列出 WiFi 密码、如何运行构建、风格指南在哪、哪些东西绝不要碰。AGENTS.md 就是这张速查表——只不过对象是要在你代码库上工作的 AI agent。

> **关键要点：** AGENTS.md 是放在仓库里的简单 Markdown 文件，告诉 AI agent 如何在项目里工作。大多数主流 AI coding tool 都会自动读取它。

---

## AGENTS.md 是什么

AGENTS.md 是放在仓库里的一份开放格式 Markdown 文件。它向 AI coding agent 提供指令与上下文——像 Claude Code、Cursor、GitHub Copilot、Gemini 等工具都会读取。

没有特殊 schema，不需要 YAML frontmatter，没有工具依赖。它就是纯 Markdown。你像给人写指令一样去写它，因为本质上它就是写给"读起来像人类"的 AI 的指令。

### 它解决的问题

没有 AGENTS.md 时，每次用 AI coding agent，你都会重复自己：

- "We use pytest, not unittest"
- "Run `make lint` before committing"
- "The API code is in `src/api/`, the frontend is in `web/`"
- "Never modify files in `vendor/`"

AGENTS.md 把这些只写一次、放在一处，让接触你代码的每个 Agent 都从正确的上下文开始。

### 它如何工作

1. 你在仓库根目录放一个 `AGENTS.md` 文件
2. AI coding agent 启动工作时自动检测并读取它
3. 这些指令影响 Agent 写代码、跑测试与做决定的方式
4. 你也可以在子目录放额外的 `AGENTS.md`，提供局部指引

就这样。无需配置、无需构建步骤、无需集成工作。

---

## 简史

AGENTS.md 于 2025 年 8 月由 OpenAI（Codex）、Amp、Google（Jules）、Cursor 与 Factory 协作产生。各公司没有各自搞专有格式，而是商定了一个共享、开放的标准。

2025 年 12 月，AGENTS.md 被贡献给 Linux Foundation 旗下的 [Agentic AI Foundation (AAIF)](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation)，与 Anthropic 的 Model Context Protocol (MCP) 以及 Block 的 Goose 并列。如今它是基金会托管的开放标准。

截至 2026 年初，已有超过 60,000 个开源仓库包含 AGENTS.md 文件。

---

## AGENTS.md 里写什么

对成千上万真实仓库的分析识别出六个最有差异的核心区域：

### 1. Commands

构建、lint、测试与运行项目的确切命令。要具体——包含 flag 与选项，而不只是工具名。

```markdown
## Commands

- Build: `npm run build`
- Lint: `npm run lint -- --fix`
- Test all: `npm test`
- Test single file: `npm test -- --testPathPattern=<filename>`
- Dev server: `npm run dev` (runs on port 3000)
- Type check: `npx tsc --noEmit`
```

为什么重要：知道确切命令的 Agent 能在交付前自己跑测试与 lint，验证自己的工作。

### 2. Testing

测试如何组织、用什么框架、写新测试时该遵守哪些约定。

```markdown
## Testing

- Framework: pytest with pytest-asyncio for async tests
- Test location: tests mirror src structure (src/api/users.py -> tests/api/test_users.py)
- Naming: test files start with `test_`, test functions start with `test_`
- Fixtures: shared fixtures live in tests/conftest.py
- Run a single test: `pytest tests/api/test_users.py::test_create_user -v`
```

### 3. 项目结构

一张"东西在哪"的地图。Agent 知道该看哪些目录，工作会更顺。

```markdown
## Project Structure

- `src/api/` - REST API endpoints (FastAPI)
- `src/core/` - Business logic, domain models
- `src/db/` - Database models and migrations (SQLAlchemy + Alembic)
- `src/workers/` - Background task processors
- `web/` - React frontend (Vite + TypeScript)
- `infra/` - Terraform infrastructure definitions
- `scripts/` - Developer utility scripts
```

### 4. 代码风格

命名约定、格式规则与偏好的模式。一段展示风格的代码片段，胜过一整段描述。

```markdown
## Code Style

- Python: Black formatting, isort for imports, Google-style docstrings
- TypeScript: Prettier + ESLint, functional components with hooks
- Naming: snake_case for Python, camelCase for TypeScript
- Prefer explicit over implicit - no magic imports or star exports
- Error handling: use custom exception classes from src/core/exceptions.py
```

### 5. Git 工作流

分支策略、提交信息约定与 PR 要求。

```markdown
## Git Workflow

- Branch from `main`, prefix with `feat/`, `fix/`, or `chore/`
- Commit messages: conventional commits format (e.g., "feat: add user search endpoint")
- Squash merge PRs
- All PRs require passing CI and one approval
```

### 6. 边界

Agent 绝不该碰的东西。这是最重要的章节之一。

```markdown
## Do Not Modify

- `vendor/` - third-party code, managed externally
- `.env` files - contain secrets, never commit
- `infra/production/` - production infrastructure, requires manual review
- `src/db/migrations/` - generate migrations with Alembic, do not write by hand
- `package-lock.json` - only modify via npm install
```

---

## 用于 monorepo 的层级化 AGENTS.md

你可以在目录树多个层级放 AGENTS.md。Agent 会读取当前目录或其上级中最近的那个文件。这对不同区域有不同约定的 monorepo 很有用。

```
my-monorepo/
  AGENTS.md              # Shared conventions (git workflow, CI, etc.)
  services/
    api/
      AGENTS.md          # Python-specific: pytest, Black, FastAPI patterns
    frontend/
      AGENTS.md          # TypeScript-specific: Vitest, Prettier, React patterns
    ml-pipeline/
      AGENTS.md          # Python + notebooks: data conventions, model testing
```

每个子项目的 AGENTS.md 聚焦该区域的独特之处，根目录文件覆盖共享的实践。

---

## AGENTS.md 与其他 Agent 配置文件

多个 AI 工具有自己的指令文件格式。它们之间的内容大量重叠——构建命令、编码规范、项目结构。差异主要是工具特有的功能。

| 文件 | 工具 | 特殊功能 |
|------|------|-----------------|
| **AGENTS.md** | 跨工具标准 | 通用、无特殊语法、被大多数 Agent 读取 |
| **CLAUDE.md** | Claude Code | 支持 `@path` 导入，便于模块化指令 |
| **.cursorrules / .mdc** | Cursor | YAML frontmatter，支持激活模式（Always、Auto、Agent Requested） |
| **.github/copilot-instructions.md** | GitHub Copilot | 带 glob 模式的作用域 `.instructions.md` 文件 |
| **GEMINI.md** | Gemini | Gemini 专属指令 |

### 实用做法

把共享指令放进 AGENTS.md。大多数工具会读它。仅在需要某工具特有功能时再用对应的工具专属文件。

如果你已有 CLAUDE.md 或 .cursorrules，不必把所有内容复制到 AGENTS.md。但如果你希望指令在多个工具间通用，AGENTS.md 是公约数。

---

## 最佳实践

### 保持简洁

控制在 150 行以内。文件过长会埋没重点，浪费 Agent 的 context window token。如果你的 AGENTS.md 比 README 还长，多半就太长了。

### 具体且可执行

差："We use a modern JavaScript stack"
好："React 18 with TypeScript 5.3, Vite 5, and Tailwind CSS 3.4"

差："Follow standard testing practices"
好："Run `npm test -- --coverage` and maintain >80% line coverage on new code"

### 用示例代替描述

一段示例代码传递风格的效果，胜过一段段描述。

```markdown
## API Endpoint Pattern

New endpoints should follow this structure:

\```python
@router.post("/users", response_model=UserResponse, status_code=201)
async def create_user(
    request: CreateUserRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserResponse:
    """Create a new user account."""
    user = await user_service.create(db, request)
    return UserResponse.from_orm(user)
\```
```

### 根据 Agent 行为迭代

从最小的 AGENTS.md 起步。当你发现 Agent 反复犯同一个错，就加一条对应的指令。最好的 AGENTS.md 文件是迭代而成，而非前期一次写好的。

### 像对待代码一样对待它

修改构建流程、测试约定或项目结构时，在同一个 PR 里更新 AGENTS.md。陈旧的指令比没有指令更糟，因为它会主动误导 Agent。

### 必要时写出"为什么"

对不直观的规则，简短说明可以帮 Agent 在边界情况下正确应用规则。

```markdown
- Do not use `datetime.now()` directly. Use `src/core/clock.py` instead.
  This allows tests to control time without monkeypatching.
```

---

## 一份完整示例

这是一个 Python Web 应用的真实风格 AGENTS.md：

```markdown
# AGENTS.md

## Project

Order management API built with FastAPI and PostgreSQL.
Python 3.12, managed with Poetry.

## Commands

- Install dependencies: `poetry install`
- Run dev server: `poetry run uvicorn src.main:app --reload --port 8000`
- Run all tests: `poetry run pytest`
- Run single test: `poetry run pytest tests/path/to/test.py -v`
- Lint: `poetry run ruff check src tests`
- Format: `poetry run ruff format src tests`
- Type check: `poetry run mypy src`
- Generate migration: `poetry run alembic revision --autogenerate -m "description"`
- Apply migrations: `poetry run alembic upgrade head`

## Project Structure

- `src/api/` - API route handlers
- `src/core/` - Business logic and domain models
- `src/db/` - SQLAlchemy models and Alembic migrations
- `src/services/` - External service integrations
- `tests/` - Mirrors src structure

## Code Style

- Ruff for linting and formatting (config in pyproject.toml)
- Google-style docstrings on public functions
- Type hints on all function signatures
- Prefer `async def` for all route handlers
- Use dependency injection via FastAPI's `Depends()`

## Testing

- pytest with pytest-asyncio
- Use factories from `tests/factories.py` to create test data
- Tests run against a real PostgreSQL database (not mocks)
- Each test function gets a fresh transaction that rolls back

## Git

- Branch naming: `feat/`, `fix/`, `chore/` prefixes
- Conventional commits
- Squash merge to main

## Do Not Modify

- `alembic/versions/` - Do not edit migration files by hand
- `.env` and `.env.local` - Contains secrets
- `src/core/legacy_adapter.py` - Scheduled for removal, do not add new code here
```

---

## 当 AGENTS.md 不够用时

AGENTS.md 能很好地处理项目级上下文，但有些场景需要更多：

- **动态 tool 访问** —— 如果 Agent 要查询数据库、调 API 或与外部服务交互，你需要 [MCP servers](/14-agent-protocols-mcp-and-a2a/) 或 tool，光靠指令不够。
- **可复用工作流** —— 如果你要把多步流程打包成 Agent 可调用的单元，参考 [Agent Skills](/18-agent-skills/)。
- **跨 Agent 协作** —— 如果多个 Agent 需要协同工作，你需要一个 [orchestration layer](/19-orchestrators/)。

AGENTS.md 是地基。把它看作让其他一切运转更好的第一层上下文。

---

## 自己动手试试

1. 在你某个项目里创建一个 `AGENTS.md`
2. 只从 Commands 与 Project Structure 两节起步
3. 在该项目里使用 AI coding agent，看它是否遵循你的指令
4. 当你注意到 Agent 出错，就加上对应的指令
5. 持续打磨，直到 Agent 一致地产出与项目契合的代码

---

## 关键要点

- AGENTS.md 是一个纯 Markdown 文件，告诉 AI agent 如何在项目里工作
- 它是大多数主流 AI coding tool 都支持的开放标准
- 聚焦六个区域：commands、testing、项目结构、代码风格、git 工作流与边界
- 保持简洁（150 行以内）、具体并保持更新
- 从简起步，根据 Agent 出错的地方迭代
- 在 monorepo 中使用层级化文件提供局部指引
- 共享指令放进 AGENTS.md，工具专属功能放各自的配置文件

---

## 延伸阅读

- [AGENTS.md official site](https://agents.md/)
- [AGENTS.md specification on GitHub](https://github.com/agentsmd/agents.md)
- [How to write a great AGENTS.md - GitHub Blog](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)
- [Agentic AI Foundation (AAIF)](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation)
- [Custom instructions with AGENTS.md - OpenAI Codex](https://developers.openai.com/codex/guides/agents-md)

---

[Next Lesson: MCP Deep Dive ->](/17-mcp-deep-dive/)
