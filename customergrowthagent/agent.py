import asyncio
import uuid
import warnings
import os
import json
from google.adk.agents import Agent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.adk.tools import FunctionTool
from google.genai import types
from google.cloud import spanner

# --- 1. Environment & Telemetry ---
warnings.filterwarnings("ignore", category=UserWarning)
os.environ["GOOGLE_CLOUD_SPANNER_ENABLE_METRICS"] = "false"
os.environ["OTEL_SDK_DISABLED"] = "true"

PROJECT_ID = "xxxx"
INSTANCE_ID = "graphxx"
DATABASE_ID = "marketinggraph" # Matches your ingestion DB

os.environ["GOOGLE_CLOUD_PROJECT"] = PROJECT_ID
os.environ["GOOGLE_CLOUD_LOCATION"] = "us-central1"
os.environ["GOOGLE_GENAI_USE_VERTEXAI"] = "True"

spanner_client = spanner.Client(project=PROJECT_ID)
instance = spanner_client.instance(INSTANCE_ID)
database = instance.database(DATABASE_ID)

# --- 2. Aligned Tool Functions ---

def get_customer_info(customer_id: str):
    """Retrieves basic customer metadata like Industry and Tier."""
    sql = "SELECT industry, tier FROM Customers WHERE customer_id = @cid"
    with database.snapshot() as snapshot:
        results = snapshot.execute_sql(sql, params={'cid': customer_id}, 
                                       param_types={'cid': spanner.param_types.STRING})
        rows = list(results)
        if rows:
            return {"industry": rows[0][0], "tier": rows[0][1]}
        return "Customer not found."


def check_retention_history(industry: str, tier: str):
    """Lookup successful patterns across an entire industry segment."""
    # We order by timestamp so the Agent sees the most modern 'Success Pathways' first
    gql_query = f"""
    GRAPH MarketingContextGraph
    MATCH (c:Customers {{industry: '{industry}', tier: '{tier}'}})<-[:AboutCustomer]-(d:Decisions)-[:ResultedIn]->(o:Outcomes)
    WHERE o.result = 'Renewed'
    RETURN 
      d.timestamp AS Date,
      d.type AS Action_Type,
      d.reasoning_text AS Success_Logic,
      o.result AS Outcome
    ORDER BY d.timestamp DESC
    """
    with database.snapshot() as snapshot:
        results = snapshot.execute_sql(gql_query)
        rows = list(results)
        return [{"date": str(r[0]), "type": r[1], "logic": r[2], "outcome": r[3]} for r in rows]

def get_policy_details(policy_id: str):
    """Retrieves corporate rules (e.g., POL-444 Margin Protection)."""
    sql = "SELECT name, rule_definition FROM Policies WHERE policy_id = @pid"
    with database.snapshot() as snapshot:
        results = snapshot.execute_sql(sql, params={'pid': policy_id}, 
                                       param_types={'pid': spanner.param_types.STRING})
        rows = list(results)
        return {"name": rows[0][0], "rule": rows[0][1]} if rows else "Policy not found."

# --- 3. Agent & Report Orchestration ---

report_instruction = (
    "You are a Senior Strategic Growth Agent. Your goal is to provide data-backed recommendations "
    "by analyzing 'Behavioral Twins' in the Spanner Context Graph.\n\n"
    
    "MISSION:\n"
    "1. FIRST: Use 'get_customer_info' to find the customer's Industry and Tier. "
    "2. SECOND: Use 'check_retention_history' using that customer's Industry and Tier to find success patterns. "
    "3. THIRD: Retrieve the 'Margin Protection' policy (POL-444) to ensure the "
    "   final recommendation is compliant with corporate governance.\n"
    "4. Finally: Synthesize a 'Success Blueprint' based on the highest-ROI historical path.\n\n"
    
    "REPORT STRUCTURE:\n"
    "==================================================\n"
    "🔍 CUSTOMER GROWTH INTELLIGENCE REPORT\n"
    "Account: [Customer Name/ID]\n\n"
    "⚠️ HISTORICAL FRICTION (The 'What to Avoid')\n"
    "Identify a pattern where a specific action led to a 'Churned' outcome in this segment.\n\n"
    "✅ THE SUCCESS PATHWAY (The 'Institutional Wisdom')\n"
    "Detail a successful 'Renewed' path from a similar customer, explaining the reasoning used.\n\n"
    "🛡️ GOVERNED RECOMMENDATION\n"
    "Provide the final recommendation, citing the relevant Policy Rule.\n"
    "=================================================="
)

# Add it to your tools list
tools = [
    FunctionTool(get_customer_info),
    FunctionTool(check_retention_history), # The industry-based one we just made
    FunctionTool(get_policy_details)
]

async def main():
    agent = Agent(name="growth_strategist", model="gemini-2.0-flash", 
                  instruction=report_instruction, tools=tools)
    
    session_service = InMemorySessionService()
    await session_service.create_session(app_name="GrowthApp", user_id="user_123", session_id="session_final")
    runner = Runner(app_name="GrowthApp", agent=agent, session_service=session_service)

    # User Query triggers the Agent to look up the specific customer we ingested (CUST-101)
    prompt = "Generate a growth report for CUST-101. Should we offer a discount to stop their usage drop?"
    content = types.Content(role='user', parts=[types.Part(text=prompt)])

    async for event in runner.run_async(new_message=content, user_id="user_123", session_id="session_final"):
        # 1. Capture and print the final text response
        if event.is_final_response():
            final_text = event.content.parts[0].text
            print(f"\n[Growth Strategist]:\n{final_text}")


if __name__ == "__main__":
    asyncio.run(main())
