//
//  ViewController.swift
//  CaptureDemo
//
//  Created by syc on 2017/12/6.
//  Copyright © 2017年 test. All rights reserved.
//

// Swift 4
// Xcode 9.1
// IOS 8.0

import UIKit

import MobileCoreServices // 选择照片 picker.mediaTypes = [kUTTypeImage as String,kUTTypeVideo as String]

import AVFoundation // 录像

import Photos // PHPhotoLibrary 视频采集后保存到相册

import CoreImage // 人脸识别
import ImageIO // kCGImagePropertyOrientation 照片方向

class ViewController: UIViewController {

    private var lab: UILabel!
    
    private var tabView: UITableView!
    private let cellIdentificer = "cell"
    private lazy var datas: [String] = {
        let arr = [
            "选择照片","拍照",
            "录制音频（开始）","录制音频（结束）","播放音频",
            "录制视频（开始）","录制视频（结束）","播放视频",
            "照片人脸识别","人脸马赛克",
            "照片二维码识别","扫描二维码/条形码","创建二维码",
            "视频采集 焦距 曝光"
        ]
        return arr
    }()
    
    private var imgView: UIImageView!
    /// 识别人脸 二维码
    private lazy var context: CIContext = {
        return CIContext()
    }()
    // MARK: 音频
    private var audioFilePath: String!
    // 录制
    private var audioRecorder: AVAudioRecorder!
    // 播放
    private var audioPlayer: AVAudioPlayer!
    
    // MARK: 视频
    private var videoFilePath: String!
    // 录制
    private var captureSession: AVCaptureSession!
    private var videoDevice: AVCaptureDevice!
    private var audioDevice: AVCaptureDevice!
    private var fileOutput: AVCaptureMovieFileOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    // 播放
    private var timeObserver: Any?
    private var playerItem: AVPlayerItem!
    private var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    // 扫描二维码
    //private var captureSession: AVCaptureSession!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationItem.title = "AVFoundation"
        self.view.backgroundColor = UIColor.white
        
        var y: CGFloat = 0
        y += 80
        lab = UILabel(frame: CGRect(x: 0, y: y, width: self.view.bounds.size.width, height: 40))
        lab.numberOfLines = 0
        lab.textAlignment = NSTextAlignment.center
        lab.font = UIFont.systemFont(ofSize: 14)
        lab.textColor = UIColor.black
        self.view.addSubview(lab)
        
        y += 40 + 10
        let tabFrame = CGRect(x: 0, y: y, width: self.view.bounds.size.width, height: 300)
        tabView = UITableView(frame: tabFrame, style: UITableViewStyle.plain)
        tabView.delegate = self
        tabView.dataSource = self
        
        tabView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentificer)
        tabView.tableFooterView = UIView()
        
        tabView.rowHeight = UITableViewAutomaticDimension
        tabView.estimatedRowHeight = 44.0
        
        self.view.addSubview(tabView)
        
        y += 300 + 10
        imgView = UIImageView(frame: CGRect(x: 10, y: y, width: 100, height: 100))
        imgView.contentMode = .scaleAspectFit
        imgView.layer.borderWidth = 1
        self.view.addSubview(imgView)
        
        // 初始化文件地址
        initFilePath()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: 视频播放
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if playerItem != nil{
            playerItem.removeObserver(self, forKeyPath: "loadedTimeRanges")
            playerItem.removeObserver(self, forKeyPath: "status")
        }
        NotificationCenter.default.removeObserver(self)
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print("observe value keypath = \(String(describing: keyPath))")
        
        guard let playObject = object as? AVPlayerItem else{
            return
        }
        if keyPath == "loadedTimeRanges"{
            
        }else if keyPath == "status"{
            if playObject.status == AVPlayerItemStatus.readyToPlay{
                player.play()
            }
        }
    }
    
    @objc func playerItemDidReachEnd(notification: Notification){
        print("playerItemDidReachEnd 播放结束")
    }
}
extension ViewController: UITableViewDataSource{
    // MARK: 表格数据源
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentificer, for: indexPath)
        cell.selectionStyle = .gray
        cell.accessoryType = .disclosureIndicator
        
        let data = self.datas[indexPath.row]
        cell.textLabel?.text = data
        
        return cell
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}
extension ViewController: UITableViewDelegate{
    // MARK: 表格代理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        lab.text = datas[indexPath.row]
        
