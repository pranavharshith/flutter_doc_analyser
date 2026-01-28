# Vortex-app

Vortex-app is a Flutter-based mobile application designed for document text recognition and analysis, primarily targeting students. The app allows users to scan/upload documents, extract text using Google ML Kit, and compare the recognized text with information provided by the student. This helps ensure accuracy in document verification for educational use cases.

## Features

- Scan and upload documents using the device camera or file picker.
- Extract text from documents with Google ML Kit for high accuracy.
- Compare extracted text with user-provided (student) information.
- Firebase authentication and Firestore integration for secure data storage and management.
- User-friendly and responsive Flutter UI.
- Local file storage and preferences support.
- Toast notifications for user feedback.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Dependencies](#dependencies)
- [Contributing](#contributing)
- [License](#license)

## Installation

1. **Clone the repository**
    ```bash
    git clone https://github.com/k-vaidoorya/Vortex-app.git
    cd Vortex-app
    ```

2. **Install dependencies**
    ```bash
    flutter clean
    flutter pub get
    ```

3. **Run the application**
    ```bash
    flutter run
    ```

## Usage

1. Open the app on your mobile device or emulator.
2. Follow the instructions to upload or scan a document.
3. Enter the expected information as prompted.
4. The app will extract and analyze the text, providing a comparison with the entered data.
5. Results, notifications, and next steps will be displayed in the app.

## Project Structure

```
Vortex-app/
├── lib/
│   ├── main.dart
│   ├── [feature folders and Dart files]
├── assets/
│   ├── vortex_icon.jpg
│   ├── vortex_splash.png
├── ios/
│   └── Runner/Assets.xcassets/LaunchImage.imageset/
├── android/
├── pubspec.yaml
├── README.md
└── ...
```

## Dependencies

Key dependencies used in this project include:
- `google_mlkit_text_recognition`: Text extraction from images/documents.
- `firebase_auth`, `firebase_core`, `cloud_firestore`: Backend authentication and storage.
- `shared_preferences`, `path_provider`: Local data storage.
- `image_picker`, `file_picker`: Document and image uploading.
- `fluttertoast`: User notifications.
- `intl_phone_field`, `intl`: Internationalization support.

For the full list, see [`pubspec.yaml`](pubspec.yaml).

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create your feature branch: `git checkout -b feature/YourFeature`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/YourFeature`
5. Open a Pull Request

Please make sure to update tests as appropriate.

---

For questions, contact [@k-vaidoorya](https://github.com/k-vaidoorya).
