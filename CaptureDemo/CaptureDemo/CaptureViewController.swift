//
//  CaptureViewController.swift
//  SycDemo
//
//  Created by rigour on 2017/12/19.
//  Copyright © 2017年 syc. All rights reserved.
//

import UIKit
import AVFoundation

class CaptureViewController: UIViewController {

    private var videoDeviceInput: AVCaptureDeviceInput!
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.frame = UIScreen.main.bounds
        return layer
    }()
    private lazy var session: AVCaptureSession = {
        return AVCaptureSession()
    }()
    private lazy var focusSquareView: UIView = {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.red.cgColor
        v.backgroundColor = UIColor.clear
        v.alpha = 0
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.white
        self.navigationItem.title = "视频采集"
        
        // 权限
        authorization()
        
        self.view.addSubview(focusSquareView)
        self.view.bringSubview(toFront: focusSquareView)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if session.isRunning{
            session.stopRunning()
        }
    }
    
    
    
    func authorization(){
        // 权限
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch status {
        case AVAuthorizationStatus.authorized:
            self.setupCapture()
        case AVAuthorizationStatus.notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
                if granted == true{
                    self.setupCapture()
                }
            })
        default:
            break
        }
    }
    func setupCapture(){
        // 获取摄像头 音频 设备
        var videoDevice: AVCaptureDevice!
        let audioDevice = AVCaptureDevice.default(for: .audio)
        let videoDevices = AVCaptureDevice.devices(for: AVMediaType.video)
        for device in videoDevices{
            if device.position == AVCaptureDevice.Position.front{
                // 正面
                videoDevice = device
            }
        }
        do{
            // 设备输入对象
            videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
            if session.canAddInput(videoDeviceInput){
                session.addInput(videoDeviceInput)
            }
            if session.canAddInput(audioDeviceInput){
                session.addInput(audioDeviceInput)
            }
            /*
            // 可以用于切换摄像头
            session.removeInput(videoDevice)
            session.addInput(videoDevice)
            */
        }catch let err{
            print("capture device input err = \(err)")
        }
        
        // 视频输出
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        if session.canAddOutput(videoOutput){
            session.addOutput(videoOutput)
        }
        // 音频输出
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        if session.canAddOutput(audioOutput){
            session.addOutput(audioOutput)
        }
        
        //let videoConnect = videoOutput.connection(with: AVMediaType.video)
        
        self.view.layer.addSublayer(previewLayer)
        
        session.startRunning()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch: UITouch = touches.first else{
            return
        }
        let point: CGPoint = touch.location(in: self.view)
        let cameraPoint: CGPoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
        
        // 显示方框
        focusSquareView.center = point
        focusSquareView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        focusSquareView.alpha = 1.0
        UIView.animate(withDuration: 1.0, animations: {
            self.focusSquareView.transform = CGAffineTransform.identity
        }) { (finished) in
            self.focusSquareView.alpha = 0
        }
        
        
        let videoDevice = videoDeviceInput.device
        // 锁定
        try? videoDevice.lockForConfiguration()
        
        // 聚焦
        if videoDevice.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus){
            videoDevice.focusMode = .autoFocus
        }
        if videoDevice.isFocusPointOfInterestSupported{
            videoDevice.focusPointOfInterest = cameraPoint
        }
        // 曝光
        if videoDevice.isExposureModeSupported(AVCaptureDevice.ExposureMode.autoExpose){
            videoDevice.exposureMode = .autoExpose
        }
        if videoDevice.isExposurePointOfInterestSupported{
            videoDevice.exposurePointOfInterest = cameraPoint
        }
        // 解锁
        videoDevice.unlockForConfiguration()
        
    }
}

extension CaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    // MARK: 视频
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output.connection(with: AVMediaType.video) == connection {
            // 采集到视频
            
        }else{
            // 采集到音频
            
        }
    }
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
}
extension CaptureViewController: AVCaptureAudioDataOutputSampleBufferDelegate{
    // MARK: 音频
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {    }
}
