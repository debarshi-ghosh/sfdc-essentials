# Apex Fundamentals — Day 02

Companion code for the Day 2 Salesforce Engineering Journey article: **Apex Fundamentals: Build Your First Useful Class**.

## What you'll learn

- Apex class and method structure
- Parameters and return values
- List collections and null/blank handling
- Bulk DML outside loops
- Apex unit tests and assertions

## Project structure

```text
Apex Fundamentals Day 02/
├── sfdx-project.json
└── force-app/main/default/classes/
    ├── AccountCreationService.cls
    ├── AccountCreationService.cls-meta.xml
    ├── AccountCreationServiceTest.cls
    └── AccountCreationServiceTest.cls-meta.xml
```

## Deploy and test

Prerequisites: Salesforce CLI, VS Code with Salesforce Extension Pack, and a Developer Edition org or Trailhead Playground.

```bash
sf org login web -a day02
sf project deploy start -o day02
sf apex run test --tests AccountCreationServiceTest --result-format human --code-coverage -o day02
```

Open this project folder (not the repository root) in VS Code. The example inserts Accounts; run it only in a practice org.

## Notes

This is an educational example, not a complete production service. Review sharing, CRUD/FLS enforcement, duplicate handling and error strategy before adapting it to real applications.
