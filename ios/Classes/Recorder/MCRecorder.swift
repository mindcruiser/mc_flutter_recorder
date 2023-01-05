//
//  MCRecorder.swift
//  mc_flutter_recorder
//
//  Created by sunfa.li on 2022/9/20.
//  Copyright © 2022 com.mindcruiser. All rights reserved.
//

import Foundation

class MCRecorder: NSObject, MCRecorderProtocol {
    
    weak var delegate: MCRecorderDelegate?
    
    var config: MCRecorderConfig?
    private var _preMediaTime: Double = 0.0
    var duration: TimeInterval = 0
    
    private var _timer: Repeater?
    
    func start() -> Bool {
        _preMediaTime = CACurrentMediaTime()
        return true
    }
    
    func pause() -> Bool {
        duration += max(CACurrentMediaTime(), _preMediaTime) - _preMediaTime;
        return true
    }
    
    func resume() -> Bool {
        _preMediaTime = CACurrentMediaTime()
        return true
    }
    
    func stop() -> Bool {
        _preMediaTime = 0
        duration = 0
        return true
    }
    
    private func initTimer(interval: Int) {
        _timer =  Repeater(interval: .milliseconds(interval), mode: .infinite) { [weak self] _ in
            self?.progressUpdated()
        }
        _timer?.start()
    }

    func fireTimer(interval: Int) {
        if (_timer == nil) {
            initTimer(interval: interval)
        } else {
            _timer?.start()
        }
    }
    
    func pauseTimer() {
        _timer?.pause();
    }
    
    func invalidateTimer() {
        _timer?.pause();
        _timer = nil;
    }
    
    func progressUpdated() {
        let isDiskFree = diskEnable()
        if (!isDiskFree) {
            delegate?.recorderException(.noSpace, "stopped because of disk not free")
        }
        
        duration += max(CACurrentMediaTime(), _preMediaTime) - _preMediaTime;
//         print("CurrentMediaTime  \(CACurrentMediaTime()), duration: \(duration)")
        _preMediaTime = CACurrentMediaTime()
        let isDurationEnable = durationEnable()
        if (!isDurationEnable) {
            delegate?.recorderException(.durationExceeded, "stopped because of duration is Exceeded")
        }
    }
    
    func diskEnable() -> Bool {
        let freeDisk = config?.freeDisk ?? 1
        if (Int(UIDevice.current.freeDiskSpaceInMB) >= freeDisk) {
            return true
        }
        
        return false;
    }
    
    func durationEnable() -> Bool {
        guard let maxDuration = config?.maxDuration else {
            return true
        }
        if (duration * 1000 <= maxDuration) {
            return true
        }
        return false;
    }
}
