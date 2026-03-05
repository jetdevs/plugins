---
name: customers
description: Use when working on customer management, customer segmentation, segment calculation, customer deduplication, loyalty programs, credit system, merchant-customer relationships, or customer migration in yobo-merchant. Also use when the user mentions "customer", "segment", "loyalty", "credits", "dedup", or "merge".
---

# Customer Management Development Guide

Core data domain of Yobo Merchant — customer lifecycle, segmentation, loyalty, and credits.

## Customer System Architecture

### Extension Structure

```
yobo-merchant/src/extensions/
  customers/             # Global customer database (org-scoped)
  customer-migration/    # Dual-write architecture migration
  segments/              # Customer segmentation engine
  default-segments/      # Pre-built behavioral segments
  loyalty/               # Loyalty program management
  credits/               # Customer credit/prepaid balance
  tags/                  # Cross-entity tagging
```

### Customer Data Model
- **Global customers** — Shared customer pool across modules
- **Merchant-customers** — Org-specific customer relationships
- **Customer attributes** — Extensible metadata per customer
- **Dual-write migration** — Transitioning from embedded to global customer architecture

### Key Tables
- `customers` — Master customer records (name, phone, email)
- `merchant_customers` — Org-to-customer mapping with merchant-specific data
- `customer_attributes` — Key-value metadata storage
- `segments` — Segment definitions (rules, filters)
- `loyalty_programs` — Program configurations
- `credits` — Credit balances and transactions

## Customer Segmentation Engine

### Segment Types
- **Static** — Manually curated customer lists
- **Dynamic** — Rule-based, auto-calculated
- **Default** — Pre-built behavioral segments (new, active, at-risk, churned)

### Segment Calculation
- **Job**: BullMQ background job (`segmentCalculation.job.ts`)
- **Triggers**: Scheduled (cron) or on-demand
- **Performance**: Batch processing for large datasets
- **Service**: `src/server/services/` segment calculation services

### Segment Rules
```typescript
// Rules compose with AND/OR logic
// Supported operators: equals, contains, gt, lt, between, in, not_in
// Fields: transaction history, last visit, total spend, loyalty tier, tags
```

## Customer Deduplication

### Service Architecture
- `deduplication-engine.service.ts` — Core matching engine
- `customer-merge.service.ts` — Record merging logic
- `conflict-detection.service.ts` — Conflict resolution

### Matching Strategy
- Phone number normalization + exact match
- Email normalization + exact match
- Fuzzy name matching (configurable threshold)
- Custom field matching

### Merge Rules
- Master record selection (most complete profile wins)
- Transaction history preserved from both records
- Loyalty points aggregated
- Audit trail maintained

## Loyalty Programs

### Program Types
- **Points-based** — Earn/redeem points per transaction
- **Tier-based** — Status levels with benefits
- **Stamp cards** — Digital stamp collection
- **Cashback** — Percentage-based returns

### Key Features
- Configurable earn rules (per-item, per-transaction, bonus events)
- Redemption rules (minimum points, conversion rates)
- Tier progression (automatic upgrade/downgrade)
- Expiration policies

## Credit System

### Architecture
- **Microservice**: Separate credit API (`src/server/credit-api/`)
- **Balance tracking**: Real-time credit balance per customer
- **Transaction types**: Top-up, redemption, adjustment, expiry, refund
- **Audit**: Full transaction history with timestamps

### Key Endpoints
- Credit balance inquiry
- Credit top-up (manual/auto)
- Credit redemption at POS
- Transaction history

### Specs
- Credit specs: `_context/yobo-merchant/_specs/p10-credits/`
- Feature doc: `_context/yobo-merchant/_wiki/feature-credits.md`

## Customer Analysis (AI-Powered)

### AI Integration
- `ai.analysis` router — Customer behavior analysis
- Segment recommendations based on transaction patterns
- Churn prediction and at-risk alerts
- Lifetime value estimation

## Key Patterns

### Customer Repository
```typescript
// Always filter by orgId (RLS enforced)
// Eager load merchant_customers for org-specific data
// Use withPrivilegedDb for cross-org dedup operations
```

### Segment Calculation Job
```typescript
// BullMQ job with retry logic
// Process customers in batches (1000 per batch)
// Update segment membership atomically
// Emit completion event for dashboard refresh
```

## Reference Documentation

- Global customer: `_context/yobo-merchant/_wiki/feature-global-customer.md`
- Segments: `_context/yobo-merchant/_wiki/feature-segments.md`
- Credits: `_context/yobo-merchant/_wiki/feature-credits.md`
- Credits specs: `_context/yobo-merchant/_specs/p10-credits/`
- Segment explorer: `_context/yobo-merchant/_specs/p15-segment-explorer+product-catalog/`
