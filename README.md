# 🏠 Niyan Property Management

**Niyan** is a premium, cross-platform property management application designed to help landlords streamline their operations, track revenue, and manage tenant relationships with ease.

Built with **Flutter** and **Firebase**, Niyan offers a reactive and intuitive experience across Android, iOS, and Web.

---

## ✨ Key Features

- **📊 Modern Dashboard**: Get a bird's-eye view of your property portfolio, including occupancy rates, monthly revenue, and pending tasks.
- **🏢 Property & Unit Management**: Organize your properties into units with detailed status tracking (Occupied, Vacant, Maintenance).
- **👥 Tenant Ledger**: Maintain a complete history of tenants, their contact information, and lease agreements.
- **🔔 Smart Rent Notifications**: Never miss a payment again. Landlords get automated reminders about upcoming and overdue rent, configurable by time and frequency.
- **💰 Financial Tracking**: A robust transaction system to track income and expenses per property.
- **📱 True Cross-Platform**: Optimized layouts for mobile (iOS/Android) and desktop/web environments.

---

## 🛠 Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase Auth, Cloud Firestore, Firebase Storage
- **Local Notifications**: `flutter_local_notifications`
- **State Management**: Provider
- **Design System**: Custom Modern Premium UI (Google Fonts, fl_chart)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>= 3.4.3)
- Firebase Account & Project

### Installation
1. **Clone the repository**:
   ```bash
   git clone https://github.com/kashivivek/niyan.git
   cd niyan/myapp
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**:
   - Add your `google-services.json` to `android/app/`
   - Add your `GoogleService-Info.plist` to `ios/Runner/`

4. **Run the app**:
   ```bash
   flutter run
   ```

---

## 📂 Project Structure

```text
niyan/
├── myapp/                  # Flutter application source code
│   ├── android/            # Native Android configuration
│   ├── ios/                # Native iOS configuration
│   ├── lib/
│   │   ├── models/         # Data models (User, Property, Tenant, etc.)
│   │   ├── providers/      # State management
│   │   ├── screens/        # UI Screens (Dashboard, Settings, etc.)
│   │   ├── services/       # Business logic (Auth, Database, Notifications)
│   │   └── widgets/        # Reusable UI components
│   └── web/                # Web configuration
└── README.md               # Project documentation
```

---

## 📄 License
Internal / Private Project for @kashivivek.
