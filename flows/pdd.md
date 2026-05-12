# Project-Driven Development (PDD) Flow

## Overview

**PDD** documents the **entire product or program** end to end: vision, domain (economy and mechanics), product UX, visual language, engineering across surfaces, and a cross-team master plan. It complements **SDD** and **VDD**, which focus on **individual features** within a codebase.

Use PDD when you need a single source of truth for:

- **Why** the project exists and what “done” means (charter)
- **What** the system is in business terms: tokens, assets, rules, protections (**domain specification**)
- **How** users move through the product: IA, screens, states, journeys (**product UX**)
- **How it looks and sounds**: design system, prompts, hero and narrative (**visual & messaging**)
- **How it is built**: backend, frontend, chain, integrations (**engineering specifications**)
- **When and in what order**: milestones, dependencies, risks (**master plan**)

Feature-level work still uses `flows/sdd.md` or `flows/vdd.md`; PDD links to those flows where a capability is delivered as a separate SDD/VDD slice.

## Flow Phases

```
CHARTER → DOMAIN → PRODUCT_UX → VISUAL_MESSAGING → ENGINEERING → MASTER_PLAN → IMPLEMENTATION
    ↑        ↑          ↑              ↑               ↑              ↑               ↑
    └────────┴──────────┴──────────────┴───────────────┴──────────────┴───────────────┘
                              (iterate at any phase)
```

### Phase 1: Project charter

**Input**: Stakeholder intent, market context, constraints  
**Output**: `flows/pdd-[name]/01-project-charter.md`

Captures **project-level requirements**:

- Vision, mission, positioning
- Target users and primary jobs-to-be-done
- Scope, MVP, explicit non-goals
- Success metrics and guardrails (compliance, brand, risk)
- High-level user journeys (reference diagrams or attachments)

### Phase 2: Domain specification

**Input**: Approved charter  
**Output**: `flows/pdd-[name]/02-domain-specification.md`

Single place for **domain and economy** (often split in drafts as “economy v1” then “mechanics / balance final” — both belong here as versioned sections):

- Entities, relationships, lifecycle
- Economic rules: inflows, outflows (sinks), fees, caps, vesting or withdrawal rules
- Progression / rarity / limits tables
- Anti-abuse and integrity rules tied to the domain
- Glossary

### Phase 3: Product UX specification

**Input**: Approved domain spec  
**Output**: `flows/pdd-[name]/03-product-ux-specification.md`

**Information architecture and UX** at product scale:

- Navigation map (tabs, hubs, service flows)
- Screen inventory with goals, primary/secondary actions
- State machines (empty, loading, gated, error, success)
- Access rules (what requires wallet, account level, asset ownership)
- Cross-cutting UX rules (e.g. “always show Base → Bonus → Total”)
- Optional: **user journey map** — link to diagram assets (e.g. flowchart image) under `assets/` or `flows/pdd-[name]/artifacts/`

### Phase 4: Visual and messaging

**Input**: Approved product UX  
**Output**: `flows/pdd-[name]/04-visual-and-messaging.md`

Aligns **look, feel, and words** before detailed engineering:

- Visual principles, layout grid, color roles, typography, motion limits
- Localization and tone
- **Generative design prompts** (per screen or flow) for tools that produce mockups
- **Hero / landing / in-app narrative** blocks (value prop, “why us”, onboarding copy)
- Traceability: which UX rules from phase 3 each visual rule supports

### Phase 5: Engineering specifications

**Input**: Approved visual & messaging (or parallel drafts with explicit sync points)  
**Output**: `flows/pdd-[name]/05-engineering-specifications.md`

One file with **standard top-level sections** (split into linked docs only if the project is huge):

1. **Backend** — modules, domain model in tech terms, APIs, jobs, idempotency, security
2. **Frontend / clients** — platforms, navigation binding to IA, state, telemetry, error handling
3. **On-chain / infrastructure** — contracts, indexers, workers, deployment notes
4. **Cross-cutting programs** — e.g. referrals, growth, support tooling (subsections)

Non-functional requirements (performance, SLOs, observability) live here.

### Phase 6: Master plan

**Input**: Approved engineering specifications  
**Output**: `flows/pdd-[name]/06-master-plan.md`

**Program plan** (not a single-feature plan):

- Workstreams (client, server, chain, design, ops)
- Milestones and dependencies
- Environment and release strategy
- Open risks and mitigations
- Mapping of milestones to **SDD/VDD** feature directories when used

### Phase 7: Implementation

**Input**: Approved master plan  
**Output**: Working deliveries (repos, contracts, apps) + `flows/pdd-[name]/07-implementation-log.md`

Same discipline as SDD/VDD:

- Log deviations and why
- Link commits/releases to plan items
- Refresh domain or engineering docs when reality changes

---

## Canonical names for “next part” documents

