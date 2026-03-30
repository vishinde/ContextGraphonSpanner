-- The Customer: Now with Tier and Usage tracking
CREATE TABLE Customers (
  customer_id STRING(36) NOT NULL,
  name STRING(MAX) NOT NULL,
  industry STRING(MAX) NOT NULL, 
  tier STRING(MAX) NOT NULL,     -- 'Gold', 'Silver', 'Bronze'
  mrr NUMERIC NOT NULL,          
  usage_score FLOAT64            -- Used to detect "Quiet Signals" of contraction
) PRIMARY KEY (customer_id);

-- The Policy: Governance for LTV and Margin Protection
CREATE TABLE Policies (
  policy_id STRING(36) NOT NULL,
  name STRING(MAX) NOT NULL,
  rule_definition STRING(MAX) NOT NULL,
  is_active BOOL
) PRIMARY KEY (policy_id);

-- The Decision: The "Reasoning" behind the action
CREATE TABLE Decisions (
  decision_id STRING(36) NOT NULL,
  type STRING(MAX) NOT NULL,     -- e.g., 'Strategic_Advisory_Workshop'
  amount NUMERIC,                -- The cost or discount value
  reasoning_text STRING(MAX),    -- The "Institutional Memory"
  timestamp TIMESTAMP
) PRIMARY KEY (decision_id);

-- The Outcome: The ground truth of what happened
CREATE TABLE Outcomes (
  outcome_id STRING(36) NOT NULL,
  result STRING(MAX) NOT NULL,   -- e.g., 'Renewed_Full_Price'
  revenue_impact NUMERIC,
  observation_period_days INT64
) PRIMARY KEY (outcome_id);

-- Connects a Decision to a specific Customer
CREATE TABLE AboutCustomer (
  decision_id STRING(36) NOT NULL,
  customer_id STRING(36) NOT NULL,
  CONSTRAINT fk_decision_customer FOREIGN KEY (decision_id) REFERENCES Decisions (decision_id),
  CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES Customers (customer_id)
) PRIMARY KEY (decision_id, customer_id);

-- Connects a Decision to the Policy it followed
CREATE TABLE FollowedPolicy (
  decision_id STRING(36) NOT NULL,
  policy_id STRING(36) NOT NULL,
  CONSTRAINT fk_decision_policy FOREIGN KEY (decision_id) REFERENCES Decisions (decision_id),
  CONSTRAINT fk_policy FOREIGN KEY (policy_id) REFERENCES Policies (policy_id)
) PRIMARY KEY (decision_id, policy_id);

-- Connects a Decision to its final Outcome
CREATE TABLE ResultedIn (
  decision_id STRING(36) NOT NULL,
  outcome_id STRING(36) NOT NULL,
  CONSTRAINT fk_decision_outcome FOREIGN KEY (decision_id) REFERENCES Decisions (decision_id),
  CONSTRAINT fk_outcome FOREIGN KEY (outcome_id) REFERENCES Outcomes (outcome_id)
) PRIMARY KEY (decision_id, outcome_id);

