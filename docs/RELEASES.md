# Android Release Process

Configure repository Actions secrets:
- ANDROID_KEYSTORE_BASE64
- ANDROID_KEYSTORE_PASSWORD
- ANDROID_KEY_ALIAS
- ANDROID_KEY_PASSWORD

Increment the app version and Android versionCode in `mobile/pubspec.yaml`, then push a tag such as `v1.0.0`. Review the Actions run and verify APK signature and SHA-256 asset.

Never replace or lose the signing key. Android updates must use the same signing certificate and a higher versionCode. Android requires the user to approve installation of downloaded APK updates.
