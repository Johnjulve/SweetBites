# Changelog

All notable changes to the **SweetBites** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-10-11

### Fixed & Improved
- **Dashboard Service Build-Phase Assertion**:
  - Wrapped `_loadDashboard()` in `WidgetsBinding.instance.addPostFrameCallback` in `DashboardScreen`, eliminating the `setState() or markNeedsBuild() called during build` assertion crash when `DashboardService.loadDashboard()` fires `notifyListeners()` during initial mount.
- **Summary Metrics Layout Overflows**:
  - Adjusted summary grid `childAspectRatio` from `1.8` to `1.5`, providing sufficient vertical height for 2-line metric cards and eliminating the 19px `RenderFlex` bottom overflow warnings across viewports.
- **Inventory & Costing TabBar Alignment**:
  - Enabled `isScrollable: true` and `tabAlignment: TabAlignment.center` on the `InventoryScreen` top `TabBar`, preventing subpixel horizontal float calculation overflows (0.00175px) on compact screen widths.
- **Android Release Internet Permission**:
  - Declared `android.permission.INTERNET` in `AndroidManifest.xml`, allowing the GitHub release updater and in-app update checks to query network endpoints on release APKs.

---

## [1.0.0] - 2026-10-11

### Added
- **Inventory Packaging Types & Distinction**:
  - Added dedicated packaging/container type support (`Can`, `Bottle`, `Pack`, `Sachet`, `Pouch`, `Box`, `Bar`, `Tub`, `Piece`) to distinguish liquid extracts, canned milks, packets, powders, and dairy bars.
  - Added dynamic pluralization and contextual form labels (e.g., "Size per Can", "Price per Bottle", "4 cans", "1 bottle", "5 sachets").
  - Automated SQLite database migration to schema version 4 adding `package_type` with safe backward compatibility.
- **Recipe Costing & Margins Analytics**:
  - Fractional recipe measurement parser supporting mixed fractions (`1 1/2 cup`, `1/8 cup`, `1/4 tbsp`, `3/4 tsp`) with automatic conversion to standard units (`ml`, `g`, `pcs`).
  - Unit-cost calculations linking raw pantry stock pricing directly into cake recipes.
  - True production cost calculator factoring COGS, baker labor time, packaging, and facility overhead.
  - Interactive profit margin indicator chips and suggested retail price generator based on target margins.
- **Customer Directory & Quick Contact Picker**:
  - Added quick contact sheet dialog in the order creation form to browse, search, and select previously registered customers with one tap.
- **Order Completion Validation Gate**:
  - Implemented strict payment completion checks before allowing an order to transition to `Completed`.
  - Added auto-reversion back to the prior production phase if payment is removed or remains incomplete.
  - Added real-time order state refresh across views without needing an app restart.
- **Theming & Dark Mode Refinement**:
  - Cohesive bakery-tailored terracotta palette with comprehensive Dark and Light mode styling across inventory, costing, order details, and customer sheets.
- **Android APK Build Pipeline**:
  - Configured Gradle and Android toolchain for release APK generation with universal and architecture-split support (`--split-per-abi`).

### Changed
- Standardized stock counter UI with unit-aware badges and direct increment/decrement actions.
- Updated `.gitignore` to keep the repository lightweight by excluding temporary platform targets (`/web/`) and build artifacts.
