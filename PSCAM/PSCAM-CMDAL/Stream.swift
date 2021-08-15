//
//  Stream.swift
//  SimpleDALPlugin
//
//  by trulyspinach :)

import Cocoa
import AVFoundation
import CoreImage
class Stream: Object, UVCCameraDelegate {

    
    var objectID: CMIOObjectID = 0
    let name = "PSCameraPlugin"
//    let width = 1280
//    let height = 720
    let width = 3448
    let height = 808
    
    let frameRate = 60
    
    var cam: UVCCamera? = nil
    var sbb: CVPixelBuffer? = nil
    
    private var sequenceNumber: UInt64 = 0
    private var queueAlteredProc: CMIODeviceStreamQueueAlteredProc?
    private var queueAlteredRefCon: UnsafeMutableRawPointer?

    private lazy var formatDescription: CMVideoFormatDescription? = {
        var formatDescription: CMVideoFormatDescription?
        let error = CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: kCVPixelFormatType_32ARGB,
            width: Int32(width), height: Int32(height),
            extensions: nil,
            formatDescriptionOut: &formatDescription)
        guard error == noErr else {
            log("CMVideoFormatDescriptionCreate Error: \(error)")
            return nil
        }
        return formatDescription
    }()

    private lazy var clock: CFTypeRef? = {
        var clock: Unmanaged<CFTypeRef>? = nil

        let error = CMIOStreamClockCreate(
            kCFAllocatorDefault,
            "SimpleDALPlugin clock" as CFString,
            Unmanaged.passUnretained(self).toOpaque(),
            CMTimeMake(value: 1, timescale: 10),
            100, 10,
            &clock);
        guard error == noErr else {
            log("CMIOStreamClockCreate Error: \(error)")
            return nil
        }
        return clock?.takeUnretainedValue()
    }()

    private lazy var queue: CMSimpleQueue? = {
        var queue: CMSimpleQueue?
        let error = CMSimpleQueueCreate(
            allocator: kCFAllocatorDefault,
            capacity: 30,
            queueOut: &queue)
        guard error == noErr else {
            log("CMSimpleQueueCreate Error: \(error)")
            return nil
        }
        return queue
    }()

    private lazy var timer: DispatchSourceTimer = {
        let interval = 1.0 / Double(frameRate)
        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now() + interval, repeating: .milliseconds(1000 / frameRate))
        timer.setEventHandler(handler: { [weak self] in
            self?.enqueueBuffer()
        })
        return timer
    }()

    lazy var properties: [Int : Property] = [
        kCMIOObjectPropertyName: Property(name),
        kCMIOStreamPropertyFormatDescription: Property(formatDescription!),
        kCMIOStreamPropertyFormatDescriptions: Property([formatDescription!] as CFArray),
        kCMIOStreamPropertyDirection: Property(UInt32(0)),
        kCMIOStreamPropertyFrameRate: Property(Float64(frameRate)),
        kCMIOStreamPropertyFrameRates: Property(Float64(frameRate)),
        kCMIOStreamPropertyMinimumFrameRate: Property(Float64(frameRate)),
        kCMIOStreamPropertyFrameRateRanges: Property(AudioValueRange(mMinimum: Float64(frameRate), mMaximum: Float64(frameRate))),
        kCMIOStreamPropertyClock: Property(CFTypeRefWrapper(ref: clock!)),
    ]

    func start() {
        timer.resume()
        
        if cam == nil {
            cam = UVCCamera()
            cam?.delegate = self
            cam?.startStreaming()
        } else {
            
        }

    }

    func stop() {
        timer.suspend()
        cam?.stopStreaming()
        cam = nil
    }

    func copyBufferQueue(queueAlteredProc: CMIODeviceStreamQueueAlteredProc?, queueAlteredRefCon: UnsafeMutableRawPointer?) -> CMSimpleQueue? {
        self.queueAlteredProc = queueAlteredProc
        self.queueAlteredRefCon = queueAlteredRefCon
        return self.queue
    }

    private func createPixelBuffer() -> CVPixelBuffer? {
        return sbb
        
        let pixelBuffer = CVPixelBuffer.create(size: CGSize(width: width, height: height))
        pixelBuffer?.modifyWithContext { [width, height] context in
            let time = Double(mach_absolute_time()) / Double(1000_000_000)
            let pos = CGFloat(time - floor(time))
            
            context.setFillColor(NSColor.cyan.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))

            context.setFillColor(NSColor.magenta.cgColor)

            context.fill(CGRect(x: pos * CGFloat(width), y: 310, width: 100, height: 100))
        }
        return pixelBuffer
    }

    func onFrameReady(pixelBuffer: CVPixelBuffer) {
//        print("lololol")
        sbb = pixelBuffer
    }
    
    private func enqueueBuffer() {
        guard let queue = queue else {
            log("queue is nil")
            return
        }

        guard CMSimpleQueueGetCount(queue) < CMSimpleQueueGetCapacity(queue) else {
            log("queue is full")
            return
        }

        guard let pixelBuffer = createPixelBuffer() else {
            log("pixelBuffer is nil")
            return
        }

        let scale = UInt64(frameRate) * 100
        let duration = CMTime(value: CMTimeValue(scale / UInt64(frameRate)), timescale: CMTimeScale(scale))
        let timestamp = CMTime(value: duration.value * CMTimeValue(sequenceNumber), timescale: CMTimeScale(scale))

        var timing = CMSampleTimingInfo(
            duration: duration,
            presentationTimeStamp: timestamp,
            decodeTimeStamp: timestamp
        )

        var error = noErr

        error = CMIOStreamClockPostTimingEvent(timestamp, mach_absolute_time(), true, clock)
        guard error == noErr else {
            log("CMSimpleQueueCreate Error: \(error)")
            return
        }

        var formatDescription: CMFormatDescription?
        error = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription)
        guard error == noErr else {
            log("CMVideoFormatDescriptionCreateForImageBuffer Error: \(error)")
            return
        }

        var sampleBufferUnmanaged: Unmanaged<CMSampleBuffer>? = nil
        error = CMIOSampleBufferCreateForImageBuffer(
            kCFAllocatorDefault,
            pixelBuffer,
            formatDescription,
            &timing,
            sequenceNumber,
            UInt32(kCMIOSampleBufferNoDiscontinuities),
            &sampleBufferUnmanaged
        )
        guard error == noErr else {
            log("CMIOSampleBufferCreateForImageBuffer Error: \(error)")
            return
        }
        
 
        queueAlteredProc?(objectID, sampleBufferUnmanaged!.toOpaque(), queueAlteredRefCon)
        CMSimpleQueueEnqueue(queue, element: sampleBufferUnmanaged!.toOpaque())
        queueAlteredProc?(objectID, sampleBufferUnmanaged!.toOpaque(), queueAlteredRefCon)

        sequenceNumber += 1
    }
}
