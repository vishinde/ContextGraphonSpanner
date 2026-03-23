CREATE PROPERTY GRAPH SupportContextGraph
  NODE TABLES (
    Customers,
    Policies,
    Decisions,
    Outcomes
  )
  EDGE TABLES (
    AboutCustomer
      SOURCE KEY (decision_id) REFERENCES Decisions
      DESTINATION KEY (customer_id) REFERENCES Customers,
    FollowedPolicy
      SOURCE KEY (decision_id) REFERENCES Decisions
      DESTINATION KEY (policy_id) REFERENCES Policies,
    ResultedIn
      SOURCE KEY (decision_id) REFERENCES Decisions
      DESTINATION KEY (outcome_id) REFERENCES Outcomes
  );

  GRAPH SupportContextGraph
MATCH (c:Customers {customer_id: 'CUST-001'})<-[:AboutCustomer]-(d:Decisions)
-- Step 2: Traverse to the outcome to see the historical "Why"
MATCH (d)-[:ResultedIn]->(o:Outcomes)
-- Step 3: Check the governing policy
MATCH (d)-[:FollowedPolicy]->(p:Policies)
RETURN 
  d.timestamp AS Date,
  d.type AS Action_Taken,
  d.reasoning_text AS AI_Reasoning,
  o.result AS Final_Result,
  o.revenue_impact AS MRR_Impact
ORDER BY d.timestamp ASC



  -- The Customer: Global Logistics Corp
INSERT INTO Customers (customer_id, name, industry, tier, mrr)
VALUES ('CUST-001', 'Global Logistics Corp', 'Manufacturing', 'Gold', 5000.00);

-- The Policy: Our Governance Rule
INSERT INTO Policies (policy_id, name, rule_definition, is_active)
VALUES ('POL-99', 'Retention Priority', 'Maximize LTV over short-term revenue. Avoid repetitive discounting.', TRUE);

--Failure Context
-- The Decision: A 50% discount given last year
INSERT INTO Decisions (decision_id, type, amount, reasoning_text, timestamp)
VALUES ('DEC-2025-01', 'Retention_Offer', 0.50, 'Customer threatened to leave for a cheaper competitor. Match price to save account.', '2025-03-15 10:00:00');

-- The Outcome: They churned anyway
INSERT INTO Outcomes (outcome_id, result, revenue_impact, observation_period_days)
VALUES ('OUT-2025-01', 'Churned', -5000.00, 90);

-- Connect the Dots (The Edges)
INSERT INTO AboutCustomer (decision_id, customer_id) VALUES ('DEC-2025-01', 'CUST-001');
INSERT INTO FollowedPolicy (decision_id, policy_id) VALUES ('DEC-2025-01', 'POL-99');
INSERT INTO ResultedIn (decision_id, outcome_id) VALUES ('DEC-2025-01', 'OUT-2025-01');

--Success Context
-- The Decision: Technical Workshop (Amount = 0 cost, but high value)
INSERT INTO Decisions (decision_id, type, amount, reasoning_text, timestamp)
VALUES ('DEC-2026-05', 'Value_Added_Service', 0.00, 'Identified low feature adoption. Offer free technical health check to increase stickiness.', '2026-03-10 14:00:00');

-- The Outcome: They Renewed!
INSERT INTO Outcomes (outcome_id, result, revenue_impact, observation_period_days)
VALUES ('OUT-2026-05', 'Renewed', 5000.00, 365);

-- Connect the Dots (The Edges)
INSERT INTO AboutCustomer (decision_id, customer_id) VALUES ('DEC-2026-05', 'CUST-001');
INSERT INTO FollowedPolicy (decision_id, policy_id) VALUES ('DEC-2026-05', 'POL-99');
INSERT INTO ResultedIn (decision_id, outcome_id) VALUES ('DEC-2026-05', 'OUT-2026-05');

GRAPH SupportContextGraph
MATCH (c:Customers {customer_id: 'CUST-001'})<-[:AboutCustomer]-(d:Decisions)
-- Step 2: Traverse to the outcome to see the historical "Why"
MATCH (d)-[:ResultedIn]->(o:Outcomes)
-- Step 3: Check the governing policy
MATCH (d)-[:FollowedPolicy]->(p:Policies)
RETURN 
  d.timestamp AS Date,
  d.type AS Action_Taken,
  d.reasoning_text AS AI_Reasoning,
  o.result AS Final_Result,
  o.revenue_impact AS MRR_Impact
ORDER BY d.timestamp ASC

/*
To show the broader impact of a Context Graph beyond a single customer, we use Community Detection and Similarity Clustering.For an ISV, this is the "Macro-Context"—it proves that the failure of the 50% discount isn't just a one-off fluke with Customer A, but a systemic pattern across a specific "Community" of customers.The "Community of Failure" GQL QueryThis query uses the Spanner Graph to find all customers in the "Manufacturing" industry who were given a high discount and still churned. It groups them by the Reasoning used in the decision to show a "Failure Cluster.
*/
GRAPH SupportContextGraph
MATCH (ind:Industry {name: 'Manufacturing'})<-[:InIndustry]-(c:Customers)
MATCH (c)<-[:AboutCustomer]-(d:Decisions {type: 'Retention_Offer'})
MATCH (d)-[:ResultedIn]->(o:Outcomes {result: 'Churned'})
WHERE d.amount >= 0.40
RETURN 
  d.reasoning_text AS Failed_Logic,
  COUNT(c) AS Customer_Count,
  SUM(o.revenue_impact) AS Total_Loss
ORDER BY Customer_Count DESC
/*
Why this is a "Spanner Power Move" for ISVs:Macro-Context Reasoning: In your demo, the AI Agent can now say: "I am rejecting the 50% discount because our Context Graph shows this logic has failed 15 times in the Manufacturing sector, resulting in $75,000 in lost revenue over the last year."Pattern Discovery: ISVs like HubSpot or Pega can use this to identify "Bad Policies." If the graph shows a cluster of failures for a specific policy, they can automatically update the Policy node to "Inactive" or "Restrictive."Cross-Tenant Intelligence (Optional): For multi-tenant ISVs, Spanner's scale allows them to see these patterns across their entire fleet of customers (anonymized, of course) to provide "Benchmark-as-a-Service" insights.Final Summary for your Demo DeckDemo ComponentWhat it proves to the ISVThe State ClockSpanner holds the "Truth" (Customer/SLA data).The Event ClockThe Context Graph holds the "Wisdom" (Decision/Outcome history).The Policy GuardrailThe ADK enforces the "Rules" (Governance).The Community QuerySpanner scales the "Insights" (Systemic patterns).*/