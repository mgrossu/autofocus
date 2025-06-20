# _AutoFocus_

A simple app that uses the iPhone or iPad camera to detect faces and automatically focus on them.

#### _Implementation_

This app leverages Apple’s **AVFoundation** and **Vision** frameworks. It uses **AVFoundation** to access the default (main) camera through the `AVCaptureSession()` class, which manages multiple input sources (such as microphones or cameras) and outputs.

On startup, the app requests permission to use the camera. **Note:** camera permission management is not fully implemented, so if the user denies access, the app may crash.

The live camera feed is displayed on the screen using `AVCaptureVideoPreviewLayer()`. Each captured frame is processed using the **Vision** framework, which provides built-in face detection algorithms. When a face is detected, the app adjusts the camera focus accordingly.

