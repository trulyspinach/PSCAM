//
//  AVFoundationCamera.swift
//  PSCAM
//
//  Created by trulyspinach on 8/7/21.
//

import Foundation
import AVFoundation

protocol AVFoundationCameraDelegate {
    func onFrameReady(sampleBuffer: CMSampleBuffer)
}

class AVFoundationCamera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var device: AVCaptureDevice!
    var session: AVCaptureSession!
    
    var pixelbuf: CVPixelBuffer?
    
    var delegate: AVFoundationCameraDelegate?
    
    override init() {
        super.init()
        if #available(macOS 10.14, *) {
            AVCaptureDevice.requestAccess(for: .video) { stat in
            }
        }
        
        
        let devices = AVCaptureDevice.devices(for: .video)
        print(devices)
//        for dev in devices {
//            if dev.modelID.contains("VendorID_1449") {device = dev}
//        }
        device = devices[1]
        print(device.activeFormat)
//        if device == nil {return nil}
        
//        print(device.activeFormat)

//        try! device.lockForConfiguration()
//        device.exposureMode = .continuousAutoExposure
//        let fm = device.formats[2]
//        device.activeFormat = fm
//        let dur = fm.videoSupportedFrameRateRanges.max(by: {$0.maxFrameRate > $1.maxFrameRate})?.minFrameDuration
//        device.activeVideoMinFrameDuration = dur!
//        device.activeVideoMaxFrameDuration = dur!
//        device.unlockForConfiguration()

        

        session = AVCaptureSession()
        let di = try! AVCaptureDeviceInput(device: device)
        session?.addInput(di)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        session?.addOutput(output)
    }
    
    func startStreaming() {

        session?.startRunning()
    }
    
    func stopStreaming() {
        session.stopRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
//        let ib = CMSampleBufferGetImageBuffer(sampleBuffer)! as CVPixelBuffer
        
        delegate?.onFrameReady(sampleBuffer: sampleBuffer)
        
    }
}
