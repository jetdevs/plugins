---
name: ai-copilot
description: Use when working on AI copilot features, Cadra SDK integration, AI agent orchestration, AI-powered campaign planning, creative generation, customer analysis, AI API service, or AI prompt management in yobo-merchant. Also use when the user mentions "copilot", "ai agent", "cadra", "ai planning", "ai analysis", "gemini", or "ai-api".
---

# AI Copilot & Agent Integration Guide

AI layer of Yobo Merchant — copilot features, Cadra SDK integration, and the external AI API service.

## AI Architecture Overview

### Three Integration Layers

1. **AI API Service** (`yobo-merchant/ai-api/`) — Standalone Fastify microservice for AI operations
2. **AI Extension** (`src/extensions/ai/`) — tRPC router proxying to AI API and Cadra
3. **Cadra SDK** (`@cadraos/sdk`) — Agent orchestration for complex multi-step tasks

### Extension Structure

```
yobo-merchant/src/extensions/
  ai/                    # Core AI integration router
  campaign-plan/         # AI-assisted campaign planning
  copilot-demo/          # Demo copilot experience
  ai-planning/           # AI-powered planning tools
  ai-prompts-proxy/      # AI prompt management
```

## AI API Service (Standalone)

### Architecture
- **Framework**: Fastify
- **Purpose**: AI inference, embeddings, image generation
- **Deployment**: Separate Docker container
- **Auth**: Token exchange with main app

### Commands
```bash
pnpm ai-api:dev           # Start AI API dev server
pnpm ai-api:build         # Build AI API
pnpm ai-api:docker        # Run in Docker
```

### Key Capabilities
- LLM inference (OpenAI, Google Gemini)
- Image generation (Gemini `gemini-2.5-flash-image-preview`)
- Customer analysis and insights
- Campaign strategy generation
- Content optimization

## Cadra SDK Integration

### Configuration
```env
CADRA_URL=https://your-cadra-instance.com
CADRA_API_KEY=cdr_prod_xxx
CADRA_CAMPAIGN_TEAM_UUID=xxx-xxx-xxx
```

### Integration Pattern
- Cadra agents handle complex multi-step tasks (campaign strategy, creative generation)
- SDK provides chat UI components for copilot experience
- SSE streaming for real-time execution updates
- Agent team orchestration for campaign workflows

### Cadra Agents for Yobo
| Agent | Purpose |
|-------|---------|
| Campaign Strategist | Strategic campaign planning and optimization |
| Creative Writer | Copy and messaging generation |
| Image Designer | Creative image generation |
| Business Analyzer | Market analysis and business insights |

### Key Files
- Agent migration: `_context/yobo-merchant/agent-migration/`
- AI SaaS integration: `_context/yobo-merchant/ai-saas-integration/`
- SDK integration specs: `_context/yobo-merchant/_specs/p18-sdk/`

## AI Extension Router

### Available Procedures
```typescript
ai.session      // Session management and auth token exchange
ai.analysis     // Customer/market analysis endpoints
ai.plan         // Campaign planning and strategy generation
ai.creative     // Creative content generation (images, copy)
ai.campaign     // AI-assisted campaign management
ai.agent        // Agent coordination and execution
ai.optimization // Performance optimization suggestions
```

### Auth Flow
1. Frontend requests AI session token
2. Backend exchanges auth credentials with AI API
3. Token used for subsequent AI requests
4. Session expires and auto-refreshes

## AI-Powered Features

### Campaign Planning
1. Merchant inputs business goals, budget, target audience
2. AI generates multi-channel campaign strategy
3. AI suggests customer segments to target
4. AI creates messaging copy and creative briefs
5. Merchant reviews, adjusts, and launches

### Creative Generation
- **Image Generation**: Gemini model creates campaign visuals
- **Copy Generation**: AI writes promotional messages per channel
- **A/B Variants**: Multiple creative options for testing
- **Brand Alignment**: Uses brand profile for consistency

### Customer Analysis
- **Behavioral Insights**: Transaction pattern analysis
- **Churn Prediction**: At-risk customer identification
- **Segment Recommendations**: AI-suggested customer groupings
- **LTV Estimation**: Customer lifetime value prediction

### Copilot Experience
- Interactive chat interface for merchant assistance
- Context-aware suggestions based on business data
- Multi-step task orchestration via Cadra agents
- Real-time streaming responses

## AI Prompt Management

### Architecture
- Centralized prompt templates (`ai-prompts-proxy` extension)
- Version-controlled prompts
- A/B testing support for prompt variants
- Performance tracking per prompt version

## Key Patterns

### AI Router
```typescript
// AI procedures use orgProtectedProcedure
// External AI calls wrapped with error handling
// Streaming responses use SSE
// Token management via session extension
```

### Image Upload Flow
```typescript
// 1. Generate image via Gemini
// 2. Get S3 presigned upload URL
// 3. Upload generated image to S3
// 4. Store S3 URL in creative record
// S3 bucket priority: S3_BUCKET → NEXT_PUBLIC_S3_BUCKET → AWS_BUCKET_NAME
```

## Reference Documentation

- AI copilot: `_context/yobo-merchant/_specs/p17-ai-copliot/`
- AI SaaS integration: `_context/yobo-merchant/ai-saas-integration/`
- Agent migration: `_context/yobo-merchant/agent-migration/`
- Agents phase: `_context/yobo-merchant/_specs/p15-agents/`
- SDK integration: `_context/yobo-merchant/_specs/p18-sdk/`
- AI API & workers: `_context/yobo-merchant/_wiki/feature-ai-api-and-workers.md`
- AI providers: `_context/yobo-merchant/_wiki/feature-ai-providers.md`
- Inferencing: `_context/yobo-merchant/_wiki/feature-inferencing.md`
- Prompts: `_context/yobo-merchant/_wiki/feature-prompts.md`
