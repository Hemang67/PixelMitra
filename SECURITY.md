# Security Policy

Report vulnerabilities privately through GitHub Security Advisories. Do not publish exploitable details in public issues.

## Credential handling
- Never commit OpenAI/Gemini API keys or Android signing credentials.
- Store user API keys with Android Keystore-backed secure storage.
- Redact credentials and authorization headers from logs and crash reports.
- Direct-device BYOK has residual risk on rooted or compromised devices; disclose it to users.
- Upload only user-selected media after clear consent.
- Do not send provider credentials to a PixelMitra-owned server.

## Release integrity
Release APKs must use the project's controlled signing identity. Publish SHA-256 checksums and verify APK signing identity before installation.
