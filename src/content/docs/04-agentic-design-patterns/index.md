---
title: "Lesson 4: agentic design patterns"
---

## What you will learn

- What agentic design patterns are and why they matter
- The four core patterns: ReAct, Reflection, Tool Use, and Planning
- When to use each pattern and the trade-offs involved
- How to combine patterns in real-world agents

## Prerequisites

- [Lesson 1: What Are AI Agents?](/01-what-are-ai-agents/)
- [Lesson 2: How Agents Think](/02-how-agents-think/)
- [Lesson 3: Tools - Giving Agents Hands](/03-tools-giving-agents-hands/)

---

## ELI5: Design patterns are like recipes

Imagine you want to cook dinner. You could just start grabbing ingredients and hope for the best. Or you could follow a recipe - a proven set of steps that someone figured out already works well.

Design patterns are recipes for building AI agents. They are tried-and-tested ways of organizing how an agent thinks, acts, and learns. Just like a cookbook has different recipes for different meals, we have different patterns for different types of agent behavior.

And just like a great chef might combine techniques from multiple recipes, the best agents usually combine several patterns together.

---

## Why design patterns matter

If you have been writing software for any length of time, you are probably familiar with design patterns like Observer, Strategy, or Factory. These patterns give engineers a shared vocabulary and proven blueprints for solving common problems.

Agentic design patterns serve the same purpose, but for AI agents. They describe recurring structures in how agents:

- **Reason** about problems
- **Take actions** in the world
- **Learn** from results
- **Improve** their own outputs

Without these patterns, building an agent feels like writing spaghetti code - everything is tangled together and hard to debug. With them, you get a clear architecture that is easier to build, test, and maintain.

### From simple to agentic

Not every LLM interaction needs a design pattern. Here is a rough spectrum:

| Level | Description | Example | Patterns needed |
|-------|------------|---------|----------------|
| **Simple prompt** | One question, one answer | "What is the capital of France?" | None |
| **Structured output** | LLM formats its response | "Return this as JSON" | None |
| **Chain** | Multiple LLM calls in sequence | Summarize, then translate | Minimal |
| **Agent** | LLM decides what to do next | Research a topic and write a report | ReAct, Tool Use, Planning |
| **Multi-agent** | Multiple agents collaborate | Team of agents building software | All of the above + coordination |

Design patterns become important once you move past simple chains into truly agentic behavior - where the LLM is making decisions about what to do next.

---

## Pattern 1: react (reason + act)

ReAct is the most fundamental agentic design pattern. If you only learn one pattern, make it this one.

### The idea

ReAct combines **reasoning** (thinking about what to do) with **acting** (actually doing it) in an interleaved loop. The agent:

1. **Thinks** about the current situation
2. **Acts** by calling a tool or taking a step
3. **Observes** the result
4. **Repeats** until the task is done

### The restaurant analogy

Think of a waiter at a restaurant:

1. **Think:** "Table 5 ordered the pasta. I need to check if the kitchen has it ready."
2. **Act:** Walk to the kitchen and ask.
3. **Observe:** The chef says it needs 5 more minutes.
4. **Think:** "Okay, I should check on table 3's drinks while I wait."
5. **Act:** Go to table 3 and refill drinks.
6. **Observe:** Table 3 is happy.
7. **Think:** "Enough time has passed. Let me check on table 5's pasta."
8. **Act:** Go back to the kitchen.
9. **Observe:** Pasta is ready.
10. **Act:** Deliver the pasta to table 5.

The waiter does not plan out their entire shift in advance. They think, act, observe, and adapt - continuously.

### What ReAct looks like

Here is the general flow:

```
User: "What is the weather in Tokyo and should I pack an umbrella?"

Agent Thought: I need to find the current weather in Tokyo. I will use the weather tool.
Agent Action: call weather_api(location="Tokyo")
Observation: {"temp": 18, "condition": "rain", "forecast": "rain continuing through tomorrow"}

Agent Thought: It is currently raining in Tokyo and rain is expected to continue.
                The user should pack an umbrella.
Agent Action: Respond to user.

Agent Response: "It is currently 18C and raining in Tokyo, with rain expected to
                continue through tomorrow. Definitely pack an umbrella!"
```

### Key characteristics of ReAct

- **Interleaved reasoning and action.** The agent does not just act blindly - it thinks about each step.
- **Grounded in observations.** Each thought is informed by what the agent actually sees, not just what it imagines.
- **Flexible.** The agent can change course based on what it discovers.
- **Transparent.** The reasoning trace makes it easier to debug what the agent was thinking.

