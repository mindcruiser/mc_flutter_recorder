//
//  UIDeviceExt.swift
//  notta_recorder
//
//  Created by 黎孙发 on 2022/8/3.
//

import Foundation

extension UIDevice {
    func MBFormatter(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = ByteCountFormatter.Units.useMB
        formatter.countStyle = ByteCountFormatter.CountStyle.decimal
        formatter.includesUnit = false
        return formatter.string(fromByteCount: bytes) as String
    }
    
    //MARK: Get String Value
    var totalDiskSpaceInGBStrig:String {
        return ByteCountFormatter.string(fromByteCount: totalDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var totalDiskSpaceInGB:Double {
        return Double(totalDiskSpaceInBytes) / 1024.0 / 1024.0 / 1024.0
    }
    
    var freeDiskSpaceInGBStrig:String {
        return ByteCountFormatter.string(fromByteCount: freeDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var freeDiskSpaceInGB:Double {
        return Double(freeDiskSpaceInBytes) / 1024.0 / 1024.0 / 1024.0
    }
    
    var usedDiskSpaceInGBStrig:String {
        return ByteCountFormatter.string(fromByteCount: usedDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var usedDiskSpaceInGB:Double {
        return Double(usedDiskSpaceInBytes) / 1024.0 / 1024.0 / 1024.0
    }
    
    var totalDiskSpaceInMBStrig:String {
        return MBFormatter(totalDiskSpaceInBytes)
    }
    
    var totalDiskSpaceInMB:Double {
        return Double(totalDiskSpaceInBytes) / 1024.0 / 1024.0
    }
    
    var freeDiskSpaceInMBStrig:String {
        return MBFormatter(freeDiskSpaceInBytes)
    }
    
    var freeDiskSpaceInMB:Double {
        return Double(freeDiskSpaceInBytes) / 1024.0 / 1024.0
    }
    
    var usedDiskSpaceInMBStrig:String {
        return MBFormatter(usedDiskSpaceInBytes)
    }
    
    var usedDiskSpaceInMB:Double {
        return Double(usedDiskSpaceInBytes) / 1024.0 / 1024.0
    }
    
    //MARK: Get raw value
    var totalDiskSpaceInBytes:Int64 {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
              let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value else { return 0 }
        return space
    }
    
    /*
     Total available capacity in bytes for "Important" resources, including space expected to be cleared by purging non-essential and cached resources. "Important" means something that the user or application clearly expects to be present on the local system, but is ultimately replaceable. This would include items that the user has explicitly requested via the UI, and resources that an application requires in order to provide functionality.
     Examples: A video that the user has explicitly requested to watch but has not yet finished watching or an audio file that the user has requested to download.
     This value should not be used in determining if there is room for an irreplaceable resource. In the case of irreplaceable resources, always attempt to save the resource regardless of available capacity and handle failure as gracefully as possible.
     */
    var freeDiskSpaceInBytes:Int64 {
        if #available(iOS 11.0, *) {
            if let space = try? URL(fileURLWithPath: NSHomeDirectory() as String).resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
                return space
            } else {
                return 0
            }
        } else {
            if let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
               let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value {
                return freeSpace
            } else {
                return 0
            }
        }
    }
    
    var usedDiskSpaceInBytes:Int64 {
        return totalDiskSpaceInBytes - freeDiskSpaceInBytes
    }
}
