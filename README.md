# SweetBites - Bakery Order & Inventory Management System

[![Version](https://img.shields.io/badge/version-1.1.0-orange.svg)](CHANGELOG.md)
[![Database Schema](https://img.shields.io/badge/sqlite_schema-v4-blue.svg)](lib/core/constants.dart)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-green.svg)](#)

SweetBites is a Flutter-based offline-first mobile application tailored for home bakers and boutique bakeshops. It manages custom cake orders, tracks payments, handles pantry stock with container distinction, calculates exact recipe COGS with fractional measurements, and generates professional PDF receipts.

See the full history of updates in the [CHANGELOG.md](CHANGELOG.md).

---

## 🚀 Key Features

### 📋 Order Management & Workflow Guard
- **Lifecycle Tracking**: Seamlessly transition orders across stages (`Pending` → `Baking` → `Ready` → `Completed`).
- **Payment Verification Gate**: Prevents marking orders as `Completed` until payment is 100% fulfilled; automatically reverts if requirements are unmet.
- **Instant State Synchronization**: Updates immediately reflect across the Dashboard, Orders, and Details screens without requiring an app restart.

### 🥫 Pantry & Stock Inventory
- **Container-Aware Packaging**: Accurately distinguish ingredients by container type (**Can**, **Bottle**, **Pack**, **Sachet**, **Pouch**, **Box**, **Bar**, **Tub**, **Piece**).
- **Dynamic Contextual Labels**: Form fields and list cards adapt to the container (e.g. `360ml per can`, `₱39.50/can`, `4 cans`, `2 bottles`, `5 sachets`).
- **Stock Counter & Alerts**: Fast increment/decrement controls, low-stock threshold badges, and automatic valuation calculation.

### 🧁 Recipe Costing & Margin Analytics
- **Fractional Recipe Measurement Parser**: Handles standard kitchen measurements (`1 1/2 cup`, `1/8 cup`, `1/4 tbsp`, `3/4 tsp`) and converts them to precise metric units (`g`, `ml`, `pcs`).
- **True Production Costing**: Calculates accurate per-cake cost factoring:
  - **COGS**: Unit costs mapped directly from live pantry stock.
  - **Labor**: Baking time (minutes) and baker's hourly wage.
  - **Overhead & Packaging**: Box, ribbon, card, and utility allocations.
- **Profit Margin Analytics**: Healthy margin indicators (green 30%+, warning chips), net profit figures, and margin-targeted suggested retail pricing.

### 👥 Customer Directory & Quick Picker
- **Instant Search & History**: Search past clients with order history and total spend.
- **Quick Contact Picker**: Easily select an existing customer when creating an order via a single-tap contacts sheet.

### 🧾 Receipts & Offline SQLite Storage
- **PDF Invoicing**: Generate clean, shareable digital receipts with itemized order details, pickup schedules, and payment terms.
- **100% Offline-First**: Built on SQLite with automated schema migrations (up to v4) for seamless updates with zero data loss.
- **Dark Mode Support**: Complete terracotta aesthetic optimized for low-light environments.

---

## 🛠️ Getting Started

### Prerequisites
- **Flutter SDK**: 3.7.0 or higher
- **Dart SDK**: 3.x
- **Android SDK**: API 34+ (for Android APK builds)

### Installation & Run

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run test suite
flutter test

# 3. Launch application on a connected device
flutter run
```

---

## 📦 Building Android APK

### Universal Release APK
```bash
flutter build apk --release
```
The output file will be generated at:
`build/app/outputs/flutter-apk/app-release.apk` (~62 MB)

### Optimized Small APKs (Split per ABI)
To generate smaller APKs (~20–25 MB) targeted for specific device architectures:
```bash
flutter build apk --split-per-abi
```
Generated files:
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` *(Modern 64-bit devices)*
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` *(Older 32-bit devices)*

---

## 🏗️ Architecture

SweetBites follows Clean Architecture combined with the **Repository Pattern**:

```
lib/
├── core/          # App theme, constants (db version), formatters, unit helpers
├── models/        # Domain entities (Customer, Product, Order, InventoryItem, RecipeItem)
├── database/      # SQLite singleton, schema definitions & version migrations
├── repositories/  # Abstract interfaces + SQLite implementations
├── services/      # Business logic & state management (ChangeNotifiers)
├── screens/       # UI Pages (Dashboard, Orders, Products, Inventory, Costing)
└── widgets/       # Reusable UI components & bottom sheets
```

### Backend Scalability
Because the data access layer is abstracted through repository interfaces, transitioning to a remote REST or GraphQL API backend (e.g., Laravel / NestJS) requires swapping repository implementations without altering screens or business logic.

---

## 📄 License
Proprietary — SweetBites Bakery. All rights reserved.