        switch indexPath.row {
            // "选择照片","拍照",
        case 0:
            selectPhoto()
        case 1:
            takePhoto()
            
            // "录制音频（开始）","录制音频（结束）","播放音频",
        case 2:
            recordStart()
        case 3:
            recordStop()
        case 4:
            audioPlay()
            
            // "录制视频（开始）","录制视频（结束）","播放视频",
        case 5:
            videoStart()
        case 6:
            videoStop()
        case 7:
            videoPlay()
            
            // "照片人脸识别","人脸马赛克",
        case 8:
            detectFace()
        case 9:
            detectPixFace()
            
            // "照片二维码识别","扫描二维码/条形码","创建二维码"
        case 10:
            detectQRCode()
        case 11:
            findQRcode()
        case 12:
            createQRCode()
            
            // "视频采集 焦距 曝光"
        case 13:
            let v = CaptureViewController()
            self.navigationController?.pushViewController(v, animated: true)
            
        default:
            break
        }
    }
}


extension ViewController: UINavigationControllerDelegate{
    // MARK: 选择照片代理
}
extension ViewController: UIImagePickerControllerDelegate{
    // MARK: 选择照片代理
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        print("didFinishPickingMediaWithInfo \(info)")
        
        var editImg: UIImage?
        var originImg: UIImage?
        
        if picker.sourceType == UIImagePickerControllerSourceType.camera{
            // 拍摄
            if picker.cameraCaptureMode == UIImagePickerControllerCameraCaptureMode.video {
                // 拍摄视频
                
            }else{
                // 拍摄照片
                
                //获取编辑后的图片
                editImg = info[UIImagePickerControllerEditedImage] as? UIImage
                //获取选择的原图
                originImg = info[UIImagePickerControllerOriginalImage] as? UIImage
            }
        }else{
            // 选择
        
            //获取编辑后的图片
            editImg = info[UIImagePickerControllerEditedImage] as? UIImage
            //获取选择的原图
            originImg = info[UIImagePickerControllerOriginalImage] as? UIImage
            
        }
        
        if editImg != nil && originImg != nil{
            self.imgView.image = editImg
            
            // MARK: GCD简单实用
            // 延迟执行
            let queue = DispatchQueue(label: "com.syc.test")
            queue.asyncAfter(deadline: DispatchTime.now() + 5.0, execute: {
                
                DispatchQueue.main.async(execute: {
                    // 在主线程更新UI
                    // 显示原图
                    self.imgView.image = originImg
                })
            })
        }
        
