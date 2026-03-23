import asyncio
import uuid
import warnings
import os
from google.adk.agents import Agent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.adk.tools import FunctionTool
from google.genai import types
from google.cloud import spanner

# --- 1. Environment & Telemetry Suppression ---
warnings.filterwarnings("ignore", category=UserWarning, module="google_genai")

# SILENCE THE TELEMETRY ERRORS: Disable Spanner and OTEL metrics
os.environ["GOOGLE_CLOUD_SPANNER_ENABLE_METRICS"] = "false"
os.environ["OTEL_SDK_DISABLED"] = "true"

PROJECT_ID = "xxx"
INSTANCE_ID = "graph"
DATABASE_ID = "supportgraph"

os.environ["GOOGLE_CLOUD_PROJECT"] = PROJECT_ID
os.environ["GOOGLE_CLOUD_LOCATION"] = "us-central1"
os.environ["GOOGLE_GENAI_USE_VERTEXAI"] = "True"

# Initialize Spanner Client
spanner_client = spanner.Client()
instance = spanner_client.instance(INSTANCE_ID)
database = instance.database(DATABASE_ID)

# --- 2. Robust Tool Functions ---

def check_retention_history(customer_id: str):
    """Lookup historical decisions and outcomes from the Spanner Context Graph."""
    gql_query = f"""
    GRAPH SupportContextGraph
    MATCH (c:Customers {{customer_id: '{customer_id}'}})<-[:AboutCustomer]-(d:Decisions)
    MATCH (d)-[:ResultedIn]->(o:Outcomes)
    RETURN 
      d.timestamp AS Date,
      d.type AS Action_Type,
      d.amount AS Past_Amount,
      o.result AS Past_Outcome
    ORDER BY d.timestamp DESC
    """
    with database.snapshot() as snapshot:
        results = snapshot.execute_sql(gql_query)
        # Convert to list to avoid iterator errors
        rows = list(results)
        return [{"date": str(r[0]), "action": r[1], "amount": r[2], "outcome": r[3]} for r in rows]

def get_policy_details(policy_id: str):
    """Retrieves the active corporate rule definition from the Policies table."""
    sql = "SELECT name, rule_definition, is_active FROM Policies WHERE policy_id = @pid"
    with database.snapshot() as snapshot:
        results = snapshot.execute_sql(
            sql, params={'pid': policy_id}, 
            param_types={'pid': spanner.param_types.STRING}
        )
        # Convert to list and safely access the first row
        rows = list(results)
        if not rows:
            return "Policy not found."
        row = rows[0]
        return {"name": row[0], "rule": row[1], "active": row[2], "id": policy_id}

# --- 3. ADK Tool & Agent Setup ---

tools = [
    FunctionTool(check_retention_history),
    FunctionTool(get_policy_details)
]

async def run_governed_pipeline(text_input: str):
    user_id = "user_123"
    session_id = str(uuid.uuid4())
    APP_NAME = "RetentionApp"

    # Define the Intelligence Report template
    report_instruction = (
            "You are an expert retention strategist. Follow these steps for every query:\n"
            "1. Run 'check_retention_history' for the customer.\n"
            "2. IF a previous 'Churned' outcome is found for a discount, run 'get_policy_details' for 'POL-99'.\n"
            "3. Generate the report using the following format:\n\n"
            "==================================================\n"
            "🔍 CONTEXT GRAPH INTELLIGENCE REPORT\n"
            "==================================================\n"
            "⚠️ PRECEDENT FOUND: HIGH-RISK FAILURE\n"
            "   • Date: [Date from history]\n"
            "   • Action: [Action_Taken] ([Discount_Amount])\n"
            "   • Outcome: ❌ [Final_Result]\n\n"
            "🛡️ CORPORATE POLICY ENFORCEMENT:\n"
            "   • Policy: [Name from policy tool] ([policy_id])\n"
            "   • Rule: [rule_definition from policy tool]\n"
            "   • Status: [IF is_active=True, 'ACTIVE - BLOCKING REPETITIVE TACTIC']\n\n"
            "==================================================\n"
            "Final Agent Decision: [Synthesize the history and policy into a recommendation.]"
        )

    # Initialize Agent
    agent = Agent(
        name="retention_specialist",
        model="gemini-2.0-flash",
        instruction=report_instruction,
        tools=tools
    )

    # Setup Session Service & Runner
    session_service = InMemorySessionService()
    await session_service.create_session(app_name=APP_NAME, user_id=user_id, session_id=session_id)
    
    runner = Runner(app_name=APP_NAME, agent=agent, session_service=session_service)

    print(f"🚀 Starting ADK Pipeline... [Session: {session_id}]")
    current_content = types.Content(role='user', parts=[types.Part(text=text_input)])

    async for event in runner.run_async(
        new_message=current_content,
        user_id=user_id, 
        session_id=session_id
    ):
        if event.author and event.content and event.content.parts:
            text = event.content.parts[0].text
            if text:
                print(f"\n[{event.author}]: {text}")

if __name__ == "__main__":
    prompt = "Should I give CUST-001 a 50% discount?"
    asyncio.run(run_governed_pipeline(prompt))
