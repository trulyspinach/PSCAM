//
//  CamUSBBooter.swift
//  PSCAM
//
//  Created by trulyspinach on 8/5/21.
//

import Foundation

class CamUSBBooter {
    

    var deviceHandle: OpaquePointer!
    
    init?() {
        var libusb_ctx: UnsafeMutablePointer<OpaquePointer?>?
        let r = libusb_init(nil)
        if r < 0 {return nil}
        
        let devCnt = libusb_get_device_list(nil, &libusb_ctx)
        
        for i in 0..<devCnt {
            let device = libusb_ctx![i]
            var desc: libusb_device_descriptor = libusb_device_descriptor()
            libusb_get_device_descriptor(device, &desc)
            
            if desc.idVendor == 0x05a9 && desc.idProduct == 0x0580 {
                var dh: OpaquePointer?
                let s = libusb_open(device, &dh)
                if s == 0 {deviceHandle = dh}
                
//                var devConfig: UnsafeMutablePointer<libusb_config_descriptor>?
//                libusb_get_config_descriptor(device, 0, &devConfig)
//                print(devConfig?[0].bConfigurationValue)
            }
   
        }
        libusb_free_device_list(libusb_ctx, 1)
        
        if deviceHandle == nil {print("Unable to find USBBoot device."); return nil}
        
        libusb_set_configuration(deviceHandle, 1)
    }
    
    func bootDeviceNow() {
        let packedFirmware = Bundle.main.url(forResource: "702_B1BA24_68032", withExtension: "bin")
        let fwData = try! Data(contentsOf: packedFirmware!)
        
        var sent = 0
        var i = 0
        var index = 0x14
        let cSize = 512
//        print(fwData.count)
        while sent < fwData.count {
            let readSize = min(cSize, fwData.count - (sent))
            let subdata = NSMutableData(data: fwData.subdata(in: sent..<sent+readSize))
            let ptr = subdata.mutableBytes.bindMemory(to: UInt8.self, capacity: cSize)
            
            libusb_control_transfer(deviceHandle, 0x40, 0x0, UInt16(i), UInt16(index),
                                    ptr, UInt16(readSize), 0)
  
            i += cSize
            if i >= 65536 {
                i = 0
                index = index + 1
            }
            sent += readSize
//            print(readSize)
        }
        
        let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
        ptr[0] = 0x5b
        libusb_control_transfer(deviceHandle, 0x40, 0x0, 0x2200, 0x8018, ptr, 1, 0)
    }
}
