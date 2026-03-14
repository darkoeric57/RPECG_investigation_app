# RPECG Investigation App

A premium, offline-first Flutter application designed for field investigators to manage meter installations and technical investigations efficiently.

## 🚀 Key Features

- **Offline-First Resilience**: Full local persistence using Hive. Investigators can work without an internet connection.
- **Form Resiliency**: Multi-step investigation form with automatic draft persistence. Never lose progress during long-standing field work.
- **Smart Search & Filters**: Advanced filtering by status (Pending, Synced, Flagged) and real-time search across 15+ data fields.
- **Native Integration**: 
  - Precise GPS coordinate fetching.
  - Camera integration for high-quality meter documentation.
  - Simulated QR scanning for rapid meter ID entry.
- **Export & Reporting**: Generate bulk CSV reports or share individual meter records using native device sharing.
- **Dark Mode Support**: Seamless transition between light and dark themes for night-time field operations.
- **Diagnostic Tools**: Built-in "Clear Cache" tool for easier debugging and data management.

## 🛠️ Technical Stack

- **Framework**: [Flutter](https://flutter.dev) (UI)
- **State Management**: [Riverpod](https://riverpod.dev) (Clean, testable status management)
- **Local Database**: [Hive](https://hivedb.dev) (Lightweight, NoSQL local storage)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router) (Declarative routing)
- **Design System**: Custom premium theme with Google Fonts (Public Sans) and Material Symbols.

## 🏗️ Architecture

The project follows a **Feature-First** architecture with clean separation of layers:

- **Data**: Repositories for storage (Hive) and data mapping (DTOs/Adapters).
- **Domain**: Pure business logic and entity definitions (`Meter`, `Investigator`).
- **Presentation**: Reactive UI components, Notifiers, and Providers.
- **Core**: Shared services (Device, Location), utilities, and application-wide theme/routing.

## 📦 Getting Started

1. **Clone the repository**
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run the app**:
   ```bash
   flutter run
   ```

## 🧪 Verification & Testing

- **Manual Verification**: Test the full investigation flow, including draft persistence (close and reopen the app during step 2).
- **Export Test**: Use the "Export All" button in the Dashboard and share the resulting CSV.
- **Sync Simulation**: Tap "Sync All" to see the background synchronization workflow.

---
*Built with care for the RPECG Investigation Team.*
