# Building MoonGoons: Syndicate Rising

## Local editor

1. Install Godot 4.3 or newer.
2. Clone this repository.
3. Open `project.godot`.
4. Press F6/F5.

## Verification

Linux/macOS/Git Bash:

```bash
GODOT_BIN=/path/to/godot ./compile_and_test.sh
```

## Browser

Install Godot export templates, then:

```bash
godot --headless --path . --export-release Web exports/web/index.html
```

## Android

Install OpenJDK 17, Android SDK platform 34, build tools 34.0.0, and Godot Android export templates. Then:

```bash
godot --headless --path . --export-debug Android exports/android/MoonGoons-Syndicate-Rising-debug.apk
```

GitHub Actions workflows are included for verification, browser artifact export, and Android APK artifact export.
