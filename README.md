# Agent Engineer · 中文译本

本项目是 [addyosmani/agent-engineer](https://github.com/addyosmani/agent-engineer.git) 的中文翻译，并以静态文档站点的形式提供阅读体验。

> Agent Engineer 是面向软件工程师的 AI agents 入门课程，覆盖从基础概念到工程实践的 19 个课时。原作者：[Addy Osmani](https://github.com/addyosmani)。

## 内容

课程分为三部分，共 19 课，每课均有对应的中英双语页面：

- **Part 1 · 基础**（01–10）：什么是 Agent、LLM 推理、tool calling、设计模式、记忆与 context、规划、多 Agent、Agentic RAG、评估、guardrails 与安全。
- **Part 2 · 构建与交付**（11–14）：从原型到生产、Vertex AI 与 ADK 入门、构建你的第一个 Agent、MCP 与 A2A 协议。
- **Part 3 · 专题深入**（15–19）：AGENTS.md、MCP 深入、Agent skills、orchestrator、延伸阅读。

完整目录见站点首页或 [`src/content/docs/index.md`](./src/content/docs/index.md)。

## 翻译说明

- 译文遵循 [`GLOSSARY.md`](./GLOSSARY.md) 中的术语表：Agent、LLM、prompt、tool calling、MCP、RAG、ReAct、ADK、Vertex AI、AGENTS.md、guardrails、orchestrator 等专有名词保留英文。
- 代码、代码注释、命令行示例与 URL 一律保留英文原貌。
- Markdown 结构、内部链接、frontmatter 与原文保持一致。
- 中英双语并存，页面右上角可一键切换语言。

## 在线阅读

通过任意一种方式启动后访问 `http://localhost:8080`（Docker）或 `http://localhost:4321`（本地开发）：

### 方式 A · Docker（推荐）

```bash
./deploy.sh up           # 构建镜像并启动容器
./deploy.sh logs         # 查看日志
./deploy.sh status       # 健康状态
./deploy.sh down         # 停止
HOST_PORT=9000 ./deploy.sh up   # 换主机端口
```

部署细节见 `Dockerfile`、`nginx.conf` 与 `docker-compose.yml`。

### 方式 B · 本地开发

```bash
npm install
npm run dev      # 开发服务器
npm run build    # 产出静态站点到 dist/
npm run preview  # 预览生产构建
```

## 仓库结构

```
.
├── src/content/docs/         # 文档源文件
│   ├── 01-…/index.md          (English，默认 locale)
│   ├── …
│   └── zh-cn/                # 简体中文翻译
│       └── 01-…/index.md
├── astro.config.mjs          # 站点配置：i18n、侧边栏、社交链接
├── GLOSSARY.md               # 翻译术语规范
├── Dockerfile                # 多阶段：构建 → nginx
├── nginx.conf                # gzip、缓存策略、clean URL
├── docker-compose.yml
└── deploy.sh                 # 部署脚本
```

## 贡献

欢迎报告译文中的错别字、不通顺或术语不一致。提交 PR 时请：

1. 同时修改对应 EN 与 zh-CN 文件（如仅修改一侧译法，请说明原因）。
2. 遵循 [`GLOSSARY.md`](./GLOSSARY.md) 中的术语表。
3. 提交前在本地运行 `npm run build` 确认无构建报错。

## 许可

原项目以 Apache 2.0 协议发布。本译本沿用同一许可，详见 [`LICENSE`](https://github.com/addyosmani/agent-engineer/blob/main/LICENSE)。

## 致谢

- [Addy Osmani](https://github.com/addyosmani) 与 Agent Engineer 课程贡献者：原文作者。
- Google Cloud / Vertex AI / ADK 团队：技术参考。
