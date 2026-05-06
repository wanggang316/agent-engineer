---
title: "Lesson 8: agentic RAG - smarter retrieval"
---

## Introduction

In earlier lessons, you learned how agents use tools to interact with the world. One of the most important tools an agent can have is the ability to look things up - to search a knowledge base, query a database, or retrieve documents. This is the foundation of Retrieval-Augmented Generation, or RAG.

Basic RAG follows a simple pattern: take the user's question, search for relevant documents, stuff those documents into the LLM's context, and generate an answer. This works well for straightforward lookups. But it falls apart when the question is complex, when the first search does not return the right documents, or when the answer requires synthesizing information from multiple sources.

Agentic RAG fixes this by putting an agent in control of the retrieval process. Instead of a rigid retrieve-then-read pipeline, the agent decides when to search, what to search for, whether the results are good enough, and when to try again with a different approach. The agent treats retrieval as a tool it uses strategically, not a fixed step it always follows.

## Quick recap: what is RAG?

RAG stands for Retrieval-Augmented Generation. The idea is simple: LLMs have a knowledge cutoff and cannot know everything. So before answering a question, you retrieve relevant information from an external source and include it in the prompt.

**The basic RAG pipeline:**

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

**Why RAG matters:**
- LLMs have knowledge cutoffs - RAG provides current information
- LLMs can hallucinate - RAG grounds answers in real documents
- LLMs cannot access private data - RAG connects them to your databases
- RAG lets you update knowledge without retraining the model

