---
title: "Lesson 1: What are AI Agents?"
---

## Introduction

You have probably used ChatGPT, Gemini, or Claude to answer a question or write some code. You typed something in, got a response, and moved on. That is a language model doing its thing - predicting useful text based on your input.

An AI agent is something different. An agent can **think**, **act**, and **remember**. It does not just answer your question - it figures out what steps to take, uses tools to carry those steps out, and adjusts its approach based on what happens along the way.

Think of it this way: if you hired a new engineer and only let them talk but never touch a keyboard, open a browser, or read documentation, they would be limited. That is an LLM on its own. Now give that engineer access to your codebase, a terminal, your company docs, and the ability to ask clarifying questions. That is an agent.

This lesson covers what AI agents are, how they differ from plain language models, what components make them work, and when you should (and should not) use them.

---

## What is an AI agent in plain terms?

An AI agent is a software system that uses a language model as its core reasoning engine, combined with the ability to take actions in the real world. Those actions might include:

- Searching the web
- Querying a database
- Calling an API
- Reading or writing files
- Sending an email
- Running code

The key distinction is **autonomy**. A plain LLM responds to a single prompt. An agent receives a goal and then independently decides what steps to take, executes those steps, observes the results, and continues until the goal is met (or it determines the goal cannot be met).

### The new hire analogy

Imagine you hire a new software engineer. On their first day, you would not expect them to know everything. But you would expect them to:

1. **Read documentation** to understand the codebase
2. **Use tools** like an IDE, terminal, and browser
3. **Ask questions** when something is unclear
4. **Break down tasks** into smaller steps
5. **Check their work** before saying they are done
6. **Learn from mistakes** and adjust their approach

An AI agent works the same way. It has a base of knowledge (the language model), access to tools, and an orchestration layer that manages the loop of thinking, acting, and observing.

---

## LLM vs. agent: what is the difference?

This is the most important distinction to internalize early.

| Aspect | LLM (alone) | AI Agent |
|---|---|---|
| **What it does** | Generates text based on a prompt | Pursues a goal through multiple steps |
| **Interaction** | Single turn (or multi-turn chat) | Autonomous loop of thought and action |
| **Tools** | None - text in, text out | Can call functions, APIs, search, etc. |
| **Memory** | Limited to context window | Can persist information across steps |
| **Decision-making** | Responds to what you ask | Decides what to do next on its own |
| **Error handling** | Gives you an answer (right or wrong) | Can observe errors and retry with a new approach |

A helpful mental model:

- **LLM** = Brain
- **Agent** = Brain + Hands + Memory

The brain (LLM) does the reasoning. The hands (tools) let it take action. The memory (state management) lets it keep track of what has happened and what still needs to be done.

### A concrete example

**LLM alone:** You ask "What is the current price of GOOG stock?" The model might say "As of my last training data, it was around $140" - which could be months out of date.

**Agent:** You ask the same question. The agent thinks "I need current stock data, I should use a finance API." It calls a stock price tool, gets the live price, and returns an accurate answer. If the API call fails, it might try a different data source.

That loop - think, act, observe, repeat - is what makes an agent an agent.

---

## Core components of an AI agent

Every agent system, regardless of framework, has three fundamental components:

### 1. the model (the brain)

This is the language model at the center of the agent. It handles:

- **Understanding** the user's goal
- **Reasoning** about what steps to take
- **Deciding** which tool to use (and with what parameters)
- **Interpreting** the results of tool calls
- **Generating** the final response

The model you choose matters. Harder tasks (multi-step reasoning, complex code generation, nuanced decision-making) benefit from frontier models like Gemini or Opus. Simpler tasks (classification, extraction, straightforward Q&A) can use lighter models like Gemini Flash to save cost and latency.

### 2. tools (the hands)

Tools are what let an agent interact with the world beyond text generation. Without tools, an agent is just a chatbot. With tools, it can:

