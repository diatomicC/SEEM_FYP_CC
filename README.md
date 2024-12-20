# ScanEat

ScanEat is a Flutter-based mobile application that allows users to scan QR codes to place menu orders.

## Prerequisites

Before starting the project, ensure the following items are installed:
- Flutter SDK (version 3.0.0 or higher)
- Dart SDK (version 2.17.0 or higher)
- Android Studio or VS Code
- Xcode for iOS development (for Mac users)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/username/ScanEat.git
```

2. Navigate to the project directory:
```bash
cd ScanEat
```

3. Install dependencies:
```bash
flutter pub get
```

## How to Run the Project

### Development Mode

To run the app in debug mode:
```bash
flutter run
```

### Release Build

For an Android APK build:
```bash
flutter build apk
```

For an iOS IPA build (Mac only):
```bash
flutter build ios
```

## Setting Up Environment Variables

Create a `.env` file in the root directory of the project and add the following variables:
```
API_URL=your_api_url
FIREBASE_API_KEY=your_firebase_api_key
```

## Testing

Run unit tests:
```bash
flutter test
```

## Key Features

- QR code scanning functionality
- Menu ordering system
- Payment system integration
- Order history view
- User profile management

## Project Structure

```
lib/
  ├── models/        # Data models
  ├── views/         # UI screens
  ├── controllers/   # Business logic
  ├── services/      # APIs and external services
  └── utils/         # Utility functions
```

## Contact

Email the development team at: team@scaneat.com  
Project link: [https://github.com/diatomicC/SEEM_FYP_CC](https://github.com/diatomicC/SEEM_FYP_CC)
