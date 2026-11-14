# SFDC Dev Essentials

A collection of reusable Salesforce projects for everyday development work.

Each folder is a **self-contained SFDX project** with its own `sfdx-project.json`, metadata and README — clone the repository once, then open and deploy whichever project you need.

---

## Projects

| Project | Description |
| --- | --- |
| [Trigger Framework](Trigger%20Framework/README.md) | Metadata-driven Apex trigger framework with a centralised bypass mechanism shared by Apex triggers and record-triggered Flows. Handlers are registered as custom metadata, so adding, reordering or deactivating automation is a configuration change rather than a code change. |

---

## Getting started

```bash
git clone https://github.com/debarshi-ghosh/sfdc-essentials.git
cd "sfdc-essentials/Trigger Framework"
```

Open the **project folder itself** in VS Code — not the repository root. The Salesforce extensions look for `sfdx-project.json` in the folder you open.

Then connect an org and deploy:

```bash
sf org login web -a myorg
sf project deploy start -d force-app -o myorg
```

See each project's README for its full setup, configuration and test instructions.

### Cloning a single project

The repository is small, so a full clone is usually fine. To pull down just one project:

```bash
git clone --filter=blob:none --sparse https://github.com/debarshi-ghosh/sfdc-essentials.git
cd sfdc-essentials
git sparse-checkout set "Trigger Framework"
```

---

## Prerequisites

- **Salesforce CLI** — [developer.salesforce.com/tools/salesforcecli](https://developer.salesforce.com/tools/salesforcecli)
- **VS Code with the Salesforce Extension Pack** — [installation instructions](https://developer.salesforce.com/docs/platform/sfvscode-extensions/guide/install.html)
- **A Salesforce org** — [sign up for a free Developer Edition](https://developer.salesforce.com/signup)

---

## Repository layout

Projects live in folders on `main`. Branches are used for work in progress and merged back via pull request, so everything on `main` is ready to clone and deploy.

```
sfdc-essentials/
├── README.md              # this index
├── LICENSE                # MIT
├── .gitignore             # repository-wide ignores
└── Trigger Framework/     # self-contained SFDX project
    ├── sfdx-project.json
    ├── force-app/
    ├── config/
    └── README.md
```

---

## Licence

Released under the [MIT Licence](LICENSE) — free to use, modify and deploy, including commercially. Please keep the copyright notice.