### When to use ReAct

| Good fit | Poor fit |
|----------|----------|
| Tasks that need external information | Pure text generation tasks |
| Multi-step problems with uncertain paths | Simple question-answer |
| Situations where you need an audit trail | Latency-critical applications |
| Tasks that require adapting to new info | Tasks with a fixed, known sequence |

### Common pitfalls

- **Reasoning loops.** The agent thinks the same thought repeatedly without making progress. Add a maximum iteration count.
- **Hallucinated actions.** The agent "calls" a tool that does not exist. Validate tool names before execution.
- **Observation blindness.** The agent ignores what the tool returned and continues with its prior assumption. Make sure observations are clearly injected into the context.

---

## Pattern 2: reflection

### The idea

In the Reflection pattern, an agent reviews its own output and improves it. Instead of producing a single response and moving on, the agent generates a draft, critiques it, and then revises.

### The writer analogy

Think of a writer working on an article:

1. **Draft:** Write the first version.
2. **Review:** Read it back. "Hmm, the introduction is weak and paragraph 3 contradicts paragraph 1."
3. **Revise:** Rewrite the introduction and fix the contradiction.
4. **Review again:** "Better. But the conclusion needs a stronger call to action."
5. **Revise again:** Improve the conclusion.
6. **Done:** The final version is much stronger than the first draft.

No experienced writer ships a first draft. Similarly, agents that reflect on their output produce significantly better results.

### What Reflection looks like

```
Step 1 - Generate:
  Agent produces initial response to user's request.

Step 2 - Critique:
  Agent (or a separate critic) reviews the response:
  "This code has a bug on line 12 - the loop index is off by one.
   Also, the function lacks error handling for empty input."

Step 3 - Revise:
  Agent fixes the identified issues and produces an improved version.

Step 4 - Evaluate:
  "The bug is fixed and error handling is added. The code now handles
   edge cases. This meets the requirements."
```

### Variations of reflection

| Variation | How it works | Example |
|-----------|-------------|---------|
| **Self-reflection** | Same LLM reviews its own output | "Review your code for bugs" |
| **Critic agent** | A separate LLM instance reviews | Dedicated code reviewer agent |
| **Rubric-based** | Reflection guided by specific criteria | "Check for: accuracy, completeness, tone" |
| **Test-driven** | Output is tested against concrete checks | Run unit tests, check formatting |

### When to use reflection

| Good fit | Poor fit |
|----------|----------|
| Code generation (catch bugs before shipping) | Real-time conversational responses |
| Writing tasks (improve clarity and structure) | Simple factual lookups |
| Complex reasoning (catch logical errors) | Tasks where speed matters more than quality |
| Any task where quality matters more than speed | Tasks with objectively verifiable answers |

### Practical tips

- **Set a maximum number of reflection rounds.** Two to three rounds is usually enough. More than that often yields diminishing returns.
- **Use specific criteria.** "Make it better" is vague. "Check for SQL injection vulnerabilities, missing error handling, and performance issues" gives the reflection focus.
- **Consider using a different model or prompt for the critic.** A fresh perspective catches more issues than re-reading with the same lens.
- **Track what changed.** Log the differences between each revision so you can verify the reflection actually improved things.

---

## Pattern 3: tool use

### The idea

In the Tool Use pattern, the agent decides which tools to call, with what arguments, and in what order. The LLM acts as a reasoning engine that orchestrates external capabilities rather than trying to do everything itself.

We covered tools in depth in [Lesson 3](/03-tools-giving-agents-hands/). This section focuses on the *pattern* of how agents decide to use tools.

### The craftsperson analogy

Think of an experienced carpenter working on a project. They have a workshop full of tools - saws, drills, sanders, clamps. For each step of the project, they:

1. Assess what needs to be done next
2. Choose the right tool for this specific step
3. Use the tool
4. Inspect the result
5. Decide what comes next

They do not use a hammer for everything. They pick the tool that fits the job. And sometimes they realize mid-project that they need a tool they did not expect to use.

### What tool use looks like

```
User: "Find the top 3 trending repositories on GitHub about AI agents
       and summarize what each one does."

Agent Thought: I need to search GitHub for trending AI agent repositories.
Agent Action: github_search(query="AI agents", sort="stars", limit=3)
Observation: [repo1: "autogen", repo2: "crewai", repo3: "langchain-agents"]

Agent Thought: Now I need to get details about each repository.
Agent Action: github_get_repo(name="autogen")
Observation: {description: "...", readme: "...", stars: 42000}

Agent Action: github_get_repo(name="crewai")
Observation: {description: "...", readme: "...", stars: 28000}

Agent Action: github_get_repo(name="langchain-agents")
Observation: {description: "...", readme: "...", stars: 19000}

Agent Thought: I now have enough information to summarize all three.
Agent Response: "Here are the top 3 trending AI agent repositories..."
```

