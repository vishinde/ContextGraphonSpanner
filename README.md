# Governed Growth Strategist
### A Spanner Graph System of Intelligence

This project demonstrates a **System of Intelligence** built on **Google Cloud Spanner Graph** and **Gemini 2.0**. It transforms unstructured corporate data—such as PDFs, Slack messages, and CRM logs—into a structured **Context Graph**, enabling AI Agents to make data-backed, governed business decisions.

---

## Repository Structure

The repository is organized into three progressive stages of implementation:

### 1. agenticingestion/ — The Institutional Memory Pipeline
* **Goal:** Build the initial Context Graph in Spanner.
* **Purpose:** Ingests unstructured PDF policies and CRM logs (CSV).
* **Logic:** Uses Gemini to extract causal relationships (Decision -> Outcome) and corporate guardrails.
* **Key Files:** `ingestpolicies.py`, `agent.py` (ingestor), `createcontextgraph.sql`.

### 2. customergrowthagent/ — The Direct Strategist
* **Goal:** Reasoning via Direct Database Access.
* **Purpose:** A production-ready agent querying Spanner via Python `FunctionTools`.
* **Logic:** Performs **"Behavioral Twin"** lookups to find historical success patterns for similar customer profiles.
* **Key Files:** `agent.py`, `insightsfromcontextgraph.sql`.

### 3. customergrowthagentwmcptoolbox/ — The Managed Integration
* **Goal:** Scalable Tooling via MCP Toolbox.
* **Purpose:** Decouples the Agent from database logic using the **Model Context Protocol (MCP)**.
* **Logic:** Uses a `tools.yaml` configuration to map natural language intent to high-performance SQL/GQL queries.
* **Key Files:** `agent.py`, `tools.yaml`.

### Note: The benchmarkagenticingestion folder is optional code. It demonstrates options for benchmarking on agenticingestion pipeline.
---

## Technical Architecture

| Phase | Description |
| :--- | :--- |
| **Ingestion** | Gemini 2.0 parses PDFs and CSVs, mapping them to a Property Graph schema in Spanner. |
| **Storage** | Spanner Graph stores **Institutional Wisdom** (Success vs. Churn pathways). |
| **Governance** | The `Policies` table acts as a real-time guardrail for AI recommendations. |
| **Action** | The Agent synthesizes history and policy to generate a **Success Blueprint**. |

---

## The "Behavioral Twin" Methodology

Standard Retrieval-Augmented Generation (RAG) often lacks structural context. This system utilizes a **Context Graph** on Spanner to provide deeper relational insights:

* **Nodes:** `Customers`, `Decisions`, `Outcomes`, `Policies`.
* **Edges:** `AboutCustomer`, `ResultedIn`.

> **The Graph Advantage:** Instead of basic keyword searches, the Agent performs relational queries: *"Show me other Gold-tier Manufacturing accounts that faced a 30% usage drop. What specific actions were taken, and what was the resulting outcome?"*

---

## Quick Start

### Prerequisites
* Google Cloud Project with an active Spanner Instance.
* Python 3.10+
* Gemini 2.0 API access via Vertex AI.

### Installation
1. **Initialize Schema:** Run `agenticingestion/createcontextgraph.sql` in Spanner Studio.
2. **Populate Data:** Run the scripts in `agenticingestion/` to load initial policies and history.
3. **Run the Agent:** Choose the preferred implementation (Direct or MCP) and run the respective `agent.py`.
