# Engineering specifications: [PROJECT_NAME]

> Version: 0.1  
> Status: DRAFT | REVIEW | APPROVED  
> Last updated: [DATE]

## Purpose

Technical design for **all major surfaces** of the program. Keep sections; split into separate files only if the document becomes unmanageable (then link from here).

---

## 1. System context

[Context diagram or bullet list: clients, backend, chain, third parties.]

---

## 2. Backend

### 2.1 Modules and responsibilities

| Module | Responsibility |
|--------|----------------|
| | |

### 2.2 Domain model (technical)

[Entities, IDs, state machines.]

### 2.3 APIs (high level)

| Area | Method | Path | Notes |
|------|--------|------|-------|
| | | | |

### 2.4 Background jobs and schedulers

| Job | Schedule | Idempotency |
|-----|----------|-------------|
| | | |

### 2.5 Security, auth, audit

[Auth flows, secrets handling, audit events.]

---

## 3. Frontend / clients

### 3.1 Targets

[e.g. Telegram Mini App, web admin, mobile native]

### 3.2 Binding to IA

[Map major routes to screens from doc 03.]

### 3.3 Telemetry and client-side integrity

[Events, batching, rate limits.]

### 3.4 Error and offline behavior

---

## 4. On-chain and infrastructure

### 4.1 Contracts and roles

| Contract | Purpose | Key functions / events |
|----------|---------|-------------------------|
| | | |

### 4.2 Indexers and workers

### 4.3 Deployment and environments

---

## 5. Cross-cutting programs

### 5.1 [e.g. Referral / growth]

[Rules, entities, APIs.]

### 5.2 [e.g. Support / admin]

---

## 6. Non-functional requirements

| Category | Requirement |
|----------|-------------|
| Performance | |
| Availability | |
| Observability | |
| Compliance | |

---

## 7. SDD/VDD breakout

| Topic | Delegated to |
|-------|----------------|
| [Feature] | `flows/sdd-...` or `flows/vdd-...` |

---

## Approvals

**Approval phrase to advance**: “engineering specifications approved”