### Tool selection strategies

Agents use several strategies to decide which tool to use:

| Strategy | Description | Trade-off |
|----------|------------|-----------|
| **Direct matching** | Tool name/description matches the need | Fast, but brittle if tools are poorly named |
| **Capability reasoning** | Agent reasons about what each tool can do | More flexible, but uses more tokens |
| **Few-shot examples** | Examples in the prompt show when to use each tool | Reliable, but takes up context space |
| **Tool recommendations** | System suggests relevant tools based on the query | Reduces decision burden on the LLM |

### Parallel vs sequential tool calls

Some tasks allow calling multiple tools at once:

- **Sequential:** Search for a user, then look up their order history (need the user ID first)
- **Parallel:** Check the weather in three different cities (all independent)

Parallel tool calls reduce latency significantly. When designing your agent, identify which tool calls are independent and can run simultaneously.

### When to use tool use

This pattern applies to almost any agent that interacts with external systems. The key design decisions are:

- **How many tools?** Start small. An agent with 3-5 well-designed tools usually outperforms one with 50 poorly-designed tools.
- **How descriptive are the tool schemas?** Better descriptions lead to better tool selection.
- **What happens when a tool fails?** Good agents handle errors gracefully - retry, try an alternative tool, or ask the user for help.

---

## Pattern 4: planning

### The idea

In the Planning pattern, the agent creates a plan before executing. Instead of figuring out each step as it goes (like ReAct), the agent thinks ahead and lays out a structured approach.

### The project manager analogy

Imagine a project manager who gets a request to build a new feature:

1. **Break it down:** "We need to update the database schema, write the API endpoints, build the UI, and add tests."
2. **Order the work:** "Schema first, then API, then UI, then tests - each depends on the previous step."
3. **Assign resources:** "Database work goes to the backend team, UI to the frontend team."
4. **Execute and track:** Work through the plan, checking off items as they complete.
5. **Adjust if needed:** "The schema change was more complex than expected - let me re-plan the timeline."

### What Planning looks like

```
User: "Write a comprehensive blog post about Kubernetes security best practices."

Agent Plan:
  1. Research current Kubernetes security threats and CVEs
  2. Identify the top 5-7 security best practices
  3. For each practice, find concrete examples and commands
  4. Write an outline with introduction, main sections, and conclusion
  5. Draft each section
  6. Review the full post for accuracy and flow
  7. Add code examples and formatting

Agent Execution:
  [Executes steps 1-7 in order, adjusting as needed]
```

### Planning strategies

| Strategy | How it works | Best for |
|----------|-------------|----------|
| **Sequential planning** | Create a linear list of steps | Simple, well-understood tasks |
| **Hierarchical planning** | Break into high-level goals, then sub-tasks | Complex, multi-phase projects |
| **Conditional planning** | Include if/then branches in the plan | Tasks with uncertain outcomes |
| **Iterative planning** | Plan a few steps, execute, re-plan | Tasks where later steps depend on early results |

### Plan-then-execute vs. ReAct

These two patterns represent different philosophies:

| Aspect | Planning | ReAct |
|--------|----------|-------|
| **When decisions are made** | Mostly upfront | Step by step |
| **Adaptability** | Requires explicit re-planning | Naturally adaptive |
| **Efficiency** | Can parallelize independent steps | Typically sequential |
| **Transparency** | Full plan visible upfront | Reasoning visible per step |
| **Risk of wasted work** | Higher if plan turns out wrong | Lower, adapts as it goes |
| **Best for** | Well-structured tasks | Exploratory tasks |

In practice, most agents blend both approaches: they make a rough plan upfront and then use ReAct-style reasoning during execution.

### When to use planning

| Good fit | Poor fit |
|----------|----------|
| Multi-step tasks with clear structure | Simple single-step tasks |
| Tasks where order matters | Purely reactive/conversational agents |
| Work that can be parallelized | Tasks where the path is completely unknown |
| Projects that need progress tracking | Quick, ad-hoc requests |

---

## Comparing the patterns

Here is a side-by-side comparison to help you choose:

| Pattern | Core idea | Strength | Weakness | Cost |
|---------|-----------|----------|----------|------|
| **ReAct** | Think-act-observe loop | Flexible, transparent | Can be slow, may loop | Medium (multiple LLM calls) |
| **Reflection** | Self-review and improvement | Higher quality output | Adds latency | High (multiple passes) |
| **Tool Use** | Orchestrate external tools | Extends agent capabilities | Depends on tool quality | Varies (tool-dependent) |
| **Planning** | Plan before executing | Structured, efficient | Brittle if plan is wrong | Medium-high (planning + execution) |

### Decision flowchart

Ask yourself these questions:

1. **Does the agent need external information or actions?** Yes -> Tool Use
2. **Is the task multi-step with an uncertain path?** Yes -> ReAct
3. **Is quality critical and the task has clear criteria?** Yes -> Reflection
4. **Is the task complex but well-structured?** Yes -> Planning
5. **Is the answer to most of these "yes"?** -> Combine patterns

---

## Combining patterns

Real-world agents almost never use a single pattern in isolation. The most effective agents layer patterns together.

### Common combinations

**ReAct + Tool Use** (the most common combination)

The agent reasons about what to do, uses tools to take actions, observes results, and reasons again. This is the backbone of most practical agents.

```
Think -> Use Tool -> Observe -> Think -> Use Tool -> Observe -> Respond
```

**Planning + ReAct + Tool Use**

The agent creates a plan, then executes each step using ReAct-style reasoning with tools.

```
Plan -> [Think -> Act -> Observe] -> [Think -> Act -> Observe] -> ... -> Done
```

**Planning + Reflection**

The agent creates a plan, executes it, and then reviews the overall output before delivering it.

```
Plan -> Execute -> Reflect -> Revise -> Deliver
```

**Full stack: Planning + ReAct + Tool Use + Reflection**

For complex, high-stakes tasks, you might use all four:

```
Plan the approach
  -> Execute each step with ReAct + Tools
    -> Reflect on the overall result
      -> Revise if needed
        -> Deliver
```

### Example: A code generation agent

Here is how a code generation agent might combine patterns:

1. **Planning:** "I need to write a REST API. Steps: define the data model, create endpoints, add validation, write tests."
2. **ReAct + Tool Use:** For each step, the agent reasons about what to do, uses tools (file reader, code search, linter) to gather information and write code.
3. **Reflection:** After writing the code, the agent reviews it against best practices. "Does this handle errors? Is the input validated? Are there security issues?"
4. **Revision:** The agent fixes issues found during reflection.

### When not to combine

More patterns is not always better. Each pattern adds:

- **Latency:** More LLM calls means more time
- **Cost:** More tokens means more money
- **Complexity:** More moving parts means more debugging

For a simple question-answering agent, ReAct + Tool Use is probably all you need. Save the full stack for complex, high-value tasks where quality justifies the cost.

---

## Patterns in Google Cloud

Google Cloud's [Vertex AI Agent Engine](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview) provides infrastructure for building agents that use these patterns. The [Agent Development Kit (ADK)](https://google.github.io/adk-docs/) gives you building blocks to implement them.

Key concepts in the Google Cloud ecosystem:

- **Agent Engine** manages the lifecycle of your agents - deployment, scaling, and monitoring
- **ADK** provides the framework for defining agent behavior, tools, and orchestration
- **Gemini models** serve as the LLM backbone that powers reasoning in each pattern

We will get hands-on with these in [Lesson 12](/12-getting-started-with-vertex-and-adk/) and [Lesson 13](/13-building-your-first-agent/).

---

## Key takeaways

1. **Agentic design patterns are proven blueprints** for organizing how agents think and act. They give you a shared vocabulary and a starting point for architecture.

2. **ReAct is the foundation.** The think-act-observe loop is the most fundamental pattern and the starting point for most agents.

3. **Reflection dramatically improves quality** but costs time and tokens. Use it when quality matters more than speed.

4. **Tool Use extends what agents can do** beyond the LLM's built-in knowledge. Good tool design is as important as good prompt design.

5. **Planning brings structure** to complex tasks. It works best when the task is well-understood and the steps can be laid out in advance.

6. **Combine patterns thoughtfully.** More patterns means more capability but also more complexity and cost. Start simple and add patterns as needed.

7. **There is no single best pattern.** The right choice depends on your task, your quality requirements, and your latency and cost budgets.

---

## Further reading

- [Vertex AI Agent Engine overview](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview)
- [Agent Development Kit (ADK) documentation](https://google.github.io/adk-docs/)
- [Google Cloud AI codelabs](https://codelabs.developers.google.com/?cat=AI)

---

**Next lesson:** [Memory and Context - How Agents Remember](/05-memory-and-context/)