- **Retrieve information**: Search the web, query a database, read a file
- **Take actions**: Send an email, create a ticket, deploy code
- **Compute**: Run calculations, execute code, transform data

Tools are typically defined as functions with clear names, descriptions, and parameter schemas. The model decides when and how to call them. We will cover tools in depth in Lesson 3.

### 3. the orchestration layer (the control loop)

This is the glue that connects the model and tools into a functioning system. The orchestration layer manages:

- **The agent loop**: Think -> Act -> Observe -> Repeat
- **State management**: What has happened so far, what context the model needs
- **Error handling**: What to do when a tool call fails
- **Termination conditions**: When to stop looping and return a result
- **Guardrails**: Safety checks, output validation, scope limits

The simplest orchestration pattern looks like this:

```
1. Receive user goal
2. Send goal + available tools to the model
3. Model returns either:
   a. A final answer -> Return to user
   b. A tool call -> Execute the tool, add result to context, go to step 2
```

This is often called a **ReAct loop** (Reasoning + Acting). More sophisticated patterns exist - we will explore them in later lessons.

### How the components work together

```
User Goal
    |
    v
+-------------------+
| Orchestration     |
| Layer             |
|                   |
|  +-------------+  |
|  |   Model     |  |    "I need to search for X"
|  |  (Brain)    |--+--->  Tool Call
|  +-------------+  |         |
|        ^          |         v
|        |          |  +-------------+
|        +----------+--+   Tools     |
|     Tool results  |  |  (Hands)   |
|                   |  +-------------+
+-------------------+
    |
    v
Final Response
```

---

## A taxonomy of agent systems

Not all agents are created equal. It is helpful to think about agent systems on a spectrum of autonomy and capability, from Level 0 through Level 4.

### Level 0: basic reasoning (simple LLM

**What it is:** A language model answering questions with no tools or memory.

**Example:** You ask Gemini "Explain the CAP theorem" and it gives you a clear explanation from its training data.

**Capabilities:**
- Text generation and comprehension
- Single-turn or multi-turn conversation
- No external data access
- No ability to take actions

**When it works well:** General knowledge questions, creative writing, brainstorming, summarization of provided text.

### Level 1: connected problem-solver (tool-using agent)

**What it is:** A model that can call tools to retrieve information or perform simple actions. This is where we cross the line from "chatbot" to "agent."

**Example:** A customer support bot that can look up order status by calling your order API, or a coding assistant that can search documentation.

**Capabilities:**
- Everything in Level 0
- Function calling (tools)
- Retrieval-Augmented Generation (RAG) for grounding in real data
- Simple single-step or few-step task completion

**When it works well:** Tasks that require current data, API integrations, straightforward workflows with a small number of steps.

### Level 2: strategic agent (autonomous with context)

**What it is:** An agent that can plan multi-step approaches, maintain context across a longer session, and adapt its strategy based on intermediate results.

**Example:** A research agent that takes a question like "Compare the top 3 cloud providers on serverless pricing," then searches for pricing pages, extracts data, builds a comparison table, and summarizes findings.

**Capabilities:**
- Everything in Level 1
- Multi-step planning and execution
- Dynamic replanning when things change
- Working memory across steps
- Self-evaluation ("Is this result good enough?")

**When it works well:** Research tasks, complex troubleshooting, multi-step workflows where the path depends on intermediate results.

### Level 3: collaborative multi-agent system

**What it is:** Multiple specialized agents working together, each handling a different aspect of a larger task. One agent might coordinate the others.

**Example:** A software development system where one agent writes code, another writes tests, a third reviews the code, and an orchestrator agent manages the workflow.

**Capabilities:**
- Everything in Level 2
- Agent-to-agent communication
- Specialized roles and delegation
- Parallel execution of subtasks
- Consensus or voting mechanisms for quality

**When it works well:** Complex projects that benefit from specialization, tasks requiring multiple perspectives or quality gates.

### Level 4: self-evolving agent

