# PixelMitra 🎨
### Your Creative Friend

PixelMitra is a free, open-source Android photo and video editing application built with Flutter.

## Product architecture
- AI processing: API-only Bring Your Own Key (BYOK).
- Providers: OpenAI API and Google Gemini API.
- Routing: capability-based automatic selection and controlled API-to-API fallback.
- Local AI: no bundled models, model downloads, local AI runtimes or silent local fallback.
- Offline: basic non-AI photo/video editing is designed to remain available offline.
- No advertisements, subscriptions, in-app purchases or mandatory registration.
- Users pay their AI providers directly for API usage.

## Repository layout
- `mobile/`: Flutter Android application.
- `docs/`: architecture, security and release documentation.
- `.github/workflows/`: CI and Android release automation.

## Development
Install Flutter stable and Android SDK:
```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

## Android release signing
Configure GitHub Actions secrets:
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Never commit signing keys, key.properties, API keys or passwords. Every published update must use the same signing identity and a higher Android versionCode.

## Releases
A semantic version tag such as `v1.0.0` triggers the Android release workflow. Releases publish an APK and SHA-256 checksum. The in-app updater must verify both the checksum and Android signing identity; Android still requires user approval to install an APK update.

## Security
See [SECURITY.md](SECURITY.md). Never commit provider API keys, signing files, private media or credentials.

## License
MIT. See [LICENSE](LICENSE).
