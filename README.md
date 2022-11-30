# _AutoFocus_
### _Project for IZA course at at Faculty of Information Technology, Brno University of Technology_

**Name and surname:** Marius Iustin Grossu

**Login:** xgross10

Simple app that use the iPhone/iPad camera to detect a face and when a face is detected it focus on it.

#### _Implementation_

In this app are used the **AVFoundation** and **Vision** libraries from Apple. Using AVFoundation the app gets access to the main (default) camera via the _AVCaptureSession()_ class, which coordinates several inputs like a microphone or camera in several outputs. On startup the user is asked to allow the camera to be used, the permission management for the camera is not implemented, so if the user disables access the application crashes. Subsequently, what the camera captures is displayed on the screen using the _AVCaptureVideoPreviewLayer()_ class. While receiving each frame that the camera captures, it is sent for processing using Vision, which has already implemented face detection algorithms.

