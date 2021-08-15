//
//  Main.swift
//  SimpleDALPlugin
//
//  by trulyspinach :)

import Foundation
import CoreMediaIO
import IOKit

let debugLog = false

class Plugin: Object {
    var objectID: CMIOObjectID = 0
    let name = "PSCAMDALPlugin"

    lazy var properties: [Int : Property] = [
        kCMIOObjectPropertyName: Property(name),
    ]
}

class Device: Object {
    var objectID: CMIOObjectID = 0
    var streamID: CMIOStreamID = 0
    let name = "PlayStation Camera"
    let manufacturer = "Sony Interactive Entertainment & SPINACH Instruments"
    let deviceUID = "PlayStation Camera DAL Device"
    let modelUID = "PlayStation Camera DAL Model"
    var excludeNonDALAccess: Bool = false
    var deviceMaster: Int32 = -1

    lazy var properties: [Int : Property] = [
        kCMIOObjectPropertyName: Property(name),
        kCMIOObjectPropertyManufacturer: Property(manufacturer),
        kCMIODevicePropertyDeviceUID: Property(deviceUID),
        kCMIODevicePropertyModelUID: Property(modelUID),
        kCMIODevicePropertyTransportType: Property(UInt32(kIOAudioDeviceTransportTypeBuiltIn)),
        kCMIODevicePropertyDeviceIsAlive: Property(UInt32(1)),
        kCMIODevicePropertyDeviceIsRunning: Property(UInt32(1)),
        kCMIODevicePropertyDeviceIsRunningSomewhere: Property(UInt32(1)),
        kCMIODevicePropertyDeviceCanBeDefaultDevice: Property(UInt32(1)),
        kCMIODevicePropertyCanProcessAVCCommand: Property(UInt32(0)),
        kCMIODevicePropertyCanProcessRS422Command: Property(UInt32(0)),
        kCMIODevicePropertyHogMode: Property(Int32(-1)),
        kCMIODevicePropertyStreams: Property { [unowned self] in self.streamID },
        kCMIODevicePropertyExcludeNonDALAccess: Property(
            getter: { [unowned self] () -> UInt32 in self.excludeNonDALAccess ? 1 : 0 },
            setter: { [unowned self] (value: UInt32) -> Void in self.excludeNonDALAccess = value != 0  }
        ),
        kCMIODevicePropertyDeviceMaster: Property(
            getter: { [unowned self] () -> Int32 in self.deviceMaster },
            setter: { [unowned self] (value: Int32) -> Void in self.deviceMaster = value  }
        ),
    ]
}



func log(_ message: Any = "", function: String = #function) {
    if !debugLog {return}
    NSLog("PSCAM DAL: \(function): \(message)")
}

@_cdecl("pscamDALPluginMain")
public func pscamDALPluginMain(allocator: CFAllocator, requestedTypeUUID: CFUUID) -> CMIOHardwarePlugInRef {
    NSLog("PSCAM DAL Start!")
    return pluginRef
}
