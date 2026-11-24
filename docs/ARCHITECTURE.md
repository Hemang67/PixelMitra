# PixelMitra Architecture

## Fixed product decisions
- API-only AI using user-owned OpenAI and Gemini credentials.
- Automatic routing/fallback only between connected, eligible API providers.
- No local AI runtime, bundled model, model downloader or silent local fallback.
- Basic non-AI photo/video editing remains available offline.

## Layers
Flutter features -> AI Request Coordinator -> Capability Registry -> Provider Router -> OpenAI/Gemini adapters.

Credential storage is a separate service. Provider configuration must never contain raw credentials.

## Failover
Fallback is limited to eligible connected providers and safe retryable failures. Do not blindly retry ambiguous timeouts because the provider may already have processed and billed the request. Authentication, quota, billing, safety, invalid-input and user-cancel errors are not ordinary fallback conditions.

## Media privacy
Upload only media explicitly selected for an AI operation, after clear disclosure and consent. Keep originals unchanged and save outputs locally by default.