        //图片控制器退出
        picker.dismiss(animated: true, completion: {() -> Void in
        })
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("取消")
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: 选择照片
    func selectPhoto(){
        //判断是否支持要使用的图片库
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            //初始化图片控制器
            let picker = UIImagePickerController()
            //设置代理
            picker.delegate = self
            //指定图片控制器类型
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            //设置是否允许编辑
            picker.allowsEditing = true
            //弹出控制器，显示界面
            self.present(picker, animated: true, completion: {() -> Void in
                
            })
        }else{
            print("读取相册错误")
        }
    }
    // MARK: 拍照
    func takePhoto(){
        //判断是否支持相机
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            //初始化图片控制器
            let picker = UIImagePickerController()
            //设置代理
            picker.delegate = self
            //设置媒体类型
            picker.mediaTypes = [kUTTypeImage as String,kUTTypeVideo as String]
            //设置来源
            picker.sourceType = UIImagePickerControllerSourceType.camera
            // 拍摄视频时的最大拍摄时间
            picker.videoMaximumDuration = 6.0
            // 拍摄质量
            picker.videoQuality = UIImagePickerControllerQualityType.typeMedium
            
            // 是否显示系统默认相机UI界面（包括拍摄按钮、前后摄像头切换、闪光灯开关），默认为YES（显示系统默认UI）
            // 如果需要自定义该界面，则需要隐藏该UI，设置自定义的UI给cameraOverlayView
            //picker.cameraOverlayView = ...
            picker.showsCameraControls = true
            
            // 相机界面旋转
            picker.cameraViewTransform = CGAffineTransform(rotationAngle: CGFloat.pi*2)
            
            // 拍摄模式  照片/视频
            picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureMode.photo
            
            if UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice.front) {
                //设置镜头 front:前置摄像头  Rear:后置摄像头
                picker.cameraDevice = UIImagePickerControllerCameraDevice.front
            }
            //设置闪光灯(On:开、Off:关、Auto:自动)
            picker.cameraFlashMode = UIImagePickerControllerCameraFlashMode.on
            
            //允许编辑
            picker.allowsEditing = true
            //打开相机
            self.present(picker, animated: true, completion: nil)
        }
        else{
            print("读取摄像头错误")
        }
    }
    // MARK: 保存到相册
    /// 保存图片到相册
    func saveImageToAlbum(img: UIImage){
        UIImageWriteToSavedPhotosAlbum(img, self, #selector(self.imageSavedToAlbum(img:didFinishSaving:)), nil)
    }
    /// 保存照片成功后的回调
    @objc func imageSavedToAlbum(img: UIImage, didFinishSaving err: Error?){
        print("img save ablum \(String(describing: err))")
    }
    /// 保存视频到相册
    func saveVideoToAlbum(videoPath: String){
        UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, #selector(self.videoSavedToAlbum(videoPath:didFinishSaving:)), nil)
    }
    @objc func videoSavedToAlbum(videoPath: String, didFinishSaving err: Error?){
        print("video save ablum \(String(describing: err))")
    }
}
extension ViewController{
    // MARK: 文件地址
    /*
     3、tmp：保存应用运行时所需要的临时数据，使用完毕后再将相应的文件从该目录删除。应用没有运行，系统也可能会清除该目录下的文件，iTunes不会同步备份该目录
     */
    func initFilePath(){
        //获取程序的Home目录 包含了所有的资源文件和可执行文件
        let homeDirectory = NSHomeDirectory()
        
        //用户文档目录，苹果建议将程序中建立的或在程序中浏览到的文件数据保存在该目录下，iTunes备份和恢复的时候会包括此目录
        let documentPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        var documnetPath = documentPaths[0]
        // 或者可以这样
        documnetPath = homeDirectory + "/Documents"
        
        /*
         Library/Preferences目录，包含应用程序的偏好设置文件。不应该直接创建偏好设置文件，而是应该使用NSUserDefaults类来取得和设置应用程序的偏好。iTunes同步设备时会备份该目录
         Library/Caches目录，此目录下文件不会再应用退出时删除，保存应用运行时生成的需要持久化的数据，iTunes同步设备时不备份该目录。一般存放体积大、不需要备份的非重要数据
         */
        let libraryPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        var libraryPath = libraryPaths[0]
        libraryPath = homeDirectory + "/Library"
        
        let cachePaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        var cachePath = cachePaths[0]
        cachePath = NSHomeDirectory() + "/Library/Caches"
        
        // tmp目录 用于存放临时文件，保存应用程序再次启动过程中不需要的信息，重启后清空。
        var tmpDir = NSTemporaryDirectory()
        tmpDir = NSHomeDirectory() + "/tmp"
        
        audioFilePath = tmpDir + "/audio.wav"
        videoFilePath = tmpDir + "/video.mp4"
    }
}
extension ViewController{
    // MARK: 音频 录制、暂停、继续、结束、播放
    func recordStart(){
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        guard status == AVAuthorizationStatus.authorized else{
            // 未授权
            return
        }
        
        let session = AVAudioSession.sharedInstance()
        do{
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        }catch let err{
            print("session set category err = \(err)")
        }
        do{
            try session.setActive(true)
        }catch let err{
            print("session set active err = \(err)")
        }
        
        let recordSetting: [String: Any] = [
            AVSampleRateKey: NSNumber(value: 16000),//采样率
            AVFormatIDKey: NSNumber(value: kAudioFormatLinearPCM),//音频格式
            AVLinearPCMBitDepthKey: NSNumber(value: 16),//采样位数
            AVNumberOfChannelsKey: NSNumber(value: 1),//通道数
            AVEncoderAudioQualityKey: NSNumber(value: AVAudioQuality.min.rawValue)//录音质量
        ]
        
        // 开始录音
        do{
            let url = URL(fileURLWithPath: audioFilePath)
            audioRecorder = try AVAudioRecorder(url: url, settings: recordSetting)
            //开启仪表计数功能
            audioRecorder.isMeteringEnabled = true
            audioRecorder.prepareToRecord()
            audioRecorder.record()
        }catch let err{
            print("record err = \(err)")
        }
    }
    func recordPause(){
        // 暂停录音
        if audioRecorder != nil{
            if audioRecorder.isRecording {
                audioRecorder.pause()
            }
        }
    }
    func recordContinue(){
        // 暂停后继续录音
        if audioRecorder != nil{
            if audioRecorder.isRecording == false {
                let leng = audioRecorder.currentTime
                let r = audioRecorder.record(atTime: leng)
                if r == false{
                    audioRecorder.record()
                }
            }
        }
    }
    func recordStop(){
        // 结束录音
        if audioRecorder != nil{
            if audioRecorder.isRecording {
                print("正在录音，将要结束")
            }else{
                print("没有录音，将要结束")
            }
            audioRecorder.stop()
            audioRecorder = nil
        }
    }
    func audioPlay(){
        // 播放录音
        if audioPlayer != nil{
            if audioPlayer.isPlaying {
                audioPlayer.stop()
            }
        }
        do{
            let url = URL(fileURLWithPath: audioFilePath)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.prepareToPlay()
            let leng = audioPlayer.duration
            print("audio file leng = \(leng)")
        }catch let err {
            print("audio player err = \(err)")
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    // MARK: 视频输出代理 Video Data Output
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output.connection(with: AVMediaType.video) == connection{
            print("采集到视频")
        }else{
            print("采集到音频")
        }
        
        let pixeBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let ciImg = CIImage(cvPixelBuffer: pixeBuffer)
        let img = UIImage(ciImage: ciImg)
        // 代理方法中的所有动作所在队列都是在异步串行队列中，所以更新UI的操作需要回到主队列中进行
        DispatchQueue.main.async(execute: {
            self.imgView.image = img
        })
        
        
        /*
        从输出数据流捕捉单一的图像帧，并使用 OpenGL 手动地把它们显示在 view 上。
        可以对实时预览图进行操作或使用滤镜
        将它们绘制在一个 GLKView 中
        */
        
        /*
        let pixeBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let image = CIImage(cvPixelBuffer: pixeBuffer)
        
        let glContext = EAGLContext(api: EAGLRenderingAPI.openGLES2)
        let glView = GLKView(frame: self.imgView.frame, context: glContext)
        let ciContext = CIContext(eaglContext: glContext!)
        
        if EAGLContext.current() != glContext{
            EAGLContext.setCurrent(glContext)
        }
        glView.bindDrawable()
        ciContext.draw(image, in: image.extent, from: image.extent)
        glView.display()
        */
    }
}
extension ViewController: AVCaptureAudioDataOutputSampleBufferDelegate{
    // MARK: 音频输出代理 Audio Data Output
    //func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) { }
}
extension ViewController: AVCaptureFileOutputRecordingDelegate{
    // MARK: 视频录制 代理
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("didStartRecordingTo")
    }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("didFinishRecordingTo")
        // 录制结束，保存到相册
        let url = URL(fileURLWithPath: videoFilePath)
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { (suc, err) in
            print("performChanges suc = \(suc) err = \(String(describing: err))")
        }
    }
    
    // MARK: 视频 录制、结束、播放
    /// 直接使用 AVCaptureDevice.default 和 AVCaptureMovieFileOutput
    func initVideo1(){
        do{
            // 输入设备
            //直接使用后置摄像头
            videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
            audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
            //AVCaptureDeviceInput：使用该对象从AVCaptureDevice设备获取数据（用于获取摄像头拍摄的数据）
            //AVCaptureScreenInput：使用该对象从屏幕获取数据(用于录制屏幕)
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            
            /*
             输出为 NSData
             AVCaptureAudioDataOutput：音频数据
             AVCaptureStillImageOutput：相片数据
             AVCaptureVideoDataOutput：录像数据
             输出为 AVCaptureFileOutput
             AVCaptureAudioFileOutput：音频文件，生成一个URL
             AVCaptureMovieFileOutput：视频文件，生成一个URL
             */
            fileOutput = AVCaptureMovieFileOutput()
            
            // 将捕捉到的音视频会话输出到硬件设备上也就是AVCaptureDevice上。一个AVCaptureSession是可以包含多个输入和多个输出的。
            captureSession = AVCaptureSession()
            captureSession.beginConfiguration()
            // 添加 音视频 输入设备
            captureSession.addInput(videoInput)
            captureSession.addInput(audioInput)
            // 添加视频输出
            if captureSession.canAddOutput(fileOutput){
                captureSession.addOutput(fileOutput)
            }
            // 分辨率
            if captureSession.canSetSessionPreset(AVCaptureSession.Preset.medium){
                captureSession.sessionPreset = AVCaptureSession.Preset.medium
            }
            captureSession.commitConfiguration()
            
            // 预览实时画面
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = imgView.frame
            previewLayer.frame.origin.x += imgView.frame.size.width + 20
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            previewLayer.borderWidth = 1
            self.view.layer.addSublayer(previewLayer)
        }catch let err{
            print("init video err = \(err)")
        }
    }
    
    /**
     * 使用 AVCaptureDevice.position 可以调整前后摄像头
     * AVCaptureVideoDataOutput
     * 需要再次初始化 AVCaptureMovieFileOutput
     */
    func initVideo2(){
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        
        // 视频输入设备
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        //改变device.position, captureSession.removeInput后，重新addInput，用于切换前后摄像头
        //或者使用 AVCaptureConnection.videoOrientation = .portrait 切换
        videoDevice = devices.filter { (d: AVCaptureDevice) -> Bool in
            return d.position == AVCaptureDevice.Position.front
        }.first
        do{
            // 添加 输入设备
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput){
                captureSession.addInput(videoInput)
            }
        }catch let err{
            print("init video err = \(err)")
        }
        // 视频输出
        let videoDataOutput = AVCaptureVideoDataOutput()
        //videoDataOutput.videoSettings =
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global())
        if captureSession.canAddOutput(videoDataOutput){
            // 添加 输出
            captureSession.addOutput(videoDataOutput)
        }
        // 切换前后摄像头
        let connect: AVCaptureConnection = videoDataOutput.connection(with: AVMediaType.video)!
        connect.videoOrientation = .portrait
        
        
        // 音频输入设备
        audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
        do{
            // 添加 音视频 输入设备
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            captureSession.addInput(audioInput)
        }catch let err{
            print("init video err = \(err)")
        }
        // 音频输出
        let audioDataOutput = AVCaptureAudioDataOutput()
        audioDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global())
        captureSession.addOutput(audioDataOutput)
        
        //使用AVCaptureVideoPreviewLayer可以将摄像头的拍摄的实时画面显示在ViewController上
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = imgView.frame
        previewLayer.frame.origin.x += imgView.frame.size.width + 20
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        previewLayer.borderWidth = 1
        self.view.layer.addSublayer(previewLayer)
        
        captureSession.commitConfiguration()
    }
    func videoStart(){
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch status {
        case AVAuthorizationStatus.notDetermined:
            // 发起授权
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (grant) in
                if grant {
                    // 允许
                }else{
                    // 拒绝
                }
            })
        case AVAuthorizationStatus.authorized:
            // 已经授权
            break
        case AVAuthorizationStatus.denied:
            // 已经拒绝
            break
        case AVAuthorizationStatus.restricted:
            // 无法使用
            break
        }
        
        // 重复初始化是为了解决 扫描二维码共同 session
        initVideo2()
        
        if captureSession.isRunning == false {
            captureSession.startRunning()
        }
        if fileOutput == nil {
            // init2
            fileOutput = AVCaptureMovieFileOutput()
            let connect = fileOutput.connection(with: AVMediaType.video)
            connect?.automaticallyAdjustsVideoMirroring = true
            captureSession.beginConfiguration()
            if captureSession.canAddOutput(fileOutput){
                captureSession.addOutput(fileOutput)
            }
            captureSession.commitConfiguration()
        }
        // init1 or init2
        let url = URL(fileURLWithPath: videoFilePath)
        fileOutput.startRecording(to: url, recordingDelegate: self)
    }
    func videoStop(){
        if fileOutput.isRecording{
            fileOutput.stopRecording()
        }
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        previewLayer.removeFromSuperlayer()
    }
    func videoPlay(){
        let url = URL(fileURLWithPath: videoFilePath)
        
        //通过KVO监听AVPlayerItem的属性 addObserver(self, forKeyPath: "status", options: .new, context: nil)，
        //当属性变为AVPlayerStatusReadyToPlay时，通过AVPlayer调用play方法即可播放视频。
        playerItem = AVPlayerItem(url: url)
        playerItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
        playerItem.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerItemDidReachEnd(notification:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    
    
        //AVPlayer的play和pause分别控制播放和暂停
        //根据AVPlayer的播放速度rate可以判断当前是否为播放状态，rate=0暂停，rate=1播放。
        //视频播放完成后AVPlayerItem会发送AVPlayerItemDidPlayToEndTimeNotification通知。
        player = AVPlayer(playerItem: playerItem)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        playerLayer.contentsScale = UIScreen.main.scale
        playerLayer.frame = self.imgView.frame
        playerLayer.frame.origin.y += imgView.frame.size.height + 20
        playerLayer.borderWidth = 1
        
        self.view.layer.addSublayer(playerLayer)
        
        
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(value: CMTimeValue(bitPattern: 1), timescale: 1) , queue: DispatchQueue.main, using: { [weak self] (time: CMTime) in
            
            //视频总时间通过CMTimeGetSeconds(player.currentItem.duration)获取
            let totalTime = CMTimeGetSeconds(self!.playerItem.duration)
            //当前播放时间通过CMTimeGetSeconds(player.currentTime)获取
            let currentTime = CMTimeGetSeconds(time)
            
            //更新显示的时间和进度条
            print("total = \(totalTime), current = \(currentTime)")
        })
    }
}
extension ViewController{
    // MARK: 人脸识别
    func detectFace(){
        for v in self.imgView.subviews{
            v.removeFromSuperview()
        }
        guard let originImg = imgView.image else {
            return
        }
        guard let inputImg = CIImage(image: originImg) else{
            return
        }
        
        let accuracy:[String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        //CIDetectorTypeFace外，CIDetector还能检测二维码
        //多个CIDetector可以共用一个context对象
        //指定检测的精度，除了CIDetectorAccuracyHigh以外，还有CIDetectorAccuracyLow，精度高会识别度更高，但识别速度就更慢
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: accuracy)
        
        var feature:[CIFeature]!
        // 判断CIImage是否带有方向的元数据
        if let orientation = inputImg.properties[kCGImagePropertyOrientation as String]{
            let option: [String: Any] = [CIDetectorImageOrientation: orientation]
            feature = detector?.features(in: inputImg, options: option)
            
        }else{
            feature = detector!.features(in: inputImg)
            
        }
        let faceFeatures = feature as! [CIFaceFeature]
        print("faceFeatures = \(faceFeatures)")
        
        // 转换坐标
        let ciImgSize = inputImg.extent.size
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -ciImgSize.height)
        
