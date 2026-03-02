---
name: crm-messaging
description: Use when working on CRM messaging, inbox, conversations, WhatsApp integration, email channels, messaging service, or platform SDK client. Also use when the user mentions "messaging", "inbox", "conversations", "WhatsApp", or "channels".
---

# CRM Messaging Integration

The CRM integrates with a standalone messaging microservice via the `@jetdevs/messaging` SDK.

## Architecture

```
Messaging Service (standalone)    CRM (consumer)
  Fastify + BullMQ + Redis          Next.js + tRPC
  PostgreSQL (own DB)                @jetdevs/messaging SDK
  Channel adapters                   Inbox UI
  Webhooks + IMAP                    tRPC proxy routes
  SSE/WebSocket                      Settings UI
  Message delivery                   Permission gating
```

**Key principle:** CRM is a consumer, NOT the owner of messaging logic.

## Service Ownership

| Owned by Service | Owned by CRM |
|-------------------|-------------|
| Channel adapters (WhatsApp, email, Telegram, etc.) | Inbox UI components |
| Webhook handlers | tRPC proxy routes to service |
| IMAP email sync | Settings/configuration UI |
| Message delivery & queuing | Permission gating |
| Database tables for conversations/messages | Conversation assignment UI |
| SSE/WebSocket real-time events | Contact linking |

## CRM Integration Files

```
crm/src/extensions/messaging/
  platform-sdk-client.ts    # @jetdevs/messaging SDK client
  sdk-client.ts             # Deprecated - use platform-sdk-client
  router.ts                 # tRPC proxy routes
  routers/
    channel-router.ts       # Channel management
    observability-router.ts # Metrics and monitoring
    platform-router.ts      # Platform operations
    realtime-router.ts      # SSE/WebSocket connections
```

## SDK Client Usage

```typescript
import { createMessagingClient } from '@jetdevs/messaging'

const client = createMessagingClient({
  baseUrl: process.env.MESSAGING_SERVICE_URL,
  apiKey: process.env.MESSAGING_API_KEY,
})

// List conversations
const conversations = await client.conversations.list({ orgId })

// Send message
await client.messages.send({
  conversationId,
  content: 'Hello',
  channel: 'whatsapp',
})
```

## Reference Documentation

### CRM Messaging (consumer side)
- Feature: `_context/yobo-crm/messaging/feature.md`
- Specs: `_context/yobo-crm/messaging/specs.md`
- PRD: `_context/yobo-crm/messaging/prd.md`
- Implementation: `_context/yobo-crm/messaging/implementation.md`
- Change log: `_context/yobo-crm/messaging/log.md`
- Feedback: `_context/yobo-crm/messaging/feedback.md`

### Messaging Service (standalone microservice)
- Feature: `_context/yobo-crm/messaging-service/feature.md`
- Specs: `_context/yobo-crm/messaging-service/specs.md`
- PRD: `_context/yobo-crm/messaging-service/prd.md`
- Implementation: `_context/yobo-crm/messaging-service/implementation.md`
- Change log: `_context/yobo-crm/messaging-service/log.md`
