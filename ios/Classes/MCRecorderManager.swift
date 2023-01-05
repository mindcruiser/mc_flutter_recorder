//
//  MCRecorderManager.swift
//  mc_flutter_recorder
//
//  Created by sunfa.li on 2022/9/20.
//  Copyright © 2022 com.mindcruiser. All rights reserved.
//

import Foundation
import AVFAudio

class MCRecorderManager: NSObject {
    
    weak var delegate: MCRecorderManagerDelegate?
    
    private var _recorder: MCRecorder?
    
    var state: MCRecorderState {
        get { _state }
    }
    private var _state: MCRecorderState = .notInitialized {
        didSet {
//            print("current state \(_state)")
            delegate?.updateRecorderState(_state)
        }
    }
}

extension MCRecorderManager {
    
    func initRecorder(arguments: Any?) -> Bool {
        requestPermission { [weak self] in
            self?.setupRecorder(arguments: arguments)
        } rejected: { [weak self] in
            self?.delegate?.updateRecorderException(.noPermission, "not record permission")
        }
        return true
    }
    
    private func setupRecorder(arguments: Any?) {
        guard let args = arguments as? Dictionary<String, Any>,
              let filePath = args["filePath"] as? String,
              let sampleRate = args["sampleRate"] as? Double,
              let bitRate = args["pcmBitRate"] as? String,
              let channel = args["channel"] as? String,
              let period = args["period"] as? Int,
              let freeDisk = args["freeDisk"] as? Int,
              let interruptedBehavior = args["interruptedBehavior"] as? String else {
                  delegate?.updateRecorderException(.illegalArgument, "recorder config arguments error")
                  return
              }
        let maxDuration = args["maxDuration"] as? TimeInterval
        let config = MCRecorderConfig(filePath: filePath,
                                         sampleRate: sampleRate,
                                         pcmBitRate: PCMBitRate.fromString(rate: bitRate),
                                         channel: RecorderChannel.fromString(channel: channel),
                                         period: period,
                                         maxDuration: maxDuration,
                                         freeDisk: freeDisk,
                                         interruptedBehavior: InterruptedBehavior.fromString(behavior: interruptedBehavior))
        _recorder = initRecorder(config: config)
//        if (PCMBitRate.fromString(rate: bitRate) == .PCM16Bit) {
//            _recorder = initEngine(config: config)
//        } else {
//            _recorder = initRecorder(config: config)
//        }
        _state = .initialized
        registerObservers()
    }
    
    private func initEngine(config: MCRecorderConfig) -> MCAudioEngine {
        let audioEngine = MCAudioEngine.init(config: config)
        audioEngine.delegate = self
        return audioEngine
    }
    
    private func initRecorder(config: MCRecorderConfig) -> MCAudioRecorder {
        let audioRecorder = MCAudioRecorder.init(config: config)
        audioRecorder.delegate = self
        return audioRecorder
    }
    
    func start() -> Bool {
        let result = _recorder?.start() ?? false
        if (result) {
            _state = .recording
        }
        return result
    }
    
    func pause() -> Bool {
        let result = _recorder?.pause() ?? false
        if (result) {
            _state = .pausing
        }
        return true
    }
    
    func resume() -> Bool {
        let result = _recorder?.resume() ?? false
        if (result) {
            _state = .recording
        }
        return result
    }
    
    func stop() -> Bool {
        let result = _recorder?.stop() ?? false
        if (result) {
            _state = .stopped
        }
        return true
    }
    
    func close() -> Bool {
        _recorder?.delegate = nil
        _recorder = nil
        return true
    }
}

extension MCRecorderManager : MCRecorderDelegate {
    
    func recorderInfoChanged(_ duration: TimeInterval, _ db: Double) {
//        print("recorderInfoChanged duration \(duration), db: \(db)")
        delegate?.updateRecorderInfo(duration, db)
    }
    
    func recorderDidFinish(successfully flag: Bool) {
        _state = .finalized
        removeObservers()
    }
    
    func recorderEncodeError(error: Error?) {
        _state = .finalized
        removeObservers()
        delegate?.updateRecorderException(.encodeError, error?.localizedDescription ?? "empty error description")
    }
    
    func recorderException(_ exception: MCRecorderException, _ message: String) {
        let _ = stop()
        delegate?.updateRecorderException(exception, message)
    }
}

extension MCRecorderManager {
    
    private func requestPermission(allowed: @escaping () -> (), rejected: @escaping () -> ()) {
        let permission = AVAudioSession.sharedInstance().recordPermission
        switch (permission) {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { $0 ? allowed() : rejected() }
        case .denied:
            rejected()
        case .granted:
            allowed()
        @unknown default:
            break
        }
    }
    
    private func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(interruptionTypeChanged(_:)), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    @objc private func interruptionTypeChanged(_ noti: NSNotification) {
        guard let userInfo = noti.userInfo, let reasonValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt else { return }
        
        switch reasonValue {
        case AVAudioSession.InterruptionType.began.rawValue://Began
            var isInterrupted = false //是否是被其他音频会话打断
            if #available(iOS 10.3, *) {
                if #available(iOS 14.5, *) {
                    // iOS 14.5之后使用InterruptionReasonKey
                    let reasonKey = userInfo[AVAudioSessionInterruptionReasonKey] as! UInt
                    switch reasonKey {
                    case AVAudioSession.InterruptionReason.default.rawValue:
                        //因为另一个会话被激活,音频中断
                        isInterrupted = true
                        delegate?.updateRecorderException(.interrupted, "interruption was interrupted by others")
                        break
                    case AVAudioSession.InterruptionReason.appWasSuspended.rawValue:
                        //由于APP被系统挂起，音频中断。
//                        delegate?.updateRecorderError(.interrupted, "interruption was suspended")
                        break
                    case AVAudioSession.InterruptionReason.builtInMicMuted.rawValue:
                        //音频因内置麦克风静音而中断(例如iPad智能关闭套iPad's Smart Folio关闭)
                        delegate?.updateRecorderException(.interrupted, "interruption was built in mic muted")
                        break
                    default: break
                    }
                    print(reasonKey)
                } else {
                    // iOS 10.3-14.5，AVAudioSessionInterruptionTypeKey为1表示是另一音频打断,
                    let suspendedNumber:NSNumber = userInfo[AVAudioSessionInterruptionTypeKey] as! NSNumber
                    isInterrupted = suspendedNumber.boolValue
                    if (isInterrupted) {
                        delegate?.updateRecorderException(.interrupted, "interruption was suspended（iOS 10.3-14.5）")
                    }
                }
            }
            
            if isInterrupted {
               if _recorder?.config?.interruptedBehavior == .Pause {
                   let _ = pause()
               } else {
                   let _ = stop()
               }
            }
            break
        case AVAudioSession.InterruptionType.ended.rawValue://End
            let optionKey = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt
            if optionKey == AVAudioSession.InterruptionOptions.shouldResume.rawValue {
                //指示另一个音频会话的中断已结束，本应用程序可以恢复音频。
            }
            break
        default: break
        }
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
    }
}