        for face in faceFeatures {
            print("face.bounds = \(face.bounds)")
            
            // 计算实际位置
            let viewSize = self.imgView.bounds.size
            let scale = min(viewSize.width / ciImgSize.width, viewSize.height / ciImgSize.height)
            let offsetX = (viewSize.width - ciImgSize.width * scale) / 2
            let offsetY = (viewSize.height - ciImgSize.height * scale) / 2
            
            // 转换坐标
            var faceViewBounds = face.bounds.applying(transform)
            faceViewBounds = faceViewBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
            faceViewBounds.origin.x += offsetX
            faceViewBounds.origin.y += offsetY
            
            let faceBox = UIView(frame: faceViewBounds)
            faceBox.layer.borderWidth = 3
            faceBox.layer.borderColor = UIColor.red.cgColor
            faceBox.backgroundColor = UIColor.clear
            self.imgView.addSubview(faceBox)
            
            // 左眼
            print("left eye bounds = \(face.leftEyePosition)")
            let leftEye = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 5))
            leftEye.backgroundColor = UIColor.white
            leftEye.center = face.leftEyePosition
            self.imgView.addSubview(leftEye)
            
        }
    }
    
    func detectPixFace(){
        for v in self.imgView.subviews{
            v.removeFromSuperview()
        }
        guard let originImg = imgView.image else {
            return
        }
        guard let inputImg = CIImage(image: originImg) else{
            return
        }
        
        let inputScale = max(inputImg.extent.size.width , inputImg.extent.size.height) / 80
        
        let filter = CIFilter(name: "CIPixellate")
        filter?.setValue(inputImg, forKey: kCIInputImageKey)
        filter?.setValue(inputScale, forKey: kCIInputScaleKey)
        
        guard let fullPixelateImg = filter?.outputImage else{
            return
        }
        
        // 监测人脸，保存到 faceFeatures
        guard let detector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: nil) else{
            return
        }
        let faceFeatures = detector.features(in: inputImg)
        
        // 初始化蒙版图，并开始遍历检测到的所有人脸
        var maskImage: CIImage!
        for faceFeature in faceFeatures {
            print(faceFeature.bounds)
            // 基于人脸的位置，为每一张脸都单独创建一个蒙版，所以要先计算出脸的中心点，对应为x、y轴坐标，
            // 再基于脸的宽度或高度给一个半径，最后用这些计算结果初始化一个CIRadialGradient滤镜
            let centerX = faceFeature.bounds.origin.x + faceFeature.bounds.size.width / 2
            let centerY = faceFeature.bounds.origin.y + faceFeature.bounds.size.height / 2
            let radius = min(faceFeature.bounds.size.width, faceFeature.bounds.size.height)
            let radialGradient = CIFilter(
                name: "CIRadialGradient",
                withInputParameters: [
                    "inputRadius0" : radius,
                    "inputRadius1" : radius + 1,
                    "inputColor0" : CIColor(red: 0, green: 1, blue: 0, alpha: 1),
                    "inputColor1" : CIColor(red: 0, green: 0, blue: 0, alpha: 0),
                    kCIInputCenterKey : CIVector(x: centerX, y: centerY)
                ])!
            print(radialGradient.attributes)
            // 由于CIRadialGradient滤镜创建的是一张无限大小的图，所以在使用之前先对它进行裁剪
            guard let radialGradientOutputImage = radialGradient.outputImage?.cropped(to: inputImg.extent) else{
                return
            }
            if maskImage == nil {
                maskImage = radialGradientOutputImage
            } else {
                maskImage = CIFilter(
                    name: "CISourceOverCompositing",
                    withInputParameters: [
                        kCIInputImageKey : radialGradientOutputImage,
                        kCIInputBackgroundImageKey : maskImage
                    ]
                )!.outputImage
            }
        }
        // 用CIBlendWithMask滤镜把马赛克图、原图、蒙版图混合起来
        let blendFilter = CIFilter(name: "CIBlendWithMask")!
        blendFilter.setValue(fullPixelateImg, forKey: kCIInputImageKey)
        blendFilter.setValue(inputImg, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)
        // 输出，在界面上显示
        guard let blendOutputImage = blendFilter.outputImage else{
            return
        }
        guard let blendCGImage = context.createCGImage(blendOutputImage, from: blendOutputImage.extent) else{
            return
        }
        self.imgView.image = UIImage(cgImage: blendCGImage)
    }
}

