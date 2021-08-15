//
//  ViewController.swift
//  PSCAM
//
//  Created by trulyspinach on 8/1/21.
//

import Cocoa
import AVFoundation
import CoreImage

class ViewController: NSViewController {
    
    var session: AVCaptureSession?
    var displayLayer: CALayer?
    
    let ctx = CIContext()
    var pixelbuf: CVPixelBuffer?
    var cam: AVFoundationCamera? = nil
    var uvcCam: UVCCamera? = nil
    @IBOutlet weak var iview: NSImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let booter = CamUSBBooter()
        booter?.bootDeviceNow()
        
        
        
        
//        cam = AVFoundationCamera()
//        cam?.delegate = self
//        initAVCaptureDev()
        
        uvcCam = UVCCamera()
        uvcCam?.delegate = self
        
    }
    

    
    @IBAction func doStuff(_ sender: Any) {
        cam?.startStreaming()
        uvcCam?.startStreaming()
    }
    
}

extension ViewController: AVFoundationCameraDelegate {
    func onFrameReady(sampleBuffer: CMSampleBuffer) {
        let ib = CMSampleBufferGetImageBuffer(sampleBuffer)! as CVPixelBuffer
        let ciimg = CIImage(cvPixelBuffer: ib)
        let cg = ctx.createCGImage(ciimg, from: CGRect(x: 0, y: 0, width: 3448, height: 808))
//        ctx.render(ciimg, to: pixelbuf!)
        displayLayer?.contents = cg
//        print(CMSampleBufferGetFormatDescription(sampleBuffer))
        iview.image = NSImage(cgImage: cg!, size: ciimg.extent.size)
        displayLayer?.setNeedsDisplay()
        view.setNeedsDisplay(view.bounds)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        
//        print(CMSampleBufferGetFormatDescription(sampleBuffer))
    }
}


extension ViewController: UVCCameraDelegate {
    func onFrameReady(pixelBuffer: CVPixelBuffer) {
        let ciimg = CIImage(cvPixelBuffer: pixelBuffer)
        let cg = ctx.createCGImage(ciimg, from: CGRect(x: 0, y: 0, width: 1280, height: 800))
//        ctx.render(ciimg, to: pixelbuf!)
        displayLayer?.contents = cg
//        print(CMSampleBufferGetFormatDescription(sampleBuffer))
        iview.image = NSImage(cgImage: cg!, size: ciimg.extent.size)
        displayLayer?.setNeedsDisplay()
        view.setNeedsDisplay(view.bounds)
    }
}
