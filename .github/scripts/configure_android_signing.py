from pathlib import Path
import re
import sys

app_dir = Path("mobile/android/app")
groovy = app_dir / "build.gradle"
kotlin = app_dir / "build.gradle.kts"
target = kotlin if kotlin.exists() else groovy if groovy.exists() else None
if target is None:
    raise SystemExit("Flutter Android app Gradle file not found")

text = target.read_text(encoding="utf-8")
if "signingConfigs" in text and "release" in text:
    print("Signing configuration already appears to exist; inspect generated Gradle file.")
    sys.exit(0)

if target.suffix == ".kts":
    prelude = '''
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}
'''
    if "android {" not in text:
        raise SystemExit("Could not locate android block")
    text = prelude + text
    signing = '''
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
'''
    text = text.replace("android {", "android {\n" + signing, 1)
    # Replace Flutter template's debug signing for release, or add a release block.
    if re.search(r'buildTypes\s*\{', text):
        if 'getByName("release")' in text:
            text = re.sub(r'getByName\("release"\)\s*\{', 'getByName("release") {\n        signingConfig = signingConfigs.getByName("release")', text, count=1)
        elif 'create("release")' in text:
            pass
        else:
            text = text.replace("buildTypes {", 'buildTypes {\n        getByName("release") { signingConfig = signingConfigs.getByName("release") }', 1)
    else:
        text += '\nbuildTypes { getByName("release") { signingConfig = signingConfigs.getByName("release") } }\n'
else:
    prelude = '''
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
'''
    text = prelude + text
    signing = '''
    signingConfigs {
        release {
            keyAlias keystoreProperties["keyAlias"]
            keyPassword keystoreProperties["keyPassword"]
            storeFile file(keystoreProperties["storeFile"])
            storePassword keystoreProperties["storePassword"]
        }
    }
'''
    text = text.replace("android {", "android {\n" + signing, 1)
    if re.search(r'buildTypes\s*\{', text):
        if re.search(r'release\s*\{', text):
            text = re.sub(r'(release\s*\{)', r'\1\n            signingConfig signingConfigs.release', text, count=1)
        else:
            text = text.replace("buildTypes {", "buildTypes {\n        release { signingConfig signingConfigs.release }", 1)
    else:
        text += "\nbuildTypes { release { signingConfig signingConfigs.release } }\n"

target.write_text(text, encoding="utf-8")
print(f"Configured release signing in {target}")
