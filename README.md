# ARQuest - Scavenger Hunt AR 🚀

**ARQuest** is an augmented reality scavenger hunt app built with Flutter and Firebase. This project was developed as part of the Mobile App Development (Project 2) requirements at GSU.

## 📍 Project Objectives
- **Real-time Scavenger Hunt:** Discover treasures based on GPS location.
- **Augmented Reality:** View 3D treasures (GLB models) in the real world.
- **Spark Plan Integration:** Uses Firestore for image storage (Base64) to remain within free tier limits.

## 🛠️ Technical Architecture
- **Framework:** Flutter (Android/iOS)
- **Backend:** Firebase (Auth, Firestore)
- **AR Engine:** `ar_flutter_plugin` (v0.7.3)
- **Maps:** `Maps_flutter`
- **Location:** `geolocator` for 20m proximity detection.

## 🚀 Recent Milestones (May 3rd Final Sprint)
- ✅ **Firebase Setup:** Successfully configured `firebase_options.dart` and registered Android/iOS apps.
- ✅ **Dynamic Assets:** Implemented Remote URL loading for 3D models via Firestore `modelUrl`.
- ✅ **Real-world Testing:** Calibrated GPS coordinates for **Queen Tea GSU** (33.7538, -84.3871).
- ✅ **Spark Plan Compliance:** Developed Base64 encoding for photo capture to bypass paid storage needs.

## 📂 Installation
1. Clone the repo: `git clone https://github.com/simmikumari12/UserOne.git`
2. Install dependencies: `flutter pub get`
3. Add your `google-services.json` to `android/app/`.
4. Run: `flutter run` (Note: AR requires a physical device with SDK 24+).

## 👥 Team & Contributions
- **Simmi Kumari:** Lead Developer - Firebase Integration, AR Configuration, and UI Design.
