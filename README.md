<div align="center">

<img src="assets/ic/spottr_icon.png" alt="Spottr Logo" width="100" style="border-radius: 22px;" />

# Spottr

**A personal workout tracking app built with Flutter.**  
Plan your training, track your sets, and review your progress — all offline, all on your device.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![BLoC](https://img.shields.io/badge/State-BLoC-FF6B35?logo=dart)](https://bloclibrary.dev)
[![Hive](https://img.shields.io/badge/Storage-Hive-yellow)](https://pub.dev/packages/hive)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](#)

</div>

---

## Overview

Spottr is a fully offline workout companion app. Users can build structured training plans, run live workout sessions with real-time rest timers, and review their history and weekly volume — no account, no internet, no data sent anywhere.

The project was built as a personal deep-dive into Flutter architecture, state management, and local-first data design.

---

## Features

### 🗂 Workout Plans
- Create multi-day training plans (Push/Pull/Legs, PPL, custom splits, etc.)
- Organise exercises per day with target sets, reps, and weight
- Set one plan as **active** — it drives the home screen and workout sessions

### 🏋️ Live Workout Sessions
- Start a session from your active plan's day
- Log actual sets with weight and reps inline
- **Previous best** is shown per exercise — tap it to auto-fill the current sets
- **Live volume tracking** per exercise updates as you log sets
- **Wakelock** keeps the screen on for the duration of the session

### ⏱ Rest Timer
- Automatically starts after completing each set
- Configurable rest duration (30s – custom) per your preference
- AppBar displays a live rest countdown or workout elapsed time
- Visual colour shift distinguishes rest mode from active mode

### 📊 History & Analytics
- Every completed session is saved with full set logs
- **Weekly summary** on the home screen: workouts completed and total volume lifted
- Full history list with per-session breakdown

### ⚙️ Settings & Customisation
- **Light / Dark / System** theme support
- Profile & appearance preferences
- Workout preferences (rest time, screen-awake toggle)
- **Backup & Restore** — export your full data as a `.zip`, restore on any device

---

## Tech Stack

| Layer | Technology |
|---|---|
| **UI Framework** | Flutter (Material 3) |
| **State Management** | flutter_bloc (BLoC pattern) |
| **Local Database** | Hive (NoSQL, fully offline) |
| **Dependency Injection** | get_it |
| **Navigation** | Flutter Navigator 2 (page routes) |
| **Background Tasks** | Dart isolate-free timers via BLoC |
| **Backup / Restore** | archive + share_plus + file_picker |
| **Audio** | audioplayers |
| **Fonts** | Google Fonts |
| **Splash Screen** | flutter_native_splash |

---

## Architecture

The project follows **Clean Architecture** principles with a clear separation across three layers:

```
lib/
├── core/               # Theme, colours, DI setup
│   ├── theme/
│   └── di/
├── data/               # Hive models, local DB service, repositories impl
│   ├── models/
│   ├── datasources/
│   └── repositories/
├── domain/             # Entities, abstract repository contracts
│   ├── entities/
│   └── repositories/
└── presentation/       # UI — screens, widgets, BLoCs
    ├── blocs/
    │   ├── plans/
    │   ├── workout/
    │   ├── timer/
    │   ├── history/
    │   └── settings/
    ├── screens/
    └── widgets/
```

Each feature has its own BLoC — `PlansBloc`, `WorkoutBloc`, `TimerBloc`, `HistoryBloc`, `SettingsBloc` — keeping state isolated and testable.

---

## Getting Started

**Prerequisites:** Flutter 3.x, Dart 3.x

```bash
# Clone the repo
git clone https://github.com/hudaif99/spottr.git
cd spottr

# Install dependencies
flutter pub get

# Run on a connected device
flutter run
```

> The app requires no API keys, accounts, or internet connection. Everything runs locally on-device via Hive.

---

## Design System

Spottr uses a custom design system defined in `lib/core/theme/`:

- **Primary accent:** Electric Lime `#B7FF00` (dark) / Olive `#6B9900` (light)
- **Secondary accent:** Mint `#00FFA3` / Teal `#00AA6E`
- **Background:** `#111111` (dark) / `#F2F2F7` (light)
- **Components:** `SpottrButton`, `SpottrCard`, `SpottrTextField` — reusable, themeable widgets

Both light and dark themes are fully supported, including a system-follow mode.

---

## Backup & Restore

Spottr's data lives in a Hive database on-device. The backup flow:

1. **Export** — packages the Hive database files into a `.zip` using the `archive` package, then shares it via the native share sheet
2. **Restore** — picks a `.zip` via the file picker, extracts, and replaces the local database; all BLoCs reload automatically

---

<div align="center">

Built by **Hudaif** · Flutter & Dart

</div>