**What it is:** An agent that can reflect on its own performance, learn from past runs, update its strategies, and improve over time without manual intervention.

**Example:** A deployment agent that tracks which rollback strategies worked best historically and adjusts its approach for future deployments.

**Capabilities:**
- Everything in Level 3
- Long-term memory and learning
- Strategy optimization based on past outcomes
- Self-modification of prompts or tool selection
- Performance monitoring and self-correction

**When it works well:** Recurring tasks where patterns emerge over time, systems that benefit from continuous improvement.

### Summary table

| Level | Name | Key Feature | Example |
|---|---|---|---|
| 0 | Basic Reasoning | Text in, text out | Chatbot, Q&A |
| 1 | Connected Problem-Solver | Tool use | Order lookup bot |
| 2 | Strategic Agent | Multi-step planning | Research assistant |
| 3 | Collaborative Multi-Agent | Agent coordination | Dev team simulation |
| 4 | Self-Evolving | Learning from experience | Adaptive ops agent |

Most production agent systems today operate at Level 1 or Level 2. Levels 3 and 4 are active areas of research and are becoming more practical, but they add significant complexity. Start simple and move up only when you have a clear reason to.

---

## When to use agents vs. when a simple prompt is enough

Agents add power but also complexity, cost, and latency. Not every problem needs an agent. Here is a practical guide.

### Use a simple prompt when:

- The task can be completed in a single step
- No external data or actions are needed
- The answer exists within the model's training data
- Low latency is critical (agents add multiple round trips)
- The cost of multiple model calls is not justified

**Examples:**
- "Summarize this paragraph"
- "Convert this JSON to a Python dataclass"
- "Write a regex that matches email addresses"
- "Explain the difference between TCP and UDP"

### Use an agent when:

- The task requires multiple steps that depend on each other
- External data or tools are needed (APIs, databases, search)
- The task requires real-time or current information
- The approach may need to change based on intermediate results
- The task involves taking actions (not just generating text)

**Examples:**
- "Find the three most recent bugs in our issue tracker and draft a summary for the team standup"
- "Look up the customer's order, check the shipping status, and send them an update email"
- "Research competitors' pricing and build a comparison spreadsheet"
- "Review this pull request, run the tests, and suggest improvements"

### The decision flowchart

```
Does the task require external data or actions?
  |
  +-- No --> Can the model answer from its training data?
  |            |
  |            +-- Yes --> Use a simple prompt
  |            +-- No  --> Consider RAG (retrieval) first, then an agent
  |
  +-- Yes --> Is it a single tool call?
               |
               +-- Yes --> A simple function-calling setup may suffice
               +-- No  --> Use an agent with orchestration
```

### Cost and latency considerations

Every step in an agent loop involves a model call. A 5-step agent workflow means 5 or more calls to the model, plus tool execution time. This adds up:

- **Latency**: Each model call takes 1-10 seconds depending on the model and prompt size. A 5-step agent might take 15-30 seconds.
- **Cost**: Each model call costs tokens. Agent workflows can use 10-50x more tokens than a single prompt.
- **Reliability**: More steps means more chances for errors or hallucinations.

The engineering principle is the same as anywhere else: use the simplest approach that gets the job done.

---

## Real-World Examples

### Customer support agent

**Goal:** Handle customer inquiries end-to-end.

**How it works:**
1. Customer writes: "Where is my order #12345?"
2. Agent calls the order lookup tool with the order ID
3. Gets status: "Shipped, tracking number XYZ, estimated delivery March 20"
4. Agent formats a friendly response with the tracking link
5. If the customer asks to change the delivery address, the agent calls the address update tool

**Level:** 1-2 (tool use with some multi-step logic)

### Code assistant agent

**Goal:** Help developers write, debug, and improve code.

**How it works:**
1. Developer asks: "Why is this function returning null?"
2. Agent reads the relevant source files
3. Searches for related tests
4. Identifies the bug (missing null check on line 42)
5. Suggests a fix with code
6. Optionally runs the tests to verify the fix works

