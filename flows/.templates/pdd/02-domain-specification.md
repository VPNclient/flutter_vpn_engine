# Domain specification: [PROJECT_NAME]

> Version: 0.1  
> Status: DRAFT | REVIEW | APPROVED  
> Last updated: [DATE]

## Purpose

Single source of truth for **business and game domain**: entities, economy, progression rules, and integrity constraints. Subsections can evolve as v1, v2, … but stay in this document (or clearly linked addenda under `artifacts/`).

---

## 1. Glossary

| Term | Definition |
|------|------------|
| [Term] | [Definition] |

---

## 2. Core entities and relationships

[Diagram or bullet model: who owns what, lifecycles, cardinalities.]

---

## 3. Economy and tokens (if applicable)

### 3.1 Asset / currency roles

| Instrument | Layer | Transferable | Primary uses |
|------------|-------|--------------|--------------|
| [Name] | on-chain / off-chain | yes / no | |

### 3.2 Flows

- **Inflows**: [how value enters]
- **Outflows / sinks**: [where value leaves circulation]
- **Fees and commissions**: [table]

### 3.3 Withdrawal / conversion rules

[Rules that protect the economy, caps, eligibility, cooldowns.]

---

## 4. Mechanics and balance

### 4.1 Progression or tiers

[Tables: levels, limits, bonuses, costs.]

### 4.2 Key formulas

[Scoring, rewards, splits — keep formulas explicit.]

### 4.3 Edge cases and invariants

[What must never happen; idempotency expectations at domain level.]

---

## 5. Domain-level integrity and abuse prevention

| Threat | Domain rule or detection |
|--------|--------------------------|
| [Threat] | [Rule] |

---

## 6. Traceability to charter

| Charter goal | Supported by (section) |
|--------------|------------------------|
| | |

---

## Approvals

**Approval phrase to advance**: “domain specification approved”
