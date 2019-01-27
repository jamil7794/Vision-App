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
    var speechSinthetizer = AVSpeechSynthesizer()

    @IBOutlet weak var spinner: UIActivityIndicatorView!
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
        speechSinthetizer.delegate = self
        self.spinner.isHidden = true
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
        self.cameraView.isUserInteractionEnabled = false
        self.spinner.isHidden = false
        self.spinner.startAnimating()
        
        let settings = AVCapturePhotoSettings()
        
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        
        if flashControl == .off {
            settings.flashMode = .off
        }else{
            settings.flashMode = .on
        }
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func resultsMethod(request: VNRequest, error: Error?){
        guard let results = request.results as? [VNClassificationObservation] else {return}
        for classification in results {
            if classification.confidence < 0.5 {
                let unknownObjectMessage = "I am not sure what this is. Please try Again!"
                self.indentificationLbl.text = unknownObjectMessage
                sinthesizeSpeech(fromString: unknownObjectMessage)
                self.confidenceLbl.text = ""
                break
            }else{
                let identification = classification.identifier
                let confidence = classification.confidence * 100
                self.indentificationLbl.text = identification
                self.confidenceLbl.text = "Confidence: \(confidence)%"
                let completeSentence = "This looks like \(identification) and I am \(confidence) percent sure"
                sinthesizeSpeech(fromString: completeSentence)
                break
            }
        }
    }
    @IBAction func flashButtonWasPressed(_ sender: Any) {
        switch flashControl {
            case .on:
                flashButton.setTitle("Flash Off", for: .normal)
                flashControl = .off
            case .off:
                flashButton.setTitle("Flash On", for: .normal)
                flashControl = .on
            }
    }
    
    func sinthesizeSpeech(fromString string: String){
        let speechUtterence = AVSpeechUtterance(string: string)
        speechSinthetizer.speak(speechUtterence)
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

extension CameraVC: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.cameraView.isUserInteractionEnabled = true
        self.spinner.isHidden = true
        self.spinner.stopAnimating()
    }
}

