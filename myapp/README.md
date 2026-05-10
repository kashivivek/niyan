# Niyan Property Management & Society ERP

![Niyan Cover](https://via.placeholder.com/1200x400.png?text=Niyan+Society+ERP+-+Next+Gen+Property+Management)

Niyan is a modern, responsive, full-fledged Property Management and Society ERP built with Flutter and Firebase. It features a stunning, premium user interface inspired by industry leaders like Zillow, and provides an end-to-end ecosystem for Landlords, Society Admins, Residents, and Security Guards.

## 🚀 Key Features & Modules

### 1. Dual-Mode Architecture
- **Standalone Landlord Mode:** Manage personal rental portfolios, units, and leases.
- **Society ERP Mode:** A fully collaborative ecosystem for managing large residential complexes and Homeowner Associations (HOAs).

### 2. Comprehensive Financial & Billing Engine
- Automated invoice generation with PDF receipts.
- Intelligent rent collection tracking and overdue alerts.
- Admin tool for applying automated late fees across the society.
- Expense tracking and Purchase Order (PO) creation for vendor management.

### 3. Advanced Security & Gate Management
- **QR-Based Pre-Approvals:** Residents can generate digital gate passes for guests.
- **Guard Dashboard:** A real-time interface for guards to track visitors inside, log walk-ins, and manage deliveries.
- **🚨 Emergency SOS:** One-tap panic button for residents that immediately triggers an unmissable red alert at the security gate.
- **Daily Help Tracking:** Automated attendance logging for maids, drivers, and cooks.

### 4. Administrative & Governance Tools
- **Asset Tracking:** Track physical society assets (e.g., elevators, generators), purchase dates, and maintenance schedules.
- **Helpdesk Ticketing:** A streamlined complaint resolution system with dynamic priority assignment.
- **Parking Management:** Digital layout of parking spots and assignment tracking.
- **Lease Tracking:** Lifecycle management of tenant leases, documents, and move-in/move-out workflows.

### 5. Community Engagement Hub
- **Notice Board:** High-priority community announcements and broadcasts.
- **Interactive Polls:** Democratic decision-making for society events or rules.
- **Document Library:** A centralized repository for society by-laws, meeting minutes, and rulebooks.
- **Amenity Booking:** Real-time scheduling and capacity management for clubhouses, gyms, and pools.

### 6. AI-Ready Infrastructure
- Built with a modular service layer ready for AI integration (e.g., Smart Helpdesk Categorization, AI Document Chat for society rules).

---

## 🛠️ Tech Stack

- **Frontend:** Flutter (Web, iOS, Android)
- **Backend:** Firebase (Firestore, Authentication, Storage)
- **State Management:** Provider
- **Routing:** GoRouter (ShellRoute architecture for responsive navigation)
- **UI/UX:** Google Fonts (Outfit, Inter), Custom Glassmorphism, Material 3.

---

## 💻 Running the App Locally

### Prerequisites
- Flutter SDK (latest stable)
- Firebase CLI installed and logged in.

### Setup
1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Configure your Firebase project using `flutterfire configure`.
4. To run on the web:
   ```bash
   flutter run -d chrome
   ```

### Production Build
To create an optimized production web build:
```bash
flutter build web --release --no-tree-shake-icons
firebase deploy --only hosting
```

---

## 🛡️ Role-Based Access Control (RBAC)
Niyan uses granular Firestore security rules and a robust front-end router to deliver isolated experiences based on user roles:
- `Super Admin`: System-wide access, data migration execution.
- `Society Admin` / `Treasurer`: Financials, Assets, Helpdesk, Notices.
- `Resident` / `Tenant`: My dues, My gate passes, Amenity bookings, SOS.
- `Guard`: Gate operations, Visitor Check-ins, Live SOS Monitoring.

*Built with ❤️ for Modern Communities.*
