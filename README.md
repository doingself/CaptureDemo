# CaptureDemo

+ Xcode	9.1
+ Swift	4
+ IOS	8.0



对 AVFoundation 一次综合的使用

起初只想做选择照片, 视频录制的例子, 后来不断扩展

目前包含了: `选择照片` `拍照` `照片人脸识别/二维码识别` `创建二维码` `扫描二维码条形码` `视频/音频 录制/播放`

```
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
```



#### ReplayKit(后续补充)

+ A7+
+ IOS9+

ReplayKit不需要太大电量损耗和性能损耗就可以产出高清的视频记录

```

import ReplayKit

// 开始录制
if RPScreenRecorder.shared().isAvailable{
    // 是否开启设备的麦克风
    RPScreenRecorder.shared().isMicrophoneEnabled = true
    RPScreenRecorder.shared().startRecording(handler: { (err: Error?) in
        
    })
}


// 结束录制
if RPScreenRecorder.shared().isRecording {
    RPScreenRecorder.shared().stopRecording(handler: { (previewVC: RPPreviewViewController?, err: Error?) in
        guard let preview = previewVC else{
            return
        }
        let needSave = false
        if needSave {
            // 回看
            self.present(preview, animated: true, completion: {
                
            })
        }else{
            // 丢弃记录
            RPScreenRecorder.shared().discardRecording {
                // ......
            }
        }
    })
}
```
