---
name: campaigns
description: Use when working on campaign management, campaign planning, campaign execution, creative generation, multi-channel delivery, campaign events, campaign detail page, promotion messaging, or campaign strategy in yobo-merchant. Also use when the user mentions "campaign", "creative", "promotion message", "campaign plan", "campaign detail", "campaign strategy", or "campaign tabs".
---

# Campaign Management Development Guide

Core business domain of Yobo Merchant — campaign lifecycle from planning through execution and analytics.

## Campaign System Architecture

### Extension Structure

```
yobo-merchant/src/extensions/
  campaigns/           # Core campaign CRUD, status management, scheduling
  campaign-plan/       # AI-assisted campaign planning (strategy, messaging, targeting)
  campaign-events/     # Event tracking (sent, delivered, opened, clicked, redeemed)
  creatives/           # Creative asset management (images, copy, templates)
  promotions/          # Promotion campaign types (discount, cashback, points)
  promotion-messages/  # Promotion messaging templates
  ad-studio/           # Ad design and creation tool
```

### Campaign Lifecycle
1. **Draft** — Initial creation with basic details
2. **Planning** — AI-assisted strategy, targeting, creative generation
3. **Review** — Approval workflow
4. **Scheduled** — Queued for delivery
5. **Active** — Currently running
6. **Completed** — Finished execution
7. **Archived** — Historical record

### Key Tables
- `campaigns` — Core campaign data (name, type, status, schedule, channel)
- `campaign_events` — Event tracking per campaign
- `creatives` — Generated/uploaded creative assets
- `promotions` — Promotion configurations (discount rules, limits)
- `promotion_messages` — Message templates per channel

## AI-Powered Campaign Planning

### Flow
1. Merchant provides business context (goals, budget, audience)
2. AI generates campaign strategy with recommended segments
3. AI creates creative content (copy, images via Gemini)
4. Merchant reviews and adjusts
5. Campaign scheduled for execution

### AI Integration Points
- `ai.plan` router — Strategy and plan generation
- `ai.creative` router — Image and copy generation
- `ai.analysis` router — Performance analysis
- Cadra SDK — Agent-based campaign orchestration (team UUID: `CADRA_CAMPAIGN_TEAM_UUID`)

### Image Generation
- Provider: `gemini-2.5-flash-image-preview`
- Upload: S3 presigned URL flow
- S3 bucket priority: `S3_BUCKET` → `NEXT_PUBLIC_S3_BUCKET` → `AWS_BUCKET_NAME`

## Multi-Channel Delivery

### Supported Channels
- **WhatsApp** — Via WhatsApp Cloud API + webhook receivers
- **Email** — SMTP via Nodemailer
- **Push** — Future (PWA push notifications)
- **SMS** — Future integration

### WhatsApp Integration
- Auth: `whatsapp-auth` extension handles OAuth flow
- Templates: WhatsApp-approved message templates
- Media: Image/document attachments via S3
- Webhooks: `api/webhooks/whatsapp/` receivers
- Lessons: `_context/yobo-merchant/_arch/learnings-whatsapp.md`

## Campaign Events & Analytics

### Event Types
- `sent` — Message dispatched
- `delivered` — Confirmed delivery
- `read` — Message read (WhatsApp blue ticks)
- `clicked` — CTA/link clicked
- `redeemed` — Offer redeemed
- `failed` — Delivery failure

### Analytics
- Campaign performance dashboard
- Channel comparison
- Redemption rates
- Cost per engagement
- ROI calculation

## Campaign Detail Page (GTM Design)

### Route & Layout
- List page: `src/app/(org)/campaigns/page.tsx` — card-based layout, Live/Other sections, search, kanban toggle
- Detail page: `src/app/(no-sidebar)/campaigns/[uuid]/detail/page.tsx` — full-window, no sidebar
- `(no-sidebar)` route group provides maximum screen real estate for detail/editor pages

### 6-Tab Structure
| Tab | Content | Source |
|-----|---------|--------|
| Home | Dashboard: LIVE banner, metric cards (Revenue/Redemptions/Outlets), Offers, Live Feed | `CampaignHomeView` from demo |
| Ads | Messages/promotions: PromotionsList, PromotionDetailView, CampaignForm | Original campaigns-v2 |
| Redemptions | Summary stat cards, redemption data | Campaign analytics |
| Outlets | Outlet performance data | Campaign analytics |
| Reports | CampaignAnalytics component | Existing |
| Settings | Campaign info cards (sub-tabs: Matrix, Workflow, Offers) | Demo editor views |

### Data Hook
- `useCampaignDetail` from `src/app/(demo)/hooks/use-campaign-data.ts`
- Calls: `api.campaigns.getByUuid`, `getAnalyticsByUuid`, `getOutletPerformance`, `getRedemptions`
- Returns enriched data (offers, outlets, redemptions arrays) mapping directly to component props

### Demo Migration Pattern
- Export components from `src/app/(demo)/pages/` rather than copying — single source of truth
- Demo components use `onNavigate` callback — map to `setActiveTab` or `router.push`
- Demo components use `@ts-nocheck` and custom `Icons` — use `@ts-ignore` on import in production

### Add New Campaign
- "Add New" button opens `CreateCampaignDialog` (not router.push to `/ai-planning`)
- Import from `src/extensions/campaigns/components/create-campaign-dialog.tsx`
- On success: navigate to `/campaigns/{uuid}/detail`

## Sticky Positioning in Scroll Containers

- When `<main overflow-y-auto>` is the scroll container (not window), `sticky top-{X}` is relative to the scroll container
- If scroll container starts at 64px (top nav), use `sticky top-0` — it sticks at viewport y=64 automatically
- Scroll listeners must target `main[tabindex="-1"]`, not `window`

## Key Patterns

### Campaign Router
```typescript
// Campaign procedures use orgProtectedProcedure
// Status transitions validated server-side
// Scheduling uses BullMQ delayed jobs
```

### Creative Generation
```typescript
// AI generates multiple creative options
// Each creative stored with metadata (dimensions, format, channel)
// S3 presigned upload for generated images
```

## Reference Documentation

### Campaign Specs
- Campaign V2: `_context/yobo-merchant/_specs/p8-campaign-v2/`
- AI plan generation: `_context/yobo-merchant/_specs/p12-plan-generation/`
- Feature doc: `_context/yobo-merchant/_wiki/feature-campaigns.md`

### Related Features
- WhatsApp: `_context/yobo-merchant/_arch/learnings-whatsapp.md`
- Segments: `_context/yobo-merchant/_wiki/feature-segments.md`
- Creatives: `_context/yobo-merchant/_wiki/feature-whatsapp-creative-status-optimization.md`