extension ViewController{
    // MARK: 识别照片二维码
    func detectQRCode(){
        guard let img = self.imgView.image else{
            return
        }
        guard let ciImg = CIImage(image: img) else{
            return
        }
        
        let detecotor = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: context,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )
        
        let features = detecotor?.features(in: ciImg)
        let qrs = features as! [CIQRCodeFeature]
        for feature in qrs{
            print("得到的二维码：" + (feature.messageString ?? ""))
        }
    }
}
extension ViewController{
    // MARK: 扫描二维码
    func findQRcode(){
        //计算中间可探测区域
        let windowSize = UIScreen.main.bounds.size
        let scanSize = CGSize(
            width:windowSize.width*3/4,
            height:windowSize.width*3/4
        )
        var scanRect = CGRect(
            x:(windowSize.width-scanSize.width)/2,
            y:(windowSize.height-scanSize.height)/2,
            width:scanSize.width,
            height:scanSize.height
        )
        //计算rectOfInterest 注意x,y交换位置
        scanRect = CGRect(
            x:scanRect.origin.y/windowSize.height,
            y:scanRect.origin.x/windowSize.width,
            width:scanRect.size.height/windowSize.height,
            height:scanRect.size.width/windowSize.width
        )
        
        
        let vDevice = AVCaptureDevice.default(for: .video)!
        let vInput = try! AVCaptureDeviceInput(device: vDevice)
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        captureSession = AVCaptureSession()
        captureSession.addInput(vInput)
        captureSession.addOutput(output)
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        
        
        output.metadataObjectTypes = [
            // 二维码
            AVMetadataObject.ObjectType.qr,
            
            // 条形码
            AVMetadataObject.ObjectType.ean13, .ean8,.code39, .code93, .code128
        ]
        // 可探测区域
        output.rectOfInterest = scanRect
        
        // 预览实时画面
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = UIScreen.main.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.view.layer.addSublayer(previewLayer)
        
        // 开始扫描
        captureSession.startRunning()
    }
}

