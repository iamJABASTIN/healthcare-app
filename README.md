<div align="center">

# 🏥 Healthcare Appointment Booking System
### A ZenThink Technologies Internship Task

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=flat&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0-blue?style=flat&logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-orange?style=flat&logo=firebase)
![Architecture](https://img.shields.io/badge/Architecture-MVVM-green)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-tech-stack">Tech Stack</a> •
  <a href="#-getting-started">Getting Started</a> •
  <a href="#-project-structure">Structure</a> •
  <a href="#-troubleshooting">Troubleshooting</a>
</p>

</div>

---

## 📖 Overview

A comprehensive, cross-platform mobile application designed to bridge the gap between patients, doctors, and administrators. The app facilitates seamless appointment booking, secure medical record storage (using Cloudinary & Firestore), and robust doctor verification workflows.

This project adheres to the **MVVM (Model-View-ViewModel)** architecture to ensure separation of concerns and code scalability.

---

## 📱 Screenshots
### User Flow

```markdown
![user Screen](docs/screenshots/u1.png)
![user Screen](docs/screenshots/u2.png)
![user Screen](docs/screenshots/u3.png)
![user Screen](docs/screenshots/u4.png)
![user Screen](docs/screenshots/u5.png)
![user Screen](docs/screenshots/u6.png)
![user Screen](docs/screenshots/u7.png)
![user Screen](docs/screenshots/u8.png)
![user Screen](docs/screenshots/u9.png)

### Doctor Flow
![Docter Screen](docs/screenshots/d1.png)
![Docter Screen](docs/screenshots/d2.png)
![Docter Screen](docs/screenshots/d3.png)
![Docter Screen](docs/screenshots/d4.png)
![Docter Screen](docs/screenshots/d5.png)
![Docter Screen](docs/screenshots/d6.png)
![Docter Screen](docs/screenshots/d7.png)

### Admin Flow
![Docter Screen](docs/screenshots/a1.png)
![Docter Screen](docs/screenshots/a2.png)
![Booking - Confirmation](assets/screenshots/booking-2.png)
```

## ✨ Features

### 🩺 Patient
- [x] **Authentication:** Secure login/signup via Firebase.
- [x] **Doctor Discovery:** Browse verified doctors by specialty.
- [x] **Smart Booking:** Slot reservation system.
- [x] **Records:** Upload medical files (Cloudinary) with metadata storage.
- [x] **Status Tracking:** "Upcoming" vs "Past" appointments (Auto-classified with 10min buffer).

### 👨‍⚕️ Doctor
- [x] **Profile Management:** Set professional details.
- [x] **Dashboard:** Quick view of Today's, Upcoming, and Total Patient stats.
- [x] **Schedule Management:** View appointments sorted by time.

### 🛡️ Admin
- [x] **Analytics:** Visual metrics for Total Appointments and Specialties.
- [x] **Verification:** Approve or Reject doctor registrations.
- [x] **System Oversight:** Monitor registration rates.

---

## 🛠 Tech Stack

- **Frontend:** Flutter (Material 3 Design)
- **Backend:** Firebase (Authentication, Firestore Database)
- **Storage:** Cloudinary (Image/File hosting)
- **State Management:** Provider / ChangeNotifier
- **Architecture:** MVVM

---

## 🚀 Getting Started

Follow these steps to get a local copy up and running.

### Prerequisites
* Flutter SDK (Stable Channel)
* Android Studio / VS Code
* A Firebase Project

### Installation

1.  **Clone the repository**
    ```bash
    git clone <your-repo-url>
    cd healthcare_app
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Environment Configuration (Crucial)**
    > ⚠️ **Note:** You must provide your own API keys.

    * **Firebase:** Place `google-services.json` in `android/app/` and `GoogleService-Info.plist` in `ios/Runner/`.
    * **Cloudinary:** Update credentials in `lib/core/services/cloudinary_service.dart`:
        ```dart
        const String cloudName = "YOUR_CLOUD_NAME";
        const String uploadPreset = "YOUR_PRESET";
        ```

4.  **Run the App**
    ```bash
    flutter run
    ```

---

## 📂 Project Structure

A high-level overview of the MVVM implementation:

```text
lib/
├── main.dart                  # Entry point, Providers setup
├── core/                      # Constants, Utils, Services (Cloudinary/Firebase)
├── data/                      # Data Layer
│   └── models/                # AppointmentModel, UserModel, MedicalRecordModel
├── view_models/               # Business Logic (ChangeNotifiers)
│   ├── auth_view_model.dart
│   ├── doctor_home_view_model.dart
│   └── ...
└── views/                     # UI Layer
    ├── widgets/               # Reusable components
    └── screens/
        ├── auth/              # Login/Register
        ├── patient/           # Patient workflows
        ├── doctor/            # Doctor workflows
        └── admin/             # Admin Dashboard