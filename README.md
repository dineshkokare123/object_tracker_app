# object_tracker_app
🌟 Real-Time Object Transformation Tracker (Flutter & ML Kit)
This project is a mobile application developed using Flutter and Google's ML Kit for real-time video processing. It goes beyond standard object detection by implementing an object tracking algorithm to analyze and report on the transformation (movement and scaling) of detected objects frame-by-frame.

💡 Key Features and Functionality
Feature	Description
Real-Time Detection	Utilizes the device's camera stream and Google ML Kit's built-in models for continuous object detection.
Multi-Object Tracking	Uses the trackingId provided by ML Kit to maintain state for multiple objects across successive frames.
Transformation Analysis	Calculates two main types of transformations based on bounding box changes: <ul><li>Translation: Analyzes change in the object's center (deltaX, deltaY) to determine if it is Moving.</li><li>Scaling: Analyzes the ratio of change in the object's width to determine if it is Growing or Shrinking.</li></ul>
Cross-Platform Compatibility	Includes crucial logic (_processCameraImage function) to correctly handle image byte formats for both Android (NV21/YUV) and iOS (BGRA8888), ensuring reliable camera streaming.
Custom Visualization	Uses a CustomPainter to overlay bounding boxes, object labels, and the detected transformation status directly onto the camera preview.
🛠️ Technologies Used
Framework: Flutter (for cross-platform UI).

Language: Dart.

Computer Vision Library: google_mlkit_object_detection (for core object detection and tracking).

Camera Integration: camera package (for accessing the device camera stream).

🚀 Installation and Setup
Prerequisites

Flutter SDK and proper environment setup.

Android/iOS Development Environment (Xcode/Android Studio).

Ensure the minimum SDK requirements for the google_mlkit_object_detection package are met.

Project Steps

Clone the Repository:

Bash
git clone https://github.com/dineshkokare123/object_tracker_app/tree/main
cd object_tracker_app
Get Dependencies:

Bash
flutter pub get
Permissions Setup: You must ensure that Camera permissions are added to both your Info.plist (iOS) and AndroidManifest.xml (Android) files.

Run the App:

Bash
flutter run
(Note: This application requires a physical device or a well-configured emulator/simulator with camera access.)

📁 Code Highlights
The core logic resides in ObjectTrackerScreenState:

_initializeDetector(): Sets up the ObjectDetector in stream mode with multipleObjects: true to enable tracking IDs.

_processCameraImage(): Manages the continuous feed from the camera, performs the platform-specific byte handling, and calls _objectDetector.processImage().

_analyzeTransformations(): This is the heart of the tracking algorithm. It uses the object's historical center and size data to calculate its current status (Moving, Scaling, or Static) based on set thresholds.

## Screenshots

| Real-Time Detection | Object Tracking 
<img width="345" height="698" alt="IMG_5314" src="https://github.com/user-attachments/assets/dd320141-9baf-489f-b315-90657a98f1b7" />
<img width="345" height="698" alt="IMG_5313" src="https://github.com/user-attachments/assets/1534a17f-1dfb-4d23-8237-53f7d53b4258" />