**A simple analogy:** RAG is like an open-book exam. Instead of relying only on what you memorized (the LLM's training data), you get to look things up in your notes (the document store) before writing your answer.

## The limits of basic RAG

Basic RAG works well for simple, direct questions where the answer exists in a single document. But it struggles in several common scenarios:

### Problem 1: the query does not match the documents

The user asks a question using different words than the documents use. The retriever searches for "how to fix a slow database" but the relevant document talks about "query optimization techniques." The semantic gap means the retriever misses the best document.

### Problem 2: the answer spans multiple documents

The user asks "What are our company's policies on remote work for international employees?" The answer requires combining information from the remote work policy, the international employment guidelines, and the tax compliance documentation. Basic RAG retrieves a handful of documents in one shot and hopes the right ones are included.

### Problem 3: the first results are not good enough

Basic RAG retrieves documents once and commits to using them. If the top results are mediocre or irrelevant, the LLM generates a mediocre or incorrect answer. There is no mechanism to say "these results are not helpful, let me try a different search."

### Problem 4: the question needs decomposition

The user asks a complex question like "Compare our Q3 revenue in North America vs Europe and explain the key drivers of the difference." This requires multiple sub-queries: Q3 revenue for North America, Q3 revenue for Europe, and analysis of contributing factors. Basic RAG tries to answer it with a single search.

### Problem 5: no verification

Basic RAG has no self-checking mechanism. The LLM generates an answer based on whatever documents were retrieved, even if those documents are outdated, irrelevant, or contradictory. There is no step that asks "does this answer actually make sense given the evidence?"

## What makes RAG "agentic"

Agentic RAG gives the LLM agency over the retrieval process. Instead of following a fixed pipeline, the agent makes decisions at every step:

### The agent decides when to search

Not every question requires retrieval. An agentic RAG system can recognize when it already knows the answer (from its training data or the current conversation context) and skip retrieval entirely. It can also recognize when it definitely needs external information and launch a search.

### The agent reformulates queries

If the initial search returns poor results, the agent does not give up. It analyzes why the results are bad and tries a different query. Maybe the original question was too broad, so it narrows it down. Maybe it used the wrong terminology, so it rephrases.

**Example:**
```
Original query: "fix slow database"
    Results: generic articles about databases
    Agent thinks: "Too vague. Let me be more specific."
Reformulated: "PostgreSQL query optimization for slow JOIN operations"
    Results: specific optimization techniques
    Agent thinks: "Much better. These are relevant."
```

### The agent cross-references multiple sources

Instead of relying on a single search, the agent can query multiple sources, compare the results, and synthesize a more complete answer. It might check the internal knowledge base, then verify against public documentation, then cross-reference with recent support tickets.

### The Agent Self-Corrects

After generating an answer, the agent checks it against the retrieved evidence. Does the answer actually follow from the documents? Are there contradictions? Is any critical information missing? If the answer does not hold up, the agent goes back and retrieves more information.

## The agentic RAG loop

The core of agentic RAG is a loop, not a pipeline. The agent iterates through retrieval, evaluation, and refinement until it has a satisfactory answer or has exhausted its options.

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

Let us walk through each step in detail.

### Step 1: query planning

The agent analyzes the user's question and decides on a retrieval strategy. For simple questions, this might mean a single search. For complex questions, the agent decomposes the question into sub-queries.

**Example:**

User asks: "How did our customer satisfaction scores change after we launched the new support chatbot?"

Agent plans:
1. Find customer satisfaction scores before the chatbot launch
2. Find the chatbot launch date
3. Find customer satisfaction scores after the chatbot launch
4. Look for any analysis or reports connecting the two

### Step 2: retrieve

The agent executes its planned searches. This might involve querying a vector database, calling a search API, looking up structured data, or any combination.

### Step 3: evaluate results

This is where agentic RAG diverges from basic RAG. The agent looks at the retrieved documents and makes a judgment:

- **Relevance:** Do these documents actually address my question?
- **Completeness:** Do I have all the information I need?
- **Freshness:** Are these documents up to date?
- **Consistency:** Do the sources agree with each other?

### Step 4: refine (if needed)

If the results are not good enough, the agent refines its approach:

- **Reformulate the query:** Use different keywords, be more specific or more general
- **Try a different source:** Switch from the general knowledge base to a specialized one
- **Decompose further:** Break the question into even smaller sub-questions
- **Expand the search:** Look for related concepts that might lead to the answer

### Step 5: generate answer

Once the agent has sufficient evidence, it generates an answer grounded in the retrieved documents. The answer should cite its sources so the user can verify.

### Step 6: verify answer

The agent performs a final check:

- Does the answer contradict any of the retrieved documents?
- Are all claims in the answer supported by evidence?
- Are there any gaps or hedging that suggest more retrieval is needed?

If verification fails, the agent loops back to gather more information.

## Key capabilities of agentic RAG

### Autonomous query planning

The agent breaks complex questions into sub-queries automatically, without needing predefined templates or rules. It uses its understanding of the question to determine what information it needs.

**Basic RAG:** Sends the user's exact question to the retriever.
**Agentic RAG:** Analyzes the question, identifies information needs, and plans multiple targeted searches.

### Adaptive source selection

The agent can choose which knowledge sources to query based on the question. A question about company policy goes to the policy database. A question about a customer goes to the CRM. A question about recent events goes to the web.

| Question Type | Source Selection |
|---|---|
| Company policy | Internal policy database |
| Customer information | CRM system |
| Technical documentation | Engineering wiki |
| Recent events | Web search |
| Product specifications | Product catalog |
| Historical data | Data warehouse |

### Context-Aware query expansion

The agent uses the conversation context and previously retrieved information to improve subsequent queries. If the first search returned information about "Project Alpha," the agent might add "Project Alpha" to subsequent queries to find related documents.

### Multi-Hop Reasoning

Some questions require chains of retrieval. The answer to the first query informs what to search for next.

**Example:**
```
Question: "Who manages the team that built our recommendation engine?"

Hop 1: Search for "recommendation engine team"
  -> Found: "The recommendation engine was built by the ML Platform team"

Hop 2: Search for "ML Platform team manager"
  -> Found: "The ML Platform team is managed by Sarah Chen"

Answer: "Sarah Chen manages the ML Platform team, which built
         the recommendation engine."
```

## Self-Correction Mechanisms

One of the most valuable aspects of agentic RAG is its ability to recognize and recover from mistakes.

### Re-Querying

When the agent detects that its initial results are insufficient, it formulates new queries based on what it learned from the first round. This is not random retry - it is informed refinement.

```
Initial query: "deployment process"
Results: Too many general documents about various deployment processes
Agent analysis: "I need to be more specific about which service"
Refined query: "deployment process for the payment microservice"
Results: Specific runbook for the payment service deployment
```

### Diagnostic tools

The agent can use diagnostic tools to evaluate the quality of its retrieval:

- **Relevance scoring:** Rate each retrieved document on a scale of relevance to the question
- **Coverage checking:** Verify that all aspects of the question are addressed
- **Contradiction detection:** Flag when different sources disagree
- **Confidence estimation:** Assess how confident it is in the answer based on the evidence

### Human fallback

When the agent cannot find a satisfactory answer after multiple attempts, it escalates to a human rather than guessing. This is a critical safety mechanism.

```
Agent: "I searched our knowledge base for information about
the 2024 data migration project but could not find sufficient
documentation. I found references to it in three documents,
but none contained the specific timeline you asked about.
I recommend checking with the Data Engineering team directly."
```

## When to use basic RAG vs. agentic RAG

Not every use case needs the full agentic approach. Here is a guide for choosing:

### Use basic RAG when:

- Questions are simple and direct ("What is our return policy?")
- The answer typically exists in a single document
- Latency is critical (agentic RAG adds multiple LLM calls)
- Cost is a major constraint
- The knowledge base is small and well-organized
- Accuracy requirements are moderate

### Use agentic RAG when:

- Questions are complex and open-ended ("Analyze our customer churn trends")
- Answers require synthesizing multiple documents
- The user expects research-quality depth
- The knowledge base is large, diverse, or poorly organized
- Accuracy is critical and wrong answers are costly
- Questions often require clarification or decomposition

### Cost and latency comparison

| Aspect | Basic RAG | Agentic RAG |
|---|---|---|
| LLM calls per query | 1 | 3-10+ |
| Retrieval calls per query | 1 | 2-5+ |
| Typical latency | 1-3 seconds | 5-30 seconds |
| Token cost | Low | 3-10x higher |
| Answer quality for simple questions | Good | Similar (overkill) |
| Answer quality for complex questions | Poor to fair | Good to excellent |

## ELI5: the librarian vs. the research assistant

Basic RAG is like asking a librarian one question. You walk up to the desk and say, "Do you have a book about dinosaurs?" The librarian checks the catalog, finds a book, and hands it to you. If the book does not answer your specific question, too bad - that is all you get.

Agentic RAG is like hiring a research assistant. You say, "I need to understand why dinosaurs went extinct." The research assistant goes to the library, pulls several books, reads through them, realizes one is outdated, puts it back, finds a more recent paper, cross-references two different theories, checks the citations, and comes back with a well-sourced summary. If they cannot find enough information at the library, they check online databases. If they find conflicting information, they note the disagreement and explain both sides.

The librarian gives you a book. The research assistant gives you an answer.

## Agentic RAG with Google Cloud

Google Cloud provides several building blocks for implementing agentic RAG:

### Vertex AI RAG engine

The [Vertex AI RAG Engine](https://cloud.google.com/vertex-ai/generative-ai/docs/rag-overview) provides managed infrastructure for RAG pipelines. It handles document ingestion, chunking, embedding, and retrieval so you can focus on the agentic logic.

Key features:
- Managed vector search with automatic indexing
- Multiple data source connectors (Cloud Storage, Google Drive, web URLs)
- Configurable chunking and embedding strategies
- Integration with Vertex AI's model endpoints

### Vertex AI Agent engine

The [Vertex AI Agent Engine](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview) lets you build agents that use RAG as one of their tools. The agent can decide when to search, which data sources to query, and how to combine results.

### Building the loop

A practical agentic RAG implementation on Google Cloud might look like this:

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

## Practical implementation patterns

### Pattern 1: query decomposition

Break complex queries into simpler sub-queries before retrieval.

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

### Pattern 2: retrieval with verification

After generating an answer, verify each claim against the source documents.

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

### Pattern 3: iterative deepening

Start with a broad search and progressively narrow based on what you find.

```
Round 1: Broad search for "customer complaints Q3"
  -> Found: Common themes include shipping delays, product quality

Round 2: Focused search for "shipping delay root cause Q3"
  -> Found: Warehouse staffing issues in September

Round 3: Specific search for "warehouse staffing September impact"
  -> Found: 40% increase in fulfillment time due to understaffing

Agent now has a complete chain from symptoms to root cause.
```

### Pattern 4: source triangulation

Query multiple independent sources and look for agreement.

```
Question: "What is the expected release date for Project Phoenix?"

Source 1 (Project tracker): "Target: March 15"
Source 2 (Team standup notes): "Aiming for mid-March release"
Source 3 (Executive update): "Phoenix launching March 15-20 window"

Agent: "Multiple sources converge on a mid-March release,
specifically targeting March 15-20."
```

## Common pitfalls

### Pitfall 1: infinite retrieval loops

The agent keeps searching because it never considers the results "good enough." Always set a maximum number of retrieval iterations (typically 3-5) and have the agent provide its best answer with a confidence caveat when the limit is reached.

### Pitfall 2: Over-Retrieval

The agent retrieves too many documents and overwhelms the context window. Set limits on the number of documents per retrieval step and the total context size. Prioritize relevance over quantity.

### Pitfall 3: ignoring retrieved context

The agent retrieves documents but then generates an answer based on its training data instead of the retrieved information. Use strong grounding instructions that tell the agent to base its answer on the retrieved documents and cite them explicitly.

### Pitfall 4: no fallback for missing information

The agent tries to answer even when the knowledge base does not contain the needed information. Train the agent to recognize gaps and say "I could not find information about X in the available sources" rather than hallucinating an answer.

## Hands-On Exercise

Build an agentic RAG system for a technical documentation use case:

1. **Setup:** Choose a set of technical documents (your own project docs, or a public documentation set like the Google Cloud docs).

2. **Basic RAG baseline:** Implement a simple retrieve-then-read pipeline. Test it with five questions of varying complexity.

3. **Add agentic capabilities:** Implement at least two of the following:
   - Query decomposition for complex questions
   - Result evaluation with re-querying
   - Multi-source retrieval
   - Answer verification against sources

4. **Compare:** Run the same five questions through both systems. Document where the agentic version produces better answers and where it adds unnecessary overhead.

## Key takeaways

- Basic RAG follows a fixed retrieve-then-read pipeline. Agentic RAG puts an agent in control of retrieval, letting it decide when to search, what to search for, and whether results are sufficient.
- The agentic RAG loop - plan, retrieve, evaluate, refine, answer, verify - replaces the single-shot approach with iterative refinement.
- Key capabilities include autonomous query planning, adaptive source selection, context-aware expansion, and multi-hop reasoning.
- Self-correction through re-querying, diagnostic checks, and human fallback prevents the system from committing to poor results.
- Use basic RAG for simple lookups where speed matters. Use agentic RAG for complex research questions where accuracy matters more than latency.
- Set clear limits on retrieval iterations and context size to avoid infinite loops and runaway costs.

## Further reading

- [Vertex AI RAG Engine Overview](https://cloud.google.com/vertex-ai/generative-ai/docs/rag-overview) - Managed RAG infrastructure on Google Cloud
- [Vertex AI Agent Engine Overview](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview) - Building agents that use RAG as a tool on Vertex AI
