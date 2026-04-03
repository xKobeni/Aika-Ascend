# Aika Ascend

Aika Ascend is a gamified fitness app built with Flutter.

## Features

- Daily quests and progression system
- Achievement and title unlocks
- Activity tracking (steps, movement state, distance, active time)
- Challenges and progress stats
- Local-first data storage with Hive

## Stack

- Flutter (Dart)
- Hive
- geolocator, pedometer, permission_handler
- fl_chart

## Quick Start

1. Install dependencies

```bash
flutter pub get
```

2. Generate model files (when needed)

```bash
dart run build_runner build --delete-conflicting-outputs
```

3. Run the app

```bash
flutter run
```

## Common Commands

```bash
flutter analyze
flutter test
flutter clean
```

## Notes

- Data is stored locally using Hive.
- App content is loaded from `assets/data/`.
- Activity tracking works best on Android devices with required permissions enabled.

## Landing Page (Vercel)

A simple web landing page is available in `landing-page/`.

To deploy it on Vercel:

1. Import this repository in Vercel.
2. In Project Settings, set Root Directory to `landing-page`.
3. Deploy (no build command required for this static site).

If you use Vercel CLI:

```bash
cd landing-page
vercel
```

## License

No license file is currently included.
