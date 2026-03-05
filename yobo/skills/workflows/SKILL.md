---
name: workflows
description: Use when working on workflow automation, n8n integration, workflow builder, BullMQ background jobs, worker processes, queue monitoring, or execution tracking in yobo-merchant. Also use when the user mentions "workflow", "n8n", "automation", "queue", "job", "worker", or "background task".
---

# Workflow & Automation Development Guide

Automation layer of Yobo Merchant — n8n workflow integration, background jobs, and execution tracking.

## Workflow System Architecture

### Extension Structure

```
yobo-merchant/src/extensions/
  workflow/              # Workflow builder and management
  execution/             # Workflow execution tracking
  queue-monitor/         # BullMQ job monitoring dashboard
```

### Backend Services

```
yobo-merchant/src/server/
  workflow-api/          # n8n integration layer
  jobs/                  # BullMQ job definitions
    message-history-sync.job.ts   # Sync WhatsApp message history
    segmentCalculation.job.ts     # Compute customer segments
  workers/               # Worker process implementations
```

## n8n Workflow Integration

### Architecture
- n8n runs as separate service (Docker or hosted)
- Yobo acts as trigger source and data provider
- Workflows defined in n8n visual editor
- Execution results tracked in Yobo database

### Configuration
- `N8N_*` environment variables for connection
- Webhook endpoints for n8n triggers
- API endpoints for n8n to fetch/push data

### Common Workflow Patterns
- **Campaign execution** — Trigger on schedule, process customer list, send messages
- **Customer journey** — Event-driven multi-step engagement flows
- **Data sync** — Periodic sync with external systems (POS, CRM)
- **Notifications** — Alert triggers based on business rules

### Key Files
- Workflow router: `src/extensions/workflow/router.ts`
- Execution tracker: `src/extensions/execution/`
- Workflow API: `src/server/workflow-api/`
- Blueprint: `_context/yobo-merchant/_wiki/blueprint-workflows.md`

## BullMQ Background Jobs

### Job Queue Architecture
- **Redis**: Job queue storage and pub/sub
- **BullMQ**: Job processing framework
- **Workers**: Separate process for job execution (`pnpm worker`)
- **Monitoring**: Queue monitor extension for dashboard visibility

### Active Jobs

| Job | Purpose | Schedule |
|-----|---------|----------|
| `segmentCalculation` | Recompute customer segments | Cron + on-demand |
| `message-history-sync` | Sync WhatsApp message history | Periodic |

### Job Pattern
```typescript
// Job definition
import { Queue, Worker } from 'bullmq'

const queue = new Queue('segment-calculation', { connection: redis })

// Add job
await queue.add('calculate', { orgId, segmentId }, {
  attempts: 3,
  backoff: { type: 'exponential', delay: 1000 },
  removeOnComplete: 100,
  removeOnFail: 50,
})

// Worker processes job
const worker = new Worker('segment-calculation', async (job) => {
  const { orgId, segmentId } = job.data
  // Process in batches...
}, { connection: redis })
```

### Worker Deployment
- Development: `pnpm worker` (runs in same process)
- Production: Separate container via `Dockerfile.worker`
- Deploy script: `deploy-worker-v2.sh`
- Docker compose: `docker-compose.worker.yml`

## Queue Monitoring

### Dashboard Features
- Active/waiting/completed/failed job counts
- Job details and progress tracking
- Manual retry for failed jobs
- Queue pause/resume controls

### Key Files
- Extension: `src/extensions/queue-monitor/`
- Dashboard page: `src/app/(org)/queue-monitor/`

## Workflow Execution Tracking

### Execution States
- `pending` — Queued for execution
- `running` — Currently processing
- `completed` — Successfully finished
- `failed` — Error during execution
- `cancelled` — Manually cancelled

### Tracking Features
- Step-by-step execution logs
- Error details and stack traces
- Retry capability for failed steps
- Performance metrics (duration, throughput)

## Reference Documentation

- Workflow specs: `_context/yobo-merchant/_specs/p7-workflow/`
- Workflow blueprint: `_context/yobo-merchant/_wiki/blueprint-workflows.md`
- Execution flow: `_context/yobo-merchant/_wiki/feature-workflow-execution-flow-detailed.md`
- Wait node states: `_context/yobo-merchant/_wiki/diagram-wait-node-state.md`
- AI API & workers: `_context/yobo-merchant/_wiki/feature-ai-api-and-workers.md`
