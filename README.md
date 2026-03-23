This repository demonstrates how to build a Context Graph using Google Cloud Spanner Graph and the Google ADK. By unifying operational state, decision history, and corporate policy in a single globally consistent environment, we move from a simple "System of Record" to a "System of Intelligence".

🏗️ The Agentic Stack
This implementation focuses on a Local Function Tool approach, allowing developers to build agentic workflows without requiring an external MCP (Model Context Protocol) server.

Foundation: Google Cloud Spanner Graph.

Orchestration: Google ADK (Agent Development Kit).

Intelligence: Gemini 2.0 Flash.

📂 Repository Structure
agent.py: The core ADK implementation. It manages the multi-turn reasoning loop, enforcing policies before delivering an Intelligence Report.

ContextGraph.sql: The DDL and DML scripts to initialize your Spanner Graph, including Nodes (Customers, Policies, Decisions, Outcomes) and Edges.

ContextGraphOnSpanner.ipynb: A companion notebook for rapid prototyping of GQL (Graph Query Language) patterns.

🚀 Getting Started
1. Initialize Spanner Graph
Run the contents of ContextGraph.sql in your Spanner instance to create the schema and seed the "Institutional Memory".

2. Configure Environment
Set your Google Cloud credentials and project details:

Bash
export GOOGLE_CLOUD_PROJECT="your-project-id"
export GOOGLE_CLOUD_LOCATION="us-central1"
export GOOGLE_GENAI_USE_VERTEXAI="True"
3. Install Dependencies
Bash
pip install google-cloud-spanner google-adk google-genai
4. Run the Agent
Bash
python3 agent.py
🛡️ The Intelligence Loop
This agent doesn't just "chat"; it follows a governed lifecycle:

Recall: Traversing the Graph to find similar historical outcomes (The Event Clock).

Govern: Checking active corporate mandates in the Policies table (The Policy Guardrail).

Codify: Writing its final reasoning back into Spanner, growing the graph for future runs.

💡 Why Spanner Graph?
Unlike traditional Vector RAG, a Context Graph on Spanner provides deterministic reliability. It ensures your AI agents are governed by the same ACID-compliant rigor as your financial transactions, delivering high-fidelity responses at global scale.
