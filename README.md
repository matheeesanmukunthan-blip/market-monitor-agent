# Market Monitor Agent — Agentforce + FSC + Data Cloud

> Salesforce Agentforce Hackathon 2025

## Deploy

```bash
# 1. Authenticate
sf org login web --alias my-org

# 2. Deploy all metadata
sf project deploy start --source-dir force-app --target-org my-org

# 3. Assign permission set
sf org assign permset --name Market_Monitor_Agent_PS --target-org my-org

# 4. Run tests
sf apex run test --class-names MarketAlertServiceTest ClientSegmentationServiceTest --result-format human --target-org my-org

force-app/main/default/
├── classes/                        ← Apex classes + test classes
├── lwc/
│   ├── marketAlertBanner/          ← FSC Home Page alert banner
│   └── preCallBrief/               ← Contact Record 360° brief
├── objects/
│   ├── Market_Alert__c/            ← Custom object + fields
│   ├── Contact/fields/             ← Custom fields on Contact
│   └── FinancialHolding__c/fields/ ← Custom fields on Holdings
├── permissionsets/                 ← Market_Monitor_Agent_PS
└── flows/                          ← Dispatch + Reply Logger flows
```
