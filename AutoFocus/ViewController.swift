//
//  ViewController.swift
//  AutoFocus
//
//  Created by Marius Grossu on 19.05.2021.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    
    // MARK: Variables
    private let captureSession = AVCaptureSession()
    // Lazy because captureSession needs to be laoded only once and when it's really needed
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
        preview.videoGravity = .resizeAspectFill
        return preview
    }()
    // Default rear camera
    private let device = AVCaptureDevice.default(for: .video)!
    private let videoOutput = AVCaptureVideoDataOutput()
    private var faceLayers: [CAShapeLayer] = []

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addCameraInput(device)
        self.addPreviewLayer()
        self.addVideoOutput()
        self.setDefaultFocus(device)
        self.captureSession.startRunning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.bounds
    }
}

// MARK: Private functions
private extension ViewController {
    // Add default rear camera feed
    func addCameraInput(_ device: AVCaptureDevice){
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }

    // Display the camera feed
    func addPreviewLayer() {
        self.view.layer.addSublayer(self.previewLayer)
    }

    // Send live camera frames to ViewController
    func addVideoOutput() {
        self.videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        self.captureSession.addOutput(self.videoOutput)

        guard let connection = self.videoOutput.connection(with: AVMediaType.video),
            connection.isVideoOrientationSupported else { return }

        connection.videoOrientation = .portrait
    }

    // Handle the face detected
    func handleFaceDetectionResults(_ observedFaces: [VNFaceObservation]){
        observedFaces.forEach { face in
            let box = face.boundingBox
            let boxOnScreen = self.convert(rect: box)
            // Uses {0,0} to {1,1} coordinations where {1,1} is right bottom
            let focusPoint = CGPoint(x: box.midX, y: box.midY)
            self.changeFocus(focusPoint, self.device)
            let boxOnScreenPath = CGPath(rect: boxOnScreen, transform: nil)

            let faceLayer = CAShapeLayer()
            faceLayer.path = boxOnScreenPath
            faceLayer.fillColor = UIColor.clear.cgColor
            faceLayer.strokeColor = UIColor.yellow.cgColor

            self.faceLayers.append(faceLayer)
            self.view.layer.addSublayer(faceLayer)
        }
    }

    // Converts the normalize coordination of the detected face rectangle into the pixeled coordination on the screen
    func convert(rect: CGRect) -> CGRect{
        let boxOnScreen = self.previewLayer.layerRectConverted(fromMetadataOutputRect: rect)
        return boxOnScreen
    }

    // Change the focus of the camera
    func changeFocus(_ focusPoint: CGPoint, _ device:AVCaptureDevice){
        //print("Focus on x: \(focusPoint.x), y: \(focusPoint.y)")
        do {
            try device.lockForConfiguration()
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
            }

            device.unlockForConfiguration()
        } catch {
            print("Could not lock device for configuration: \(error)")
        }
    }

    // Make the request to detect the face, handles the request
    func detectFace(in image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async { [weak self] in
                // We don't want to create retain cycle
                guard let self = self else { return }

                self.faceLayers.forEach({drawing in drawing.removeFromSuperlayer()})

                if let results = request.results as? [VNFaceObservation], results.count > 0 {

                    //print("did detect \(results.count) face(s)")
                    self.handleFaceDetectionResults(results)

                } else {
                    //print("did not detect any face")
                }
            }
        })
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageRequestHandler.perform([faceDetectionRequest])
    }

    func setDefaultFocus(_ device:AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            device.isSubjectAreaChangeMonitoringEnabled = true
            device.focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
            device.unlockForConfiguration()
        } catch {
            // Handle errors here
            print("There was an error focusing the device's camera")
        }
    }
}

// MARK: AVCaptureVideoDataOutputSampleBufferDelegate
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    // Receives the frames
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer")
            return
        }
        // Process image here
        self.detectFace(in: frame)
    }
}
