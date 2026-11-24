from pathlib import Path
import re

app_dir = Path("mobile/android/app")
groovy = app_dir / "build.gradle"
kotlin = app_dir / "build.gradle.kts"
target = kotlin if kotlin.exists() else groovy if groovy.exists() else None
if target is None:
    raise SystemExit("Flutter Android app Gradle file not found")

source = target.read_text(encoding="utf-8")
is_kotlin = target.suffix == ".kts"

prelude = """
import java.util.Properties
import java.io.FileInputStream

def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
""" if not is_kotlin else """
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}
"""

if "keystoreProperties" not in source:
    source = prelude + "\n" + source

def block_bounds(text, pattern):
    match = re.search(pattern, text)
    if not match:
        return None
    opening = text.find("{", match.start(), match.end() + 1)
    if opening < 0:
        opening = text.find("{", match.end())
    if opening < 0:
        return None
    depth = 0
    for i in range(opening, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return opening, i
    raise SystemExit(f"Unbalanced Gradle block for {pattern}")

if is_kotlin:
    config = """
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
"""
    signing_line = 'signingConfig = signingConfigs.getByName("release")'
else:
    config = """
        release {
            keyAlias keystoreProperties["keyAlias"]
            keyPassword keystoreProperties["keyPassword"]
            storeFile file(keystoreProperties["storeFile"])
            storePassword keystoreProperties["storePassword"]
        }
"""
    signing_line = "signingConfig signingConfigs.release"

android = block_bounds(source, r"\bandroid\s*\{")
if not android:
    raise SystemExit("Could not locate android block")
signing = block_bounds(source, r"\bsigningConfigs\s*\{")
if signing:
    inner = source[signing[0] + 1:signing[1]]
    if "release" not in inner:
        source = source[:signing[1]] + config + source[signing[1]:]
else:
    # Insert a new signingConfigs block at the start of android.
    source = source[:android[0] + 1] + "\n    signingConfigs {\n" + config + "    }\n" + source[android[0] + 1:]

build_types = block_bounds(source, r"\bbuildTypes\s*\{")
if not build_types:
    raise SystemExit("Could not locate buildTypes block")
release = block_bounds(source[build_types[0] + 1:build_types[1]], r"\brelease\s*\{")
if release:
    start = build_types[0] + 1 + release[0]
    end = build_types[0] + 1 + release[1]
    body = source[start + 1:end]
    body = re.sub(r"signingConfig\s*(?:=\s*)?(?:signingConfigs\.debug|signingConfigs\.getByName\(\"debug\"\))", signing_line, body)
    if "signingConfig" not in body:
        body = "\n            " + signing_line + body
    source = source[:start + 1] + body + source[end:]
else:
    addition = '\n        release { ' + signing_line + ' }\n'
    source = source[:build_types[1]] + addition + source[build_types[1]:]

target.write_text(source, encoding="utf-8")
print(f"Configured release signing in {target}")
