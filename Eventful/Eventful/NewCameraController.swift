//
//  NewCameraController.swift
//  Eventful
//
//  Created by Shawn Miller on 5/16/18.
//  Copyright © 2018 Make School. All rights reserved.
//

//custom camera built using avFoundation
//AV Foundation is the full featured framework for working with time-based audiovisual media on iOS

import Foundation
import AVFoundation
import UIKit


class NewCameraController: UIViewController {
    var stackView: UIStackView?
    var stackView2: UIStackView?
    let cameraController = CameraHelper()
    var tapToFocus = true;
    
    let captureButton : UIButton = {
        let captureButton = UIButton()
                captureButton.setImage(#imageLiteral(resourceName: "Trigger"), for: .normal)
        captureButton.addTarget(self, action: #selector(captureAction(_:)), for: .touchUpInside)

        //        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(Tap))  //Tap function will call when user tap on button
        //        tapGesture.delegate = self
        //        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector( captureAction(_:))) //Long function will call when user long press on button.
        //        longGesture.delegate = self
        //        tapGesture.numberOfTapsRequired = 1
        //        captureButton.addGestureRecognizer(tapGesture)
        //        captureButton.addGestureRecognizer(longGesture)
        return captureButton
    }()
    
    lazy var capturePreviewView: UIView = {
        let capturePreviewView =  UIView()
        capturePreviewView.backgroundColor = .black
        return capturePreviewView
    }()
    
    lazy var flashButton : UIButton = {
        let flashButton = UIButton()
        flashButton.setImage(#imageLiteral(resourceName: "Torch"), for: UIControlState())
        flashButton.addTarget(self, action: #selector(toggleFlashAction(_:)), for: .touchUpInside)
        return flashButton
    }()
    
    lazy var flipCameraButton : UIButton = {
        let flipCameraButton = UIButton()
        flipCameraButton.setImage(#imageLiteral(resourceName: "flip"), for: UIControlState())
        flipCameraButton.addTarget(self, action: #selector(cameraSwitchAction(_:)), for: .touchUpInside)
        return flipCameraButton
    }()
    
    lazy var cameraButton : UIButton = {
        let cameraButton = UIButton()
        cameraButton.setImage(#imageLiteral(resourceName: "icons8-instagram-filled-50"), for: UIControlState())
        //        flipCameraButton.addTarget(self, action: #selector(cameraSwitchAction(_:)), for: .touchUpInside)
        return cameraButton
    }()
    
    lazy var videoButton : UIButton = {
        let videoButton = UIButton()
        videoButton.setImage(#imageLiteral(resourceName: "icons8-documentary-filled-50"), for: UIControlState())
        //        flipCameraButton.addTarget(self, action: #selector(cameraSwitchAction(_:)), for: .touchUpInside)
        return videoButton
    }()
    
    
    override func viewDidLoad() {
        setupVC()
        
        func configureCameraController() {
            cameraController.prepare {(error) in
                if let error = error {
                    print(error)
                }
                
                try? self.cameraController.displayPreview(on: self.capturePreviewView)
            }
        }
        
        configureCameraController()
    }
    
    // Function which controls the flash button
    @objc private func toggleFlashAction(_ sender: Any) {
        if cameraController.flashMode == .on {
            cameraController.flashMode = .off
            flashButton.setImage(#imageLiteral(resourceName: "Torch"), for: UIControlState())
        }
            
        else {
            cameraController.flashMode = .on
            flashButton.setImage(#imageLiteral(resourceName: "Torch2"), for: UIControlState())
        }
    }
    
    // Function which controls the camera switch button
    @objc private func cameraSwitchAction(_ sender: Any) {
        do {
            try cameraController.switchCameras()
        }
            
        catch {
            print(error)
        }
        
        switch cameraController.currentCameraPosition {
        case .some(.front):
            flipCameraButton.setImage(#imageLiteral(resourceName: "flip"), for: UIControlState())

        case .some(.rear):
            flipCameraButton.setImage(#imageLiteral(resourceName: "flip"), for: UIControlState())

        case .none:
            return
        }
    }
    
    // Function which controls the taking of a picture
    @objc private func captureAction(_ sender: Any) {
        cameraController.captureImage {(image, error) in
            guard let image = image else {
                print(error ?? "Image capture error")
                return
            }
            
            let containerView = PreviewPhotoContainerView()
            self.view.addSubview(containerView)
            containerView.previewImageView.image =  image
//            containerView.eventKey = eventKey
            containerView.snp.makeConstraints { (make) in
                make.edges.equalTo(self.view)
            }
            
    }
    }
    
    //will take in a tap gesture and auto focus the camera
    @objc fileprivate func singleTapGesture(_ tap: UITapGestureRecognizer) {
        guard tapToFocus == true else {
            // Ignore taps
            return
        }
    
        let screenSize = capturePreviewView.bounds.size
        let tapPoint = tap.location(in: capturePreviewView)
        let x = tapPoint.y / screenSize.height
        let y = 1.0 - tapPoint.x / screenSize.width
        let focusPoint = CGPoint(x: x, y: y)
        
        switch cameraController.currentCameraPosition {
        case .some(.front):
            if let device = cameraController.frontCamera {
                do {
                    try device.lockForConfiguration()
                    
                    if device.isFocusPointOfInterestSupported == true {
                        device.focusPointOfInterest = focusPoint
                        device.focusMode = .autoFocus
                    }
                    device.exposurePointOfInterest = focusPoint
                    device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
                    device.unlockForConfiguration()
                    //Call delegate function and pass in the location of the touch
                    
                    DispatchQueue.main.async {
                        //self.cameraDelegate?.swiftyCam(self, didFocusAtPoint: tapPoint)
                    }
                }
                catch {
                    // just ignore
                }
            }
            
        case .some(.rear):
            if let device = cameraController.rearCamera {
                do {
                    try device.lockForConfiguration()
                    
                    if device.isFocusPointOfInterestSupported == true {
                        device.focusPointOfInterest = focusPoint
                        device.focusMode = .autoFocus
                    }
                    device.exposurePointOfInterest = focusPoint
                    device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
                    device.unlockForConfiguration()
                    //Call delegate function and pass in the location of the touch
                    
                    DispatchQueue.main.async {
                        //self.cameraDelegate?.swiftyCam(self, didFocusAtPoint: tapPoint)
                    }
                }
                catch {
                    // just ignore
                }
            }
            
            
        case .none:
            return
        }
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc func setupVC(){
        view.addSubview(capturePreviewView)
        capturePreviewView.addSubview(captureButton)
        capturePreviewView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
         stackView = UIStackView(arrangedSubviews: [ cameraButton, videoButton])
        stackView?.axis = .vertical
        stackView?.distribution = .fillEqually
        stackView?.spacing = 15.0
        if let firstStackView = stackView{
            self.capturePreviewView.addSubview(firstStackView)
            firstStackView.snp.makeConstraints { (make) in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(15)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).inset(15)
            }
        }
        
        stackView2 = UIStackView(arrangedSubviews: [ flashButton, flipCameraButton])
        stackView2?.axis = .vertical
        stackView2?.distribution = .fillEqually
        stackView2?.spacing = 15.0
        if let secondStackView = stackView2{
            self.capturePreviewView.addSubview(secondStackView)
            secondStackView.snp.makeConstraints { (make) in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(15)
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right).inset(15)
            }
        }
        
        captureButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(10.5)
            make.centerX.equalTo(view.safeAreaLayoutGuide.snp.centerX)
            make.height.width.equalTo(65)
        }
        //will allow the camera to be switched focused to a point on tap of the screen
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.singleTapGesture(_:)))
        singleTapGesture.numberOfTapsRequired = 1
        capturePreviewView.addGestureRecognizer(singleTapGesture)
        
        
        //will allow the camera to be switched from front to back with double tap of screen
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(cameraSwitchAction))
        doubleTapGesture.numberOfTapsRequired = 2
        capturePreviewView.addGestureRecognizer(doubleTapGesture)
        
        
    }
}