extension ViewController: AVCaptureMetadataOutputObjectsDelegate{
    // MARK: metadata output 扫描二维码
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if let codeObjs = metadataObjects as? [AVMetadataMachineReadableCodeObject], codeObjs.count > 0 {
            for metadataObj: AVMetadataMachineReadableCodeObject in codeObjs{
                print("扫描到二维码：" + (metadataObj.stringValue ?? ""))
            }
        }
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        previewLayer.removeFromSuperlayer()
    }
}
extension ViewController{
    // MARK: 创建二维码
    func createQRCode(){
        let qrString = "https://doingself.github.io"
        let qrData = qrString.data(using: String.Encoding.utf8)
        let qrFilter = CIFilter(name: "CIQRCodeGenerator")!
        qrFilter.setValue(qrData, forKey: "inputMessage")
        qrFilter.setValue("H", forKey: "inputCorrectionLevel")
        let qrCIImg = qrFilter.outputImage!
        
        let colorFilter = CIFilter(name: "CIFalseColor")!
        colorFilter.setDefaults()
        colorFilter.setValue(qrCIImg, forKey: "inputImage")
        colorFilter.setValue(CIColor(red: 0, green: 0, blue: 0), forKey: "inputColor0")
        colorFilter.setValue(CIColor(red: 1, green: 1, blue: 1), forKey: "inputColor1")
        
        let transform = CGAffineTransform(scaleX: 5, y: 5)
        //let ciImg = colorFilter.outputImage!.applying(transform)
        let ciImg: CIImage = colorFilter.outputImage!.transformed(by: transform)
        let codeImg = UIImage(ciImage: ciImg)
        
        if let logoImg = self.imgView.image{
            let rect = self.imgView.bounds
            UIGraphicsBeginImageContext(rect.size)
            
            codeImg.draw(in: rect)
            
            let avatarSize = CGSize(width: rect.size.width*0.25, height: rect.size.width*0.25)
            let x = (rect.width - avatarSize.width)*0.5
            let y = (rect.height - avatarSize.height)*0.5
            logoImg.draw(in: CGRect(x: x, y: y, width: avatarSize.width, height: avatarSize.height))
            
            let resultImg = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            self.imgView.image = resultImg
            
        }else{
            self.imgView.image = codeImg
        }
    }
}