**Level:** 2 (multi-step reasoning with tool use)

### Research agent

**Goal:** Gather and synthesize information from multiple sources.

**How it works:**
1. User asks: "What are the pros and cons of server-side rendering in 2026?"
2. Agent searches for recent articles and benchmarks
3. Reads and extracts key points from multiple sources
4. Cross-references claims and checks for consistency
5. Produces a structured summary with citations

**Level:** 2 (search, read, synthesize across multiple steps)

### DevOps incident response agent

**Goal:** Help diagnose and resolve production incidents.

**How it works:**
1. Alert fires: "API latency spike on service-auth"
2. Agent queries monitoring dashboards for the last 30 minutes
3. Checks recent deployments for changes
4. Examines logs for error patterns
5. Correlates findings: "Latency spike started 5 minutes after deploy #789 which changed the auth token cache TTL"
6. Suggests rollback and drafts an incident report

**Level:** 2-3 (multi-step investigation, potentially coordinating with other agents)

---

## ELI5: what is an AI agent?

### Think of an agent like a really capable intern

Imagine you have a brand new intern on their first day. They are smart - they graduated top of their class - but they have never seen your codebase before.

**An LLM by itself is like this intern sitting in a room with no computer.** You can ask them questions and they will give you thoughtful answers based on what they learned in school. But they cannot look anything up, they cannot run any code, and they cannot send any emails. All they can do is talk.

**An agent is like this intern with a full desk setup.** They have a laptop, access to your internal tools, a browser, and your company Slack. Now when you ask them a question, they can:

- Look things up if they do not know the answer
- Try running code to test their ideas
- Check the documentation to make sure they are right
- Ask a colleague (another agent) for help
- Come back to you with a verified answer

The intern still makes mistakes sometimes - they are new, after all. But they can catch most of their errors because they can check their work. And if they get stuck, they know to ask for help rather than guessing.

**The key insight:** The intern's brain did not change. What changed was what they have access to and how they approach the work. That is exactly the difference between an LLM and an agent. Same brain, more capabilities, better process.

---

## How Google Cloud fits in

Google Cloud provides infrastructure for building and deploying agents through several services:

- **Vertex AI Agent Engine** - A managed platform for building, deploying, and managing AI agents in production. It handles orchestration, tool management, session state, and scaling so you can focus on agent logic rather than infrastructure.

- **Gemini Models** - The language models that serve as the "brain" of your agents, available in different sizes for different use cases.

- **Agent Development Kit (ADK)** - An open-source, code-first toolkit for building agents with features like multi-agent orchestration, built-in tool support, and easy deployment to Agent Engine.

We will use these tools throughout the course. For now, just know they exist.

> **Learn more:** [Vertex AI Agent Engine Overview](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview)

---

## Key takeaways

1. **An AI agent is a system that uses a language model to reason, tools to act, and an orchestration layer to manage the loop between thinking and doing.**

2. **LLM = brain. Agent = brain + hands + memory.** The model provides reasoning. Tools provide action. The orchestration layer provides control flow.

3. **Agents exist on a spectrum** from simple tool-using assistants (Level 1) to self-evolving systems (Level 4). Start at the lowest level that solves your problem.

4. **Not everything needs an agent.** If a single prompt gets the job done, use a single prompt. Add agent capabilities only when the task genuinely requires tools, multi-step reasoning, or real-world actions.

5. **The core loop is simple:** Receive goal -> Think about what to do -> Use a tool -> Observe the result -> Repeat until done.

---

## What is next?

In the next lesson, we will look under the hood at the "brain" of the agent - the language model. You will learn how LLMs process information, how different reasoning strategies affect agent performance, and how to pick the right model for the job.

[Next: Lesson 2 - How Agents Think: LLMs as the Reasoning Engine -->](/02-how-agents-think/)
