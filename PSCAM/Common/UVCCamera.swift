//
//  UVCCamera.swift
//  PSCAM
//
//  Created by trulyspinach on 8/7/21.
//

import Foundation
import CoreImage

@_cdecl("UVCCAMframeCallback")
func UVCCAMframeCallback(frame: UnsafeMutablePointer<uvc_frame>?, me: UnsafeMutableRawPointer?) -> Void {
    let meme = Unmanaged<UVCCamera>.fromOpaque(me!).takeUnretainedValue()
    if frame != nil {meme.handleNewFrame(frame: frame!)}
}

protocol UVCCameraDelegate {
    func onFrameReady(pixelBuffer: CVPixelBuffer)
}

class UVCCamera {
    
    var libuvcCtx: OpaquePointer? = nil
    let devHandle: OpaquePointer
    var streamCtrl: uvc_stream_ctrl_t
    
    var delegate: UVCCameraDelegate?
    
    var canvasBuffer: CVPixelBuffer? = nil
    
    var cictx = CIContext()
    
    init?() {
        uvc_init(&libuvcCtx, nil)
        
        var td: OpaquePointer? = nil
        uvc_find_device(libuvcCtx!, &td, 0x05a9, 0x058b, nil)
        if td == nil {return nil}
        
        var dh: OpaquePointer? = nil
        uvc_open(td!, &dh)
        if dh == nil {return nil}
        devHandle = dh!
 
        uvc_print_diag(devHandle, nil)
        var stream: uvc_stream_ctrl_t = uvc_stream_ctrl_t()
        uvc_get_stream_ctrl_format_size(devHandle, &stream, UVC_FRAME_FORMAT_YUYV, 3448, 808, 60)
        streamCtrl = stream
        uvc_print_stream_ctrl(&streamCtrl, nil)
        
        let sur = IOSurfaceCreate([kIOSurfaceWidth:1280,
                                   kIOSurfaceHeight:800,
                                   kIOSurfaceBytesPerElement: 4,
                                   kIOSurfacePixelFormat: kCVPixelFormatType_32BGRA] as CFDictionary)
        
        var pb: Unmanaged<CVPixelBuffer>? = nil
        CVPixelBufferCreateWithIOSurface(kCFAllocatorDefault, sur!, nil, &pb)
        canvasBuffer = pb!.takeRetainedValue()
        
    }
    
    func handleNewFrame(frame: UnsafeMutablePointer<uvc_frame>) {

        var bgra: UnsafeMutablePointer<uvc_frame_t>? = nil
        bgra = uvc_allocate_frame(Int(1280 * 800) * 4)
        
        uvc_yuyv2bgra_subset(frame, bgra, 48, 0, 1280, 800);
        
        var pb: CVPixelBuffer? = nil
   
        CVPixelBufferCreateWithBytes(kCFAllocatorDefault, 1280, 800, kCVPixelFormatType_32BGRA, bgra![0].data, 1280 * 4, { frame, buff in
            uvc_free_frame(frame?.bindMemory(to: uvc_frame_t.self, capacity: 1))
        }, bgra, nil, &pb)
        
        let ciimg = CIImage(cvPixelBuffer: pb!)
        let noiseRed = CIFilter(name: "CINoiseReduction")
        noiseRed?.setDefaults()
        noiseRed?.setValue(ciimg, forKey: kCIInputImageKey)
        
        cictx.render(noiseRed!.outputImage!, to: canvasBuffer!)
        
        DispatchQueue.main.async {
            self.delegate?.onFrameReady(pixelBuffer: self.canvasBuffer!)
        }
        
    }
    
    func startStreaming() {
        
        let freeSelf = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let a: (@convention(c)(UnsafeMutablePointer<uvc_frame>?, UnsafeMutableRawPointer?) -> Void)? = UVCCAMframeCallback
        
        uvc_set_ae_mode(devHandle, 2)
        
        let re = uvc_start_streaming(devHandle, &streamCtrl, a, freeSelf, 0)
        print("stream started \(re)")
    }
    
    func stopStreaming() {
        uvc_close(devHandle)
    }
    
//    deinit {
//        stopStreaming()
//    }
}