CREATE OR REPLACE PROPERTY GRAPH GrowthContextGraph
  NODE TABLES (
    Customers,
    Policies,
    Decisions,
    Outcomes
  )
  EDGE TABLES (
    AboutCustomer
      SOURCE KEY (decision_id) REFERENCES Decisions (decision_id)
      DESTINATION KEY (customer_id) REFERENCES Customers (customer_id)
      LABEL AboutCustomer,
    FollowedPolicy
      SOURCE KEY (decision_id) REFERENCES Decisions (decision_id)
      DESTINATION KEY (policy_id) REFERENCES Policies (policy_id)
      LABEL FollowedPolicy,
    ResultedIn
      SOURCE KEY (decision_id) REFERENCES Decisions (decision_id)
      DESTINATION KEY (outcome_id) REFERENCES Outcomes (outcome_id)
      LABEL ResultedIn
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



-- ============================================================================
-- STEP 1: INITIALIZE THE CUSTOMER ENTITY (THE STATE)
-- ============================================================================
-- High-value Gold tier account in the Manufacturing sector.
INSERT INTO Customers (customer_id, name, industry, tier, mrr, usage_score)
VALUES 
  ('CUST-001', 'Global Logistics Corp', 'Manufacturing', 'Gold', 5000.00, 0.45), -- The target (Usage dropped)
  ('CUST-TWIN', 'Precision Parts Intl', 'Manufacturing', 'Gold', 7500.00, 0.85); -- The "Twin" (Success Story)
-- ============================================================================
-- STEP 2: DEFINE THE GROWTH & RETENTION GOVERNANCE (THE POLICY)
-- ============================================================================
-- Shifting from simple "Retention" to "LTV Optimization" to protect margins.
INSERT INTO Policies (policy_id, name, rule_definition, is_active)
VALUES 
  ('POL-99', 
  'LTV Optimization & Margin Protection', 
  'Maximize Long-Term Value (LTV) over short-term revenue. Avoid repetitive discounting if it failed to prevent churn in the past.', 
  TRUE);
-- 1. The Strategy: Expansion & Upsell Logic
INSERT INTO Policies (policy_id, name, rule_definition, is_active)
VALUES (
    'POL-102', 
    'Expansion-First Growth', 
    'For Gold Tier accounts with high usage (score > 0.8), prioritize Upsell offers for Premium Analytics over retention discounts.', 
    TRUE
);

-- 2. The Safeguard: Multi-Product Synergy
INSERT INTO Policies (policy_id, name, rule_definition, is_active)
VALUES (
    'POL-205', 
    'Cross-Sell Bundle Governance', 
    'If a customer uses both Logistics and Warehouse modules, offer a "Unified Suite" credit instead of individual module discounts to increase platform stickiness.', 
    TRUE
);

-- 3. The Financial Guardrail: Minimum Margin Floor
INSERT INTO Policies (policy_id, name, rule_definition, is_active)
VALUES (
    'POL-444', 
    'Minimum Margin Protection', 
    'Total contract discounts across all decisions cannot exceed 20% of annual contract value (ACV) without Executive VP approval.', 
    TRUE
);

-- 4. The Relationship Pivot: Executive Engagement
INSERT INTO Policies (policy_id, name, rule_definition, is_active)
VALUES (
    'POL-88', 
    'Executive QBR Escalation', 
    'For any Gold Tier account showing a >20% usage drop, trigger an Executive Business Review (EBR) credit to align product roadmap with client business goals.', 
    TRUE
);
-- ============================================================================
-- STEP 3: CODIFY THE FAILURE CONTEXT (THE LESSON FROM HISTORY)
-- ============================================================================
-- The Decision: A reactive 50% discount attempt that "threw money at the problem."
INSERT INTO Decisions (decision_id, type, amount, reasoning_text, timestamp)
VALUES (
    'DEC-2025-01', 
    'Reactive_Discount', 
    0.50, 
    'Customer threatened to leave for a cheaper competitor. Attempted to match price to save account.', 
    '2025-03-15 10:00:00'
);

-- The Outcome: The discount failed to address the root cause, leading to churn.
INSERT INTO Outcomes (outcome_id, result, revenue_impact, observation_period_days)
VALUES ('OUT-2025-01', 'Churned', -5000.00, 90);

-- Connecting the Dots: Linking the failure to the Customer, Policy, and Outcome.
INSERT INTO AboutCustomer (decision_id, customer_id) VALUES ('DEC-2025-01', 'CUST-001');
INSERT INTO FollowedPolicy (decision_id, policy_id) VALUES ('DEC-2025-01', 'POL-99');
INSERT INTO ResultedIn (decision_id, outcome_id) VALUES ('DEC-2025-01', 'OUT-2025-01');


-- ============================================================================
-- STEP 4: CODIFY THE SUCCESS CONTEXT (THE PROVEN ALTERNATIVE)
-- ============================================================================
-- The Decision: Pivoting to Strategic Advisory/Expertise to increase "stickiness."
-- Note: Amount = 0 direct cost to protect company margin, but high perceived value.
-- The Successful Decision (The Workshop)
INSERT INTO Decisions (decision_id, type, amount, reasoning_text, timestamp)
VALUES ('DEC-WIN-2026', 
  'Strategic_Advisory_Workshop', 
  0.00, 
  'Identified low feature adoption in Gold account. Offer expert-led Competitive Edge workshop to increase product stickiness and demonstrate ROI vs competitors.', 
  '2026-01-15 14:00:00');

-- The Positive Outcome
INSERT INTO Outcomes (outcome_id, result, revenue_impact, observation_period_days)
VALUES ('OUT-WIN-2026', 'Renewed_Full_Price', 7500.00, 365);

-- Linking the Success to the Twin
INSERT INTO AboutCustomer (decision_id, customer_id) VALUES ('DEC-WIN-2026', 'CUST-TWIN');
INSERT INTO FollowedPolicy (decision_id, policy_id) VALUES ('DEC-WIN-2026', 'POL-99');
INSERT INTO ResultedIn (decision_id, outcome_id) VALUES ('DEC-WIN-2026', 'OUT-WIN-2026');


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
To show the broader impact of a Context Graph beyond a single customer, 
  we use Community Detection and Similarity Clustering.
  For an ISV, this is the "Macro-Context"—it proves that the failure of the 50% discount isn't just a one-off fluke with Customer A, 
  but a systemic pattern across a specific "Community" of customers.The "Community of Failure" GQL Query
  This query uses the Spanner Graph to find all customers in the "Manufacturing" industry who were given a high discount and still churned. It groups them by the Reasoning used in the decision to show a "Failure Cluster.
*/
--Old, Refer to below query. Check this queries functionality and logic
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

/*
I see a Gold Tier customer with falling usage. 
Let me find a similar Gold Tier peer who had this problem and see what specific action led to a full-price renewal.
*/
GRAPH GrowthContextGraph
MATCH (twin:Customers {industry: 'Manufacturing', tier: 'Gold'})
      <-[:AboutCustomer]-(d:Decisions)
      -[:ResultedIn]->(o:Outcomes {result: 'Renewed_Full_Price'})
WHERE d.reasoning_text LIKE '%low feature adoption%'
  AND twin.customer_id != 'CUST-001' -- Don't look at the current customer
RETURN 
    d.type AS Recommended_Action, 
    d.reasoning_text AS Success_Reasoning, 
    o.revenue_impact AS Margin_Protected
ORDER BY o.revenue_impact DESC
LIMIT 1;