When splitting drafts, use these names so the team and agents map files consistently:

| Draft habit | Canonical document / section |
|-------------|------------------------------|
| Economy / tokenomics v1 | `02-domain-specification.md` — *Economy & tokens* |
| Final mechanics / balance (tables, caps) | `02-domain-specification.md` — *Mechanics & balance* |
| Screen map, onboarding, flows | `03-product-ux-specification.md` |
| Style + GenAI prompts | `04-visual-and-messaging.md` — *Visual system & prompts* |
| Backend API & jobs | `05-engineering-specifications.md` — *Backend* |
| Client / Mini App | `05-engineering-specifications.md` — *Frontend* |
| NFT / contracts | `05-engineering-specifications.md` — *On-chain* |
| Referral / growth rules | `05-engineering-specifications.md` — *Programs* |
| Landing / hero copy | `04-visual-and-messaging.md` — *Messaging* |
| User flow diagram (image) | `03-product-ux-specification.md` or `artifacts/` + link |

---

## Directory structure

```
flows/
├── pdd.md                         # This file
├── .templates/pdd/
│   ├── _status.md
│   ├── 01-project-charter.md
│   ├── 02-domain-specification.md
│   ├── 03-product-ux-specification.md
│   ├── 04-visual-and-messaging.md
│   ├── 05-engineering-specifications.md
│   ├── 06-master-plan.md
│   └── 07-implementation-log.md
└── pdd-[project-name]/
    ├── 01-project-charter.md
    ├── 02-domain-specification.md
    ├── 03-product-ux-specification.md
    ├── 04-visual-and-messaging.md
    ├── 05-engineering-specifications.md
    ├── 06-master-plan.md
    ├── 07-implementation-log.md
    ├── _status.md
    └── artifacts/                 # Optional: diagrams, exports
```

---

## Starting a PDD flow

### New project program

```
/pdd start [project-name]
```

Creates `flows/pdd-[project-name]/` from `flows/.templates/pdd/` and opens the **charter** phase.

### Resume

```
/pdd resume [project-name]
```

Reads `_status.md` and continues from the current phase.

### Fork

```
/pdd fork [existing] [new]
```

Copies `flows/pdd-[existing]/` to `flows/pdd-[new]/`, updates `_status.md` with fork metadata.

### Status overview

```
/pdd status
```

Lists all `flows/pdd-*/` directories and summarizes phase and blockers from each `_status.md`.

---

## Phase transitions (explicit approval)

### Charter → Domain

- [ ] Vision, scope, and non-goals are clear
- [ ] MVP and success metrics agreed
- [ ] User explicitly approves: **“project charter approved”**

### Domain → Product UX

- [ ] Glossary and economic rules stable enough to design screens
- [ ] Open domain questions listed or resolved
- [ ] User explicitly approves: **“domain specification approved”**

### Product UX → Visual and messaging

- [ ] IA and critical flows covered
- [ ] User explicitly approves: **“product ux approved”**

### Visual and messaging → Engineering

- [ ] Visual principles and key copy directions set
- [ ] User explicitly approves: **“visual and messaging approved”**

### Engineering → Master plan

- [ ] Major systems and interfaces described
- [ ] NFRs captured
- [ ] User explicitly approves: **“engineering specifications approved”**

### Master plan → Implementation

- [ ] Milestones and dependencies reviewed
- [ ] SDD/VDD breakout features identified where needed
- [ ] User explicitly approves: **“master plan approved”**

---

## Status tracking

Each program directory has `_status.md` with current phase, blockers, progress checklist, and handoff notes (same spirit as `flows/sdd.md`).

---

## Relationship to SDD / VDD

| Flow | Granularity | Typical output |
|------|----------------|----------------|
| **PDD** | Whole project / product line | Charter through master plan + program implementation log |
| **SDD** | Single feature or change | Requirements → specs → plan → code |
| **VDD** | Feature with strong UI | Requirements → visual → specs → plan → code → docs |

Use PDD to define **boundaries and contracts**; spawn `sdd-[feature]` or `vdd-[feature]` for scoped delivery with the same approval discipline.

---

## Session handoff

1. Update `_status.md` (phase, blockers, next actions)
2. Note decisions that affect downstream phases
3. List open questions for the next session

---

## Anti-patterns

- **Treating PDD as a giant SDD**: If only one component changes, prefer SDD/VDD
- **Orphan features**: Engineering specs that do not trace to domain or UX
- **Skipping charter**: Domain specs without agreed scope drift quickly
- **Stale diagrams**: User journey attachments not linked from phase 3 doc
- **Silent pivots**: Changing economy or IA without updating `_status.md` and doc version

---

## Integration with CLAUDE.md

PDD follows the same principles as SDD/VDD: explicit approvals, checkpoints, resumability via `_status.md`, and traceability from implementation log back to charter.
