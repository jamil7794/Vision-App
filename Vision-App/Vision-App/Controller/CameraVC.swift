//
//  ViewController.swift
//  Vision-App
//
//  Created by Jamil Jalal on 1/20/19.
//  Copyright © 2019 Jamil Jalal. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum flashState {
    case on
    case off
}

class CameraVC: UIViewController {
    
    var captureSession: AVCaptureSession! // it controls the real time capture of the camera
    var cameraOutput: AVCapturePhotoOutput! // see documentation, converts to jpeg format
    var previewLayer: AVCaptureVideoPreviewLayer! // background view to show the camear
    var photoData: Data?
    var flashControl : flashState = .off

    @IBOutlet weak var captuteImageView: RoundedShadowImageView!
    @IBOutlet weak var flashButton: RoundedShadowButton!
    @IBOutlet weak var indentificationLbl: UILabel!
    @IBOutlet weak var confidenceLbl: UILabel!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var roundedLblView: RoundedShadowView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(1)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        previewLayer.frame = cameraView.bounds // to fit the framw the way we want it
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tap.numberOfTapsRequired = 1
        
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        
        do{
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(input) == true {
                captureSession.addInput(input)
            }
            
            cameraOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddOutput(cameraOutput) == true {
                captureSession.addOutput(cameraOutput!)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                
                cameraView.layer.addSublayer(previewLayer!)
                cameraView.addGestureRecognizer(tap)
                captureSession.startRunning()
            }
        }catch {
            debugPrint(error)
        }
    }
    
    @objc func didTapCameraView(){
        let settings = AVCapturePhotoSettings()
        
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        
        
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func resultsMethod(request: VNRequest, error: Error?){
        guard let results = request.results as? [VNClassificationObservation] else {return}
        for classification in results {
            if classification.confidence < 0.5 {
                self.indentificationLbl.text = "I am not sure what this is. Please try Again!"
                self.confidenceLbl.text = ""
                break
            }else{
                self.indentificationLbl.text = classification.identifier
                self.confidenceLbl.text = "Confidence: \(classification.confidence * 100)%"
                break
            }
        }
    }
}

extension CameraVC: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            debugPrint(error)
        }else{
            photoData = photo.fileDataRepresentation()
            
            do {
                let model = try VNCoreMLModel(for: SqueezeNet().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                let handler = VNImageRequestHandler(data: photoData!)
                try handler.perform([request])
            } catch {
                debugPrint(error)
            }
            
            let image = UIImage(data: photoData!)
            self.captuteImageView.image = image
        }
    }
}

